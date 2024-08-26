// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";
import { IERC1155 } from "openzeppelin-contracts/contracts/interfaces/IERC1155.sol";
import { IERC1155Receiver } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {
    CallbackType,
    TransactionType,
    ReturnSingleData,
    ReturnMultiData,
    SingleDirectSingleVaultStateReq,
    SingleDirectMultiVaultStateReq,
    SingleXChainSingleVaultStateReq,
    SingleXChainMultiVaultStateReq,
    MultiDstMultiVaultStateReq,
    MultiDstSingleVaultStateReq
} from "src/types/DataTypes.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { IBaseSuperformRouterPlus, IERC20 } from "src/interfaces/IBaseSuperformRouterPlus.sol";
import { IBaseRouter } from "src/interfaces/IBaseRouter.sol";
import { ISuperformRouterLike } from "src/router-plus/ISuperformRouterLike.sol";
import { Error } from "src/libraries/Error.sol";

abstract contract BaseSuperformRouterPlus is IBaseSuperformRouterPlus, IERC1155Receiver {
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                       CONSTANTS                          //
    //////////////////////////////////////////////////////////////
    ISuperRegistry public immutable superRegistry;
    uint64 public immutable CHAIN_ID;
    uint256 internal constant ENTIRE_SLIPPAGE = 10_000;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    mapping(uint256 routerPayloadId => address receiverAddressSP) public msgSenderMap;
    mapping(uint256 csrAckPayloadId => bool processed) public statusMap;
    mapping(Actions => mapping(bytes4 selector => bool whitelisted)) public whitelistedSelectors;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyRouterPlusProcessor() {
        if (!_hasRole(keccak256("ROUTER_PLUS_PROCESSOR"), msg.sender)) {
            revert NOT_ROUTER_PLUS_PROCESSOR();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) {
        if (superRegistry_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }

        CHAIN_ID = uint64(block.chainid);

        superRegistry = ISuperRegistry(superRegistry_);

        whitelistedSelectors[Actions.REBALANCE_FROM_SINGLE][IBaseRouter.singleDirectSingleVaultWithdraw.selector] = true;
        whitelistedSelectors[Actions.REBALANCE_FROM_MULTI][IBaseRouter.singleDirectMultiVaultWithdraw.selector] = true;
        whitelistedSelectors[Actions.REBALANCE_X_CHAIN_FROM_SINGLE][IBaseRouter.singleXChainSingleVaultWithdraw.selector]
        = true;
        whitelistedSelectors[Actions.REBALANCE_X_CHAIN_FROM_MULTI][IBaseRouter.singleXChainMultiVaultWithdraw.selector]
        = true;
        whitelistedSelectors[Actions.REBALANCE_X_CHAIN_FROM_MULTI][IBaseRouter.multiDstSingleVaultWithdraw.selector] =
            true;
        whitelistedSelectors[Actions.REBALANCE_X_CHAIN_FROM_MULTI][IBaseRouter.multiDstMultiVaultWithdraw.selector] =
            true;

        whitelistedSelectors[Actions.DEPOSIT][IBaseRouter.singleDirectSingleVaultDeposit.selector] = true;
        whitelistedSelectors[Actions.DEPOSIT][IBaseRouter.singleXChainSingleVaultDeposit.selector] = true;
        whitelistedSelectors[Actions.DEPOSIT][IBaseRouter.singleDirectMultiVaultDeposit.selector] = true;
        whitelistedSelectors[Actions.DEPOSIT][IBaseRouter.singleXChainMultiVaultDeposit.selector] = true;
        whitelistedSelectors[Actions.DEPOSIT][IBaseRouter.multiDstSingleVaultDeposit.selector] = true;
        whitelistedSelectors[Actions.DEPOSIT][IBaseRouter.multiDstMultiVaultDeposit.selector] = true;
    }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL PROTECTED FUNCTIONS            //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IBaseSuperformRouterPlus
    function finalizeDisbursement(uint256 csrSrcPayloadId_) external override onlyRouterPlusProcessor {
        address receiverAddressSP = _completeDisbursement(csrSrcPayloadId_);

        emit DisbursementCompleted(receiverAddressSP, csrSrcPayloadId_);
    }

    /// @inheritdoc IBaseSuperformRouterPlus
    function finalizeBatchDisbursement(uint256[] calldata csrSrcPayloadIds_)
        external
        override
        onlyRouterPlusProcessor
    {
        uint256 len = csrSrcPayloadIds_.length;
        if (len == 0) revert Error.ARRAY_LENGTH_MISMATCH();
        address receiverAddressSP;
        for (uint256 i; i < len; i++) {
            receiverAddressSP = _completeDisbursement(csrSrcPayloadIds_[i]);
            emit DisbursementCompleted(receiverAddressSP, csrSrcPayloadIds_[i]);
        }
    }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL PURE FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @dev overrides receive functions
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    )
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    )
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

    //////////////////////////////////////////////////////////////
    //                   INTERNAL FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev returns if an address has a specific role
    function _hasRole(bytes32 id_, address addressToCheck_) internal view returns (bool) {
        return ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasRole(id_, addressToCheck_);
    }

    function _callSuperformRouter(bytes memory callData_, uint256 msgValue_) internal {
        (bool success, bytes memory returndata) =
            _getAddress(keccak256("SUPERFORM_ROUTER")).call{ value: msgValue_ }(callData_);

        Address.verifyCallResult(success, returndata);
    }

    function _deposit(IERC20 asset_, uint256 amountToDeposit_, uint256 msgValue_, bytes memory callData_) internal {
        /// @dev approves superform router on demand
        asset_.approve(_getAddress(keccak256("SUPERFORM_ROUTER")), amountToDeposit_);

        _callSuperformRouter(callData_, msgValue_);
    }

    function _depositUsingSmartWallet(
        IERC20 asset_,
        uint256 amountToDeposit_,
        uint256 msgValue_,
        address receiverAddressSP_,
        bytes memory callData_,
        bool[] memory sameChain_,
        uint256[][] memory superformIds_
    )
        internal
    {
        /// @dev approves superform router on demand
        asset_.approve(_getAddress(keccak256("SUPERFORM_ROUTER")), amountToDeposit_);

        uint256 payloadStartCount = ISuperformRouterLike(_getAddress(keccak256("SUPERFORM_ROUTER"))).payloadIds();

        uint256 lenDst = sameChain_.length;
        uint256[][] memory batchBalanceBefore = new uint256[][](lenDst);
        address superPositions = _getAddress(keccak256("SUPER_POSITIONS"));
        for (uint256 i; i < lenDst; i++) {
            if (sameChain_[i]) {
                uint256 lenSps = superformIds_[i].length;
                address[] memory receiverAddressSPs = new address[](lenSps);
                for (uint256 j; j < lenSps; ++j) {
                    receiverAddressSPs[j] = address(this);
                }
                batchBalanceBefore[i] = IERC1155(superPositions).balanceOfBatch(receiverAddressSPs, superformIds_[i]);
            }
        }

        _callSuperformRouter(callData_, msgValue_);

        uint256[][] memory batchBalanceAfter = new uint256[][](lenDst);
        for (uint256 i; i < lenDst; i++) {
            if (sameChain_[i]) {
                uint256 lenSps = superformIds_[i].length;
                address[] memory receiverAddressSPs = new address[](lenSps);
                for (uint256 j; j < lenSps; ++j) {
                    receiverAddressSPs[j] = address(this);
                }
                batchBalanceAfter[i] = IERC1155(superPositions).balanceOfBatch(receiverAddressSPs, superformIds_[i]);

                for (uint256 j; j < lenSps; j++) {
                    IERC1155(superPositions).safeTransferFrom(
                        address(this),
                        receiverAddressSP_,
                        superformIds_[i][j],
                        batchBalanceAfter[i][j] - batchBalanceBefore[i][j],
                        ""
                    );
                }
            }
        }

        uint256 payloadEndCount = ISuperformRouterLike(_getAddress(keccak256("SUPERFORM_ROUTER"))).payloadIds();

        if (payloadEndCount - payloadStartCount > 0) {
            for (uint256 i = payloadStartCount; i < payloadEndCount; i++) {
                msgSenderMap[i] = receiverAddressSP_;
            }
        }
    }

    function _completeDisbursement(uint256 csrAckPayloadId_) internal returns (address receiverAddressSP) {
        mapping(uint256 => bool) storage statusMapLoc = statusMap;

        if (statusMapLoc[csrAckPayloadId_]) revert Error.PAYLOAD_ALREADY_PROCESSED();

        statusMapLoc[csrAckPayloadId_] = true;

        address coreStateRegistry = _getAddress(keccak256("CORE_STATE_REGISTRY"));
        address superPositions = _getAddress(keccak256("SUPER_POSITIONS"));

        uint256 txInfo = IBaseStateRegistry(coreStateRegistry).payloadHeader(csrAckPayloadId_);

        (uint256 returnTxType, uint256 callbackType, uint8 multi,,,) = txInfo.decodeTxInfo();

        if (!(returnTxType == uint256(TransactionType.DEPOSIT) && callbackType == uint256(CallbackType.RETURN))) {
            revert Error.INVALID_PAYLOAD_TYPE();
        }

        if (multi != 0) {
            ReturnMultiData memory returnData =
                abi.decode(IBaseStateRegistry(coreStateRegistry).payloadBody(csrAckPayloadId_), (ReturnMultiData));

            /// @dev receiver address SP is retrieved from _depositUsingSmartWallet here. ReturnData.payloadId is the
            /// original router id
            receiverAddressSP = msgSenderMap[returnData.payloadId];

            if (receiverAddressSP == address(0)) revert Error.INVALID_PAYLOAD_ID();

            IERC1155(superPositions).safeBatchTransferFrom(
                address(this), receiverAddressSP, returnData.superformIds, returnData.amounts, ""
            );
        } else {
            ReturnSingleData memory returnData =
                abi.decode(IBaseStateRegistry(coreStateRegistry).payloadBody(csrAckPayloadId_), (ReturnSingleData));

            /// @dev receiver address SP is retrieved from _depositUsingSmartWallet here. ReturnData.payloadId is the
            /// original router id
            receiverAddressSP = msgSenderMap[returnData.payloadId];

            if (receiverAddressSP == address(0)) revert Error.INVALID_PAYLOAD_ID();

            IERC1155(superPositions).safeTransferFrom(
                address(this), receiverAddressSP, returnData.superformId, returnData.amount, ""
            );
        }
    }

    /// @dev returns the address from super registry
    function _getAddress(bytes32 id_) internal view returns (address) {
        return superRegistry.getAddress(id_);
    }
}

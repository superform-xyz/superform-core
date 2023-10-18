///SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { Transmuter } from "ERC1155A/transmuter/Transmuter.sol";
import { IERC1155A } from "ERC1155A/interfaces/IERC1155A.sol";
import { sERC20 } from "ERC1155A/transmuter/sERC20.sol";
import { StateSyncer } from "src/StateSyncer.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { ISuperTransmuter } from "src/interfaces/ISuperTransmuter.sol";
import { TransactionType, ReturnMultiData, ReturnSingleData, CallbackType, AMBMessage } from "src/types/DataTypes.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { Error } from "src/utils/Error.sol";
import { IStateSyncer } from "src/interfaces/IStateSyncer.sol";
import { IBroadcastRegistry } from "./interfaces/IBroadcastRegistry.sol";
import { BroadcastMessage } from "./types/DataTypes.sol";

/// @title SuperTransmuter
/// @author Zeropoint Labs.
/// @notice This contract inherits from ERC1155A transmuter, changing the way transmuters are registered to only require
/// a superformId. Metadata is fetched from underlying vault
contract SuperTransmuter is ISuperTransmuter, Transmuter, StateSyncer {
    using DataLib for uint256;

    bytes32 constant DEPLOY_NEW_TRANSMUTER = keccak256("DEPLOY_NEW_TRANSMUTER");

    /*///////////////////////////////////////////////////////////////
                            MODIFIER
    //////////////////////////////////////////////////////////////*/

    /// @dev minters can be router with id 2 (or) state registry for that beacon
    modifier onlyMinter(uint256 superformId) override {
        uint8 routerId = superRegistry.getSuperformRouterId(msg.sender);
        uint8 registryId = superRegistry.getStateRegistryId(msg.sender);

        /// if registry id is 2 (or) corresponding state registry can mint
        if (routerId != ROUTER_TYPE) {
            (, uint32 formBeaconId,) = DataLib.getSuperform(superformId);

            if (uint32(registryId) != formBeaconId) {
                revert Error.NOT_MINTER();
            }
        }

        _;
    }

    /// @dev minters can be router with id 2 (or) state registry for that beacon
    modifier onlyBatchMinter(uint256[] memory superformIds) override {
        uint8 routerId = superRegistry.getSuperformRouterId(msg.sender);
        uint8 registryId = superRegistry.getStateRegistryId(msg.sender);

        /// if registry id is 1 (or) corresponding state registry can mint
        if (routerId != ROUTER_TYPE) {
            for (uint256 i; i < superformIds.length; ++i) {
                (, uint32 formBeaconId,) = DataLib.getSuperform(superformIds[i]);

                if (uint32(registryId) != formBeaconId) {
                    revert Error.NOT_MINTER();
                }
            }
        }
        _;
    }

    /// @dev only routers with id 2 can burn sERC20
    modifier onlyBurner() override {
        uint8 id = superRegistry.getSuperformRouterId(msg.sender);

        if (id != 2) {
            revert Error.NOT_BURNER();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    uint256 public xChainPayloadCounter;

    /// @param superPositions_ the super positions contract
    /// @param superRegistry_ the superform registry contract
    /// @param routerType_ the router type
    constructor(
        IERC1155A superPositions_,
        address superRegistry_,
        uint8 routerType_
    )
        Transmuter(superPositions_)
        StateSyncer(superRegistry_, routerType_)
    { }

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc Transmuter
    /// @notice explicity revert on register transmuter
    function registerTransmuter(
        uint256, /*id*/
        string memory, /*name*/
        string memory, /*symbol*/
        uint8 /*decimals*/
    )
        external
        pure
        override
        returns (address)
    {
        revert Error.DISABLED();
    }

    /// @inheritdoc ISuperTransmuter
    function registerTransmuter(uint256 superformId_, bytes memory extraData_) external override returns (address) {
        (address superform, uint32 formImplementationId, uint64 chainId) = DataLib.getSuperform(superformId_);

        if (CHAIN_ID != chainId) revert Error.INVALID_CHAIN_ID();
        if (superform == address(0)) revert Error.NOT_SUPERFORM();
        if (formImplementationId == 0) revert Error.FORM_DOES_NOT_EXIST();
        if (synthethicTokenId[superformId_] != address(0)) revert TRANSMUTER_ALREADY_REGISTERED();

        string memory name =
            string(abi.encodePacked("Synthetic ERC20 ", IBaseForm(superform).superformYieldTokenName()));
        string memory symbol = string(abi.encodePacked("sERC20-", IBaseForm(superform).superformYieldTokenSymbol()));
        uint8 decimal = uint8(IBaseForm(superform).getVaultDecimals());

        synthethicTokenId[superformId_] = address(
            new sERC20(
                name,
                symbol,
                decimal
            )
        );

        /// @dev broadcast and deploy to the other destination chains
        if (extraData_.length > 0) {
            BroadcastMessage memory transmuterPayload = BroadcastMessage(
                "SUPER_TRANSMUTER",
                DEPLOY_NEW_TRANSMUTER,
                abi.encode(CHAIN_ID, ++xChainPayloadCounter, superformId_, name, symbol, decimal)
            );

            _broadcast(abi.encode(transmuterPayload), extraData_);
        }

        return synthethicTokenId[superformId_];
    }

    /// @inheritdoc IStateSyncer
    function mintSingle(
        address srcSender_,
        uint256 id_,
        uint256 amount_
    )
        external
        override(IStateSyncer, StateSyncer)
        onlyMinter(id_)
    {
        validateSingleIdExists(id_);
        sERC20(synthethicTokenId[id_]).mint(srcSender_, amount_);
    }

    /// @inheritdoc IStateSyncer
    function mintBatch(
        address srcSender_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    )
        external
        override(IStateSyncer, StateSyncer)
        onlyBatchMinter(ids_)
    {
        uint256 len = ids_.length;
        validateBatchIdsExist(ids_);
        for (uint256 i; i < len;) {
            sERC20(synthethicTokenId[ids_[i]]).mint(srcSender_, amounts_[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IStateSyncer
    function burnSingle(
        address srcSender_,
        uint256 id_,
        uint256 amount_
    )
        external
        override(IStateSyncer, StateSyncer)
        onlyBurner
    {
        validateSingleIdExists(id_);
        sERC20(synthethicTokenId[id_]).burn(srcSender_, amount_);
    }

    /// @inheritdoc IStateSyncer
    function burnBatch(
        address srcSender_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    )
        external
        override(IStateSyncer, StateSyncer)
        onlyBurner
    {
        uint256 len = ids_.length;
        validateBatchIdsExist(ids_);

        /// @dev note each allowance check in burn needs to pass. Since we burn atomically (on SuperformRouter level),
        /// if this loop fails, tx reverts right in the 1st stage
        for (uint256 i; i < len;) {
            sERC20(synthethicTokenId[ids_[i]]).burn(srcSender_, amounts_[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IStateSyncer
    function stateMultiSync(AMBMessage memory data_)
        external
        override(IStateSyncer, StateSyncer)
        returns (uint64 srcChainId_)
    {
        /// @dev here we decode the txInfo and params from the data brought back from destination

        (uint256 returnTxType, uint256 callbackType, uint8 multi,, address returnDataSrcSender,) =
            data_.txInfo.decodeTxInfo();

        if (callbackType != uint256(CallbackType.RETURN)) {
            if (callbackType != uint256(CallbackType.FAIL)) revert Error.INVALID_PAYLOAD();
        }

        /// @dev decode remaining info on superPositions to mint from destination
        ReturnMultiData memory returnData = abi.decode(data_.params, (ReturnMultiData));
        if (returnData.superformRouterId != ROUTER_TYPE) revert Error.INVALID_PAYLOAD();
        _validateStateSyncer(returnData.superformIds);
        validateBatchIdsExist(returnData.superformIds);

        uint256 txInfo = txHistory[returnData.payloadId];
        address srcSender;
        uint256 txType;

        /// @dev decode initial payload info stored on source chain in this contract
        (txType,,,, srcSender, srcChainId_) = txInfo.decodeTxInfo();

        /// @dev verify this is a single vault mint
        if (multi == 0) revert Error.INVALID_PAYLOAD();
        /// @dev compare final shares beneficiary to be the same (dst/src)
        if (returnDataSrcSender != srcSender) revert Error.SRC_SENDER_MISMATCH();
        /// @dev compare txType to be the same (dst/src)
        if (returnTxType != txType) revert Error.SRC_TX_TYPE_MISMATCH();

        /// @dev mint super positions accordingly
        if (
            (txType == uint256(TransactionType.DEPOSIT) && callbackType == uint256(CallbackType.RETURN))
                || (txType == uint256(TransactionType.WITHDRAW) && callbackType == uint256(CallbackType.FAIL))
        ) {
            uint256 len = returnData.superformIds.length;
            for (uint256 i; i < len;) {
                sERC20(synthethicTokenId[returnData.superformIds[i]]).mint(srcSender, returnData.amounts[i]);

                unchecked {
                    ++i;
                }
            }
        } else {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        emit Completed(returnData.payloadId);
    }

    /// @inheritdoc IStateSyncer
    function stateSync(AMBMessage memory data_)
        external
        override(IStateSyncer, StateSyncer)
        returns (uint64 srcChainId_)
    {
        /// @dev here we decode the txInfo and params from the data brought back from destination

        (uint256 returnTxType, uint256 callbackType, uint8 multi,, address returnDataSrcSender,) =
            data_.txInfo.decodeTxInfo();

        if (callbackType != uint256(CallbackType.RETURN)) {
            if (callbackType != uint256(CallbackType.FAIL)) revert Error.INVALID_PAYLOAD();
        }

        /// @dev decode remaining info on superPositions to mint from destination
        ReturnSingleData memory returnData = abi.decode(data_.params, (ReturnSingleData));
        if (returnData.superformRouterId != ROUTER_TYPE) revert Error.INVALID_PAYLOAD();
        _validateStateSyncer(returnData.superformId);
        validateSingleIdExists(returnData.superformId);

        uint256 txInfo = txHistory[returnData.payloadId];
        uint256 txType;
        address srcSender;

        /// @dev decode initial payload info stored on source chain in this contract
        (txType,,,, srcSender, srcChainId_) = txInfo.decodeTxInfo();

        /// @dev verify this is a multi vault mint
        if (multi == 1) revert Error.INVALID_PAYLOAD();
        /// @dev compare final shares beneficiary to be the same (dst/src)
        if (returnDataSrcSender != srcSender) revert Error.SRC_SENDER_MISMATCH();
        /// @dev compare txType to be the same (dst/src)
        if (returnTxType != txType) revert Error.SRC_TX_TYPE_MISMATCH();

        /// @dev mint super positions accordingly
        if (
            (txType == uint256(TransactionType.DEPOSIT) && callbackType == uint256(CallbackType.RETURN))
                || (txType == uint256(TransactionType.WITHDRAW) && callbackType == uint256(CallbackType.FAIL))
        ) {
            sERC20(synthethicTokenId[returnData.superformId]).mint(srcSender, returnData.amount);
        } else {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        emit Completed(returnData.payloadId);
    }

    /// @inheritdoc ISuperTransmuter
    function stateSyncBroadcast(bytes memory data_) external payable override {
        /// @dev this function is only accessible through broadcast registry
        if (msg.sender != superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))) {
            revert Error.NOT_BROADCAST_REGISTRY();
        }

        BroadcastMessage memory transmuterPayload = abi.decode(data_, (BroadcastMessage));

        if (transmuterPayload.messageType == DEPLOY_NEW_TRANSMUTER) {
            _deployTransmuter(transmuterPayload.message);
        }
    }

    function validateSingleIdExists(uint256 superformId_) public view override(IStateSyncer, StateSyncer) {
        if (synthethicTokenId[superformId_] == address(0)) revert Error.TRANSMUTER_NOT_REGISTERED();
    }

    function validateBatchIdsExist(uint256[] memory superformIds_) public view override(IStateSyncer, StateSyncer) {
        uint256 len = superformIds_.length;
        for (uint256 i; i < len;) {
            if (synthethicTokenId[superformIds_[i]] == address(0)) revert Error.TRANSMUTER_NOT_REGISTERED();

            unchecked {
                ++i;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev interacts with broadcast state registry to broadcasting state changes to all connected remote chains
    /// @param message_ is the crosschain message to be sent.
    /// @param extraData_ is the amb override information.
    function _broadcast(bytes memory message_, bytes memory extraData_) internal {
        (uint8[] memory ambIds, bytes memory broadcastParams) = abi.decode(extraData_, (uint8[], bytes));

        /// @dev ambIds are validated inside the broadcast state registry
        /// @dev broadcastParams if wrong will revert in the amb implementation
        IBroadcastRegistry(superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))).broadcastPayload{
            value: msg.value
        }(msg.sender, ambIds, message_, broadcastParams);
    }

    /// @dev deploys new transmuter on broadcasting
    function _deployTransmuter(bytes memory message_) internal {
        (,, uint256 superformId, string memory name, string memory symbol, uint8 decimal) =
            abi.decode(message_, (uint64, uint256, uint256, string, string, uint8));

        address syntheticToken = address(
            new sERC20(
                name,
                symbol,
                decimal
            )
        );

        synthethicTokenId[superformId] = syntheticToken;
    }
}

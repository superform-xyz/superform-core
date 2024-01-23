// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { ERC1155A } from "ERC1155A/ERC1155A.sol";
import { aERC20 } from "ERC1155A/aERC20.sol";
import { Broadcastable } from "src/crosschain-data/utils/Broadcastable.sol";
import { ISuperPositions } from "src/interfaces/ISuperPositions.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { IPaymentHelper } from "./interfaces/IPaymentHelper.sol";
import { Error } from "src/libraries/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import {
    TransactionType,
    ReturnMultiData,
    ReturnSingleData,
    CallbackType,
    AMBMessage,
    BroadcastMessage
} from "src/types/DataTypes.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title SuperPositions
/// @dev Cross-chain LP token minted on source chain
/// @author Zeropoint Labs
contract SuperPositions is ISuperPositions, ERC1155A, Broadcastable {
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    ISuperRegistry public immutable superRegistry;
    uint64 public immutable CHAIN_ID;
    uint8 internal constant CORE_STATE_REGISTRY_ID = 1;
    bytes32 internal constant DEPLOY_NEW_AERC20 = keccak256("DEPLOY_NEW_AERC20");

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    /// @dev maps all transaction data routed through the smart contract.
    mapping(uint256 transactionId => TxHistory txHistory) public override txHistory;

    /// @dev is the base uri set by admin
    string public dynamicURI;

    /// @dev is the base uri frozen status
    bool public dynamicURIFrozen;

    /// @dev nonce for aERC20 broadcast
    uint256 public xChainPayloadCounter;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyRouter() {
        if (msg.sender != superRegistry.getAddress(keccak256("SUPERFORM_ROUTER"))) revert Error.NOT_SUPERFORM_ROUTER();
        _;
    }

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    /// @dev is used in same chain case (as superform is available on the chain to validate caller)
    modifier onlyMinter(uint256 superformId) {
        address router = superRegistry.getAddress(keccak256("SUPERFORM_ROUTER"));

        /// if msg.sender isn't superformRouter then it must be state registry of that form
        if (msg.sender != router) {
            uint8 registryId = superRegistry.getStateRegistryId(msg.sender);

            (address superform,,) = DataLib.getSuperform(superformId);
            uint8 formRegistryId = IBaseForm(superform).getStateRegistryId();

            if (registryId != formRegistryId) {
                revert Error.NOT_MINTER();
            }
        }

        _;
    }

    modifier onlyBroadcastRegistry() {
        if (msg.sender != superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))) {
            revert Error.NOT_BROADCAST_REGISTRY();
        }
        _;
    }

    modifier onlyBatchMinter(uint256[] memory superformIds) {
        address router = superRegistry.getAddress(keccak256("SUPERFORM_ROUTER"));

        /// if msg.sender isn't superformRouter then it must be state registry for that superform
        if (msg.sender != router) {
            uint256 len = superformIds.length;
            for (uint256 i; i < len; ++i) {
                (, uint32 formImplementationId,) = DataLib.getSuperform(superformIds[i]);
                uint8 registryId = superRegistry.getStateRegistryId(msg.sender);

                if (uint32(registryId) != formImplementationId) {
                    revert Error.NOT_MINTER();
                }
            }
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    /// @param dynamicURI_  URL for external metadata of ERC1155 SuperPositions
    /// @param superRegistry_ the superform registry contract
    constructor(
        string memory dynamicURI_,
        address superRegistry_,
        string memory name_,
        string memory symbol_
    )
        ERC1155A(name_, symbol_)
    {
        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }

        CHAIN_ID = uint64(block.chainid);

        superRegistry = ISuperRegistry(superRegistry_);
        dynamicURI = dynamicURI_;
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ERC1155A
    function supportsInterface(bytes4 interfaceId_) public view virtual override(ERC1155A, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId_);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ISuperPositions
    function updateTxHistory(
        uint256 payloadId_,
        uint256 txInfo_,
        address receiverAddressSP_
    )
        external
        override
        onlyRouter
    {
        txHistory[payloadId_] = TxHistory({ txInfo: txInfo_, receiverAddressSP: receiverAddressSP_ });

        emit TxHistorySet(payloadId_, txInfo_, receiverAddressSP_);
    }

    /// @inheritdoc ISuperPositions
    function mintSingle(address receiverAddressSP_, uint256 id_, uint256 amount_) external override onlyMinter(id_) {
        _mint(receiverAddressSP_, msg.sender, id_, amount_, "");
    }

    /// @inheritdoc ISuperPositions
    function mintBatch(
        address receiverAddressSP_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    )
        external
        override
        onlyBatchMinter(ids_)
    {
        if (ids_.length != amounts_.length) revert Error.ARRAY_LENGTH_MISMATCH();
        _batchMint(receiverAddressSP_, msg.sender, ids_, amounts_, "");
    }

    /// @inheritdoc ISuperPositions
    function burnSingle(address srcSender_, uint256 id_, uint256 amount_) external override onlyRouter {
        _burn(srcSender_, msg.sender, id_, amount_);
    }

    /// @inheritdoc ISuperPositions
    function burnBatch(
        address srcSender_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    )
        external
        override
        onlyRouter
    {
        if (ids_.length != amounts_.length) revert Error.ARRAY_LENGTH_MISMATCH();
        _batchBurn(srcSender_, msg.sender, ids_, amounts_);
    }

    /// @inheritdoc ISuperPositions
    function stateMultiSync(AMBMessage memory data_) external override returns (uint64 srcChainId_) {
        /// @dev here we decode the txInfo and params from the data brought back from destination

        (uint256 returnTxType, uint256 callbackType, uint8 multi,,,) = data_.txInfo.decodeTxInfo();

        if (callbackType != uint256(CallbackType.RETURN) && callbackType != uint256(CallbackType.FAIL)) {
            revert Error.INVALID_PAYLOAD_TYPE();
        }

        /// @dev decode remaining info on superPositions to mint from destination
        ReturnMultiData memory returnData = abi.decode(data_.params, (ReturnMultiData));

        _validateStateSyncer(returnData.superformIds);

        uint256 txInfo = txHistory[returnData.payloadId].txInfo;

        /// @dev if txInfo is zero then the payloadId is invalid for ack
        if (txInfo == 0) {
            revert Error.TX_HISTORY_NOT_FOUND();
        }

        uint256 txType;

        /// @dev decode initial payload info stored on source chain in this contract
        (txType,,,,, srcChainId_) = txInfo.decodeTxInfo();

        /// @dev verify this is a not single vault mint
        if (multi != 1) revert Error.INVALID_PAYLOAD_TYPE();
        /// @dev compare txType to be the same (dst/src)
        if (returnTxType != txType) revert Error.SRC_TX_TYPE_MISMATCH();

        /// @dev mint super positions accordingly
        if (
            (txType == uint256(TransactionType.DEPOSIT) && callbackType == uint256(CallbackType.RETURN))
                || (txType == uint256(TransactionType.WITHDRAW) && callbackType == uint256(CallbackType.FAIL))
        ) {
            _batchMint(
                txHistory[returnData.payloadId].receiverAddressSP,
                msg.sender,
                returnData.superformIds,
                returnData.amounts,
                ""
            );
        } else {
            revert Error.INVALID_PAYLOAD_TYPE();
        }

        emit Completed(returnData.payloadId);
    }

    /// @inheritdoc ISuperPositions
    function stateSync(AMBMessage memory data_) external override returns (uint64 srcChainId_) {
        /// @dev here we decode the txInfo and params from the data brought back from destination

        (uint256 returnTxType, uint256 callbackType, uint8 multi,,,) = data_.txInfo.decodeTxInfo();

        if (callbackType != uint256(CallbackType.RETURN) && callbackType != uint256(CallbackType.FAIL)) {
            revert Error.INVALID_PAYLOAD_TYPE();
        }

        /// @dev decode remaining info on superPositions to mint from destination
        ReturnSingleData memory returnData = abi.decode(data_.params, (ReturnSingleData));
        _validateStateSyncer(returnData.superformId);

        uint256 txInfo = txHistory[returnData.payloadId].txInfo;

        /// @dev if txInfo is zero then the payloadId is invalid for ack
        if (txInfo == 0) {
            revert Error.TX_HISTORY_NOT_FOUND();
        }

        uint256 txType;

        /// @dev decode initial payload info stored on source chain in this contract
        (txType,,,,, srcChainId_) = txInfo.decodeTxInfo();

        /// @dev this is a not multi vault mint
        if (multi != 0) revert Error.INVALID_PAYLOAD_TYPE();
        /// @dev compare txType to be the same (dst/src)
        if (returnTxType != txType) revert Error.SRC_TX_TYPE_MISMATCH();

        /// @dev mint super positions accordingly
        if (
            (txType == uint256(TransactionType.DEPOSIT) && callbackType == uint256(CallbackType.RETURN))
                || (txType == uint256(TransactionType.WITHDRAW) && callbackType == uint256(CallbackType.FAIL))
        ) {
            _mint(
                txHistory[returnData.payloadId].receiverAddressSP,
                msg.sender,
                returnData.superformId,
                returnData.amount,
                ""
            );
        } else {
            revert Error.INVALID_PAYLOAD_TYPE();
        }

        emit Completed(returnData.payloadId);
    }

    /// @inheritdoc ISuperPositions
    function stateSyncBroadcast(bytes memory data_) external payable override onlyBroadcastRegistry {
        BroadcastMessage memory transmuterPayload = abi.decode(data_, (BroadcastMessage));

        if (transmuterPayload.messageType != DEPLOY_NEW_AERC20) {
            revert Error.INVALID_MESSAGE_TYPE();
        }
        _deployTransmuter(transmuterPayload.message);
    }

    /// @inheritdoc ISuperPositions
    function setDynamicURI(string memory dynamicURI_, bool freeze_) external override onlyProtocolAdmin {
        if (dynamicURIFrozen) {
            revert Error.DYNAMIC_URI_FROZEN();
        }

        string memory oldURI = dynamicURI;
        dynamicURI = dynamicURI_;
        dynamicURIFrozen = freeze_;

        emit DynamicURIUpdated(oldURI, dynamicURI_, freeze_);
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @notice Used to construct return url
    function _baseURI() internal view override returns (string memory) {
        return dynamicURI;
    }

    /// @dev helps validate the state registry id for minting superform id
    /// @dev is used in cross chain case (as superform is not available on the chain to validate caller)
    function _validateStateSyncer(uint256 superformId_) internal view {
        uint8 registryId = superRegistry.getStateRegistryId(msg.sender);
        _isValidStateSyncer(registryId, superformId_);
    }

    /// @dev helps validate the state registry id for minting superform id
    function _validateStateSyncer(uint256[] memory superformIds_) internal view {
        uint8 registryId = superRegistry.getStateRegistryId(msg.sender);
        for (uint256 i; i < superformIds_.length; ++i) {
            _isValidStateSyncer(registryId, superformIds_[i]);
        }
    }

    function _isValidStateSyncer(uint8 registryId_, uint256 superformId_) internal view {
        /// @dev registryId_ zero check is done in superRegistry.getStateRegistryId()

        /// @dev If registryId is 1, meaning CoreStateRegistry, no further checks are necessary.
        /// @dev This is because CoreStateRegistry is the default minter for all kinds of forms
        /// @dev In case registryId is > 1, we need to check if the registryId matches the formImplementationId
        if (registryId_ == CORE_STATE_REGISTRY_ID) {
            return;
        }

        (, uint32 formImplementationId,) = DataLib.getSuperform(superformId_);
        uint8 formRegistryId = ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY")))
            .getFormStateRegistryId(formImplementationId);

        if (registryId_ != formRegistryId) {
            revert Error.NOT_MINTER_STATE_REGISTRY_ROLE();
        }
    }

    function _registerAERC20(uint256 id) internal override returns (address aErc20Token) {
        if (!ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).isSuperform(id)) {
            revert Error.SUPERFORM_ID_NONEXISTENT();
        }
        (address superform,,) = id.getSuperform();

        string memory name = string.concat("SuperPositions AERC20 ", IBaseForm(superform).superformYieldTokenName());
        string memory symbol = string.concat("aERC20-", IBaseForm(superform).superformYieldTokenSymbol());
        uint8 decimal = uint8(IBaseForm(superform).getVaultDecimals());
        aErc20Token = address(new aERC20(name, symbol, decimal));
        /// @dev broadcast and deploy to the other destination chains
        BroadcastMessage memory transmuterPayload = BroadcastMessage(
            "SUPER_POSITIONS",
            DEPLOY_NEW_AERC20,
            abi.encode(CHAIN_ID, ++xChainPayloadCounter, id, name, symbol, decimal)
        );

        _broadcast(
            superRegistry.getAddress(keccak256("BROADCAST_REGISTRY")),
            superRegistry.getAddress(keccak256("PAYMASTER")),
            abi.encode(transmuterPayload),
            IPaymentHelper(superRegistry.getAddress(keccak256("PAYMENT_HELPER"))).getRegisterTransmuterAMBData()
        );

        emit AERC20TokenRegistered(id, aErc20Token);

        return aErc20Token;
    }

    /// @dev deploys new transmuter on broadcasting
    function _deployTransmuter(bytes memory message_) internal {
        (,, uint256 superformId, string memory name, string memory symbol, uint8 decimal) =
            abi.decode(message_, (uint64, uint256, uint256, string, string, uint8));
        if (aErc20TokenId[superformId] != address(0)) revert AERC20_ALREADY_REGISTERED();

        address aErc20Token = address(new aERC20(name, symbol, decimal));

        aErc20TokenId[superformId] = aErc20Token;

        emit AERC20TokenRegistered(superformId, aErc20Token);
    }
}

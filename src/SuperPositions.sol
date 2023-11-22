///SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import { ERC1155A } from "ERC1155A/ERC1155A.sol";
import { sERC20 } from "ERC1155A/sERC20.sol";
import {
    TransactionType,
    ReturnMultiData,
    ReturnSingleData,
    CallbackType,
    AMBMessage,
    BroadcastMessage
} from "src/types/DataTypes.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperPositions } from "src/interfaces/ISuperPositions.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { IBroadcastRegistry } from "./interfaces/IBroadcastRegistry.sol";
import { IPaymentHelper } from "./interfaces/IPaymentHelper.sol";
import { Error } from "src/utils/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";

/// @title SuperPositions
/// @author Zeropoint Labs.
contract SuperPositions is ISuperPositions, ERC1155A {
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////
    ISuperRegistry public immutable superRegistry;
    uint64 public immutable CHAIN_ID;
    bytes32 constant DEPLOY_NEW_SERC20 = keccak256("DEPLOY_NEW_SERC20");

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    /// @dev maps all transaction data routed through the smart contract.
    mapping(uint256 transactionId => uint256 txInfo) public override txHistory;

    /// @dev is the base uri set by admin
    string public dynamicURI;

    /// @dev is the base uri frozen status
    bool public dynamicURIFrozen;

    /// @dev nonce for sERC20 broadcast
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

    modifier onlyMinter(uint256 superformId) {
        address router = superRegistry.getAddress(keccak256("SUPERFORM_ROUTER"));

        /// if msg.sender isn't superformRouter then it must be state registry for that superform
        if (msg.sender != router) {
            (, uint32 formBeaconId,) = DataLib.getSuperform(superformId);
            uint8 registryId = superRegistry.getStateRegistryId(msg.sender);

            if (uint32(registryId) != formBeaconId) {
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
                (, uint32 formBeaconId,) = DataLib.getSuperform(superformIds[i]);
                uint8 registryId = superRegistry.getStateRegistryId(msg.sender);

                if (uint32(registryId) != formBeaconId) {
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
    constructor(string memory dynamicURI_, address superRegistry_) {
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
    function updateTxHistory(uint256 payloadId_, uint256 txInfo_) external override onlyRouter {
        txHistory[payloadId_] = txInfo_;
    }

    /// @inheritdoc ISuperPositions
    function mintSingle(address srcSender_, uint256 id_, uint256 amount_) external override onlyMinter(id_) {
        _mint(srcSender_, msg.sender, id_, amount_, "");
    }

    /// @inheritdoc ISuperPositions
    function mintBatch(
        address srcSender_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    )
        external
        override
        onlyBatchMinter(ids_)
    {
        _batchMint(srcSender_, msg.sender, ids_, amounts_, "");
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
        _batchBurn(srcSender_, msg.sender, ids_, amounts_);
    }

    /// @inheritdoc ISuperPositions
    function stateMultiSync(AMBMessage memory data_) external override returns (uint64 srcChainId_) {
        /// @dev here we decode the txInfo and params from the data brought back from destination

        (uint256 returnTxType, uint256 callbackType, uint8 multi,, address returnDataSrcSender,) =
            data_.txInfo.decodeTxInfo();

        if (callbackType != uint256(CallbackType.RETURN) && callbackType != uint256(CallbackType.FAIL)) {
            revert Error.INVALID_PAYLOAD_TYPE();
        }

        /// @dev decode remaining info on superPositions to mint from destination
        ReturnMultiData memory returnData = abi.decode(data_.params, (ReturnMultiData));

        _validateStateSyncer(returnData.superformIds);

        uint256 txInfo = txHistory[returnData.payloadId];

        /// @dev if txInfo is zero then the payloadId is invalid for ack
        if (txInfo == 0) {
            revert Error.TX_HISTORY_NOT_FOUND();
        }

        address srcSender;
        uint256 txType;

        /// @dev decode initial payload info stored on source chain in this contract
        (txType,,,, srcSender, srcChainId_) = txInfo.decodeTxInfo();

        /// @dev verify this is a not single vault mint
        if (multi != 1) revert Error.INVALID_PAYLOAD_TYPE();
        /// @dev compare final shares beneficiary to be the same (dst/src)
        if (returnDataSrcSender != srcSender) revert Error.SRC_SENDER_MISMATCH();
        /// @dev compare txType to be the same (dst/src)
        if (returnTxType != txType) revert Error.SRC_TX_TYPE_MISMATCH();

        /// @dev mint super positions accordingly
        if (
            (txType == uint256(TransactionType.DEPOSIT) && callbackType == uint256(CallbackType.RETURN))
                || (txType == uint256(TransactionType.WITHDRAW) && callbackType == uint256(CallbackType.FAIL))
        ) {
            _batchMint(srcSender, msg.sender, returnData.superformIds, returnData.amounts, "");
        } else {
            revert Error.INVALID_PAYLOAD_TYPE();
        }

        emit Completed(returnData.payloadId);
    }

    /// @inheritdoc ISuperPositions
    function stateSync(AMBMessage memory data_) external override returns (uint64 srcChainId_) {
        /// @dev here we decode the txInfo and params from the data brought back from destination

        (uint256 returnTxType, uint256 callbackType, uint8 multi,, address returnDataSrcSender,) =
            data_.txInfo.decodeTxInfo();

        if (callbackType != uint256(CallbackType.RETURN) && callbackType != uint256(CallbackType.FAIL)) {
            revert Error.INVALID_PAYLOAD_TYPE();
        }

        /// @dev decode remaining info on superPositions to mint from destination
        ReturnSingleData memory returnData = abi.decode(data_.params, (ReturnSingleData));
        _validateStateSyncer(returnData.superformId);

        uint256 txInfo = txHistory[returnData.payloadId];

        /// @dev if txInfo is zero then the payloadId is invalid for ack
        if (txInfo == 0) {
            revert Error.TX_HISTORY_NOT_FOUND();
        }

        uint256 txType;
        address srcSender;

        /// @dev decode initial payload info stored on source chain in this contract
        (txType,,,, srcSender, srcChainId_) = txInfo.decodeTxInfo();

        /// @dev this is a not multi vault mint
        if (multi != 0) revert Error.INVALID_PAYLOAD_TYPE();

        /// @dev compare final shares beneficiary to be the same (dst/src)
        if (returnDataSrcSender != srcSender) revert Error.SRC_SENDER_MISMATCH();
        /// @dev compare txType to be the same (dst/src)
        if (returnTxType != txType) revert Error.SRC_TX_TYPE_MISMATCH();

        /// @dev mint super positions accordingly
        if (
            (txType == uint256(TransactionType.DEPOSIT) && callbackType == uint256(CallbackType.RETURN))
                || (txType == uint256(TransactionType.WITHDRAW) && callbackType == uint256(CallbackType.FAIL))
        ) {
            _mint(srcSender, msg.sender, returnData.superformId, returnData.amount, "");
        } else {
            revert Error.INVALID_PAYLOAD_TYPE();
        }

        emit Completed(returnData.payloadId);
    }

    /// @inheritdoc ISuperPositions
    function stateSyncBroadcast(bytes memory data_) external payable override onlyBroadcastRegistry {
        BroadcastMessage memory transmuterPayload = abi.decode(data_, (BroadcastMessage));

        if (transmuterPayload.messageType != DEPLOY_NEW_SERC20) {
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

    function _isValidStateSyncer(uint8 registryId_, uint256 superformId_) internal pure {
        /// @dev Directly check if the registryId is 0 or doesn't match the allowed cases.
        if (registryId_ == 0) {
            revert Error.NOT_MINTER_STATE_REGISTRY_ROLE();
        }
        /// @dev If registryId is 1, meaning CoreStateRegistry, no further checks are necessary.
        /// @dev This is because CoreStateRegistry is the default minter for all kinds of forms
        /// @dev In case registryId is > 1, we need to check if the registryId matches the formImplementationId
        if (registryId_ == 1) {
            return;
        }

        (, uint32 formImplementationId,) = DataLib.getSuperform(superformId_);

        if (uint32(registryId_) != formImplementationId) {
            revert Error.NOT_MINTER_STATE_REGISTRY_ROLE();
        }
    }

    function _registerSERC20(uint256 id) internal override returns (address syntheticToken) {
        if (!ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).isSuperform(id)) {
            revert Error.SUPERFORM_ID_NONEXISTENT();
        }
        (address superform,,) = id.getSuperform();

        string memory name =
            string(abi.encodePacked("Synthetic ERC20 ", IBaseForm(superform).superformYieldTokenName()));
        string memory symbol = string(abi.encodePacked("sERC20-", IBaseForm(superform).superformYieldTokenSymbol()));
        uint8 decimal = uint8(IBaseForm(superform).getVaultDecimals());
        syntheticToken = address(
            new sERC20(
                name,
                symbol,
                decimal
            )
        );
        /// @dev broadcast and deploy to the other destination chains
        BroadcastMessage memory transmuterPayload = BroadcastMessage(
            "SUPER_POSITIONS",
            DEPLOY_NEW_SERC20,
            abi.encode(CHAIN_ID, ++xChainPayloadCounter, id, name, symbol, decimal)
        );

        _broadcast(abi.encode(transmuterPayload));

        emit SyntheticTokenRegistered(id, syntheticToken);

        return syntheticToken;
    }

    /// @dev interacts with broadcast state registry to broadcasting state changes to all connected remote chains
    /// @param message_ is the crosschain message to be sent.
    function _broadcast(bytes memory message_) internal {
        (uint256 totalFees, bytes memory extraData) =
            IPaymentHelper(superRegistry.getAddress(keccak256("PAYMENT_HELPER"))).getRegisterTransmuterAMBData();

        (uint8 ambId, bytes memory broadcastParams) = abi.decode(extraData, (uint8, bytes));

        if (msg.value < totalFees) {
            revert Error.INVALID_BROADCAST_FEE();
        }

        /// @dev ambIds are validated inside the broadcast state registry
        /// @dev broadcastParams if wrong will revert in the amb implementation
        IBroadcastRegistry(superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))).broadcastPayload{
            value: msg.value
        }(msg.sender, ambId, message_, broadcastParams);
    }

    /// @dev deploys new transmuter on broadcasting
    function _deployTransmuter(bytes memory message_) internal {
        (,, uint256 superformId, string memory name, string memory symbol, uint8 decimal) =
            abi.decode(message_, (uint64, uint256, uint256, string, string, uint8));
        if (synthethicTokenId[superformId] != address(0)) revert SYNTHETIC_ERC20_ALREADY_REGISTERED();

        address syntheticToken = address(
            new sERC20(
                name,
                symbol,
                decimal
            )
        );

        synthethicTokenId[superformId] = syntheticToken;

        emit SyntheticTokenRegistered(superformId, syntheticToken);
    }
}

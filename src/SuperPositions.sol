///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC1155s} from "ERC1155s/src/ERC1155s.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {TransactionType, ReturnMultiData, ReturnSingleData, CallbackType, InitMultiVaultData, InitSingleVaultData, AMBMessage} from "./types/DataTypes.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";
import {ISuperPositions} from "./interfaces/ISuperPositions.sol";
import {ISuperRouter} from "./interfaces/ISuperRouter.sol";
import {ISuperRBAC} from "./interfaces/ISuperRBAC.sol";
import "./utils/DataPacking.sol";
import {Error} from "./utils/Error.sol";

/// @title SuperPositions
/// @author Zeropoint Labs.
contract SuperPositions is ISuperPositions, ERC1155s {
    string public dynamicURI = "https://api.superform.xyz/superposition/";

    ISuperRegistry public immutable superRegistry;

    /// @dev maps all transaction data routed through the smart contract.
    mapping(uint256 transactionId => AMBMessage ambMessage) public txHistory;

    modifier onlyRouter() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasSuperRouterRole(msg.sender)) revert Error.NOT_SUPER_ROUTER();
        _;
    }

    modifier onlyCoreStateRegistry() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasCoreStateRegistryRole(msg.sender))
            revert Error.NOT_CORE_STATE_REGISTRY();
        _;
    }

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(msg.sender)) revert Error.NOT_PROTOCOL_ADMIN();
        _;
    }

    /// @param dynamicURI_              URL for external metadata of ERC1155 SuperPositions
    /// @param superRegistry_ the superform registry contract

    constructor(string memory dynamicURI_, address superRegistry_) {
        dynamicURI = dynamicURI_;

        superRegistry = ISuperRegistry(superRegistry_);
    }

    /// FIXME: Temp extension need to make approve at superRouter, may change with arch
    function setApprovalForAll(address operator, bool approved) public virtual override(ISuperPositions, ERC1155) {
        super.setApprovalForAll(operator, approved);
    }

    /// @inheritdoc ISuperPositions
    function mintSingleSP(address owner_, uint256 superFormId_, uint256 amount_) external override onlyRouter {
        _mint(owner_, superFormId_, amount_, "");
    }

    /// @inheritdoc ISuperPositions
    function mintBatchSP(
        address owner_,
        uint256[] memory superFormIds_,
        uint256[] memory amounts_
    ) external override onlyRouter {
        _batchMint(owner_, superFormIds_, amounts_, "");
    }

    /// @inheritdoc ISuperPositions
    function burnSingleSP(address srcSender_, uint256 superFormId_, uint256 amount_) external override onlyRouter {
        _burn(srcSender_, superFormId_, amount_);
    }

    /// @inheritdoc ISuperPositions
    function burnBatchSP(
        address srcSender_,
        uint256[] memory superFormIds_,
        uint256[] memory amounts_
    ) external override onlyRouter {
        _batchBurn(srcSender_, superFormIds_, amounts_);
    }

    /// @inheritdoc ISuperPositions
    function updateTxHistory(uint256 payloadId, AMBMessage memory message_) external override onlyRouter {
        txHistory[payloadId] = message_;
    }

    /// @inheritdoc ISuperPositions
    function stateMultiSync(
        AMBMessage memory data_
    ) external payable override onlyCoreStateRegistry returns (uint64 srcChainId_) {
        (uint256 txType, uint256 callbackType, , , , uint64 returnDataSrcChainId) = _decodeTxInfo(data_.txInfo);

        /// @dev NOTE: some optimization ideas? suprisingly, you can't use || here!
        if (callbackType != uint256(CallbackType.RETURN))
            if (callbackType != uint256(CallbackType.FAIL)) revert Error.INVALID_PAYLOAD();

        ReturnMultiData memory returnData = abi.decode(data_.params, (ReturnMultiData));

        AMBMessage memory stored = txHistory[returnData.payloadId];

        uint8 multi;
        address srcSender;
        (, , multi, , srcSender, srcChainId_) = _decodeTxInfo(stored.txInfo);

        if (multi == 0) revert Error.INVALID_PAYLOAD();

        InitMultiVaultData memory multiVaultData = abi.decode(stored.params, (InitMultiVaultData));

        if (returnDataSrcChainId != srcChainId_) revert Error.SRC_CHAIN_IDS_MISMATCH();

        if (txType == uint256(TransactionType.DEPOSIT) && callbackType == uint256(CallbackType.RETURN)) {
            _batchMint(srcSender, multiVaultData.superFormIds, returnData.amounts, "");
        } else if (txType == uint256(TransactionType.WITHDRAW) && callbackType == uint256(CallbackType.FAIL)) {
            /// @dev mint back super positions
            _batchMint(srcSender, multiVaultData.superFormIds, returnData.amounts, "");
        } else {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        emit Completed(returnData.payloadId);
    }

    /// @inheritdoc ISuperPositions
    function stateSync(
        AMBMessage memory data_
    ) external payable override onlyCoreStateRegistry returns (uint64 srcChainId_) {
        (uint256 txType, uint256 callbackType, , , , uint64 returnDataSrcChainId) = _decodeTxInfo(data_.txInfo);

        /// @dev NOTE: some optimization ideas? suprisingly, you can't use || here!
        if (callbackType != uint256(CallbackType.RETURN))
            if (callbackType != uint256(CallbackType.FAIL)) revert Error.INVALID_PAYLOAD();

        ReturnSingleData memory returnData = abi.decode(data_.params, (ReturnSingleData));

        AMBMessage memory stored = txHistory[returnData.payloadId];
        uint8 multi;
        address srcSender;
        (, , multi, , srcSender, srcChainId_) = _decodeTxInfo(stored.txInfo);

        if (multi == 1) revert Error.INVALID_PAYLOAD();

        InitSingleVaultData memory singleVaultData = abi.decode(stored.params, (InitSingleVaultData));

        if (returnDataSrcChainId != srcChainId_) revert Error.SRC_CHAIN_IDS_MISMATCH();

        if (txType == uint256(TransactionType.DEPOSIT) && callbackType == uint256(CallbackType.RETURN)) {
            _mint(srcSender, singleVaultData.superFormId, returnData.amount, "");
        } else if (txType == uint256(TransactionType.WITHDRAW) && callbackType == uint256(CallbackType.FAIL)) {
            _mint(srcSender, singleVaultData.superFormId, singleVaultData.amount, "");
        } else {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        emit Completed(returnData.payloadId);
    }

    /*///////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev PREVILEGED admin ONLY FUNCTION.
    /// @param dynamicURI_    represents the dynamicURI for the ERC1155 super positions
    function setDynamicURI(string memory dynamicURI_) external onlyProtocolAdmin {
        dynamicURI = dynamicURI_;
    }

    /*///////////////////////////////////////////////////////////////
                            Read Only Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Used to construct return url
    function _baseURI() internal view override returns (string memory) {
        return dynamicURI;
    }

    /**
     * @dev See {ERC1155s-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

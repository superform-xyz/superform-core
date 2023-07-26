///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC1155s} from "ERC1155s/ERC1155s.sol";
import {TransactionType, ReturnMultiData, ReturnSingleData, CallbackType, InitMultiVaultData, InitSingleVaultData, AMBMessage} from "./types/DataTypes.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";
import {ISuperPositions} from "./interfaces/ISuperPositions.sol";
import {ISuperRBAC} from "./interfaces/ISuperRBAC.sol";
import {Error} from "./utils/Error.sol";
import {DataLib} from "./libraries/DataLib.sol";

/// @title SuperPositions
/// @author Zeropoint Labs.
contract SuperPositions is ISuperPositions, ERC1155s {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                        STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev is the base uri set by admin
    string public dynamicURI;

    /// @dev is the base uri frozen status
    bool public dynamicURIFrozen;

    /// @dev is the super registry address
    ISuperRegistry public immutable superRegistry;

    /// @dev maps all transaction data routed through the smart contract.
    mapping(uint256 transactionId => uint256 txInfo) public txHistory;

    /*///////////////////////////////////////////////////////////////
                            MODIFIER
    //////////////////////////////////////////////////////////////*/

    /// note replace this to support some new role called minter in super registry
    modifier onlyMinter() {
        if (superRegistry.superRouter() != msg.sender && superRegistry.twoStepsFormStateRegistry() != msg.sender)
            revert Error.NOT_MINTER();
        _;
    }

    modifier onlyRouter() {
        if (superRegistry.superRouter() != msg.sender && superRegistry.twoStepsFormStateRegistry() != msg.sender)
            revert Error.NOT_SUPER_ROUTER();
        _;
    }

    modifier onlyCoreStateRegistry() {
        if (superRegistry.coreStateRegistry() != msg.sender && superRegistry.twoStepsFormStateRegistry() != msg.sender)
            revert Error.NOT_CORE_STATE_REGISTRY();
        _;
    }

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(msg.sender)) revert Error.NOT_PROTOCOL_ADMIN();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param dynamicURI_  URL for external metadata of ERC1155 SuperPositions
    /// @param superRegistry_ the superform registry contract

    constructor(string memory dynamicURI_, address superRegistry_) {
        dynamicURI = dynamicURI_;

        superRegistry = ISuperRegistry(superRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// FIXME: Temp extension need to make approve at superRouter, may change with arch
    function setApprovalForAll(address operator, bool approved) public virtual override(ISuperPositions, ERC1155s) {
        super.setApprovalForAll(operator, approved);
    }

    /// @inheritdoc ISuperPositions
    function mintSingleSP(address owner_, uint256 superFormId_, uint256 amount_) external override onlyMinter {
        _mint(owner_, superFormId_, amount_, "");
    }

    /// @inheritdoc ISuperPositions
    function mintBatchSP(
        address owner_,
        uint256[] memory superFormIds_,
        uint256[] memory amounts_
    ) external override onlyMinter {
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
    function updateTxHistory(uint256 payloadId_, uint256 txInfo_) external override onlyRouter {
        txHistory[payloadId_] = txInfo_;
    }

    /// @inheritdoc ISuperPositions
    function stateMultiSync(
        AMBMessage memory data_
    ) external payable override onlyCoreStateRegistry returns (uint64 srcChainId_) {
        (uint256 returnTxType, uint256 callbackType, uint8 multi, , address returnDataSrcSender, ) = data_
            .txInfo
            .decodeTxInfo();

        /// @dev NOTE: some optimization ideas? suprisingly, you can't use || here!
        if (callbackType != uint256(CallbackType.RETURN))
            if (callbackType != uint256(CallbackType.FAIL)) revert Error.INVALID_PAYLOAD();

        ReturnMultiData memory returnData = abi.decode(data_.params, (ReturnMultiData));

        uint256 txInfo = txHistory[returnData.payloadId];

        address srcSender;
        uint256 txType;
        (txType, , , , srcSender, srcChainId_) = txInfo.decodeTxInfo();

        if (multi == 0) revert Error.INVALID_PAYLOAD();
        if (returnDataSrcSender != srcSender) revert Error.SRC_SENDER_MISMATCH();
        if (returnTxType != txType) revert Error.SRC_TX_TYPE_MISMATCH();

        if (txType == uint256(TransactionType.DEPOSIT) && callbackType == uint256(CallbackType.RETURN)) {
            _batchMint(srcSender, returnData.superFormIds, returnData.amounts, "");
        } else if (txType == uint256(TransactionType.WITHDRAW) && callbackType == uint256(CallbackType.FAIL)) {
            /// @dev mint back super positions
            _batchMint(srcSender, returnData.superFormIds, returnData.amounts, "");
        } else {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        emit Completed(returnData.payloadId);
    }

    /// @inheritdoc ISuperPositions
    function stateSync(
        AMBMessage memory data_
    ) external payable override onlyCoreStateRegistry returns (uint64 srcChainId_) {
        (uint256 txType, uint256 callbackType, uint8 multi, , address returnDataSrcSender, ) = data_
            .txInfo
            .decodeTxInfo();

        /// @dev NOTE: some optimization ideas? suprisingly, you can't use || here!
        if (callbackType != uint256(CallbackType.RETURN))
            if (callbackType != uint256(CallbackType.FAIL)) revert Error.INVALID_PAYLOAD();

        ReturnSingleData memory returnData = abi.decode(data_.params, (ReturnSingleData));

        uint256 txInfo = txHistory[returnData.payloadId];

        address srcSender;
        (, , , , srcSender, srcChainId_) = txInfo.decodeTxInfo();

        if (multi == 1) revert Error.INVALID_PAYLOAD();

        if (returnDataSrcSender != srcSender) revert Error.SRC_SENDER_MISMATCH();

        if (txType == uint256(TransactionType.DEPOSIT) && callbackType == uint256(CallbackType.RETURN)) {
            _mint(srcSender, returnData.superFormId, returnData.amount, "");
        } else if (txType == uint256(TransactionType.WITHDRAW) && callbackType == uint256(CallbackType.FAIL)) {
            _mint(srcSender, returnData.superFormId, returnData.amount, "");
        } else {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        emit Completed(returnData.payloadId);
    }

    /*///////////////////////////////////////////////////////////////
                        PREVILAGED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev PREVILEGED ADMIN ONLY FUNCTION.
    /// @param dynamicURI_ represents the dynamicURI for the ERC1155 super positions
    function setDynamicURI(string memory dynamicURI_, bool freeze) external override onlyProtocolAdmin {
        if (dynamicURIFrozen) {
            revert Error.DYNAMIC_URI_FROZEN();
        }

        string memory oldURI = dynamicURI;
        dynamicURI = dynamicURI_;
        dynamicURIFrozen = freeze;

        emit DynamicURIUpdated(oldURI, dynamicURI_, freeze);
    }

    /*///////////////////////////////////////////////////////////////
                        READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ERC1155s
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155s) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Used to construct return url
    function _baseURI() internal view override returns (string memory) {
        return dynamicURI;
    }
}

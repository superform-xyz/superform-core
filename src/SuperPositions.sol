///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { ERC1155A } from "ERC1155A/ERC1155A.sol";
import { StateSyncer } from "./StateSyncer.sol";
import { TransactionType, ReturnMultiData, ReturnSingleData, CallbackType, AMBMessage } from "./types/DataTypes.sol";
import { ISuperPositions } from "./interfaces/ISuperPositions.sol";
import { ISuperRBAC } from "./interfaces/ISuperRBAC.sol";
import { IStateSyncer } from "./interfaces/IStateSyncer.sol";
import { Error } from "./utils/Error.sol";
import { DataLib } from "./libraries/DataLib.sol";

/// @title SuperPositions
/// @author Zeropoint Labs.
contract SuperPositions is ISuperPositions, ERC1155A, StateSyncer {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                        STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev is the base uri set by admin
    string public dynamicURI;

    /// @dev is the base uri frozen status
    bool public dynamicURIFrozen;

    /*///////////////////////////////////////////////////////////////
                            MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier onlyMinter() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasSuperPositionsMinterRole(msg.sender)) {
            revert Error.NOT_MINTER();
        }
        _;
    }

    modifier onlyBurner() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasSuperPositionsBurnerRole(msg.sender)) {
            revert Error.NOT_BURNER();
        }
        _;
    }

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    modifier onlyMinterStateRegistry() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasMinterStateRegistryRole(msg.sender)) {
            revert Error.NOT_MINTER_STATE_REGISTRY_ROLE();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param dynamicURI_  URL for external metadata of ERC1155 SuperPositions
    /// @param superRegistry_ the superform registry contract
    /// @param routerType_ the router type
    constructor(
        string memory dynamicURI_,
        address superRegistry_,
        uint8 routerType_
    )
        StateSyncer(superRegistry_, routerType_)
    {
        dynamicURI = dynamicURI_;
    }

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperPositions
    function mintSingleSP(address owner_, uint256 id_, uint256 amount_) external override onlyMinter {
        _mint(owner_, id_, amount_, "");
    }

    /// @inheritdoc ISuperPositions
    function mintBatchSP(
        address owner_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    )
        external
        override
        onlyMinter
    {
        _batchMint(owner_, ids_, amounts_, "");
    }

    /// @inheritdoc ISuperPositions
    function burnSingleSP(address srcSender_, uint256 id_, uint256 amount_) external override onlyBurner {
        _burn(srcSender_, id_, amount_);
    }

    /// @inheritdoc ISuperPositions
    function burnBatchSP(
        address srcSender_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    )
        external
        override
        onlyBurner
    {
        _batchBurn(srcSender_, ids_, amounts_);
    }

    /// @inheritdoc IStateSyncer
    function stateMultiSync(AMBMessage memory data_)
        external
        payable
        override(IStateSyncer, StateSyncer)
        onlyMinterStateRegistry
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
            _batchMint(srcSender, returnData.superformIds, returnData.amounts, "");
        } else {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        emit Completed(returnData.payloadId);
    }

    /// @inheritdoc IStateSyncer
    function stateSync(AMBMessage memory data_)
        external
        payable
        override(IStateSyncer, StateSyncer)
        onlyMinterStateRegistry
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
            _mint(srcSender, returnData.superformId, returnData.amount, "");
        } else {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        emit Completed(returnData.payloadId);
    }

    function stateSyncTwoStep(
        address sender_,
        uint256 id_,
        uint256 amount_
    )
        external
        payable
        override(IStateSyncer, StateSyncer)
        onlyMinter
    {
        _mint(sender_, id_, amount_, "");
    }

    /*///////////////////////////////////////////////////////////////
                        PRIVILEGED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperPositions
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

    /// @inheritdoc ERC1155A
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Used to construct return url
    function _baseURI() internal view override returns (string memory) {
        return dynamicURI;
    }
}

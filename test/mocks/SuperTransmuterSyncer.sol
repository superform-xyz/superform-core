///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { Transmuter } from "ERC1155A/transmuter/Transmuter.sol";
import { IERC1155A } from "ERC1155A/interfaces/IERC1155A.sol";
import { sERC20 } from "ERC1155A/transmuter/sERC20.sol";
import { StateSyncer } from "src/StateSyncer.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { ISuperTransmuter } from "./ISuperTransmuter.sol";
import { TransactionType, ReturnMultiData, ReturnSingleData, CallbackType, AMBMessage } from "src/types/DataTypes.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { Error } from "src/utils/Error.sol";
import { IStateSyncer } from "src/interfaces/IStateSyncer.sol";

/// @title SuperTransmuter
/// @author Zeropoint Labs.
/// @notice This contract inherits from ERC1155A transmuter, changing the way transmuters are registered to only require
/// a superformId. Metadata is fetched from underlying vault
contract SuperTransmuterSyncer is ISuperTransmuter, Transmuter, StateSyncer {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

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

    /// @inheritdoc ISuperTransmuter
    function registerTransmuter(uint256 superformId) external override returns (address) {
        (address superform, uint32 formBeaconId, uint64 chainId) = DataLib.getSuperform(superformId);

        if (superRegistry.chainId() != chainId) revert Error.INVALID_CHAIN_ID();
        if (superform == address(0)) revert Error.NOT_SUPERFORM();
        if (formBeaconId == 0) revert Error.FORM_DOES_NOT_EXIST();
        if (synthethicTokenId[superformId] != address(0)) revert TRANSMUTER_ALREADY_REGISTERED();
        address syntheticToken = address(
            new sERC20(
                string(abi.encodePacked("Synthetic ERC20 ", IBaseForm(superform).superformYieldTokenName())),
                string(abi.encodePacked("sERC20-", IBaseForm(superform).superformYieldTokenSymbol())),
                uint8(IBaseForm(superform).getVaultDecimals())
            )
        );
        synthethicTokenId[superformId] = syntheticToken;

        return synthethicTokenId[superformId];
    }

    /// @dev to be modified in mainnet for a real state sync function
    function mockStateSync(
        uint256 superformId,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 decimals
    )
        external
        returns (address)
    {
        (, uint32 formBeaconId,) = DataLib.getSuperform(superformId);

        if (formBeaconId == 0) revert Error.FORM_DOES_NOT_EXIST();
        if (synthethicTokenId[superformId] != address(0)) revert TRANSMUTER_ALREADY_REGISTERED();

        address syntheticToken = address(
            new sERC20(
                tokenName,
                tokenSymbol,
                decimals
            )
        );
        synthethicTokenId[superformId] = syntheticToken;

        return synthethicTokenId[superformId];
    }

    /// @inheritdoc IStateSyncer
    function mintSingle(
        address srcSender_,
        uint256 id_,
        uint256 amount_
    )
        external
        override(IStateSyncer, StateSyncer)
        onlyMinter
    {
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
        onlyMinter
    {
        for (uint256 i = 0; i < ids_.length; i++) {
            sERC20(synthethicTokenId[ids_[i]]).mint(srcSender_, amounts_[i]);
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
        /// @dev note each allowance check in burn needs to pass. Since we burn atomically (on SuperformRouter level),
        /// if this loop fails, tx reverts right in the 1st stage
        for (uint256 i = 0; i < ids_.length; i++) {
            sERC20(synthethicTokenId[ids_[i]]).burn(srcSender_, amounts_[i]);
        }
    }

    /// @inheritdoc IStateSyncer
    function stateMultiSync(AMBMessage memory data_)
        external
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
            for (uint256 i = 0; i < returnData.superformIds.length; i++) {
                sERC20(synthethicTokenId[returnData.superformIds[i]]).mint(srcSender, returnData.amounts[i]);
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
            sERC20(synthethicTokenId[returnData.superformId]).mint(srcSender, returnData.amount);
        } else {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        emit Completed(returnData.payloadId);
    }
}

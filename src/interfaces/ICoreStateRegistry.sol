// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";
import "../types/DataTypes.sol";

/// @title ICoreStateRegistry
/// @author ZeroPoint Labs
/// @notice Interface for Core State Registry
interface ICoreStateRegistry {
    /*///////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/
    /// @dev local struct to avoid stack too deep errors in `processPayload`
    struct CoreProcessPayloadLocalVars {
        bytes _payloadBody;
        uint256 _payloadHeader;
        PayloadState initialState;
        uint8 txType;
        uint8 callbackType;
        uint8 multi;
        address srcSender;
        uint64 srcChainId;
        AMBMessage _message;
        bytes returnMessage;
        bytes32 _proof;
    }

    /// @dev local struct to avoid stack too deep errors in `updateWithdrawPayload`
    struct UpdateWithdrawPayloadVars {
        bytes32 prevPayloadProof;
        bytes prevPayloadBody;
        uint256 prevPayloadHeader;
        uint8 isMulti;
        uint64 srcChainId;
        uint64 dstChainId;
        address srcSender;
    }

    /// @dev local struct to avoid stack too deep errors in `updateDepositPayload`
    struct UpdateDepositPayloadVars {
        bytes32 prevPayloadProof;
        bytes prevPayloadBody;
        uint256 prevPayloadHeader;
        uint64 srcChainId;
        uint8 isMulti;
        PayloadState finalState;
    }

    /// @dev local struct to avoid stack too deep errors in `updateWithdrawPayload`
    struct UpdateMultiVaultWithdrawPayloadLocalVars {
        InitMultiVaultData multiVaultData;
        InitSingleVaultData singleVaultData;
        uint256 len;
        uint256 i;
        address superform;
        uint256[] tSuperFormIds;
        uint256[] tAmounts;
        uint256[] tMaxSlippage;
        LiqRequest[] tLiqData;
        uint256 finalAmount;
        IBridgeValidator bridgeValidator;
    }

    /// @dev local struct to avoid stack too deep errors in `rescueFailedDeposits`
    struct RescueFailedDepositsLocalVars {
        uint64 dstChainId;
        address srcSender;
        uint64 srcChainId;
        address superform;
        IBridgeValidator bridgeValidator;
        uint256 i;
        uint256 l1;
        uint256 l2;
        uint256 _payloadHeader;
        uint256[] superformIds;
    }

    struct FailedDeposit {
        uint256[] superformIds;
        uint256[] amounts;
        address refundAddress;
        uint256 lastProposedTimestamp;
    }

    /*///////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when any deposit fails
    event FailedXChainDeposits(uint256 indexed payloadId);

    /// @dev is emitted when a rescue is proposed for failed deposits in a payload
    event RescueProposed(
        uint256 indexed payloadId, uint256[] superformIds, uint256[] proposedAmount, uint256 proposedTime
    );

    /// @dev is emitted when an user disputed his refund amounts
    event RescueDisputed(uint256 indexed payloadId);

    /// @dev is emitted when deposit rescue is finalized
    event RescueFinalized(uint256 indexed payloadId);

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev allows users to read the superformIds that failed in a specific payloadId_
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @return superformIds_ is the identifiers of superforms in the payloadId that got failed.
    function getFailedDeposits(uint256 payloadId_)
        external
        view
        returns (uint256[] memory superformIds_, uint256[] memory amounts);

    /// @dev allows accounts with {CORE_STATE_REGISTRY_UPDATER_ROLE} to modify a received cross-chain deposit payload.
    /// @param payloadId_ is the identifier of the cross-chain payload to be updated.
    /// @param finalAmounts_ is the amount to be updated.
    /// NOTE: amounts cannot be updated beyond user specified safe slippage limit.
    function updateDepositPayload(uint256 payloadId_, uint256[] calldata finalAmounts_) external;

    /// @dev allows accounts with {CORE_STATE_REGISTRY_UPDATER_ROLE} to modify a received cross-chain withdraw payload.
    /// @param payloadId_  is the identifier of the cross-chain payload to be updated.
    /// @param txData_ is the transaction data to be updated.
    function updateWithdrawPayload(uint256 payloadId_, bytes[] calldata txData_) external;

    /// @dev allows accounts with {CORE_STATE_REGISTRY_PROCESSOR_ROLE} to rescue tokens on failed deposits
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @param proposedAmounts_ is the array of proposed rescue amounts.
    function proposeRescueFailedDeposits(uint256 payloadId_, uint256[] memory proposedAmounts_) external;

    /// @dev allows refund receivers to challenge their final receiving token amounts on failed deposits
    /// @param payloadId_ is the identifier of the cross-chain payload
    /// @notice should challenge within the delay window configured on SuperRegistry
    function disputeRescueFailedDeposits(uint256 payloadId_) external;

    /// @dev allows anyone to settle refunds for unprocessed/failed deposits past the challenge period
    /// @param payloadId_ is the identifier of the cross-chain payload
    function finalizeRescueFailedDeposits(uint256 payloadId_) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title ICoreStateRegistry
/// @author ZeroPoint Labs
/// @notice Interface for Core State Registry
interface ICoreStateRegistry {
    //////////////////////////////////////////////////////////////
    //                           STRUCTS                        //
    //////////////////////////////////////////////////////////////

    /// @dev holds all information about a failed deposit mapped to a payload id
    /// @param superformIds is an array of failing superform ids
    /// @param settlementToken is an array of tokens to be refunded for the failing superform
    /// @param amounts is an array of amounts of settlementToken to be refunded
    /// @param receiverAddress is the users refund address
    /// @param lastProposedTime indicates the rescue proposal timestamp
    struct FailedDeposit {
        uint256[] superformIds;
        address[] settlementToken;
        uint256[] amounts;
        bool[] settleFromDstSwapper;
        address receiverAddress;
        uint256 lastProposedTimestamp;
    }

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when any deposit fails
    event FailedXChainDeposits(uint256 indexed payloadId);

    /// @dev is emitted when a rescue is proposed for failed deposits in a payload
    event RescueProposed(
        uint256 indexed payloadId,
        uint256[] indexed superformIds,
        uint256[] indexed proposedAmount,
        uint256 proposedTime
    );

    /// @dev is emitted when an user disputed his refund amounts
    event RescueDisputed(uint256 indexed payloadId);

    /// @dev is emitted when deposit rescue is finalized
    event RescueFinalized(uint256 indexed payloadId);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev allows users to read the superformIds that failed in a specific payloadId_
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @return superformIds is the identifiers of superforms in the payloadId that got failed.
    /// @return amounts is the amounts of refund tokens issues
    /// @return lastProposedTime is the refund proposed time
    function getFailedDeposits(uint256 payloadId_)
        external
        view
        returns (uint256[] memory superformIds, uint256[] memory amounts, uint256 lastProposedTime);

    /// @dev used internally for try/catching
    /// @param finalAmount_ is the final amount of tokens received
    /// @param amount_ is the indicated amount of tokens to be received
    /// @param maxSlippage_ is the amount of acceptable slippage for the transaction
    function validateSlippage(uint256 finalAmount_, uint256 amount_, uint256 maxSlippage_)
        external
        view
        returns (bool);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

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

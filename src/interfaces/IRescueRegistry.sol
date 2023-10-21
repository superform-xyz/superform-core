// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

/// @title IRescueRegistry
/// @author ZeroPoint Labs
/// @notice Interface for Core State Registry
interface IRescueRegistry {
    /*///////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/
    // struct FailedDeposit {
    //     uint256[] superformIds;
    //     address[] rescueTokens;
    //     uint256[] amounts;
    //     address refundAddress;
    //     uint256 lastProposedTimestamp;
    // }
    /*///////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when a rescue is proposed for failed deposits in a payload
    event RescueProposed(
        uint256 indexed payloadId, uint256[] superformIds, uint256[] proposedAmount, uint256 proposedTime
    );

    /// @dev is emitted when an user disputed his refund amounts
    event RescueDisputed(uint256 indexed payloadId);

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev allows accounts with {CORE_STATE_REGISTRY_PROCESSOR_ROLE} to rescue tokens on failed deposits
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @param proposedAmounts_ is the array of proposed rescue amounts.
    function proposeRescueFailedDeposits(uint256 payloadId_, uint256[] memory proposedAmounts_) external;

    /// @dev allows refund receivers to challenge their final receiving token amounts on failed deposits
    /// @param payloadId_ is the identifier of the cross-chain payload
    /// @notice should challenge within the delay window configured on SuperRegistry
    function disputeRescueFailedDeposits(uint256 payloadId_) external;
}

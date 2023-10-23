// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

/// @title ICollateralRescuer
/// @author ZeroPoint Labs
/// @notice Interface for Core State Registry
interface ICollateralRescuer {
    /*///////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct FailedDeposit {
        uint256[] superformIds;
        address[] rescueTokens;
        uint256[] amounts;
        address refundAddress;
        uint256 lastProposedTimestamp;
    }
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

    /// @dev allows CoreStateRegistry to add failed deposits
    /// @param payloadId_ is the identifier of the cross-chain payload
    /// @param superformId_ is the identifier of the superform whose deposit failed
    function addFailedDeposit(uint256 payloadId_, uint256 superformId_) external;

    /// @dev allows CoreStateRegistry to delete failed deposits
    /// @param payloadId_ is the identifier of the cross-chain payload to be deleted
    function deleteFailedDeposits(uint256 payloadId_) external;

    /// @dev allows users to read the superformIds that failed in a specific payloadId_
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @return superformIds_ is the identifiers of superforms in the payloadId that got failed.
    function getFailedDeposits(uint256 payloadId_) external view returns (FailedDeposit memory);
}

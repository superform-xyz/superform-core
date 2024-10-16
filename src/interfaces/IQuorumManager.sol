// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title IQuorumManager
/// @dev Interface for QuorumManager
/// @author ZeroPoint Labs
interface IQuorumManager {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                           //
    //////////////////////////////////////////////////////////////

    /// @dev emitted when a new quorum is set for a specific chain
    /// @param srcChainId the chain id from which the message (payload) is sent
    /// @param quorum the minimum number of message bridges required for processing
    event QuorumSet(uint64 indexed srcChainId, uint256 indexed quorum);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev returns the required quorum for the srcChain & dstChain
    /// @param srcChainId_ is the chain id from which the message (payload) is sent
    /// @return quorum_ the minimum number of message bridges required for processing
    function getRequiredMessagingQuorum(uint64 srcChainId_) external view returns (uint256 quorum_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev allows inheriting contracts to set the messaging quorum for a specific sender chain
    /// @notice quorum is the number of extra ambs a message proof must go through and be validated
    /// @param srcChainId_ is the chain id from which the message (payload) is sent
    /// @param quorum_ the minimum number of message bridges required for processing
    /// NOTE: overriding child contracts should handle the sender validation & setting of message quorum
    function setRequiredMessagingQuorum(uint64 srcChainId_, uint256 quorum_) external;
}

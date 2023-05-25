// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface IQuorumManager {
    /// @dev allows inheriting contracts to set the messaging quorum for a specific sender chain
    /// @param srcChainId_ is the chain id from which the message (payload) is sent
    /// @param quorum_ the minimum number of message bridges required for processing
    /// NOTE: overriding child contracts should handle the sender validation & setting of message quorum
    function setRequiredMessagingQuorum(uint64 srcChainId_, uint256 quorum_) external;

    /// @dev returns the required quorum for the srcChain & dstChain
    /// @param srcChainId_ is the chain id from which the message (payload) is sent
    /// @return quorum_ the minimum number of message bridges required for processing
    function getRequiredMessagingQuorum(uint64 srcChainId_) external view returns (uint256 quorum_);
}

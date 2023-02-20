// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

/// @title IBridgeImpl
/// @author ZeroPoint Labs
/// @dev interface for arbitrary message bridge implementation
interface IBridgeImpl {
    error INVALID_CALLER();

    error DUPLICATE_PAYLOAD();

    /// @dev allows state registry to send message via implementation.
    /// @param dstChainId_ is the identifier of the destination chain
    /// @param message_ is the cross-chain message to be sent
    /// @param extraData_ is message bridge specific override information
    function dipatchPayload(
        uint256 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable;
}

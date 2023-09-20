// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

/// @title IBroadcastRegistry
/// @author ZeroPoint Labs
/// @dev is an helper for base state registry with broadcasting abilities.
interface IBroadcastRegistry {
    /// @dev allows core contracts to send payload to all configured destination chain.
    /// @param srcSender_ is the caller of the function (used for gas refunds).
    /// @param ambIds_ is the identifier of the arbitrary message bridge to be used
    /// @param message_ is the crosschain payload to be broadcasted
    /// @param extraData_ defines all the message bridge realted overrides
    function broadcastPayload(
        address srcSender_,
        uint8[] memory ambIds_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        payable;

    /// @dev allows ambs to write broadcasted payloads
    function receiveBroadcastPayload(uint64 srcChainId_, bytes memory message_) external;

    /// @dev allows previlaged actors to process broadcasted payloads
    /// @param payloadId_ is the identifier of the cross-chain payload
    function processPayload(uint256 payloadId_) external;
}

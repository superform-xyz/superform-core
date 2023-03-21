// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.19;

interface IMessageRecipient {
    /// @notice Handle an interchain message
    /// @param origin_ Domain ID of the chain from which the message came
    /// @param sender_ Address of the message sender on the origin chain as bytes32
    /// @param body_ Raw bytes content of message body
    function handle(
        uint32 origin_,
        bytes32 sender_,
        bytes calldata body_
    ) external;
}

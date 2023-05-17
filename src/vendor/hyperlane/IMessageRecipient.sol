// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/// @dev is imported from (https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/main/solidity/contracts/interfaces/IMessageRecipient.sol)
interface IMessageRecipient {
    /// @param _origin Domain ID of the chain from which the message came
    /// @param _sender Address of the message sender on the origin chain as bytes32
    /// @param _message Raw bytes content of message body
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external;
}

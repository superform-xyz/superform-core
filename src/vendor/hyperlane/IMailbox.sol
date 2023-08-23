// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

/// @dev is imported from
/// (https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/main/solidity/contracts/interfaces/IMailbox.sol)
interface IMailbox {
    // ============ Events ============
    /// @notice Emitted when a new message is dispatched via Hyperlane
    /// @param sender The address that dispatched the message
    /// @param destination The destination domain of the message
    /// @param recipient The message recipient address on `destination`
    /// @param message Raw bytes of message
    event Dispatch(address indexed sender, uint32 indexed destination, bytes32 indexed recipient, bytes message);

    /// @notice Emitted when a new message is dispatched via Hyperlane
    /// @param messageId The unique message identifier
    event DispatchId(bytes32 indexed messageId);

    /// @notice Emitted when a Hyperlane message is processed
    /// @param messageId The unique message identifier
    event ProcessId(bytes32 indexed messageId);

    /// @notice Emitted when a Hyperlane message is delivered
    /// @param origin The origin domain of the message
    /// @param sender The message sender address on `origin`
    /// @param recipient The address that handled the message
    event Process(uint32 indexed origin, bytes32 indexed sender, address indexed recipient);

    function localDomain() external view returns (uint32);

    function delivered(bytes32 messageId) external view returns (bool);

    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    )
        external
        returns (bytes32);

    function process(bytes calldata _metadata, bytes calldata _message) external;

    function count() external view returns (uint32);

    function root() external view returns (bytes32);

    function latestCheckpoint() external view returns (bytes32, uint32);
}

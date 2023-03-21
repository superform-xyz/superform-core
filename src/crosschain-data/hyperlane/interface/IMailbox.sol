// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.19;

/// @dev are inherited contracts for hyperlane message bridge
///
/// @notice see https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/6046ce68ef32b986d4ed813ad656d05497911815/solidity/interfaces/IMailbox.sol
/// for more information
interface IMailbox {
    function localDomain() external view returns (uint32);

    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external returns (bytes32);

    function process(bytes calldata _metadata, bytes calldata _message)
        external;

    function count() external view returns (uint32);

    function root() external view returns (bytes32);

    function latestCheckpoint() external view returns (bytes32, uint32);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.19;

/// @title IInterchainGasPaymaster
/// @notice Manages payments on a source chain to cover gas costs of relaying
/// messages to destination chains.
interface IInterchainGasPaymaster {
    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gas,
        address _refundAddress
    ) external payable;
}

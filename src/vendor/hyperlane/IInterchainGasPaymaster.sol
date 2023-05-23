// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/// @dev is imported from (https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/main/solidity/contracts/interfaces/IInterchainGasPaymaster.sol)
interface IInterchainGasPaymaster {
    /// @notice Emitted when a payment is made for a message's gas costs.
    /// @param messageId The ID of the message to pay for.
    /// @param gasAmount The amount of destination gas paid for.
    /// @param payment The amount of native tokens paid.
    event GasPayment(bytes32 indexed messageId, uint256 gasAmount, uint256 payment);

    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gasAmount,
        address _refundAddress
    ) external payable;

    function quoteGasPayment(uint32 _destinationDomain, uint256 _gasAmount) external view returns (uint256);
}

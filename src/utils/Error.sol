// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

library Error {
    /// @dev 0- is emitted when the chain id input is invalid.
    error INVALID_INPUT_CHAIN_ID();

    /// @dev - when msg.sender is not state registry
    error NOT_STATE_REGISTRY();

    /// @dev - when msg.sender is not protocol admin
    error NOT_PROTOCOL_ADMIN();

    /// @dev - when msg.sender is not super router
    error NOT_SUPER_ROUTER();

    /// @dev error thrown when the deployer is not the protocol admin
    error INVALID_DEPLOYER();

    /// @dev error thrown when the bridge tokens haven't arrived to destination
    error BRIDGE_TOKENS_PENDING();

    /// @dev error thrown when the safe gas param is incorrectly set
    error INVALID_GAS_OVERRIDE();

    /// @dev error thrown when address input is address 0
    error ZERO_ADDRESS();
}

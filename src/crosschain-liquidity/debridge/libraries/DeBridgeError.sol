// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

library DeBridgeError {
    /// @dev if permit envelop length is greater than zero
    error INVALID_PERMIT_ENVELOP();

    /// @dev if authority address is invalid
    error INVALID_DEBRIDGE_AUTHORITY();

    /// @dev if external call is allowed
    error INVALID_EXTRA_CALL_DATA();

    /// @dev if bridge data is invalid
    error INVALID_BRIDGE_DATA();

    /// @dev if swap token and bridge token mismatch
    error INVALID_BRIDGE_TOKEN();

    /// @dev debridge don't allow same chain swaps
    error ONLY_SWAPS_DISALLOWED();

    /// @dev if dst taker is restricted
    error INVALID_TAKER_DST();

    /// @dev if cancel beneficiary is invalid
    error INVALID_REFUND_ADDRESS();
}
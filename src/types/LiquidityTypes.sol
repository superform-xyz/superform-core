// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @dev contains all the common struct used for interchain token transfers.
struct LiqRequest {
    uint8 bridgeId;
    /// @dev what bridge to use to move tokens:  1 - cross chain bridge / 2 - inch implementation / 3 - 0x
    /// implementation
    bytes txData;
    /// @dev generated data (input token is already here)
    address token;
    /// @dev this is the input token (pre-swap, not necessarily the underlying token)
    uint256 amount;
    /// @dev in what amount token is bridged (already present inside txData
    uint256 nativeAmount;
    /// @dev currently this amount is used as msg.value in the txData call. For socket this should be at least amount +
    /// optionalNative(middlewareRequest) + optionalNative(bridgeRequest)
    bytes permit2data;
}

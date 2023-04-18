// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @dev contains all the common struct used for interchain token transfers.
struct LiqRequest {
    uint8 bridgeId; /// @dev what bridge to use to move tokens:  1 - cross chain bridge / 2 - inch implementation / 3 - 0x implementation
    bytes txData; /// @dev generated data
    address token; /// @dev what token to move from src to dst
    uint256 amount; /// @dev in what amount token is bridged
    uint256 nativeAmount;
    bytes permit2data;
}

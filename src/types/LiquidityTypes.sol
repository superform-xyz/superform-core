// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @dev contains all the common struct used for interchain token transfers.
struct LiqRequest {
    /// @dev what bridge to use to move tokens
    uint8 bridgeId;
    /// @dev generated data
    bytes txData;
    /// @dev input token. Relevant for withdraws especially to know when to update txData
    address token;
    /// @dev dstChainId = liqDstchainId for deposits. For withdraws it is the target chain id for where the underlying
    /// is to be delivered
    uint64 liqDstChainId;
    /// @dev currently this amount is used as msg.value in the txData call.
    uint256 nativeAmount;
}

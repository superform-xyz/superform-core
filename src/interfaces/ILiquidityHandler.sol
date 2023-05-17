// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title ILiquidityHandler
/// @author ZeroPoint Labs
/// @notice Interface for Liquidity Handler
interface ILiquidityHandler {
    /// @dev allows movement of tokens using socket.
    /// @param to_ address of the cross-chain token receiver
    /// @param txData_ socket transaction data generated off-chain
    /// @param token_ token to be moved
    /// @param allowanceTarget_ socket's implementation address to be approved
    /// @param amount_ token amount to be moved
    function dispatchTokens(
        address to_,
        bytes memory txData_,
        address token_,
        address allowanceTarget_,
        uint256 amount_
    ) external;
}

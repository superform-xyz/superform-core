// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title AcrossFacetPackedV3
/// @author LI.FI (https://li.fi)
/// @notice Provides functionality for bridging through Across in a gas-optimized way
/// @notice taken from LiFi contracts https://github.com/lifinance/contracts and stripped down to needs
/// @notice !WARNING ALREADY BLACKLISTED
/// @custom:version 1.0.0
contract AcrossFacetPackedV3 {
    /// Constructor ///

    /// External Methods ///

    /// @notice Bridges native tokens via Across (packed implementation)
    /// No params, all data will be extracted from manually encoded callData
    function startBridgeTokensViaAcrossV3NativePacked() external payable { }

    /// @notice Bridges native tokens via Across (minimal implementation)
    /// @param transactionId Custom transaction ID for tracking
    /// @param receiver Receiving wallet address
    /// @param destinationChainId Receiving chain
    /// @param receivingAssetId The address of the token to be received at destination chain
    /// @param outputAmount The amount to be received at destination chain (after fees)
    /// @param quoteTimestamp The timestamp of the Across quote that was used for this transaction
    /// @param fillDeadline The destination chain timestamp until which the order can be filled
    /// @param message Arbitrary data that can be used to pass additional information to the recipient along with the
    /// tokens
    function startBridgeTokensViaAcrossV3NativeMin(
        bytes32 transactionId,
        address receiver,
        uint256 destinationChainId,
        address receivingAssetId,
        uint256 outputAmount,
        uint32 quoteTimestamp,
        uint32 fillDeadline,
        bytes calldata message
    )
        external
        payable
    { }

    /// @notice Bridges ERC20 tokens via Across (packed implementation)
    /// No params, all data will be extracted from manually encoded callData
    function startBridgeTokensViaAcrossV3ERC20Packed() external { }

    /// @notice Bridges ERC20 tokens via Across (minimal implementation)
    /// @param transactionId Custom transaction ID for tracking
    /// @param sendingAssetId The address of the asset/token to be bridged
    /// @param inputAmount The amount to be bridged (including fees)
    /// @param receiver Receiving wallet address
    /// @param destinationChainId Receiving chain
    /// @param receivingAssetId The address of the token to be received at destination chain
    /// @param outputAmount The amount to be received at destination chain (after fees)
    /// @param quoteTimestamp The timestamp of the Across quote that was used for this transaction
    /// @param fillDeadline The destination chain timestamp until which the order can be filled
    /// @param message Arbitrary data that can be used to pass additional information to the recipient along with the
    /// tokens
    function startBridgeTokensViaAcrossV3ERC20Min(
        bytes32 transactionId,
        address sendingAssetId,
        uint256 inputAmount,
        address receiver,
        uint64 destinationChainId,
        address receivingAssetId,
        uint256 outputAmount,
        uint32 quoteTimestamp,
        uint32 fillDeadline,
        bytes calldata message
    )
        external
    {
        // Deposit assets
    }
}

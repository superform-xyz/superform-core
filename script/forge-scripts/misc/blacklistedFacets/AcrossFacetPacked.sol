// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title AcrossFacetPacked
/// @author LI.FI (https://li.fi)
/// @notice Provides functionality for bridging through Across in a gas-optimized way
/// @notice taken from LiFi contracts https://github.com/lifinance/contracts and stripped down to needs
/// @notice !WARNING ALREADY BLACKLISTED
/// @custom:version 1.0.0
contract AcrossFacetPacked {
    /// @notice Bridges native tokens via Across (packed implementation)
    /// No params, all data will be extracted from manually encoded callData
    function startBridgeTokensViaAcrossNativePacked() external payable { }

    /// @notice Bridges native tokens via Across (minimal implementation)
    /// @param transactionId Custom transaction ID for tracking
    /// @param receiver Receiving wallet address
    /// @param destinationChainId Receiving chain
    /// @param relayerFeePct The relayer fee in token percentage with 18 decimals
    /// @param quoteTimestamp The timestamp associated with the suggested fee
    /// @param message Arbitrary data that can be used to pass additional information to the recipient along with the
    /// tokens
    /// @param maxCount Used to protect the depositor from frontrunning to guarantee their quote remains valid
    function startBridgeTokensViaAcrossNativeMin(
        bytes32 transactionId,
        address receiver,
        uint256 destinationChainId,
        int64 relayerFeePct,
        uint32 quoteTimestamp,
        bytes calldata message,
        uint256 maxCount
    )
        external
        payable
    { }

    /// @notice Bridges ERC20 tokens via Across (packed implementation)
    /// No params, all data will be extracted from manually encoded callData
    function startBridgeTokensViaAcrossERC20Packed() external payable { }

    /// @notice Bridges ERC20 tokens via Across (minimal implementation)
    /// @param transactionId Custom transaction ID for tracking
    /// @param sendingAssetId The address of the asset/token to be bridged
    /// @param minAmount The amount to be bridged
    /// @param receiver Receiving wallet address
    /// @param destinationChainId Receiving chain
    /// @param relayerFeePct The relayer fee in token percentage with 18 decimals
    /// @param quoteTimestamp The timestamp associated with the suggested fee
    /// @param message Arbitrary data that can be used to pass additional information to the recipient along with the
    /// tokens
    /// @param maxCount Used to protect the depositor from frontrunning to guarantee their quote remains valid
    function startBridgeTokensViaAcrossERC20Min(
        bytes32 transactionId,
        address sendingAssetId,
        uint256 minAmount,
        address receiver,
        uint64 destinationChainId,
        int64 relayerFeePct,
        uint32 quoteTimestamp,
        bytes calldata message,
        uint256 maxCount
    )
        external
        payable
    { }
}

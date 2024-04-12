// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title AmarokFacetPacked
/// @author LI.FI (https://li.fi)
/// @notice Provides functionality for bridging through Amarok in a gas-optimized way
/// @notice taken from LiFi contracts https://github.com/lifinance/contracts and stripped down to needs
/// @notice !WARNING ALREADY BLACKLISTED
/// @custom:version 1.0.0
contract AmarokFacetPacked {
    /// @notice Bridges ERC20 tokens via Amarok
    /// No params, all data will be extracted from manually encoded callData
    function startBridgeTokensViaAmarokERC20PackedPayFeeWithAsset() external { }

    function startBridgeTokensViaAmarokERC20PackedPayFeeWithNative() external payable { }

    /// @notice Bridges ERC20 tokens via Amarok
    /// @param transactionId Custom transaction ID for tracking
    /// @param receiver Receiving wallet address
    /// @param sendingAssetId Address of the source asset to bridge
    /// @param minAmount Amount of the source asset to bridge
    /// @param destChainDomainId The Amarok-specific domainId of the destination chain
    /// @param slippageTol Maximum acceptable slippage in BPS. For example, a value of 30 means 0.3% slippage
    /// @param relayerFee The amount of relayer fee the tx called xcall with
    function startBridgeTokensViaAmarokERC20MinPayFeeWithAsset(
        bytes32 transactionId,
        address receiver,
        address sendingAssetId,
        uint256 minAmount,
        uint32 destChainDomainId,
        uint256 slippageTol,
        uint256 relayerFee
    )
        external
    { }

    /// @notice Bridges ERC20 tokens via Amarok
    /// @param transactionId Custom transaction ID for tracking
    /// @param receiver Receiving wallet address
    /// @param sendingAssetId Address of the source asset to bridge
    /// @param minAmount Amount of the source asset to bridge
    /// @param destChainDomainId The Amarok-specific domainId of the destination chain
    /// @param slippageTol Maximum acceptable slippage in BPS. For example, a value of 30 means 0.3% slippage
    function startBridgeTokensViaAmarokERC20MinPayFeeWithNative(
        bytes32 transactionId,
        address receiver,
        address sendingAssetId,
        uint256 minAmount,
        uint32 destChainDomainId,
        uint256 slippageTol
    )
        external
        payable
    { }
}

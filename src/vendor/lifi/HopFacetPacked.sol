// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @title Hop Facet (Optimized for Rollups)
/// @author LI.FI (https://li.fi)
/// @notice Provides functionality for bridging through Hop
/// @notice taken from LiFi contracts https://github.com/lifinance/contracts and stripped down to needs
/// @custom:version 1.0.6
contract HopFacetPacked {
    /// @notice Bridges Native tokens via Hop Protocol from L2
    /// No params, all data will be extracted from manually encoded callData
    function startBridgeTokensViaHopL2NativePacked() external payable { }

    /// @notice Bridges Native tokens via Hop Protocol from L2
    /// @param transactionId Custom transaction ID for tracking
    /// @param receiver Receiving wallet address
    /// @param destinationChainId Receiving chain
    /// @param bonderFee Fees payed to hop bonder
    /// @param amountOutMin Source swap minimal accepted amount
    /// @param destinationAmountOutMin Destination swap minimal accepted amount
    /// @param destinationDeadline Destination swap maximal time
    /// @param hopBridge Address of the Hop L2_AmmWrapper
    function startBridgeTokensViaHopL2NativeMin(
        bytes8 transactionId,
        address receiver,
        uint256 destinationChainId,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline,
        address hopBridge
    )
        external
        payable
    { }

    /// @notice Bridges ERC20 tokens via Hop Protocol from L2
    /// No params, all data will be extracted from manually encoded callData
    function startBridgeTokensViaHopL2ERC20Packed() external { }

    /// @notice Bridges ERC20 tokens via Hop Protocol from L2
    /// @param transactionId Custom transaction ID for tracking
    /// @param receiver Receiving wallet address
    /// @param destinationChainId Receiving chain
    /// @param sendingAssetId Address of the source asset to bridge
    /// @param minAmount Amount of the source asset to bridge
    /// @param bonderFee Fees payed to hop bonder
    /// @param amountOutMin Source swap minimal accepted amount
    /// @param destinationAmountOutMin Destination swap minimal accepted amount
    /// @param destinationDeadline Destination swap maximal time
    /// @param hopBridge Address of the Hop L2_AmmWrapper
    function startBridgeTokensViaHopL2ERC20Min(
        bytes8 transactionId,
        address receiver,
        uint256 destinationChainId,
        address sendingAssetId,
        uint256 minAmount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline,
        address hopBridge
    )
        external
    { }

    /// @notice Bridges Native tokens via Hop Protocol from L1
    /// No params, all data will be extracted from manually encoded callData
    function startBridgeTokensViaHopL1NativePacked() external payable { }

    /// @notice Bridges Native tokens via Hop Protocol from L1
    /// @param transactionId Custom transaction ID for tracking
    /// @param receiver Receiving wallet address
    /// @param destinationChainId Receiving chain
    /// @param destinationAmountOutMin Destination swap minimal accepted amount
    /// @param relayer needed for gas spikes
    /// @param relayerFee needed for gas spikes
    /// @param hopBridge Address of the Hop Bridge
    function startBridgeTokensViaHopL1NativeMin(
        bytes8 transactionId,
        address receiver,
        uint256 destinationChainId,
        uint256 destinationAmountOutMin,
        address relayer,
        uint256 relayerFee,
        address hopBridge
    )
        external
        payable
    { }

    /// @notice Bridges Native tokens via Hop Protocol from L1
    /// No params, all data will be extracted from manually encoded callData
    function startBridgeTokensViaHopL1ERC20Packed() external payable { }

    /// @notice Bridges ERC20 tokens via Hop Protocol from L1
    /// @param transactionId Custom transaction ID for tracking
    /// @param receiver Receiving wallet address
    /// @param destinationChainId Receiving chain
    /// @param sendingAssetId Address of the source asset to bridge
    /// @param minAmount Amount of the source asset to bridge
    /// @param destinationAmountOutMin Destination swap minimal accepted amount
    /// @param relayer needed for gas spikes
    /// @param relayerFee needed for gas spikes
    /// @param hopBridge Address of the Hop Bridge
    function startBridgeTokensViaHopL1ERC20Min(
        bytes8 transactionId,
        address receiver,
        uint256 destinationChainId,
        address sendingAssetId,
        uint256 minAmount,
        uint256 destinationAmountOutMin,
        address relayer,
        uint256 relayerFee,
        address hopBridge
    )
        external
    { }
}

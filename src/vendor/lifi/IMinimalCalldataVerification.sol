// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title Minimal Calldata Verification
/// @author LI.FI (https://li.fi)
/// @notice Provides functionality for verifying calldata
/// @notice upgraded to solidity 0.8.19 and adapted from CalldataVerificationFacet and LibBytes without any changes to
/// used functions
/// @notice taken from LiFi contracts https://github.com/lifinance/contracts
/// @custom:version 1.1.0
interface IMinimalCalldataVerification {
    /// @notice Extracts the main parameters from the calldata
    /// @param data The calldata to extract the main parameters from
    /// @return bridge The bridge extracted from the calldata
    /// @return sendingAssetId The sending asset id extracted from the calldata
    /// @return receiver The receiver extracted from the calldata
    /// @return amount The min amountfrom the calldata
    /// @return destinationChainId The destination chain id extracted from the calldata
    /// @return hasSourceSwaps Whether the calldata has source swaps
    /// @return hasDestinationCall Whether the calldata has a destination call
    function extractMainParameters(bytes calldata data)
        external
        pure
        returns (
            string memory bridge,
            address sendingAssetId,
            address receiver,
            uint256 amount,
            uint256 destinationChainId,
            bool hasSourceSwaps,
            bool hasDestinationCall
        );

    /// @notice Extracts the generic swap parameters from the calldata
    /// @param data The calldata to extract the generic swap parameters from
    /// @return sendingAssetId The sending asset id extracted from the calldata
    /// @return amount The amount extracted from the calldata
    /// @return receiver The receiver extracted from the calldata
    /// @return receivingAssetId The receiving asset id extracted from the calldata
    /// @return receivingAmount The receiving amount extracted from the calldata
    function extractGenericSwapParameters(bytes calldata data)
        external
        pure
        returns (
            address sendingAssetId,
            uint256 amount,
            address receiver,
            address receivingAssetId,
            uint256 receivingAmount
        );
}

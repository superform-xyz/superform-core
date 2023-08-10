/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title ISuperTransmuter
/// @author Zeropoint Labs.
/// @dev interface for Super Transmuter
interface ISuperTransmuter {
    /// @dev anyone can register a transmuter for an existent superForm
    /// @notice this overrides registerTransmuter from original transmuter implementation so that users cannot insert name, symbol, and decimals
    /// @param superFormId the superForm to register a transmuter for
    function registerTransmuter(uint256 superFormId) external returns (address);
}

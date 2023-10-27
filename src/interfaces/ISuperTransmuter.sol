/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { IStateSyncer } from "src/interfaces/IStateSyncer.sol";

/// @title ISuperTransmuter
/// @author Zeropoint Labs.
/// @dev interface for Super Transmuter
interface ISuperTransmuter is IStateSyncer {
    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev anyone can register a transmuter for an existent superform
    /// @notice it uses WormholeSR implementation by default and broadcast to all chains
    /// @notice this overrides registerTransmuter from original transmuter implementation so that users cannot insert
    /// name, symbol, and decimals
    /// @param superformId the superform to register a transmuter for
    function registerTransmuter(uint256 superformId) external payable returns (address);

    /// @dev allows sync register new superform ids using broadcast state registry
    /// @param data_ is the crosschain payload
    function stateSyncBroadcast(bytes memory data_) external payable;
}

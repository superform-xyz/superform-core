/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { IStateSyncer } from "src/interfaces/IStateSyncer.sol";

/// @title ISuperTransmuter
/// @author Zeropoint Labs.
/// @dev interface for Super Transmuter
interface ISuperTransmuter is IStateSyncer {
    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev anyone can register a transmuter for an existent superform
    /// @notice this overrides registerTransmuter from original transmuter implementation so that users cannot insert
    /// name, symbol, and decimals
    /// @param superformId the superform to register a transmuter for
    /// @param extraData_ is an optional param to broadcast changes to all chains
    function registerTransmuter(uint256 superformId, bytes memory extraData_) external returns (address);

    /// @dev allows sync register new superform ids using broadcast state registry
    /// @param data_ is the crosschain payload
    function stateSyncBroadcast(bytes memory data_) external payable;
}

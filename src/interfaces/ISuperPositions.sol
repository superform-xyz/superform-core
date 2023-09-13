/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import { IStateSyncer } from "./IStateSyncer.sol";

/// @title ISuperPositions
/// @author Zeropoint Labs.
/// @dev interface for Super Positions
interface ISuperPositions is IStateSyncer {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when a dynamic uri is updated
    event DynamicURIUpdated(string oldURI, string newURI, bool frozen);

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev sets the dynamic uri for NFT
    /// @param dynamicURI_ is the dynamic uri of the NFT
    /// @param freeze_ is to prevent updating the metadata once migrated to IPFS
    function setDynamicURI(string memory dynamicURI_, bool freeze_) external;
}

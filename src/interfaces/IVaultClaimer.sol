// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title IVaultClaimer
/// @author Zeropoint Labs
interface IVaultClaimer {
    //////////////////////////////////////////////////////////////
    //                      ERRORS                              //
    //////////////////////////////////////////////////////////////
    error AlreadyClaimed();

    //////////////////////////////////////////////////////////////
    //                      EVENTS                              //
    //////////////////////////////////////////////////////////////
    event Claimed(address indexed claimer, string protocolId);

    //////////////////////////////////////////////////////////////
    //                      EXTERNAL FUNCTIONS                  //
    //////////////////////////////////////////////////////////////

    /// @notice helps users claim ownership of a protocol id
    /// @param protocolId_ unique identifier of the protocol to claim ownership
    /// @dev actual validation of ownership happens offchain
    /// calling this function, triggers ownership verification
    function claimProtocolOwnership(string calldata protocolId_) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title LiFi Validator Interface
/// @author Zeropoint Labs
interface ISocketValidator {
    //////////////////////////////////////////////////////////////
    //                      EVENTS                              //
    //////////////////////////////////////////////////////////////
    ///@dev emitted when a route id is added to the blacklist
    event AddedToBlacklist(uint256 indexed id);

    ///@dev emitted when a route id is removed from the blacklist
    event RemovedFromBlacklist(uint256 indexed id);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL  FUNCTIONS                         //
    //////////////////////////////////////////////////////////////

    /// @dev Adds a route id to the blacklist
    /// @param id_ the route id to add
    function addToBlacklist(uint256 id_) external;

    /// @dev Removes a route id from the blacklist
    /// @param id_ the route id to remove
    function removeFromBlacklist(uint256 id_) external;
    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev Checks if given route id is blacklisted
    /// @param id_ the route id to check
    /// @return blacklisted if the route is blacklisted
    function isRouteBlacklisted(uint256 id_) external view returns (bool blacklisted);
}

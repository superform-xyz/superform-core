// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title LiFi Validator Interface
/// @author Zeropoint Labs
interface ISocketValidator {
    //////////////////////////////////////////////////////////////
    //              EXTERNAL  FUNCTIONS                         //
    //////////////////////////////////////////////////////////////

    /// @dev Adds a route id to the blacklist
    /// @param id_ the selector to add
    function addToBlacklist(uint256 id_) external;

    /// @dev Removes a route id from the blacklist
    /// @param id_ the selector to remove
    function removeFromBlacklist(uint256 id_) external;
    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev Checks if given route id is blacklisted
    /// @param chainId_ the chain to check
    /// @param id_ the route id to check
    /// @return blacklisted if selector is blacklisted
    function isRouteBlacklisted(uint64 chainId_, uint256 id_) external view returns (bool blacklisted);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title ISuperformRouterLike
/// @dev Interface for abstract SuperformRouter with payloadIds getter
/// @author Zeropoint Labs
interface ISuperformRouterLike {
    function payloadIds() external view returns (uint256);
}

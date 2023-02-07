// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.17;

import "./IAaveMining.sol";

/// @notice IMultiFeeDistribution - protocol dependent reward claiming systems interface
/// @dev Extend as you see fit. Keeps the functionality of original AAVE v2 protocol.
interface IMultiFeeDistribution is IAaveMining {
    function getReward() external;

    function exit() external;
}

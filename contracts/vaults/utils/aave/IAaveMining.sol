// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.14;

interface IAaveMining {
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);
}

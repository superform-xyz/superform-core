// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

interface IPositionsSplitter {
    function wrapFor(address user, uint256 amount) external;

    function registerWrapper(
        uint256 vaultId,
        string memory name,
        string memory symbol
    ) external;
}

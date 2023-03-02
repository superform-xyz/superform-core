// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface IPositionsSplitter {
    function wrapFor(address user_, uint256 amount_) external;

    function registerWrapper(
        uint256 vaultId_,
        string memory name_,
        string memory symbol_
    ) external;
}

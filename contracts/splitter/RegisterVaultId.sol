// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import {IPositionsSplitter} from "../interfaces/IPositionsSplitter.sol";

/// @title Positions Splitter
/// @dev Implementation of managment logic inside of SuperRouter, causes it to go over contract size limit.
/// @dev Ops like registering external modules should be modularized themselves.
abstract contract RegisterVautlId {
    IPositionsSplitter public positionsSplitter;

    function setSpliter(address impl) external {
        positionsSplitter = IPositionsSplitter(impl);
    }

    function addWrapper(
        uint256 vaultId,
        string memory name,
        string memory symbol
    ) external {
        /// @dev We should release more control here. Read name and symbol directly from the Vault.
        positionsSplitter.registerWrapper(vaultId, name, symbol);
    }
}

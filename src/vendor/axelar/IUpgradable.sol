// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from "./IOwnable.sol";
import { IImplementation } from "./IImplementation.sol";

// General interface for upgradable contracts
interface IUpgradable is IOwnable, IImplementation {
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();

    event Upgraded(address indexed newImplementation);

    function implementation() external view returns (address);

    function upgrade(address newImplementation, bytes32 newImplementationCodeHash, bytes calldata params) external;
}

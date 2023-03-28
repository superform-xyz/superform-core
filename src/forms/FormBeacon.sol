// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {UpgradeableBeacon} from "@openzeppelin-contracts/contracts/proxy/beacon/UpgradeableBeacon.sol";

/// @title FormBeacon
/// @notice The Beacon for any given form.
contract FormBeacon {
    UpgradeableBeacon immutable beacon;

    address public formLogic;

    constructor(address _formLogic) {
        beacon = new UpgradeableBeacon(_formLogic);
        formLogic = _formLogic;
    }

    function update(address _formLogic) public {
        beacon.upgradeTo(_formLogic);
        formLogic = _formLogic;
    }

    function implementation() public view returns (address) {
        return beacon.implementation();
    }
}

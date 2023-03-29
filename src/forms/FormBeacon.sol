// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {UpgradeableBeacon} from "@openzeppelin-contracts/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {AccessControl} from "@openzeppelin-contracts/contracts/access/AccessControl.sol";

/// @title FormBeacon
/// @notice The Beacon for any given form.
contract FormBeacon is AccessControl {
    UpgradeableBeacon immutable beacon;

    address public formLogic;

    constructor(address _formLogic) {
        beacon = new UpgradeableBeacon(_formLogic);
        formLogic = _formLogic;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function update(address _formLogic) external onlyRole(DEFAULT_ADMIN_ROLE) {
        beacon.upgradeTo(_formLogic);
        formLogic = _formLogic;
    }

    function implementation() external view returns (address) {
        return beacon.implementation();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {UpgradeableBeacon} from "openzeppelin-contracts/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {Error} from "../utils/Error.sol";

/// @title FormBeacon
/// @notice The Beacon for any given form.
contract FormBeacon {
    /*///////////////////////////////////////////////////////////////
                    State Variables
    //////////////////////////////////////////////////////////////*/

    ISuperRegistry public immutable superRegistry;

    UpgradeableBeacon immutable beacon;

    /// @notice chainId represents unique chain id for each chains.
    uint16 public immutable chainId;

    address public formLogic;

    modifier onlyProtocolAdmin() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(
                msg.sender
            )
        ) revert Error.NOT_PROTOCOL_ADMIN();
        _;
    }

    /// @param chainId_              SuperForm chain id
    /// @param superRegistry_        SuperForm registry contract
    /// @param formLogic_            The initial form logic contract
    constructor(uint16 chainId_, address superRegistry_, address formLogic_) {
        chainId = chainId_;
        superRegistry = ISuperRegistry(superRegistry_);
        beacon = new UpgradeableBeacon(formLogic_);
        formLogic = formLogic_;
    }

    function update(address formLogic_) external onlyProtocolAdmin {
        beacon.upgradeTo(formLogic_);
        formLogic = formLogic_;
    }

    function implementation() external view returns (address) {
        return beacon.implementation();
    }
}

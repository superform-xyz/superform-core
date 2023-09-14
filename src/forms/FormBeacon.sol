// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import { UpgradeableBeacon } from "openzeppelin-contracts/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { IFormBeacon } from "../interfaces/IFormBeacon.sol";
import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";
import { Error } from "../utils/Error.sol";

/// @title FormBeacon
/// @notice The Beacon for any given form.
/// @dev Superforms follow the proxy beacon pattern, with each of the same form kind pointing to the same implementation
/// @dev This allows us to pause all superforms of a given form kind or upgrade them in one go
contract FormBeacon is IFormBeacon {
    /*///////////////////////////////////////////////////////////////
                    State Variables
    //////////////////////////////////////////////////////////////*/

    ISuperRegistry public immutable superRegistry;

    UpgradeableBeacon immutable beacon;

    address public formLogic;

    uint256 public paused = 1;

    modifier onlySuperformFactory() {
        if (superRegistry.getAddress(keccak256("SUPERFORM_FACTORY")) != msg.sender) {
            revert Error.NOT_SUPERFORM_FACTORY();
        }
        _;
    }

    /// @param superRegistry_        Superform registry contract
    /// @param formLogic_            The initial form logic contract
    constructor(address superRegistry_, address formLogic_) {
        superRegistry = ISuperRegistry(superRegistry_);
        beacon = new UpgradeableBeacon(formLogic_);
        formLogic = formLogic_;
    }

    /// @inheritdoc IFormBeacon
    function update(address formLogic_) external override onlySuperformFactory {
        beacon.upgradeTo(formLogic_);
        address oldLogic = formLogic;
        formLogic = formLogic_;

        emit FormLogicUpdated(oldLogic, formLogic_);
    }

    /// @inheritdoc IFormBeacon
    function changePauseStatus(uint256 paused_) external override onlySuperformFactory {
        paused = paused_;
        emit FormBeaconPaused(paused_);
    }

    /// @inheritdoc IFormBeacon
    function implementation() external view override returns (address) {
        return beacon.implementation();
    }
}

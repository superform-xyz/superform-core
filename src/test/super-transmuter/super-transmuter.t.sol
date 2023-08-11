// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "../utils/BaseSetup.sol";
import "../utils/Utilities.sol";

import {DataLib} from "../../libraries/DataLib.sol";
import {Transmuter} from "ERC1155A/transmuter/Transmuter.sol";
import {SuperTransmuter} from "../../SuperTransmuter.sol";
import {Error} from "../../utils/Error.sol";
import {VaultMock} from "../mocks/VaultMock.sol";

contract SuperTransmuterTest is BaseSetup {
    SuperTransmuter public superTransmuter;
    address formImplementation;
    address vault;
    uint32 formBeaconId = 4;

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
        superTransmuter = SuperTransmuter(payable(getContract(ETH, "SuperTransmuter")));

        address superRegistry = getContract(ETH, "SuperRegistry");

        formImplementation = address(new ERC4626Form(superRegistry));
        vault = getContract(ETH, VAULT_NAMES[0][0]);
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).addFormBeacon(formImplementation, formBeaconId, salt);
    }

    function test_registerTransmuter() public {
        (uint256 superformId, ) = SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(
            formBeaconId,
            vault
        );
        superTransmuter.registerTransmuter(superformId);
    }

    function test_InvalidSuperFormAddress() public {
        uint256 invalidSuperFormId = DataLib.packSuperform(address(0), 4, ETH);
        vm.expectRevert(Error.NOT_SUPERFORM.selector);
        superTransmuter.registerTransmuter(invalidSuperFormId);
    }

    function test_InvalidFormBeacon() public {
        uint256 invalidSuperFormId = DataLib.packSuperform(address(0x777), 0, ETH);
        vm.expectRevert(Error.FORM_DOES_NOT_EXIST.selector);
        superTransmuter.registerTransmuter(invalidSuperFormId);
    }

    function test_alreadyRegistered() public {
        (uint256 superformId, ) = SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(
            formBeaconId,
            vault
        );
        superTransmuter.registerTransmuter(superformId);
        vm.expectRevert(Transmuter.TRANSMUTER_ALREADY_REGISTERED.selector);

        superTransmuter.registerTransmuter(superformId);
    }
}

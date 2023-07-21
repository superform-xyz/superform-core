// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {ISuperFormFactory} from "../../interfaces/ISuperFormFactory.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {SuperFormFactory} from "../../SuperFormFactory.sol";
import {FactoryStateRegistry} from "../../crosschain-data/extensions/FactoryStateRegistry.sol";
import {ERC4626Form} from "../../forms/ERC4626Form.sol";
import {ERC4626TimelockForm} from "../../forms/ERC4626TimelockForm.sol";
import "../utils/BaseSetup.sol";
import "../utils/Utilities.sol";
import {Error} from "../../utils/Error.sol";

contract SuperFormFactoryUpdateFormTest is BaseSetup {

    uint64 internal chainId = ETH;

    event FormLogicUpdated(address indexed oldLogic, address indexed newLogic);

    function setUp() public override {
        super.setUp();
    }

    function test_updateFormBeaconLogic() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        // @dev Deploying Forms
        address formImplementation1 = address(new ERC4626Form(superRegistry));
        uint32 formBeaconId = 0;


        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(
            formImplementation1,
            formBeaconId,
            salt
        );

        // @dev Updating The Form To A New Implementation
        address formImplementation2 = address(new ERC4626TimelockForm(superRegistry));

        vm.expectEmit();
        emit FormLogicUpdated(formImplementation1, formImplementation2);

        SuperFormFactory(getContract(chainId, "SuperFormFactory")).updateFormBeaconLogic(
            formBeaconId,
            formImplementation2
        );
    }

    function test_revert_updateFormBeaconLogic_ZERO_ADDRESS() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        // @dev Deploying Forms
        address formImplementation1 = address(new ERC4626Form(superRegistry));
        uint32 formBeaconId = 0;


        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(
            formImplementation1,
            formBeaconId,
            salt
        );

        // @dev Updating The Form To A New Implementation With Zero
        address formImplementation2 = address(0);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).updateFormBeaconLogic(
            formBeaconId,
            formImplementation2
        );
    }

    function test_revert_updateFormBeaconLogic_ERC165_UNSUPPORTED() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        // @dev Deploying Forms
        address formImplementation1 = address(new ERC4626Form(superRegistry));
        uint32 formBeaconId = 0;


        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(
            formImplementation1,
            formBeaconId,
            salt
        );

        // @dev Updating The Form To A New Implementation Which Is Not A ERC165 Supported
        address formImplementation2 = address(0x1);

        vm.expectRevert(Error.ERC165_UNSUPPORTED.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).updateFormBeaconLogic(
            formBeaconId,
            formImplementation2
        );
    }

    function test_revert_updateFormBeaconLogic_INVALID_FORM_ID() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        // @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formBeaconId1 = 0;


        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(
            formImplementation,
            formBeaconId1,
            salt
        );

        // @dev Updating The Form With Invalid Beacon
        uint32 formBeaconId2 = 9999;

        vm.expectRevert(Error.INVALID_FORM_ID.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).updateFormBeaconLogic(
            formBeaconId2,
            formImplementation
        );
    }
}
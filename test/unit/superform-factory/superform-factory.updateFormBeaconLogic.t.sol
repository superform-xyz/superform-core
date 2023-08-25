// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { SuperformFactory } from "src/SuperformFactory.sol";
import { ERC4626Form } from "src/forms/ERC4626Form.sol";
import { ERC4626FormInterfaceNotSupported } from "test/mocks/InterfaceNotSupported/ERC4626InterFaceNotSupported.sol";
import { ERC4626TimelockForm } from "src/forms/ERC4626TimelockForm.sol";
import "test/utils/BaseSetup.sol";
import { Error } from "src/utils/Error.sol";

contract SuperformFactoryUpdateFormTest is BaseSetup {
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
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(
            formImplementation1, formBeaconId, salt
        );

        // @dev Updating The Form To A New Implementation
        address formImplementation2 = address(new ERC4626TimelockForm(superRegistry));

        vm.expectEmit();
        emit FormLogicUpdated(formImplementation1, formImplementation2);

        SuperformFactory(getContract(chainId, "SuperformFactory")).updateFormBeaconLogic(
            formBeaconId, formImplementation2
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
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(
            formImplementation1, formBeaconId, salt
        );

        // @dev Updating The Form To A New Implementation With Zero
        address formImplementation2 = address(0);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).updateFormBeaconLogic(
            formBeaconId, formImplementation2
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
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(
            formImplementation1, formBeaconId, salt
        );

        // @dev Updating The Form To A New Implementation Which Is Not A ERC165 Supported
        address formImplementation2 = address(0x1);

        vm.expectRevert(Error.ERC165_UNSUPPORTED.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).updateFormBeaconLogic(
            formBeaconId, formImplementation2
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
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(
            formImplementation, formBeaconId1, salt
        );

        // @dev Updating The Form With Invalid Beacon
        uint32 formBeaconId2 = 9999;

        vm.expectRevert(Error.INVALID_FORM_ID.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).updateFormBeaconLogic(
            formBeaconId2, formImplementation
        );
    }

    function test_revert_updateFormBeaconLogic_FORM_INTERFACE_UNSUPPORTED() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        // @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formBeaconId = 0;

        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(formImplementation, formBeaconId, salt);

        address formImplementation_interface_unsupported = address(new ERC4626FormInterfaceNotSupported(superRegistry));

        vm.expectRevert(Error.FORM_INTERFACE_UNSUPPORTED.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).updateFormBeaconLogic(
            formBeaconId, formImplementation_interface_unsupported
        );
    }
}

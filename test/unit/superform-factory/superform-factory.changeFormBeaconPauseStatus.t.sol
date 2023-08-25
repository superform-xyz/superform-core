// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { SuperformFactory } from "src/SuperformFactory.sol";
import { FactoryStateRegistry } from "src/crosschain-data/extensions/FactoryStateRegistry.sol";
import { ERC4626Form } from "src/forms/ERC4626Form.sol";
import "test/utils/BaseSetup.sol";
import { Error } from "src/utils/Error.sol";

contract SuperformFactoryChangePauseTest is BaseSetup {
    uint64 internal chainId = ETH;

    event FormLogicUpdated(address indexed oldLogic, address indexed newLogic);

    function setUp() public override {
        super.setUp();
    }

    function test_changeFormBeaconPauseStatus() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation1 = address(new ERC4626Form(superRegistry));
        uint32 formBeaconId = 0;

        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(
            formImplementation1, formBeaconId, salt
        );

        SuperformFactory(getContract(chainId, "SuperformFactory")).changeFormBeaconPauseStatus{ value: 800 * 10 ** 18 }(
            formBeaconId, true, generateBroadcastParams(5, 2)
        );

        bool status =
            SuperformFactory(payable(getContract(chainId, "SuperformFactory"))).isFormBeaconPaused(formBeaconId);

        assertEq(status, true);
    }

    function test_changeFormBeaconPauseStatusNoBroadcast() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation1 = address(new ERC4626Form(superRegistry));
        uint32 formBeaconId = 0;

        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(
            formImplementation1, formBeaconId, salt
        );

        SuperformFactory(getContract(chainId, "SuperformFactory")).changeFormBeaconPauseStatus{ value: 800 * 10 ** 18 }(
            formBeaconId, true, ""
        );

        bool status =
            SuperformFactory(payable(getContract(chainId, "SuperformFactory"))).isFormBeaconPaused(formBeaconId);

        assertEq(status, true);
    }

    function test_revert_changeFormBeaconPauseStatus_INVALID_FORM_ID() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation1 = address(new ERC4626Form(superRegistry));
        uint32 formBeaconId = 0;
        uint32 formBeaconId_invalid = 999;

        /// @dev Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(
            formImplementation1, formBeaconId, salt
        );

        /// @dev Invalid Form Beacon For Pausing
        vm.expectRevert(Error.INVALID_FORM_ID.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).changeFormBeaconPauseStatus{ value: 800 * 10 ** 18 }(
            formBeaconId_invalid, true, generateBroadcastParams(5, 2)
        );
    }
}

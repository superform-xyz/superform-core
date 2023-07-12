// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {ISuperFormFactory} from "src/interfaces/ISuperFormFactory.sol";
import {ISuperRegistry} from "src/interfaces/ISuperRegistry.sol";
import {SuperFormFactory} from "src/SuperFormFactory.sol";
import {FactoryStateRegistry} from "src/crosschain-data/extensions/FactoryStateRegistry.sol";
import {ERC4626Form} from "src/forms/ERC4626Form.sol";
import {ERC4626TimelockForm} from "src/forms/ERC4626TimelockForm.sol";
import "src/test/utils/BaseSetup.sol";
import "src/test/utils/Utilities.sol";
import {Error} from "src/utils/Error.sol";
import "src/utils/DataPacking.sol";

contract SuperFormFactoryTest is BaseSetup {

    uint64 internal chainId = ETH;

    event FormLogicUpdated(address indexed oldLogic, address indexed newLogic);

    function setUp() public override {
        super.setUp();
    }

    function test_changeFormBeaconPauseStatus() public {
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

        SuperFormFactory(getContract(chainId, "SuperFormFactory")).changeFormBeaconPauseStatus{value: 800 * 10 ** 18}(
            formBeaconId,
            true,
            generateBroadcastParams(5, 2)
        );

        bool status = SuperFormFactory(payable(getContract(chainId, "SuperFormFactory")))
                    .isFormBeaconPaused(formBeaconId);

        assertEq(status, true);
    }

    function xtest_changeFormBeaconPauseStatus() public {
        vm.startPrank(deployer);
        vm.selectFork(FORKS[chainId]);

        uint32 formBeaconId = 1;

        vm.recordLogs();
        /// setting the status as false in chain id = ETH & broadcasting it
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).changeFormBeaconPauseStatus{value: 800 * 10 ** 18}(
            formBeaconId,
            true,
            generateBroadcastParams(5, 2)
        );
        _broadcastPayloadHelper(chainId, vm.getRecordedLogs());

        /// process the payload across all other chains
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] != chainId) {
                vm.selectFork(FORKS[chainIds[i]]);

                bool statusBefore = SuperFormFactory(payable(getContract(chainIds[i], "SuperFormFactory")))
                    .isFormBeaconPaused(1);

                FactoryStateRegistry(payable(getContract(chainIds[i], "FactoryStateRegistry"))).processPayload(31, "");

                bool statusAfter = SuperFormFactory(payable(getContract(chainIds[i], "SuperFormFactory")))
                    .isFormBeaconPaused(1);

                /// assert status update before and after processing the payload
                assertEq(statusBefore, false);
                assertEq(statusAfter, true);
            }
        }
    }

    function test_revert_changeFormBeaconPauseStatus_INVALID_FORM_ID() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        // @dev Deploying Forms
        address formImplementation1 = address(new ERC4626Form(superRegistry));
        uint32 formBeaconId = 0;
        uint32 formBeaconId_invalid = 999;


        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(
            formImplementation1,
            formBeaconId,
            salt
        );

        // @dev Invalid Form Beacon For Pausing
        vm.expectRevert(Error.INVALID_FORM_ID.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).changeFormBeaconPauseStatus{value: 800 * 10 ** 18}(
            formBeaconId_invalid,
            true,
            generateBroadcastParams(5, 2)
        );
    }
}
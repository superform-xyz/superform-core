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

contract SuperFormFactoryChangePauseTest is BaseSetup {

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

        /// @dev Deploying Forms
        address formImplementation1 = address(new ERC4626Form(superRegistry));
        uint32 formBeaconId = 0;
        uint32 formBeaconId_invalid = 999;


        /// @dev Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(
            formImplementation1,
            formBeaconId,
            salt
        );

        /// @dev Invalid Form Beacon For Pausing
        vm.expectRevert(Error.INVALID_FORM_ID.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).changeFormBeaconPauseStatus{value: 800 * 10 ** 18}(
            formBeaconId_invalid,
            true,
            generateBroadcastParams(5, 2)
        );
    }
}
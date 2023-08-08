// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {SuperformFactory} from "../../SuperformFactory.sol";
import {FactoryStateRegistry} from "../../crosschain-data/extensions/FactoryStateRegistry.sol";
import {ERC4626Form} from "../../forms/ERC4626Form.sol";
import "../utils/BaseSetup.sol";
import {Error} from "../../utils/Error.sol";

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
            formImplementation1,
            formBeaconId,
            salt
        );

        SuperformFactory(getContract(chainId, "SuperformFactory")).changeFormBeaconPauseStatus{value: 800 * 10 ** 18}(
            formBeaconId,
            true,
            generateBroadcastParams(5, 2)
        );

        bool status = SuperformFactory(payable(getContract(chainId, "SuperformFactory"))).isFormBeaconPaused(
            formBeaconId
        );

        assertEq(status, true);
    }

    function xtest_changeFormBeaconPauseStatus() public {
        vm.startPrank(deployer);
        vm.selectFork(FORKS[chainId]);

        uint32 formBeaconId = 1;

        vm.recordLogs();
        /// setting the status as false in chain id = ETH & broadcasting it
        SuperformFactory(getContract(chainId, "SuperformFactory")).changeFormBeaconPauseStatus{value: 800 * 10 ** 18}(
            formBeaconId,
            true,
            generateBroadcastParams(5, 2)
        );
        _broadcastPayloadHelper(chainId, vm.getRecordedLogs());

        /// process the payload across all other chains
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] != chainId) {
                vm.selectFork(FORKS[chainIds[i]]);

                bool statusBefore = SuperformFactory(payable(getContract(chainIds[i], "SuperformFactory")))
                    .isFormBeaconPaused(1);

                FactoryStateRegistry(payable(getContract(chainIds[i], "FactoryStateRegistry"))).processPayload(31, "");

                bool statusAfter = SuperformFactory(payable(getContract(chainIds[i], "SuperformFactory")))
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
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(
            formImplementation1,
            formBeaconId,
            salt
        );

        /// @dev Invalid Form Beacon For Pausing
        vm.expectRevert(Error.INVALID_FORM_ID.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).changeFormBeaconPauseStatus{value: 800 * 10 ** 18}(
            formBeaconId_invalid,
            true,
            generateBroadcastParams(5, 2)
        );
    }
}

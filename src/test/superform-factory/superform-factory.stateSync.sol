// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "../utils/ProtocolActions.sol";
import {Error} from "../../utils/Error.sol";

contract SuperformFactoryStateSyncTest is BaseSetup {
    function setUp() public override {
        super.setUp();
    }

    function test_formBeaconStatusBroadcast() public {
        /// pausing form beacon id 1 from ETH
        uint32 formBeaconId = 1;

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        vm.recordLogs();
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormBeaconPauseStatus{value: 800 ether}(
            formBeaconId,
            true,
            generateBroadcastParams(5, 2)
        );

        _broadcastPayloadHelper(ETH, vm.getRecordedLogs());

        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] != ETH) {
                vm.selectFork(FORKS[chainIds[i]]);

                bool statusBefore = SuperformFactory(getContract(chainIds[i], "SuperformFactory")).isFormBeaconPaused(
                    formBeaconId
                );
                FactoryStateRegistry(payable(getContract(chainIds[i], "FactoryStateRegistry"))).processPayload(1, "");
                bool statusAfter = SuperformFactory(getContract(chainIds[i], "SuperformFactory")).isFormBeaconPaused(
                    formBeaconId
                );

                /// @dev assert status update before and after processing the payload
                assertEq(statusBefore, false);
                assertEq(statusAfter, true);
            }
        }

        /// try processing the same payload again
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] != ETH) {
                vm.selectFork(FORKS[chainIds[i]]);

                vm.expectRevert(Error.PAYLOAD_ALREADY_PROCESSED.selector);
                FactoryStateRegistry(payable(getContract(chainIds[i], "FactoryStateRegistry"))).processPayload(1, "");
            }
        }

        /// try processing not available payload id
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] != ETH) {
                vm.selectFork(FORKS[chainIds[i]]);

                vm.expectRevert(Error.INVALID_PAYLOAD_ID.selector);
                FactoryStateRegistry(payable(getContract(chainIds[i], "FactoryStateRegistry"))).processPayload(2, "");
            }
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {ISuperFormFactory} from "../interfaces/ISuperFormFactory.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {SuperRBAC} from "../settings/SuperRBAC.sol";
import {RolesStateRegistry} from "../crosschain-data/RolesStateRegistry.sol";
import "./utils/BaseSetup.sol";
import "./utils/Utilities.sol";
import {Error} from "../utils/Error.sol";
import "../utils/DataPacking.sol";

contract SuperformRolesTest is BaseSetup {
    uint16 internal chainId = ETH;

    function setUp() public override {
        super.setUp();
    }

    function test_revokeRoleBroadcast() public {
        vm.startPrank(deployer);
        vm.selectFork(FORKS[chainId]);

        vm.recordLogs();
        /// setting the status as false in chain id = ETH & broadcasting it
        SuperRBAC(getContract(chainId, "SuperRBAC")).revokeSuperRouterRole{
            value: 800 * 10 ** 18
        }(getContract(chainId, "SuperRouter"), generateBroadcastParams(5, 2));
        _broadcastPayloadHelper(chainId, vm.getRecordedLogs());

        /// process the payload across all other chains
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] != chainId) {
                vm.selectFork(FORKS[chainIds[i]]);

                bool statusBefore = SuperRBAC(
                    getContract(chainIds[i], "SuperRBAC")
                ).hasSuperRouterRole(getContract(chainIds[i], "SuperRouter"));

                RolesStateRegistry(
                    payable(getContract(chainIds[i], "RolesStateRegistry"))
                ).processPayload(1, "");

                bool statusAfter = SuperRBAC(
                    getContract(chainIds[i], "SuperRBAC")
                ).hasSuperRouterRole(getContract(chainIds[i], "SuperRouter"));

                /// assert status update before and after processing the payload
                assertEq(statusBefore, true);
                assertEq(statusAfter, false);
            }
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/BaseSetup.sol";
import { SuperRegistry } from "src/settings/SuperRegistry.sol";
import { Error } from "src/libraries/Error.sol";

contract QuorumManagerTest is BaseSetup {
    SuperRegistry public superRegistry;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRegistry = SuperRegistry(payable(getContract(ETH, "SuperRegistry")));
    }

    function test_getRequiredMessagingQuorum() public {
        vm.selectFork(FORKS[ETH]);

        vm.expectRevert(Error.ZERO_INPUT_VALUE.selector);
        superRegistry.getRequiredMessagingQuorum(0);
    }
}

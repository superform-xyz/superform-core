// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/BaseSetup.sol";
import { BroadcastRegistry } from "src/crosschain-data/BroadcastRegistry.sol";

contract InvalidReceiver {
    receive() external payable {
        revert();
    }
}

contract BroadcastRegistryTest is BaseSetup {
    BroadcastRegistry public broadcastRegistry;
    address caller;
    address invalidReceiver;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        broadcastRegistry = BroadcastRegistry(payable(getContract(ETH, "BroadcastRegistry")));
        invalidReceiver = address(new InvalidReceiver());

        /// @dev caller
        caller = address(420);
        vm.deal(caller, 100 ether);
        vm.deal(invalidReceiver, 100 ether);

        vm.startPrank(deployer);
        SuperRBAC rbac = SuperRBAC(getContract(ETH, "SuperRBAC"));
        rbac.grantRole(rbac.BROADCASTER_ROLE(), caller);
        rbac.grantRole(rbac.BROADCASTER_ROLE(), invalidReceiver);
        vm.stopPrank();
    }

    function test_broadcastRefunds() public {
        vm.startPrank(caller);
        broadcastRegistry.broadcastPayload{ value: 100 ether }(caller, 4, 0, bytes("testmepls"), bytes(""));
        assertEq(address(broadcastRegistry).balance, 0);
        assertEq(caller.balance, 100 ether);
    }

    function test_revertOnFailedRefunds() public {
        vm.startPrank(invalidReceiver);
        vm.expectRevert(Error.FAILED_TO_SEND_NATIVE.selector);
        broadcastRegistry.broadcastPayload{ value: 100 ether }(invalidReceiver, 4, 0, bytes("testmepls"), bytes(""));
        assertEq(address(broadcastRegistry).balance, 0);
        assertEq(invalidReceiver.balance, 100 ether);
    }
}

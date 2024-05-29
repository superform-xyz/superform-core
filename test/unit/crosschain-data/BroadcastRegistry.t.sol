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
    address nonBroadcaster;
    address nonProcessor;
    address invalidAmbImplementation;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        broadcastRegistry = BroadcastRegistry(payable(getContract(ETH, "BroadcastRegistry")));
        invalidReceiver = address(new InvalidReceiver());

        /// @dev caller
        caller = address(420);
        vm.deal(caller, 100 ether);
        vm.deal(invalidReceiver, 100 ether);

        nonBroadcaster = address(421);
        nonProcessor = address(422);
        invalidAmbImplementation = address(423);

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

    function test_revertOnBroadcastUnderPayment() public {
        vm.startPrank(invalidReceiver);
        vm.expectRevert(Error.INVALID_BROADCAST_FEE.selector);
        broadcastRegistry.broadcastPayload{ value: 1 ether }(invalidReceiver, 4, 2 ether, bytes("testmepls"), bytes(""));
    }

    function test_revertOnNonBroadcaster() public {
        vm.startPrank(nonBroadcaster);
        vm.expectRevert(Error.NOT_ALLOWED_BROADCASTER.selector);
        broadcastRegistry.broadcastPayload(nonBroadcaster, 4, 0, bytes("testmepls"), bytes(""));
    }

    function test_revertOnNonProcessor() public {
        vm.startPrank(nonProcessor);
        vm.expectRevert(
            abi.encodeWithSelector(
                Error.NOT_PRIVILEGED_CALLER.selector,
                bytes32(0xbc04cc915ae49862455f81e94a0b624d54c65f74ec4700f8249a99a5ac18cf56)
            )
        );
        broadcastRegistry.processPayload(1);
    }

    function test_revertOnInvalidAmbImplementation() public {
        vm.startPrank(invalidAmbImplementation);
        vm.expectRevert(Error.NOT_BROADCAST_AMB_IMPLEMENTATION.selector);
        broadcastRegistry.receiveBroadcastPayload(1, bytes("testmepls"));
    }
}

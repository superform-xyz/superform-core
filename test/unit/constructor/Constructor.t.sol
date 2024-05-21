// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/BaseSetup.sol";

contract ConstructorsTest is BaseSetup {
    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
    }

    function test_superRegistry_address_0() public {
        bytes32 saltT = keccak256(abi.encodePacked("test"));
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new PayMaster{ salt: saltT }(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new PaymentHelper{ salt: saltT }(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new SuperformRouter{ salt: saltT }(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new EmergencyQueue{ salt: saltT }(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new RewardsDistributor{ salt: saltT }(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new LiFiValidator{ salt: saltT }(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new SocketOneInchValidator{ salt: saltT }(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new SocketValidator{ salt: saltT }(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new DstSwapper{ salt: saltT }(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new SuperformFactory{ salt: saltT }(address(0));
    }
}

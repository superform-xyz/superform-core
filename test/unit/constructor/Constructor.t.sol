// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/BaseSetup.sol";

contract ConstructorsTest is BaseSetup {
    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
    }

    function test_superRegistry_address_0() public {
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new PayMaster(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new PaymentHelper(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new SuperformRouter(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new EmergencyAdmin(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new RewardsDistributor(address(0));
    }
}

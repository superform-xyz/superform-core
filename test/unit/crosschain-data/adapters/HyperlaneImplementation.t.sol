// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "../../../utils/BaseSetup.sol";

import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { HyperlaneImplementation } from "src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol";
import { Error } from "src/libraries/Error.sol";

contract HyperlaneImplementationUnitTest is BaseSetup {
    HyperlaneImplementation hyperlaneImplementation;

    function setUp() public override {
        super.setUp();

        ISuperRegistry superRegistry = ISuperRegistry(getContract(ETH, "SuperRegistry"));

        vm.selectFork(FORKS[ETH]);
        hyperlaneImplementation = HyperlaneImplementation(payable(superRegistry.getAmbAddress(2)));
    }

    function test_setHyperlaneConfig_ZERO_ADDRESS() public {
        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        hyperlaneImplementation.setHyperlaneConfig(IMailbox(address(0)), IInterchainGasPaymaster(address(420)));

        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        hyperlaneImplementation.setHyperlaneConfig(IMailbox(address(420)), IInterchainGasPaymaster(address(0)));
    }
}

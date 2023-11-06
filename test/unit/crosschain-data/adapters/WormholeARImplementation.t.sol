// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import "test/utils/BaseSetup.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { Error } from "src/utils/Error.sol";
import { VaaKey, IWormholeRelayer } from "src/vendor/wormhole/IWormholeRelayer.sol";

contract WormholeARImplementationTest is BaseSetup {
    ISuperRegistry public superRegistry;
    WormholeARImplementation wormholeARImpl;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRegistry = ISuperRegistry(getContract(ETH, "SuperRegistry"));
        wormholeARImpl = WormholeARImplementation(payable(superRegistry.getAmbAddress(3)));
    }

    function test_setWormholeRelayer_addressZero() public {
        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        wormholeARImpl.setWormholeRelayer(address(0));
    }

    function test_retryPayload() public {
        VaaKey memory vaaKey = VaaKey(1, keccak256("test"), 1);

        bytes memory data = abi.encode(vaaKey, 2, 3, 4, deployer);

        vm.mockCall(
            address(wormholeARImpl.relayer()),
            abi.encodeWithSelector(
                IWormholeRelayer(wormholeARImpl.relayer()).resendToEvm.selector, vaaKey, 2, 3, 4, deployer
            ),
            abi.encode("")
        );

        vm.prank(deployer);
        wormholeARImpl.retryPayload(data);

        vm.clearMockedCalls();
    }

    function test_receiveWormholeMessages_revertInvalidSrcSender() public {
        address relayer = address(wormholeARImpl.relayer());
        vm.selectFork(FORKS[ARBI]);

        address payable wormholeARArbi = payable(ISuperRegistry(getContract(ARBI, "SuperRegistry")).getAmbAddress(3));
        vm.prank(relayer);
        vm.expectRevert(Error.INVALID_SRC_SENDER.selector);
        WormholeARImplementation(wormholeARArbi).receiveWormholeMessages(
            "", new bytes[](0), bytes32(uint256(uint160(address(wormholeARArbi))) << 96), 4, bytes32(0)
        );
    }
}

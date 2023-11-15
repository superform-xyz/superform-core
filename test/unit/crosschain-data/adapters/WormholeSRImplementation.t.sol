// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import "test/utils/BaseSetup.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { Error } from "src/utils/Error.sol";
import { IWormhole } from "src/vendor/wormhole/IWormhole.sol";
import { BroadcastRegistry } from "src/crosschain-data/BroadcastRegistry.sol";

contract FakeRelayer {
    receive() external payable {
        revert();
    }
}

contract WormholeSRImplementationTest is BaseSetup {
    ISuperRegistry public superRegistry;
    WormholeSRImplementation wormholeSRImpl;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRegistry = ISuperRegistry(getContract(ETH, "SuperRegistry"));
        wormholeSRImpl = WormholeSRImplementation(payable(superRegistry.getAmbAddress(4)));
    }

    function test_setWormholeCore() public {
        vm.selectFork(FORKS[ETH]);

        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        wormholeSRImpl.setWormholeCore(address(0));
    }

    function test_setRelayer() public {
        vm.selectFork(FORKS[ETH]);

        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        wormholeSRImpl.setRelayer(address(0));
    }

    function test_setFinality() public {
        vm.selectFork(FORKS[ETH]);

        vm.prank(deployer);
        vm.expectRevert(Error.INVALID_BROADCAST_FINALITY.selector);
        wormholeSRImpl.setFinality(0);

        vm.prank(deployer);
        wormholeSRImpl.setFinality(1);
    }

    function test_broadcastPayload_feeUnderpaid() public {
        vm.selectFork(FORKS[ETH]);

        address wormhole = address(wormholeSRImpl.wormhole());

        vm.mockCall(wormhole, abi.encodeWithSelector(IWormhole(wormhole).messageFee.selector), abi.encode(1000));

        vm.prank(getContract(ETH, "BroadcastRegistry"));
        vm.expectRevert(Error.INSUFFICIENT_NATIVE_AMOUNT.selector);
        wormholeSRImpl.broadcastPayload(address(0), "", "");

        vm.clearMockedCalls();
    }

    function test_broadcastPayload_RelayerNotSet() public {
        vm.selectFork(FORKS[ETH]);

        WormholeSRImplementation newImpl = new WormholeSRImplementation(superRegistry);
        address wormholeCore_ = address(wormholeSRImpl.wormhole());
        vm.prank(deployer);
        newImpl.setWormholeCore(wormholeCore_);
        SuperformFactory sfFactory = SuperformFactory(getContract(ETH, "SuperformFactory"));

        uint8[] memory ambId = new uint8[](1);
        ambId[0] = 5;

        address[] memory ambAddress = new address[](1);

        ambAddress[0] = address(newImpl);

        bool[] memory isBroadcastAmb = new bool[](1);
        isBroadcastAmb[0] = true;

        vm.prank(deployer);
        superRegistry.setAmbAddress(ambId, ambAddress, isBroadcastAmb);

        vm.prank(deployer);
        vm.expectRevert(Error.RELAYER_NOT_SET.selector);
        sfFactory.changeFormImplementationPauseStatus(1, true, abi.encode(5, abi.encode(0, "")));
    }

    function test_broadcastPayload_RelayerInvalid() public {
        vm.selectFork(FORKS[ETH]);

        WormholeSRImplementation newImpl = new WormholeSRImplementation(superRegistry);
        address wormholeCore_ = address(wormholeSRImpl.wormhole());
        address relayer_ = address(new FakeRelayer());

        vm.startPrank(deployer);
        newImpl.setWormholeCore(wormholeCore_);
        newImpl.setRelayer(relayer_);

        SuperformFactory sfFactory = SuperformFactory(getContract(ETH, "SuperformFactory"));

        uint8[] memory ambId = new uint8[](1);
        ambId[0] = 5;

        address[] memory ambAddress = new address[](1);

        ambAddress[0] = address(newImpl);

        bool[] memory isBroadcastAmb = new bool[](1);
        isBroadcastAmb[0] = true;

        superRegistry.setAmbAddress(ambId, ambAddress, isBroadcastAmb);

        vm.expectRevert(Error.FAILED_TO_SEND_NATIVE.selector);
        sfFactory.changeFormImplementationPauseStatus(1, true, abi.encode(5, abi.encode(0, "")));

        vm.stopPrank();
    }

    function test_receiveMessage() public {
        vm.selectFork(FORKS[ETH]);

        IWormhole.Signature[] memory signatures = new IWormhole.Signature[](1);
        signatures[0] = IWormhole.Signature(keccak256("1"), keccak256("1"), 1, 1);

        IWormhole.VM memory wormholeMessage = IWormhole.VM(
            1, 1, 1, 2, bytes32(uint256(uint160(address(wormholeSRImpl)))), 1, 1, "", 1, signatures, keccak256("1")
        );

        vm.mockCall(
            address(wormholeSRImpl.wormhole()),
            abi.encodeWithSelector(wormholeSRImpl.wormhole().parseAndVerifyVM.selector, ""),
            abi.encode(wormholeMessage, false, "")
        );

        vm.prank(getContract(ETH, "WormholeBroadcastHelper"));

        vm.expectRevert(Error.INVALID_BROADCAST_PAYLOAD.selector);
        wormholeSRImpl.receiveMessage("");

        vm.clearMockedCalls();
        wormholeMessage = IWormhole.VM(
            1, 1, 1, 2, bytes32(uint256(uint160(address(wormholeSRImpl)))), 1, 1, "", 1, signatures, keccak256("1")
        );
        vm.mockCall(
            address(wormholeSRImpl.wormhole()),
            abi.encodeWithSelector(wormholeSRImpl.wormhole().parseAndVerifyVM.selector, ""),
            abi.encode(wormholeMessage, true, "")
        );

        vm.prank(getContract(ETH, "WormholeBroadcastHelper"));

        vm.expectRevert(Error.INVALID_SRC_CHAIN_ID.selector);
        wormholeSRImpl.receiveMessage("");

        vm.clearMockedCalls();

        wormholeMessage = IWormhole.VM(
            1, 1, 1, 4, bytes32(uint256(uint160(address(address(0))))), 1, 1, "", 1, signatures, keccak256("1")
        );
        vm.mockCall(
            address(wormholeSRImpl.wormhole()),
            abi.encodeWithSelector(wormholeSRImpl.wormhole().parseAndVerifyVM.selector, ""),
            abi.encode(wormholeMessage, true, "")
        );

        vm.prank(getContract(ETH, "WormholeBroadcastHelper"));

        vm.expectRevert(Error.INVALID_SRC_SENDER.selector);
        wormholeSRImpl.receiveMessage("");

        vm.clearMockedCalls();

        wormholeMessage = IWormhole.VM(
            1, 1, 1, 4, bytes32(uint256(uint160(address(wormholeSRImpl)))), 1, 1, "", 1, signatures, keccak256("1")
        );
        vm.mockCall(
            address(wormholeSRImpl.wormhole()),
            abi.encodeWithSelector(wormholeSRImpl.wormhole().parseAndVerifyVM.selector, ""),
            abi.encode(wormholeMessage, true, "")
        );

        vm.prank(getContract(ETH, "WormholeBroadcastHelper"));

        wormholeSRImpl.receiveMessage("");

        vm.prank(getContract(ETH, "WormholeBroadcastHelper"));

        vm.expectRevert(Error.DUPLICATE_PAYLOAD.selector);
        wormholeSRImpl.receiveMessage("");

        vm.clearMockedCalls();
    }

    function test_setChainId_invalidChainId() public {
        vm.selectFork(FORKS[ETH]);

        vm.prank(deployer);
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        wormholeSRImpl.setChainId(0, 1);

        vm.prank(deployer);
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        wormholeSRImpl.setChainId(1, 0);

        vm.prank(deployer);
        wormholeSRImpl.setChainId(56, 4);
    }

    function test_setReceiver_invalidInputs() public {
        vm.selectFork(FORKS[ETH]);

        vm.prank(deployer);
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        wormholeSRImpl.setReceiver(0, address(0));

        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        wormholeSRImpl.setReceiver(1, address(0));
    }

    function test_estimateFees() public {
        vm.selectFork(FORKS[ETH]);

        wormholeSRImpl.estimateFees("", "");
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/BaseSetup.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { Error } from "src/libraries/Error.sol";
import { TransactionType, CallbackType, AMBMessage } from "src/types/DataTypes.sol";
import { VaaKey, IWormholeRelayer } from "src/vendor/wormhole/IWormholeRelayer.sol";
import { DataLib } from "src/libraries/DataLib.sol";

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
        vm.selectFork(FORKS[ETH]);

        vm.selectFork(FORKS[ARBI]);

        address payable wormholeARArbi = payable(ISuperRegistry(getContract(ARBI, "SuperRegistry")).getAmbAddress(3));
        address relayer = address(WormholeARImplementation(wormholeARArbi).relayer());

        vm.prank(relayer);
        vm.expectRevert(Error.INVALID_SRC_SENDER.selector);
        WormholeARImplementation(wormholeARArbi).receiveWormholeMessages(
            "", new bytes[](0), bytes32(uint256(uint160(address(wormholeARArbi)))), 4, bytes32(0)
        );
    }

    function test_receiveWormholeMessages_duplicatePayload() public {
        vm.selectFork(FORKS[ARBI]);

        address payable wormholeARArbi = payable(ISuperRegistry(getContract(ARBI, "SuperRegistry")).getAmbAddress(3));

        address relayer = address(WormholeARImplementation(wormholeARArbi).relayer());

        AMBMessage memory ambMessage = AMBMessage(
            DataLib.packTxInfo(
                uint8(TransactionType.DEPOSIT),
                /// @dev TransactionType
                uint8(CallbackType.INIT),
                0,
                /// @dev isMultiVaults
                1,
                /// @dev STATE_REGISTRY_TYPE,
                deployer,
                /// @dev srcSender,
                ETH
            ),
            /// @dev srcChainId
            abi.encode(new uint8[](0), "")
        );
        vm.prank(relayer);
        WormholeARImplementation(wormholeARArbi).receiveWormholeMessages(
            abi.encode(ambMessage),
            new bytes[](0),
            bytes32(uint256(uint160(address(wormholeARImpl)))),
            2,
            keccak256(abi.encode(ambMessage))
        );

        vm.prank(relayer);
        vm.expectRevert(Error.DUPLICATE_PAYLOAD.selector);

        WormholeARImplementation(wormholeARArbi).receiveWormholeMessages(
            abi.encode(ambMessage),
            new bytes[](0),
            bytes32(uint256(uint160(address(wormholeARImpl)))),
            2,
            keccak256(abi.encode(ambMessage))
        );
    }

    function test_setChainId_InvalidChainId() public {
        vm.selectFork(FORKS[ETH]);

        vm.startPrank(deployer);
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        wormholeARImpl.setChainId(0, 1);

        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        wormholeARImpl.setChainId(1, 0);
    }

    function test_setChainId_OverridePrevious() public {
        vm.selectFork(FORKS[ETH]);

        vm.startPrank(deployer);
        wormholeARImpl.setChainId(56, 4);
    }

    function test_setReceiver_InvalidChainId() public {
        vm.selectFork(FORKS[ETH]);

        vm.startPrank(deployer);
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        wormholeARImpl.setReceiver(0, address(0));
    }

    function test_setReceiver_ZeroAddress() public {
        vm.selectFork(FORKS[ETH]);

        vm.startPrank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        wormholeARImpl.setReceiver(1, address(0));
    }

    function test_estimateFees() public {
        vm.selectFork(FORKS[ETH]);

        vm.startPrank(deployer);
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        wormholeARImpl.estimateFees(111, "", abi.encode(1, 1));
    }
}

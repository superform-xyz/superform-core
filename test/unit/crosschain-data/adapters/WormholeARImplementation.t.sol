// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/BaseSetup.sol";
import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { Error } from "src/libraries/Error.sol";
import { ProofLib } from "src/libraries/ProofLib.sol";
import { TransactionType, CallbackType, AMBMessage } from "src/types/DataTypes.sol";
import { VaaKey, IWormholeRelayer } from "src/vendor/wormhole/IWormholeRelayer.sol";
import { DataLib } from "src/libraries/DataLib.sol";

contract InvalidReceiver {
    receive() external payable {
        revert();
    }
}

contract WormholeARImplementationTest is BaseSetup {
    using ProofLib for AMBMessage;

    ISuperRegistry public superRegistry;
    WormholeARImplementation wormholeARImpl;

    address invalidReceiver;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRegistry = ISuperRegistry(getContract(ETH, "SuperRegistry"));
        wormholeARImpl = WormholeARImplementation(payable(superRegistry.getAmbAddress(3)));
        invalidReceiver = address(new InvalidReceiver());
    }

    function test_setWormholeRelayer_addressZero() public {
        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        wormholeARImpl.setWormholeRelayer(address(0));
    }

    function test_dispatchPayload_RefundChainIdNotSet() public {
        vm.prank(deployer);
        WormholeARImplementation newWormholeARImpl =
            new WormholeARImplementation(ISuperRegistry(getContract(ETH, "SuperRegistry")));

        vm.prank(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.REFUND_CHAIN_ID_NOT_SET.selector);
        newWormholeARImpl.dispatchPayload(deployer, ARBI, bytes("testmessage"), abi.encode(0, 500_000));
    }

    function test_retryPayload() public {
        VaaKey memory vaaKey = VaaKey(1, keccak256("test"), 1);

        bytes memory data = abi.encode(vaaKey, 5, 3, 4, deployer);

        vm.mockCall(
            address(wormholeARImpl.relayer()),
            abi.encodeWithSelector(
                IWormholeRelayer(wormholeARImpl.relayer()).resendToEvm.selector, vaaKey, 5, 3, 4, deployer
            ),
            abi.encode("")
        );

        uint256 fee = wormholeARImpl.estimateFees(uint64(137), bytes(""), abi.encode(uint256(0), uint256(4)));

        vm.prank(deployer);
        uint256 balanceBefore = deployer.balance;
        wormholeARImpl.retryPayload{ value: fee + 1 ether }(data);
        assertEq(deployer.balance, balanceBefore - fee);

        vm.clearMockedCalls();
    }

    function test_retryPayloadFailedToRefundExcessMsgValue() public {
        deal(invalidReceiver, 100 ether);

        VaaKey memory vaaKey = VaaKey(1, keccak256("testInvalidRefund"), 1);
        bytes memory data = abi.encode(vaaKey, 5, 3, 4, invalidReceiver);

        vm.mockCall(
            address(wormholeARImpl.relayer()),
            abi.encodeWithSelector(
                IWormholeRelayer(wormholeARImpl.relayer()).resendToEvm.selector, vaaKey, 5, 3, 4, invalidReceiver
            ),
            abi.encode("")
        );

        vm.prank(invalidReceiver);
        vm.expectRevert(Error.FAILED_TO_SEND_NATIVE.selector);
        wormholeARImpl.retryPayload{ value: 100 ether }(data);

        vm.clearMockedCalls();
    }

    function test_retryPayloadWithZeroAddress() public {
        VaaKey memory vaaKey = VaaKey(1, keccak256("test"), 1);

        bytes memory data = abi.encode(vaaKey, 5, 3, 4, address(0));

        vm.mockCall(
            address(wormholeARImpl.relayer()),
            abi.encodeWithSelector(
                IWormholeRelayer(wormholeARImpl.relayer()).resendToEvm.selector, vaaKey, 5, 3, 4, address(0)
            ),
            abi.encode("")
        );

        uint256 fee = wormholeARImpl.estimateFees(uint64(137), bytes(""), abi.encode(uint256(0), uint256(4)));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        vm.prank(deployer);
        wormholeARImpl.retryPayload{ value: fee }(data);

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

    function test_wormholeRetryPayload_InvalidRetryFee() public {
        VaaKey memory vaaKey = VaaKey(1, keccak256("test"), 1);

        bytes memory data = abi.encode(vaaKey, 5, 3, 4, deployer);

        vm.mockCall(
            address(wormholeARImpl.relayer()),
            abi.encodeWithSelector(
                IWormholeRelayer(wormholeARImpl.relayer()).resendToEvm.selector, vaaKey, 5, 3, 4, deployer
            ),
            abi.encode("")
        );

        uint256 fee = wormholeARImpl.estimateFees(uint64(137), bytes(""), abi.encode(uint256(0), uint256(4)));

        vm.prank(deployer);
        vm.expectRevert(Error.INVALID_RETRY_FEE.selector);
        wormholeARImpl.retryPayload{ value: fee - 100 wei }(data);

        vm.clearMockedCalls();
    }

    function test_receiveWormholeMessages_InvalidChainId() public {
        vm.prank(address(wormholeARImpl.relayer()));
        AMBMessage memory ambMessage;
        ambMessage.txInfo = DataLib.packTxInfo(0, 0, 0, 1, address(0), 0);

        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        wormholeARImpl.receiveWormholeMessages(
            abi.encode(ambMessage), new bytes[](0), bytes32(uint256(uint160(address(0)))), 0, bytes32(0)
        );
    }

    function test_receiveWormholeMessages_ambProtect() public {
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

        bytes32 proof = AMBMessage(ambMessage.txInfo, "").computeProof();

        vm.prank(relayer);
        WormholeARImplementation(wormholeARArbi).receiveWormholeMessages(
            abi.encode(ambMessage),
            new bytes[](0),
            bytes32(uint256(uint160(address(wormholeARImpl)))),
            2,
            keccak256(abi.encode(ambMessage))
        );

        // Test with proof in params
        AMBMessage memory ambMessageWithProof = AMBMessage(
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
            abi.encode(proof)
        );

        vm.prank(relayer);
        vm.expectRevert();
        WormholeARImplementation(wormholeARArbi).receiveWormholeMessages(
            abi.encode(ambMessageWithProof),
            new bytes[](0),
            bytes32(uint256(uint160(address(wormholeARImpl)))),
            2,
            keccak256(abi.encode(ambMessageWithProof, ambMessageWithProof))
        );
    }

    function test_receiveWormholeMessages_CALLER_NOT_RELAYER() public {
        vm.expectRevert(Error.CALLER_NOT_RELAYER.selector);
        wormholeARImpl.receiveWormholeMessages("", new bytes[](0), bytes32(0), 0, bytes32(0));
    }

    function test_dispatchPayload_NOT_STATE_REGISTRY() public {
        vm.expectRevert(Error.NOT_STATE_REGISTRY.selector);
        wormholeARImpl.dispatchPayload(deployer, 0, "", "");
    }

    function test_setWormholeRelayer_NOT_PROTOCOL_ADMIN() public {
        vm.prank(address(0));
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        wormholeARImpl.setWormholeRelayer(address(0));
    }

    function test_setChainId_NOT_PROTOCOL_ADMIN() public {
        vm.prank(address(0));
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        wormholeARImpl.setChainId(0, 0);
    }

    function test_setRefundChainId_NOT_PROTOCOL_ADMIN() public {
        vm.prank(address(0));
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        wormholeARImpl.setRefundChainId(0);
    }

    function test_setReceiver_NOT_PROTOCOL_ADMIN() public {
        vm.prank(address(0));
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        wormholeARImpl.setReceiver(0, deployer);
    }

    function test_setWormholeRelayer_NotProtocolAdmin() public {
        vm.prank(address(1));
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        wormholeARImpl.setWormholeRelayer(address(2));
    }

    function test_setChainId_NotProtocolAdmin() public {
        vm.prank(address(1));
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        wormholeARImpl.setChainId(1, 1);
    }

    function test_setRefundChainId_NotProtocolAdmin() public {
        vm.prank(address(1));
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        wormholeARImpl.setRefundChainId(1);
    }

    function test_setReceiver_NotProtocolAdmin() public {
        vm.prank(address(1));
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        wormholeARImpl.setReceiver(1, address(2));
    }

    function test_dispatchPayload_NotStateRegistry() public {
        vm.prank(address(1));
        vm.expectRevert(Error.NOT_STATE_REGISTRY.selector);
        wormholeARImpl.dispatchPayload(address(1), 1, bytes(""), bytes(""));
    }

    function test_receiveWormholeMessages_CallerNotRelayer() public {
        vm.prank(address(1));
        vm.expectRevert(Error.CALLER_NOT_RELAYER.selector);
        wormholeARImpl.receiveWormholeMessages(bytes(""), new bytes[](0), bytes32(0), 1, bytes32(0));
    }
}

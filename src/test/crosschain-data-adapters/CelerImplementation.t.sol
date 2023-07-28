// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "../utils/BaseSetup.sol";
import {TransactionType, CallbackType, AMBMessage} from "../../types/DataTypes.sol";
import {DataLib} from "../../libraries/DataLib.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {CelerImplementation} from "../../crosschain-data/adapters/celer/CelerImplementation.sol";
import {CoreStateRegistry} from "../../crosschain-data/extensions/CoreStateRegistry.sol";
import {Error} from "../../utils/Error.sol";

contract CelerImplementationTest is BaseSetup {
    /// @dev event emitted from CelerMessageBus on ETH (CELER_BUS)
    event Message(address indexed sender, address receiver, uint256 dstChainId, bytes message, uint256 fee);

    address public constant CELER_BUS = 0x4066D196A423b2b3B8B054f4F40efB47a74E200C;
    ISuperRegistry public superRegistry;
    CelerImplementation celerImplementation;
    address public bond;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRegistry = ISuperRegistry(getContract(ETH, "SuperRegistry"));
        celerImplementation = CelerImplementation(payable(superRegistry.getAmbAddress(3)));
        /// @dev malicious caller
        bond = address(7);
        /// @dev (who's a brokie)
        vm.deal(bond, 1 ether);

        vm.startPrank(deployer);
    }

    function test_setCelerBus() public {
        celerImplementation.setCelerBus(CELER_BUS);
        assertEq(address(celerImplementation.messageBus()), CELER_BUS);
    }

    function test_revert_setCelerBus_invalidMessageBus_invalidCaller() public {
        vm.expectRevert();
        celerImplementation.setCelerBus(address(0));

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        celerImplementation.setCelerBus(CELER_BUS);
    }

    function test_setReceiver() public {
        celerImplementation.setReceiver(10, getContract(10, "CelerImplementation")); /// optimism
        celerImplementation.setReceiver(137, getContract(137, "CelerImplementation")); /// polygon

        assertEq(celerImplementation.authorizedImpl(10), getContract(10, "CelerImplementation"));
        assertEq(celerImplementation.authorizedImpl(137), getContract(137, "CelerImplementation"));
    }

    function test_revert_setReceiver_invalidChainId_invalidAuthorizedImpl_invalidCaller() public {
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        celerImplementation.setReceiver(0, getContract(10, "CelerImplementation"));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        celerImplementation.setReceiver(10, address(0));

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        celerImplementation.setReceiver(10, getContract(10, "CelerImplementation"));
    }

    function test_setChainId() public {
        celerImplementation.setChainId(10, 10); /// optimism
        celerImplementation.setChainId(137, 137); /// polygon

        assertEq(celerImplementation.ambChainId(10), 10);
        assertEq(celerImplementation.superChainId(137), 137);
    }

    function test_revert_setChainId_invalidChainId_invalidCaller() public {
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        celerImplementation.setChainId(10, 0); /// optimism

        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        celerImplementation.setChainId(0, 10); /// optimism

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        celerImplementation.setChainId(137, 137); /// polygon
    }

    function test_broadcastPayload() public {
        /// @dev need to call setCelerBus(), setReceiver(), setChainId() before calling broadcastPayload(),
        /// but we don't need to, as it's already done in BaseSetup
        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        (ambMessage, ambExtraData, coreStateRegistry) = setupBroadcastPayloadAMBData(users[0]);

        /// @dev only checking topic1 as it is the only one indexed in the Message event
        vm.expectEmit(true, false, false, true, CELER_BUS);

        /// @dev chainIds = [1, 56, 43114, 137, 42161, 10];
        for (uint i = 1; i < chainIds.length; i++) {
            emit Message(
                address(celerImplementation),
                celerImplementation.authorizedImpl(chainIds[i]),
                chainIds[i],
                abi.encode(ambMessage),
                0.1 ether
            );
        }

        vm.prank(coreStateRegistry);
        celerImplementation.broadcastPayload{value: 0.1 ether}(
            users[0],
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_broadcastPayload_invalidCaller() public {
        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        (ambMessage, ambExtraData, coreStateRegistry) = setupBroadcastPayloadAMBData(users[0]);

        vm.expectRevert(Error.INVALID_CALLER.selector);

        vm.prank(bond);
        celerImplementation.broadcastPayload{value: 0.1 ether}(
            users[0],
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_broadcastPayload_gasRefundFailed() public {
        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        /// @dev a contract that doesn't accept ETH
        address dai = getContract(1, "DAI");

        (ambMessage, ambExtraData, coreStateRegistry) = setupBroadcastPayloadAMBData(dai);

        vm.expectRevert(Error.GAS_REFUND_FAILED.selector);

        vm.prank(coreStateRegistry);
        /// @dev note first arg to be dai
        celerImplementation.broadcastPayload{value: 0.1 ether}(dai, abi.encode(ambMessage), abi.encode(ambExtraData));
    }

    function test_revert_dispatchPayload_gasRefundFailed_invalidCaller() public {
        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        /// @dev a contract that doesn't accept ETH
        address dai = getContract(1, "DAI");

        (ambMessage, ambExtraData, coreStateRegistry) = setupBroadcastPayloadAMBData(dai);

        vm.expectRevert(Error.GAS_REFUND_FAILED.selector);
        vm.prank(coreStateRegistry);
        /// @dev note first arg to be dai, second arg to be optimism
        celerImplementation.dispatchPayload{value: 0.1 ether}(
            dai,
            chainIds[5],
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );

        vm.expectRevert(Error.INVALID_CALLER.selector);
        vm.prank(bond);
        celerImplementation.dispatchPayload{value: 0.1 ether}(
            users[0],
            chainIds[5],
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_executeMessage_duplicatePayload_invalidCaller() public {
        AMBMessage memory ambMessage;

        (ambMessage, , ) = setupBroadcastPayloadAMBData(users[0]);

        vm.prank(CELER_BUS);
        celerImplementation.executeMessage{value: 0.1 ether}(
            users[0],
            ETH,
            abi.encode(ambMessage),
            getContract(ETH, "CelerHelper")
        );

        vm.expectRevert(Error.DUPLICATE_PAYLOAD.selector);
        vm.prank(CELER_BUS);
        celerImplementation.executeMessage{value: 0.1 ether}(
            users[0],
            ETH,
            abi.encode(ambMessage),
            getContract(ETH, "CelerHelper")
        );

        vm.expectRevert(Error.INVALID_CALLER.selector);
        vm.prank(bond);
        celerImplementation.executeMessage{value: 0.1 ether}(
            users[0],
            ETH,
            abi.encode(ambMessage),
            getContract(ETH, "CelerHelper")
        );
    }

    function setupBroadcastPayloadAMBData(
        address _srcSender
    ) public returns (AMBMessage memory, BroadCastAMBExtraData memory, address) {
        AMBMessage memory ambMessage = AMBMessage(
            DataLib.packTxInfo(
                uint8(TransactionType.DEPOSIT), /// @dev TransactionType
                uint8(CallbackType.INIT),
                0, /// @dev isMultiVaults
                1, /// @dev STATE_REGISTRY_TYPE,
                _srcSender, /// @dev srcSender,
                ETH /// @dev srcChainId
            ),
            "" /// ambData
        );

        /// @dev gasFees for chainIds = [56, 43114, 137, 42161, 10];
        /// @dev excluding chainIds[0] = 1 i.e. ETH, as no point broadcasting to same chain
        uint256[] memory gasPerDst = new uint256[](5);
        for (uint i = 0; i < gasPerDst.length; i++) {
            gasPerDst[i] = 0.1 ether;
        }

        /// @dev keeping extraDataPerDst empty for now
        bytes[] memory extraDataPerDst = new bytes[](5);

        BroadCastAMBExtraData memory ambExtraData = BroadCastAMBExtraData(gasPerDst, extraDataPerDst);

        address coreStateRegistry = getContract(1, "CoreStateRegistry");
        /// @dev bcoz we're simulating celerImplementation.broadcastPayload() from CoreStateRegistry (below),
        /// we need sufficient ETH in CoreStateRegistry and CelerImplementation. On mainnet, these funds will
        /// come from the user via SuperFormRouter
        vm.deal(coreStateRegistry, 10 ether);
        vm.deal(address(celerImplementation), 10 ether);

        /// @dev need to stop unused deployer prank, to use new prank, AND changePrank() doesn't work smh
        vm.stopPrank();

        return (ambMessage, ambExtraData, coreStateRegistry);
    }
}

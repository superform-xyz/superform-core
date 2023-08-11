// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "../../utils/BaseSetup.sol";
import {TransactionType, CallbackType, AMBMessage} from "src/types/DataTypes.sol";
import {DataLib} from "src/libraries/DataLib.sol";
import {ISuperRegistry} from "src/interfaces/ISuperRegistry.sol";
import {HyperlaneImplementation} from "src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol";
import {CoreStateRegistry} from "src/crosschain-data/extensions/CoreStateRegistry.sol";
import {Error} from "src/utils/Error.sol";

contract HyperlaneImplementationTest is BaseSetup {
    address public constant MAILBOX = 0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70;
    ISuperRegistry public superRegistry;
    HyperlaneImplementation hyperlaneImplementation;
    address public bond;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRegistry = ISuperRegistry(getContract(ETH, "SuperRegistry"));
        hyperlaneImplementation = HyperlaneImplementation(payable(superRegistry.getAmbAddress(2)));
        /// @dev malicious caller
        bond = address(7);
        /// @dev (who's a brokie)
        vm.deal(bond, 1 ether);
    }

    function test_setReceiver() public {
        vm.startPrank(deployer);
        hyperlaneImplementation.setReceiver(10, getContract(10, "HyperlaneImplementation")); /// optimism
        hyperlaneImplementation.setReceiver(137, getContract(137, "HyperlaneImplementation")); /// polygon

        assertEq(hyperlaneImplementation.authorizedImpl(10), getContract(10, "HyperlaneImplementation"));
        assertEq(hyperlaneImplementation.authorizedImpl(137), getContract(137, "HyperlaneImplementation"));
    }

    function test_revert_setReceiver_invalidChainId_invalidAuthorizedImpl_invalidCaller() public {
        vm.startPrank(deployer);
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        hyperlaneImplementation.setReceiver(0, getContract(10, "HyperlaneImplementation"));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        hyperlaneImplementation.setReceiver(10, address(0));

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);

        vm.stopPrank();
        vm.prank(bond);
        hyperlaneImplementation.setReceiver(10, getContract(10, "HyperlaneImplementation"));
    }

    function test_setChainId() public {
        vm.startPrank(deployer);
        hyperlaneImplementation.setChainId(10, 10); /// optimism
        hyperlaneImplementation.setChainId(137, 137); /// polygon

        assertEq(hyperlaneImplementation.ambChainId(10), 10);
        assertEq(hyperlaneImplementation.superChainId(137), 137);
    }

    function test_revert_setChainId_invalidChainId_invalidCaller() public {
        vm.startPrank(deployer);
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        hyperlaneImplementation.setChainId(10, 0); /// optimism

        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        hyperlaneImplementation.setChainId(0, 10); /// optimism

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);

        vm.stopPrank();
        vm.prank(bond);
        hyperlaneImplementation.setChainId(137, 137); /// polygon
    }

    function test_revert_broadcastPayload_invalidCaller() public {
        vm.startPrank(deployer);
        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        (ambMessage, ambExtraData, coreStateRegistry) = setupBroadcastPayloadAMBData(users[0]);

        vm.expectRevert(Error.NOT_STATE_REGISTRY.selector);
        vm.prank(bond);
        hyperlaneImplementation.broadcastPayload{value: 0.1 ether}(
            users[0],
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_broadcastPayload_invalidGasDstLength() public {
        vm.startPrank(deployer);
        AMBMessage memory ambMessage;
        address coreStateRegistry;

        (ambMessage, , coreStateRegistry) = setupBroadcastPayloadAMBData(users[0]);

        uint256[] memory gasPerDst = new uint256[](5);
        for (uint i = 0; i < gasPerDst.length; i++) {
            gasPerDst[i] = 0.1 ether;
        }

        /// @dev keeping extraDataPerDst empty for now
        bytes[] memory extraDataPerDst = new bytes[](1);

        BroadCastAMBExtraData memory ambExtraData = BroadCastAMBExtraData(gasPerDst, extraDataPerDst);

        vm.expectRevert(Error.INVALID_EXTRA_DATA_LENGTHS.selector);
        vm.prank(coreStateRegistry);
        hyperlaneImplementation.broadcastPayload{value: 0.1 ether}(
            users[0],
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_dispatchPayload_invalidCaller() public {
        vm.startPrank(deployer);
        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        (ambMessage, ambExtraData, coreStateRegistry) = setupBroadcastPayloadAMBData(users[0]);

        vm.expectRevert(Error.NOT_STATE_REGISTRY.selector);
        vm.prank(bond);
        hyperlaneImplementation.dispatchPayload{value: 0.1 ether}(
            users[0],
            chainIds[5],
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_handle_duplicatePayload_invalidSrcChainSender_invalidCaller() public {
        vm.startPrank(deployer);
        AMBMessage memory ambMessage;

        /// @dev setting authorizedImpl[ETH] to HyperlaneImplementation on ETH, as it was smh reset to 0 (after setting in BaseSetup)
        hyperlaneImplementation.setReceiver(1, getContract(1, "HyperlaneImplementation"));

        (ambMessage, , ) = setupBroadcastPayloadAMBData(users[0]);

        vm.prank(MAILBOX);
        hyperlaneImplementation.handle(
            uint32(ETH),
            bytes32(uint256(uint160(address(hyperlaneImplementation)))),
            abi.encode(ambMessage)
        );

        vm.expectRevert(Error.DUPLICATE_PAYLOAD.selector);
        vm.prank(MAILBOX);
        hyperlaneImplementation.handle(
            uint32(ETH),
            bytes32(uint256(uint160(address(hyperlaneImplementation)))),
            abi.encode(ambMessage)
        );

        vm.expectRevert(Error.INVALID_SRC_SENDER.selector);
        vm.prank(MAILBOX);
        hyperlaneImplementation.handle(uint32(ETH), bytes32(uint256(uint160(bond))), abi.encode(ambMessage));

        vm.expectRevert(Error.CALLER_NOT_MAILBOX.selector);
        vm.prank(bond);
        hyperlaneImplementation.handle(
            uint32(ETH),
            bytes32(uint256(uint160(address(hyperlaneImplementation)))),
            abi.encode(ambMessage)
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
        /// @dev bcoz we're simulating hyperlaneImplementation.broadcastPayload() from CoreStateRegistry (below),
        /// we need sufficient ETH in CoreStateRegistry and HyperlaneImplementation. On mainnet, these funds will
        /// come from the user via SuperformRouter
        vm.deal(coreStateRegistry, 10 ether);
        vm.deal(address(hyperlaneImplementation), 10 ether);

        /// @dev need to stop unused deployer prank, to use new prank, AND changePrank() doesn't work smh
        vm.stopPrank();

        return (ambMessage, ambExtraData, coreStateRegistry);
    }
}

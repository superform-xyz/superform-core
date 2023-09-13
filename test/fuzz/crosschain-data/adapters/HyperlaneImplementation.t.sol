// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.21;

import "../../../utils/BaseSetup.sol";
import { TransactionType, CallbackType, AMBMessage } from "src/types/DataTypes.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { HyperlaneImplementation } from "src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol";
import { CoreStateRegistry } from "src/crosschain-data/extensions/CoreStateRegistry.sol";
import { Error } from "src/utils/Error.sol";

contract HyperlaneImplementationTest is BaseSetup {
    address public constant MAILBOX = 0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70;
    ISuperRegistry public superRegistry;
    HyperlaneImplementation hyperlaneImplementation;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRegistry = ISuperRegistry(getContract(ETH, "SuperRegistry"));
        hyperlaneImplementation = HyperlaneImplementation(payable(superRegistry.getAmbAddress(2)));
    }

    function test_setReceiver(uint256 chainIdSeed_) public {
        /// @dev chainIds = [1, 56, 43114, 137, 42161, 10];
        uint64 chainId = chainIds[chainIdSeed_ % chainIds.length];
        vm.prank(deployer);
        hyperlaneImplementation.setReceiver(uint32(chainId), getContract(chainId, "HyperlaneImplementation"));

        assertEq(
            hyperlaneImplementation.authorizedImpl(uint32(chainId)), getContract(chainId, "HyperlaneImplementation")
        );
    }

    function test_revert_setReceiver_invalidChainId_invalidAuthorizedImpl_invalidCaller(
        uint256 chainIdSeed_,
        address malice_
    )
        public
    {
        /// @dev chainIds = [1, 56, 43114, 137, 42161, 10];
        uint64 chainId = chainIds[chainIdSeed_ % chainIds.length];
        vm.startPrank(deployer);

        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        hyperlaneImplementation.setReceiver(0, getContract(chainId, "HyperlaneImplementation"));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        hyperlaneImplementation.setReceiver(uint32(chainId), address(0));

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);

        vm.stopPrank();
        vm.prank(malice_);
        hyperlaneImplementation.setReceiver(uint32(chainId), getContract(chainId, "HyperlaneImplementation"));
    }

    function test_setChainId(uint256 superChainIdSeed_, uint256 ambChainIdSeed_) public {
        /// @dev chainIds = [1, 56, 43114, 137, 42161, 10];
        /// @dev hyperlane_chainIds = [1, 56, 43114, 137, 42161, 10];
        uint64 superChainId = chainIds[superChainIdSeed_ % chainIds.length];
        uint64 ambChainId = hyperlane_chainIds[ambChainIdSeed_ % hyperlane_chainIds.length];

        vm.prank(deployer);
        hyperlaneImplementation.setChainId(superChainId, uint32(ambChainId));

        assertEq(hyperlaneImplementation.ambChainId(superChainId), ambChainId);
        assertEq(hyperlaneImplementation.superChainId(uint32(ambChainId)), superChainId);
    }

    function test_revert_setChainId_invalidChainId_invalidCaller(
        uint256 superChainIdSeed_,
        uint256 ambChainIdSeed_,
        address malice_
    )
        public
    {
        vm.startPrank(deployer);

        uint64 superChainId = chainIds[superChainIdSeed_ % chainIds.length];
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        hyperlaneImplementation.setChainId(superChainId, 0);

        uint64 ambChainId = hyperlane_chainIds[ambChainIdSeed_ % hyperlane_chainIds.length];
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        hyperlaneImplementation.setChainId(0, uint32(ambChainId));

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.stopPrank();
        vm.assume(malice_ != deployer);
        vm.prank(malice_);
        hyperlaneImplementation.setChainId(superChainId, uint32(ambChainId));
    }

    function test_revert_dispatchPayload_invalidCaller(uint256 userSeed_, address malice_) public {
        vm.startPrank(deployer);
        uint256 userIndex = userSeed_ % users.length;

        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        (ambMessage, ambExtraData, coreStateRegistry) = setupBroadcastPayloadAMBData(users[userIndex]);

        vm.expectRevert(Error.NOT_STATE_REGISTRY.selector);
        vm.deal(malice_, 100 ether);
        vm.prank(malice_);
        hyperlaneImplementation.dispatchPayload{ value: 0.1 ether }(
            users[userIndex], chainIds[5], abi.encode(ambMessage), abi.encode(ambExtraData)
        );
    }

    function test_revert_handle_duplicatePayload_invalidSrcChainSender_invalidCaller(address malice_) public {
        vm.startPrank(deployer);
        AMBMessage memory ambMessage;

        /// @dev setting authorizedImpl[ETH] to HyperlaneImplementation on ETH, as it was smh reset to 0 (after setting
        /// in BaseSetup)
        hyperlaneImplementation.setReceiver(uint32(ETH), getContract(ETH, "HyperlaneImplementation"));

        (ambMessage,,) = setupBroadcastPayloadAMBData(address(hyperlaneImplementation));

        vm.prank(MAILBOX);
        hyperlaneImplementation.handle(
            uint32(ETH), bytes32(uint256(uint160(address(hyperlaneImplementation)))), abi.encode(ambMessage)
        );

        vm.expectRevert(Error.DUPLICATE_PAYLOAD.selector);
        vm.prank(MAILBOX);
        hyperlaneImplementation.handle(
            uint32(ETH), bytes32(uint256(uint160(address(hyperlaneImplementation)))), abi.encode(ambMessage)
        );

        vm.expectRevert(Error.INVALID_SRC_SENDER.selector);
        vm.prank(MAILBOX);
        hyperlaneImplementation.handle(uint32(ETH), bytes32(uint256(uint160(malice_))), abi.encode(ambMessage));

        vm.expectRevert(Error.CALLER_NOT_MAILBOX.selector);
        vm.prank(malice_);
        hyperlaneImplementation.handle(
            uint32(ETH), bytes32(uint256(uint160(address(hyperlaneImplementation)))), abi.encode(ambMessage)
        );
    }

    function setupBroadcastPayloadAMBData(address _srcSender)
        public
        returns (AMBMessage memory, BroadCastAMBExtraData memory, address)
    {
        AMBMessage memory ambMessage = AMBMessage(
            DataLib.packTxInfo(
                uint8(TransactionType.DEPOSIT),
                /// @dev TransactionType
                uint8(CallbackType.INIT),
                0,
                /// @dev isMultiVaults
                1,
                /// @dev STATE_REGISTRY_TYPE,
                _srcSender,
                /// @dev srcSender,
                ETH
            ),
            /// @dev srcChainId
            ""
        );
        /// ambData

        /// @dev gasFees for chainIds = [56, 43114, 137, 42161, 10];
        /// @dev excluding chainIds[0] = 1 i.e. ETH, as no point broadcasting to same chain
        uint256[] memory gasPerDst = new uint256[](5);
        for (uint256 i = 0; i < gasPerDst.length; i++) {
            gasPerDst[i] = 0.1 ether;
        }

        /// @dev keeping extraDataPerDst empty for now
        bytes[] memory extraDataPerDst = new bytes[](5);

        BroadCastAMBExtraData memory ambExtraData = BroadCastAMBExtraData(gasPerDst, extraDataPerDst);

        address coreStateRegistry = getContract(1, "CoreStateRegistry");

        vm.deal(coreStateRegistry, 10 ether);
        vm.deal(address(hyperlaneImplementation), 10 ether);

        /// @dev need to stop unused deployer prank, to use new prank, AND changePrank() doesn't work smh
        vm.stopPrank();

        return (ambMessage, ambExtraData, coreStateRegistry);
    }
}

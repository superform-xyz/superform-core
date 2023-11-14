// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import "../../../utils/CommonProtocolActions.sol";
import { AMBMessage } from "src/types/DataTypes.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { HyperlaneImplementation } from "src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol";
import { CoreStateRegistry } from "src/crosschain-data/extensions/CoreStateRegistry.sol";
import { Error } from "src/utils/Error.sol";

contract HyperlaneImplementationTest is CommonProtocolActions {
    address public constant MAILBOX = 0xc005dc82818d67AF737725bD4bf75435d065D239;
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

        (ambMessage, ambExtraData, coreStateRegistry) =
            setupBroadcastPayloadAMBData(users[userIndex], address(hyperlaneImplementation));

        vm.expectRevert(Error.NOT_STATE_REGISTRY.selector);
        vm.deal(malice_, 100 ether);
        vm.prank(malice_);
        hyperlaneImplementation.dispatchPayload{ value: 0.1 ether }(
            users[userIndex], chainIds[5], abi.encode(ambMessage), abi.encode(ambExtraData)
        );
    }

    function test_dispatchPayload_retryPayload(uint256 userSeed_) public {
        vm.startPrank(deployer);
        uint256 userIndex = userSeed_ % users.length;

        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        (ambMessage, ambExtraData, coreStateRegistry) =
            setupBroadcastPayloadAMBData(users[userIndex], address(hyperlaneImplementation));

        vm.deal(getContract(ETH, "CoreStateRegistry"), 100 ether);
        vm.prank(getContract(ETH, "CoreStateRegistry"));
        hyperlaneImplementation.dispatchPayload{ value: 0.1 ether }(
            users[userIndex], chainIds[5], abi.encode(ambMessage), abi.encode(ambExtraData)
        );
        uint32 destination = 10;
        bytes32 messageId = 0x024a45f20750393b28c9aac33aafc694857b6d09e9da4a8ed9f2b0e144685348;

        vm.prank(deployer);
        /// @dev note these values don't make sense, should be estimated properly
        hyperlaneImplementation.retryPayload{ value: 10 ether }(abi.encode(messageId, destination, 1_500_000));
    }

    function test_revert_handle_duplicatePayload_invalidSrcChainSender_invalidCaller(address malice_) public {
        vm.startPrank(deployer);
        AMBMessage memory ambMessage;

        /// @dev setting authorizedImpl[ETH] to HyperlaneImplementation on ETH, as it was smh reset to 0 (after setting
        /// in BaseSetup)
        hyperlaneImplementation.setReceiver(uint32(ETH), getContract(ETH, "HyperlaneImplementation"));

        (ambMessage,,) =
            setupBroadcastPayloadAMBData(address(hyperlaneImplementation), address(hyperlaneImplementation));

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

    function test_estimateFees_InvalidDstChainId() public {
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        hyperlaneImplementation.estimateFees(100, "", "");
    }
}

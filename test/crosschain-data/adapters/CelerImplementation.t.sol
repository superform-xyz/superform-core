// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "../../utils/BaseSetup.sol";
import {TransactionType, CallbackType, AMBMessage} from "src/types/DataTypes.sol";
import {DataLib} from "src/libraries/DataLib.sol";
import {ISuperRegistry} from "src/interfaces/ISuperRegistry.sol";
import {CelerImplementation} from "src/crosschain-data/adapters/celer/CelerImplementation.sol";
import {CoreStateRegistry} from "src/crosschain-data/extensions/CoreStateRegistry.sol";
import {Error} from "src/utils/Error.sol";

contract CelerImplementationTest is BaseSetup {
    /// @dev event emitted from CelerMessageBus on ETH (CELER_BUS)
    event Message(address indexed sender, address receiver, uint256 dstChainId, bytes message, uint256 fee);

    address public constant CELER_BUS = 0x4066D196A423b2b3B8B054f4F40efB47a74E200C;
    ISuperRegistry public superRegistry;
    CelerImplementation celerImplementation;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRegistry = ISuperRegistry(getContract(ETH, "SuperRegistry"));
        celerImplementation = CelerImplementation(payable(superRegistry.getAmbAddress(3)));
    }

    function test_setCelerBus(address celerBus_) public {
        vm.assume(celerBus_ != address(0));
        vm.prank(deployer);
        celerImplementation.setCelerBus(celerBus_);
        assertEq(address(celerImplementation.messageBus()), celerBus_);
    }

    function test_revert_setCelerBus_invalidMessageBus_invalidCaller(address malice_) public {
        vm.startPrank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        celerImplementation.setCelerBus(address(0));

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);

        vm.stopPrank();
        vm.assume(malice_ != deployer);
        vm.prank(malice_);
        celerImplementation.setCelerBus(CELER_BUS);
    }

    function test_setReceiver(uint256 chainIdSeed_) public {
        /// @dev chainIds = [1, 56, 43114, 137, 42161, 10];
        uint64 chainId = chainIds[chainIdSeed_ % chainIds.length];
        vm.prank(deployer);
        celerImplementation.setReceiver(chainId, getContract(chainId, "CelerImplementation"));

        assertEq(celerImplementation.authorizedImpl(chainId), getContract(chainId, "CelerImplementation"));
    }

    function test_revert_setReceiver_invalidChainId_invalidAuthorizedImpl_invalidCaller(address malice_) public {
        vm.startPrank(deployer);
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        celerImplementation.setReceiver(0, getContract(10, "CelerImplementation"));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        celerImplementation.setReceiver(10, address(0));

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);

        vm.stopPrank();
        vm.assume(malice_ != deployer);
        vm.prank(malice_);
        celerImplementation.setReceiver(10, getContract(10, "CelerImplementation"));
    }

    function test_setChainId(uint256 superChainIdSeed_, uint256 ambChainIdSeed_) public {
        /// @dev chainIds = [1, 56, 43114, 137, 42161, 10];
        /// @dev celer_chainIds = [1, 56, 43114, 137, 42161, 10];
        uint64 superChainId = chainIds[superChainIdSeed_ % chainIds.length];
        uint64 ambChainId = celer_chainIds[ambChainIdSeed_ % celer_chainIds.length];

        vm.prank(deployer);
        celerImplementation.setChainId(superChainId, ambChainId);

        assertEq(celerImplementation.ambChainId(superChainId), ambChainId);
        assertEq(celerImplementation.superChainId(ambChainId), superChainId);
    }

    function test_revert_setChainId_invalidChainId_invalidCaller(
        uint256 superChainIdSeed_,
        uint256 ambChainIdSeed_,
        address malice_
    ) public {
        vm.startPrank(deployer);

        uint64 superChainId = chainIds[superChainIdSeed_ % chainIds.length];
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        celerImplementation.setChainId(superChainId, 0);

        uint64 ambChainId = celer_chainIds[ambChainIdSeed_ % celer_chainIds.length];
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        celerImplementation.setChainId(0, ambChainId);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);

        vm.stopPrank();
        vm.assume(malice_ != deployer);
        vm.prank(malice_);
        celerImplementation.setChainId(superChainId, ambChainId);
    }

    function test_broadcastPayload(uint256 userSeed_) public {
        vm.startPrank(deployer);
        uint256 userIndex = userSeed_ % users.length;

        /// @dev need to call setCelerBus(), setReceiver(), setChainId() before calling broadcastPayload(),
        /// but we don't need to, as it's already done in BaseSetup
        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        (ambMessage, ambExtraData, coreStateRegistry) = setupBroadcastPayloadAMBData(users[userIndex]);

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
            users[userIndex],
            _getBroadcastChains(ETH),
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );

        vm.prank(coreStateRegistry);
        celerImplementation.broadcastPayload{value: 0.1 ether}(
            users[userIndex],
            _getBroadcastChains(ETH),
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_broadcastPayload_invalidGasDstLength(
        uint256 userSeed_,
        uint256 gasPerDstLenSeed,
        uint256 extraDataPerDstLenSeed
    ) public {
        vm.startPrank(deployer);
        uint256 userIndex = userSeed_ % users.length;
        uint256 gasPerDstLen = bound(gasPerDstLenSeed, 1, chainIds.length);
        uint256 extraDataPerDstLen = bound(extraDataPerDstLenSeed, 1, chainIds.length);
        vm.assume(gasPerDstLen != extraDataPerDstLen);

        AMBMessage memory ambMessage;
        address coreStateRegistry;

        (ambMessage, , coreStateRegistry) = setupBroadcastPayloadAMBData(users[userIndex]);

        uint256[] memory gasPerDst = new uint256[](gasPerDstLen);
        for (uint i = 0; i < gasPerDst.length; i++) {
            gasPerDst[i] = 0.1 ether;
        }

        /// @dev keeping extraDataPerDst empty for now
        bytes[] memory extraDataPerDst = new bytes[](extraDataPerDstLen);

        BroadCastAMBExtraData memory ambExtraData = BroadCastAMBExtraData(gasPerDst, extraDataPerDst);

        vm.expectRevert(Error.INVALID_EXTRA_DATA_LENGTHS.selector);
        vm.prank(coreStateRegistry);
        celerImplementation.broadcastPayload{value: 0.1 ether}(
            users[userIndex],
            _getBroadcastChains(ETH),
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_broadcastPayload_invalidCaller(uint256 userSeed_, address malice_) public {
        vm.startPrank(deployer);
        uint256 userIndex = userSeed_ % users.length;

        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        (ambMessage, ambExtraData, coreStateRegistry) = setupBroadcastPayloadAMBData(users[userIndex]);

        vm.expectRevert(Error.NOT_STATE_REGISTRY.selector);

        vm.deal(malice_, 100 ether);
        vm.prank(malice_);
        celerImplementation.broadcastPayload{value: 0.1 ether}(
            users[userIndex],
            _getBroadcastChains(ETH),
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_broadcastPayload_gasRefundFailed() public {
        vm.startPrank(deployer);
        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        /// @dev a contract that doesn't accept ETH
        address dai = getContract(1, "DAI");

        (ambMessage, ambExtraData, coreStateRegistry) = setupBroadcastPayloadAMBData(dai);

        vm.expectRevert(Error.GAS_REFUND_FAILED.selector);

        vm.prank(coreStateRegistry);
        /// @dev note first arg to be dai
        celerImplementation.broadcastPayload{value: 0.1 ether}(
            dai,
            _getBroadcastChains(ETH),
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_dispatchPayload_gasRefundFailed_invalidCaller(uint256 chainIdSeed_, address malice_) public {
        vm.startPrank(deployer);
        /// @dev chainIds = [1, 56, 43114, 137, 42161, 10];
        uint64 chainId = chainIds[chainIdSeed_ % chainIds.length];
        vm.assume(chainId != ETH);

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
            chainId,
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );

        vm.expectRevert(Error.NOT_STATE_REGISTRY.selector);
        vm.deal(malice_, 100 ether);
        vm.prank(malice_);
        celerImplementation.dispatchPayload{value: 0.1 ether}(
            users[0],
            chainId,
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_executeMessage_duplicatePayload_invalidSrcChainSender_invalidCaller(address malice_) public {
        vm.startPrank(deployer);
        AMBMessage memory ambMessage;

        (ambMessage, , ) = setupBroadcastPayloadAMBData(address(celerImplementation));

        vm.prank(deployer);
        celerImplementation.setReceiver(ETH, address(celerImplementation));

        vm.prank(CELER_BUS);
        celerImplementation.executeMessage{value: 0.1 ether}(
            address(celerImplementation),
            ETH,
            abi.encode(ambMessage),
            getContract(ETH, "CelerHelper")
        );

        vm.expectRevert(Error.DUPLICATE_PAYLOAD.selector);
        vm.prank(CELER_BUS);
        celerImplementation.executeMessage{value: 0.1 ether}(
            address(celerImplementation),
            ETH,
            abi.encode(ambMessage),
            getContract(ETH, "CelerHelper")
        );

        vm.expectRevert(Error.INVALID_SRC_SENDER.selector);
        vm.prank(CELER_BUS);
        celerImplementation.executeMessage(
            malice_, /// @dev invalid srcChainSender
            ETH,
            abi.encode(ambMessage),
            getContract(ETH, "CelerHelper")
        );

        vm.expectRevert(Error.CALLER_NOT_MESSAGE_BUS.selector);
        vm.deal(malice_, 100 ether);
        vm.prank(malice_);
        celerImplementation.executeMessage{value: 0.1 ether}(
            getContract(ETH, "CelerImplemtation"),
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
        /// come from the user via SuperformRouter
        vm.deal(coreStateRegistry, 10 ether);
        vm.deal(address(celerImplementation), 10 ether);

        /// @dev need to stop unused deployer prank, to use new prank, AND changePrank() doesn't work smh
        vm.stopPrank();

        return (ambMessage, ambExtraData, coreStateRegistry);
    }
}

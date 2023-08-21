// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "../../utils/BaseSetup.sol";
import "pigeon/src/layerzero/lib/LZPacket.sol";

import {TransactionType, CallbackType, AMBMessage} from "src/types/DataTypes.sol";
import {DataLib} from "src/libraries/DataLib.sol";
import {ISuperRegistry} from "src/interfaces/ISuperRegistry.sol";
import {IAmbImplementation} from "src/interfaces/IAmbImplementation.sol";
import {LayerzeroImplementation} from "src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol";
import {CoreStateRegistry} from "src/crosschain-data/extensions/CoreStateRegistry.sol";
import {Error} from "src/utils/Error.sol";

interface ILzEndpoint {
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);
}

contract LayerzeroImplementationTest is BaseSetup {
    /// @dev event emitted from LZ_ENDPOINT_ETH
    event UaSendVersionSet(address ua, uint16 version);
    event UaReceiveVersionSet(address ua, uint16 version);
    event UaForceResumeReceive(uint16 chainId, bytes srcAddress);
    event PayloadReceived(uint64 srcChainId, uint64 dstChainId, uint256 payloadId);

    address public constant LZ_ENDPOINT_ETH = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
    address public constant LZ_ENDPOINT_OP = 0x3c2269811836af69497E5F486A85D7316753cf62;

    address public constant CHAINLINK_lzOracle = 0x150A58e9E6BF69ccEb1DBA5ae97C166DC8792539;
    ISuperRegistry public superRegistry;
    LayerzeroImplementation layerzeroImplementation;
    address public bond;
    bytes public srcAddressOP;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRegistry = ISuperRegistry(getContract(ETH, "SuperRegistry"));
        layerzeroImplementation = LayerzeroImplementation(payable(superRegistry.getAmbAddress(1)));

        srcAddressOP = abi.encodePacked(
            getContract(ETH, "LayerzeroImplementation"),
            getContract(OP, "LayerzeroImplementation")
        );

        /// @dev malicious caller
        bond = address(7);
        /// @dev (who's a brokie)
        vm.deal(bond, 1 ether);
    }

    function test_setLzEndpoint(address lzEndPoint_) public {
        /// @dev resetting lzEndpoint's storage slot to 0 (which was set in BaseSetup)
        vm.store(address(layerzeroImplementation), bytes32(uint256(0)), bytes32(uint256(0)));
        vm.assume(lzEndPoint_ != address(0));
        console.log(address(layerzeroImplementation.lzEndpoint()));

        vm.prank(deployer);
        layerzeroImplementation.setLzEndpoint(lzEndPoint_);

        assertEq(address(layerzeroImplementation.lzEndpoint()), lzEndPoint_);
    }

    function test_revert_setLzEndpoint_invalidLzEndpoint_invalidCaller(address malice_) public {
        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        layerzeroImplementation.setLzEndpoint(address(0));

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);

        vm.assume(malice_ != deployer);
        vm.prank(malice_);
        layerzeroImplementation.setLzEndpoint(LZ_ENDPOINT_ETH);
    }

    function test_setChainId(uint256 superChainIdSeed_, uint256 ambChainIdSeed_) public {
        /// @dev chainIds = [1, 56, 43114, 137, 42161, 10];
        /// @dev lz_chainIds = [101, 102, 106, 109, 110, 111];
        uint64 superChainId = chainIds[superChainIdSeed_ % chainIds.length];
        uint16 ambChainId = lz_chainIds[ambChainIdSeed_ % lz_chainIds.length];

        vm.prank(deployer);
        layerzeroImplementation.setChainId(superChainId, ambChainId);

        assertEq(layerzeroImplementation.ambChainId(superChainId), ambChainId);
        assertEq(layerzeroImplementation.superChainId(ambChainId), superChainId);
    }

    function test_estimateFeesWithInvalidChainId(uint64 chainId) public {
        /// @dev chainIds = [1, 56, 43114, 137, 42161, 10];
        /// @dev notice chainId = 1 is invalid
        vm.assume(chainId != 137 && chainId != 42161 && chainId != 10 && chainId != 56 && chainId != 43114);
        uint256 fees = layerzeroImplementation.estimateFees(chainId, abi.encode(420), bytes(""));
        assertEq(fees, 0);
    }

    function test_estimateFeesWithValidChainId(uint256 chainIdSeed_) public {
        /// @dev chainIds = [1, 56, 43114, 137, 42161, 10];
        uint64 chainId = chainIds[chainIdSeed_ % chainIds.length];
        /// @dev estimating fees for same chain is invalid
        vm.assume(chainId != 1);
        uint256 fees = layerzeroImplementation.estimateFees(chainId, abi.encode(420), bytes(""));
        assertGt(fees, 0);
    }

    function test_revert_setChainId_invalidChainId_invalidCaller(
        uint256 superChainIdSeed_,
        uint256 ambChainIdSeed_,
        address malice_
    ) public {
        vm.startPrank(deployer);

        uint64 superChainId = chainIds[superChainIdSeed_ % chainIds.length];
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        layerzeroImplementation.setChainId(superChainId, 0);

        uint16 ambChainId = lz_chainIds[ambChainIdSeed_ % lz_chainIds.length];
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        layerzeroImplementation.setChainId(0, ambChainId);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);

        vm.stopPrank();
        vm.assume(malice_ != deployer);
        vm.prank(malice_);
        layerzeroImplementation.setChainId(superChainId, ambChainId);
    }

    function test_setConfig_getConfig_and_revert_invalidCaller(
        uint16 versionSeed_,
        uint16 chainIdSeed_,
        address malice_
    ) public {
        /// @dev chainIds = [1, 56, 43114, 137, 42161, 10];
        uint16 chainId = uint16(chainIds[chainIdSeed_ % chainIds.length]);
        /// @dev remoteChainId on LzLibrary cannot be current fork's chainId
        // vm.assume(chainId != 1);
        uint16 version = uint16(bound(versionSeed_, 0, 3));

        vm.prank(deployer);
        /// @dev our configType = 6
        layerzeroImplementation.setConfig(version, chainId, 6, abi.encode(CHAINLINK_lzOracle));

        bytes memory response = layerzeroImplementation.getConfig(version, chainId, address(0), 6);
        assertEq(response, abi.encode(CHAINLINK_lzOracle));

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(malice_);
        layerzeroImplementation.setConfig(version, chainId, 6, abi.encode(CHAINLINK_lzOracle));
    }

    function test_setSendVersion_and_revert_invalidCaller(uint16 versionSeed_, address malice_) public {
        uint16 version = uint16(bound(versionSeed_, 0, 3));

        vm.expectEmit(false, false, false, true, LZ_ENDPOINT_ETH);
        emit UaSendVersionSet(address(layerzeroImplementation), version);
        vm.prank(deployer);
        layerzeroImplementation.setSendVersion(version);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(malice_);
        layerzeroImplementation.setSendVersion(version);
    }

    function test_setReceiveVersion_and_revert_invalidCaller(uint16 versionSeed_, address malice_) public {
        uint16 version = uint16(bound(versionSeed_, 0, 3));

        vm.expectEmit(false, false, false, true, LZ_ENDPOINT_ETH);
        emit UaReceiveVersionSet(address(layerzeroImplementation), version);
        vm.prank(deployer);
        layerzeroImplementation.setReceiveVersion(version);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(malice_);
        layerzeroImplementation.setReceiveVersion(version);
    }

    /// @dev uint64[] public chainIds = [1, 56, 43114, 137, 42161, 10];
    /// @dev uint16[] public lz_chainIds = [101, 102, 106, 109, 110, 111];
    function test_setTrustedRemote_isTrustedRemote_and_revert_invalidCaller(
        uint16 chainIdSeed_,
        address malice_
    ) public {
        uint16 chainId = uint16(chainIds[chainIdSeed_ % chainIds.length]);
        vm.assume(chainId != ETH);
        uint16 lzChainId = uint16(lz_chainIds[chainIdSeed_ % lz_chainIds.length]);
        bytes memory srcAddress = abi.encodePacked(
            getContract(ETH, "LayerzeroImplementation"),
            getContract(chainId, "LayerzeroImplementation")
        );

        vm.prank(deployer);
        layerzeroImplementation.setTrustedRemote(lzChainId, srcAddress);

        assertEq(layerzeroImplementation.isTrustedRemote(lzChainId, srcAddress), true);

        uint16 newChainId = uint16(chainIds[(chainIdSeed_ / 2) % chainIds.length]);
        vm.assume(newChainId != ETH);
        uint16 newLzChainId = uint16(lz_chainIds[(chainIdSeed_ / 2) % lz_chainIds.length]);
        bytes memory newSrcAddress = abi.encodePacked(
            getContract(newChainId, "LayerzeroImplementation"),
            address(layerzeroImplementation)
        );

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(malice_);
        layerzeroImplementation.setTrustedRemote(newLzChainId, newSrcAddress);
    }

    function test_forceResumeReceive_and_revert_invalidCaller(address malice_) public {
        vm.selectFork(FORKS[ETH]);

        _depositFromETHtoOP(0);

        vm.selectFork(FORKS[OP]);
        LayerzeroImplementation lzImplOP = LayerzeroImplementation(payable(getContract(OP, "LayerzeroImplementation")));
        /// @dev verify the msg to be present in LZ_ENDPOINT_OP.storedPayload[][]
        /// @dev 101 is lz_chainId for ETH
        assertEq(ILzEndpoint(LZ_ENDPOINT_OP).hasStoredPayload(101, srcAddressOP), true);

        /// @dev first testing revert on invalid caller
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(malice_);
        lzImplOP.forceResumeReceive(101, srcAddressOP);

        /// @dev remove the unexecuted blocked msg from LZ_ENDPOINT_OP, using forceResumeReceive()
        vm.prank(deployer);
        lzImplOP.forceResumeReceive(101, srcAddressOP);

        /// @dev verify the msg to be removed from LZ_ENDPOINT_OP
        assertEq(ILzEndpoint(LZ_ENDPOINT_OP).hasStoredPayload(101, srcAddressOP), false);
    }

    function test_retryMessage_and_revert_invalidPayload_invalidPayloadState() public {
        _resetCoreStateRegistry(FORKS[OP], false);

        vm.selectFork(FORKS[ETH]);

        Vm.Log[] memory logs = _depositFromETHtoOP(500000);

        _resetCoreStateRegistry(FORKS[OP], true);

        bytes memory payload;
        for (uint256 i; i < logs.length; i++) {
            Vm.Log memory log = logs[i];

            if (log.topics[0] == 0xe9bded5f24a4168e4f3bf44e00298c993b22376aad8c58c7dda9718a54cbea82) {
                bytes memory _data = abi.decode(log.data, (bytes));
                LayerZeroPacket.Packet memory _packet = LayerZeroPacket.getPacket(_data);
                payload = _packet.payload;
            }
        }

        LayerzeroImplementation lzImplOP = LayerzeroImplementation(payable(getContract(OP, "LayerzeroImplementation")));

        vm.expectRevert(Error.ZERO_PAYLOAD_HASH.selector);
        /// @dev NOTE nonce = 1, instead of 2
        lzImplOP.retryMessage(101, srcAddressOP, 1, payload);

        bytes memory invalidPayload = hex"0007";
        vm.expectRevert(Error.INVALID_PAYLOAD_HASH.selector);
        lzImplOP.retryMessage(101, srcAddressOP, 2, invalidPayload);

        vm.expectEmit(false, false, false, true, getContract(OP, "CoreStateRegistry"));
        emit PayloadReceived(ETH, OP, 1);
        lzImplOP.retryMessage(101, srcAddressOP, 2, payload);
    }

    function test_revert_broadcastPayload_invalidCaller(uint8 userSeed_, address malice_) public {
        uint256 userIndex = userSeed_ % users.length;

        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        (ambMessage, ambExtraData, coreStateRegistry) = _setupBroadcastPayloadAMBData(users[userIndex]);

        vm.expectRevert(Error.NOT_STATE_REGISTRY.selector);
        vm.deal(malice_, 100 ether);
        vm.prank(malice_);
        layerzeroImplementation.broadcastPayload{value: 0.1 ether}(
            users[userIndex],
            _getBroadcastChains(ETH),
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_broadcastPayload_invalidExtraDataLengths(
        uint256 userSeed_,
        uint256 gasPerDstLenSeed_,
        uint256 extraDataPerDstLenSeed_
    ) public {
        uint256 userIndex = userSeed_ % users.length;
        uint256 gasPerDstLen = bound(gasPerDstLenSeed_, 1, chainIds.length);
        uint256 extraDataPerDstLen = bound(extraDataPerDstLenSeed_, 1, chainIds.length);
        vm.assume(gasPerDstLen != extraDataPerDstLen);

        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        (ambMessage, , coreStateRegistry) = _setupBroadcastPayloadAMBData(users[userIndex]);

        uint256[] memory gasPerDst = new uint256[](gasPerDstLen);
        for (uint i = 0; i < gasPerDst.length; i++) {
            gasPerDst[i] = 0.1 ether;
        }

        /// @dev keeping extraDataPerDst empty for now
        bytes[] memory extraDataPerDst = new bytes[](extraDataPerDstLen);

        ambExtraData = BroadCastAMBExtraData(gasPerDst, extraDataPerDst);

        vm.expectRevert(Error.INVALID_EXTRA_DATA_LENGTHS.selector);
        vm.prank(coreStateRegistry);
        layerzeroImplementation.broadcastPayload{value: 0.1 ether}(
            users[userIndex],
            _getBroadcastChains(ETH),
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_dispatchPayload_invalidCaller_invalidSrcChainId(
        uint64 chainId,
        uint256 userSeed_,
        address malice_
    ) public {
        uint256 userIndex = userSeed_ % users.length;
        vm.assume(
            chainId != 1 && chainId != 56 && chainId != 43114 && chainId != 137 && chainId != 42161 && chainId != 10
        );

        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        (ambMessage, ambExtraData, coreStateRegistry) = _setupBroadcastPayloadAMBData(users[userIndex]);

        vm.expectRevert(Error.NOT_STATE_REGISTRY.selector);

        vm.deal(malice_, 100 ether);
        vm.prank(malice_);
        layerzeroImplementation.dispatchPayload{value: 0.1 ether}(
            users[userIndex],
            chainId,
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );

        vm.expectRevert(Error.INVALID_SRC_CHAIN_ID.selector);
        vm.prank(coreStateRegistry);
        /// @dev notice the use of chainId, whose trustedRemote is not set
        layerzeroImplementation.dispatchPayload{value: 0.1 ether}(
            users[userIndex],
            chainId,
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_lzReceive_invalidCaller_duplicatePayload_invalidSrcSender() public {
        vm.selectFork(FORKS[ETH]);

        Vm.Log[] memory logs = _depositFromETHtoOP(500000);

        bytes memory payload;
        for (uint256 i; i < logs.length; i++) {
            Vm.Log memory log = logs[i];

            if (log.topics[0] == 0xe9bded5f24a4168e4f3bf44e00298c993b22376aad8c58c7dda9718a54cbea82) {
                bytes memory _data = abi.decode(log.data, (bytes));
                LayerZeroPacket.Packet memory _packet = LayerZeroPacket.getPacket(_data);
                payload = _packet.payload;
            }
        }

        vm.selectFork(FORKS[OP]);

        LayerzeroImplementation lzImplOP = LayerzeroImplementation(payable(getContract(OP, "LayerzeroImplementation")));

        vm.expectRevert(Error.CALLER_NOT_ENDPOINT.selector);
        vm.prank(bond);
        lzImplOP.lzReceive(101, srcAddressOP, 2, payload);

        vm.expectRevert(Error.DUPLICATE_PAYLOAD.selector);
        vm.prank(LZ_ENDPOINT_OP);
        lzImplOP.lzReceive(101, srcAddressOP, 2, payload);

        vm.expectRevert(Error.INVALID_SRC_SENDER.selector);
        vm.prank(LZ_ENDPOINT_OP);
        /// @dev notice the use of 111 (OP's lz_chainId as srcChainId on OP) instead of 101 (ETH's)
        lzImplOP.lzReceive(111, srcAddressOP, 2, payload);
    }

    function test_revert_nonblockingLzReceive_invalidCaller(uint16 lzChainIdSeed_, address malice_) public {
        vm.expectRevert(Error.CALLER_NOT_ENDPOINT.selector);
        uint16 lzChainId = lz_chainIds[lzChainIdSeed_ % lz_chainIds.length];

        vm.prank(malice_);
        layerzeroImplementation.nonblockingLzReceive(lzChainId, srcAddressOP, "");
    }

    function _depositFromETHtoOP(uint256 gasLimit_) internal returns (Vm.Log[] memory) {
        bytes memory crossChainMsg = abi.encode(AMBMessage(DataLib.packTxInfo(0, 1, 1, 1, deployer, ETH), bytes("")));

        address coreStateRegistryETH = getContract(ETH, "CoreStateRegistry");
        vm.deal(coreStateRegistryETH, 1 ether);
        vm.prank(coreStateRegistryETH);

        vm.recordLogs();
        layerzeroImplementation.dispatchPayload{value: 1 ether}(bond, OP, crossChainMsg, bytes(""));
        Vm.Log[] memory logs = vm.getRecordedLogs();

        /// @dev payload will fail in _nonblockLzReceive
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).help(
            LZ_ENDPOINT_OP,
            gasLimit_, /// note: using `0` to get the payload stored in LZ_ENDPOINT
            FORKS[OP],
            logs
        );

        return logs;
    }

    function _resetCoreStateRegistry(uint256 forkId, bool isReset) internal {
        vm.selectFork(forkId);

        SuperRegistry superRegistryOP = SuperRegistry(getContract(OP, "SuperRegistry"));

        vm.prank(deployer);

        uint8[] memory registryId_ = new uint8[](1);
        registryId_[0] = 1;

        address[] memory registryAddress_ = new address[](1);
        registryAddress_[0] = isReset ? getContract(OP, "CoreStateRegistry") : address(1);
        superRegistryOP.setStateRegistryAddress(registryId_, registryAddress_);
    }

    function _setupBroadcastPayloadAMBData(
        address _srcSender
    ) internal returns (AMBMessage memory, BroadCastAMBExtraData memory, address) {
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
        /// @dev bcoz we're simulating layerzeroImplementation.broadcastPayload() from CoreStateRegistry (below),
        /// we need sufficient ETH in CoreStateRegistry and LayerzeroImplementation. On mainnet, these funds will
        /// come from the user via SuperformRouter
        vm.deal(coreStateRegistry, 10 ether);
        vm.deal(address(layerzeroImplementation), 10 ether);

        return (ambMessage, ambExtraData, coreStateRegistry);
    }
}

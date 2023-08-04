// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "../utils/BaseSetup.sol";
import "../../../lib/pigeon/src/layerzero/lib/LZPacket.sol";

import {TransactionType, CallbackType, AMBMessage} from "../../types/DataTypes.sol";
import {DataLib} from "../../libraries/DataLib.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {LayerzeroImplementation} from "../../crosschain-data/adapters/layerzero/LayerzeroImplementation.sol";
import {CoreStateRegistry} from "../../crosschain-data/extensions/CoreStateRegistry.sol";
import {Error} from "../../utils/Error.sol";

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

    function test_setLzEndpoint() public {
        /// @dev resetting lzEndpoint's storage slot to 0 (which was set in BaseSetup)
        vm.store(address(layerzeroImplementation), bytes32(uint256(1)), bytes32(uint256(0)));

        vm.startPrank(deployer);
        layerzeroImplementation.setLzEndpoint(LZ_ENDPOINT_OP); /// optimism

        assertEq(address(layerzeroImplementation.lzEndpoint()), LZ_ENDPOINT_OP);
    }

    function test_setChainId() public {
        vm.startPrank(deployer);
        layerzeroImplementation.setChainId(10, 10); /// optimism
        layerzeroImplementation.setChainId(137, 137); /// polygon

        assertEq(layerzeroImplementation.ambChainId(10), 10);
        assertEq(layerzeroImplementation.superChainId(137), 137);
    }

    function test_revert_setChainId_invalidChainId_invalidCaller() public {
        vm.startPrank(deployer);
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        layerzeroImplementation.setChainId(10, 0); /// optimism

        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        layerzeroImplementation.setChainId(0, 10); /// optimism

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.stopPrank();
        vm.prank(bond);
        layerzeroImplementation.setChainId(137, 137); /// polygon
    }

    function test_setConfig_getConfig_and_revert_invalidCaller() public {
        vm.startPrank(deployer);
        layerzeroImplementation.setConfig(0, 10, 6, abi.encode(CHAINLINK_lzOracle));

        bytes memory response = layerzeroImplementation.getConfig(0, 10, address(0), 6);
        assertEq(abi.encode(CHAINLINK_lzOracle), response);

        /// @dev testing revert here and not separately, to avoid making the call above twice and facing
        /// the error, 'You cannot overwrite `prank` until it is applied at least once' otherwise
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.stopPrank();
        vm.prank(bond);
        layerzeroImplementation.setConfig(0, 10, 6, abi.encode(CHAINLINK_lzOracle));
    }

    function test_setSendVersion_and_revert_invalidCaller() public {
        vm.startPrank(deployer);
        vm.expectEmit(false, false, false, true, LZ_ENDPOINT_ETH);
        emit UaSendVersionSet(address(layerzeroImplementation), 2);

        layerzeroImplementation.setSendVersion(2);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.stopPrank();
        vm.prank(bond);
        layerzeroImplementation.setSendVersion(5);
    }

    function test_setReceiveVersion_and_revert_invalidCaller() public {
        vm.startPrank(deployer);
        vm.expectEmit(false, false, false, true, LZ_ENDPOINT_ETH);
        emit UaReceiveVersionSet(address(layerzeroImplementation), 2);

        layerzeroImplementation.setReceiveVersion(2);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.stopPrank();
        vm.prank(bond);
        layerzeroImplementation.setReceiveVersion(5);
    }

    /// @dev uint64[] public chainIds = [1, 56, 43114, 137, 42161, 10];
    /// @dev uint16[] public lz_chainIds = [101, 102, 106, 109, 110, 111];
    function test_setTrustedRemote_isTrustedRemote_and_revert_invalidCaller() public {
        vm.startPrank(deployer);
        layerzeroImplementation.setTrustedRemote(111, srcAddressOP);

        assertEq(layerzeroImplementation.isTrustedRemote(111, srcAddressOP), true);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.stopPrank();
        vm.prank(bond);
        bytes memory srcAddressPOLY = abi.encodePacked(
            getContract(POLY, "LayerzeroImplementation"),
            address(layerzeroImplementation)
        );
        layerzeroImplementation.setTrustedRemote(109, srcAddressPOLY);
    }

    function test_forceResumeReceive_and_revert_invalidCaller() public {
        vm.selectFork(FORKS[ETH]);

        _depositfromETHtoOP(0);

        vm.selectFork(FORKS[OP]);

        /// @dev verify the msg to be present in LZ_ENDPOINT_OP.storedPayload[][]
        /// @dev 101 is lz_chainId for ETH
        assertEq(ILzEndpoint(LZ_ENDPOINT_OP).hasStoredPayload(101, srcAddressOP), true);

        /// @dev first testing revert on invalid caller
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        layerzeroImplementation.forceResumeReceive(101, srcAddressOP);

        /// @dev remove the unexecuted blocked msg from LZ_ENDPOINT_OP, using forceResumeReceive()
        vm.prank(deployer);
        layerzeroImplementation.forceResumeReceive(101, srcAddressOP);

        /// @dev verify the msg to be removed from LZ_ENDPOINT_OP
        assertEq(ILzEndpoint(LZ_ENDPOINT_OP).hasStoredPayload(101, srcAddressOP), false);
    }

    function test_retryMessage_and_revert_invalidPayload_invalidPayloadState() public {
        _resetCoreStateRegistry(FORKS[OP], false);

        vm.selectFork(FORKS[ETH]);

        Vm.Log[] memory logs = _depositfromETHtoOP(500000);

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

        vm.expectRevert(Error.ZERO_PAYLOAD_HASH.selector);
        /// @dev NOTE nonce = 1, instead of 2
        layerzeroImplementation.retryMessage(101, srcAddressOP, 1, payload);

        bytes memory invalidPayload = hex"0007";
        vm.expectRevert(Error.INVALID_PAYLOAD_HASH.selector);
        layerzeroImplementation.retryMessage(101, srcAddressOP, 2, invalidPayload);

        vm.expectEmit(false, false, false, true, getContract(ETH, "CoreStateRegistry"));
        emit PayloadReceived(ETH, OP, 1);
        layerzeroImplementation.retryMessage(101, srcAddressOP, 2, payload);
    }

    function test_revert_broadcastPayload_invalidCaller() public {
        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        (ambMessage, ambExtraData, coreStateRegistry) = _setupBroadcastPayloadAMBData(users[0]);

        vm.expectRevert(Error.NOT_STATE_REGISTRY.selector);

        vm.prank(bond);
        layerzeroImplementation.broadcastPayload{value: 0.1 ether}(
            users[0],
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_dispatchPayload_invalidCaller_invalidSrcChainId() public {
        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        (ambMessage, ambExtraData, coreStateRegistry) = _setupBroadcastPayloadAMBData(users[0]);

        vm.expectRevert(Error.NOT_STATE_REGISTRY.selector);

        vm.prank(bond);
        layerzeroImplementation.dispatchPayload{value: 0.1 ether}(
            users[0],
            chainIds[5],
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );

        vm.expectRevert(Error.INVALID_SRC_CHAIN_ID.selector);
        vm.prank(coreStateRegistry);
        /// @dev NOTE the use of zkSync's chainId: 324, whose trustedRemote is not set
        layerzeroImplementation.dispatchPayload{value: 0.1 ether}(
            users[0],
            324,
            abi.encode(ambMessage),
            abi.encode(ambExtraData)
        );
    }

    function test_revert_lzReceive_invalidCaller_duplicatePayload_invalidSrcSender() public {
        vm.selectFork(FORKS[ETH]);

        Vm.Log[] memory logs = _depositfromETHtoOP(500000);

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

        vm.expectRevert(Error.CALLER_NOT_ENDPOINT.selector);

        vm.prank(bond);
        layerzeroImplementation.lzReceive(101, srcAddressOP, 2, payload);

        vm.expectRevert(Error.DUPLICATE_PAYLOAD.selector);
        vm.prank(LZ_ENDPOINT_OP);
        layerzeroImplementation.lzReceive(101, srcAddressOP, 2, payload);

        vm.expectRevert(Error.INVALID_SRC_SENDER.selector);
        vm.prank(LZ_ENDPOINT_OP);
        /// @dev NOTE the use of 111 (OP's lz_chainId as srcChainId on OP) instead of 101 (ETH's)
        layerzeroImplementation.lzReceive(111, srcAddressOP, 2, payload);
    }

    function test_revert_nonblockingLzReceive_invalidCaller() public {
        vm.expectRevert(Error.CALLER_NOT_ENDPOINT.selector);

        vm.prank(bond);
        layerzeroImplementation.nonblockingLzReceive(111, srcAddressOP, "");
    }

    function _depositfromETHtoOP(uint256 gasLimit_) internal returns (Vm.Log[] memory) {
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
        vm.prank(deployer);

        uint8[] memory registryId_ = new uint8[](1);
        registryId_[0] = 1;

        address[] memory registryAddress_ = new address[](1);
        registryAddress_[0] = isReset ? getContract(OP, "CoreStateRegistry") : address(1);
        superRegistry.setStateRegistryAddress(registryId_, registryAddress_);
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
        /// come from the user via SuperFormRouter
        vm.deal(coreStateRegistry, 10 ether);
        vm.deal(address(layerzeroImplementation), 10 ether);

        return (ambMessage, ambExtraData, coreStateRegistry);
    }
}

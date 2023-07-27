// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "../utils/BaseSetup.sol";
import {TransactionType, CallbackType, AMBMessage} from "../../types/DataTypes.sol";
import {DataLib} from "../../libraries/DataLib.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {LayerzeroImplementation} from "../../crosschain-data/adapters/layerzero/LayerzeroImplementation.sol";
import {CoreStateRegistry} from "../../crosschain-data/extensions/CoreStateRegistry.sol";
import {Error} from "../../utils/Error.sol";
import "../utils/ProtocolActions.sol";
import "../../../lib/pigeon/src/layerzero/lib/LZPacket.sol";

interface ILzEndpoint {
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);
}

contract LayerzeroImplementationTest is ProtocolActions {
    /// @dev event emitted from LZ_ENDPOINT_ETH
    event UaSendVersionSet(address ua, uint16 version);
    event UaReceiveVersionSet(address ua, uint16 version);
    event UaForceResumeReceive(uint16 chainId, bytes srcAddress);

    address public constant LZ_ENDPOINT_ETH = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
    address public constant LZ_ENDPOINT_OP = 0x3c2269811836af69497E5F486A85D7316753cf62;

    address public constant CHAINLINK_lzOracle = 0x150A58e9E6BF69ccEb1DBA5ae97C166DC8792539;
    ISuperRegistry public superRegistry;
    LayerzeroImplementation layerzeroImplementation;
    address public bond;

    function setUp() public override {
        super.setUp();

        ////////////// forceResumeReceive(), retryMessage() setup //////////////
        AMBs = [1, 3];
        CHAIN_0 = OP;
        DST_CHAINS = [ETH];
        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ETH][0] = [1];
        TARGET_VAULTS[ETH][0] = [0]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ETH][0] = [0];
        AMOUNTS[ETH][0] = [133];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[ETH][0] = [1];

        ///////////////////// remaining funcs setup ///////////////////////
        vm.selectFork(FORKS[ETH]);
        superRegistry = ISuperRegistry(getContract(ETH, "SuperRegistry"));
        layerzeroImplementation = LayerzeroImplementation(payable(superRegistry.getAmbAddress(1)));
        /// @dev malicious caller
        bond = address(7);
        /// @dev (who's a brokie)
        vm.deal(bond, 1 ether);
    }

    function test_forceResumeReceive_and_revert_invalidCaller() public {
        depositfromOPtoETH();

        vm.selectFork(FORKS[ETH]);

        /// @dev Simulate receiving the same msg, with same nonce (by re-using same logs from Stage 2 - 3 of
        /// @dev the previous successful msg), but this time with 0 gasLimit from Lzhelper,
        /// @dev so that txn gets stuck in LZ_ENDPOINT_ETH.storedPayload[][]
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).help(
            LZ_ENDPOINT_ETH,
            0, /// NOTE: 0 gasLimit ensures revert
            FORKS[ETH],
            srcLogs /// @dev -> repeated logs
        );

        bytes memory srcAddressOP = abi.encodePacked(
            getContract(ETH, "LayerzeroImplementation"),
            getContract(OP, "LayerzeroImplementation")
        );
        /// @dev verify the msg to be present in LZ_ENDPOINT_ETH.storedPayload[][]
        /// @dev 111 is lz_chainId for OP
        assertEq(ILzEndpoint(LZ_ENDPOINT_ETH).hasStoredPayload(111, srcAddressOP), true);

        /// @dev first testing revert on invalid caller
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        layerzeroImplementation.forceResumeReceive(111, srcAddressOP);

        /// @dev remove the unexecuted blocked msg from LZ_ENDPOINT_ETH, using forceResumeReceive()
        vm.prank(deployer);
        layerzeroImplementation.forceResumeReceive(111, srcAddressOP);

        /// @dev verify the msg to be removed from LZ_ENDPOINT_ETH
        assertEq(ILzEndpoint(LZ_ENDPOINT_ETH).hasStoredPayload(111, srcAddressOP), false);
    }

    function test_retryMessage_and_revert_invalidPayload_invalidPayloadState_duplicatePayload() public {
        depositfromOPtoETH();

        vm.selectFork(FORKS[ETH]);

        bytes memory srcAddressOP = abi.encodePacked(
            getContract(ETH, "LayerzeroImplementation"),
            getContract(OP, "LayerzeroImplementation")
        );

        /// @dev duplicate msg (with same nonce as previous successful action)
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).help(LZ_ENDPOINT_ETH, 5000000, FORKS[ETH], srcLogs);

        // console.log("FAILED_MESSAGES");
        // console.logBytes32(layerzeroImplementation.failedMessages(111, srcAddressOP, 2));
        // console.log(ILzEndpoint(LZ_ENDPOINT_ETH).hasStoredPayload(111, srcAddressOP));

        bytes memory payload = abi.decode(srcLogs[0].data, (bytes));

        vm.expectRevert(Error.INVALID_PAYLOAD_STATE.selector);
        /// @dev NOTE nonce = 1, instead of 2
        layerzeroImplementation.retryMessage(111, srcAddressOP, 1, payload);

        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        layerzeroImplementation.retryMessage(111, srcAddressOP, 2, payload);

        // LayerZeroPacket.Packet memory packet = LayerZeroPacket.getPacket(payload);

        /// @dev FIXME: the line above throws arithmetic over/underflow error, hence hardcoding the payload in this call for now
        bytes
            memory fixedPayload = hex"0000000000000000000000000000000000000000000000000000000000000020000000000000000a7e5f4552091a69125d5dfcb7b8c2659029395bdf0100000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000001000000015c77b7ee63b818289ba07c96e78bd2b43a6b10bb000000000000000000000000000000000000000000000000000000000000008500000000000000000000000000000000000000000000000000000000000003e800000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000";
        vm.expectRevert(Error.DUPLICATE_PAYLOAD.selector);
        layerzeroImplementation.retryMessage(111, srcAddressOP, 2, fixedPayload);
    }

    function test_revert_broadcastPayload_invalidCaller() public {
        AMBMessage memory ambMessage;
        BroadCastAMBExtraData memory ambExtraData;
        address coreStateRegistry;

        (ambMessage, ambExtraData, coreStateRegistry) = setupBroadcastPayloadAMBData(users[0]);

        vm.expectRevert(Error.INVALID_CALLER.selector);
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

        (ambMessage, ambExtraData, coreStateRegistry) = setupBroadcastPayloadAMBData(users[0]);

        vm.expectRevert(Error.INVALID_CALLER.selector);
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

    function test_revert_lzReceive_invalidCaller_invalidSrcSender() public {
        bytes memory srcAddressOP = abi.encodePacked(
            getContract(ETH, "LayerzeroImplementation"),
            getContract(OP, "LayerzeroImplementation")
        );

        vm.expectRevert(Error.INVALID_CALLER.selector);
        vm.prank(bond);
        layerzeroImplementation.lzReceive(111, srcAddressOP, 1, "");

        vm.expectRevert(Error.INVALID_SRC_SENDER.selector);
        vm.prank(LZ_ENDPOINT_ETH);
        /// @dev NOTE the use of 101 (ETH's lz_chainId) instead of 111 (optimism's)
        layerzeroImplementation.lzReceive(101, srcAddressOP, 1, "");
    }

    function test_revert_nonblockingLzReceive_invalidCaller() public {
        bytes memory srcAddressOP = abi.encodePacked(
            getContract(ETH, "LayerzeroImplementation"),
            getContract(OP, "LayerzeroImplementation")
        );

        vm.expectRevert(Error.INVALID_CALLER.selector);
        vm.prank(bond);
        layerzeroImplementation.nonblockingLzReceive(111, srcAddressOP, 1, "");
    }

    function test_setLzEndpoint() public {
        vm.startPrank(deployer);
        layerzeroImplementation.setLzEndpoint(LZ_ENDPOINT_OP); /// optimism

        /// @dev lzEndPoint doesn't change as it's only supposed to be called once (which it was in BaseSetup)
        assertEq(address(layerzeroImplementation.lzEndpoint()), LZ_ENDPOINT_ETH);
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
        vm.prank(bond);
        layerzeroImplementation.setConfig(0, 10, 6, abi.encode(CHAINLINK_lzOracle));
    }

    function test_setSendVersion_and_revert_invalidCaller() public {
        vm.startPrank(deployer);
        vm.expectEmit(false, false, false, true, LZ_ENDPOINT_ETH);
        emit UaSendVersionSet(address(layerzeroImplementation), 2);

        layerzeroImplementation.setSendVersion(2);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        layerzeroImplementation.setSendVersion(5);
    }

    function test_setReceiveVersion_and_revert_invalidCaller() public {
        vm.startPrank(deployer);
        vm.expectEmit(false, false, false, true, LZ_ENDPOINT_ETH);
        emit UaReceiveVersionSet(address(layerzeroImplementation), 2);

        layerzeroImplementation.setReceiveVersion(2);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        layerzeroImplementation.setReceiveVersion(5);
    }

    /// @dev uint64[] public chainIds = [1, 56, 43114, 137, 42161, 10];
    /// @dev uint16[] public lz_chainIds = [101, 102, 106, 109, 110, 111];
    function test_setTrustedRemote_isTrustedRemote_and_revert_invalidCaller() public {
        vm.startPrank(deployer);
        bytes memory srcAddressOP = abi.encodePacked(
            getContract(OP, "LayerzeroImplementation"),
            address(layerzeroImplementation)
        );
        layerzeroImplementation.setTrustedRemote(111, srcAddressOP);

        assertEq(layerzeroImplementation.isTrustedRemote(111, srcAddressOP), true);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        bytes memory srcAddressPOLY = abi.encodePacked(
            getContract(POLY, "LayerzeroImplementation"),
            address(layerzeroImplementation)
        );
        layerzeroImplementation.setTrustedRemote(109, srcAddressPOLY);
    }

    function depositfromOPtoETH() internal {
        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: true,
                externalToken: 1 // 0 = DAI, 1 = USDT, 2 = WETH
            })
        );

        /// @dev send first msg (deposit) from ETH to OP
        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperFormsData;
            SingleVaultSFData[] memory singleSuperFormsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            _runMainStages(action, act, multiSuperFormsData, singleSuperFormsData, aV, vars, success);
        }
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
        /// @dev bcoz we're simulating layerzeroImplementation.broadcastPayload() from CoreStateRegistry (below),
        /// we need sufficient ETH in CoreStateRegistry and LayerzeroImplementation. On mainnet, these funds will
        /// come from the user via SuperFormRouter
        vm.deal(coreStateRegistry, 10 ether);
        vm.deal(address(layerzeroImplementation), 10 ether);

        return (ambMessage, ambExtraData, coreStateRegistry);
    }
}

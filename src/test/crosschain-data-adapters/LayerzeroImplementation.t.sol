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

interface ILzEndpoint {
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);
}

contract LayerzeroImplementationTest is ProtocolActions {
    /// @dev event emitted from CelerMessageBus on ETH (LZ_ENDPOINT)
    event UaSendVersionSet(address ua, uint16 version);
    event UaReceiveVersionSet(address ua, uint16 version);
    event UaForceResumeReceive(uint16 chainId, bytes srcAddress);

    address public constant LZ_ENDPOINT = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
    address public constant CHAINLINK_lzOracle = 0x150A58e9E6BF69ccEb1DBA5ae97C166DC8792539;
    ISuperRegistry public superRegistry;
    LayerzeroImplementation layerzeroImplementation;
    address public bond;
    uint256 public snapId;
    Vm.Log[] public depositSrcLogs;

    function setUp() public override {
        super.setUp();

        ////////////// forceResumeReceive(), retryMessage() setup //////////////
        AMBs = [1, 3];
        CHAIN_0 = ETH;
        DST_CHAINS = [OP];
        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][0] = [1];
        TARGET_VAULTS[OP][0] = [0]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[OP][0] = [0];
        AMOUNTS[OP][0] = [133];
        MAX_SLIPPAGE = 1000;
        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[OP][0] = [1];

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
        depositETHtoOP();
        /// @dev Resend the same msg, with same nonce (by re-using same logs from Stage 2 - 3 of 
        /// @dev the previous successful msg), so as to block this msg in LZ_ENDPOINT
        LayerZeroHelper(getContract(CHAIN_0, "LayerZeroHelper")).help(
            LZ_ENDPOINT,
            5000000, /// note: using some max limit
            FORKS[ETH],
            srcLogs /// @dev -> repeated logs
        );

        bytes memory srcAddressETH = abi.encodePacked(getContract(ETH, "LayerzeroImplementation"), getContract(OP, "LayerzeroImplementation"));
        /// @dev verify the msg to be present in LZ_ENDPOINT.storedPayload[][]
        /// @dev 101 is lz_chainId for ETH
        assertEq(ILzEndpoint(LZ_ENDPOINT).hasStoredPayload(101, srcAddressETH), true);

        /// @dev first testing revert on invalid caller
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        layerzeroImplementation.forceResumeReceive(101, srcAddressETH);

        /// @dev remove the unexecuted blocked msg from LZ_ENDPOINT, using forceResumeReceive()
        vm.prank(deployer);
        layerzeroImplementation.forceResumeReceive(101, srcAddressETH);

        /// @dev verify the msg to be removed from LZ_ENDPOINT
        assertEq(ILzEndpoint(LZ_ENDPOINT).hasStoredPayload(101, srcAddressETH), false);
    }

    function test_retryMessage() public {
        depositETHtoOP();
        /// @dev record a successful deposit's logs with gasLimit 5m, in our test state
        for(uint256 i = 0; i < srcLogs.length; i++) {
            depositSrcLogs.push(srcLogs[i]);
        }
        /// @dev revert the state to before the deposit
        vm.revertTo(snapId);

        /// @dev execute deposit with 0 gasLimit, so that it fails
        LayerZeroHelper(getContract(CHAIN_0, "LayerZeroHelper")).help(
            LZ_ENDPOINT,
            0,
            FORKS[ETH],
            depositSrcLogs
        );

        bytes memory srcAddressETH = abi.encodePacked(getContract(ETH, "LayerzeroImplementation"), getContract(OP, "LayerzeroImplementation"));
        console.log("FAILED_MESSAGES");
        console.logBytes32(layerzeroImplementation.failedMessages(101, srcAddressETH, 2));
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
        vm.expectEmit(false, false, false, true, LZ_ENDPOINT);
        emit UaSendVersionSet(address(layerzeroImplementation), 2);

        layerzeroImplementation.setSendVersion(2);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        layerzeroImplementation.setSendVersion(5);
    }

    function test_setReceiveVersion_and_revert_invalidCaller() public {
        vm.startPrank(deployer);
        vm.expectEmit(false, false, false, true, LZ_ENDPOINT);
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
        bytes memory srcAddressOP = abi.encodePacked(getContract(OP, "LayerzeroImplementation"), address(layerzeroImplementation));
        layerzeroImplementation.setTrustedRemote(111, srcAddressOP);

        assertEq(layerzeroImplementation.isTrustedRemote(111, srcAddressOP), true);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        bytes memory srcAddressPOLY = abi.encodePacked(getContract(POLY, "LayerzeroImplementation"), address(layerzeroImplementation));
        layerzeroImplementation.setTrustedRemote(109, srcAddressPOLY);
    }

    function depositETHtoOP() internal {
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

        snapId = vm.snapshot();
        /// @dev send first msg (deposit) from ETH to OP
        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultsSFData[] memory multiSuperFormsData;
            SingleVaultSFData[] memory singleSuperFormsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            _runMainStages(action, act, multiSuperFormsData, singleSuperFormsData, aV, vars, success);
        }
    }
}

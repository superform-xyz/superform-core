// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@std/Test.sol";
import "@ds-test/test.sol";
import "forge-std/console.sol";
import {LayerZeroHelper} from "@pigeon/layerzero/LayerZeroHelper.sol";
import {FixedPointMathLib} from "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";
import {LZEndpointMock} from "contracts/mocks/LzEndpointMock.sol";
import {VaultMock} from "contracts/mocks/VaultMock.sol";
import {IStateHandler} from "contracts/interface/layerzero/IStateHandler.sol";
import {StateHandler} from "contracts/layerzero/stateHandler.sol";
import {IController} from "contracts/interface/ISource.sol";
import {IDestination} from "contracts/interface/IDestination.sol";
import {IERC4626} from "contracts/interface/IERC4626.sol";
import {SuperRouter} from "contracts/SuperRouter.sol";
import {SuperDestination} from "contracts/SuperDestination.sol";
import {SocketRouterMockFork} from "../mocks/SocketRouterMockFork.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";
import "contracts/types/socketTypes.sol";
import "contracts/types/lzTypes.sol";

struct SetupVars {
    uint16[2] chainIds;
    address[2] lzEndpoints;
    uint16 chainId;
    uint16 dstChainId;
    uint256 fork;
    address lzEndpoint;
    address lzHelper;
    address socketRouter;
    address superDestination;
    address stateHandler;
    address UNDERLYING_TOKEN;
    address vault;
    address srcSuperRouter;
    address srcStateHandler;
    address srcSuperDestination;
    address destStateHandler;
}

struct DepositArgs {
    address underlyingSrcToken;
    address payable fromSrc; // SuperRouter
    address payable toDst; // SuperDestination
    address toLzEndpoint;
    address user;
    StateReq stateReq;
    LiqRequest liqReq;
    uint256 amount;
    uint16 srcChainId;
    uint16 toChainId;
}

struct WithdrawArgs {
    address payable fromSrc; // SuperRouter
    address payable toDst; // SuperDestination
    address toLzEndpoint;
    address user;
    StateReq stateReq;
    LiqRequest liqReq;
    uint256 amount;
    uint16 srcChainId;
    uint16 toChainId;
}

struct BuildDepositArgs {
    address fromSrc;
    address toDst;
    address underlyingSrcToken;
    uint256 targetVaultId;
    uint256 amount;
    uint16 srcChainId;
    uint16 toChainId;
}

struct BuildWithdrawArgs {
    address fromSrc;
    address toDst;
    address underlyingDstToken;
    uint256 targetVaultId;
    uint256 amount;
    uint16 srcChainId;
    uint16 toChainId;
}

error ETH_TRANSFER_FAILED();
error INVALID_UNDERLYING_TOKEN_NAME();

abstract contract BaseSetup is DSTest, Test {
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public deployer = address(777);
    address[] public users;
    mapping(uint16 => mapping(bytes32 => address)) public contracts;

    /*//////////////////////////////////////////////////////////////
                        PROTOCOL VARIABLES
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant CORE_CONTRACTS_ROLE =
        keccak256("CORE_CONTRACTS_ROLE");
    bytes32 public constant PROCESSOR_CONTRACTS_ROLE =
        keccak256("PROCESSOR_CONTRACTS_ROLE");

    string public UNDERLYING_TOKEN;
    string public VAULT_NAME;

    mapping(uint16 => IERC4626[]) vaults;
    mapping(uint16 => uint256[]) vaultIds;

    uint8[] bridgeIds;
    address[] bridgeAddresses;

    /*//////////////////////////////////////////////////////////////
                        LAYER ZERO VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(uint16 => address) public LZ_ENDPOINTS;

    address public constant ETH_lzEndpoint =
        0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
    address public constant BSC_lzEndpoint =
        0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant AVAX_lzEndpoint =
        0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant POLY_lzEndpoint =
        0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant ARBI_lzEndpoint =
        0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant OP_lzEndpoint =
        0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant FTM_lzEndpoint =
        0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;

    /// @dev reference for chain ids https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
    uint16 public constant ETH = 101;
    uint16 public constant BSC = 102;
    uint16 public constant AVAX = 106;
    uint16 public constant POLY = 109;
    uint16 public constant ARBI = 110;
    uint16 public constant OP = 111;
    uint16 public constant FTM = 112;

    uint16 public constant version = 1;
    uint256 public constant gasLimit = 1000000;
    uint256 public constant mockEstimatedNativeFee = 1000000000000000; // 0.001 Native Tokens
    uint256 public constant mockEstimatedZroFee = 250000000000000; // 0.00025 Native Tokens
    uint256 public constant milionTokensE18 = 1 ether;

    /*//////////////////////////////////////////////////////////////
                        CHAINLINK VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(uint16 => address) public PRICE_FEEDS;

    address public constant ETHEREUM_ETH_USD_FEED =
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public constant BSC_BNB_USD_FEED =
        0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    address public constant AVALANCHE_AVAX_USD_FEED =
        0x0A77230d17318075983913bC2145DB16C7366156;
    address public constant POLYGON_MATIC_USD_FEED =
        0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
    address public constant FANTOM_FTM_USD_FEED =
        0xf4766552D15AE4d256Ad41B6cf2933482B0680dc;

    /*//////////////////////////////////////////////////////////////
                        RPC VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(uint16 => uint256) public FORKS;
    mapping(uint16 => string) public RPC_URLS;

    string public ETHEREUM_RPC_URL = vm.envString("ETHEREUM_RPC_URL"); // Native token: ETH
    string public BSC_RPC_URL = vm.envString("BSC_RPC_URL"); // Native token: BNB
    string public AVALANCHE_RPC_URL = vm.envString("AVALANCHE_RPC_URL"); // Native token: AVAX
    string public POLYGON_RPC_URL = vm.envString("POLYGON_RPC_URL"); // Native token: MATIC
    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL"); // Native token: ETH
    string public OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC_URL"); // Native token: ETH
    string public FANTOM_RPC_URL = vm.envString("FANTOM_RPC_URL"); // Native token: FTM

    /*//////////////////////////////////////////////////////////////
                        TESTS SELECTION VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public lzEndpoint_0;
    address public lzEndpoint_1;
    uint16 public CHAIN_0;
    uint16 public CHAIN_1;

    function setUp() public virtual {
        _preDeploymentSetup();

        _deployProtocol();
    }

    function getContract(uint16 chainId, string memory _name)
        public
        view
        returns (address)
    {
        return contracts[chainId][bytes32(bytes(_name))];
    }

    /*//////////////////////////////////////////////////////////////
                        PROTOCOL DEPLOYMENT
    //////////////////////////////////////////////////////////////*/

    function _deployProtocol() internal {
        SetupVars memory vars;

        vars.chainIds = [CHAIN_0, CHAIN_1];
        vars.lzEndpoints = [lzEndpoint_0, lzEndpoint_1];
        _fundNativeTokens(vars.chainIds);

        vm.startPrank(deployer);
        /// @dev deployments
        for (uint256 i = 0; i < vars.chainIds.length; i++) {
            vars.chainId = vars.chainIds[i];
            vars.fork = FORKS[vars.chainId];
            vm.selectFork(vars.fork);

            /// @dev 1- deploy LZ Helper from Pigeon
            vars.lzHelper = address(new LayerZeroHelper());
            vm.allowCheatcodes(vars.lzHelper);

            contracts[vars.chainId][bytes32(bytes("LayerZeroHelper"))] = vars
                .lzHelper;

            /// @dev 2- deploy StateHandler pointing to lzEndpoints (constants)
            vars.stateHandler = address(new StateHandler(vars.lzEndpoints[i]));
            contracts[vars.chainId][bytes32(bytes("StateHandler"))] = vars
                .stateHandler;

            /// @dev 3- deploy SocketRouterMockFork
            vars.socketRouter = address(new SocketRouterMockFork());
            contracts[vars.chainId][
                bytes32(bytes("SocketRouterMockFork"))
            ] = vars.socketRouter;
            vm.allowCheatcodes(vars.socketRouter);

            if (i == 0) {
                bridgeAddresses.push(vars.socketRouter);
            }

            /// @dev 4 - Deploy mock UNDERLYING_TOKEN with 18 decimals
            vars.UNDERLYING_TOKEN = address(
                new MockERC20(
                    UNDERLYING_TOKEN,
                    UNDERLYING_TOKEN,
                    18,
                    deployer,
                    milionTokensE18
                )
            );
            contracts[vars.chainId][bytes32(bytes(UNDERLYING_TOKEN))] = vars
                .UNDERLYING_TOKEN;

            /// @dev 5 - Deploy mock Vault
            vars.vault = address(
                new VaultMock(
                    MockERC20(vars.UNDERLYING_TOKEN),
                    string.concat(UNDERLYING_TOKEN, "Vault"),
                    string.concat(UNDERLYING_TOKEN, "Vault")
                )
            );
            contracts[vars.chainId][
                bytes32(bytes(string.concat(UNDERLYING_TOKEN, "Vault")))
            ] = vars.vault;

            vaults[vars.chainId].push(IERC4626(vars.vault));
            vaultIds[vars.chainId].push(1);

            /// @dev 6 - Deploy SuperDestination
            vars.superDestination = address(
                new SuperDestination(
                    vars.chainId,
                    IStateHandler(payable(vars.stateHandler))
                )
            );
            contracts[vars.chainId][bytes32(bytes("SuperDestination"))] = vars
                .superDestination;

            /// @dev 7 - Deploy SuperRouter
            contracts[vars.chainId][bytes32(bytes("SuperRouter"))] = address(
                new SuperRouter(
                    vars.chainId,
                    "test.com/",
                    IStateHandler(payable(vars.stateHandler)),
                    IDestination(vars.superDestination)
                )
            );
        }
        _fundUnderlyingTokens(vars.chainIds, 1);

        for (uint256 i = 0; i < vars.chainIds.length; i++) {
            vars.chainId = vars.chainIds[i];
            vars.fork = FORKS[vars.chainId];
            vm.selectFork(vars.fork);

            vars.dstChainId = vars.chainId == CHAIN_0 ? CHAIN_1 : CHAIN_0;

            vars.srcStateHandler = getContract(vars.chainId, "StateHandler");
            vars.srcSuperRouter = getContract(vars.chainId, "SuperRouter");
            vars.srcSuperDestination = getContract(
                vars.chainId,
                "SuperDestination"
            );

            vars.destStateHandler = getContract(
                vars.dstChainId,
                "StateHandler"
            );

            /// @dev - Add vaults to super destination
            SuperDestination(payable(vars.srcSuperDestination)).addVault(
                vaults[vars.chainId],
                vaultIds[vars.chainId]
            );

            SuperDestination(payable(vars.srcSuperDestination))
                .updateSafeGasParam(abi.encodePacked(version, gasLimit));

            /// @dev - RBAC
            StateHandler(payable(vars.srcStateHandler)).setHandlerController(
                IController(vars.srcSuperRouter),
                IController(vars.srcSuperDestination)
            );

            StateHandler(payable(vars.srcStateHandler)).grantRole(
                CORE_CONTRACTS_ROLE,
                vars.srcSuperRouter
            );
            StateHandler(payable(vars.srcStateHandler)).grantRole(
                CORE_CONTRACTS_ROLE,
                vars.srcSuperDestination
            );
            StateHandler(payable(vars.srcStateHandler)).grantRole(
                PROCESSOR_CONTRACTS_ROLE,
                deployer
            );

            StateHandler(payable(vars.srcStateHandler)).setTrustedRemote(
                vars.dstChainId,
                abi.encodePacked(vars.srcStateHandler, vars.destStateHandler)
            );

            /// @dev - Set bridge addresses
            SuperRouter(payable(vars.srcSuperRouter)).setBridgeAddress(
                bridgeIds,
                bridgeAddresses
            );
            SuperDestination(payable(vars.srcSuperDestination))
                .setBridgeAddress(bridgeIds, bridgeAddresses);
        }
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                    PROTOCOL INTERACTION HELPERS
    //////////////////////////////////////////////////////////////*/

    function _depositToVault(DepositArgs memory args) internal {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[args.srcChainId]);

        /// @dev - APPROVE transfer to SuperRouter
        vm.prank(args.user);

        MockERC20(args.underlyingSrcToken).approve(args.fromSrc, args.amount);

        vm.selectFork(FORKS[args.toChainId]);

        StateReq[] memory stateReqs = new StateReq[](1);
        LiqRequest[] memory liqReqs = new LiqRequest[](1);

        stateReqs[0] = args.stateReq;
        liqReqs[0] = args.liqReq;

        vm.selectFork(FORKS[args.srcChainId]);

        /// @dev - DEPOSIT to super router
        uint256 msgValue = 1 * _getPriceMultiplier(args.srcChainId) * 1e18;
        vm.prank(args.user);
        /// @dev see pigeon for this implementation
        vm.recordLogs();
        /// @dev Value == fee paid to relayer. API call in our design
        SuperRouter(args.fromSrc).deposit{value: msgValue}(liqReqs, stateReqs);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        /// @dev see pigeon for this implementation
        LayerZeroHelper(getContract(args.srcChainId, "LayerZeroHelper"))
            .helpWithEstimates(
                args.toLzEndpoint,
                1000000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
                FORKS[args.toChainId],
                logs
            );

        /// @dev - assert the payload reached destination state handler
        InitData memory expectedInitData = InitData(
            args.srcChainId,
            args.toChainId,
            args.user,
            args.stateReq.vaultIds,
            args.stateReq.amounts,
            args.stateReq.maxSlippage,
            SuperRouter(args.fromSrc).totalTransactions(),
            bytes("")
        );
        vm.selectFork(FORKS[args.toChainId]);

        StateHandler stateHandler = StateHandler(
            payable(getContract(args.toChainId, "StateHandler"))
        );

        StateData memory data = abi.decode(
            stateHandler.payload(stateHandler.totalPayloads()),
            (StateData)
        );
        InitData memory receivedInitData = abi.decode(data.params, (InitData));

        assertEq(receivedInitData.srcChainId, expectedInitData.srcChainId);
        assertEq(receivedInitData.dstChainId, expectedInitData.dstChainId);
        assertEq(receivedInitData.user, expectedInitData.user);
        assertEq(receivedInitData.vaultIds[0], expectedInitData.vaultIds[0]);
        assertEq(receivedInitData.amounts[0], expectedInitData.amounts[0]);
        assertEq(
            receivedInitData.maxSlippage[0],
            expectedInitData.maxSlippage[0]
        );
        assertEq(receivedInitData.txId, expectedInitData.txId);

        vm.selectFork(initialFork);
    }

    function _withdrawFromVault(WithdrawArgs memory args) internal {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[args.srcChainId]);

        StateReq[] memory stateReqs = new StateReq[](1);
        LiqRequest[] memory liqReqs = new LiqRequest[](1);

        stateReqs[0] = args.stateReq;
        liqReqs[0] = args.liqReq;

        /// @dev - WITHDRAW from super router
        uint256 msgValue = 1 * _getPriceMultiplier(args.srcChainId) * 1e18;
        vm.prank(args.user);
        /// @dev see pigeon for this implementation
        vm.recordLogs();
        /// @dev Value == fee paid to relayer. API call in our design
        SuperRouter(args.fromSrc).withdraw{value: msgValue}(stateReqs, liqReqs);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        LayerZeroHelper(getContract(args.srcChainId, "LayerZeroHelper"))
            .helpWithEstimates(
                args.toLzEndpoint,
                1000000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
                FORKS[args.toChainId],
                logs
            );

        /// @dev - assert the payload reached destination state handler
        InitData memory expectedInitData = InitData(
            args.srcChainId,
            args.toChainId,
            args.user,
            args.stateReq.vaultIds,
            args.stateReq.amounts,
            args.stateReq.maxSlippage,
            SuperRouter(args.fromSrc).totalTransactions(),
            bytes("")
        );
        vm.selectFork(FORKS[args.toChainId]);

        StateHandler stateHandler = StateHandler(
            payable(getContract(args.toChainId, "StateHandler"))
        );

        StateData memory data = abi.decode(
            stateHandler.payload(stateHandler.totalPayloads()),
            (StateData)
        );
        InitData memory receivedInitData = abi.decode(data.params, (InitData));

        assertEq(receivedInitData.srcChainId, expectedInitData.srcChainId);
        assertEq(receivedInitData.dstChainId, expectedInitData.dstChainId);
        assertEq(receivedInitData.user, expectedInitData.user);
        assertEq(receivedInitData.vaultIds[0], expectedInitData.vaultIds[0]);
        assertEq(receivedInitData.amounts[0], expectedInitData.amounts[0]);
        assertEq(
            receivedInitData.maxSlippage[0],
            expectedInitData.maxSlippage[0]
        );
        assertEq(receivedInitData.txId, expectedInitData.txId);

        vm.selectFork(initialFork);
    }

    function _buildDepositCallData(BuildDepositArgs memory args)
        internal
        returns (StateReq memory stateReq, LiqRequest memory liqReq)
    {
        /// @dev set to empty bytes for now
        bytes memory adapterParam;
        /*
            adapterParam = abi.encodePacked(version, gasLimit);
        */

        /// @dev only testing 1 vault at a time for now
        uint256[] memory amountsToDeposit = new uint256[](1);
        uint256[] memory targetVaultIds = new uint256[](1);
        uint256[] memory slippage = new uint256[](1);

        amountsToDeposit[0] = args.amount;
        targetVaultIds[0] = args.targetVaultId;
        slippage[0] = 1000;

        uint256 msgValue = 1 * _getPriceMultiplier(args.srcChainId) * 1e18;

        stateReq = StateReq(
            args.toChainId,
            amountsToDeposit,
            targetVaultIds,
            slippage,
            adapterParam,
            msgValue
        );

        /// @dev build socket tx data for a mock socket transfer (using new Mock contract because of the two forks)
        bytes memory socketTxData = abi.encodeWithSignature(
            "mockSocketTransfer(address,address,address,uint256,uint256)",
            args.fromSrc,
            args.toDst,
            args.underlyingSrcToken,
            args.amount,
            FORKS[args.toChainId]
        );

        liqReq = LiqRequest(
            1,
            socketTxData,
            args.underlyingSrcToken,
            getContract(args.srcChainId, "SocketRouterMockFork"),
            args.amount,
            0
        );
    }

    function _buildWithdrawCallData(BuildWithdrawArgs memory args)
        internal
        returns (StateReq memory stateReq, LiqRequest memory liqReq)
    {
        /// @dev set to empty bytes for now
        bytes memory adapterParam;

        /// @dev only testing 1 vault at a time for now
        uint256[] memory amountsToDeposit = new uint256[](1);
        uint256[] memory targetVaultIds = new uint256[](1);
        uint256[] memory slippage = new uint256[](1);

        amountsToDeposit[0] = args.amount;
        targetVaultIds[0] = args.targetVaultId;
        slippage[0] = 1000;

        uint256 msgValue = 1 * _getPriceMultiplier(args.srcChainId) * 1e18;

        stateReq = StateReq(
            args.toChainId,
            amountsToDeposit,
            targetVaultIds,
            slippage,
            adapterParam,
            msgValue
        );

        bytes memory socketTxData = abi.encodeWithSignature(
            "mockSocketTransfer(address,address,address,uint256,uint256)",
            args.toDst,
            args.fromSrc,
            args.underlyingDstToken,
            args.amount,
            FORKS[args.toChainId]
        );

        liqReq = LiqRequest(
            1,
            socketTxData,
            args.underlyingDstToken,
            getContract(args.srcChainId, "SocketRouterMockFork"),
            args.amount,
            0
        );
    }

    function _updateState(
        uint256 payloadId_,
        uint256 finalAmount_,
        uint16 targetChainId_
    ) internal {
        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[targetChainId_]);
        uint256[] memory finalAmounts = new uint256[](1);
        finalAmounts[0] = finalAmount_;

        vm.prank(deployer);
        StateHandler(payable(getContract(targetChainId_, "StateHandler")))
            .updateState(payloadId_, finalAmounts);

        vm.selectFork(initialFork);
    }

    function _processPayload(uint256 payloadId_, uint16 targetChainId_)
        internal
    {
        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[targetChainId_]);

        uint256 msgValue = 1 * _getPriceMultiplier(targetChainId_) * 1e18;

        bytes memory hashZero;
        vm.prank(deployer);
        StateHandler(payable(getContract(targetChainId_, "StateHandler")))
            .processPayload{value: msgValue}(payloadId_, hashZero);

        vm.selectFork(initialFork);
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _preDeploymentSetup() internal {
        mapping(uint16 => uint256) storage forks = FORKS;
        forks[ETH] = vm.createFork(ETHEREUM_RPC_URL);
        forks[BSC] = vm.createFork(BSC_RPC_URL);
        forks[AVAX] = vm.createFork(AVALANCHE_RPC_URL);
        forks[POLY] = vm.createFork(POLYGON_RPC_URL);
        forks[ARBI] = vm.createFork(ARBITRUM_RPC_URL);
        forks[OP] = vm.createFork(OPTIMISM_RPC_URL);
        forks[FTM] = vm.createFork(FANTOM_RPC_URL);

        mapping(uint16 => string) storage rpcURLs = RPC_URLS;
        rpcURLs[ETH] = ETHEREUM_RPC_URL;
        rpcURLs[BSC] = BSC_RPC_URL;
        rpcURLs[AVAX] = AVALANCHE_RPC_URL;
        rpcURLs[POLY] = POLYGON_RPC_URL;
        rpcURLs[ARBI] = ARBITRUM_RPC_URL;
        rpcURLs[OP] = OPTIMISM_RPC_URL;
        rpcURLs[FTM] = FANTOM_RPC_URL;

        mapping(uint16 => address) storage lzEndpointsStorage = LZ_ENDPOINTS;
        lzEndpointsStorage[ETH] = ETH_lzEndpoint;
        lzEndpointsStorage[BSC] = BSC_lzEndpoint;
        lzEndpointsStorage[AVAX] = AVAX_lzEndpoint;
        lzEndpointsStorage[POLY] = POLY_lzEndpoint;
        lzEndpointsStorage[ARBI] = ARBI_lzEndpoint;
        lzEndpointsStorage[OP] = OP_lzEndpoint;
        lzEndpointsStorage[FTM] = FTM_lzEndpoint;

        lzEndpoint_0 = lzEndpointsStorage[CHAIN_0];
        lzEndpoint_1 = lzEndpointsStorage[CHAIN_1];

        mapping(uint16 => address) storage priceFeeds = PRICE_FEEDS;
        priceFeeds[ETH] = ETHEREUM_ETH_USD_FEED;
        priceFeeds[BSC] = BSC_BNB_USD_FEED;
        priceFeeds[AVAX] = AVALANCHE_AVAX_USD_FEED;
        priceFeeds[POLY] = POLYGON_MATIC_USD_FEED;
        priceFeeds[ARBI] = address(0);
        priceFeeds[OP] = address(0);
        priceFeeds[FTM] = FANTOM_FTM_USD_FEED;

        VAULT_NAME = string.concat(UNDERLYING_TOKEN, "Vault");

        /// @dev setup bridges. Only bridgeId 1 available for tests (Socket)
        bridgeIds.push(1);

        /// @dev setup users
        users.push(address(1));
        users.push(address(2));
        users.push(address(3));
        users.push(address(4));
        users.push(address(5));
        users.push(address(6));
        users.push(address(7));
        users.push(address(8));
        users.push(address(9));
        users.push(address(10));
    }

    function _fundNativeTokens(uint16[2] memory chainIds) internal {
        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.selectFork(FORKS[chainIds[i]]);

            uint256 multiplier = _getPriceMultiplier(chainIds[i]);

            uint256 amountDeployer = 100000 * multiplier * 1e18;
            uint256 amountUSER = 1000 * multiplier * 1e18;

            vm.deal(deployer, amountDeployer);

            vm.deal(address(1), amountUSER);
            vm.deal(address(2), amountUSER);
            vm.deal(address(3), amountUSER);
            vm.deal(address(4), amountUSER);
            vm.deal(address(5), amountUSER);
            vm.deal(address(6), amountUSER);
            vm.deal(address(7), amountUSER);
            vm.deal(address(8), amountUSER);
            vm.deal(address(9), amountUSER);
            vm.deal(address(10), amountUSER);
        }
    }

    function _getPriceMultiplier(uint16 targetChainId_)
        internal
        returns (uint256)
    {
        uint256 multiplier;

        if (
            targetChainId_ == ETH ||
            targetChainId_ == ARBI ||
            targetChainId_ == OP
        ) {
            /// @dev default multiplier for chains with ETH native token

            multiplier = 1;
        } else {
            uint256 initialFork = vm.activeFork();

            vm.selectFork(FORKS[ETH]);

            int256 ethUsdPrice = _getLatestPrice(PRICE_FEEDS[ETH]);

            vm.selectFork(FORKS[targetChainId_]);
            int256 price = _getLatestPrice(PRICE_FEEDS[targetChainId_]);

            multiplier = uint256(ethUsdPrice / price);

            /// @dev return to initial fork

            vm.selectFork(initialFork);
        }

        return multiplier;
    }

    function _getLatestPrice(address priceFeed_)
        internal
        view
        returns (int256)
    {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface(priceFeed_).latestRoundData();
        return price;
    }

    function _fundUnderlyingTokens(uint16[2] memory chainIds, uint256 amount)
        internal
    {
        if (getContract(chainIds[0], UNDERLYING_TOKEN) == address(0))
            revert INVALID_UNDERLYING_TOKEN_NAME();

        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.selectFork(FORKS[chainIds[i]]);
            address token = getContract(chainIds[i], UNDERLYING_TOKEN);
            deal(token, address(1), 1 ether * amount);
            deal(token, address(2), 1 ether * amount);
            deal(token, address(3), 1 ether * amount);
            deal(token, address(4), 1 ether * amount);
            deal(token, address(5), 1 ether * amount);
            deal(token, address(6), 1 ether * amount);
            deal(token, address(7), 1 ether * amount);
            deal(token, address(8), 1 ether * amount);
            deal(token, address(9), 1 ether * amount);
            deal(token, address(10), 1 ether * amount);
        }
    }
}

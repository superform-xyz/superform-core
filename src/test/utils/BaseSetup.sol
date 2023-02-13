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
    address destSuperDestination;
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

struct BuildWithdrawArgs {
    address fromSrc;
    address toDst;
    address underlyingDstToken;
    uint256 targetVaultId;
    uint256 amount;
    uint256 msgValue;
    uint16 srcChainId;
    uint16 toChainId;
}

error ETH_TRANSFER_FAILED();
error INVALID_UNDERLYING_TOKEN_NAME();

abstract contract BaseSetup is DSTest, Test {
    using FixedPointMathLib for uint256;

    bytes32 public constant CORE_CONTRACTS_ROLE =
        keccak256("CORE_CONTRACTS_ROLE");
    bytes32 public constant PROCESSOR_CONTRACTS_ROLE =
        keccak256("PROCESSOR_CONTRACTS_ROLE");

    mapping(uint16 => mapping(bytes32 => address)) public contracts;
    mapping(uint16 => uint256) public FORKS;
    mapping(uint16 => IERC4626[]) vaults;
    mapping(uint16 => uint256[]) vaultIds;

    uint8[] bridgeIds;
    address[] bridgeAddresses;

    /// @dev safe gas params for LZ
    uint16 constant version = 1;
    uint256 constant gasLimit = 1000000;

    uint256 constant mockEstimatedNativeFee = 1000000000000000; // 0.001 Native Tokens
    uint256 constant mockEstimatedZroFee = 250000000000000; // 0.00025 Native Tokens
    uint256 public constant milionTokensE18 = 1 ether;

    address public deployer = address(777);
    address[] public users;

    function setUp() public virtual {
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

    function _deployProtocol(
        string memory RPC_URL_0,
        string memory RPC_URL_1,
        address lzEndpoint_1,
        address lzEndpoint_2,
        uint16 ID_0,
        uint16 ID_1,
        string memory underlyingTokenName
    ) internal {
        SetupVars memory vars;

        vars.chainIds = [ID_0, ID_1];
        vars.lzEndpoints = [lzEndpoint_1, lzEndpoint_2];

        FORKS[ID_0] = vm.createFork(RPC_URL_0);
        FORKS[ID_1] = vm.createFork(RPC_URL_1);

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
                    underlyingTokenName,
                    underlyingTokenName,
                    18,
                    deployer,
                    milionTokensE18
                )
            );
            contracts[vars.chainId][bytes32(bytes(underlyingTokenName))] = vars
                .UNDERLYING_TOKEN;

            /// @dev 5 - Deploy mock Vault
            vars.vault = address(
                new VaultMock(
                    MockERC20(vars.UNDERLYING_TOKEN),
                    string.concat(underlyingTokenName, "Vault"),
                    string.concat(underlyingTokenName, "Vault")
                )
            );
            contracts[vars.chainId][
                bytes32(bytes(string.concat(underlyingTokenName, "Vault")))
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

        _fundUnderlyingTokens(vars.chainIds, 1, underlyingTokenName);

        for (uint256 i = 0; i < vars.chainIds.length; i++) {
            vars.chainId = vars.chainIds[i];
            vars.fork = FORKS[vars.chainId];
            vm.selectFork(vars.fork);

            vars.dstChainId = vars.chainId == ID_0 ? ID_1 : ID_0;

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
            vars.destSuperDestination = getContract(
                vars.dstChainId,
                "SuperDestination"
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

    function _buildDepositCallData(
        address fromSrc,
        address toDst,
        address underlyingSrcToken,
        uint256 targetVaultId,
        uint256 amount,
        uint256 msgValue,
        uint16 srcChainId,
        uint16 toChainId
    )
        internal
        view
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

        amountsToDeposit[0] = amount;
        targetVaultIds[0] = targetVaultId;
        slippage[0] = 1000;

        stateReq = StateReq(
            toChainId,
            amountsToDeposit,
            targetVaultIds,
            slippage,
            adapterParam,
            msgValue
        );

        /// @dev build socket tx data for a mock socket transfer (using new Mock contract because of the two forks)
        bytes memory socketTxData = abi.encodeWithSignature(
            "mockSocketTransfer(address,address,address,uint256,uint256)",
            fromSrc,
            toDst,
            underlyingSrcToken,
            amount,
            FORKS[toChainId]
        );

        liqReq = LiqRequest(
            1,
            socketTxData,
            underlyingSrcToken,
            getContract(srcChainId, "SocketRouterMockFork"),
            amount,
            0
        );
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
        /// @dev Mocking gas fee airdrop (native) from layerzero
        /// @dev This value can be lower
        /*
        vm.prank(deployer);
        (bool success, ) = args.toDst.call{value: 1 ether}(new bytes(0));
        if (!success) revert ETH_TRANSFER_FAILED();
        */

        StateReq[] memory stateReqs = new StateReq[](1);
        LiqRequest[] memory liqReqs = new LiqRequest[](1);

        stateReqs[0] = args.stateReq;
        liqReqs[0] = args.liqReq;

        vm.selectFork(FORKS[args.srcChainId]);

        /// @dev - DEPOSIT to super router
        vm.prank(args.user);
        /// @dev see pigeon for this implementation
        vm.recordLogs();
        /// @dev Value == fee paid to relayer. API call in our design
        SuperRouter(args.fromSrc).deposit{value: 2 ether}(liqReqs, stateReqs);
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
        vm.prank(args.user);
        /// @dev see pigeon for this implementation
        vm.recordLogs();
        /// @dev Value == fee paid to relayer. API call in our design
        SuperRouter(args.fromSrc).withdraw{value: 2 ether}(stateReqs, liqReqs);
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

    function _buildWithdrawCallData(BuildWithdrawArgs memory args)
        internal
        view
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

        stateReq = StateReq(
            args.toChainId,
            amountsToDeposit,
            targetVaultIds,
            slippage,
            adapterParam,
            args.msgValue
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

        bytes memory hashZero;
        vm.prank(deployer);
        /// @dev WARNING - must check with LZ why estimates are so high in this case
        StateHandler(payable(getContract(targetChainId_, "StateHandler")))
            .processPayload{value: 100 ether}(payloadId_, hashZero);

        vm.selectFork(initialFork);
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _fundNativeTokens(uint16[2] memory chainIds) internal {
        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.selectFork(FORKS[chainIds[i]]);
            vm.deal(deployer, 100000 ether);

            vm.deal(address(1), 1000 ether);
            vm.deal(address(2), 1000 ether);
            vm.deal(address(3), 1000 ether);
            vm.deal(address(4), 1000 ether);
            vm.deal(address(5), 1000 ether);
            vm.deal(address(6), 1000 ether);
            vm.deal(address(7), 1000 ether);
            vm.deal(address(8), 1000 ether);
            vm.deal(address(9), 1000 ether);
            vm.deal(address(10), 1000 ether);
        }
    }

    function _fundUnderlyingTokens(
        uint16[2] memory chainIds,
        uint256 amount,
        string memory underlyingTokenName
    ) internal {
        if (getContract(chainIds[0], underlyingTokenName) == address(0))
            revert INVALID_UNDERLYING_TOKEN_NAME();

        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.selectFork(FORKS[chainIds[i]]);
            address token = getContract(chainIds[i], underlyingTokenName);
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

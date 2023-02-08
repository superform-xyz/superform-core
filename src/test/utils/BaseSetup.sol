// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@std/Test.sol";
import "@ds-test/test.sol";
import "forge-std/console.sol";

import {LayerZeroHelper} from "@pigeon/layerzero/LayerZeroHelper.sol";
import {FixedPointMathLib} from "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";
import {LZEndpointMock} from "contracts/mocks/LzEndpointMock.sol";
import {SocketRouterMock} from "contracts/mocks/SocketRouterMock.sol";
import {VaultMock} from "contracts/mocks/VaultMock.sol";
import {IStateHandler} from "contracts/interface/layerzero/IStateHandler.sol";
import {StateHandler} from "contracts/layerzero/stateHandler.sol";
import {IController} from "contracts/interface/ISource.sol";
import {IDestination} from "contracts/interface/IDestination.sol";
import {IERC4626} from "contracts/interface/IERC4626.sol";
import {SuperRouter} from "contracts/SuperRouter.sol";
import {SuperDestination} from "contracts/SuperDestination.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import "contracts/types/socketTypes.sol";
import "contracts/types/lzTypes.sol";

struct SetupVars {
    uint16[2] chainIds;
    address[2] lzEndpoints;
    uint256 fork;
    uint16 chainId;
    uint16 dstChainId;
    address lzEndpoint;
    address lzHelper;
    address socketRouter;
    address superDestination;
    address stateHandler;
    address DAI;
    address vault;
    address srcSuperRouter;
    address srcStateHandler;
    address srcSuperDestination;
    address destStateHandler;
    address destSuperDestination;
}

error ETH_TRANSFER_FAILED();

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

    uint256 constant mockEstimatedNativeFee = 1000000000000000; // 0.001 Native Tokens
    uint256 constant mockEstimatedZroFee = 250000000000000; // 0.00025 Native Tokens
    uint256 public constant milionTokensE18 = 1 ether;

    address public deployer = address(777);
    address[] public users;

    function setUp() public virtual {
        /// @dev setup bridges and other high level info
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

    function _fundNativeTokens(uint16[2] memory chainIds) internal {
        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.selectFork(FORKS[chainIds[i]]);
            vm.deal(deployer, 1000 ether);

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

    function _fundUnderlyingTokens(uint16[2] memory chainIds, uint256 amount)
        internal
    {
        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.selectFork(FORKS[chainIds[i]]);
            address dai = getContract(chainIds[i], "DAI");
            deal(dai, address(1), 1 ether * amount);
            deal(dai, address(2), 1 ether * amount);
            deal(dai, address(3), 1 ether * amount);
            deal(dai, address(4), 1 ether * amount);
            deal(dai, address(5), 1 ether * amount);
            deal(dai, address(6), 1 ether * amount);
            deal(dai, address(7), 1 ether * amount);
            deal(dai, address(8), 1 ether * amount);
            deal(dai, address(9), 1 ether * amount);
            deal(dai, address(10), 1 ether * amount);
        }
    }

    function _deployProtocol(
        string memory RPC_URL_0,
        string memory RPC_URL_1,
        address lzEndpoint_1,
        address lzEndpoint_2,
        uint16 ID_0,
        uint16 ID_1
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

            /// @dev 1- deploy LZ Mock
            /*
            vars.lzEndpoint = address(new LZEndpointMock(vars.chainId));
            contracts[vars.chainId][bytes32(bytes("LZEndpointMock"))] = vars
                .lzEndpoint;
            */

            /// @dev 2- deploy StateHandler pointing to lzHelper
            vars.stateHandler = address(new StateHandler(vars.lzEndpoints[i]));
            contracts[vars.chainId][bytes32(bytes("StateHandler"))] = vars
                .stateHandler;

            /// @dev 3- deploy SocketRouterMock
            vars.socketRouter = address(new SocketRouterMock());
            contracts[vars.chainId][bytes32(bytes("SocketRouterMock"))] = vars
                .socketRouter;

            if (i == 0) {
                bridgeAddresses.push(vars.socketRouter);
            }

            /*
            /// @dev 4- Set estimated fees on LZ Mock
            /// @notice this is subject to change using pigeon
            LZEndpointMock(vars.lzEndpoint).setEstimatedFees(
                mockEstimatedNativeFee,
                mockEstimatedZroFee
            );
            */
            /// @dev 5 - Deploy mock DAI with 18 decimals
            vars.DAI = address(
                new MockERC20("DAI", "DAI", 18, deployer, milionTokensE18)
            );
            contracts[vars.chainId][bytes32(bytes("DAI"))] = vars.DAI;

            /// @dev 6 - Deploy mock Vault
            vars.vault = address(
                new VaultMock(MockERC20(vars.DAI), "DAIVault", "DAIVault")
            );
            contracts[vars.chainId][bytes32(bytes("DAIVault"))] = vars.vault;

            vaults[vars.chainId].push(IERC4626(vars.vault));
            vaultIds[vars.chainId].push(1);
            /// @dev 7 - Deploy SuperDestination
            vars.superDestination = address(
                new SuperDestination(
                    vars.chainId,
                    IStateHandler(payable(vars.stateHandler))
                )
            );
            contracts[vars.chainId][bytes32(bytes("SuperDestination"))] = vars
                .superDestination;

            /// @dev 8 - Deploy SuperRouter
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

            vars.dstChainId = vars.chainId == ID_0 ? ID_1 : ID_0;
            // vars.lzEndpoint = getContract(vars.chainId, "LZEndpointMock");

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

            /*
            /// @dev - Set LZ dst endpoints on source
            LZEndpointMock(vars.lzEndpoint).setDestLzEndpoint(
                vars.destStateHandler,
                vars.destSuperDestination
            );
            */

            /// @dev - Add vaults to super destination
            SuperDestination(payable(vars.srcSuperDestination)).addVault(
                vaults[vars.chainId],
                vaultIds[vars.chainId]
            );

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

        bytes memory socketTxData = abi.encodeWithSignature(
            "mockSocketTransfer(address,address,address,uint256)",
            fromSrc,
            toDst,
            underlyingSrcToken,
            amount
        );

        liqReq = LiqRequest(
            1,
            socketTxData,
            underlyingSrcToken,
            getContract(srcChainId, "SocketRouterMock"),
            amount,
            0
        );
    }

    function _depositToVault(
        address underlyingSrcToken,
        address payable fromSrc, // SuperRouter
        address payable toDst, // SuperDestination
        StateReq memory stateReq,
        LiqRequest memory liqReq,
        uint256 amount,
        uint256 userIndex,
        uint16 srcChainId,
        uint16 toChainId,
        address toLzEndpoint
    ) internal {
        vm.selectFork(FORKS[srcChainId]);

        vm.prank(users[userIndex]);
        MockERC20(underlyingSrcToken).approve(fromSrc, amount);

        vm.selectFork(FORKS[toChainId]);
        /// @dev Mocking gas fee airdrop (native) from layerzero
        vm.prank(deployer);
        (bool success, ) = toDst.call{value: 1 ether}(new bytes(0));
        if (!success) revert ETH_TRANSFER_FAILED();

        assertEq(toDst.balance, 1 ether);

        StateReq[] memory stateReqs = new StateReq[](1);
        LiqRequest[] memory liqReqs = new LiqRequest[](1);

        stateReqs[0] = stateReq;
        liqReqs[0] = liqReq;

        vm.selectFork(FORKS[srcChainId]);

        vm.prank(users[userIndex]);

        /// @dev see pigeon for this implementation
        vm.recordLogs();

        /// @dev Value == fee paid to relayer. API call in our design
        SuperRouter(fromSrc).deposit{value: 2 ether}(liqReqs, stateReqs);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        address lzHelper = getContract(srcChainId, "LayerZeroHelper");
        LayerZeroHelper(lzHelper).help(
            toLzEndpoint,
            100000,
            FORKS[toChainId],
            logs
        );
    }
}

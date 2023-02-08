// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@std/Test.sol";
import "@ds-test/test.sol";
import "forge-std/console.sol";
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
    address lzEndpoint;
    address socketRouter;
    address superDestination;
    address stateHandler;
    address DAI;
    address vault;
    uint16 chainId;
    uint16 dstChainId;
    uint256 fork;
    address srcSuperRouter;
    address srcStateHandler;
    address srcSuperDestination;
    address destStateHandler;
    address destSuperDestination;
    uint16[2] chainIds;
}

error ETH_TRANSFER_FAILED();

abstract contract BaseSetup is DSTest, Test {
    using FixedPointMathLib for uint256;

    bytes32 public constant CORE_CONTRACTS_ROLE =
        keccak256("CORE_CONTRACTS_ROLE");
    bytes32 public constant PROCESSOR_CONTRACTS_ROLE =
        keccak256("PROCESSOR_CONTRACTS_ROLE");

    mapping(uint16 => mapping(bytes32 => address)) public contracts;
    mapping(uint16 => uint256) public forks;
    mapping(uint16 => IERC4626[]) vaults;
    mapping(uint16 => uint256[]) vaultIds;

    uint8[] bridgeIds;
    address[] bridgeAddresses;

    uint256 mockEstimatedNativeFee = 1000000000000000; // 0.001 Native Tokens
    uint256 mockEstimatedZroFee = 250000000000000; // 0.00025 Native Tokens
    uint256 public milionTokensE18 = 1 ether;

    address public deployer = address(777);
    address[] public users;

    function setUp() public virtual {
        vm.deal(deployer, 1000 ether);

        /// @dev setup bridges and other high level info
        bridgeIds.push(1);

        for (uint256 i = 0; i < 10; i++) {
            /// @dev foundry does not allow conversion of uint256 to address
            vm.deal(address(0), 1000 ether);

            users.push(address(0));
            vm.deal(address(1), 1000 ether);

            users.push(address(1));
            vm.deal(address(2), 1000 ether);
            users.push(address(2));
            vm.deal(address(3), 1000 ether);
            users.push(address(3));
            vm.deal(address(4), 1000 ether);
            users.push(address(4));
            vm.deal(address(5), 1000 ether);
            users.push(address(5));
            vm.deal(address(6), 1000 ether);
            users.push(address(6));
            vm.deal(address(7), 1000 ether);
            users.push(address(7));
            vm.deal(address(8), 1000 ether);
            users.push(address(8));
            vm.deal(address(9), 1000 ether);
            users.push(address(9));
        }
    }

    function getContract(uint16 chainId, string memory _name)
        public
        view
        returns (address)
    {
        return contracts[chainId][bytes32(bytes(_name))];
    }

    function _deployProtocol(
        string memory RPC_URL_0,
        string memory RPC_URL_1,
        uint16 chainId0,
        uint16 chainId1
    ) internal {
        SetupVars memory vars;

        vars.chainIds = [chainId0, chainId1];

        forks[chainId0] = vm.createFork(RPC_URL_0);
        forks[chainId1] = vm.createFork(RPC_URL_1);

        vm.startPrank(deployer);
        /// @dev deployments
        for (uint256 i = 0; i < vars.chainIds.length; i++) {
            vars.chainId = vars.chainIds[i];
            vars.fork = forks[vars.chainId];
            vm.selectFork(vars.fork);

            /// @dev 1- deploy LZ Mock
            vars.lzEndpoint = address(new LZEndpointMock(vars.chainId));
            contracts[vars.chainId][bytes32(bytes("LZEndpointMock"))] = vars
                .lzEndpoint;

            /// @dev 2- deploy StateHandler pointing to LzMock
            vars.stateHandler = address(new StateHandler(vars.lzEndpoint));
            contracts[vars.chainId][bytes32(bytes("StateHandler"))] = vars
                .stateHandler;

            /// @dev 3- deploy SocketRouterMock
            vars.socketRouter = address(new SocketRouterMock());
            contracts[vars.chainId][bytes32(bytes("SocketRouterMock"))] = vars
                .socketRouter;

            if (i == 0) {
                bridgeAddresses.push(vars.socketRouter);
            }

            /// @dev 4- Set estimated fees on LZ Mock
            /// @notice this is subject to change using pigeon
            LZEndpointMock(vars.lzEndpoint).setEstimatedFees(
                mockEstimatedNativeFee,
                mockEstimatedZroFee
            );
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

        for (uint256 i = 0; i < vars.chainIds.length; i++) {
            vars.chainId = vars.chainIds[i];
            vars.fork = forks[vars.chainId];
            vm.selectFork(vars.fork);

            vars.dstChainId = vars.chainId == chainId0 ? chainId1 : chainId0;
            vars.lzEndpoint = getContract(vars.chainId, "LZEndpointMock");

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

            /// @dev - Set LZ dst endpoints on source
            LZEndpointMock(vars.lzEndpoint).setDestLzEndpoint(
                vars.destStateHandler,
                vars.destSuperDestination
            );

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
                abi.encodePacked(vars.destStateHandler)
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
        address underlyingDstToken,
        uint256 targetVaultId,
        uint256 amount,
        uint256 msgValue,
        uint16 targetChainId
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
            targetChainId,
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
            targetChainId,
            amount
        );

        liqReq = LiqRequest(
            1,
            socketTxData,
            underlyingDstToken,
            getContract(targetChainId, "SocketRouterMock"),
            amount,
            0
        );
    }

    function _depositToVault(
        address underlyingDstToken,
        address payable fromSrc, // SuperRouter
        address toDst, // SuperDestination
        StateReq memory stateReq,
        LiqRequest memory liqReq,
        uint256 amount,
        uint256 userIndex
    ) internal {
        vm.prank(users[userIndex]);
        MockERC20(underlyingDstToken).approve(fromSrc, amount);

        /// @dev Mocking gas fee airdrop (native) from layerzero
        vm.prank(deployer);
        (bool success, ) = toDst.call{value: 1e18}(new bytes(0));
        if (!success) revert ETH_TRANSFER_FAILED();

        StateReq[] memory stateReqs = new StateReq[](1);
        LiqRequest[] memory liqReqs = new LiqRequest[](1);

        stateReqs[0] = stateReq;
        liqReqs[0] = liqReq;

        /// @dev Value == fee paid to relayer. API call in our design
        vm.prank(users[userIndex]);
        SuperRouter(fromSrc).deposit{value: 2 ether}(liqReqs, stateReqs);
    }
}

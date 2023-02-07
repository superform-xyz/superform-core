// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@std/Test.sol";
import "@ds-test/test.sol";
import {FixedPointMathLib} from "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";
import {LZEndpointMock} from "contracts/mocks/LZEndpointMock.sol";
import {SocketRouterMock} from "contracts/mocks/SocketRouterMock.sol";
import {VaultMock} from "contracts/mocks/VaultMock.sol";
import {IStateHandler} from "contracts/interface/layerzero/IStateHandler.sol";
import {StateHandler} from "contracts/layerzero/StateHandler.sol";
import {IController} from "contracts/interface/ISource.sol";
import {IDestination} from "contracts/interface/IDestination.sol";
import {IERC4626} from "contracts/interface/IERC4626.sol";
import {SuperRouter} from "contracts/SuperRouter.sol";
import {SuperDestination} from "contracts/SuperDestination.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

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
    uint256 public milionTokensE18 = 1000000000000000000000000;

    function setUp(
        string memory RPC_URL_0,
        string memory RPC_URL_1,
        uint16 chainId0,
        uint16 chainId1
    ) public virtual {
        address lzEndpoint;
        address socketRouter;
        address superDestination;
        address stateHandler;
        address USDC;
        uint16 chainId;
        uint16 dstChainId;
        uint256 fork;

        address srcSuperRouter;
        address srcStateHandler;
        address srcSuperDestination;
        address destStateHandler;
        address destSuperDestination;

        uint16[2] memory chainIds = [chainId0, chainId1];

        forks[chainId0] = vm.createFork(RPC_URL_0);
        forks[chainId1] = vm.createFork(RPC_URL_1);

        bridgeIds.push(1);

        /// @dev deployments
        for (uint256 i = 0; i < chainIds.length; i++) {
            chainId = chainIds[i];
            fork = forks[chainId];
            vm.selectFork(fork);

            /// @dev 1- deploy LZ Mock
            lzEndpoint = address(new LZEndpointMock(chainId));
            contracts[chainId][bytes32(bytes("LZEndpointMock"))] = lzEndpoint;

            /// @dev 2- deploy StateHandler pointing to LzMock
            stateHandler = address(new StateHandler(lzEndpoint));
            contracts[chainId][bytes32(bytes("StateHandler"))] = stateHandler;

            /// @dev 3- deploy SocketRouterMock
            socketRouter = address(new SocketRouterMock());
            contracts[chainId][
                bytes32(bytes("SocketRouterMock"))
            ] = socketRouter;

            if (i == 0) {
                bridgeAddresses.push(socketRouter);
            }

            /// @dev 4- Set estimated fees on LZ Mock
            /// @notice this is subject to change using pigeon
            LZEndpointMock(lzEndpoint).setEstimatedFees(
                mockEstimatedNativeFee,
                mockEstimatedZroFee
            );

            /// @dev 5 - Deploy mock USDC (6 decimals)
            USDC = address(
                new MockERC20("USDC", "USDC", 6, msg.sender, milionTokensE18)
            );
            contracts[chainId][bytes32(bytes("USDC"))] = USDC;

            /// @dev 6 - Deploy mock Vault
            address vault = address(
                new VaultMock(MockERC20(USDC), "USDCVault", "USDCVault")
            );
            contracts[chainId][bytes32(bytes("USDCVault"))] = vault;

            vaults[chainId].push(IERC4626(vault));
            vaultIds[chainId].push(1);
            /// @dev 7 - Deploy SuperDestination
            superDestination = address(
                new SuperDestination(
                    chainId,
                    IStateHandler(payable(stateHandler))
                )
            );
            contracts[chainId][
                bytes32(bytes("SuperDestination"))
            ] = superDestination;

            /// @dev 8 - Deploy SuperRouter
            contracts[chainId][bytes32(bytes("SuperRouter"))] = address(
                new SuperRouter(
                    chainId,
                    "test.com/",
                    IStateHandler(payable(stateHandler)),
                    IDestination(superDestination)
                )
            );
        }

        for (uint256 i = 0; i < chainIds.length; i++) {
            chainId = chainIds[i];
            fork = forks[chainId];
            vm.selectFork(fork);

            dstChainId = chainId == chainId0 ? chainId1 : chainId0;
            lzEndpoint = getContract(chainId, "LZEndpointMock");

            srcStateHandler = getContract(chainId, "StateHandler");
            srcSuperRouter = getContract(chainId, "SuperRouter");
            srcSuperDestination = getContract(chainId, "SuperDestination");

            destStateHandler = getContract(dstChainId, "StateHandler");
            destSuperDestination = getContract(dstChainId, "SuperDestination");

            /// @dev - Set LZ dst endpoints on source
            LZEndpointMock(lzEndpoint).setDestLzEndpoint(
                destStateHandler,
                destSuperDestination
            );

            /// @dev - Add vaults to super destination
            SuperDestination(payable(srcSuperDestination)).addVault(
                vaults[chainId],
                vaultIds[chainId]
            );

            /// @dev - RBAC
            StateHandler(payable(srcStateHandler)).setHandlerController(
                IController(srcSuperRouter),
                IController(srcSuperDestination)
            );

            StateHandler(payable(srcStateHandler)).grantRole(
                CORE_CONTRACTS_ROLE,
                srcSuperRouter
            );
            StateHandler(payable(srcStateHandler)).grantRole(
                CORE_CONTRACTS_ROLE,
                srcSuperDestination
            );
            StateHandler(payable(srcStateHandler)).grantRole(
                PROCESSOR_CONTRACTS_ROLE,
                msg.sender
            );

            StateHandler(payable(srcStateHandler)).setTrustedRemote(
                dstChainId,
                abi.encodePacked(destStateHandler)
            );

            /// @dev - Set bridge addresses
            SuperRouter(payable(srcSuperRouter)).setBridgeAddress(
                bridgeIds,
                bridgeAddresses
            );
        }
    }

    function getContract(uint16 chainId, string memory _name)
        public
        view
        returns (address)
    {
        return contracts[chainId][bytes32(bytes(_name))];
    }
}

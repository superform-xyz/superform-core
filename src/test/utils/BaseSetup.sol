/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "forge-std/console.sol";

/// @dev lib imports
import "@std/Test.sol";
import "@ds-test/test.sol";
// import "forge-std/console.sol";
import {LayerZeroHelper} from "@pigeon/layerzero/LayerZeroHelper.sol";
import {HyperlaneHelper} from "@pigeon/hyperlane/HyperlaneHelper.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import "@openzeppelin-contracts/contracts/utils/Strings.sol";

/// @dev src imports
import {VaultMock} from "../mocks/VaultMock.sol";
import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {CoreStateRegistry} from "../../crosschain-data/CoreStateRegistry.sol";
import {FactoryStateRegistry} from "../../crosschain-data/FactoryStateRegistry.sol";
import {ISuperRouter} from "../../interfaces/ISuperRouter.sol";
import {ISuperFormFactory} from "../../interfaces/ISuperFormFactory.sol";
import {IERC4626} from "../../interfaces/IERC4626.sol";
import {IBaseForm} from "../../interfaces/IBaseForm.sol";
import {SuperRouter} from "../../SuperRouter.sol";
import {SuperRegistry} from "../../SuperRegistry.sol";
import {TokenBank} from "../../TokenBank.sol";
import {SuperFormFactory} from "../../SuperFormFactory.sol";
import {ERC4626Form} from "../../forms/ERC4626Form.sol";
import {MultiTxProcessor} from "../../crosschain-liquidity/MultiTxProcessor.sol";
import {LayerzeroImplementation} from "../../crosschain-data/layerzero/Implementation.sol";
import {HyperlaneImplementation} from "../../crosschain-data/hyperlane/Implementation.sol";

import {IMailbox} from "../../crosschain-data/hyperlane/interface/IMailbox.sol";
import {IInterchainGasPaymaster} from "../../crosschain-data/hyperlane/interface/IInterchainGasPaymaster.sol";

/// @dev local test imports
import {SocketRouterMockFork} from "../mocks/SocketRouterMockFork.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";
import "./TestTypes.sol";

abstract contract BaseSetup is DSTest, Test {
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public deployer = address(777);
    address[] public users;
    uint256 public trustedRemote;
    mapping(uint16 => mapping(bytes32 => address)) public contracts;

    /*//////////////////////////////////////////////////////////////
                        PROTOCOL VARIABLES
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
    bytes32 public constant CORE_CONTRACTS_ROLE =
        keccak256("CORE_CONTRACTS_ROLE");
    bytes32 public constant IMPLEMENTATION_CONTRACTS_ROLE =
        keccak256("IMPLEMENTATION_CONTRACTS_ROLE");
    bytes32 public constant PROCESSOR_ROLE = keccak256("PROCESSOR_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");
    bytes32 public constant SUPER_ROUTER_ROLE = keccak256("SUPER_ROUTER_ROLE");
    bytes32 public constant TOKEN_BANK_ROLE = keccak256("TOKEN_BANK_ROLE");
    bytes32 public constant STATE_REGISTRY_ROLE =
        keccak256("STATE_REGISTRY_ROLE");

    /// @dev one vault per request at the moment - do not change for now
    uint256 internal constant allowedNumberOfVaultsPerRequest = 1;

    /// @dev we should fork these instead of mocking
    string[] public UNDERLYING_TOKENS = ["DAI", "USDT", "WETH"];
    /// @dev all these vault mocks are currently  using formId 1 (4626)
    uint256[] public FORMS_FOR_VAULTS = [uint256(1), 1, 1];
    uint256[] public FORM_BEACON_IDS = [uint256(1)];
    string[] public VAULT_NAMES;

    mapping(uint16 => IERC4626[]) public vaults;
    mapping(uint16 => uint256[]) vaultIds;
    mapping(uint16 => uint256) PAYLOAD_ID; // chaindId => payloadId

    /// @dev liquidity bridge ids
    uint8[] bridgeIds;
    /// @dev liquidity bridge addresses
    address[] bridgeAddresses;

    /// @dev amb ids
    uint8[] ambIds;
    /// @dev amb implementations
    address[] ambAddresses;

    /*//////////////////////////////////////////////////////////////
                        AMB VARIABLES
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

    address[6] public lzEndpoints = [
        0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62
    ];

    /*
    address[7] public lzEndpoints = [
        0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7
    ];
    */
    /*//////////////////////////////////////////////////////////////
                        HYPERLANE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IMailbox public constant HyperlaneMailbox =
        IMailbox(0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70);
    IInterchainGasPaymaster public constant HyperlaneGasPaymaster =
        IInterchainGasPaymaster(0x6cA0B6D22da47f091B7613223cD4BB03a2d77918);

    uint16 public constant ETH = 1;
    uint16 public constant BSC = 2;
    uint16 public constant AVAX = 3;
    uint16 public constant POLY = 4;
    uint16 public constant ARBI = 5;
    uint16 public constant OP = 6;
    //uint16 public constant FTM = 7;

    uint16[6] public chainIds = [1, 2, 3, 4, 5, 6];

    /// @dev reference for chain ids https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
    uint16 public constant LZ_ETH = 101;
    uint16 public constant LZ_BSC = 102;
    uint16 public constant LZ_AVAX = 106;
    uint16 public constant LZ_POLY = 109;
    uint16 public constant LZ_ARBI = 110;
    uint16 public constant LZ_OP = 111;
    //uint16 public constant LZ_FTM = 112;

    uint16[6] public lz_chainIds = [101, 102, 106, 109, 110, 111];
    uint32[6] public hyperlane_chainIds = [1, 56, 43114, 137, 42161, 10];

    // uint16[7] public lz_chainIds = [101, 102, 106, 109, 110, 111, 112];
    // uint32[7] public hyperlane_chainIds = [1, 56, 43114, 137, 42161, 10, 250];

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

    // chainID => FORK
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
                    PUBLIC FUNCTIONS FOR TESTS
            THESE FUNCTIONS SHOULD BE USED WHENEVER POSSIBLE
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        _preDeploymentSetup();

        _fundNativeTokens();

        _deployProtocol();

        _fundUnderlyingTokens(100);
    }

    function getContract(
        uint16 chainId,
        string memory _name
    ) public view returns (address) {
        return contracts[chainId][bytes32(bytes(_name))];
    }

    function getAccessControlErrorMsg(
        address _addr,
        bytes32 _role
    ) public pure returns (bytes memory errorMsg) {
        errorMsg = abi.encodePacked(
            "AccessControl: account ",
            Strings.toHexString(uint160(_addr), 20),
            " is missing role ",
            Strings.toHexString(uint256(_role), 32)
        );
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL HELPERS: DEPLOY
    //////////////////////////////////////////////////////////////*/

    function _deployProtocol() internal {
        SetupVars memory vars;

        vm.startPrank(deployer);
        /// @dev deployments
        for (uint256 i = 0; i < chainIds.length; i++) {
            vars.chainId = chainIds[i];
            vars.fork = FORKS[vars.chainId];
            vm.selectFork(vars.fork);

            /// @dev 1- deploy LZ Helper from Pigeon
            vars.lzHelper = address(new LayerZeroHelper());
            vm.allowCheatcodes(vars.lzHelper);

            contracts[vars.chainId][bytes32(bytes("LayerZeroHelper"))] = vars
                .lzHelper;

            /// @dev 1.1- deploy Hyperlane Helper from Pigeon
            vars.hyperlaneHelper = address(new HyperlaneHelper());
            vm.allowCheatcodes(vars.hyperlaneHelper);

            contracts[vars.chainId][bytes32(bytes("HyperlaneHelper"))] = vars
                .hyperlaneHelper;

            /// @dev 2 - Deploy SuperRegistry and assign roles
            vars.superRegistry = address(new SuperRegistry(vars.chainId));
            contracts[vars.chainId][bytes32(bytes("SuperRegistry"))] = vars
                .superRegistry;

            /// @dev 3- deploy StateRegistry pointing to lzEndpoints (constants)
            vars.coreStateRegistry = address(
                new CoreStateRegistry(
                    vars.chainId,
                    SuperRegistry(vars.superRegistry)
                )
            );
            contracts[vars.chainId][bytes32(bytes("CoreStateRegistry"))] = vars
                .coreStateRegistry;

            /// @dev 3.1- deploy Factory State Registry
            vars.factoryStateRegistry = address(
                new FactoryStateRegistry(
                    vars.chainId,
                    SuperRegistry(vars.superRegistry)
                )
            );
            contracts[vars.chainId][
                bytes32(bytes("FactoryStateRegistry"))
            ] = vars.factoryStateRegistry;

            /// @dev 3.2- deploy Layerzero Implementation
            vars.lzImplementation = address(
                new LayerzeroImplementation(
                    lzEndpoints[i],
                    SuperRegistry(vars.superRegistry)
                )
            );
            contracts[vars.chainId][bytes32(bytes("LzImplementation"))] = vars
                .lzImplementation;

            /// @dev 3.3- deploy Hyperlane Implementation
            vars.hyperlaneImplementation = address(
                new HyperlaneImplementation(
                    HyperlaneMailbox,
                    HyperlaneGasPaymaster,
                    SuperRegistry(vars.superRegistry)
                )
            );
            contracts[vars.chainId][
                bytes32(bytes("HyperlaneImplementation"))
            ] = vars.hyperlaneImplementation;

            if (i == 0) {
                ambAddresses.push(vars.lzImplementation);
                ambAddresses.push(vars.hyperlaneImplementation);
            }

            /// @dev 4- deploy SocketRouterMockFork
            vars.socketRouter = address(new SocketRouterMockFork());
            contracts[vars.chainId][
                bytes32(bytes("SocketRouterMockFork"))
            ] = vars.socketRouter;
            vm.allowCheatcodes(vars.socketRouter);

            if (i == 0) {
                bridgeAddresses.push(vars.socketRouter);
            }

            /// @dev 4.1 - Deploy UNDERLYING_TOKENS and VAULTS
            for (uint256 j = 0; j < UNDERLYING_TOKENS.length; j++) {
                vars.UNDERLYING_TOKEN = address(
                    new MockERC20(
                        UNDERLYING_TOKENS[j],
                        UNDERLYING_TOKENS[j],
                        18,
                        deployer,
                        milionTokensE18
                    )
                );
                contracts[vars.chainId][
                    bytes32(bytes(UNDERLYING_TOKENS[j]))
                ] = vars.UNDERLYING_TOKEN;

                /// @dev 4.2 - Deploy mock Vault
                vars.vault = address(
                    new VaultMock(
                        MockERC20(vars.UNDERLYING_TOKEN),
                        VAULT_NAMES[j],
                        VAULT_NAMES[j]
                    )
                );
                contracts[vars.chainId][
                    bytes32(bytes(string.concat(UNDERLYING_TOKENS[j], "Vault")))
                ] = vars.vault;

                vaults[vars.chainId].push(IERC4626(vars.vault));
                vaultIds[vars.chainId].push(j + 1);
            }

            /// @dev 5 - Deploy SuperFormFactory
            vars.factory = address(new SuperFormFactory(vars.chainId));

            contracts[vars.chainId][bytes32(bytes("SuperFormFactory"))] = vars
                .factory;

            /// @dev 6 - Deploy 4626Form implementation

            vars.erc4626Form = address(new ERC4626Form());
            contracts[vars.chainId][bytes32(bytes("ERC4626Form"))] = vars
                .erc4626Form;

            /// @dev 7 - Add newly deployed form  implementation to Factory, formBeaconId 1
            ISuperFormFactory(vars.factory).addFormBeacon(
                vars.erc4626Form,
                FORM_BEACON_IDS[0]
            );

            /// @dev 8 - Deploy TokenBank
            vars.tokenBank = address(new TokenBank(vars.chainId));

            contracts[vars.chainId][bytes32(bytes("TokenBank"))] = vars
                .tokenBank;

            /// @dev 9 - Deploy SuperRouter
            contracts[vars.chainId][bytes32(bytes("SuperRouter"))] = address(
                new SuperRouter(vars.chainId, "test.com/")
            );

            /// @dev 10 - Deploy MultiTx Processor
            contracts[vars.chainId][
                bytes32(bytes("MultiTxProcessor"))
            ] = address(new MultiTxProcessor());

            /// @dev 11 - Deploy SWAP token with no associated vault with 18 decimals
            contracts[vars.chainId][bytes32(bytes("Swap"))] = address(
                new MockERC20("Swap", "SWP", 18, deployer, milionTokensE18)
            );

            SuperRegistry(vars.superRegistry).setSuperRouter(
                contracts[vars.chainId][bytes32(bytes("SuperRouter"))]
            );
            SuperRegistry(vars.superRegistry).setTokenBank(
                contracts[vars.chainId][bytes32(bytes("TokenBank"))]
            );
            SuperRegistry(vars.superRegistry).setSuperFormFactory(vars.factory);

            SuperRegistry(vars.superRegistry).setCoreStateRegistry(
                vars.coreStateRegistry
            );

            SuperRegistry(vars.superRegistry).setFactoryStateRegistry(
                vars.factoryStateRegistry
            );

            SuperRegistry(vars.superRegistry).setBridgeAddress(
                bridgeIds,
                bridgeAddresses
            );

            SuperFormFactory(vars.factory).setSuperRegistry(vars.superRegistry);

            MultiTxProcessor(
                payable(
                    contracts[vars.chainId][bytes32(bytes("MultiTxProcessor"))]
                )
            ).setSuperRegistry(vars.superRegistry);

            SuperRouter(
                payable(contracts[vars.chainId][bytes32(bytes("SuperRouter"))])
            ).setSuperRegistry(vars.superRegistry);

            TokenBank(payable(vars.tokenBank)).setSuperRegistry(
                vars.superRegistry
            );

            IBaseStateRegistry(vars.coreStateRegistry).setSuperRegistry(
                vars.superRegistry
            );
        }

        for (uint256 i = 0; i < chainIds.length; i++) {
            vars.chainId = chainIds[i];
            vars.fork = FORKS[vars.chainId];
            vm.selectFork(vars.fork);

            vars.srcCoreStateRegistry = getContract(
                vars.chainId,
                "CoreStateRegistry"
            );
            vars.srcFactoryStateRegistry = getContract(
                vars.chainId,
                "FactoryStateRegistry"
            );
            vars.srcLzImplementation = getContract(
                vars.chainId,
                "LzImplementation"
            );
            vars.srcHyperlaneImplementation = getContract(
                vars.chainId,
                "HyperlaneImplementation"
            );

            vars.srcSuperRouter = getContract(vars.chainId, "SuperRouter");
            vars.srcSuperFormFactory = getContract(
                vars.chainId,
                "SuperFormFactory"
            );

            vars.dstSuperFormFactory = getContract(
                vars.chainId,
                "SuperFormFactory"
            );

            vars.srcTokenBank = getContract(vars.chainId, "TokenBank");
            vars.srcMultiTxProcessor = getContract(
                vars.chainId,
                "MultiTxProcessor"
            );

            /// @dev - Create SuperForm for id 1 in Factory contract
            /// @dev FIXME: currently hardcoded formId 1
            ///

            // SuperDestination(payable(vars.srcSuperDestination))
            //     .setSrcTokenDistributor(vars.srcSuperRouter, vars.chainId);

            // SuperDestination(payable(vars.srcSuperDestination))
            //     .updateSafeGasParam("0x000100000000000000000000000000000000000000000000000000000000004c4b40");

            /// @dev - RBAC

            CoreStateRegistry(payable(vars.srcCoreStateRegistry)).grantRole(
                CORE_CONTRACTS_ROLE,
                vars.srcSuperRouter
            );

            FactoryStateRegistry(payable(vars.srcFactoryStateRegistry))
                .setFactoryContract(vars.srcSuperFormFactory);

            FactoryStateRegistry(payable(vars.srcFactoryStateRegistry))
                .grantRole(CORE_CONTRACTS_ROLE, vars.srcSuperFormFactory);

            /// @dev TODO: for each form , add it to the core_contracts_role. Just 1 for now
            CoreStateRegistry(payable(vars.srcCoreStateRegistry)).grantRole(
                CORE_CONTRACTS_ROLE,
                vars.srcTokenBank
            );
            CoreStateRegistry(payable(vars.srcCoreStateRegistry)).grantRole(
                IMPLEMENTATION_CONTRACTS_ROLE,
                vars.lzImplementation
            );
            CoreStateRegistry(payable(vars.srcCoreStateRegistry)).grantRole(
                IMPLEMENTATION_CONTRACTS_ROLE,
                vars.hyperlaneImplementation
            );

            FactoryStateRegistry(payable(vars.srcFactoryStateRegistry))
                .grantRole(
                    IMPLEMENTATION_CONTRACTS_ROLE,
                    vars.lzImplementation
                );

            FactoryStateRegistry(payable(vars.srcFactoryStateRegistry))
                .grantRole(
                    IMPLEMENTATION_CONTRACTS_ROLE,
                    vars.hyperlaneImplementation
                );

            CoreStateRegistry(payable(vars.srcCoreStateRegistry)).grantRole(
                PROCESSOR_ROLE,
                deployer
            );
            FactoryStateRegistry(payable(vars.srcFactoryStateRegistry))
                .grantRole(PROCESSOR_ROLE, deployer);

            CoreStateRegistry(payable(vars.srcCoreStateRegistry)).grantRole(
                UPDATER_ROLE,
                deployer
            );

            /// @dev FIXME: in reality who has the SWAPPER_ROLE?
            MultiTxProcessor(payable(vars.srcMultiTxProcessor)).grantRole(
                SWAPPER_ROLE,
                deployer
            );

            TokenBank(payable(vars.srcTokenBank)).grantRole(
                STATE_REGISTRY_ROLE,
                vars.srcCoreStateRegistry
            );

            /// @dev configures lzImplementation and hyperlane to super registry
            SuperRegistry(payable(getContract(vars.chainId, "SuperRegistry")))
                .setAmbAddress(ambIds, ambAddresses);

            /// @dev Set all trusted remotes for each chain & configure amb chains ids
            for (uint256 j = 0; j < chainIds.length; j++) {
                if (vars.chainId != chainIds[j]) {
                    vars.dstChainId = chainIds[j];
                    /// @dev FIXME: for now only LZ amb
                    vars.dstAmbChainId = lz_chainIds[j];
                    vars.dstHypChainId = hyperlane_chainIds[j];

                    vars.dstLzImplementation = getContract(
                        vars.dstChainId,
                        "LzImplementation"
                    );
                    vars.dstHyperlaneImplementation = getContract(
                        vars.dstChainId,
                        "HyperlaneImplementation"
                    );

                    LayerzeroImplementation(payable(vars.srcLzImplementation))
                        .setTrustedRemote(
                            vars.dstAmbChainId,
                            abi.encodePacked(
                                vars.srcLzImplementation,
                                vars.dstLzImplementation
                            )
                        );
                    LayerzeroImplementation(payable(vars.srcLzImplementation))
                        .setChainId(vars.dstChainId, vars.dstAmbChainId);

                    HyperlaneImplementation(
                        payable(vars.srcHyperlaneImplementation)
                    ).setReceiver(
                            vars.dstHypChainId,
                            vars.dstHyperlaneImplementation
                        );

                    HyperlaneImplementation(
                        payable(vars.srcHyperlaneImplementation)
                    ).setChainId(vars.dstChainId, vars.dstHypChainId);
                }
            }

            /// @dev create superforms when the whole state registry is configured?
            for (uint256 j = 0; j < vaults[vars.chainId].length; j++) {
                /// @dev FIXME should be an offchain calculation
                vm.recordLogs();

                (, vars.superForm) = ISuperFormFactory(vars.srcSuperFormFactory)
                    .createSuperForm{
                    value: _getPriceMultiplier(vars.chainId) * 10 ** 18
                }(FORMS_FOR_VAULTS[j], address(vaults[vars.chainId][j]));
                _broadcastPayload(vars.chainId, vm.getRecordedLogs());

                contracts[vars.chainId][
                    bytes32(
                        bytes(
                            string.concat(
                                UNDERLYING_TOKENS[j],
                                "SuperForm",
                                Strings.toString(FORMS_FOR_VAULTS[j])
                            )
                        )
                    )
                ] = vars.superForm;
            }
        }
        _processFactoryPayloads();
        vm.stopPrank();
    }

    /*
    function _resetPayloadIDs() internal {
        mapping(uint16 => uint256) storage payloadID = PAYLOAD_ID; // chaindId => payloadId

        payloadID[ETH] = 0;
        payloadID[BSC] = 0;
        payloadID[AVAX] = 0;
        payloadID[POLY] = 0;
        payloadID[ARBI] = 0;
        payloadID[OP] = 0;
        // payloadID[FTM] = 0;
    }
*/
    /*//////////////////////////////////////////////////////////////
                        MISC. HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _preDeploymentSetup() private {
        mapping(uint16 => uint256) storage forks = FORKS;
        forks[ETH] = vm.createFork(ETHEREUM_RPC_URL, 16742187);
        forks[BSC] = vm.createFork(BSC_RPC_URL, 26121321);
        forks[AVAX] = vm.createFork(AVALANCHE_RPC_URL, 26933006);
        forks[POLY] = vm.createFork(POLYGON_RPC_URL, 39887036);
        forks[ARBI] = vm.createFork(ARBITRUM_RPC_URL, 66125184);
        forks[OP] = vm.createFork(OPTIMISM_RPC_URL, 78219242);
        //forks[FTM] = vm.createFork(FANTOM_RPC_URL, 56806404);

        mapping(uint16 => string) storage rpcURLs = RPC_URLS;
        rpcURLs[ETH] = ETHEREUM_RPC_URL;
        rpcURLs[BSC] = BSC_RPC_URL;
        rpcURLs[AVAX] = AVALANCHE_RPC_URL;
        rpcURLs[POLY] = POLYGON_RPC_URL;
        rpcURLs[ARBI] = ARBITRUM_RPC_URL;
        rpcURLs[OP] = OPTIMISM_RPC_URL;
        //rpcURLs[FTM] = FANTOM_RPC_URL;

        mapping(uint16 => address) storage lzEndpointsStorage = LZ_ENDPOINTS;
        lzEndpointsStorage[ETH] = ETH_lzEndpoint;
        lzEndpointsStorage[BSC] = BSC_lzEndpoint;
        lzEndpointsStorage[AVAX] = AVAX_lzEndpoint;
        lzEndpointsStorage[POLY] = POLY_lzEndpoint;
        lzEndpointsStorage[ARBI] = ARBI_lzEndpoint;
        lzEndpointsStorage[OP] = OP_lzEndpoint;
        //lzEndpointsStorage[FTM] = FTM_lzEndpoint;

        mapping(uint16 => address) storage priceFeeds = PRICE_FEEDS;
        priceFeeds[ETH] = ETHEREUM_ETH_USD_FEED;
        priceFeeds[BSC] = BSC_BNB_USD_FEED;
        priceFeeds[AVAX] = AVALANCHE_AVAX_USD_FEED;
        priceFeeds[POLY] = POLYGON_MATIC_USD_FEED;
        priceFeeds[ARBI] = address(0);
        priceFeeds[OP] = address(0);
        //priceFeeds[FTM] = FANTOM_FTM_USD_FEED;

        /// @dev setup bridges. Only bridgeId 1 available for tests (Socket)
        bridgeIds.push(1);

        /// @dev setup amb bridges
        /// @notice id 1 is layerzero
        /// @notice id 2 is hyperlane
        ambIds.push(1);
        ambIds.push(2);

        /// @dev setup users
        users.push(address(1));
        users.push(address(2));
        users.push(address(3));

        string[] memory underlyingTokens = UNDERLYING_TOKENS;
        for (uint256 i = 0; i < underlyingTokens.length; i++) {
            VAULT_NAMES.push(string.concat(underlyingTokens[i], "Vault"));
        }
    }

    function _fundNativeTokens() private {
        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.selectFork(FORKS[chainIds[i]]);

            uint256 multiplier = _getPriceMultiplier(chainIds[i]);

            uint256 amountDeployer = 100000 * multiplier * 1e18;
            uint256 amountUSER = 1000 * multiplier * 1e18;

            vm.deal(deployer, amountDeployer);

            vm.deal(address(1), amountUSER);
            vm.deal(address(2), amountUSER);
            vm.deal(address(3), amountUSER);
        }
    }

    function _getPriceMultiplier(
        uint16 targetChainId_
    ) internal returns (uint256) {
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

            multiplier = 2 * uint256(ethUsdPrice / price);

            /// @dev return to initial fork

            vm.selectFork(initialFork);
        }

        return multiplier;
    }

    function _getLatestPrice(
        address priceFeed_
    ) internal view returns (int256) {
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

    function _fundUnderlyingTokens(uint256 amount) private {
        for (uint256 j = 0; j < UNDERLYING_TOKENS.length; j++) {
            if (getContract(chainIds[0], UNDERLYING_TOKENS[j]) == address(0))
                revert INVALID_UNDERLYING_TOKEN_NAME();

            for (uint256 i = 0; i < chainIds.length; i++) {
                vm.selectFork(FORKS[chainIds[i]]);
                address token = getContract(chainIds[i], UNDERLYING_TOKENS[j]);
                deal(token, address(1), 1 ether * amount);
                deal(token, address(2), 1 ether * amount);
                deal(token, address(3), 1 ether * amount);

                address swap = getContract(chainIds[i], "Swap");
                deal(swap, address(1), 1 ether * amount);
                deal(swap, address(2), 1 ether * amount);
                deal(swap, address(3), 1 ether * amount);
            }
        }
    }

    /// @dev will sync the payloads for broadcast
    function _broadcastPayload(
        uint16 currentChainId,
        Vm.Log[] memory logs
    ) private {
        vm.stopPrank();

        for (uint256 j = 0; j < chainIds.length; j++) {
            if (chainIds[j] != currentChainId) {
                LayerZeroHelper(getContract(currentChainId, "LayerZeroHelper"))
                    .helpWithEstimates(
                        lzEndpoints[j],
                        lz_chainIds[j],
                        1000000, /// (change to 2000000) @dev This is the gas value to send - value needs to be tested and probably be lower
                        FORKS[chainIds[j]],
                        logs
                    );
                HyperlaneHelper(getContract(currentChainId, "HyperlaneHelper"))
                    .help(
                        address(HyperlaneMailbox),
                        hyperlane_chainIds[j],
                        FORKS[chainIds[j]],
                        logs
                    );
            }
        }

        vm.startPrank(deployer);
    }

    /// @dev will sync the broadcasted factory payloads
    function _processFactoryPayloads() private {
        for (uint256 j = 0; j < chainIds.length; j++) {
            vm.selectFork(FORKS[chainIds[j]]);
            for (uint256 k = 1; k < 16; k++) {
                FactoryStateRegistry(
                    payable(getContract(chainIds[j], "FactoryStateRegistry"))
                ).processPayload(k);
            }
        }
    }
}

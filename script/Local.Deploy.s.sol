// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {AggregatorV3Interface} from "../src/test/utils/AggregatorV3Interface.sol";
import {MockERC20} from "../src/test/mocks/MockERC20.sol";
import {VaultMock} from "../src/test/mocks/VaultMock.sol";
import {ERC4626TimelockMock} from "../src/test/mocks/ERC4626TimelockMock.sol";

/// @dev Protocol imports
import {IBaseStateRegistry} from "../src/interfaces/IBaseStateRegistry.sol";
import {CoreStateRegistry} from "../src/crosschain-data/CoreStateRegistry.sol";
import {RolesStateRegistry} from "../src/crosschain-data/RolesStateRegistry.sol";
import {FactoryStateRegistry} from "../src/crosschain-data/FactoryStateRegistry.sol";
import {ISuperRouter} from "../src/interfaces/ISuperRouter.sol";
import {ISuperFormFactory} from "../src/interfaces/ISuperFormFactory.sol";
import {IERC4626} from "../src/vendor/IERC4626.sol";
import {IBaseForm} from "../src/interfaces/IBaseForm.sol";
import {SuperRouter} from "../src/SuperRouter.sol";
import {SuperRegistry} from "../src/settings/SuperRegistry.sol";
import {SuperRBAC} from "../src/settings/SuperRBAC.sol";
import {SuperPositions} from "../src/SuperPositions.sol";
import {SuperFormFactory} from "../src/SuperFormFactory.sol";
import {ERC4626Form} from "../src/forms/ERC4626Form.sol";
import {ERC4626TimelockForm} from "../src/forms/ERC4626TimelockForm.sol";
import {MultiTxProcessor} from "../src/crosschain-liquidity/MultiTxProcessor.sol";
import {LiFiValidator} from "../src/crosschain-liquidity/lifi/LiFiValidator.sol";
import {SocketValidator} from "../src/crosschain-liquidity/socket/SocketValidator.sol";
import {LayerzeroImplementation} from "../src/crosschain-data/layerzero/Implementation.sol";
import {HyperlaneImplementation} from "../src/crosschain-data/hyperlane/Implementation.sol";
import {CelerImplementation} from "../src/crosschain-data/celer/Implementation.sol";
import {IMailbox} from "../src/vendor/hyperlane/IMailbox.sol";
import {IInterchainGasPaymaster} from "../src/vendor/hyperlane/IInterchainGasPaymaster.sol";
import {IMessageBus} from "../src/vendor/celer/IMessageBus.sol";
import {TwoStepsFormStateRegistry} from "../src/crosschain-data/TwoStepsFormStateRegistry.sol";

struct SetupVars {
    uint16[2] chainIds;
    address[2] lzEndpoints;
    uint16 chainId;
    uint16 dstChainId;
    uint16 dstAmbChainId;
    uint32 dstHypChainId;
    uint256 fork;
    address superForm;
    address factory;
    address lzEndpoint;
    address lzImplementation;
    address hyperlaneImplementation;
    address celerImplementation;
    address erc4626Form;
    address erc4626TimelockForm;
    address factoryStateRegistry;
    address formStateRegistry;
    address rolesStateRegistry;
    address coreStateRegistry;
    address UNDERLYING_TOKEN;
    address vault;
    address timelockVault;
    address superRouter;
    address dstLzImplementation;
    address dstHyperlaneImplementation;
    address dstStateRegistry;
    address multiTxProcessor;
    address superRegistry;
    address superPositions;
    address superRBAC;
    address socketValidator;
    address lifiValidator;
}

contract Deploy is Script {
    /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public constant CANONICAL_PERMIT2 =
        0x000000000022D473030F116dDEE9F6B43aC78BA3;
    mapping(uint16 chainId => mapping(bytes32 implementation => address at))
        public contracts;
    string[13] public contractNames = [
        "CoreStateRegistry",
        "FactoryStateRegistry",
        "LayerzeroImplementation",
        "HyperlaneImplementation",
        "SuperFormFactory",
        "ERC4626Form",
        "ERC4626TimelockForm",
        "SuperRouter",
        "SuperPositions",
        "MultiTxProcessor",
        "SuperRegistry",
        "SuperRBAC"
    ];

    bytes32 constant salt = "SUPERFORM";

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

    /// @dev we should fork these instead of mocking
    string[] public UNDERLYING_TOKENS = ["DAI", "USDT", "WETH"];

    /// @dev 1 = ERC4626Form, 2 = ERC4626TimelockForm
    uint256[] public FORM_BEACON_IDS = [uint256(1), 2];
    string[] public VAULT_KINDS = ["Vault", "TimelockedVault"];

    bytes[] public vaultBytecodes;
    // formbeacon id => vault name
    mapping(uint256 formBeaconId => string[] names) VAULT_NAMES;
    // chainId => formbeacon id => vault
    mapping(uint16 chainId => mapping(uint256 formBeaconId => IERC4626[] vaults))
        public vaults;
    // chainId => formbeacon id => vault id
    mapping(uint16 chainId => mapping(uint256 formBeaconId => uint256[] ids)) vaultIds;
    mapping(uint16 chainId => uint256 payloadId) PAYLOAD_ID; // chaindId => payloadId

    /// @dev liquidity bridge ids. 1,2,3 belong to socket. 4 is lifi
    uint8[] public bridgeIds = [uint8(1), 2, 3];

    /// @dev liquidity bridge addresses - NOTE this is a todo for all chains
    address[] public bridgeAddresses = [
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    ];

    /// @dev liquidity validator addresses
    address[] bridgeValidators;

    /// @dev setup amb bridges
    /// @notice id 1 is layerzero
    /// @notice id 2 is hyperlane
    uint8[] public ambIds = [uint8(1), 2];
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

    /// @dev removed FTM temporarily
    address[] public lzEndpoints = [
        0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62
    ];

    address[] public celerMessageBusses = [
        0x4066D196A423b2b3B8B054f4F40efB47a74E200C,
        0x95714818fdd7a5454F73Da9c777B3ee6EbAEEa6B,
        0x5a926eeeAFc4D217ADd17e9641e8cE23Cd01Ad57,
        0xaFDb9C40C7144022811F034EE07Ce2E110093fe6,
        0x3Ad9d0648CDAA2426331e894e980D0a5Ed16257f,
        0x0D71D18126E03646eb09FEc929e2ae87b7CAE69d
    ];

    /*
    address[] public lzEndpoints = [
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
    uint16[] public chainIds = [1, 2, 3, 4, 5, 6];
    string[] public chainNames = ["ETH", "BSC", "AVAX", "POLY", "ARBI", "OP"];

    /// @dev reference for chain ids https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
    uint16 public constant LZ_ETH = 101;
    uint16 public constant LZ_BSC = 102;
    uint16 public constant LZ_AVAX = 106;
    uint16 public constant LZ_POLY = 109;
    uint16 public constant LZ_ARBI = 110;
    uint16 public constant LZ_OP = 111;
    //uint16 public constant LZ_FTM = 112;

    uint16[] public lz_chainIds = [101, 102, 106, 109, 110, 111];
    uint32[] public hyperlane_chainIds = [1, 56, 43114, 137, 42161, 10];

    /// @dev FIXME to fix with correct chainIds
    uint256[] public socketChainIds = [1, 2, 3, 4, 5, 6];
    /// @dev FIXME to fix with correct chainIds
    uint256[] public lifiChainIds = [1, 2, 3, 4, 5, 6];

    uint256 public constant milionTokensE18 = 1 ether;

    // uint16[7] public lz_chainIds = [101, 102, 106, 109, 110, 111, 112];
    // uint32[7] public hyperlane_chainIds = [1, 56, 43114, 137, 42161, 10, 250];

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
    mapping(uint16 chainId => uint256 fork) public FORKS;
    mapping(uint16 chainId => string forkUrl) public RPC_URLS;

    string public ETHEREUM_RPC_URL = vm.envString("ETHEREUM_RPC_URL"); // Native token: ETH
    string public BSC_RPC_URL = vm.envString("BSC_RPC_URL"); // Native token: BNB
    string public AVALANCHE_RPC_URL = vm.envString("AVALANCHE_RPC_URL"); // Native token: AVAX
    string public POLYGON_RPC_URL = vm.envString("POLYGON_RPC_URL"); // Native token: MATIC
    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL"); // Native token: ETH
    string public OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC_URL"); // Native token: ETH
    string public FANTOM_RPC_URL = vm.envString("FANTOM_RPC_URL"); // Native token: FTM

    address deployer = vm.envAddress("LOCAL_DEPLOYER");

    function getContract(
        uint16 chainId,
        string memory _name
    ) public view returns (address) {
        return contracts[chainId][bytes32(bytes(_name))];
    }

    /// @notice The main script entrypoint
    function run() external {
        _preDeploymentSetup();
        _fundNativeTokens();

        SetupVars memory vars;
        /// @dev deployments
        for (uint256 i = 0; i < chainIds.length; i++) {
            vars.chainId = chainIds[i];
            vars.fork = FORKS[vars.chainId];

            vm.selectFork(vars.fork);
            vm.startBroadcast();

            /// @dev 1 - Deploy SuperRegistry and assign roles
            vars.superRegistry = address(
                new SuperRegistry{salt: salt}(deployer)
            );
            contracts[vars.chainId][bytes32(bytes("SuperRegistry"))] = vars
                .superRegistry;

            SuperRegistry(vars.superRegistry).setImmutables(
                vars.chainId,
                CANONICAL_PERMIT2
            );
            SuperRegistry(vars.superRegistry).setProtocolAdmin(deployer);

            /// @dev 2 - Deploy SuperRBAC
            vars.superRBAC = address(
                new SuperRBAC{salt: salt}(vars.superRegistry, deployer)
            );
            contracts[vars.chainId][bytes32(bytes("SuperRBAC"))] = vars
                .superRBAC;

            SuperRegistry(vars.superRegistry).setSuperRBAC(vars.superRBAC);

            /// @dev FIXME: in reality who should have the SWAPPER_ROLE for multiTxProcessor?
            SuperRBAC(vars.superRBAC).grantSwapperRole(deployer);
            /// @dev FIXME: in reality who should have the PROCESSOR_ROLE for state registry?
            SuperRBAC(vars.superRBAC).grantProcessorRole(deployer);
            /// @dev FIXME: in reality who should have the UPDATER_ROLE for state registry?
            SuperRBAC(vars.superRBAC).grantUpdaterRole(deployer);
            /// @dev FIXME: in reality who should have the FORM_STATE_REGISTRY_ROLE for state registry?
            SuperRBAC(vars.superRBAC).grantFormStateRegistryRole(deployer);

            /// @dev 3.1 - deploy Core State Registry

            vars.coreStateRegistry = address(
                new CoreStateRegistry{salt: salt}(
                    SuperRegistry(vars.superRegistry),
                    1
                )
            );
            contracts[vars.chainId][bytes32(bytes("CoreStateRegistry"))] = vars
                .coreStateRegistry;

            SuperRegistry(vars.superRegistry).setCoreStateRegistry(
                vars.coreStateRegistry
            );

            SuperRBAC(vars.superRBAC).grantCoreStateRegistryRole(
                vars.coreStateRegistry
            );

            /// @dev 3.2- deploy Factory State Registry

            vars.factoryStateRegistry = address(
                new FactoryStateRegistry{salt: salt}(
                    SuperRegistry(vars.superRegistry),
                    2
                )
            );
            contracts[vars.chainId][
                bytes32(bytes("FactoryStateRegistry"))
            ] = vars.factoryStateRegistry;

            SuperRegistry(vars.superRegistry).setFactoryStateRegistry(
                vars.factoryStateRegistry
            );

            /// @dev 3.3 - deploy Form State Registry
            vars.formStateRegistry = address(
                new TwoStepsFormStateRegistry{salt: salt}(
                    SuperRegistry(vars.superRegistry),
                    1
                )
            );

            contracts[vars.chainId][
                bytes32(bytes("TwoStepsFormStateRegistry"))
            ] = vars.formStateRegistry;

            SuperRegistry(vars.superRegistry).setFormStateRegistry(
                vars.formStateRegistry
            );

            /// @dev 3.4- deploy Roles State Registry
            vars.rolesStateRegistry = address(
                new RolesStateRegistry{salt: salt}(
                    SuperRegistry(vars.superRegistry),
                    3
                )
            );

            contracts[vars.chainId][bytes32(bytes("RolesStateRegistry"))] = vars
                .rolesStateRegistry;

            SuperRegistry(vars.superRegistry).setRolesStateRegistry(
                vars.rolesStateRegistry
            );

            SuperRegistry(vars.superRegistry).setRolesStateRegistry(
                vars.rolesStateRegistry
            );

            address[] memory registryAddresses = new address[](3);
            registryAddresses[0] = vars.coreStateRegistry;
            registryAddresses[1] = vars.factoryStateRegistry;
            registryAddresses[2] = vars.rolesStateRegistry;

            uint8[] memory registryIds = new uint8[](3);
            registryIds[0] = 1;
            registryIds[1] = 2;
            registryIds[2] = 3;

            SuperRegistry(vars.superRegistry).setStateRegistryAddress(
                registryIds,
                registryAddresses
            );
            /// @dev 4.1- deploy Layerzero Implementation
            vars.lzImplementation = address(
                new LayerzeroImplementation{salt: salt}(
                    SuperRegistry(vars.superRegistry)
                )
            );
            contracts[vars.chainId][
                bytes32(bytes("LayerzeroImplementation"))
            ] = vars.lzImplementation;

            LayerzeroImplementation(payable(vars.lzImplementation))
                .setLzEndpoint(lzEndpoints[i]);

            /// @dev 4.2- deploy Hyperlane Implementation
            vars.hyperlaneImplementation = address(
                new HyperlaneImplementation{salt: salt}(
                    HyperlaneMailbox,
                    HyperlaneGasPaymaster,
                    SuperRegistry(vars.superRegistry)
                )
            );
            contracts[vars.chainId][
                bytes32(bytes("HyperlaneImplementation"))
            ] = vars.hyperlaneImplementation;

            /// @dev 4.3 - deploy Celer Implementation
            vars.celerImplementation = address(
                new CelerImplementation{salt: salt}(
                    IMessageBus(celerMessageBusses[i]),
                    SuperRegistry(vars.superRegistry)
                )
            );
            contracts[vars.chainId][
                bytes32(bytes("CelerImplementation"))
            ] = vars.celerImplementation;

            if (i == 0) {
                ambAddresses.push(vars.lzImplementation);
                ambAddresses.push(vars.hyperlaneImplementation);
                ambAddresses.push(vars.celerImplementation);
            }

            /// @dev 5- deploy socket validator
            vars.socketValidator = address(
                new SocketValidator{salt: salt}(vars.superRegistry)
            );
            contracts[vars.chainId][bytes32(bytes("SocketValidator"))] = vars
                .socketValidator;

            SocketValidator(vars.socketValidator).setChainIds(
                chainIds,
                socketChainIds
            );

            vars.lifiValidator = address(
                new LiFiValidator{salt: salt}(vars.superRegistry)
            );
            contracts[vars.chainId][bytes32(bytes("LiFiValidator"))] = vars
                .lifiValidator;

            LiFiValidator(vars.lifiValidator).setChainIds(
                chainIds,
                lifiChainIds
            );

            /// @dev can do this in first loop because of create2
            if (i == 0) {
                for (uint256 j = 0; j < 3; j++) {
                    bridgeValidators.push(vars.socketValidator);
                }
                bridgeValidators.push(vars.lifiValidator);
            }

            /// @dev 5 - Deploy UNDERLYING_TOKENS and VAULTS
            /// @dev FIXME grab testnet tokens
            /// NOTE: This loop deploys all Forms on all chainIds with all of the UNDERLYING TOKENS (id x form) x chainId
            for (uint256 j = 0; j < UNDERLYING_TOKENS.length; j++) {
                vars.UNDERLYING_TOKEN = address(
                    new MockERC20(
                        UNDERLYING_TOKENS[j],
                        UNDERLYING_TOKENS[j],
                        deployer,
                        milionTokensE18
                    )
                );
                contracts[vars.chainId][
                    bytes32(bytes(UNDERLYING_TOKENS[j]))
                ] = vars.UNDERLYING_TOKEN;
            }
            uint256 vaultId = 0;
            for (uint256 j = 0; j < FORM_BEACON_IDS.length; j++) {
                for (uint256 k = 0; k < UNDERLYING_TOKENS.length; k++) {
                    /// @dev 5 - Deploy mock Vault

                    bytes memory bytecodeWithArgs = abi.encodePacked(
                        vaultBytecodes[j],
                        abi.encode(
                            MockERC20(
                                getContract(vars.chainId, UNDERLYING_TOKENS[k])
                            ),
                            VAULT_NAMES[j][k],
                            VAULT_NAMES[j][k]
                        )
                    );

                    vars.vault = _deployWithCreate2(bytecodeWithArgs, 1);

                    /// @dev Add ERC4626Vault
                    contracts[vars.chainId][
                        bytes32(bytes(string.concat(VAULT_NAMES[j][k])))
                    ] = vars.vault;

                    vaults[vars.chainId][FORM_BEACON_IDS[j]].push(
                        IERC4626(vars.vault)
                    );
                    vaultIds[vars.chainId][FORM_BEACON_IDS[j]].push(vaultId++);
                }
            }

            /// @dev 6 - Deploy SuperFormFactory
            vars.factory = address(
                new SuperFormFactory{salt: salt}(vars.superRegistry)
            );

            contracts[vars.chainId][bytes32(bytes("SuperFormFactory"))] = vars
                .factory;

            SuperRegistry(vars.superRegistry).setSuperFormFactory(vars.factory);
            SuperRBAC(vars.superRBAC).grantSuperformFactoryRole(vars.factory);

            /// @dev 7 - Deploy 4626Form implementations
            // Standard ERC4626 Form
            vars.erc4626Form = address(
                new ERC4626Form{salt: salt}(vars.superRegistry)
            );
            contracts[vars.chainId][bytes32(bytes("ERC4626Form"))] = vars
                .erc4626Form;

            // Timelock + ERC4626 Form
            vars.erc4626TimelockForm = address(
                new ERC4626TimelockForm{salt: salt}(vars.superRegistry)
            );
            contracts[vars.chainId][
                bytes32(bytes("ERC4626TimelockForm"))
            ] = vars.erc4626TimelockForm;

            /// @dev 8 - Add newly deployed form  implementation to Factory, formBeaconId 1
            ISuperFormFactory(vars.factory).addFormBeacon(
                vars.erc4626Form,
                FORM_BEACON_IDS[0],
                salt
            );

            ISuperFormFactory(vars.factory).addFormBeacon(
                vars.erc4626TimelockForm,
                FORM_BEACON_IDS[1],
                salt
            );

            /// @dev 10 - Deploy SuperRouter

            vars.superRouter = address(
                new SuperRouter{salt: salt}(vars.superRegistry)
            );
            contracts[vars.chainId][bytes32(bytes("SuperRouter"))] = vars
                .superRouter;

            SuperRegistry(vars.superRegistry).setSuperRouter(vars.superRouter);
            SuperRBAC(vars.superRBAC).grantSuperRouterRole(vars.superRouter);

            /// @dev 11 - Deploy SuperPositions
            vars.superPositions = address(
                new SuperPositions{salt: salt}("test.com/", vars.superRegistry)
            );

            contracts[vars.chainId][bytes32(bytes("SuperPositions"))] = vars
                .superPositions;
            SuperRegistry(vars.superRegistry).setSuperPositions(
                vars.superPositions
            );
            /// @dev 12 - Deploy MultiTx Processor
            vars.multiTxProcessor = address(
                new MultiTxProcessor{salt: salt}(vars.superRegistry)
            );
            contracts[vars.chainId][bytes32(bytes("MultiTxProcessor"))] = vars
                .multiTxProcessor;

            SuperRegistry(vars.superRegistry).setMultiTxProcessor(
                vars.multiTxProcessor
            );

            /// @dev 13 - Super Registry extra setters

            SuperRegistry(vars.superRegistry).setBridgeAddresses(
                bridgeIds,
                bridgeAddresses,
                bridgeValidators
            );

            /// @dev configures lzImplementation and hyperlane to super registry
            SuperRegistry(payable(getContract(vars.chainId, "SuperRegistry")))
                .setAmbAddress(ambIds, ambAddresses);

            /// @dev 14 Setup extra RBAC

            SuperRBAC(vars.superRBAC).grantCoreContractsRole(vars.superRouter);
            SuperRBAC(vars.superRBAC).grantCoreContractsRole(vars.factory);
            SuperRBAC(vars.superRBAC).grantImplementationContractsRole(
                vars.lzImplementation
            );
            SuperRBAC(vars.superRBAC).grantImplementationContractsRole(
                vars.hyperlaneImplementation
            );
            /// FIXME: check if this is safe in all aspects
            SuperRBAC(vars.superRBAC).grantProtocolAdminRole(
                vars.rolesStateRegistry
            );

            vm.stopBroadcast();
        }

        /// @dev 15 - Setup trusted remotes and deploy superforms. This must be done after the rest of the protocol has been deployed on all chains
        for (uint256 i = 0; i < chainIds.length; i++) {
            vars.chainId = chainIds[i];
            vars.fork = FORKS[vars.chainId];
            vm.selectFork(vars.fork);
            vm.startBroadcast();

            vars.lzImplementation = getContract(
                vars.chainId,
                "LayerzeroImplementation"
            );

            vars.hyperlaneImplementation = getContract(
                vars.chainId,
                "HyperlaneImplementation"
            );

            vars.factory = getContract(vars.chainId, "SuperFormFactory");

            /// @dev Set all trusted remotes for each chain & configure amb chains ids
            for (uint256 j = 0; j < chainIds.length; j++) {
                if (j != i) {
                    vars.dstChainId = chainIds[j];
                    vars.dstAmbChainId = lz_chainIds[j];
                    vars.dstHypChainId = hyperlane_chainIds[j];

                    vars.dstLzImplementation = getContract(
                        vars.dstChainId,
                        "LayerzeroImplementation"
                    );
                    vars.dstHyperlaneImplementation = getContract(
                        vars.dstChainId,
                        "HyperlaneImplementation"
                    );

                    LayerzeroImplementation(payable(vars.lzImplementation))
                        .setTrustedRemote(
                            vars.dstAmbChainId,
                            abi.encodePacked(
                                vars.dstLzImplementation,
                                vars.lzImplementation
                            )
                        );
                    LayerzeroImplementation(payable(vars.lzImplementation))
                        .setChainId(vars.dstChainId, vars.dstAmbChainId);

                    HyperlaneImplementation(
                        payable(vars.hyperlaneImplementation)
                    ).setReceiver(
                            vars.dstHypChainId,
                            vars.dstHyperlaneImplementation
                        );

                    HyperlaneImplementation(
                        payable(vars.hyperlaneImplementation)
                    ).setChainId(vars.dstChainId, vars.dstHypChainId);
                }
            }
            vm.stopBroadcast();
            /// @dev Exports
            for (uint256 j = 0; j < contractNames.length; j++) {
                exportContract(
                    chainNames[i],
                    contractNames[j],
                    getContract(vars.chainId, contractNames[j]),
                    vars.chainId
                );
            }
        }
    }

    function _preDeploymentSetup() private {
        mapping(uint16 => uint256) storage forks = FORKS;
        /*
        forks[ETH] = vm.createFork(ETHEREUM_RPC_URL);
        forks[BSC] = vm.createFork(BSC_RPC_URL);
        forks[AVAX] = vm.createFork(AVALANCHE_RPC_URL);
        forks[POLY] = vm.createFork(POLYGON_RPC_URL);
        forks[ARBI] = vm.createFork(ARBITRUM_RPC_URL);
        forks[OP] = vm.createFork(OPTIMISM_RPC_URL);
        //forks[FTM] = vm.createFork(FANTOM_RPC_URL, 56806404);
        */
        forks[ETH] = vm.createFork("http://127.0.0.1:8545");
        forks[BSC] = vm.createFork("http://127.0.0.1:8546");
        forks[AVAX] = vm.createFork("http://127.0.0.1:8547");
        forks[POLY] = vm.createFork("http://127.0.0.1:8548");
        forks[ARBI] = vm.createFork("http://127.0.0.1:8549");
        forks[OP] = vm.createFork("http://127.0.0.1:8550");

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

        /// @dev setup vault bytecodes
        vaultBytecodes.push(type(VaultMock).creationCode);
        vaultBytecodes.push(type(ERC4626TimelockMock).creationCode);

        string[] memory underlyingTokens = UNDERLYING_TOKENS;
        for (uint256 i = 0; i < VAULT_KINDS.length; i++) {
            for (uint256 j = 0; j < underlyingTokens.length; j++) {
                VAULT_NAMES[i].push(
                    string.concat(underlyingTokens[j], VAULT_KINDS[i])
                );
            }
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
            vm.startBroadcast();

            int256 ethUsdPrice = _getLatestPrice(PRICE_FEEDS[ETH]);

            vm.stopBroadcast();
            vm.selectFork(FORKS[targetChainId_]);
            vm.startBroadcast();

            address targetChainPriceFeed = PRICE_FEEDS[targetChainId_];
            if (targetChainPriceFeed != address(0)) {
                int256 price = _getLatestPrice(targetChainPriceFeed);
                vm.stopBroadcast();

                multiplier = 2 * uint256(ethUsdPrice / price);
            } else {
                vm.stopBroadcast();
                multiplier = 2 * uint256(ethUsdPrice);
            }
            /// @dev return to initial fork

            vm.selectFork(initialFork);
            vm.startBroadcast();
            vm.stopBroadcast();
        }

        return multiplier;
    }

    function _getLatestPrice(
        address priceFeed_
    ) internal view returns (int256) {
        // prettier-ignore
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface(priceFeed_).latestRoundData();
        return price;
    }

    function _deployWithCreate2(
        bytes memory bytecode_,
        uint256 salt_
    ) internal returns (address addr) {
        assembly {
            addr := create2(0, add(bytecode_, 0x20), mload(bytecode_), salt_)

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        return addr;
    }

    function _fundNativeTokens() private {
        for (uint256 i = 0; i < chainIds.length; i++) {
            uint256 multiplier = _getPriceMultiplier(chainIds[i]);

            uint256 amountDeployer = 100000 * multiplier * 1e18;

            vm.selectFork(FORKS[chainIds[i]]);
            vm.startBroadcast();

            vm.deal(deployer, amountDeployer);

            vm.stopBroadcast();
        }
    }

    function exportContract(
        string memory name,
        string memory label,
        address addr,
        uint16 chainId
    ) internal {
        string memory json = vm.serializeAddress("EXPORTS", label, addr);
        string memory root = vm.projectRoot();

        string memory chainOutputFolder = string(
            abi.encodePacked(
                "/script/output/",
                vm.toString(uint256(chainId)),
                "/"
            )
        );

        if (vm.envOr("FOUNDRY_EXPORTS_OVERWRITE_LATEST", false)) {
            vm.writeJson(
                json,
                string(
                    abi.encodePacked(
                        root,
                        chainOutputFolder,
                        name,
                        "-latest.json"
                    )
                )
            );
        } else {
            vm.writeJson(
                json,
                string(
                    abi.encodePacked(
                        root,
                        chainOutputFolder,
                        name,
                        "-",
                        vm.toString(block.timestamp),
                        ".json"
                    )
                )
            );
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

/// @dev Protocol imports
import {IBaseStateRegistry} from "../src/interfaces/IBaseStateRegistry.sol";
import {CoreStateRegistry} from "../src/crosschain-data/CoreStateRegistry.sol";
import {RolesStateRegistry} from "../src/crosschain-data/RolesStateRegistry.sol";
import {FactoryStateRegistry} from "../src/crosschain-data/FactoryStateRegistry.sol";
import {ISuperFormRouter} from "../src/interfaces/ISuperFormRouter.sol";
import {ISuperFormFactory} from "../src/interfaces/ISuperFormFactory.sol";
import {IBaseForm} from "../src/interfaces/IBaseForm.sol";
import {SuperFormRouter} from "../src/SuperFormRouter.sol";
import {SuperRegistry} from "../src/settings/SuperRegistry.sol";
import {SuperRBAC} from "../src/settings/SuperRBAC.sol";
import {SuperPositions} from "../src/SuperPositions.sol";
import {SuperFormFactory} from "../src/SuperFormFactory.sol";
import {ERC4626Form} from "../src/forms/ERC4626Form.sol";
import {ERC4626TimelockForm} from "../src/forms/ERC4626TimelockForm.sol";
import {ERC4626KYCDaoForm} from "../src/forms/ERC4626KYCDaoForm.sol";
import {MultiTxProcessor} from "../src/crosschain-liquidity/MultiTxProcessor.sol";
import {LiFiValidator} from "../src/crosschain-liquidity/lifi/LiFiValidator.sol";
import {SocketValidator} from "../src/crosschain-liquidity/socket/SocketValidator.sol";
import {LayerzeroImplementation} from "../src/crosschain-data/layerzero/LayerzeroImplementation.sol";
import {HyperlaneImplementation} from "../src/crosschain-data/hyperlane/HyperlaneImplementation.sol";
import {CelerImplementation} from "../src/crosschain-data/celer/CelerImplementation.sol";
import {IMailbox} from "../src/vendor/hyperlane/IMailbox.sol";
import {IInterchainGasPaymaster} from "../src/vendor/hyperlane/IInterchainGasPaymaster.sol";
import {IMessageBus} from "../src/vendor/celer/IMessageBus.sol";
import {TwoStepsFormStateRegistry} from "../src/crosschain-data/TwoStepsFormStateRegistry.sol";

struct SetupVars {
    uint64 chainId;
    uint64 dstChainId;
    uint16 dstLzChainId;
    uint32 dstHypChainId;
    uint64 dstCelerChainId;
    string fork;
    address[] ambAddresses;
    address superForm;
    address factory;
    address lzEndpoint;
    address lzImplementation;
    address hyperlaneImplementation;
    address celerImplementation;
    address erc4626Form;
    address erc4626TimelockForm;
    address factoryStateRegistry;
    address twoStepsFormStateRegistry;
    address rolesStateRegistry;
    address coreStateRegistry;
    address UNDERLYING_TOKEN;
    address vault;
    address timelockVault;
    address superRouter;
    address dstLzImplementation;
    address dstHyperlaneImplementation;
    address dstCelerImplementation;
    address dstStateRegistry;
    address multiTxProcessor;
    address superRegistry;
    address superPositions;
    address superRBAC;
    address socketValidator;
    address lifiValidator;
    address kycDao4626Form;
}

abstract contract AbstractDeploySingle is Script {
    /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public constant CANONICAL_PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    mapping(uint64 chainId => mapping(bytes32 implementation => address at)) public contracts;

    string[18] public contractNames = [
        "CoreStateRegistry",
        "FactoryStateRegistry",
        "TwoStepsFormStateRegistry",
        "RolesStateRegistry",
        "LayerzeroImplementation",
        "HyperlaneImplementation",
        "CelerImplementation",
        "SocketValidator",
        "LiFiValidator",
        "SuperFormFactory",
        "ERC4626Form",
        "ERC4626TimelockForm",
        "ERC4626KYCDaoForm",
        "SuperFormRouter",
        "SuperPositions",
        "MultiTxProcessor",
        "SuperRegistry",
        "SuperRBAC"
    ];

    bytes32 constant salt = "SUPERFORM_69";

    enum Chains {
        Ethereum,
        Polygon,
        Bsc,
        Avalanche,
        Arbitrum,
        Optimism,
        Fantom,
        Ethereum_Fork,
        Polygon_Fork,
        Bsc_Fork,
        Avalanche_Fork,
        Arbitrum_Fork,
        Optimism_Fork,
        Fantom_Fork
    }

    enum Cycle {
        Dev,
        Prod
    }

    uint256 public deployerPrivateKey;
    address public ownerAddress;

    /// @dev Mapping of chain enum to rpc url
    mapping(Chains chains => string rpcUrls) public forks;

    /*//////////////////////////////////////////////////////////////
                        PROTOCOL VARIABLES
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
    bytes32 public constant CORE_CONTRACTS_ROLE = keccak256("CORE_CONTRACTS_ROLE");
    bytes32 public constant IMPLEMENTATION_CONTRACTS_ROLE = keccak256("IMPLEMENTATION_CONTRACTS_ROLE");
    bytes32 public constant PROCESSOR_ROLE = keccak256("PROCESSOR_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");
    bytes32 public constant SUPER_ROUTER_ROLE = keccak256("SUPER_ROUTER_ROLE");
    bytes32 public constant STATE_REGISTRY_ROLE = keccak256("STATE_REGISTRY_ROLE");

    /// @dev 1 = ERC4626Form, 2 = ERC4626TimelockForm, 3 = KYCDaoForm
    uint32[] public FORM_BEACON_IDS = [uint32(1), uint32(2), uint32(3)];
    string[] public VAULT_KINDS = ["Vault", "TimelockedVault", "KYCDaoVault"];

    /// @dev liquidity bridge ids. 1,2,3 belong to socket. 4 is lifi
    uint8[] public bridgeIds = [uint8(1), 2, 3, 4];

    mapping(uint64 chainId => address[] bridgeAddresses) public BRIDGE_ADDRESSES;

    /// @dev setup amb bridges
    /// @notice id 1 is layerzero
    /// @notice id 2 is hyperlane
    /// @notice id 3 is celer
    uint8[] public ambIds = [uint8(1), 2, 3];

    /*//////////////////////////////////////////////////////////////
                        AMB VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(uint64 => address) public LZ_ENDPOINTS;
    mapping(uint64 => address) public CELER_BUSSES;
    mapping(uint64 => uint64) public CELER_CHAIN_IDS;

    address public constant ETH_lzEndpoint = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
    address public constant BSC_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant AVAX_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant POLY_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant ARBI_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant OP_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant FTM_lzEndpoint = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;

    IMailbox public constant HyperlaneMailbox = IMailbox(0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70);
    IInterchainGasPaymaster public constant HyperlaneGasPaymaster =
        IInterchainGasPaymaster(0x6cA0B6D22da47f091B7613223cD4BB03a2d77918);

    address public constant ETH_messageBus = 0x4066D196A423b2b3B8B054f4F40efB47a74E200C;
    address public constant BSC_messageBus = 0x95714818fdd7a5454F73Da9c777B3ee6EbAEEa6B;
    address public constant AVAX_messageBus = 0x5a926eeeAFc4D217ADd17e9641e8cE23Cd01Ad57;
    address public constant POLY_messageBus = 0xaFDb9C40C7144022811F034EE07Ce2E110093fe6;
    address public constant ARBI_messageBus = 0x3Ad9d0648CDAA2426331e894e980D0a5Ed16257f;
    address public constant OP_messageBus = 0x0D71D18126E03646eb09FEc929e2ae87b7CAE69d;
    address public constant FTM_messageBus = 0xFF4E183a0Ceb4Fa98E63BbF8077B929c8E5A2bA4;

    address[] public lzEndpoints = [
        0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7
    ];

    /// @dev NOTE: hyperlane does not support FTM
    address[] public hyperlaneMailboxes = [
        0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70,
        0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70,
        0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70,
        0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70,
        0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70,
        0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70,
        address(0)
    ];

    address[] public celerMessageBusses = [
        0x4066D196A423b2b3B8B054f4F40efB47a74E200C,
        0x95714818fdd7a5454F73Da9c777B3ee6EbAEEa6B,
        0x5a926eeeAFc4D217ADd17e9641e8cE23Cd01Ad57,
        0xaFDb9C40C7144022811F034EE07Ce2E110093fe6,
        0x3Ad9d0648CDAA2426331e894e980D0a5Ed16257f,
        0x0D71D18126E03646eb09FEc929e2ae87b7CAE69d,
        0xFF4E183a0Ceb4Fa98E63BbF8077B929c8E5A2bA4
    ];

    /// @dev superformChainIds

    uint64 public constant ETH = 1;
    uint64 public constant BSC = 56;
    uint64 public constant AVAX = 43114;
    uint64 public constant POLY = 137;
    uint64 public constant ARBI = 42161;
    uint64 public constant OP = 10;
    uint64 public constant FTM = 250;

    uint64[] public chainIds = [1, 56, 43114, 137, 42161, 10, 250];
    string[] public chainNames = ["Ethereum", "Binance", "Avalanche", "Polygon", "Arbitrum", "Optimism", "Fantom"];

    /// @dev vendor chain ids
    uint16[] public lz_chainIds = [101, 102, 106, 109, 110, 111, 112];
    uint32[] public hyperlane_chainIds = [1, 56, 43114, 137, 42161, 10, 250];
    uint64[] public celer_chainIds = [1, 56, 43114, 137, 42161, 10, 250];
    uint256[] public socketChainIds = [1, 56, 43114, 137, 42161, 10, 250];
    uint256[] public lifiChainIds = [1, 56, 43114, 137, 42161, 10, 250];

    uint256 public constant milionTokensE18 = 1 ether;

    /*//////////////////////////////////////////////////////////////
                        KYC DAO VALIDITY VARIABLES
    //////////////////////////////////////////////////////////////*/

    address[] public kycDAOValidityAddresses = [
        address(0),
        address(0),
        address(0),
        0x205E10d3c4C87E26eB66B1B270b71b7708494dB9,
        address(0),
        address(0),
        address(0)
    ];

    /// @dev environment variable setup for upgrade
    /// @param cycle deployment cycle (dev, prod)
    modifier setEnvDeploy(Cycle cycle) {
        if (cycle == Cycle.Dev) {
            deployerPrivateKey = vm.envUint("LOCAL_PRIVATE_KEY");
            ownerAddress = vm.envAddress("LOCAL_OWNER_ADDRESS");
        } else {
            deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
            ownerAddress = vm.envAddress("OWNER_ADDRESS");
        }

        _;
    }

    constructor() {
        // Mainnet
        forks[Chains.Ethereum] = "ethereum";
        forks[Chains.Polygon] = "polygon";
        forks[Chains.Bsc] = "bsc";
        forks[Chains.Avalanche] = "avalanche";
        forks[Chains.Arbitrum] = "arbitrum";
        forks[Chains.Optimism] = "optimism";
        forks[Chains.Fantom] = "fantom";

        // Mainnet Forks
        forks[Chains.Ethereum_Fork] = "ethereum_fork";
        forks[Chains.Polygon_Fork] = "polygon_fork";
        forks[Chains.Bsc_Fork] = "bsc_fork";
        forks[Chains.Avalanche_Fork] = "avalanche_fork";
        forks[Chains.Arbitrum_Fork] = "arbitrum_fork";
        forks[Chains.Optimism_Fork] = "optimism_fork";
        forks[Chains.Fantom_Fork] = "fantom_fork";
    }

    function getContract(uint64 chainId, string memory _name) public view returns (address) {
        return contracts[chainId][bytes32(bytes(_name))];
    }

    function _deploy(
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds,
        uint256[] memory s_llBridgeChainIds
    ) internal setEnvDeploy(cycle) {
        SetupVars memory vars;
        /// @dev liquidity validator addresses
        address[] memory bridgeValidators = new address[](bridgeIds.length);

        vars.chainId = s_superFormChainIds[i];

        vars.ambAddresses = new address[](ambIds.length);

        vm.startBroadcast(deployerPrivateKey);

        /// @dev 1 - Deploy SuperRegistry and assign roles
        vars.superRegistry = address(new SuperRegistry{salt: salt}(ownerAddress));
        contracts[vars.chainId][bytes32(bytes("SuperRegistry"))] = vars.superRegistry;

        SuperRegistry(vars.superRegistry).setImmutables(vars.chainId, CANONICAL_PERMIT2);

        SuperRegistry(vars.superRegistry).setProtocolAdmin(ownerAddress);

        /// @dev 2 - Deploy SuperRBAC
        vars.superRBAC = address(new SuperRBAC{salt: salt}(vars.superRegistry, ownerAddress));
        contracts[vars.chainId][bytes32(bytes("SuperRBAC"))] = vars.superRBAC;

        SuperRegistry(vars.superRegistry).setSuperRBAC(vars.superRBAC);

        /// @dev FIXME: in reality who should have the EMERGENCY_ADMIN_ROLE?
        SuperRBAC(vars.superRBAC).grantEmergencyAdminRole(ownerAddress);
        /// @dev FIXME: in reality who should have the SWAPPER_ROLE for multiTxProcessor?
        SuperRBAC(vars.superRBAC).grantSwapperRole(ownerAddress);
        /// @dev FIXME: in reality who should have the PROCESSOR_ROLE for state registry?
        SuperRBAC(vars.superRBAC).grantProcessorRole(ownerAddress);
        /// @dev FIXME: in reality who should have the UPDATER_ROLE for state registry?
        SuperRBAC(vars.superRBAC).grantUpdaterRole(ownerAddress);
        /// @dev FIXME: in reality who should have the TWOSTEPS_PROCESSOR_ROLE for state registry?
        SuperRBAC(vars.superRBAC).grantTwoStepsProcessorRole(ownerAddress);

        /// @dev 3.1 - deploy Core State Registry

        vars.coreStateRegistry = address(new CoreStateRegistry{salt: salt}(SuperRegistry(vars.superRegistry), 1));
        contracts[vars.chainId][bytes32(bytes("CoreStateRegistry"))] = vars.coreStateRegistry;

        SuperRegistry(vars.superRegistry).setCoreStateRegistry(vars.coreStateRegistry);

        /// @dev 3.2- deploy Factory State Registry

        vars.factoryStateRegistry = address(new FactoryStateRegistry{salt: salt}(SuperRegistry(vars.superRegistry), 2));
        contracts[vars.chainId][bytes32(bytes("FactoryStateRegistry"))] = vars.factoryStateRegistry;

        SuperRegistry(vars.superRegistry).setFactoryStateRegistry(vars.factoryStateRegistry);

        /// @dev 3.3 - deploy Form State Registry
        vars.twoStepsFormStateRegistry = address(
            new TwoStepsFormStateRegistry{salt: salt}(SuperRegistry(vars.superRegistry), 4)
        );

        contracts[vars.chainId][bytes32(bytes("TwoStepsFormStateRegistry"))] = vars.twoStepsFormStateRegistry;

        SuperRegistry(vars.superRegistry).setTwoStepsFormStateRegistry(vars.twoStepsFormStateRegistry);

        /// @dev 3.4- deploy Roles State Registry
        vars.rolesStateRegistry = address(new RolesStateRegistry{salt: salt}(SuperRegistry(vars.superRegistry), 3));

        contracts[vars.chainId][bytes32(bytes("RolesStateRegistry"))] = vars.rolesStateRegistry;

        SuperRegistry(vars.superRegistry).setRolesStateRegistry(vars.rolesStateRegistry);

        SuperRegistry(vars.superRegistry).setRolesStateRegistry(vars.rolesStateRegistry);

        address[] memory registryAddresses = new address[](4);
        registryAddresses[0] = vars.coreStateRegistry;
        registryAddresses[1] = vars.factoryStateRegistry;
        registryAddresses[2] = vars.rolesStateRegistry;
        registryAddresses[3] = vars.twoStepsFormStateRegistry;

        uint8[] memory registryIds = new uint8[](4);
        registryIds[0] = 1;
        registryIds[1] = 2;
        registryIds[2] = 3;
        registryIds[3] = 4;

        SuperRegistry(vars.superRegistry).setStateRegistryAddress(registryIds, registryAddresses);
        /// @dev 4.1- deploy Layerzero Implementation
        vars.lzImplementation = address(new LayerzeroImplementation{salt: salt}(SuperRegistry(vars.superRegistry)));
        contracts[vars.chainId][bytes32(bytes("LayerzeroImplementation"))] = vars.lzImplementation;

        LayerzeroImplementation(payable(vars.lzImplementation)).setLzEndpoint(lzEndpoints[trueIndex]);

        /// @dev 4.2- deploy Hyperlane Implementation
        vars.hyperlaneImplementation = address(
            new HyperlaneImplementation{salt: salt}(
                HyperlaneMailbox,
                HyperlaneGasPaymaster,
                SuperRegistry(vars.superRegistry)
            )
        );
        contracts[vars.chainId][bytes32(bytes("HyperlaneImplementation"))] = vars.hyperlaneImplementation;

        /// @dev 4.3 - deploy Celer Implementation
        vars.celerImplementation = address(new CelerImplementation{salt: salt}(SuperRegistry(vars.superRegistry)));
        contracts[vars.chainId][bytes32(bytes("CelerImplementation"))] = vars.celerImplementation;

        CelerImplementation(payable(vars.celerImplementation)).setCelerBus(celerMessageBusses[trueIndex]);

        vars.ambAddresses[0] = vars.lzImplementation;
        vars.ambAddresses[1] = vars.hyperlaneImplementation;
        vars.ambAddresses[2] = vars.celerImplementation;

        /// @dev 5- deploy socket validator
        vars.socketValidator = address(new SocketValidator{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("SocketValidator"))] = vars.socketValidator;

        /// @dev FIXME: set only the corresponding chain ids
        SocketValidator(vars.socketValidator).setChainIds(s_superFormChainIds, s_llBridgeChainIds);

        vars.lifiValidator = address(new LiFiValidator{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("LiFiValidator"))] = vars.lifiValidator;

        /// @dev FIXME: set only the corresponding chain ids
        LiFiValidator(vars.lifiValidator).setChainIds(s_superFormChainIds, s_llBridgeChainIds);

        for (uint256 j = 0; j < 3; j++) {
            bridgeValidators[j] = vars.socketValidator;
        }
        bridgeValidators[3] = vars.lifiValidator;

        /// @dev 6 - Deploy SuperFormFactory
        vars.factory = address(new SuperFormFactory{salt: salt}(vars.superRegistry));

        contracts[vars.chainId][bytes32(bytes("SuperFormFactory"))] = vars.factory;

        SuperRegistry(vars.superRegistry).setSuperFormFactory(vars.factory);

        /// @dev 7 - Deploy 4626Form implementations
        // Standard ERC4626 Form
        vars.erc4626Form = address(new ERC4626Form{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("ERC4626Form"))] = vars.erc4626Form;

        // Timelock + ERC4626 Form
        vars.erc4626TimelockForm = address(new ERC4626TimelockForm{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("ERC4626TimelockForm"))] = vars.erc4626TimelockForm;

        /// @dev 8 - Add newly deployed form  implementation to Factory, formBeaconId 1
        ISuperFormFactory(vars.factory).addFormBeacon(vars.erc4626Form, FORM_BEACON_IDS[0], salt);

        ISuperFormFactory(vars.factory).addFormBeacon(vars.erc4626TimelockForm, FORM_BEACON_IDS[1], salt);

        /// @dev 9 KYCDao ERC4626 Form (only for Polygon)
        vars.kycDao4626Form = address(new ERC4626KYCDaoForm{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("ERC4626KYCDaoForm"))] = vars.kycDao4626Form;

        ISuperFormFactory(vars.factory).addFormBeacon(vars.kycDao4626Form, FORM_BEACON_IDS[2], salt);

        /// @dev 10 - Deploy SuperFormRouter

        vars.superRouter = address(new SuperFormRouter{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("SuperFormRouter"))] = vars.superRouter;

        SuperRegistry(vars.superRegistry).setSuperRouter(vars.superRouter);

        /// @dev 11 - Deploy SuperPositions
        vars.superPositions = address(new SuperPositions{salt: salt}("test.com/", vars.superRegistry));

        contracts[vars.chainId][bytes32(bytes("SuperPositions"))] = vars.superPositions;
        SuperRegistry(vars.superRegistry).setSuperPositions(vars.superPositions);
        /// @dev 12 - Deploy MultiTx Processor
        vars.multiTxProcessor = address(new MultiTxProcessor{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("MultiTxProcessor"))] = vars.multiTxProcessor;

        SuperRegistry(vars.superRegistry).setMultiTxProcessor(vars.multiTxProcessor);

        /// @dev 13 - Super Registry extra setters

        SuperRegistry(vars.superRegistry).setBridgeAddresses(
            bridgeIds,
            BRIDGE_ADDRESSES[vars.chainId],
            bridgeValidators
        );

        /// @dev configures lzImplementation and hyperlane to super registry
        SuperRegistry(payable(getContract(vars.chainId, "SuperRegistry"))).setAmbAddress(ambIds, vars.ambAddresses);

        /// @dev 14 Setup extra RBAC

        SuperRBAC(vars.superRBAC).grantCoreContractsRole(vars.superRouter);
        SuperRBAC(vars.superRBAC).grantCoreContractsRole(vars.factory);

        /// FIXME: check if this is safe in all aspects
        SuperRBAC(vars.superRBAC).grantProtocolAdminRole(vars.rolesStateRegistry);

        for (uint256 j = 0; j < s_superFormChainIds.length; j++) {
            if (j != i) {
                vars.dstChainId = s_superFormChainIds[j];
                vars.dstLzChainId = lz_chainIds[j];
                vars.dstHypChainId = hyperlane_chainIds[j];
                vars.dstCelerChainId = celer_chainIds[j];

                vars.dstLzImplementation = getContract(vars.chainId, "LayerzeroImplementation");
                // 0x90a9D112fd9337C60C8404234dF1FeBa570f2a1E
                vars.dstHyperlaneImplementation = getContract(vars.chainId, "HyperlaneImplementation");
                // 0xff07dE9eb321Aa70CB41363fC47Fad6092F0eB43

                vars.dstCelerImplementation = getContract(vars.chainId, "CelerImplementation");
                // 0x24D1cF9E531d1636A83880c2aA9d60B0f613E2Ce

                LayerzeroImplementation(payable(vars.lzImplementation)).setTrustedRemote(
                    vars.dstLzChainId,
                    abi.encodePacked(vars.dstLzImplementation, vars.lzImplementation)
                );
                LayerzeroImplementation(payable(vars.lzImplementation)).setChainId(vars.dstChainId, vars.dstLzChainId);

                HyperlaneImplementation(payable(vars.hyperlaneImplementation)).setReceiver(
                    vars.dstHypChainId,
                    vars.dstHyperlaneImplementation
                );

                HyperlaneImplementation(payable(vars.hyperlaneImplementation)).setChainId(
                    vars.dstChainId,
                    vars.dstHypChainId
                );

                CelerImplementation(payable(vars.celerImplementation)).setReceiver(
                    vars.dstCelerChainId,
                    vars.dstCelerImplementation
                );

                CelerImplementation(payable(vars.celerImplementation)).setChainId(
                    vars.dstChainId,
                    vars.dstCelerChainId
                );
            }
        }
        vm.stopBroadcast();

        /// @dev Exports
        for (uint256 j = 0; j < contractNames.length; j++) {
            exportContract(
                chainNames[trueIndex],
                contractNames[j],
                getContract(vars.chainId, contractNames[j]),
                vars.chainId
            );
        }
    }

    function _preDeploymentSetup() internal {
        mapping(uint64 => address) storage lzEndpointsStorage = LZ_ENDPOINTS;
        lzEndpointsStorage[ETH] = ETH_lzEndpoint;
        lzEndpointsStorage[BSC] = BSC_lzEndpoint;
        lzEndpointsStorage[AVAX] = AVAX_lzEndpoint;
        lzEndpointsStorage[POLY] = POLY_lzEndpoint;
        lzEndpointsStorage[ARBI] = ARBI_lzEndpoint;
        lzEndpointsStorage[OP] = OP_lzEndpoint;
        lzEndpointsStorage[FTM] = FTM_lzEndpoint;

        mapping(uint64 => address) storage celerMessageBusStorage = CELER_BUSSES;
        celerMessageBusStorage[ETH] = ETH_messageBus;
        celerMessageBusStorage[BSC] = BSC_messageBus;
        celerMessageBusStorage[AVAX] = AVAX_messageBus;
        celerMessageBusStorage[POLY] = POLY_messageBus;
        celerMessageBusStorage[ARBI] = ARBI_messageBus;
        celerMessageBusStorage[OP] = OP_messageBus;
        celerMessageBusStorage[FTM] = FTM_messageBus;

        mapping(uint64 => uint64) storage celerChainIdsStorage = CELER_CHAIN_IDS;

        for (uint256 i = 0; i < chainIds.length; i++) {
            celerChainIdsStorage[chainIds[i]] = celer_chainIds[i];
        }

        mapping(uint64 chainId => address[] bridgeAddresses) storage bridgeAddresses = BRIDGE_ADDRESSES;
        bridgeAddresses[ETH] = [
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0,
            0x2ddf16BA6d0180e5357d5e170eF1917a01b41fc0,
            0x33BE2a7CF4Bb94d28131116F840d313Cab1eD2DA,
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE
        ];
        bridgeAddresses[BSC] = [
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0,
            0xd286595d2e3D879596FAB51f83A702D10a6db27b,
            0x805696d6079ce9F347811f0Fe4D7e4c24C15dF5f,
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE
        ];
        bridgeAddresses[AVAX] = [
            0x2b42AFFD4b7C14d9B7C2579229495c052672Ccd3,
            0xbDf50eAe568ECef74796ed6022a0d453e8432410,
            0xdcABb6d7E88396498FFF4CD987F60e354BF2a44b,
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE
        ];
        bridgeAddresses[POLY] = [
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0,
            0x2ddf16BA6d0180e5357d5e170eF1917a01b41fc0,
            0xAE3dd4C0E3cA6823Cdbe9641B1938551cCb25a2d,
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE
        ];
        bridgeAddresses[ARBI] = [
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0,
            0xaa3d9fA3aB930aE635b001d00C612aa5b14d750e,
            address(0),
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE
        ];
        bridgeAddresses[OP] = [
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0,
            0xbDf50eAe568ECef74796ed6022a0d453e8432410,
            0x2d7F2B4CEe097F08ed8d30D928A40eB1379071Fe,
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE
        ];

        bridgeAddresses[FTM] = [
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0,
            address(0),
            0xA7649aa944b7Dce781859C18913c2Dc8A97f03e4,
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE
        ];
    }

    function exportContract(string memory name, string memory label, address addr, uint64 chainId) internal {
        string memory json = vm.serializeAddress("EXPORTS", label, addr);
        string memory root = vm.projectRoot();

        string memory chainOutputFolder = string(
            abi.encodePacked("/script/output/", vm.toString(uint256(chainId)), "/")
        );

        if (vm.envOr("FOUNDRY_EXPORTS_OVERWRITE_LATEST", false)) {
            vm.writeJson(json, string(abi.encodePacked(root, chainOutputFolder, name, "-latest.json")));
        } else {
            vm.writeJson(
                json,
                string(abi.encodePacked(root, chainOutputFolder, name, "-", vm.toString(block.timestamp), ".json"))
            );
        }
    }

    function _deployWithCreate2(bytes memory bytecode_, uint256 salt_) internal returns (address addr) {
        assembly {
            addr := create2(0, add(bytecode_, 0x20), mload(bytecode_), salt_)

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        return addr;
    }
}

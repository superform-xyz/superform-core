// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {IERC1155A} from "ERC1155A/interfaces/IERC1155A.sol";

/// @dev Protocol imports
import {CoreStateRegistry} from "src/crosschain-data/extensions/CoreStateRegistry.sol";
import {FactoryStateRegistry} from "src/crosschain-data/extensions/FactoryStateRegistry.sol";
import {ISuperformFactory} from "src/interfaces/ISuperformFactory.sol";
import {SuperformRouter} from "src/SuperformRouter.sol";
import {SuperRegistry} from "src/settings/SuperRegistry.sol";
import {SuperRBAC} from "src/settings/SuperRBAC.sol";
import {SuperPositions} from "src/SuperPositions.sol";
import {SuperformFactory} from "src/SuperformFactory.sol";
import {ERC4626Form} from "src/forms/ERC4626Form.sol";
import {ERC4626TimelockForm} from "src/forms/ERC4626TimelockForm.sol";
import {ERC4626KYCDaoForm} from "src/forms/ERC4626KYCDaoForm.sol";
import {MultiTxProcessor} from "src/crosschain-liquidity/MultiTxProcessor.sol";
import {LiFiValidator} from "src/crosschain-liquidity/lifi/LiFiValidator.sol";
import {SocketValidator} from "src/crosschain-liquidity/socket/SocketValidator.sol";
import {LayerzeroImplementation} from "src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol";
import {HyperlaneImplementation} from "src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol";
import {CelerImplementation} from "src/crosschain-data/adapters/celer/CelerImplementation.sol";
import {IMailbox} from "src/vendor/hyperlane/IMailbox.sol";
import {IInterchainGasPaymaster} from "src/vendor/hyperlane/IInterchainGasPaymaster.sol";
import {TwoStepsFormStateRegistry} from "src/crosschain-data/extensions/TwoStepsFormStateRegistry.sol";
import {PayloadHelper} from "src/crosschain-data/utils/PayloadHelper.sol";
import {PaymentHelper} from "src/payments/PaymentHelper.sol";
import {PayMaster} from "src/payments/PayMaster.sol";
import {SuperTransmuter} from "src/SuperTransmuter.sol";

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
    address PayloadHelper;
    address paymentHelper;
    address payMaster;
}

abstract contract AbstractDeploySingle is Script {
    /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public constant CANONICAL_PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    mapping(uint64 chainId => mapping(bytes32 implementation => address at)) public contracts;

    string[21] public contractNames = [
        "CoreStateRegistry",
        "FactoryStateRegistry",
        "TwoStepsFormStateRegistry",
        "LayerzeroImplementation",
        "HyperlaneImplementation",
        "CelerImplementation",
        "SocketValidator",
        "LiFiValidator",
        "SuperformFactory",
        "ERC4626Form",
        "ERC4626TimelockForm",
        "ERC4626KYCDaoForm",
        "SuperformRouter",
        "SuperPositions",
        "MultiTxProcessor",
        "SuperRegistry",
        "SuperRBAC",
        "SuperTransmuter",
        "PayloadHelper",
        "PaymentHelper",
        "PayMaster"
    ];

    bytes32 constant salt = "SUPERFORM_4RD_TEST";

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

    address public constant CHAINLINK_lzOracle = 0x150A58e9E6BF69ccEb1DBA5ae97C166DC8792539;

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
                        CHAINLINK VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(uint64 => mapping(uint64 => address)) public PRICE_FEEDS;

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
        uint64[] memory s_superFormChainIds
    ) internal setEnvDeploy(cycle) {
        SetupVars memory vars;
        /// @dev liquidity validator addresses
        address[] memory bridgeValidators = new address[](bridgeIds.length);

        vars.chainId = s_superFormChainIds[i];

        vars.ambAddresses = new address[](ambIds.length);

        vm.startBroadcast(deployerPrivateKey);

        /// @dev 1 - Deploy SuperRBAC
        vars.superRBAC = address(new SuperRBAC{salt: salt}(ownerAddress));
        contracts[vars.chainId][bytes32(bytes("SuperRBAC"))] = vars.superRBAC;

        /// @dev 2 - Deploy SuperRegistry and assign roles
        vars.superRegistry = address(new SuperRegistry{salt: salt}(vars.superRBAC));
        contracts[vars.chainId][bytes32(bytes("SuperRegistry"))] = vars.superRegistry;

        SuperRBAC(vars.superRBAC).setSuperRegistry(vars.superRegistry);
        SuperRegistry(vars.superRegistry).setImmutables(vars.chainId, CANONICAL_PERMIT2);

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

        vars.coreStateRegistry = address(new CoreStateRegistry{salt: salt}(SuperRegistry(vars.superRegistry)));
        contracts[vars.chainId][bytes32(bytes("CoreStateRegistry"))] = vars.coreStateRegistry;

        SuperRegistry(vars.superRegistry).setCoreStateRegistry(vars.coreStateRegistry);

        /// @dev 3.2- deploy Factory State Registry

        vars.factoryStateRegistry = address(new FactoryStateRegistry{salt: salt}(SuperRegistry(vars.superRegistry)));
        contracts[vars.chainId][bytes32(bytes("FactoryStateRegistry"))] = vars.factoryStateRegistry;

        SuperRegistry(vars.superRegistry).setFactoryStateRegistry(vars.factoryStateRegistry);

        /// @dev 3.3 - deploy Form State Registry
        vars.twoStepsFormStateRegistry = address(
            new TwoStepsFormStateRegistry{salt: salt}(SuperRegistry(vars.superRegistry))
        );

        contracts[vars.chainId][bytes32(bytes("TwoStepsFormStateRegistry"))] = vars.twoStepsFormStateRegistry;

        SuperRegistry(vars.superRegistry).setTwoStepsFormStateRegistry(vars.twoStepsFormStateRegistry);

        // SuperRegistry(vars.superRegistry).setRolesStateRegistry(vars.rolesStateRegistry);

        address[] memory registryAddresses = new address[](3);
        registryAddresses[0] = vars.coreStateRegistry;
        registryAddresses[1] = vars.factoryStateRegistry;
        //registryAddresses[2] = vars.rolesStateRegistry; /// @dev unused for now (will be address 0)
        registryAddresses[2] = vars.twoStepsFormStateRegistry;

        uint8[] memory registryIds = new uint8[](3);
        registryIds[0] = 1;
        registryIds[1] = 2;
        //registryIds[2] = 3;
        registryIds[2] = 4;

        SuperRegistry(vars.superRegistry).setStateRegistryAddress(registryIds, registryAddresses);
        SuperRBAC(vars.superRBAC).grantMinterStateRegistryRole(vars.coreStateRegistry);
        SuperRBAC(vars.superRBAC).grantMinterStateRegistryRole(vars.twoStepsFormStateRegistry);

        /// @dev 4- deploy Payment Helper
        vars.paymentHelper = address(new PaymentHelper{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("PaymentHelper"))] = vars.paymentHelper;

        SuperRegistry(vars.superRegistry).setPaymentHelper(vars.paymentHelper);

        /// @dev 5.1- deploy Layerzero Implementation
        vars.lzImplementation = address(new LayerzeroImplementation{salt: salt}(SuperRegistry(vars.superRegistry)));
        contracts[vars.chainId][bytes32(bytes("LayerzeroImplementation"))] = vars.lzImplementation;

        LayerzeroImplementation(payable(vars.lzImplementation)).setLzEndpoint(lzEndpoints[trueIndex]);

        /// @dev 5.2- deploy Hyperlane Implementation
        vars.hyperlaneImplementation = address(
            new HyperlaneImplementation{salt: salt}(
                HyperlaneMailbox,
                HyperlaneGasPaymaster,
                SuperRegistry(vars.superRegistry)
            )
        );
        contracts[vars.chainId][bytes32(bytes("HyperlaneImplementation"))] = vars.hyperlaneImplementation;

        /// @dev 5.3 - deploy Celer Implementation
        vars.celerImplementation = address(new CelerImplementation{salt: salt}(SuperRegistry(vars.superRegistry)));
        contracts[vars.chainId][bytes32(bytes("CelerImplementation"))] = vars.celerImplementation;

        CelerImplementation(payable(vars.celerImplementation)).setCelerBus(celerMessageBusses[trueIndex]);

        vars.ambAddresses[0] = vars.lzImplementation;
        vars.ambAddresses[1] = vars.hyperlaneImplementation;
        vars.ambAddresses[2] = vars.celerImplementation;

        /// @dev 6- deploy socket validator
        vars.socketValidator = address(new SocketValidator{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("SocketValidator"))] = vars.socketValidator;

        vars.lifiValidator = address(new LiFiValidator{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("LiFiValidator"))] = vars.lifiValidator;

        for (uint256 j = 0; j < 3; j++) {
            bridgeValidators[j] = vars.socketValidator;
        }
        bridgeValidators[3] = vars.lifiValidator;

        /// @dev 7 - Deploy SuperformFactory
        vars.factory = address(new SuperformFactory{salt: salt}(vars.superRegistry));

        contracts[vars.chainId][bytes32(bytes("SuperformFactory"))] = vars.factory;

        SuperRegistry(vars.superRegistry).setSuperformFactory(vars.factory);

        /// @dev 8 - Deploy 4626Form implementations
        // Standard ERC4626 Form
        vars.erc4626Form = address(new ERC4626Form{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("ERC4626Form"))] = vars.erc4626Form;

        // Timelock + ERC4626 Form
        vars.erc4626TimelockForm = address(new ERC4626TimelockForm{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("ERC4626TimelockForm"))] = vars.erc4626TimelockForm;

        /// 9 KYCDao ERC4626 Form
        vars.kycDao4626Form = address(new ERC4626KYCDaoForm{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("ERC4626KYCDaoForm"))] = vars.kycDao4626Form;

        /// @dev 9 - Add newly deployed form  implementation to Factory, formBeaconId 1
        ISuperformFactory(vars.factory).addFormBeacon(vars.erc4626Form, FORM_BEACON_IDS[0], salt);

        ISuperformFactory(vars.factory).addFormBeacon(vars.erc4626TimelockForm, FORM_BEACON_IDS[1], salt);

        ISuperformFactory(vars.factory).addFormBeacon(vars.kycDao4626Form, FORM_BEACON_IDS[2], salt);

        /// @dev 10 - Deploy SuperformRouter

        vars.superRouter = address(new SuperformRouter{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("SuperformRouter"))] = vars.superRouter;

        SuperRegistry(vars.superRegistry).setSuperRouter(vars.superRouter);

        /// @dev 11 - Deploy SuperPositions
        vars.superPositions = address(
            new SuperPositions{salt: salt}("https://apiv2-dev.superform.xyz/", vars.superRegistry)
        );

        contracts[vars.chainId][bytes32(bytes("SuperPositions"))] = vars.superPositions;
        SuperRegistry(vars.superRegistry).setSuperPositions(vars.superPositions);

        contracts[vars.chainId][bytes32(bytes("SuperTransmuter"))] = address(
            new SuperTransmuter{salt: salt}(IERC1155A(vars.superPositions), vars.superRegistry)
        );

        /// @dev 12 - Deploy Payload Helper
        vars.PayloadHelper = address(
            new PayloadHelper{salt: salt}(vars.coreStateRegistry, vars.superPositions, vars.twoStepsFormStateRegistry)
        );
        contracts[vars.chainId][bytes32(bytes("PayloadHelper"))] = vars.PayloadHelper;

        /// @dev 13 - Deploy MultiTx Processor
        vars.multiTxProcessor = address(new MultiTxProcessor{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("MultiTxProcessor"))] = vars.multiTxProcessor;

        SuperRegistry(vars.superRegistry).setMultiTxProcessor(vars.multiTxProcessor);

        /// @dev 14 - Deploy PayMaster
        vars.payMaster = address(new PayMaster{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes32("PayMaster"))] = vars.payMaster;

        SuperRegistry(vars.superRegistry).setPayMaster(vars.payMaster);

        /// @dev 15 - Super Registry extra setters
        SuperRegistry(vars.superRegistry).setBridgeAddresses(
            bridgeIds,
            BRIDGE_ADDRESSES[vars.chainId],
            bridgeValidators
        );

        /// @dev configures lzImplementation and hyperlane to super registry
        SuperRegistry(payable(getContract(vars.chainId, "SuperRegistry"))).setAmbAddress(ambIds, vars.ambAddresses);

        /// @dev 16 Setup extra RBAC
        SuperRBAC(vars.superRBAC).grantCoreContractsRole(vars.superRouter);
        SuperRBAC(vars.superRBAC).grantCoreContractsRole(vars.factory);

        /// FIXME: check if this is safe in all aspects
        /// @dev disabled as we are not using rolesStateRegistry for now
        /// SuperRBAC(vars.superRBAC).grantProtocolAdminRole(vars.rolesStateRegistry);

        for (uint256 j = 0; j < s_superFormChainIds.length; j++) {
            if (j != i) {
                vars.dstChainId = s_superFormChainIds[j];
                vars.dstLzChainId = lz_chainIds[j];
                vars.dstHypChainId = hyperlane_chainIds[j];
                vars.dstCelerChainId = celer_chainIds[j];

                vars.dstLzImplementation = getContract(vars.dstChainId, "LayerzeroImplementation");
                vars.dstHyperlaneImplementation = getContract(vars.dstChainId, "HyperlaneImplementation");
                vars.dstCelerImplementation = getContract(vars.dstChainId, "CelerImplementation");

                LayerzeroImplementation(payable(vars.lzImplementation)).setTrustedRemote(
                    vars.dstLzChainId,
                    abi.encodePacked(vars.dstLzImplementation, vars.lzImplementation)
                );
                LayerzeroImplementation(payable(vars.lzImplementation)).setChainId(vars.dstChainId, vars.dstLzChainId);
                LayerzeroImplementation(payable(vars.lzImplementation)).setConfig(
                    0, /// Defaults To Zero
                    vars.dstLzChainId,
                    6, /// For Oracle Config
                    abi.encode(CHAINLINK_lzOracle)
                );

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

                SuperRegistry(payable(vars.superRegistry)).setRequiredMessagingQuorum(vars.dstChainId, 1);

                /// swap gas cost: 50000
                /// update gas cost: 40000
                /// deposit gas cost: 70000
                /// withdraw gas cost: 80000
                /// default gas price: 50 Gwei
                PaymentHelper(payable(vars.paymentHelper)).addChain(
                    vars.dstChainId,
                    address(0),
                    PRICE_FEEDS[vars.chainId][vars.dstChainId],
                    50000,
                    40000,
                    70000,
                    80000,
                    10 wei,
                    50 * 10 ** 9 wei,
                    10 wei
                );
            } else {
                /// ack gas cost: 40000
                /// two step form cost: 50000
                /// default gas price: 50 Gwei
                PaymentHelper(payable(vars.paymentHelper)).setSameChainConfig(
                    2,
                    abi.encode(PRICE_FEEDS[vars.chainId][vars.chainId])
                );
                PaymentHelper(payable(vars.paymentHelper)).setSameChainConfig(3, abi.encode(40000));
                PaymentHelper(payable(vars.paymentHelper)).setSameChainConfig(3, abi.encode(50000));
                PaymentHelper(payable(vars.paymentHelper)).setSameChainConfig(3, abi.encode(50 * 10 ** 9 wei));
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

        /// price feeds on all chains
        mapping(uint64 => mapping(uint64 => address)) storage priceFeeds = PRICE_FEEDS;

        /// ETH
        priceFeeds[ETH][ETH] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][BSC] = 0x14e613AC84a31f709eadbdF89C6CC390fDc9540A;
        priceFeeds[ETH][AVAX] = 0xFF3EEb22B5E3dE6e705b44749C2559d704923FD7;
        priceFeeds[ETH][POLY] = 0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676;
        priceFeeds[ETH][OP] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][ARBI] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

        /// BSC
        priceFeeds[BSC][BSC] = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        priceFeeds[BSC][ETH] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][AVAX] = address(0);
        priceFeeds[BSC][POLY] = 0x7CA57b0cA6367191c94C8914d7Df09A57655905f;
        priceFeeds[BSC][OP] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][ARBI] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;

        /// AVAX
        priceFeeds[AVAX][AVAX] = 0x0A77230d17318075983913bC2145DB16C7366156;
        priceFeeds[AVAX][BSC] = address(0);
        priceFeeds[AVAX][ETH] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][POLY] = address(0);
        priceFeeds[AVAX][OP] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][ARBI] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;

        /// POLYGON
        priceFeeds[POLY][POLY] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        priceFeeds[POLY][AVAX] = address(0);
        priceFeeds[POLY][BSC] = 0x82a6c4AF830caa6c97bb504425f6A66165C2c26e;
        priceFeeds[POLY][ETH] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][OP] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][ARBI] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;

        /// OPTIMISM
        priceFeeds[OP][OP] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][POLY] = address(0);
        priceFeeds[OP][AVAX] = address(0);
        priceFeeds[OP][BSC] = address(0);
        priceFeeds[OP][ETH] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][ARBI] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;

        /// ARBITRUM
        priceFeeds[ARBI][ARBI] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][OP] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][POLY] = 0x52099D4523531f678Dfc568a7B1e5038aadcE1d6;
        priceFeeds[ARBI][AVAX] = address(0);
        priceFeeds[ARBI][BSC] = address(0);
        priceFeeds[ARBI][ETH] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
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

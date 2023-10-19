// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { Script } from "forge-std/Script.sol";
import { IERC1155A } from "ERC1155A/interfaces/IERC1155A.sol";
/// @dev Protocol imports
import { CoreStateRegistry } from "src/crosschain-data/extensions/CoreStateRegistry.sol";
import { BroadcastRegistry } from "src/crosschain-data/BroadcastRegistry.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";
import { SuperformRouter } from "src/SuperformRouter.sol";
import { SuperRegistry } from "src/settings/SuperRegistry.sol";
import { SuperRBAC } from "src/settings/SuperRBAC.sol";
import { SuperPositions } from "src/SuperPositions.sol";
import { SuperformFactory } from "src/SuperformFactory.sol";
import { ERC4626Form } from "src/forms/ERC4626Form.sol";
import { ERC4626TimelockForm } from "src/forms/ERC4626TimelockForm.sol";
import { ERC4626KYCDaoForm } from "src/forms/ERC4626KYCDaoForm.sol";
import { DstSwapper } from "src/crosschain-liquidity/DstSwapper.sol";
import { LiFiValidator } from "src/crosschain-liquidity/lifi/LiFiValidator.sol";
import { SocketValidator } from "src/crosschain-liquidity/socket/SocketValidator.sol";
import { SocketOneInchValidator } from "src/crosschain-liquidity/socket/SocketOneInchValidator.sol";
import { LayerzeroImplementation } from "src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol";
import { HyperlaneImplementation } from "src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol";
import { WormholeARImplementation } from
    "src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol";
import { WormholeSRImplementation } from
    "src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol";
import { IMailbox } from "src/vendor/hyperlane/IMailbox.sol";
import { IInterchainGasPaymaster } from "src/vendor/hyperlane/IInterchainGasPaymaster.sol";
import { TimelockStateRegistry } from "src/crosschain-data/extensions/TimelockStateRegistry.sol";
import { PayloadHelper } from "src/crosschain-data/utils/PayloadHelper.sol";
import { PaymentHelper } from "src/payments/PaymentHelper.sol";
import { IPaymentHelper } from "src/interfaces/IPaymentHelper.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { PayMaster } from "src/payments/PayMaster.sol";
import { SuperTransmuter } from "src/SuperTransmuter.sol";
import { EmergencyQueue } from "src/emergency/EmergencyQueue.sol";

struct SetupVars {
    uint64 chainId;
    uint64 dstChainId;
    uint16 dstLzChainId;
    uint32 dstHypChainId;
    uint16 dstWormholeChainId;
    string fork;
    address[] ambAddresses;
    address superForm;
    address factory;
    address lzEndpoint;
    address lzImplementation;
    address hyperlaneImplementation;
    address wormholeImplementation;
    address wormholeSRImplementation;
    address erc4626Form;
    address erc4626TimelockForm;
    address twoStepsFormStateRegistry;
    address broadcastRegistry;
    address coreStateRegistry;
    address UNDERLYING_TOKEN;
    address vault;
    address timelockVault;
    address superformRouter;
    address dstLzImplementation;
    address dstHyperlaneImplementation;
    address dstWormholeARImplementation;
    address dstWormholeSRImplementation;
    address dstStateRegistry;
    address dstSwapper;
    address superRegistry;
    address superPositions;
    address superRBAC;
    address lifiValidator;
    address socketValidator;
    address socketOneInchValidator;
    address kycDao4626Form;
    address PayloadHelper;
    address paymentHelper;
    address payMaster;
    address emergencyQueue;
    SuperRegistry superRegistryC;
    SuperRBAC superRBACC;
}

abstract contract AbstractDeploySingle is Script {
    /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public constant CANONICAL_PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    mapping(uint64 chainId => mapping(bytes32 implementation => address at)) public contracts;

    string[24] public contractNames = [
        "CoreStateRegistry",
        "TimelockStateRegistry",
        "BroadcastRegistry",
        "LayerzeroImplementation",
        "HyperlaneImplementation",
        "WormholeARImplementation",
        "WormholeSRImplementation",
        "LiFiValidator",
        "SocketValidator",
        "SocketOneInchValidator",
        "DstSwapper",
        "SuperformFactory",
        "ERC4626Form",
        "ERC4626TimelockForm",
        "ERC4626KYCDaoForm",
        "SuperformRouter",
        "SuperPositions",
        "SuperRegistry",
        "SuperRBAC",
        "SuperTransmuter",
        "PayloadHelper",
        "PaymentHelper",
        "PayMaster",
        "EmergencyQueue"
    ];

    bytes32 constant salt = "SUPERFORM_TENTATIVE_DEPLOYMENT2";

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

    /// @dev 1 = ERC4626Form, 2 = ERC4626TimelockForm, 3 = KYCDaoForm
    uint32[] public FORM_IMPLEMENTATION_IDS = [uint32(1), uint32(2), uint32(3)];
    string[] public VAULT_KINDS = ["Vault", "TimelockedVault", "KYCDaoVault"];

    /// @dev liquidity bridge ids 1 is lifi, 2 is socket, 3 is socket one inch implementation
    uint8[] public bridgeIds = [1, 2, 3];

    mapping(uint64 chainId => address[] bridgeAddresses) public BRIDGE_ADDRESSES;

    /// @dev setup amb bridges
    /// @notice id 1 is layerzero
    /// @notice id 2 is hyperlane
    /// @notice id 3 is wormhole AR
    /// @notice 4 is wormhole SR
    uint8[] public ambIds = [uint8(1), 2, 3, 4];
    bool[] public broadcastAMB = [false, false, false, true];

    /*//////////////////////////////////////////////////////////////
                        AMB VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(uint64 => address) public LZ_ENDPOINTS;

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

    address[] public wormholeCore = [
        0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B,
        0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B,
        0x54a8e5f9c4CbA08F9943965859F6c34eAF03E26c,
        0x7A4B5a56256163F07b2C80A7cA55aBE66c4ec4d7,
        0xa5f208e072434bC67592E4C49C1B991BA79BCA46,
        0xEe91C335eab126dF5fDB3797EA9d6aD93aeC9722
    ];

    /// @dev uses CREATE2
    address public wormholeRelayer = 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911;

    /// @dev superformChainIds

    uint64 public constant ETH = 1;
    uint64 public constant BSC = 56;
    uint64 public constant AVAX = 43_114;
    uint64 public constant POLY = 137;
    uint64 public constant ARBI = 42_161;
    uint64 public constant OP = 10;
    uint64 public constant FTM = 250;

    uint64[] public chainIds = [1, 56, 43_114, 137, 42_161, 10, 250];
    string[] public chainNames = ["Ethereum", "Binance", "Avalanche", "Polygon", "Arbitrum", "Optimism", "Fantom"];

    /// @dev vendor chain ids
    uint16[] public lz_chainIds = [101, 102, 106, 109, 110, 111, 112];
    uint32[] public hyperlane_chainIds = [1, 56, 43_114, 137, 42_161, 10, 250];
    uint16[] public wormhole_chainIds = [2, 6, 23, 5, 4, 24];
    uint256[] public lifiChainIds = [1, 56, 43_114, 137, 42_161, 10, 250];

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

    function _deployStage1(
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
        setEnvDeploy(cycle)
    {
        SetupVars memory vars;
        /// @dev liquidity validator addresses
        address[] memory bridgeValidators = new address[](bridgeIds.length);

        vars.chainId = s_superFormChainIds[i];

        vars.ambAddresses = new address[](ambIds.length);

        vm.startBroadcast(deployerPrivateKey);

        /// @dev 1 - Deploy SuperRBAC
        vars.superRBAC = address(
            new SuperRBAC{salt: salt}(ISuperRBAC.InitialRoleSetup({
                        admin: ownerAddress,
                        emergencyAdmin: ownerAddress, /// @dev NOTE this should be 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490, but must be ownerAddress on deployment
                        paymentAdmin: 0xD911673eAF0D3e15fe662D58De15511c5509bAbB,
                        csrProcessor: 0x23c658FE050B4eAeB9401768bF5911D11621629c,
                        tlProcessor: ownerAddress,
                        brProcessor: ownerAddress,
                        csrUpdater: 0xaEbb4b9f7e16BEE2a0963569a5E33eE10E478a5f,
                        srcVaaRelayer: ownerAddress,
                        dstSwapper: 0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C,
                        csrRescuer: 0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5,
                        csrDisputer: ownerAddress
                    }))
        );
        contracts[vars.chainId][bytes32(bytes("SuperRBAC"))] = vars.superRBAC;
        vars.superRBACC = SuperRBAC(vars.superRBAC);

        /// @dev 2 - Deploy SuperRegistry
        vars.superRegistry = address(new SuperRegistry{salt: salt}(vars.superRBAC));
        contracts[vars.chainId][bytes32(bytes("SuperRegistry"))] = vars.superRegistry;
        vars.superRegistryC = SuperRegistry(vars.superRegistry);

        vars.superRBACC.setSuperRegistry(vars.superRegistry);
        vars.superRegistryC.setPermit2(CANONICAL_PERMIT2);

        /// @dev 3.1 - deploy Core State Registry
        vars.coreStateRegistry = address(new CoreStateRegistry{salt: salt}(vars.superRegistryC));
        contracts[vars.chainId][bytes32(bytes("CoreStateRegistry"))] = vars.coreStateRegistry;

        vars.superRegistryC.setAddress(vars.superRegistryC.CORE_STATE_REGISTRY(), vars.coreStateRegistry, vars.chainId);

        /// @dev 3.2 - deploy Form State Registry
        vars.twoStepsFormStateRegistry = address(new TimelockStateRegistry{salt: salt}(vars.superRegistryC));
        contracts[vars.chainId][bytes32(bytes("TimelockStateRegistry"))] = vars.twoStepsFormStateRegistry;

        vars.superRegistryC.setAddress(
            vars.superRegistryC.TIMELOCK_STATE_REGISTRY(), vars.twoStepsFormStateRegistry, vars.chainId
        );

        /// @dev 3.3 - deploy Broadcast State Registry
        vars.broadcastRegistry = address(new BroadcastRegistry{salt: salt}(vars.superRegistryC));
        contracts[vars.chainId][bytes32(bytes("BroadcastRegistry"))] = vars.broadcastRegistry;

        vars.superRegistryC.setAddress(vars.superRegistryC.BROADCAST_REGISTRY(), vars.broadcastRegistry, vars.chainId);

        address[] memory registryAddresses = new address[](3);
        registryAddresses[0] = vars.coreStateRegistry;
        registryAddresses[1] = vars.twoStepsFormStateRegistry;
        registryAddresses[2] = vars.broadcastRegistry;

        uint8[] memory registryIds = new uint8[](3);
        registryIds[0] = 1;
        registryIds[1] = 2;
        registryIds[2] = 3;

        vars.superRegistryC.setStateRegistryAddress(registryIds, registryAddresses);

        /// @dev 4- deploy Payment Helper
        vars.paymentHelper = address(new PaymentHelper{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("PaymentHelper"))] = vars.paymentHelper;

        vars.superRegistryC.setAddress(vars.superRegistryC.PAYMENT_HELPER(), vars.paymentHelper, vars.chainId);
        /// @dev 5.1- deploy Layerzero Implementation
        vars.lzImplementation = address(new LayerzeroImplementation{salt: salt}(vars.superRegistryC));
        contracts[vars.chainId][bytes32(bytes("LayerzeroImplementation"))] = vars.lzImplementation;

        LayerzeroImplementation(payable(vars.lzImplementation)).setLzEndpoint(lzEndpoints[trueIndex]);

        /// @dev 5.2- deploy Hyperlane Implementation
        vars.hyperlaneImplementation = address(new HyperlaneImplementation{salt: salt}(vars.superRegistryC));
        HyperlaneImplementation(vars.hyperlaneImplementation).setHyperlaneConfig(
            HyperlaneMailbox, HyperlaneGasPaymaster
        );
        contracts[vars.chainId][bytes32(bytes("HyperlaneImplementation"))] = vars.hyperlaneImplementation;

        /// @dev 5.3- deploy Wormhole Automatic Relayer Implementation
        vars.wormholeImplementation = address(
            new WormholeARImplementation{salt: salt}(
                    vars.superRegistryC
                )
        );
        contracts[vars.chainId][bytes32(bytes("WormholeARImplementation"))] = vars.wormholeImplementation;

        WormholeARImplementation(vars.wormholeImplementation).setWormholeRelayer(wormholeRelayer);

        /// @dev 6.5- deploy Wormhole Specialized Relayer Implementation
        vars.wormholeSRImplementation = address(
            new WormholeSRImplementation{salt: salt}(
                    vars.superRegistryC
                )
        );
        contracts[vars.chainId][bytes32(bytes("WormholeSRImplementation"))] = vars.wormholeSRImplementation;

        WormholeSRImplementation(vars.wormholeSRImplementation).setWormholeCore(wormholeCore[trueIndex]);

        vars.ambAddresses[0] = vars.lzImplementation;
        vars.ambAddresses[1] = vars.hyperlaneImplementation;
        vars.ambAddresses[2] = vars.wormholeImplementation;
        vars.ambAddresses[3] = vars.wormholeSRImplementation;

        /// @dev 6- deploy liquidity validators
        vars.lifiValidator = address(new LiFiValidator{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("LiFiValidator"))] = vars.lifiValidator;

        vars.socketValidator = address(new SocketValidator{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("SocketValidator"))] = vars.socketValidator;

        vars.socketOneInchValidator = address(new SocketOneInchValidator{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("SocketOneInchValidator"))] = vars.socketOneInchValidator;

        bridgeValidators[0] = vars.lifiValidator;
        bridgeValidators[1] = vars.socketValidator;
        bridgeValidators[2] = vars.socketOneInchValidator;

        /// @dev 7 - Deploy SuperformFactory
        vars.factory = address(new SuperformFactory{salt: salt}(vars.superRegistry));

        contracts[vars.chainId][bytes32(bytes("SuperformFactory"))] = vars.factory;

        vars.superRegistryC.setAddress(vars.superRegistryC.SUPERFORM_FACTORY(), vars.factory, vars.chainId);
        vars.superRBACC.grantRole(vars.superRBACC.BROADCASTER_ROLE(), vars.factory);

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

        /// @dev 9 - Add newly deployed form implementations to Factory, formBeaconId 1
        ISuperformFactory(vars.factory).addFormImplementation(vars.erc4626Form, FORM_IMPLEMENTATION_IDS[0]);

        ISuperformFactory(vars.factory).addFormImplementation(vars.erc4626TimelockForm, FORM_IMPLEMENTATION_IDS[1]);

        ISuperformFactory(vars.factory).addFormImplementation(vars.kycDao4626Form, FORM_IMPLEMENTATION_IDS[2]);

        /// @dev 10 - Deploy SuperformRouter
        vars.superformRouter = address(new SuperformRouter{salt: salt}(vars.superRegistry, 1, 1));
        contracts[vars.chainId][bytes32(bytes("SuperformRouter"))] = vars.superformRouter;

        vars.superRegistryC.setAddress(vars.superRegistryC.SUPERFORM_ROUTER(), vars.superformRouter, vars.chainId);

        /// @dev 11 - Deploy SuperPositions
        vars.superPositions =
            address(new SuperPositions{salt: salt}("https://apiv2-dev.superform.xyz/", vars.superRegistry, 1));

        contracts[vars.chainId][bytes32(bytes("SuperPositions"))] = vars.superPositions;
        vars.superRegistryC.setAddress(vars.superRegistryC.SUPER_POSITIONS(), vars.superPositions, vars.chainId);

        contracts[vars.chainId][bytes32(bytes("SuperTransmuter"))] =
            address(new SuperTransmuter{salt: salt}(IERC1155A(vars.superPositions), vars.superRegistry, 2));

        vars.superRegistryC.setAddress(
            vars.superRegistryC.SUPER_TRANSMUTER(),
            contracts[vars.chainId][bytes32(bytes("SuperTransmuter"))],
            vars.chainId
        );

        vars.superRBACC.grantRole(
            vars.superRBACC.BROADCASTER_ROLE(), contracts[vars.chainId][bytes32(bytes("SuperTransmuter"))]
        );

        /// @dev 11.1 Set Router Info

        uint8[] memory superformRouterIds = new uint8[](1);
        superformRouterIds[0] = 1;

        address[] memory stateSyncers = new address[](1);
        stateSyncers[0] = vars.superPositions;

        address[] memory routers = new address[](1);
        routers[0] = vars.superformRouter;

        vars.superRegistryC.setRouterInfo(superformRouterIds, stateSyncers, routers);

        /// @dev 12 - Deploy Payload Helper
        vars.PayloadHelper = address(new PayloadHelper{salt: salt}( vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("PayloadHelper"))] = vars.PayloadHelper;
        vars.superRegistryC.setAddress(vars.superRegistryC.PAYLOAD_HELPER(), vars.PayloadHelper, vars.chainId);

        /// @dev 13 - Deploy PayMaster
        vars.payMaster = address(new PayMaster{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes32("PayMaster"))] = vars.payMaster;

        vars.superRegistryC.setAddress(vars.superRegistryC.PAYMASTER(), vars.payMaster, vars.chainId);

        /// @dev 14 - Deploy Dst Swapper
        vars.dstSwapper = address(new DstSwapper{salt: salt}(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("DstSwapper"))] = vars.dstSwapper;

        vars.superRegistryC.setAddress(vars.superRegistryC.DST_SWAPPER(), vars.dstSwapper, vars.chainId);

        /// @dev 15 - Super Registry extra setters
        vars.superRegistryC.setBridgeAddresses(bridgeIds, BRIDGE_ADDRESSES[vars.chainId], bridgeValidators);

        /// @dev configures lzImplementation and hyperlane to super registry
        SuperRegistry(payable(getContract(vars.chainId, "SuperRegistry"))).setAmbAddress(
            ambIds, vars.ambAddresses, broadcastAMB
        );

        /// @dev 16 setup setup srcChain keepers
        vars.superRegistryC.setAddress(
            vars.superRegistryC.PAYMENT_ADMIN(), 0xD911673eAF0D3e15fe662D58De15511c5509bAbB, vars.chainId
        );
        vars.superRegistryC.setAddress(
            vars.superRegistryC.CORE_REGISTRY_PROCESSOR(), 0x23c658FE050B4eAeB9401768bF5911D11621629c, vars.chainId
        );
        vars.superRegistryC.setAddress(
            vars.superRegistryC.CORE_REGISTRY_UPDATER(), 0xaEbb4b9f7e16BEE2a0963569a5E33eE10E478a5f, vars.chainId
        );
        vars.superRegistryC.setAddress(vars.superRegistryC.BROADCAST_REGISTRY_PROCESSOR(), ownerAddress, vars.chainId);
        vars.superRegistryC.setAddress(vars.superRegistryC.TIMELOCK_REGISTRY_PROCESSOR(), ownerAddress, vars.chainId);
        vars.superRegistryC.setAddress(
            vars.superRegistryC.CORE_REGISTRY_RESCUER(), 0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5, vars.chainId
        );
        vars.superRegistryC.setAddress(vars.superRegistryC.CORE_REGISTRY_DISPUTER(), ownerAddress, vars.chainId);
        vars.superRegistryC.setAddress(
            vars.superRegistryC.DST_SWAPPER_PROCESSOR(), 0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C, vars.chainId
        );

        /// @dev 17 deploy emergency queue
        vars.emergencyQueue = address(new EmergencyQueue(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("EmergencyQueue"))] = vars.emergencyQueue;
        vars.superRegistryC.setAddress(vars.superRegistryC.EMERGENCY_QUEUE(), vars.emergencyQueue, vars.chainId);

        vm.stopBroadcast();

        /// @dev Exports
        for (uint256 j = 0; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }

    /// @dev stage 2 must be called only after stage 1 is complete for all chains!
    function _deployStage2(
        uint256 i,
        /// 0, 1, 2
        uint256 trueIndex,
        /// 0, 1, 2, 3, 4, 5
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
        setEnvDeploy(cycle)
    {
        SetupVars memory vars;

        vars.chainId = s_superFormChainIds[i];
        vm.startBroadcast(deployerPrivateKey);

        vars.lzImplementation = _readContract(chainNames[trueIndex], vars.chainId, "LayerzeroImplementation");
        vars.hyperlaneImplementation = _readContract(chainNames[trueIndex], vars.chainId, "HyperlaneImplementation");
        vars.wormholeImplementation = _readContract(chainNames[trueIndex], vars.chainId, "WormholeARImplementation");
        vars.wormholeSRImplementation = _readContract(chainNames[trueIndex], vars.chainId, "WormholeSRImplementation");
        vars.superRegistry = _readContract(chainNames[trueIndex], vars.chainId, "SuperRegistry");
        vars.paymentHelper = _readContract(chainNames[trueIndex], vars.chainId, "PaymentHelper");
        vars.superRegistryC =
            SuperRegistry(payable(_readContract(chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        /// @dev Set all trusted remotes for each chain & configure amb chains ids
        for (uint256 j = 0; j < s_superFormChainIds.length; j++) {
            if (j != i) {
                uint256 dstTrueIndex;
                for (uint256 k = 0; i < chainIds.length; k++) {
                    if (s_superFormChainIds[j] == chainIds[k]) {
                        dstTrueIndex = k;

                        break;
                    }
                }
                vars.dstChainId = s_superFormChainIds[j];
                vars.dstLzChainId = lz_chainIds[dstTrueIndex];
                vars.dstHypChainId = hyperlane_chainIds[dstTrueIndex];
                vars.dstWormholeChainId = wormhole_chainIds[dstTrueIndex];

                vars.dstLzImplementation =
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "LayerzeroImplementation");
                vars.dstHyperlaneImplementation =
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "HyperlaneImplementation");
                vars.dstWormholeARImplementation =
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "WormholeARImplementation");
                vars.dstWormholeSRImplementation =
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "WormholeSRImplementation");
                LayerzeroImplementation(payable(vars.lzImplementation)).setTrustedRemote(
                    vars.dstLzChainId, abi.encodePacked(vars.dstLzImplementation, vars.lzImplementation)
                );

                LayerzeroImplementation(payable(vars.lzImplementation)).setChainId(vars.dstChainId, vars.dstLzChainId);

                /// @dev for mainnet
                LayerzeroImplementation(payable(vars.lzImplementation)).setConfig(
                    0,
                    /// Defaults To Zero
                    vars.dstLzChainId,
                    6,
                    /// For Oracle Config
                    abi.encode(CHAINLINK_lzOracle)
                );

                HyperlaneImplementation(payable(vars.hyperlaneImplementation)).setReceiver(
                    vars.dstHypChainId, vars.dstHyperlaneImplementation
                );

                HyperlaneImplementation(payable(vars.hyperlaneImplementation)).setChainId(
                    vars.dstChainId, vars.dstHypChainId
                );

                WormholeARImplementation(payable(vars.wormholeImplementation)).setReceiver(
                    vars.dstWormholeChainId, vars.dstWormholeARImplementation
                );

                WormholeARImplementation(payable(vars.wormholeImplementation)).setChainId(
                    vars.dstChainId, vars.dstWormholeChainId
                );

                WormholeSRImplementation(payable(vars.wormholeSRImplementation)).setChainId(
                    vars.dstChainId, vars.dstWormholeChainId
                );

                SuperRegistry(payable(vars.superRegistry)).setRequiredMessagingQuorum(vars.dstChainId, 1);

                /// @dev these values are mocks and has to be replaced
                /// swap gas cost: 50000
                /// update gas cost: 40000
                /// deposit gas cost: 70000
                /// withdraw gas cost: 80000
                /// default gas price: 50 Gwei
                PaymentHelper(payable(vars.paymentHelper)).addChain(
                    vars.dstChainId,
                    IPaymentHelper.PaymentHelperConfig(
                        PRICE_FEEDS[vars.chainId][vars.dstChainId],
                        address(0),
                        40_000,
                        70_000,
                        80_000,
                        12e8,
                        /// 12 usd
                        28 gwei,
                        10 wei,
                        10_000,
                        10_000,
                        50_000
                    )
                );

                vars.superRegistryC.setAddress(
                    vars.superRegistryC.SUPERFORM_ROUTER(),
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "SuperformRouter"),
                    vars.dstChainId
                );

                vars.superRegistryC.setAddress(
                    vars.superRegistryC.SUPERFORM_FACTORY(),
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "SuperformFactory"),
                    vars.dstChainId
                );

                vars.superRegistryC.setAddress(
                    vars.superRegistryC.PAYMASTER(),
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "PayMaster"),
                    vars.dstChainId
                );

                vars.superRegistryC.setAddress(
                    vars.superRegistryC.PAYMENT_HELPER(),
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "PaymentHelper"),
                    vars.dstChainId
                );

                vars.superRegistryC.setAddress(
                    vars.superRegistryC.CORE_STATE_REGISTRY(),
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "CoreStateRegistry"),
                    vars.dstChainId
                );

                vars.superRegistryC.setAddress(
                    vars.superRegistryC.DST_SWAPPER(),
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "DstSwapper"),
                    vars.dstChainId
                );

                vars.superRegistryC.setAddress(
                    vars.superRegistryC.TIMELOCK_STATE_REGISTRY(),
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "TimelockStateRegistry"),
                    vars.dstChainId
                );

                vars.superRegistryC.setAddress(
                    vars.superRegistryC.BROADCAST_REGISTRY(),
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "BroadcastRegistry"),
                    vars.dstChainId
                );

                vars.superRegistryC.setAddress(
                    vars.superRegistryC.SUPER_POSITIONS(),
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "SuperPositions"),
                    vars.dstChainId
                );

                vars.superRegistryC.setAddress(
                    vars.superRegistryC.SUPER_TRANSMUTER(),
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "SuperTransmuter"),
                    vars.dstChainId
                );

                vars.superRegistryC.setAddress(
                    vars.superRegistryC.SUPER_RBAC(),
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "SuperRBAC"),
                    vars.dstChainId
                );

                vars.superRegistryC.setAddress(
                    vars.superRegistryC.PAYLOAD_HELPER(),
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "PayloadHelper"),
                    vars.dstChainId
                );

                vars.superRegistryC.setAddress(
                    vars.superRegistryC.EMERGENCY_QUEUE(),
                    _readContract(chainNames[dstTrueIndex], vars.dstChainId, "EmergencyQueue"),
                    vars.dstChainId
                );

                /// @dev FIXME - in mainnet who is this?
                vars.superRegistryC.setAddress(
                    vars.superRegistryC.PAYMENT_ADMIN(), 0xD911673eAF0D3e15fe662D58De15511c5509bAbB, vars.dstChainId
                );
                vars.superRegistryC.setAddress(
                    vars.superRegistryC.CORE_REGISTRY_PROCESSOR(),
                    0x23c658FE050B4eAeB9401768bF5911D11621629c,
                    vars.dstChainId
                );
                vars.superRegistryC.setAddress(
                    vars.superRegistryC.CORE_REGISTRY_UPDATER(),
                    0xaEbb4b9f7e16BEE2a0963569a5E33eE10E478a5f,
                    vars.dstChainId
                );
                vars.superRegistryC.setAddress(
                    vars.superRegistryC.BROADCAST_REGISTRY_PROCESSOR(), ownerAddress, vars.dstChainId
                );
                vars.superRegistryC.setAddress(
                    vars.superRegistryC.TIMELOCK_REGISTRY_PROCESSOR(), ownerAddress, vars.dstChainId
                );

                vars.superRegistryC.setAddress(
                    vars.superRegistryC.CORE_REGISTRY_RESCUER(),
                    0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5,
                    vars.dstChainId
                );
                vars.superRegistryC.setAddress(
                    vars.superRegistryC.CORE_REGISTRY_DISPUTER(), ownerAddress, vars.dstChainId
                );
                vars.superRegistryC.setAddress(
                    vars.superRegistryC.DST_SWAPPER_PROCESSOR(),
                    0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C,
                    vars.dstChainId
                );
            } else {
                /// ack gas cost: 40000
                /// two step form cost: 50000
                /// default gas price: 50 Gwei
                PaymentHelper(payable(vars.paymentHelper)).updateChainConfig(
                    vars.chainId, 1, abi.encode(PRICE_FEEDS[vars.chainId][vars.chainId])
                );
                PaymentHelper(payable(vars.paymentHelper)).updateChainConfig(vars.chainId, 9, abi.encode(40_000));
                PaymentHelper(payable(vars.paymentHelper)).updateChainConfig(vars.chainId, 10, abi.encode(50_000));
                PaymentHelper(payable(vars.paymentHelper)).updateChainConfig(
                    vars.chainId, 7, abi.encode(50 * 10 ** 9 wei)
                );
            }
        }
        vm.stopBroadcast();
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

        mapping(uint64 chainId => address[] bridgeAddresses) storage bridgeAddresses = BRIDGE_ADDRESSES;
        bridgeAddresses[ETH] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0,
            0x2ddf16BA6d0180e5357d5e170eF1917a01b41fc0
        ];
        bridgeAddresses[BSC] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0,
            0xd286595d2e3D879596FAB51f83A702D10a6db27b
        ];
        bridgeAddresses[AVAX] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0x2b42AFFD4b7C14d9B7C2579229495c052672Ccd3,
            0xbDf50eAe568ECef74796ed6022a0d453e8432410
        ];
        bridgeAddresses[POLY] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0,
            0x2ddf16BA6d0180e5357d5e170eF1917a01b41fc0
        ];
        bridgeAddresses[ARBI] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0,
            0xaa3d9fA3aB930aE635b001d00C612aa5b14d750e
        ];
        bridgeAddresses[OP] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0,
            0xbDf50eAe568ECef74796ed6022a0d453e8432410
        ];
        bridgeAddresses[FTM] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0,
            0x957301825Dc21d4A92919C9E72dC9E6C6a29e7f8
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

    function _exportContract(string memory name, string memory label, address addr, uint64 chainId) internal {
        string memory json = vm.serializeAddress("EXPORTS", label, addr);
        string memory root = vm.projectRoot();

        string memory chainOutputFolder =
            string(abi.encodePacked("/script/output/", vm.toString(uint256(chainId)), "/"));

        if (vm.envOr("FOUNDRY_EXPORTS_OVERWRITE_LATEST", false)) {
            vm.writeJson(json, string(abi.encodePacked(root, chainOutputFolder, name, "-latest.json")));
        } else {
            vm.writeJson(
                json,
                string(abi.encodePacked(root, chainOutputFolder, name, "-", vm.toString(block.timestamp), ".json"))
            );
        }
    }

    function _readContract(
        string memory name,
        uint64 chainId,
        string memory contractName
    )
        internal
        view
        returns (address)
    {
        string memory json;
        string memory root = vm.projectRoot();
        json =
            string(abi.encodePacked(root, "/script/output/", vm.toString(uint256(chainId)), "/", name, "-latest.json"));
        string memory file = vm.readFile(json);
        return vm.parseJsonAddress(file, string(abi.encodePacked(".", contractName)));
    }

    function _deployWithCreate2(bytes memory bytecode_, uint256 salt_) internal returns (address addr) {
        assembly {
            addr := create2(0, add(bytecode_, 0x20), mload(bytecode_), salt_)

            if iszero(extcodesize(addr)) { revert(0, 0) }
        }

        return addr;
    }
}

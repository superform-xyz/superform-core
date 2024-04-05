// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { Script } from "forge-std/Script.sol";
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
import { EmergencyQueue } from "src/EmergencyQueue.sol";
import { VaultClaimer } from "src/VaultClaimer.sol";
import { generateBroadcastParams } from "test/utils/AmbParams.sol";

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
    address timelockStateRegistry;
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
    bytes32[] ids;
    address[] newAddresses;
    uint64[] chainIdsSetAddresses;
}

abstract contract AbstractDeploySingle is Script {
    /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public constant CANONICAL_PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    mapping(uint64 chainId => mapping(bytes32 implementation => address at)) public contracts;

    string[21] public contractNames = [
        "CoreStateRegistry",
        //"TimelockStateRegistry",
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
        //"ERC4626TimelockForm",
        //"ERC4626KYCDaoForm",
        "SuperformRouter",
        "SuperPositions",
        "SuperRegistry",
        "SuperRBAC",
        "PayloadHelper",
        "PaymentHelper",
        "PayMaster",
        "EmergencyQueue",
        "VaultClaimer"
    ];

    enum Chains {
        Ethereum,
        Polygon,
        Bsc,
        Avalanche,
        Arbitrum,
        Optimism,
        Base,
        Fantom,
        Ethereum_Fork,
        Polygon_Fork,
        Bsc_Fork,
        Avalanche_Fork,
        Arbitrum_Fork,
        Optimism_Fork,
        Base_Fork,
        Fantom_Fork
    }

    enum Cycle {
        Dev,
        Prod
    }

    /// @dev Mapping of chain enum to rpc url
    mapping(Chains chains => string rpcUrls) public forks;

    /*//////////////////////////////////////////////////////////////
                        PROTOCOL VARIABLES
    //////////////////////////////////////////////////////////////*/
    string public SUPER_POSITIONS_NAME;

    /// @dev 1 = ERC4626Form, 2 = ERC4626TimelockForm, 3 = KYCDaoForm
    uint32[] public FORM_IMPLEMENTATION_IDS = [uint32(1), uint32(2), uint32(3)];
    string[] public VAULT_KINDS = ["Vault", "TimelockedVault", "KYCDaoVault"];

    /// @dev liquidity bridge ids 101 is lifi v2, 2 is socket, 3 is socket one inch implementation
    uint8[] public bridgeIds = [101, 2, 3];

    mapping(uint64 chainId => address[] bridgeAddresses) public BRIDGE_ADDRESSES;

    /// @dev setup amb bridges
    /// @notice id 1 is layerzero
    /// @notice id 2 is hyperlane
    /// @notice id 3 is wormhole AR
    /// @notice id 4 is wormhole SR
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
    address public constant BASE_lzEndpoint = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;
    address public constant FANTOM_lzEndpoint = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;

    address public constant CHAINLINK_lzOracle = 0x150A58e9E6BF69ccEb1DBA5ae97C166DC8792539;

    address[] public lzEndpoints = [
        0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7,
        0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7
    ];

    address[] public hyperlaneMailboxes = [
        0xc005dc82818d67AF737725bD4bf75435d065D239,
        0x2971b9Aec44bE4eb673DF1B88cDB57b96eefe8a4,
        0xFf06aFcaABaDDd1fb08371f9ccA15D73D51FeBD6,
        0x5d934f4e2f797775e53561bB72aca21ba36B96BB,
        0x979Ca5202784112f4738403dBec5D0F3B9daabB9,
        0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D,
        0xeA87ae93Fa0019a82A727bfd3eBd1cFCa8f64f1D,
        address(0)
    ];

    address[] public hyperlanePaymasters = [
        0x9e6B1022bE9BBF5aFd152483DAD9b88911bC8611,
        0x78E25e7f84416e69b9339B0A6336EB6EFfF6b451,
        0x95519ba800BBd0d34eeAE026fEc620AD978176C0,
        0x0071740Bf129b05C4684abfbBeD248D80971cce2,
        0x3b6044acd6767f017e99318AA6Ef93b7B06A5a22,
        0xD8A76C4D91fCbB7Cc8eA795DFDF870E48368995C,
        0xc3F23848Ed2e04C0c6d41bd7804fa8f89F940B94,
        address(0)
    ];

    address[] public wormholeCore = [
        0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B,
        0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B,
        0x54a8e5f9c4CbA08F9943965859F6c34eAF03E26c,
        0x7A4B5a56256163F07b2C80A7cA55aBE66c4ec4d7,
        0xa5f208e072434bC67592E4C49C1B991BA79BCA46,
        0xEe91C335eab126dF5fDB3797EA9d6aD93aeC9722,
        0xbebdb6C8ddC678FfA9f8748f85C815C556Dd8ac6,
        0x126783A6Cb203a3E35344528B26ca3a0489a1485
    ];

    /// @dev uses CREATE2
    address public wormholeRelayer = 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911;
    address public wormholeBaseRelayer = 0x706F82e9bb5b0813501714Ab5974216704980e31;

    /// @dev superformChainIds
    uint64 public constant ETH = 1;
    uint64 public constant BSC = 56;
    uint64 public constant AVAX = 43_114;
    uint64 public constant POLY = 137;
    uint64 public constant ARBI = 42_161;
    uint64 public constant OP = 10;
    uint64 public constant BASE = 8453;
    uint64 public constant FANTOM = 250;

    uint64[] public chainIds = [1, 56, 43_114, 137, 42_161, 10, 8453, 250];
    string[] public chainNames =
        ["Ethereum", "Binance", "Avalanche", "Polygon", "Arbitrum", "Optimism", "Base", "Fantom"];

    /// @dev vendor chain ids
    uint16[] public lz_chainIds = [101, 102, 106, 109, 110, 111, 184, 112];
    uint32[] public hyperlane_chainIds = [1, 56, 43_114, 137, 42_161, 10, 8453, 250];
    uint16[] public wormhole_chainIds = [2, 4, 6, 5, 23, 24, 30, 10];

    uint256 public constant milionTokensE18 = 1 ether;

    mapping(uint64 => mapping(uint256 => bytes)) public GAS_USED;

    /// @dev !WARNING: update these for Fantom
    /// @dev check https://api-utils.superform.xyz/docs#/Utils/get_gas_prices_gwei_gas_get
    uint256[] public gasPrices = [
        50_000_000_000, // ETH
        3_000_000_000, // BSC
        25_000_000_000, // AVAX
        50_000_000_000, // POLY
        100_000_000, // ARBI
        4_000_000, // OP
        1_000_000, // BASE
        4 * 10e9 // FANTOM
    ];

    /// @dev !WARNING: update these for Fantom
    /// @dev check https://api-utils.superform.xyz/docs#/Utils/get_native_prices_chainlink_native_get
    uint256[] public nativePrices = [
        253_400_000_000, // ETH
        31_439_000_000, // BSC
        3_529_999_999, // AVAX
        81_216_600, // POLY
        253_400_000_000, // ARBI
        253_400_000_000, // OP
        253_400_000_000, // BASE
        4 * 10e9 // FANTOM
    ];

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

    /*//////////////////////////////////////////////////////////////
                        RBAC VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public deployerPrivateKey;

    address public ownerAddress;

    address public PAYMENT_ADMIN;
    address public CSR_PROCESSOR;
    address public CSR_UPDATER;
    address public DST_SWAPPER;
    address public CSR_RESCUER;
    address public CSR_DISPUTER;
    address public SUPERFORM_RECEIVER;
    address public EMERGENCY_ADMIN;
    address public BROADCAST_REGISTRY_PROCESSOR;
    address public WORMHOLE_VAA_RELAYER;

    address[] public PROTOCOL_ADMINS = [
        0xd26b38a64C812403fD3F87717624C80852cD6D61,
        /// @dev ETH https://app.onchainden.com/safes/eth:0xd26b38a64c812403fd3f87717624c80852cd6d61
        0xf70A19b67ACC4169cA6136728016E04931D550ae,
        /// @dev BSC https://app.onchainden.com/safes/bnb:0xf70a19b67acc4169ca6136728016e04931d550ae
        0x79DD9868A1a89720981bF077A02a4A43c57080d2,
        /// @dev AVAX https://app.onchainden.com/safes/avax:0x79dd9868a1a89720981bf077a02a4a43c57080d2
        0x5022b05721025159c82E02abCb0Daa87e357f437,
        /// @dev POLY https://app.onchainden.com/safes/matic:0x5022b05721025159c82e02abcb0daa87e357f437
        0x7Fc07cAFb65d1552849BcF151F7035C5210B76f4,
        /// @dev ARBI https://app.onchainden.com/safes/arb1:0x7fc07cafb65d1552849bcf151f7035c5210b76f4
        0x99620a926D68746D5F085B3f7cD62F4fFB71f0C1,
        /// @dev OP https://app.onchainden.com/safes/oeth:0x99620a926d68746d5f085b3f7cd62f4ffb71f0c1
        0x2F973806f8863E860A553d4F2E7c2AB4A9F3b87C,
        /// @dev BASE https://app.onchainden.com/safes/base:0x2f973806f8863e860a553d4f2e7c2ab4a9f3b87c
        address(0)
        /// @dev FANTOM FIXME - PROTOCOL ADMIN NOT SET FOR FANTOM
    ];

    address[] public PROTOCOL_ADMINS_STAGING = [
        0xBbb23AE2e3816a178f8bd405fb101D064C5071d9,
        /// @dev BSC https://app.onchainden.com/safes/bnb:0xBbb23AE2e3816a178f8bd405fb101D064C5071d9
        0xBbb23AE2e3816a178f8bd405fb101D064C5071d9,
        /// @dev ARBI https://app.onchainden.com/safes/arb1:0xBbb23AE2e3816a178f8bd405fb101D064C5071d9
        0xfe3A0C3c4980Eef00C2Ec73D8770a2D9A489fdE5,
        /// @dev OP https://app.onchainden.com/safes/oeth:0xfe3A0C3c4980Eef00C2Ec73D8770a2D9A489fdE5
        0xbd1F951F52FC7616E2F743F976295fDc5276Cfb9
        /// @dev BASE https://app.onchainden.com/safes/base:0xbd1F951F52FC7616E2F743F976295fDc5276Cfb9
    ];

    /// @dev environment variable setup for upgrade
    /// @param cycle deployment cycle (dev, prod)
    modifier setEnvDeploy(Cycle cycle) {
        if (cycle == Cycle.Dev) {
            (ownerAddress, deployerPrivateKey) = makeAddrAndKey("tenderly");
        } else {
            //deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
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
        forks[Chains.Base] = "base";
        forks[Chains.Fantom] = "fantom";

        // Mainnet Forks
        forks[Chains.Ethereum_Fork] = "ethereum_fork";
        forks[Chains.Polygon_Fork] = "polygon_fork";
        forks[Chains.Bsc_Fork] = "bsc_fork";
        forks[Chains.Avalanche_Fork] = "avalanche_fork";
        forks[Chains.Arbitrum_Fork] = "arbitrum_fork";
        forks[Chains.Optimism_Fork] = "optimism_fork";
        forks[Chains.Base_Fork] = "base_fork";
        forks[Chains.Fantom_Fork] = "fantom_fork";
    }

    function getContract(uint64 chainId, string memory _name) public view returns (address) {
        return contracts[chainId][bytes32(bytes(_name))];
    }

    function _deployStage1(
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory targetDeploymentChains,
        bytes32 salt
    )
        internal
        setEnvDeploy(cycle)
    {
        SetupVars memory vars;
        /// @dev liquidity validator addresses
        address[] memory bridgeValidators = new address[](bridgeIds.length);

        vars.chainId = targetDeploymentChains[i];

        vars.ambAddresses = new address[](ambIds.length);

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        /// @dev 1 - Deploy SuperRBAC
        vars.superRBAC = address(
            new SuperRBAC{ salt: salt }(
                ISuperRBAC.InitialRoleSetup({
                    admin: ownerAddress,
                    emergencyAdmin: ownerAddress,
                    paymentAdmin: PAYMENT_ADMIN,
                    csrProcessor: CSR_PROCESSOR,
                    tlProcessor: EMERGENCY_ADMIN,
                    /// @dev Temporary, as we are not using this processor in this release
                    brProcessor: BROADCAST_REGISTRY_PROCESSOR,
                    csrUpdater: CSR_UPDATER,
                    srcVaaRelayer: WORMHOLE_VAA_RELAYER,
                    dstSwapper: DST_SWAPPER,
                    csrRescuer: CSR_RESCUER,
                    csrDisputer: CSR_DISPUTER
                })
            )
        );

        contracts[vars.chainId][bytes32(bytes("SuperRBAC"))] = vars.superRBAC;
        vars.superRBACC = SuperRBAC(vars.superRBAC);

        /// @dev 2 - Deploy SuperRegistry
        vars.superRegistry = address(new SuperRegistry{ salt: salt }(vars.superRBAC));
        contracts[vars.chainId][bytes32(bytes("SuperRegistry"))] = vars.superRegistry;
        vars.superRegistryC = SuperRegistry(vars.superRegistry);

        vars.superRBACC.setSuperRegistry(vars.superRegistry);
        vars.superRegistryC.setPermit2(CANONICAL_PERMIT2);

        /// @dev sets max number of vaults per destination
        vars.superRegistryC.setVaultLimitPerDestination(vars.chainId, 5);

        /// @dev 3.1 - deploy Core State Registry
        vars.coreStateRegistry = address(new CoreStateRegistry{ salt: salt }(vars.superRegistryC));
        contracts[vars.chainId][bytes32(bytes("CoreStateRegistry"))] = vars.coreStateRegistry;

        vars.superRegistryC.setAddress(vars.superRegistryC.CORE_STATE_REGISTRY(), vars.coreStateRegistry, vars.chainId);

        /*
        /// @dev 3.2 - deploy Timelock State Registry
        vars.timelockStateRegistry = address(new TimelockStateRegistry{ salt: salt }(vars.superRegistryC));
        contracts[vars.chainId][bytes32(bytes("TimelockStateRegistry"))] = vars.timelockStateRegistry;
        

        vars.superRegistryC.setAddress(
            vars.superRegistryC.TIMELOCK_STATE_REGISTRY(), vars.timelockStateRegistry, vars.chainId
        );
        */

        /// @dev 3.3 - deploy Broadcast State Registry
        vars.broadcastRegistry = address(new BroadcastRegistry{ salt: salt }(vars.superRegistryC));
        contracts[vars.chainId][bytes32(bytes("BroadcastRegistry"))] = vars.broadcastRegistry;

        address[] memory registryAddresses = new address[](2);
        registryAddresses[0] = vars.coreStateRegistry;
        registryAddresses[1] = vars.broadcastRegistry;

        uint8 brRegistryId = 2;
        uint8[] memory registryIds = new uint8[](2);
        registryIds[0] = 1;
        registryIds[1] = brRegistryId;

        vars.superRegistryC.setStateRegistryAddress(registryIds, registryAddresses);

        /// @dev 4- deploy Payment Helper
        vars.paymentHelper = address(new PaymentHelper{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("PaymentHelper"))] = vars.paymentHelper;

        vars.superRegistryC.setAddress(vars.superRegistryC.PAYMENT_HELPER(), vars.paymentHelper, vars.chainId);

        /// @dev 5.1- deploy Layerzero Implementation
        vars.lzImplementation = address(new LayerzeroImplementation{ salt: salt }(vars.superRegistryC));
        contracts[vars.chainId][bytes32(bytes("LayerzeroImplementation"))] = vars.lzImplementation;

        LayerzeroImplementation(payable(vars.lzImplementation)).setLzEndpoint(lzEndpoints[trueIndex]);

        /// @dev 5.2- deploy Hyperlane Implementation
        vars.hyperlaneImplementation = address(new HyperlaneImplementation{ salt: salt }(vars.superRegistryC));
        HyperlaneImplementation(vars.hyperlaneImplementation).setHyperlaneConfig(
            IMailbox(hyperlaneMailboxes[trueIndex]), IInterchainGasPaymaster(hyperlanePaymasters[trueIndex])
        );
        contracts[vars.chainId][bytes32(bytes("HyperlaneImplementation"))] = vars.hyperlaneImplementation;

        /// @dev 5.3- deploy Wormhole Automatic Relayer Implementation
        vars.wormholeImplementation = address(new WormholeARImplementation{ salt: salt }(vars.superRegistryC));
        contracts[vars.chainId][bytes32(bytes("WormholeARImplementation"))] = vars.wormholeImplementation;

        address wormholeRelayerConfig = vars.chainId == BASE ? wormholeBaseRelayer : wormholeRelayer;
        WormholeARImplementation(vars.wormholeImplementation).setWormholeRelayer(wormholeRelayerConfig);
        WormholeARImplementation(vars.wormholeImplementation).setRefundChainId(wormhole_chainIds[trueIndex]);

        /// @dev 6.5- deploy Wormhole Specialized Relayer Implementation
        vars.wormholeSRImplementation =
            address(new WormholeSRImplementation{ salt: salt }(vars.superRegistryC, brRegistryId));
        contracts[vars.chainId][bytes32(bytes("WormholeSRImplementation"))] = vars.wormholeSRImplementation;

        WormholeSRImplementation(vars.wormholeSRImplementation).setWormholeCore(wormholeCore[trueIndex]);
        /// @dev FIXME who is the wormhole relayer on mainnet?
        WormholeSRImplementation(vars.wormholeSRImplementation).setRelayer(ownerAddress);

        vars.ambAddresses[0] = vars.lzImplementation;
        vars.ambAddresses[1] = vars.hyperlaneImplementation;
        vars.ambAddresses[2] = vars.wormholeImplementation;
        vars.ambAddresses[3] = vars.wormholeSRImplementation;

        /// @dev 6- deploy liquidity validators
        vars.lifiValidator = address(new LiFiValidator{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("LiFiValidator"))] = vars.lifiValidator;

        vars.socketValidator = address(new SocketValidator{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("SocketValidator"))] = vars.socketValidator;
        if (vars.chainId == 1) {
            // Mainnet Hop
            SocketValidator(vars.socketValidator).addToBlacklist(18);
        } else if (vars.chainId == 10) {
            // Optimism Hop
            SocketValidator(vars.socketValidator).addToBlacklist(15);
        } else if (vars.chainId == 42_161) {
            // Arbitrum hop
            SocketValidator(vars.socketValidator).addToBlacklist(16);
        } else if (vars.chainId == 137) {
            // Polygon hop
            SocketValidator(vars.socketValidator).addToBlacklist(21);
        } else if (vars.chainId == 8453) {
            // Base hop
            SocketValidator(vars.socketValidator).addToBlacklist(1);
        }

        vars.socketOneInchValidator = address(new SocketOneInchValidator{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("SocketOneInchValidator"))] = vars.socketOneInchValidator;

        bridgeValidators[0] = vars.lifiValidator;
        bridgeValidators[1] = vars.socketValidator;
        bridgeValidators[2] = vars.socketOneInchValidator;

        /// @dev 7 - Deploy SuperformFactory
        vars.factory = address(new SuperformFactory{ salt: salt }(vars.superRegistry));

        contracts[vars.chainId][bytes32(bytes("SuperformFactory"))] = vars.factory;

        /// @dev FIXME does SuperRBAC itself need broadcaster role?
        vars.superRegistryC.setAddress(vars.superRegistryC.SUPERFORM_FACTORY(), vars.factory, vars.chainId);
        vars.superRBACC.grantRole(vars.superRBACC.BROADCASTER_ROLE(), vars.factory);

        /// @dev 8 - Deploy 4626Form implementations
        // Standard ERC4626 Form
        vars.erc4626Form = address(new ERC4626Form{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("ERC4626Form"))] = vars.erc4626Form;

        // Timelock + ERC4626 Form
        //vars.erc4626TimelockForm = address(new ERC4626TimelockForm{ salt: salt }(vars.superRegistry));
        //contracts[vars.chainId][bytes32(bytes("ERC4626TimelockForm"))] = vars.erc4626TimelockForm;

        /// 9 KYCDao ERC4626 Form
        //vars.kycDao4626Form = address(new ERC4626KYCDaoForm{ salt: salt }(vars.superRegistry));
        //contracts[vars.chainId][bytes32(bytes("ERC4626KYCDaoForm"))] = vars.kycDao4626Form;

        /// @dev 9 - Add newly deployed form implementations to Factory, formImplementationId 1
        ISuperformFactory(vars.factory).addFormImplementation(vars.erc4626Form, FORM_IMPLEMENTATION_IDS[0], 1);

        /// passing 2 because timelock state registry id is 2
        //ISuperformFactory(vars.factory).addFormImplementation(vars.erc4626TimelockForm, FORM_IMPLEMENTATION_IDS[1],
        // 2);

        //ISuperformFactory(vars.factory).addFormImplementation(vars.kycDao4626Form, FORM_IMPLEMENTATION_IDS[2], 1);

        /// @dev 10 - Deploy SuperformRouter
        vars.superformRouter = address(new SuperformRouter{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("SuperformRouter"))] = vars.superformRouter;

        vars.superRegistryC.setAddress(vars.superRegistryC.SUPERFORM_ROUTER(), vars.superformRouter, vars.chainId);

        /// @dev 11 - Deploy SuperPositions
        vars.superPositions = address(
            new SuperPositions{ salt: salt }(
                "https://ipfs-gateway.superform.xyz/ipns/k51qzi5uqu5dg90fqdo9j63m556wlddeux4mlgyythp30zousgh3huhyzouyq8/JSON/",
                vars.superRegistry,
                SUPER_POSITIONS_NAME,
                "SP"
            )
        );

        contracts[vars.chainId][bytes32(bytes("SuperPositions"))] = vars.superPositions;
        vars.superRegistryC.setAddress(vars.superRegistryC.SUPER_POSITIONS(), vars.superPositions, vars.chainId);

        /// @dev FIXME does SuperRBAC itself need broadcaster role?
        vars.superRBACC.grantRole(
            vars.superRBACC.BROADCASTER_ROLE(), contracts[vars.chainId][bytes32(bytes("SuperPositions"))]
        );

        /// @dev 12 - Deploy Payload Helper
        vars.PayloadHelper = address(new PayloadHelper{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("PayloadHelper"))] = vars.PayloadHelper;
        vars.superRegistryC.setAddress(vars.superRegistryC.PAYLOAD_HELPER(), vars.PayloadHelper, vars.chainId);

        /// @dev 13 - Deploy PayMaster
        vars.payMaster = address(new PayMaster{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes32("PayMaster"))] = vars.payMaster;

        vars.superRegistryC.setAddress(vars.superRegistryC.PAYMASTER(), vars.payMaster, vars.chainId);

        /// @dev 14 - Deploy Dst Swapper
        vars.dstSwapper = address(new DstSwapper{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("DstSwapper"))] = vars.dstSwapper;

        vars.superRegistryC.setAddress(vars.superRegistryC.DST_SWAPPER(), vars.dstSwapper, vars.chainId);

        /// @dev BASE does not have SocketV1 available
        if (vars.chainId == BASE) {
            uint8[] memory bridgeIdsBase = new uint8[](1);
            /// @dev this is the new id of lifi validator
            bridgeIdsBase[0] = 101;

            address[] memory bridgeAddressesBase = new address[](1);
            bridgeAddressesBase[0] = BRIDGE_ADDRESSES[vars.chainId][0];

            address[] memory bridgeValidatorsBase = new address[](1);
            bridgeValidatorsBase[0] = bridgeValidators[0];
            /// @dev 15 - Super Registry extra setters
            vars.superRegistryC.setBridgeAddresses(bridgeIdsBase, bridgeAddressesBase, bridgeValidatorsBase);
        } else {
            /// @dev 15 - Super Registry extra setters
            vars.superRegistryC.setBridgeAddresses(bridgeIds, BRIDGE_ADDRESSES[vars.chainId], bridgeValidators);
        }

        /// @dev configures lzImplementation and hyperlane to super registry
        SuperRegistry(payable(getContract(vars.chainId, "SuperRegistry"))).setAmbAddress(
            ambIds, vars.ambAddresses, broadcastAMB
        );

        /// @dev 16 setup setup srcChain keepers
        vars.ids = new bytes32[](10);

        vars.ids[0] = vars.superRegistryC.PAYMENT_ADMIN();
        vars.ids[1] = vars.superRegistryC.CORE_REGISTRY_PROCESSOR();
        vars.ids[2] = vars.superRegistryC.BROADCAST_REGISTRY_PROCESSOR();
        vars.ids[3] = vars.superRegistryC.TIMELOCK_REGISTRY_PROCESSOR();
        vars.ids[4] = vars.superRegistryC.CORE_REGISTRY_UPDATER();
        vars.ids[5] = vars.superRegistryC.CORE_REGISTRY_RESCUER();
        vars.ids[6] = vars.superRegistryC.CORE_REGISTRY_DISPUTER();
        vars.ids[7] = vars.superRegistryC.DST_SWAPPER_PROCESSOR();
        vars.ids[8] = vars.superRegistryC.SUPERFORM_RECEIVER();
        vars.ids[9] = vars.superRegistryC.BROADCAST_REGISTRY();

        vars.newAddresses = new address[](10);
        vars.newAddresses[0] = PAYMENT_ADMIN;
        vars.newAddresses[1] = CSR_PROCESSOR;
        vars.newAddresses[2] = BROADCAST_REGISTRY_PROCESSOR;
        vars.newAddresses[3] = EMERGENCY_ADMIN;
        vars.newAddresses[4] = CSR_UPDATER;
        vars.newAddresses[5] = CSR_RESCUER;
        vars.newAddresses[6] = CSR_DISPUTER;
        vars.newAddresses[7] = DST_SWAPPER;
        vars.newAddresses[8] = SUPERFORM_RECEIVER;
        vars.newAddresses[9] = vars.broadcastRegistry;

        vars.chainIdsSetAddresses = new uint64[](10);
        vars.chainIdsSetAddresses[0] = vars.chainId;
        vars.chainIdsSetAddresses[1] = vars.chainId;
        vars.chainIdsSetAddresses[2] = vars.chainId;
        vars.chainIdsSetAddresses[3] = vars.chainId;
        vars.chainIdsSetAddresses[4] = vars.chainId;
        vars.chainIdsSetAddresses[5] = vars.chainId;
        vars.chainIdsSetAddresses[6] = vars.chainId;
        vars.chainIdsSetAddresses[7] = vars.chainId;
        vars.chainIdsSetAddresses[8] = vars.chainId;
        vars.chainIdsSetAddresses[9] = vars.chainId;

        vars.superRegistryC.batchSetAddress(vars.ids, vars.newAddresses, vars.chainIdsSetAddresses);

        vars.superRegistryC.setDelay(14_400);

        /// @dev 17 deploy emergency queue
        vars.emergencyQueue = address(new EmergencyQueue{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("EmergencyQueue"))] = vars.emergencyQueue;
        vars.superRegistryC.setAddress(vars.superRegistryC.EMERGENCY_QUEUE(), vars.emergencyQueue, vars.chainId);

        /// @dev 18 configure payment helper
        PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(
            vars.chainId, 1, abi.encode(PRICE_FEEDS[vars.chainId][vars.chainId])
        );
        PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(
            vars.chainId, 7, abi.encode(nativePrices[trueIndex])
        );

        PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(vars.chainId, 8, abi.encode(gasPrices[trueIndex]));

        /// @dev gas per byte
        PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(vars.chainId, 9, abi.encode(750));

        /// @dev ackGasCost to mint superPositions
        PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(
            vars.chainId, 10, abi.encode(vars.chainId == ARBI ? 500_000 : 150_000)
        );

        PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(vars.chainId, 11, abi.encode(50_000));

        PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(vars.chainId, 12, abi.encode(10_000));

        /// @dev 19 deploy vault claimer
        contracts[vars.chainId][bytes32(bytes("VaultClaimer"))] = address(new VaultClaimer{ salt: salt }());

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
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory targetDeploymentChains,
        uint64[] memory finalDeployedChains
    )
        internal
        setEnvDeploy(cycle)
    {
        SetupVars memory vars;
        // j = 0
        //
        vars.chainId = targetDeploymentChains[i];

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        vars.lzImplementation = _readContract(chainNames[trueIndex], vars.chainId, "LayerzeroImplementation");
        vars.hyperlaneImplementation = _readContract(chainNames[trueIndex], vars.chainId, "HyperlaneImplementation");
        vars.wormholeImplementation = _readContract(chainNames[trueIndex], vars.chainId, "WormholeARImplementation");
        vars.wormholeSRImplementation = _readContract(chainNames[trueIndex], vars.chainId, "WormholeSRImplementation");
        vars.superRegistry = _readContract(chainNames[trueIndex], vars.chainId, "SuperRegistry");
        vars.paymentHelper = _readContract(chainNames[trueIndex], vars.chainId, "PaymentHelper");
        vars.superRegistryC = SuperRegistry(vars.superRegistry);

        /// @dev Set all trusted remotes for each chain & configure amb chains ids
        for (uint256 j = 0; j < finalDeployedChains.length; j++) {
            if (j != i) {
                _configureCurrentChainBasedOnTargetDestinations(
                    CurrentChainBasedOnDstvars(
                        vars.chainId,
                        finalDeployedChains[j],
                        0,
                        0,
                        0,
                        0,
                        vars.lzImplementation,
                        vars.hyperlaneImplementation,
                        vars.wormholeImplementation,
                        vars.wormholeSRImplementation,
                        vars.superRegistry,
                        vars.paymentHelper,
                        address(0),
                        address(0),
                        address(0),
                        address(0),
                        vars.superRegistryC
                    )
                );
            }
        }
        vm.stopBroadcast();
    }

    /// @dev pass roles from burner wallets to multi sigs
    function _deployStage3(
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds,
        bool grantProtocolAdmin
    )
        internal
        setEnvDeploy(cycle)
    {
        SetupVars memory vars;

        vars.chainId = s_superFormChainIds[i];

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        SuperRBAC srbac = SuperRBAC(payable(_readContract(chainNames[trueIndex], vars.chainId, "SuperRBAC")));
        bytes32 protocolAdminRole = srbac.PROTOCOL_ADMIN_ROLE();
        bytes32 emergencyAdminRole = srbac.EMERGENCY_ADMIN_ROLE();

        if (grantProtocolAdmin) srbac.grantRole(protocolAdminRole, PROTOCOL_ADMINS[trueIndex]);

        srbac.grantRole(emergencyAdminRole, EMERGENCY_ADMIN);

        srbac.revokeRole(emergencyAdminRole, ownerAddress);
        srbac.revokeRole(protocolAdminRole, ownerAddress);

        vm.stopBroadcast();
    }

    /// @dev changes the settings in the already deployed chains with the new chain information
    function _configurePreviouslyDeployedChainsWithNewChain(
        uint256 i,
        /// 0, 1, 2
        uint256 trueIndex,
        /// 0, 1, 2, 3, 4, 5
        Cycle cycle,
        uint64[] memory previousDeploymentChains,
        uint64 newChainId
    )
        internal
        setEnvDeploy(cycle)
    {
        SetupVars memory vars;

        vars.chainId = previousDeploymentChains[i];

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        vars.lzImplementation = _readContract(chainNames[trueIndex], vars.chainId, "LayerzeroImplementation");
        vars.hyperlaneImplementation = _readContract(chainNames[trueIndex], vars.chainId, "HyperlaneImplementation");
        vars.wormholeImplementation = _readContract(chainNames[trueIndex], vars.chainId, "WormholeARImplementation");
        vars.wormholeSRImplementation = _readContract(chainNames[trueIndex], vars.chainId, "WormholeSRImplementation");
        vars.superRegistry = _readContract(chainNames[trueIndex], vars.chainId, "SuperRegistry");
        vars.paymentHelper = _readContract(chainNames[trueIndex], vars.chainId, "PaymentHelper");
        vars.superRegistryC = SuperRegistry(payable(vars.superRegistry));

        _configureCurrentChainBasedOnTargetDestinations(
            CurrentChainBasedOnDstvars(
                vars.chainId,
                newChainId,
                0,
                0,
                0,
                0,
                vars.lzImplementation,
                vars.hyperlaneImplementation,
                vars.wormholeImplementation,
                vars.wormholeSRImplementation,
                vars.superRegistry,
                vars.paymentHelper,
                address(0),
                address(0),
                address(0),
                address(0),
                vars.superRegistryC
            )
        );

        vm.stopBroadcast();
    }

    struct CurrentChainBasedOnDstvars {
        uint64 chainId;
        uint64 dstChainId;
        uint256 dstTrueIndex;
        uint16 dstLzChainId;
        uint32 dstHypChainId;
        uint16 dstWormholeChainId;
        address lzImplementation;
        address hyperlaneImplementation;
        address wormholeImplementation;
        address wormholeSRImplementation;
        address superRegistry;
        address paymentHelper;
        address dstLzImplementation;
        address dstHyperlaneImplementation;
        address dstWormholeARImplementation;
        address dstWormholeSRImplementation;
        SuperRegistry superRegistryC;
    }

    function _configureCurrentChainBasedOnTargetDestinations(CurrentChainBasedOnDstvars memory vars) internal {
        for (uint256 k = 0; k < chainIds.length; k++) {
            if (vars.dstChainId == chainIds[k]) {
                vars.dstTrueIndex = k;

                break;
            }
        }
        vars.dstLzChainId = lz_chainIds[vars.dstTrueIndex];
        vars.dstHypChainId = hyperlane_chainIds[vars.dstTrueIndex];
        vars.dstWormholeChainId = wormhole_chainIds[vars.dstTrueIndex];

        vars.dstLzImplementation =
            _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "LayerzeroImplementation");
        vars.dstHyperlaneImplementation =
            _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "HyperlaneImplementation");
        vars.dstWormholeARImplementation =
            _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "WormholeARImplementation");

        vars.dstWormholeSRImplementation =
            _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "WormholeSRImplementation");

        LayerzeroImplementation(payable(vars.lzImplementation)).setTrustedRemote(
            vars.dstLzChainId, abi.encodePacked(vars.dstLzImplementation, vars.lzImplementation)
        );

        LayerzeroImplementation(payable(vars.lzImplementation)).setChainId(vars.dstChainId, vars.dstLzChainId);

        /// @dev for mainnet
        /// @dev do not override default oracle with chainlink for BASE

        /// NOTE: since chainlink oracle is not on BASE, we use the default oracle
        // if (vars.chainId != BASE) {
        //     LayerzeroImplementation(payable(vars.lzImplementation)).setConfig(
        //         0,
        //         /// Defaults To Zero
        //         vars.dstLzChainId,
        //         6,
        //         /// For Oracle Config
        //         abi.encode(CHAINLINK_lzOracle)
        //     );
        // }

        HyperlaneImplementation(payable(vars.hyperlaneImplementation)).setReceiver(
            vars.dstHypChainId, vars.dstHyperlaneImplementation
        );

        HyperlaneImplementation(payable(vars.hyperlaneImplementation)).setChainId(vars.dstChainId, vars.dstHypChainId);

        WormholeARImplementation(payable(vars.wormholeImplementation)).setReceiver(
            vars.dstWormholeChainId, vars.dstWormholeARImplementation
        );

        WormholeARImplementation(payable(vars.wormholeImplementation)).setChainId(
            vars.dstChainId, vars.dstWormholeChainId
        );

        WormholeSRImplementation(payable(vars.wormholeSRImplementation)).setChainId(
            vars.dstChainId, vars.dstWormholeChainId
        );

        WormholeSRImplementation(payable(vars.wormholeSRImplementation)).setReceiver(
            vars.dstWormholeChainId, vars.dstWormholeSRImplementation
        );

        SuperRegistry(payable(vars.superRegistry)).setRequiredMessagingQuorum(vars.dstChainId, 1);

        vars.superRegistryC.setVaultLimitPerDestination(vars.dstChainId, 5);

        assert(abi.decode(GAS_USED[vars.dstChainId][3], (uint256)) > 0);
        assert(abi.decode(GAS_USED[vars.dstChainId][4], (uint256)) > 0);
        assert(abi.decode(GAS_USED[vars.dstChainId][6], (uint256)) > 0);

        PaymentHelper(payable(vars.paymentHelper)).addRemoteChain(
            vars.dstChainId,
            IPaymentHelper.PaymentHelperConfig(
                PRICE_FEEDS[vars.chainId][vars.dstChainId],
                address(0),
                abi.decode(GAS_USED[vars.dstChainId][3], (uint256)),
                abi.decode(GAS_USED[vars.dstChainId][4], (uint256)),
                vars.dstChainId == ARBI ? 1_000_000 : 200_000,
                abi.decode(GAS_USED[vars.dstChainId][6], (uint256)),
                nativePrices[vars.dstTrueIndex],
                gasPrices[vars.dstTrueIndex],
                750,
                2_000_000,
                /// @dev ackGasCost to move a msg from dst to source
                10_000,
                10_000
            )
        );

        PaymentHelper(payable(vars.paymentHelper)).updateRegisterAERC20Params(abi.encode(4, abi.encode(0, "")));

        /// @dev FIXME not setting BROADCAST_REGISTRY yet, which will result in all broadcast tentatives to fail
        bytes32[] memory ids = new bytes32[](18);
        ids[0] = vars.superRegistryC.SUPERFORM_ROUTER();
        ids[1] = vars.superRegistryC.SUPERFORM_FACTORY();
        ids[2] = vars.superRegistryC.PAYMASTER();
        ids[3] = vars.superRegistryC.PAYMENT_HELPER();
        ids[4] = vars.superRegistryC.CORE_STATE_REGISTRY();
        ids[5] = vars.superRegistryC.DST_SWAPPER();
        ids[6] = vars.superRegistryC.SUPER_POSITIONS();
        ids[7] = vars.superRegistryC.SUPER_RBAC();
        ids[8] = vars.superRegistryC.PAYLOAD_HELPER();
        ids[9] = vars.superRegistryC.EMERGENCY_QUEUE();
        ids[10] = vars.superRegistryC.PAYMENT_ADMIN();
        ids[11] = vars.superRegistryC.CORE_REGISTRY_PROCESSOR();
        ids[12] = vars.superRegistryC.CORE_REGISTRY_UPDATER();
        ids[13] = vars.superRegistryC.BROADCAST_REGISTRY_PROCESSOR();
        ids[14] = vars.superRegistryC.CORE_REGISTRY_RESCUER();
        ids[15] = vars.superRegistryC.CORE_REGISTRY_DISPUTER();
        ids[16] = vars.superRegistryC.DST_SWAPPER_PROCESSOR();
        ids[17] = vars.superRegistryC.SUPERFORM_RECEIVER();

        address[] memory newAddresses = new address[](18);
        newAddresses[0] = _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "SuperformRouter");
        newAddresses[1] = _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "SuperformFactory");
        newAddresses[2] = _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "PayMaster");
        newAddresses[3] = _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "PaymentHelper");
        newAddresses[4] = _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "CoreStateRegistry");
        newAddresses[5] = _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "DstSwapper");
        newAddresses[6] = _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "SuperPositions");
        newAddresses[7] = _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "SuperRBAC");
        newAddresses[8] = _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "PayloadHelper");
        newAddresses[9] = _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "EmergencyQueue");
        newAddresses[10] = PAYMENT_ADMIN;
        newAddresses[11] = CSR_PROCESSOR;
        newAddresses[12] = CSR_UPDATER;
        newAddresses[13] = BROADCAST_REGISTRY_PROCESSOR;
        newAddresses[14] = CSR_RESCUER;
        newAddresses[15] = CSR_DISPUTER;
        newAddresses[16] = DST_SWAPPER;
        newAddresses[17] = SUPERFORM_RECEIVER;

        uint64[] memory chainIdsSetAddresses = new uint64[](18);
        chainIdsSetAddresses[0] = vars.dstChainId;
        chainIdsSetAddresses[1] = vars.dstChainId;
        chainIdsSetAddresses[2] = vars.dstChainId;
        chainIdsSetAddresses[3] = vars.dstChainId;
        chainIdsSetAddresses[4] = vars.dstChainId;
        chainIdsSetAddresses[5] = vars.dstChainId;
        chainIdsSetAddresses[6] = vars.dstChainId;
        chainIdsSetAddresses[7] = vars.dstChainId;
        chainIdsSetAddresses[8] = vars.dstChainId;
        chainIdsSetAddresses[9] = vars.dstChainId;
        chainIdsSetAddresses[10] = vars.dstChainId;
        chainIdsSetAddresses[11] = vars.dstChainId;
        chainIdsSetAddresses[12] = vars.dstChainId;
        chainIdsSetAddresses[13] = vars.dstChainId;
        chainIdsSetAddresses[14] = vars.dstChainId;
        chainIdsSetAddresses[15] = vars.dstChainId;
        chainIdsSetAddresses[16] = vars.dstChainId;
        chainIdsSetAddresses[17] = vars.dstChainId;

        vars.superRegistryC.batchSetAddress(ids, newAddresses, chainIdsSetAddresses);

        /*
        vars.superRegistryC.setAddress(
            vars.superRegistryC.TIMELOCK_STATE_REGISTRY(),
            _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "TimelockStateRegistry"),
            vars.dstChainId
        );
        */
    }

    function _preDeploymentSetup() internal {
        mapping(uint64 => mapping(uint256 => bytes)) storage gasUsed = GAS_USED;

        // swapGasUsed = 3
        gasUsed[ETH][3] = abi.encode(400_000);
        gasUsed[BSC][3] = abi.encode(650_000);
        gasUsed[AVAX][3] = abi.encode(850_000);
        gasUsed[POLY][3] = abi.encode(700_000);
        gasUsed[OP][3] = abi.encode(550_000);
        gasUsed[ARBI][3] = abi.encode(2_500_000);
        gasUsed[BASE][3] = abi.encode(600_000);

        // updateGasUsed == 4 (only used on deposits for now)
        gasUsed[ETH][4] = abi.encode(225_000);
        gasUsed[BSC][4] = abi.encode(225_000);
        gasUsed[AVAX][4] = abi.encode(200_000);
        gasUsed[POLY][4] = abi.encode(200_000);
        gasUsed[OP][4] = abi.encode(200_000);
        gasUsed[ARBI][4] = abi.encode(1_400_000);
        gasUsed[BASE][4] = abi.encode(200_000);

        // withdrawGasUsed == 6 (incl. cost to update)
        gasUsed[ETH][6] = abi.encode(600_000);
        gasUsed[BSC][6] = abi.encode(1_500_000);
        gasUsed[AVAX][6] = abi.encode(1_000_000);
        gasUsed[POLY][6] = abi.encode(1_000_000);
        gasUsed[OP][6] = abi.encode(1_000_000);
        gasUsed[ARBI][6] = abi.encode(2_500_000);
        gasUsed[BASE][6] = abi.encode(1_500_000);

        mapping(uint64 => address) storage lzEndpointsStorage = LZ_ENDPOINTS;
        lzEndpointsStorage[ETH] = ETH_lzEndpoint;
        lzEndpointsStorage[BSC] = BSC_lzEndpoint;
        lzEndpointsStorage[AVAX] = AVAX_lzEndpoint;
        lzEndpointsStorage[POLY] = POLY_lzEndpoint;
        lzEndpointsStorage[ARBI] = ARBI_lzEndpoint;
        lzEndpointsStorage[OP] = OP_lzEndpoint;
        lzEndpointsStorage[BASE] = BASE_lzEndpoint;
        lzEndpointsStorage[FANTOM] = FANTOM_lzEndpoint;

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
        bridgeAddresses[BASE] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE, address(0), address(0)];
        bridgeAddresses[FANTOM] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0,
            0x565810cbfa3Cf1390963E5aFa2fB953795686339
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
        priceFeeds[ETH][BASE] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][FANTOM] = 0x2DE7E4a9488488e0058B95854CC2f7955B35dC9b;

        /// BSC
        priceFeeds[BSC][BSC] = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        priceFeeds[BSC][ETH] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][AVAX] = 0x5974855ce31EE8E1fff2e76591CbF83D7110F151;
        priceFeeds[BSC][POLY] = 0x7CA57b0cA6367191c94C8914d7Df09A57655905f;
        priceFeeds[BSC][OP] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][ARBI] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][BASE] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][FANTOM] = 0xe2A47e87C0f4134c8D06A41975F6860468b2F925;

        /// AVAX
        priceFeeds[AVAX][AVAX] = 0x0A77230d17318075983913bC2145DB16C7366156;
        priceFeeds[AVAX][BSC] = address(0);
        priceFeeds[AVAX][ETH] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][POLY] = 0x1db18D41E4AD2403d9f52b5624031a2D9932Fd73;
        priceFeeds[AVAX][OP] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][ARBI] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][BASE] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][FANTOM] = 0x2dD517B2f9ba49CedB0573131FD97a5AC19ff648;

        /// POLYGON
        priceFeeds[POLY][POLY] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        priceFeeds[POLY][AVAX] = 0xe01eA2fbd8D76ee323FbEd03eB9a8625EC981A10;
        priceFeeds[POLY][BSC] = 0x82a6c4AF830caa6c97bb504425f6A66165C2c26e;
        priceFeeds[POLY][ETH] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][OP] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][ARBI] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][BASE] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][FANTOM] = 0x58326c0F831b2Dbf7234A4204F28Bba79AA06d5f;

        /// OPTIMISM
        priceFeeds[OP][OP] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][POLY] = 0x0ded608AFc23724f614B76955bbd9dFe7dDdc828;
        priceFeeds[OP][AVAX] = 0x5087Dc69Fd3907a016BD42B38022F7f024140727;
        priceFeeds[OP][BSC] = 0xD38579f7cBD14c22cF1997575eA8eF7bfe62ca2c;
        priceFeeds[OP][ETH] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][ARBI] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][BASE] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][FANTOM] = 0xc19d58652d6BfC6Db6FB3691eDA6Aa7f3379E4E9;

        /// ARBITRUM
        priceFeeds[ARBI][ARBI] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][OP] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][POLY] = 0x52099D4523531f678Dfc568a7B1e5038aadcE1d6;
        priceFeeds[ARBI][AVAX] = 0x8bf61728eeDCE2F32c456454d87B5d6eD6150208;
        priceFeeds[ARBI][BSC] = 0x6970460aabF80C5BE983C6b74e5D06dEDCA95D4A;
        priceFeeds[ARBI][ETH] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][BASE] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][FANTOM] = 0xFeaC1A3936514746e70170c0f539e70b23d36F19;

        /// BASE
        priceFeeds[BASE][BASE] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][OP] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][POLY] = address(0);
        priceFeeds[BASE][AVAX] = address(0);
        priceFeeds[BASE][BSC] = address(0);
        priceFeeds[BASE][ETH] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][ARBI] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][FANTOM] = address(0);

        /// FANTOM
        priceFeeds[FANTOM][FANTOM] = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc;
        priceFeeds[FANTOM][OP] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][POLY] = address(0);
        priceFeeds[FANTOM][AVAX] = address(0);
        priceFeeds[FANTOM][BSC] = 0x6dE70f4791C4151E00aD02e969bD900DC961f92a;
        priceFeeds[FANTOM][ETH] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][BASE] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][ARBI] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
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

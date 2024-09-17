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
import { ERC5115Form } from "src/forms/ERC5115Form.sol";
import { ERC4626Form as BlastERC4626Form } from "script/forge-scripts/misc/blast/forms/BlastERC4626Form.sol";
import { ERC5115Form as BlastERC5115Form } from "script/forge-scripts/misc/blast/forms/BlastERC5115Form.sol";
import { ERC5115To4626WrapperFactory } from "src/forms/wrappers/ERC5115To4626WrapperFactory.sol";
import { DstSwapper } from "src/crosschain-liquidity/DstSwapper.sol";
import { LiFiValidator } from "src/crosschain-liquidity/lifi/LiFiValidator.sol";
import { SocketValidator } from "src/crosschain-liquidity/socket/SocketValidator.sol";
import { SocketOneInchValidator } from "src/crosschain-liquidity/socket/SocketOneInchValidator.sol";
import { DeBridgeValidator } from "src/crosschain-liquidity/debridge/DeBridgeValidator.sol";
import { DeBridgeForwarderValidator } from "src/crosschain-liquidity/debridge/DeBridgeForwarderValidator.sol";
import { OneInchValidator } from "src/crosschain-liquidity/1inch/OneInchValidator.sol";
import { LayerzeroV2Implementation } from "src/crosschain-data/adapters/layerzero-v2/LayerzeroV2Implementation.sol";
import { LayerzeroImplementation } from "src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol";
import {
    AxelarImplementation,
    IAxelarGateway,
    IAxelarGasService,
    IInterchainGasEstimation
} from "src/crosschain-data/adapters/axelar/AxelarImplementation.sol";
import { HyperlaneImplementation } from "src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol";
import { WormholeARImplementation } from
    "src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol";
import { WormholeSRImplementation } from
    "src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol";
import { IMailbox } from "src/vendor/hyperlane/IMailbox.sol";
import { IInterchainGasPaymaster } from "src/vendor/hyperlane/IInterchainGasPaymaster.sol";
import { PayloadHelper } from "src/crosschain-data/utils/PayloadHelper.sol";
import { PaymentHelper } from "src/payments/PaymentHelper.sol";
import { IPaymentHelperV2 as IPaymentHelper } from "src/interfaces/IPaymentHelperV2.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { PayMaster } from "src/payments/PayMaster.sol";
import { EmergencyQueue } from "src/EmergencyQueue.sol";
import { VaultClaimer } from "src/VaultClaimer.sol";
import { AcrossFacetPacked } from "./misc/blacklistedFacets/AcrossFacetPacked.sol";
import { AmarokFacetPacked } from "./misc/blacklistedFacets/AmarokFacetPacked.sol";
import { RewardsDistributor } from "src/RewardsDistributor.sol";
import "forge-std/console.sol";
import { BatchScript } from "./safe/BatchScript.sol";

struct SetupVars {
    uint64 chainId;
    uint64 dstChainId;
    uint16 dstLzChainId;
    uint32 dstHypChainId;
    uint16 dstWormholeChainId;
    string fork;
    bytes4[] selectorsToBlacklist;
    address[] ambAddresses;
    address superForm;
    address factory;
    address lzEndpoint;
    address lzImplementation;
    address lzV1Implementation;
    address hyperlaneImplementation;
    address wormholeImplementation;
    address wormholeSRImplementation;
    address axelarImplementation;
    address erc4626Form;
    address erc5115Form;
    address erc5115To4626WrapperFactory;
    address broadcastRegistry;
    address coreStateRegistry;
    address UNDERLYING_TOKEN;
    address vault;
    address superformRouter;
    address dstLzImplementation;
    address dstHyperlaneImplementation;
    address dstWormholeARImplementation;
    address dstWormholeSRImplementation;
    address dstAxelarImplementation;
    address dstStateRegistry;
    address dstSwapper;
    address superRegistry;
    address superPositions;
    address superRBAC;
    address lifiValidator;
    address socketOneInchValidator;
    address deBridgeValidator;
    address deBridgeForwarderValidator;
    address oneInchValidator;
    address kycDao4626Form;
    address PayloadHelper;
    address paymentHelper;
    address payMaster;
    address emergencyQueue;
    address rewardsDistributor;
    SuperRegistry superRegistryC;
    SuperRBAC superRBACC;
    LiFiValidator lv;
    bytes32[] ids;
    address[] newAddresses;
    uint64[] chainIdsSetAddresses;
}

abstract contract AbstractDeploySingle is BatchScript {
    /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public constant CANONICAL_PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    mapping(uint64 chainId => mapping(bytes32 implementation => address at)) public contracts;

    string[29] public contractNames = [
        "CoreStateRegistry",
        "BroadcastRegistry",
        "LayerzeroImplementation",
        "LayerzeroV1Implementation",
        "HyperlaneImplementation",
        "WormholeARImplementation",
        "WormholeSRImplementation",
        "LiFiValidator",
        "SocketValidator",
        "SocketOneInchValidator",
        "DstSwapper",
        "SuperformFactory",
        "ERC4626Form",
        "SuperformRouter",
        "SuperPositions",
        "SuperRegistry",
        "SuperRBAC",
        "PayloadHelper",
        "PaymentHelper",
        "PayMaster",
        "EmergencyQueue",
        "VaultClaimer",
        "RewardsDistributor",
        "DeBridgeValidator",
        "DeBridgeForwarderValidator",
        "OneInchValidator",
        "AxelarImplementation",
        "ERC5115Form",
        "ERC5115To4626WrapperFactory"
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
        Linea,
        Blast
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

    /// @dev 1 = ERC4626Form, 5 = 5115Form (2 will tentatively be used for ERC7540)
    uint32[] public STAGING_FORM_IMPLEMENTATION_IDS = [uint32(1), uint32(5)];

    /// @dev 1 = ERC4626Form, 3 = 5115Form (2 will tentatively be used for ERC7540)
    uint32[] public FORM_IMPLEMENTATION_IDS = [uint32(1), uint32(3)];
    string[] public VAULT_KINDS = ["Vault"];

    /// @dev liquidity bridge ids 101 is lifi v2,
    /// 2 is socket
    /// 3 is socket one inch implementation
    /// 4 is one inch implementation
    /// 5 is debridge implementation
    /// 6 is debridge crosschain forwarder
    uint8[] public bridgeIds = [101, 3, 4, 5, 6];

    mapping(uint64 chainId => address[] bridgeAddresses) public BRIDGE_ADDRESSES;

    /// @dev setup amb bridges
    /// @notice id 5 is layerzero v2
    /// @notice id 6 is hyperlane (with amb protect)
    /// @notice id 7 is wormhole AR (with amb protect)
    /// @notice id 4 is wormhole SR
    /// @notice id 8 is axelar
    /// @notice id 9 is layerzero v1
    uint8[] public ambIds = [uint8(5), 6, 7, 4, 8, 9];
    bool[] public broadcastAMB = [false, false, false, true, false, false];

    /// @dev new settings ids
    bytes32 rewardsDistributorId = keccak256("REWARDS_DISTRIBUTOR");
    bytes32 rewardsAdminRole = keccak256("REWARDS_ADMIN_ROLE");

    /*//////////////////////////////////////////////////////////////
                        AMB VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev uses CREATE2
    address public lzV2Endpoint = 0x1a44076050125825900e736c501f859c50fE728c;
    address public constant CHAINLINK_lzOracle = 0x150A58e9E6BF69ccEb1DBA5ae97C166DC8792539;

    address[] public lzEndpoints = [
        0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7,
        0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7,
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
        address(0),
        0x02d16BC51af6BfD153d67CA61754cF912E82C4d9,
        0x3a867fCfFeC2B790970eeBDC9023E75B0a172aa7
    ];

    address[] public hyperlanePaymasters = [
        0x9e6B1022bE9BBF5aFd152483DAD9b88911bC8611,
        0x78E25e7f84416e69b9339B0A6336EB6EFfF6b451,
        0x95519ba800BBd0d34eeAE026fEc620AD978176C0,
        0x0071740Bf129b05C4684abfbBeD248D80971cce2,
        0x3b6044acd6767f017e99318AA6Ef93b7B06A5a22,
        0xD8A76C4D91fCbB7Cc8eA795DFDF870E48368995C,
        0xc3F23848Ed2e04C0c6d41bd7804fa8f89F940B94,
        address(0),
        0x8105a095368f1a184CceA86cCe21318B5Ee5BE28,
        0xB3fCcD379ad66CED0c91028520C64226611A48c9
    ];

    address[] public wormholeCore = [
        0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B,
        0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B,
        0x54a8e5f9c4CbA08F9943965859F6c34eAF03E26c,
        0x7A4B5a56256163F07b2C80A7cA55aBE66c4ec4d7,
        0xa5f208e072434bC67592E4C49C1B991BA79BCA46,
        0xEe91C335eab126dF5fDB3797EA9d6aD93aeC9722,
        0xbebdb6C8ddC678FfA9f8748f85C815C556Dd8ac6,
        0x126783A6Cb203a3E35344528B26ca3a0489a1485,
        address(0),
        0xbebdb6C8ddC678FfA9f8748f85C815C556Dd8ac6
    ];

    address[] public axelarGateway = [
        0x4F4495243837681061C4743b74B3eEdf548D56A5,
        0x304acf330bbE08d1e512eefaa92F6a57871fD895,
        0x5029C0EFf6C34351a0CEc334542cDb22c7928f78,
        0x6f015F16De9fC8791b234eF68D486d2bF203FBA8,
        0xe432150cce91c13a887f7D836923d5597adD8E31,
        0xe432150cce91c13a887f7D836923d5597adD8E31,
        0xe432150cce91c13a887f7D836923d5597adD8E31,
        0x304acf330bbE08d1e512eefaa92F6a57871fD895,
        0xe432150cce91c13a887f7D836923d5597adD8E31,
        0xe432150cce91c13a887f7D836923d5597adD8E31
    ];

    address[] public axelarGasService = [
        0x2d5d7d31F671F86C782533cc367F14109a082712,
        0x2d5d7d31F671F86C782533cc367F14109a082712,
        0x2d5d7d31F671F86C782533cc367F14109a082712,
        0x2d5d7d31F671F86C782533cc367F14109a082712,
        0x2d5d7d31F671F86C782533cc367F14109a082712,
        0x2d5d7d31F671F86C782533cc367F14109a082712,
        0x2d5d7d31F671F86C782533cc367F14109a082712,
        0x2d5d7d31F671F86C782533cc367F14109a082712,
        0x2d5d7d31F671F86C782533cc367F14109a082712,
        0x2d5d7d31F671F86C782533cc367F14109a082712
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
    uint64 public constant LINEA = 59_144;
    uint64 public constant BLAST = 81_457;

    uint256[] public manualNonces = [19, 19, 19, 19, 18, 18, 17, 6, 0, 0];
    uint64[] public chainIds = [1, 56, 43_114, 137, 42_161, 10, 8453, 250, 59_144, 81_457];
    string[] public chainNames =
        ["Ethereum", "Binance", "Avalanche", "Polygon", "Arbitrum", "Optimism", "Base", "Fantom", "Linea", "Blast"];

    /// @dev vendor chain ids
    uint16[] public lz_v1_chainIds = [uint16(101), 102, 106, 109, 110, 111, 184, 112, 183, 243];
    uint32[] public lz_chainIds = [30_101, 30_102, 30_106, 30_109, 30_110, 30_111, 30_184, 30_112, 30_183, 30_243];
    uint32[] public hyperlane_chainIds = [1, 56, 43_114, 137, 42_161, 10, 8453, 250, 59_144, 81_457];

    /// @notice Wormhole is not available on Linea yet
    uint16[] public wormhole_chainIds = [2, 4, 6, 5, 23, 24, 30, 10, 38, 36];
    string[] public axelar_chainIds =
        ["Ethereum", "binance", "Avalanche", "Polygon", "arbitrum", "optimism", "base", "Fantom", "linea", "blast"];

    uint256 public constant milionTokensE18 = 1 ether;

    mapping(uint64 => mapping(uint256 => bytes)) public GAS_USED;

    /// @dev !WARNING: update these for Fantom
    /// @dev check https://api-utils.superform.xyz/docs#/Utils/get_gas_prices_gwei_gas_get
    uint256[] public gasPrices = [
        8_889_044_613, // ETH
        1_000_000_000, // BSC
        25_000_000_000, // AVAX
        30_000_000_024, // POLY
        10_000_000, // ARBI
        1_321_409, // OP
        6_020_565, // BASE
        10_000_000_000, // FANTOM
        60_000_000, // LINEA (0.06 gwei)
        730_000_000 // BLAST (0.73 gwei)
    ];

    /// @dev !WARNING: update these for Fantom
    /// @dev check https://api-utils.superform.xyz/docs#/Utils/get_native_prices_chainlink_native_get
    uint256[] public nativePrices = [
        229_221_000_000, // ETH
        54_521_000_000, // BSC
        2_392_000_000, // AVAX
        38_017_300, // POLY
        229_280_000_000, // ARBI
        229_221_000_000, // OP
        229_280_000_000, // BASE
        50_892_796, // FANTOM
        229_280_000_000, // LINEA
        229_280_000_000 // BLAST
    ];

    /*//////////////////////////////////////////////////////////////
                        CHAINLINK VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(uint64 => mapping(uint64 => address)) public PRICE_FEEDS;

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
    address public REWARDS_ADMIN;

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
        0xe6ca8aC2D27A1bAd2Ab6b136Eab87488c3c98Fd1,
        /// @dev FANTOM https://safe.fantom.network/home?safe=ftm:0xe6ca8aC2D27A1bAd2Ab6b136Eab87488c3c98Fd1
        0x62Bbfe3ef3faAb7045d29bC388E5A0c5033D8b77,
        /// @dev LINEA https://safe.linea.build/home?safe=linea:0x62Bbfe3ef3faAb7045d29bC388E5A0c5033D8b77
        0x95B5837CF46E6ab340fFf3844ca5e7d8ead5B8AF
        /// @dev BLAST https://blast-safe.io/home?safe=blastmainnet:0x95B5837CF46E6ab340fFf3844ca5e7d8ead5B8AF
    ];

    address[] public PROTOCOL_ADMINS_STAGING = [
        address(0),
        0xBbb23AE2e3816a178f8bd405fb101D064C5071d9,
        /// @dev BSC https://app.onchainden.com/safes/bnb:0xBbb23AE2e3816a178f8bd405fb101D064C5071d9
        address(0),
        address(0),
        0xBbb23AE2e3816a178f8bd405fb101D064C5071d9,
        /// @dev ARBI https://app.onchainden.com/safes/arb1:0xBbb23AE2e3816a178f8bd405fb101D064C5071d9
        0xfe3A0C3c4980Eef00C2Ec73D8770a2D9A489fdE5,
        /// @dev OP https://app.onchainden.com/safes/oeth:0xfe3A0C3c4980Eef00C2Ec73D8770a2D9A489fdE5
        0xbd1F951F52FC7616E2F743F976295fDc5276Cfb9,
        /// @dev BASE https://app.onchainden.com/safes/base:0xbd1F951F52FC7616E2F743F976295fDc5276Cfb9
        0xdc337f59a90B1F6a016c02851559AdbE81f0B889,
        /// @dev FANTOM https://safe.fantom.network/home?safe=ftm:0xdc337f59a90B1F6a016c02851559AdbE81f0B889
        0xBbb23AE2e3816a178f8bd405fb101D064C5071d9,
        /// @dev LINEA https://safe.linea.build/home?safe=linea:0xBbb23AE2e3816a178f8bd405fb101D064C5071d9
        0xBbb23AE2e3816a178f8bd405fb101D064C5071d9
        /// @dev BLAST https://blast-safe.io/home?safe=blastmainnet:0xBbb23AE2e3816a178f8bd405fb101D064C5071d9
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
        forks[Chains.Linea] = "linea";
        forks[Chains.Blast] = "blast";
    }

    function getContract(uint64 chainId, string memory _name) public view returns (address) {
        return contracts[chainId][bytes32(bytes(_name))];
    }

    function _deployStage1(
        uint256 env,
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
        /// @dev WARNING - MUST KEEP THESE ADDRESSES INTACT TO PRESERVE CREATE2 ADDRESS
        vars.superRBAC = address(
            new SuperRBAC{ salt: salt }(
                ISuperRBAC.InitialRoleSetup({
                    admin: ownerAddress,
                    emergencyAdmin: ownerAddress,
                    paymentAdmin: PAYMENT_ADMIN,
                    csrProcessor: CSR_PROCESSOR,
                    tlProcessor: EMERGENCY_ADMIN,
                    brProcessor: EMERGENCY_ADMIN,
                    csrUpdater: CSR_UPDATER,
                    srcVaaRelayer: EMERGENCY_ADMIN,
                    dstSwapper: DST_SWAPPER,
                    csrRescuer: CSR_RESCUER,
                    csrDisputer: CSR_DISPUTER
                })
            )
        );
        contracts[vars.chainId][bytes32(bytes("SuperRBAC"))] = vars.superRBAC;
        vars.superRBACC = SuperRBAC(vars.superRBAC);

        /// @dev 1.1 temporary setting of payment admin to owneraddress for updateRemoteChain at the end of this
        /// function
        vars.superRBACC.grantRole(vars.superRBACC.PAYMENT_ADMIN_ROLE(), ownerAddress);
        /// @dev 1.2 new setting of BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE
        vars.superRBACC.grantRole(
            vars.superRBACC.BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE(), BROADCAST_REGISTRY_PROCESSOR
        );
        vars.superRBACC.revokeRole(vars.superRBACC.BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE(), EMERGENCY_ADMIN);
        /// @dev 1.3 new setting of WORMHOLE_VAA_RELAYER_ROLE
        vars.superRBACC.grantRole(vars.superRBACC.WORMHOLE_VAA_RELAYER_ROLE(), WORMHOLE_VAA_RELAYER);
        vars.superRBACC.revokeRole(vars.superRBACC.WORMHOLE_VAA_RELAYER_ROLE(), EMERGENCY_ADMIN);

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

        /// @dev 3.2 - deploy Broadcast State Registry
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
        vars.lzImplementation = address(new LayerzeroV2Implementation{ salt: salt }(vars.superRegistryC));
        contracts[vars.chainId][bytes32(bytes("LayerzeroImplementation"))] = vars.lzImplementation;

        LayerzeroV2Implementation(payable(vars.lzImplementation)).setLzEndpoint(lzV2Endpoint);

        /// @dev 5.1.1- deploy Layerzero V1 Implementation
        vars.lzV1Implementation = address(new LayerzeroImplementation{ salt: salt }(vars.superRegistryC));
        contracts[vars.chainId][bytes32(bytes("LayerzeroV1Implementation"))] = vars.lzV1Implementation;

        LayerzeroImplementation(payable(vars.lzV1Implementation)).setLzEndpoint(lzEndpoints[trueIndex]);

        /// @dev 5.2- deploy Hyperlane Implementation
        if (vars.chainId != FANTOM) {
            vars.hyperlaneImplementation = address(new HyperlaneImplementation{ salt: salt }(vars.superRegistryC));
            HyperlaneImplementation(vars.hyperlaneImplementation).setHyperlaneConfig(
                IMailbox(hyperlaneMailboxes[trueIndex]), IInterchainGasPaymaster(hyperlanePaymasters[trueIndex])
            );
            contracts[vars.chainId][bytes32(bytes("HyperlaneImplementation"))] = vars.hyperlaneImplementation;
        }

        if (vars.chainId != LINEA) {
            /// @dev 5.3- deploy Wormhole Automatic Relayer Implementation
            vars.wormholeImplementation = address(new WormholeARImplementation{ salt: salt }(vars.superRegistryC));
            contracts[vars.chainId][bytes32(bytes("WormholeARImplementation"))] = vars.wormholeImplementation;

            address wormholeRelayerConfig = vars.chainId == BASE ? wormholeBaseRelayer : wormholeRelayer;
            WormholeARImplementation(vars.wormholeImplementation).setWormholeRelayer(wormholeRelayerConfig);
            WormholeARImplementation(vars.wormholeImplementation).setRefundChainId(wormhole_chainIds[trueIndex]);

            /// @dev 6.4- deploy Wormhole Specialized Relayer Implementation
            vars.wormholeSRImplementation =
                address(new WormholeSRImplementation{ salt: salt }(vars.superRegistryC, brRegistryId));
            contracts[vars.chainId][bytes32(bytes("WormholeSRImplementation"))] = vars.wormholeSRImplementation;

            WormholeSRImplementation(vars.wormholeSRImplementation).setWormholeCore(wormholeCore[trueIndex]);
            /// @dev FIXME who is the wormhole relayer on mainnet
            WormholeSRImplementation(vars.wormholeSRImplementation).setRelayer(ownerAddress);
        }

        /// @dev 6.5- deploy Axelar Implementation
        vars.axelarImplementation = address(new AxelarImplementation{ salt: salt }(vars.superRegistryC));
        contracts[vars.chainId][bytes32(bytes("AxelarImplementation"))] = vars.axelarImplementation;

        AxelarImplementation(vars.axelarImplementation).setAxelarConfig(IAxelarGateway(axelarGateway[trueIndex]));
        AxelarImplementation(vars.axelarImplementation).setAxelarGasService(
            IAxelarGasService(axelarGasService[trueIndex]), IInterchainGasEstimation(axelarGasService[trueIndex])
        );

        vars.ambAddresses[0] = vars.lzImplementation;
        vars.ambAddresses[1] = vars.hyperlaneImplementation;
        vars.ambAddresses[2] = vars.wormholeImplementation;
        vars.ambAddresses[3] = vars.wormholeSRImplementation;
        vars.ambAddresses[4] = vars.axelarImplementation;
        vars.ambAddresses[5] = vars.lzV1Implementation;

        /// @dev 6- deploy liquidity validators
        vars.lifiValidator = address(new LiFiValidator{ salt: salt }(vars.superRegistry));
        vars.lv = LiFiValidator(vars.lifiValidator);

        vars.selectorsToBlacklist = new bytes4[](8);

        /// @dev add selectors that need to be blacklisted post LiFiValidator deployment here
        vars.selectorsToBlacklist[0] = AcrossFacetPacked.startBridgeTokensViaAcrossNativePacked.selector;
        vars.selectorsToBlacklist[1] = AcrossFacetPacked.startBridgeTokensViaAcrossNativeMin.selector;
        vars.selectorsToBlacklist[2] = AcrossFacetPacked.startBridgeTokensViaAcrossERC20Packed.selector;
        vars.selectorsToBlacklist[3] = AcrossFacetPacked.startBridgeTokensViaAcrossERC20Min.selector;
        vars.selectorsToBlacklist[4] = AmarokFacetPacked.startBridgeTokensViaAmarokERC20PackedPayFeeWithAsset.selector;
        vars.selectorsToBlacklist[5] = AmarokFacetPacked.startBridgeTokensViaAmarokERC20PackedPayFeeWithNative.selector;
        vars.selectorsToBlacklist[6] = AmarokFacetPacked.startBridgeTokensViaAmarokERC20MinPayFeeWithAsset.selector;
        vars.selectorsToBlacklist[7] = AmarokFacetPacked.startBridgeTokensViaAmarokERC20MinPayFeeWithNative.selector;

        for (uint256 j = 0; j < vars.selectorsToBlacklist.length; ++j) {
            vars.lv.addToBlacklist(vars.selectorsToBlacklist[j]);
            assert(vars.lv.isSelectorBlacklisted(vars.selectorsToBlacklist[j]));
        }
        contracts[vars.chainId][bytes32(bytes("LiFiValidator"))] = vars.lifiValidator;

        vars.deBridgeValidator = address(new DeBridgeValidator{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("DeBridgeValidator"))] = vars.deBridgeValidator;

        vars.deBridgeForwarderValidator = address(new DeBridgeForwarderValidator{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("DeBridgeForwarderValidator"))] = vars.deBridgeForwarderValidator;

        if (vars.chainId != LINEA && vars.chainId != BLAST) {
            vars.socketOneInchValidator = address(new SocketOneInchValidator{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("SocketOneInchValidator"))] = vars.socketOneInchValidator;

            vars.oneInchValidator = address(new OneInchValidator{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("OneInchValidator"))] = vars.oneInchValidator;
        }

        bridgeValidators[0] = vars.lifiValidator;
        bridgeValidators[1] = vars.socketOneInchValidator;
        bridgeValidators[2] = vars.oneInchValidator;
        bridgeValidators[3] = vars.deBridgeValidator;
        bridgeValidators[4] = vars.deBridgeForwarderValidator;

        /// @dev 7 - Deploy SuperformFactory
        vars.factory = address(new SuperformFactory{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("SuperformFactory"))] = vars.factory;

        /// @dev FIXME does SuperRBAC itself need broadcaster role?
        vars.superRegistryC.setAddress(vars.superRegistryC.SUPERFORM_FACTORY(), vars.factory, vars.chainId);
        vars.superRBACC.grantRole(vars.superRBACC.BROADCASTER_ROLE(), vars.factory);

        /// @dev 8 - Deploy 4626Form implementations
        if (vars.chainId != BLAST) {
            // Standard ERC4626 Form

            vars.erc4626Form = address(new ERC4626Form{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("ERC4626Form"))] = vars.erc4626Form;

            /// @dev 8.1 - Deploy 5115Form implementation
            vars.erc5115Form = address(new ERC5115Form{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("ERC5115Form"))] = vars.erc5115Form;
        } else {
            // Standard ERC4626 Form
            vars.erc4626Form = address(new BlastERC4626Form{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("ERC4626Form"))] = vars.erc4626Form;

            /// @dev 8.1 - Deploy 5115Form implementation
            vars.erc5115Form = address(new BlastERC5115Form{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("ERC5115Form"))] = vars.erc5115Form;
            vars.superRegistryC.setAddress(keccak256("BLAST_REWARD_DISTRIBUTOR_ADMIN"), REWARDS_ADMIN, vars.chainId);
        }

        /// @dev 8.1.1 Deploy 5115 wrapper factory
        vars.erc5115To4626WrapperFactory = address(new ERC5115To4626WrapperFactory{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("ERC5115To4626WrapperFactory"))] = vars.erc5115To4626WrapperFactory;

        /// @dev 9 - Add newly deployed form implementations to Factory,
        /// @notice formImplementationId for ERC4626 form is 1
        /// @notice formImplementationId for ERC5115 form is 3 on prod and 5 on staging
        if (env == 0) {
            ISuperformFactory(vars.factory).addFormImplementation(vars.erc4626Form, FORM_IMPLEMENTATION_IDS[0], 1);
            ISuperformFactory(vars.factory).addFormImplementation(vars.erc5115Form, FORM_IMPLEMENTATION_IDS[1], 1);
        } else {
            ISuperformFactory(vars.factory).addFormImplementation(
                vars.erc4626Form, STAGING_FORM_IMPLEMENTATION_IDS[0], 1
            );
            ISuperformFactory(vars.factory).addFormImplementation(
                vars.erc5115Form, STAGING_FORM_IMPLEMENTATION_IDS[1], 1
            );
        }

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

        console.log("entered here");
        /// @dev 15 - Super Registry extra setters
        /// @dev BASE does not have SocketV1 available
        if (vars.chainId == BASE) {
            uint8[] memory bridgeIdsBase = new uint8[](4);

            /// @dev this is the new id of lifi validator
            bridgeIdsBase[0] = 101;

            /// @dev these are debridge
            bridgeIdsBase[1] = 4;
            bridgeIdsBase[2] = 5;

            /// @dev this is oneinch
            bridgeIdsBase[3] = 6;

            address[] memory bridgeAddressesBase = new address[](4);
            bridgeAddressesBase[0] = BRIDGE_ADDRESSES[vars.chainId][0];

            /// 3 is debridge and 4 is debridge forwarder
            bridgeAddressesBase[1] = BRIDGE_ADDRESSES[vars.chainId][3];
            bridgeAddressesBase[2] = BRIDGE_ADDRESSES[vars.chainId][4];

            /// 5 is 1inch
            bridgeAddressesBase[3] = BRIDGE_ADDRESSES[vars.chainId][5];

            address[] memory bridgeValidatorsBase = new address[](4);
            bridgeValidatorsBase[0] = bridgeValidators[0];
            bridgeValidatorsBase[1] = bridgeValidators[3];
            bridgeValidatorsBase[2] = bridgeValidators[4];
            bridgeValidatorsBase[3] = bridgeValidators[5];

            vars.superRegistryC.setBridgeAddresses(bridgeIdsBase, bridgeAddressesBase, bridgeValidatorsBase);
        } else if (vars.chainId == LINEA) {
            uint8[] memory bridgeIdsLinea = new uint8[](3);

            /// @dev this is the new id of lifi validator
            bridgeIdsLinea[0] = 101;

            /// @dev these are debridge
            bridgeIdsLinea[1] = 5;
            bridgeIdsLinea[2] = 6;

            address[] memory bridgeAddressesLinea = new address[](3);
            bridgeAddressesLinea[0] = BRIDGE_ADDRESSES[vars.chainId][0];

            /// and 4 is debridge and 5 is debridge forwarder
            bridgeAddressesLinea[1] = BRIDGE_ADDRESSES[vars.chainId][3];
            bridgeAddressesLinea[2] = BRIDGE_ADDRESSES[vars.chainId][4];

            address[] memory bridgeValidatorsLinea = new address[](3);
            bridgeValidatorsLinea[0] = bridgeValidators[0];

            bridgeValidatorsLinea[1] = bridgeValidators[3];
            bridgeValidatorsLinea[2] = bridgeValidators[4];

            vars.superRegistryC.setBridgeAddresses(bridgeIdsLinea, bridgeAddressesLinea, bridgeValidatorsLinea);
        } else if (vars.chainId == BLAST) {
            uint8[] memory bridgeIdsBlast = new uint8[](1);

            /// @dev this is the new id of lifi validator
            bridgeIdsBlast[0] = 101;

            address[] memory bridgeAddressesBlast = new address[](1);
            bridgeAddressesBlast[0] = BRIDGE_ADDRESSES[vars.chainId][0];

            address[] memory bridgeValidatorsBlast = new address[](1);
            bridgeValidatorsBlast[0] = bridgeValidators[0];
            vars.superRegistryC.setBridgeAddresses(bridgeIdsBlast, bridgeAddressesBlast, bridgeValidatorsBlast);
        } else {
            vars.superRegistryC.setBridgeAddresses(bridgeIds, BRIDGE_ADDRESSES[vars.chainId], bridgeValidators);
        }

        /// @dev configures ambImplementations to super registry
        if (vars.chainId == FANTOM) {
            uint8[] memory ambIdsFantom = new uint8[](3);
            ambIdsFantom[0] = 1;
            ambIdsFantom[1] = 3;
            ambIdsFantom[2] = 4;

            address[] memory ambAddressesFantom = new address[](3);
            ambAddressesFantom[0] = vars.lzImplementation;
            ambAddressesFantom[1] = vars.wormholeImplementation;
            ambAddressesFantom[2] = vars.wormholeSRImplementation;

            bool[] memory broadcastAMBFantom = new bool[](3);
            broadcastAMBFantom[0] = false;
            broadcastAMBFantom[1] = false;
            broadcastAMBFantom[2] = true;

            SuperRegistry(payable(getContract(vars.chainId, "SuperRegistry"))).setAmbAddress(
                ambIdsFantom, ambAddressesFantom, broadcastAMBFantom
            );
        } else if (vars.chainId == LINEA) {
            uint8[] memory ambIdsLinea = new uint8[](4);
            ambIdsLinea[0] = 5;
            ambIdsLinea[1] = 6;
            ambIdsLinea[2] = 8;
            ambIdsLinea[3] = 9;

            address[] memory ambAddressesLinea = new address[](4);
            ambAddressesLinea[0] = vars.lzImplementation;
            ambAddressesLinea[1] = vars.hyperlaneImplementation;
            ambAddressesLinea[2] = vars.axelarImplementation;
            ambAddressesLinea[3] = vars.lzV1Implementation;

            bool[] memory broadcastAMBLinea = new bool[](4);
            broadcastAMBLinea[0] = false;
            broadcastAMBLinea[1] = false;
            broadcastAMBLinea[2] = false;
            broadcastAMBLinea[3] = false;

            SuperRegistry(payable(getContract(vars.chainId, "SuperRegistry"))).setAmbAddress(
                ambIdsLinea, ambAddressesLinea, broadcastAMBLinea
            );
        } else {
            SuperRegistry(payable(getContract(vars.chainId, "SuperRegistry"))).setAmbAddress(
                ambIds, vars.ambAddresses, broadcastAMB
            );
        }

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

        vars.superRegistryC.setDelay(env == 0 ? 14_400 : 900);

        /// @dev 17 deploy emergency queue
        vars.emergencyQueue = address(new EmergencyQueue{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("EmergencyQueue"))] = vars.emergencyQueue;
        vars.superRegistryC.setAddress(vars.superRegistryC.EMERGENCY_QUEUE(), vars.emergencyQueue, vars.chainId);

        /// @dev 18 deploy vault claimer
        contracts[vars.chainId][bytes32(bytes("VaultClaimer"))] = address(new VaultClaimer{ salt: salt }());

        /// @dev 19 configure payment helper
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

        /// @dev !WARNING - Default value for updateWithdrawGas for now
        PaymentHelper(payable(vars.paymentHelper)).updateRegisterAERC20Params(abi.encode(4, abi.encode(0, "")));

        /// @dev 20 deploy rewards distributor
        vars.rewardsDistributor = address(new RewardsDistributor{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("RewardsDistributor"))] = vars.rewardsDistributor;

        vars.superRegistryC.setAddress(rewardsDistributorId, vars.rewardsDistributor, vars.chainId);

        assert(REWARDS_ADMIN != address(0));

        vars.superRBACC.setRoleAdmin(rewardsAdminRole, vars.superRBACC.PROTOCOL_ADMIN_ROLE());
        vars.superRBACC.grantRole(rewardsAdminRole, REWARDS_ADMIN);

        vm.stopBroadcast();

        /// @dev Exports
        for (uint256 j = 0; j < contractNames.length; j++) {
            _exportContractsV1(
                env, chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }

    /// @dev stage 2 must be called only after stage 1 is complete for all chains!
    function _deployStage2(
        uint256 env,
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

        vars.chainId = targetDeploymentChains[i];

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        vars.lzImplementation = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "LayerzeroImplementation");
        vars.lzV1Implementation =
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "LayerzeroV1Implementation");
        vars.hyperlaneImplementation =
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "HyperlaneImplementation");
        vars.wormholeImplementation =
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "WormholeARImplementation");
        vars.wormholeSRImplementation =
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "WormholeSRImplementation");
        vars.axelarImplementation = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "AxelarImplementation");
        vars.superRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry");
        vars.paymentHelper = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "PaymentHelper");
        vars.superRegistryC = SuperRegistry(vars.superRegistry);

        uint64[] memory remoteChainIds = new uint64[](finalDeployedChains.length - 1);
        uint256 remoteChains;

        for (uint256 j = 0; j < finalDeployedChains.length; j++) {
            if (j != i) {
                remoteChainIds[remoteChains] = finalDeployedChains[j];
                ++remoteChains;
            }
        }

        IPaymentHelper.PaymentHelperConfig[] memory addRemoteConfigs =
            new IPaymentHelper.PaymentHelperConfig[](remoteChainIds.length);

        /// @dev Set all trusted remotes for each chain & configure amb chains ids
        for (uint256 j = 0; j < remoteChainIds.length; j++) {
            addRemoteConfigs[j] = _configureCurrentChainBasedOnTargetDestinations(
                env,
                CurrentChainBasedOnDstvars(
                    vars.chainId,
                    remoteChainIds[j],
                    0,
                    0,
                    0,
                    0,
                    0,
                    "",
                    vars.lzImplementation,
                    vars.lzV1Implementation,
                    vars.hyperlaneImplementation,
                    vars.wormholeImplementation,
                    vars.wormholeSRImplementation,
                    vars.axelarImplementation,
                    vars.superRegistry,
                    vars.paymentHelper,
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    vars.superRegistryC
                ),
                false
            );
        }

        PaymentHelper(payable(vars.paymentHelper)).addRemoteChains(remoteChainIds, addRemoteConfigs);

        vm.stopBroadcast();
    }

    /// @dev pass roles from burner wallets to multi sigs
    function _deployStage3(
        uint256 env,
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

        SuperRBAC srbac = SuperRBAC(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRBAC")));
        bytes32 protocolAdminRole = srbac.PROTOCOL_ADMIN_ROLE();
        bytes32 emergencyAdminRole = srbac.EMERGENCY_ADMIN_ROLE();

        address protocolAdmin = env == 0 ? PROTOCOL_ADMINS[trueIndex] : PROTOCOL_ADMINS_STAGING[trueIndex];

        if (grantProtocolAdmin) {
            if (protocolAdmin != address(0)) {
                srbac.grantRole(protocolAdminRole, protocolAdmin);
            } else {
                revert("PROTOCOL_ADMIN_NOT_SET");
            }
        }

        srbac.grantRole(emergencyAdminRole, EMERGENCY_ADMIN);

        vm.stopBroadcast();
    }

    /// @dev revoke roles from burner wallets
    function _revokeFromBurnerWallets(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
        setEnvDeploy(cycle)
    {
        SetupVars memory vars;

        vars.chainId = s_superFormChainIds[i];

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        SuperRBAC srbac = SuperRBAC(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRBAC")));
        bytes32 protocolAdminRole = srbac.PROTOCOL_ADMIN_ROLE();
        bytes32 emergencyAdminRole = srbac.EMERGENCY_ADMIN_ROLE();
        bytes32 paymentAdminRole = srbac.PAYMENT_ADMIN_ROLE();

        srbac.revokeRole(emergencyAdminRole, ownerAddress);
        srbac.revokeRole(paymentAdminRole, ownerAddress);
        srbac.revokeRole(protocolAdminRole, ownerAddress);

        vm.stopBroadcast();
    }

    /// @dev revoke roles from burner wallets
    function _disableInvalidDeployment(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory targetDeploymentChains
    )
        internal
        setEnvDeploy(cycle)
    {
        SetupVars memory vars;

        vars.chainId = targetDeploymentChains[i];

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        vars.superRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry");
        vars.factory = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperformFactory");
        vars.superRBAC = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRBAC");

        vars.superRegistryC = SuperRegistry(vars.superRegistry);
        vars.superRBACC = SuperRBAC(vars.superRBAC);

        /// @dev pause forms
        SuperformFactory(vars.factory).changeFormImplementationPauseStatus(
            env == 0 ? FORM_IMPLEMENTATION_IDS[0] : STAGING_FORM_IMPLEMENTATION_IDS[0],
            ISuperformFactory.PauseStatus(1),
            ""
        );

        vm.stopBroadcast();
    }

    function _configureGasAmountsOfNewChainInAllChains(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
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

        address paymentHelper = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "PaymentHelper");

        uint256[] memory configTypes = new uint256[](4);
        configTypes[0] = 3;
        configTypes[1] = 4;
        configTypes[2] = 6;
        configTypes[3] = 13;

        bytes[] memory configs = new bytes[](4);
        assert(abi.decode(GAS_USED[newChainId][3], (uint256)) > 0);
        assert(abi.decode(GAS_USED[newChainId][4], (uint256)) > 0);
        assert(abi.decode(GAS_USED[newChainId][6], (uint256)) > 0);
        assert(abi.decode(GAS_USED[newChainId][13], (uint256)) > 0);

        configs[0] = GAS_USED[newChainId][3];
        configs[1] = GAS_USED[newChainId][4];
        configs[2] = GAS_USED[newChainId][6];
        configs[3] = GAS_USED[newChainId][13];

        PaymentHelper(payable(paymentHelper)).batchUpdateRemoteChain(newChainId, configTypes, configs);

        vm.stopBroadcast();
    }

    /// @dev changes the settings in the already deployed chains with the new chain information
    function _configurePreviouslyDeployedChainsWithNewChain(
        uint256 env,
        uint256 i,
        /// 0, 1, 2
        uint256 trueIndex,
        /// 0, 1, 2, 3, 4, 5
        Cycle cycle,
        uint64[] memory previousDeploymentChains,
        uint64 newChainId,
        bool execute
    )
        internal
        setEnvDeploy(cycle)
    {
        SetupVars memory vars;

        vars.chainId = previousDeploymentChains[i];
        bool safeExecution = env == 0 ? true : false;

        if (!safeExecution) {
            cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();
        }

        vars.lzImplementation = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "LayerzeroImplementation");
        vars.lzV1Implementation =
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "LayerzeroV1Implementation");

        vars.hyperlaneImplementation =
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "HyperlaneImplementation");
        vars.wormholeImplementation =
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "WormholeARImplementation");
        vars.wormholeSRImplementation =
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "WormholeSRImplementation");
        vars.axelarImplementation = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "AxelarImplementation");
        vars.superRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry");
        vars.paymentHelper = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "PaymentHelper");
        vars.superRegistryC = SuperRegistry(payable(vars.superRegistry));
        IPaymentHelper.PaymentHelperConfig memory addRemoteConfig = _configureCurrentChainBasedOnTargetDestinations(
            env,
            CurrentChainBasedOnDstvars(
                vars.chainId,
                newChainId,
                0,
                0,
                0,
                0,
                0,
                "",
                vars.lzImplementation,
                vars.lzV1Implementation,
                vars.hyperlaneImplementation,
                vars.wormholeImplementation,
                vars.wormholeSRImplementation,
                vars.axelarImplementation,
                vars.superRegistry,
                vars.paymentHelper,
                address(0),
                address(0),
                address(0),
                address(0),
                address(0),
                address(0),
                vars.superRegistryC
            ),
            safeExecution
        );
        if (!safeExecution) {
            PaymentHelper(payable(vars.paymentHelper)).addRemoteChain(newChainId, addRemoteConfig);
            vm.stopBroadcast();
        } else {
            bytes memory txn =
                abi.encodeWithSelector(PaymentHelper.addRemoteChain.selector, newChainId, addRemoteConfig);
            addToBatch(vars.paymentHelper, 0, txn);

            /// Send to Safe to sign
            executeBatch(
                vars.chainId,
                env == 0 ? PROTOCOL_ADMINS[trueIndex] : PROTOCOL_ADMINS_STAGING[i],
                manualNonces[trueIndex],
                execute
            );
        }
    }

    /// @dev changes the settings in the already deployed chains with the new chain information
    function _configurePreviouslyDeployedChainsWithVaultLimit(
        uint256 env,
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

        vars.superRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry");
        vars.superRegistryC = SuperRegistry(payable(vars.superRegistry));
        vars.superRegistryC.setVaultLimitPerDestination(newChainId, 5);
        vm.stopBroadcast();
    }

    struct CurrentChainBasedOnDstvars {
        uint64 chainId;
        uint64 dstChainId;
        uint256 dstTrueIndex;
        uint32 dstLzChainId;
        uint16 dstLzV1ChainId;
        uint32 dstHypChainId;
        uint16 dstWormholeChainId;
        string dstAxelarChainId;
        address lzImplementation;
        address lzV1Implementation;
        address hyperlaneImplementation;
        address wormholeImplementation;
        address wormholeSRImplementation;
        address axelarImplementation;
        address superRegistry;
        address paymentHelper;
        address dstLzImplementation;
        address dstLzV1Implementation;
        address dstHyperlaneImplementation;
        address dstWormholeARImplementation;
        address dstWormholeSRImplementation;
        address dstAxelarImplementation;
        SuperRegistry superRegistryC;
    }

    function _configureCurrentChainBasedOnTargetDestinations(
        uint256 env,
        CurrentChainBasedOnDstvars memory vars,
        bool safeExecution
    )
        internal
        returns (IPaymentHelper.PaymentHelperConfig memory addRemoteConfig)
    {
        for (uint256 k = 0; k < chainIds.length; k++) {
            if (vars.dstChainId == chainIds[k]) {
                vars.dstTrueIndex = k;

                break;
            }
        }

        vars.dstLzV1ChainId = lz_v1_chainIds[vars.dstTrueIndex];
        vars.dstLzChainId = lz_chainIds[vars.dstTrueIndex];
        vars.dstHypChainId = hyperlane_chainIds[vars.dstTrueIndex];
        vars.dstWormholeChainId = wormhole_chainIds[vars.dstTrueIndex];
        vars.dstAxelarChainId = axelar_chainIds[vars.dstTrueIndex];

        vars.dstLzImplementation =
            _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "LayerzeroImplementation");
        vars.dstLzV1Implementation =
            _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "LayerzeroV1Implementation");
        vars.dstHyperlaneImplementation =
            _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "HyperlaneImplementation");
        vars.dstWormholeARImplementation =
            _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "WormholeARImplementation");
        vars.dstWormholeSRImplementation =
            _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "WormholeSRImplementation");
        vars.dstAxelarImplementation =
            _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "AxelarImplementation");

        assert(abi.decode(GAS_USED[vars.dstChainId][3], (uint256)) > 0);
        assert(abi.decode(GAS_USED[vars.dstChainId][4], (uint256)) > 0);
        assert(abi.decode(GAS_USED[vars.dstChainId][6], (uint256)) > 0);
        assert(abi.decode(GAS_USED[vars.dstChainId][13], (uint256)) > 0);

        addRemoteConfig = IPaymentHelper.PaymentHelperConfig(
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
            10_000,
            abi.decode(GAS_USED[vars.dstChainId][13], (uint256))
        );

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
        //ids[18] = rewardsDistributorId;

        address[] memory newAddresses = new address[](18);
        newAddresses[0] = _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "SuperformRouter");
        newAddresses[1] = _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "SuperformFactory");
        newAddresses[2] = _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "PayMaster");
        newAddresses[3] = _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "PaymentHelper");
        newAddresses[4] = _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "CoreStateRegistry");
        newAddresses[5] = _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "DstSwapper");
        newAddresses[6] = _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "SuperPositions");
        newAddresses[7] = _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "SuperRBAC");
        newAddresses[8] = _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "PayloadHelper");
        newAddresses[9] = _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "EmergencyQueue");
        newAddresses[10] = PAYMENT_ADMIN;
        newAddresses[11] = CSR_PROCESSOR;
        newAddresses[12] = CSR_UPDATER;
        newAddresses[13] = BROADCAST_REGISTRY_PROCESSOR;
        newAddresses[14] = CSR_RESCUER;
        newAddresses[15] = CSR_DISPUTER;
        newAddresses[16] = DST_SWAPPER;
        newAddresses[17] = SUPERFORM_RECEIVER;
        //newAddresses[18] = _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId,
        // "RewardsDistributor");

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
        //chainIdsSetAddresses[18] = vars.dstChainId;

        if (!safeExecution) {
            LayerzeroV2Implementation(payable(vars.lzImplementation)).setPeer(
                vars.dstLzChainId, bytes32(uint256(uint160(vars.dstLzImplementation)))
            );

            LayerzeroV2Implementation(payable(vars.lzImplementation)).setChainId(vars.dstChainId, vars.dstLzChainId);

            LayerzeroImplementation(payable(vars.lzV1Implementation)).setTrustedRemote(
                vars.dstLzV1ChainId, abi.encodePacked(vars.dstLzV1Implementation, vars.lzV1Implementation)
            );

            LayerzeroImplementation(payable(vars.lzV1Implementation)).setChainId(vars.dstChainId, vars.dstLzV1ChainId);

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
            if (!(vars.chainId == FANTOM || vars.dstChainId == FANTOM)) {
                HyperlaneImplementation(payable(vars.hyperlaneImplementation)).setReceiver(
                    vars.dstHypChainId, vars.dstHyperlaneImplementation
                );

                HyperlaneImplementation(payable(vars.hyperlaneImplementation)).setChainId(
                    vars.dstChainId, vars.dstHypChainId
                );
            }

            if (!(vars.chainId == LINEA || vars.dstChainId == LINEA)) {
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
            }

            AxelarImplementation(payable(vars.axelarImplementation)).setChainId(vars.dstChainId, vars.dstAxelarChainId);

            AxelarImplementation(payable(vars.axelarImplementation)).setReceiver(
                vars.dstAxelarChainId, vars.dstAxelarImplementation
            );

            SuperRegistry(payable(vars.superRegistry)).setRequiredMessagingQuorum(vars.dstChainId, 1);

            vars.superRegistryC.batchSetAddress(ids, newAddresses, chainIdsSetAddresses);
        } else {
            bytes memory txn = abi.encodeWithSelector(
                LayerzeroV2Implementation.setPeer.selector,
                vars.dstLzChainId,
                bytes32(uint256(uint160(vars.dstLzImplementation)))
            );
            addToBatch(vars.lzImplementation, 0, txn);

            txn = abi.encodeWithSelector(
                LayerzeroV2Implementation.setChainId.selector, vars.dstChainId, vars.dstLzChainId
            );
            addToBatch(vars.lzImplementation, 0, txn);

            txn = abi.encodeWithSelector(
                LayerzeroImplementation.setTrustedRemote.selector,
                vars.dstLzV1ChainId,
                abi.encodePacked(vars.dstLzV1Implementation, vars.lzV1Implementation)
            );
            addToBatch(vars.lzV1Implementation, 0, txn);

            txn = abi.encodeWithSelector(
                LayerzeroImplementation.setChainId.selector, vars.dstChainId, vars.dstLzV1ChainId
            );
            addToBatch(vars.lzV1Implementation, 0, txn);

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
            if (!(vars.chainId == FANTOM || vars.dstChainId == FANTOM)) {
                txn = abi.encodeWithSelector(
                    HyperlaneImplementation.setReceiver.selector, vars.dstHypChainId, vars.dstHyperlaneImplementation
                );
                addToBatch(vars.hyperlaneImplementation, 0, txn);

                txn = abi.encodeWithSelector(
                    HyperlaneImplementation.setChainId.selector, vars.dstChainId, vars.dstHypChainId
                );
                addToBatch(vars.hyperlaneImplementation, 0, txn);
            }

            if (!(vars.chainId == LINEA || vars.dstChainId == LINEA)) {
                txn = abi.encodeWithSelector(
                    WormholeARImplementation.setReceiver.selector,
                    vars.dstWormholeChainId,
                    vars.dstWormholeARImplementation
                );
                addToBatch(vars.wormholeImplementation, 0, txn);

                txn = abi.encodeWithSelector(
                    WormholeARImplementation.setChainId.selector, vars.dstChainId, vars.dstWormholeChainId
                );
                addToBatch(vars.wormholeImplementation, 0, txn);

                txn = abi.encodeWithSelector(
                    WormholeSRImplementation.setChainId.selector, vars.dstChainId, vars.dstWormholeChainId
                );
                addToBatch(vars.wormholeSRImplementation, 0, txn);

                txn = abi.encodeWithSelector(
                    WormholeSRImplementation.setReceiver.selector,
                    vars.dstWormholeChainId,
                    vars.dstWormholeSRImplementation
                );
                addToBatch(vars.wormholeSRImplementation, 0, txn);
            }

            txn = abi.encodeWithSelector(SuperRegistry.setRequiredMessagingQuorum.selector, vars.dstChainId, 1);
            addToBatch(vars.superRegistry, 0, txn);

            txn = abi.encodeWithSelector(
                vars.superRegistryC.batchSetAddress.selector, ids, newAddresses, chainIdsSetAddresses
            );
            addToBatch(vars.superRegistry, 0, txn);
        }
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
        gasUsed[FANTOM][3] = abi.encode(643_315);
        gasUsed[LINEA][3] = abi.encode(600_000);
        gasUsed[BLAST][3] = abi.encode(600_000);

        // updateDepositGasUsed == 4 (only used on deposits for now)
        gasUsed[ETH][4] = abi.encode(225_000);
        gasUsed[BSC][4] = abi.encode(225_000);
        gasUsed[AVAX][4] = abi.encode(200_000);
        gasUsed[POLY][4] = abi.encode(200_000);
        gasUsed[OP][4] = abi.encode(200_000);
        gasUsed[ARBI][4] = abi.encode(1_400_000);
        gasUsed[BASE][4] = abi.encode(200_000);
        gasUsed[FANTOM][4] = abi.encode(734_757);
        gasUsed[LINEA][4] = abi.encode(200_000);
        gasUsed[BLAST][4] = abi.encode(200_000);

        // withdrawGasUsed == 6
        gasUsed[ETH][6] = abi.encode(1_272_330);
        gasUsed[BSC][6] = abi.encode(837_167);
        gasUsed[AVAX][6] = abi.encode(1_494_028);
        gasUsed[POLY][6] = abi.encode(1_119_242);
        gasUsed[OP][6] = abi.encode(1_716_146);
        gasUsed[ARBI][6] = abi.encode(1_654_955);
        gasUsed[BASE][6] = abi.encode(1_178_778);
        gasUsed[FANTOM][6] = abi.encode(567_881);
        gasUsed[LINEA][6] = abi.encode(1_178_778);
        gasUsed[BLAST][6] = abi.encode(1_178_778);

        // updateWithdrawGasUsed == 13
        /*
        2049183 / 1.5 = 1366122 ARB
        535243 / 1.5 = 356828  MAINNET
        973861 / 1.5 = 649240 OP
        901119  / 1.5 = 600746 AVAX
        896967 / 1.5 = 597978 MATIC
        1350127 / 1.5 = 900085 BSC
        1379199 / 1.5 = 919466 BASE
        */

        gasUsed[ETH][13] = abi.encode(356_828);
        gasUsed[BSC][13] = abi.encode(900_085);
        gasUsed[AVAX][13] = abi.encode(600_746);
        gasUsed[POLY][13] = abi.encode(597_978);
        gasUsed[OP][13] = abi.encode(649_240);
        gasUsed[ARBI][13] = abi.encode(1_366_122);
        gasUsed[BASE][13] = abi.encode(919_466);
        gasUsed[FANTOM][13] = abi.encode(2_003_157);
        gasUsed[LINEA][13] = abi.encode(919_466);
        gasUsed[BLAST][13] = abi.encode(919_466);

        mapping(uint64 chainId => address[] bridgeAddresses) storage bridgeAddresses = BRIDGE_ADDRESSES;
        bridgeAddresses[ETH] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0x2ddf16BA6d0180e5357d5e170eF1917a01b41fc0,
            0x111111125421cA6dc452d289314280a0f8842A65,
            0xeF4fB24aD0916217251F553c0596F8Edc630EB66,
            0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251
        ];

        bridgeAddresses[BSC] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0xd286595d2e3D879596FAB51f83A702D10a6db27b,
            0x111111125421cA6dc452d289314280a0f8842A65,
            0xeF4fB24aD0916217251F553c0596F8Edc630EB66,
            0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251
        ];
        bridgeAddresses[AVAX] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0xbDf50eAe568ECef74796ed6022a0d453e8432410,
            0x111111125421cA6dc452d289314280a0f8842A65,
            0xeF4fB24aD0916217251F553c0596F8Edc630EB66,
            0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251
        ];
        bridgeAddresses[POLY] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0x2ddf16BA6d0180e5357d5e170eF1917a01b41fc0,
            0x111111125421cA6dc452d289314280a0f8842A65,
            0xeF4fB24aD0916217251F553c0596F8Edc630EB66,
            0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251
        ];
        bridgeAddresses[ARBI] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0xaa3d9fA3aB930aE635b001d00C612aa5b14d750e,
            0x111111125421cA6dc452d289314280a0f8842A65,
            0xeF4fB24aD0916217251F553c0596F8Edc630EB66,
            0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251
        ];
        bridgeAddresses[OP] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0xbDf50eAe568ECef74796ed6022a0d453e8432410,
            0x111111125421cA6dc452d289314280a0f8842A65,
            0xeF4fB24aD0916217251F553c0596F8Edc630EB66,
            0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251
        ];
        bridgeAddresses[BASE] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            address(0),
            0x111111125421cA6dc452d289314280a0f8842A65,
            0xeF4fB24aD0916217251F553c0596F8Edc630EB66,
            0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251
        ];
        bridgeAddresses[FANTOM] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0x565810cbfa3Cf1390963E5aFa2fB953795686339,
            0x111111125421cA6dc452d289314280a0f8842A65,
            0xeF4fB24aD0916217251F553c0596F8Edc630EB66,
            0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251
        ];
        bridgeAddresses[LINEA] = [
            0xDE1E598b81620773454588B85D6b5D4eEC32573e,
            address(0),
            address(0),
            0xeF4fB24aD0916217251F553c0596F8Edc630EB66,
            0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251
        ];
        bridgeAddresses[BLAST] =
            [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE, address(0), address(0), address(0), address(0)];

        /// price feeds on all chains
        mapping(uint64 => mapping(uint64 => address)) storage priceFeeds = PRICE_FEEDS;
        /// https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1

        /// ETH
        priceFeeds[ETH][ETH] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][BSC] = 0x14e613AC84a31f709eadbdF89C6CC390fDc9540A;
        priceFeeds[ETH][AVAX] = 0xFF3EEb22B5E3dE6e705b44749C2559d704923FD7;
        priceFeeds[ETH][POLY] = 0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676;
        priceFeeds[ETH][OP] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][ARBI] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][BASE] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][FANTOM] = address(0);
        // 0x2DE7E4a9488488e0058B95854CC2f7955B35dC9b has 18 decimals which looks incorrect
        priceFeeds[ETH][LINEA] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][BLAST] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

        /// BSC
        priceFeeds[BSC][BSC] = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        priceFeeds[BSC][ETH] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][AVAX] = 0x5974855ce31EE8E1fff2e76591CbF83D7110F151;
        priceFeeds[BSC][POLY] = 0x7CA57b0cA6367191c94C8914d7Df09A57655905f;
        priceFeeds[BSC][OP] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][ARBI] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][BASE] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][FANTOM] = 0xe2A47e87C0f4134c8D06A41975F6860468b2F925;
        priceFeeds[BSC][LINEA] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][BLAST] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;

        /// AVAX
        priceFeeds[AVAX][AVAX] = 0x0A77230d17318075983913bC2145DB16C7366156;
        priceFeeds[AVAX][BSC] = address(0);
        priceFeeds[AVAX][ETH] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][POLY] = 0x1db18D41E4AD2403d9f52b5624031a2D9932Fd73;
        priceFeeds[AVAX][OP] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][ARBI] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][BASE] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][FANTOM] = 0x2dD517B2f9ba49CedB0573131FD97a5AC19ff648;
        priceFeeds[AVAX][LINEA] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][BLAST] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;

        /// POLYGON
        priceFeeds[POLY][POLY] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        priceFeeds[POLY][AVAX] = 0xe01eA2fbd8D76ee323FbEd03eB9a8625EC981A10;
        priceFeeds[POLY][BSC] = 0x82a6c4AF830caa6c97bb504425f6A66165C2c26e;
        priceFeeds[POLY][ETH] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][OP] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][ARBI] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][BASE] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][FANTOM] = 0x58326c0F831b2Dbf7234A4204F28Bba79AA06d5f;
        priceFeeds[POLY][LINEA] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][BLAST] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;

        /// OPTIMISM
        priceFeeds[OP][OP] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][POLY] = 0x0ded608AFc23724f614B76955bbd9dFe7dDdc828;
        priceFeeds[OP][AVAX] = 0x5087Dc69Fd3907a016BD42B38022F7f024140727;
        priceFeeds[OP][BSC] = 0xD38579f7cBD14c22cF1997575eA8eF7bfe62ca2c;
        priceFeeds[OP][ETH] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][ARBI] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][BASE] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][FANTOM] = 0xc19d58652d6BfC6Db6FB3691eDA6Aa7f3379E4E9;
        priceFeeds[OP][LINEA] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][BLAST] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;

        /// ARBITRUM
        priceFeeds[ARBI][ARBI] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][OP] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][POLY] = 0x52099D4523531f678Dfc568a7B1e5038aadcE1d6;
        priceFeeds[ARBI][AVAX] = 0x8bf61728eeDCE2F32c456454d87B5d6eD6150208;
        priceFeeds[ARBI][BSC] = 0x6970460aabF80C5BE983C6b74e5D06dEDCA95D4A;
        priceFeeds[ARBI][ETH] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][BASE] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][FANTOM] = 0xFeaC1A3936514746e70170c0f539e70b23d36F19;
        priceFeeds[ARBI][LINEA] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][BLAST] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;

        /// BASE
        priceFeeds[BASE][BASE] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][OP] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][POLY] = 0x12129aAC52D6B0f0125677D4E1435633E61fD25f;
        priceFeeds[BASE][AVAX] = 0xE70f2D34Fd04046aaEC26a198A35dD8F2dF5cd92;
        priceFeeds[BASE][BSC] = 0x4b7836916781CAAfbb7Bd1E5FDd20ED544B453b1;
        priceFeeds[BASE][ETH] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][ARBI] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][FANTOM] = address(0);
        priceFeeds[BASE][LINEA] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][BLAST] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;

        /// FANTOM
        priceFeeds[FANTOM][FANTOM] = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc;
        priceFeeds[FANTOM][OP] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][POLY] = address(0);
        priceFeeds[FANTOM][AVAX] = address(0);
        priceFeeds[FANTOM][BSC] = 0x6dE70f4791C4151E00aD02e969bD900DC961f92a;
        priceFeeds[FANTOM][ETH] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][BASE] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][ARBI] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][LINEA] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][BLAST] = 0x11DdD3d147E5b83D01cee7070027092397d63658;

        /// LINEA
        priceFeeds[LINEA][LINEA] = 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA;
        priceFeeds[LINEA][OP] = 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA;
        priceFeeds[LINEA][POLY] = 0x9ce4473B42a639d010eD741df3CA829E6e480803;
        priceFeeds[LINEA][AVAX] = 0xD86d65fb17B5E0ee7152da12b4A4D31Bf5f4fDe9;
        priceFeeds[LINEA][BSC] = 0x09E929D57969D8B996a62ee176Df214D87565bDE;
        priceFeeds[LINEA][ETH] = 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA;
        priceFeeds[LINEA][BASE] = 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA;
        priceFeeds[LINEA][ARBI] = 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA;
        priceFeeds[LINEA][FANTOM] = 0xA40819f13aece3D0C8375522bF44DCC30290f655;
        priceFeeds[LINEA][BLAST] = 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA;

        /// BLAST
        priceFeeds[BLAST][LINEA] = 0x4AB67C7e24d94bd70502c44051274195215d8071;
        priceFeeds[BLAST][OP] = 0x4AB67C7e24d94bd70502c44051274195215d8071;
        priceFeeds[BLAST][POLY] = 0x4ebFA571bEF94Bd1292eA27EcCD958812986129d;
        priceFeeds[BLAST][AVAX] = 0x057C39FD71b74F5f31992eB9865D36fb630ab2ac;
        priceFeeds[BLAST][BSC] = 0x372b09083afDA47463022f8Cfb5dBFE186f2c13b;
        priceFeeds[BLAST][ETH] = 0x4AB67C7e24d94bd70502c44051274195215d8071;
        priceFeeds[BLAST][BASE] = 0x4AB67C7e24d94bd70502c44051274195215d8071;
        priceFeeds[BLAST][ARBI] = 0x4AB67C7e24d94bd70502c44051274195215d8071;
        priceFeeds[BLAST][FANTOM] = 0xde79aFAE86CAF94775f0388a15fC51059374f570;
        priceFeeds[BLAST][BLAST] = 0x4AB67C7e24d94bd70502c44051274195215d8071;
    }

    /// @dev use this function for full deployments
    function _exportContractsV1(
        uint256 env,
        string memory name,
        string memory label,
        address addr,
        uint64 chainId
    )
        internal
    {
        string memory json = vm.serializeAddress("EXPORTS", label, addr);
        string memory root = vm.projectRoot();
        string memory chainOutputFolder;
        if (env == 0) {
            chainOutputFolder =
                string(abi.encodePacked("/script/deployments/v1_", "deployment/", vm.toString(uint256(chainId)), "/"));
        } else if (env == 1) {
            chainOutputFolder = string(
                abi.encodePacked("/script/deployments/v1_", "staging_deployment/", vm.toString(uint256(chainId)), "/")
            );
        } else if (env == 2) {
            chainOutputFolder = string(abi.encodePacked("/script/output/", vm.toString(uint256(chainId)), "/"));
        } else {
            revert("Invalid Env");
        }

        if (vm.envOr("FOUNDRY_EXPORTS_OVERWRITE_LATEST", false)) {
            vm.writeJson(json, string(abi.encodePacked(root, chainOutputFolder, name, "-latest.json")));
        } else {
            vm.writeJson(
                json,
                string(abi.encodePacked(root, chainOutputFolder, name, "-", vm.toString(block.timestamp), ".json"))
            );
        }
    }

    /// @dev use this function for single file deployments and config changes (one off)
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

    function _readContractsV1(
        uint256 env,
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
        if (env == 0) {
            json = string(
                abi.encodePacked(
                    root,
                    "/script/deployments/v1_",
                    "deployment/",
                    vm.toString(uint256(chainId)),
                    "/",
                    name,
                    "-latest.json"
                )
            );
        } else if (env == 1) {
            json = string(
                abi.encodePacked(
                    root,
                    "/script/deployments/v1_",
                    "staging_deployment/",
                    vm.toString(uint256(chainId)),
                    "/",
                    name,
                    "-latest.json"
                )
            );
        } else if (env == 2) {
            json = string(
                abi.encodePacked(root, "/script/output/", vm.toString(uint256(chainId)), "/", name, "-latest.json")
            );
        } else {
            revert("Invalid Env");
        }

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

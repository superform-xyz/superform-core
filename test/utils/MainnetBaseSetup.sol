// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @dev lib imports
import "forge-std/Test.sol";
import "ds-test/test.sol";
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

import "./TestTypes.sol";

abstract contract MainnetBaseSetup is DSTest, StdInvariant, Test {
    /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
    //////////////////////////////////////////////////////////////*/

    string public folderToRead;
    uint64[] TARGET_DEPLOYMENT_CHAINS;
    address public constant CANONICAL_PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    mapping(uint64 chainId => mapping(bytes32 implementation => address at)) public contracts;

    string[20] public contractNames = [
        "CoreStateRegistry",
        //"TimelockStateRegistry",
        "BroadcastRegistry",
        "LayerzeroImplementation",
        "HyperlaneImplementation",
        "WormholeARImplementation",
        "WormholeSRImplementation",
        "LiFiValidator",
        "SocketValidator",
        //"SocketOneInchValidator",
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

    enum Cycle {
        Dev,
        Prod
    }

    string public ETHEREUM_RPC_URL = vm.envString("ETHEREUM_RPC_URL"); // Native token: ETH
    string public BSC_RPC_URL = vm.envString("BSC_RPC_URL"); // Native token: BNB
    string public AVALANCHE_RPC_URL = vm.envString("AVALANCHE_RPC_URL"); // Native token: AVAX
    string public POLYGON_RPC_URL = vm.envString("POLYGON_RPC_URL"); // Native token: MATIC
    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL"); // Native token: ETH
    string public OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC_URL"); // Native token: ETH
    string public BASE_RPC_URL = vm.envString("BASE_RPC_URL"); // Native token: ETH

    mapping(uint64 chainId => uint256 fork) public FORKS;
    mapping(uint64 chainId => string forkUrl) public RPC_URLS;

    /*//////////////////////////////////////////////////////////////
                        PROTOCOL VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev 1 = ERC4626Form, 2 = ERC4626TimelockForm, 3 = KYCDaoForm
    uint32[] public FORM_IMPLEMENTATION_IDS = [uint32(1), uint32(2), uint32(3)];
    string[] public VAULT_KINDS = ["Vault", "TimelockedVault", "KYCDaoVault"];

    /// @dev liquidity bridge ids 1 is lifi, 2 is socket, 3 is socket one inch implementation (not added to this
    /// release)
    uint8[] public bridgeIds = [1, 2];

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
    address public constant GNOSIS_lzEndpoint = 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4;

    address public constant CHAINLINK_lzOracle = 0x150A58e9E6BF69ccEb1DBA5ae97C166DC8792539;

    address[] public lzEndpoints = [
        0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7,
        0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4
    ];

    address[] public hyperlaneMailboxes = [
        0xc005dc82818d67AF737725bD4bf75435d065D239,
        0x2971b9Aec44bE4eb673DF1B88cDB57b96eefe8a4,
        0xFf06aFcaABaDDd1fb08371f9ccA15D73D51FeBD6,
        0x5d934f4e2f797775e53561bB72aca21ba36B96BB,
        0x979Ca5202784112f4738403dBec5D0F3B9daabB9,
        0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D,
        0xeA87ae93Fa0019a82A727bfd3eBd1cFCa8f64f1D,
        0xaD09d78f4c6b9dA2Ae82b1D34107802d380Bb74f
    ];

    address[] public hyperlanePaymasters = [
        0x9e6B1022bE9BBF5aFd152483DAD9b88911bC8611,
        0x78E25e7f84416e69b9339B0A6336EB6EFfF6b451,
        0x95519ba800BBd0d34eeAE026fEc620AD978176C0,
        0x0071740Bf129b05C4684abfbBeD248D80971cce2,
        0x3b6044acd6767f017e99318AA6Ef93b7B06A5a22,
        0xD8A76C4D91fCbB7Cc8eA795DFDF870E48368995C,
        0xc3F23848Ed2e04C0c6d41bd7804fa8f89F940B94,
        0xDd260B99d302f0A3fF885728c086f729c06f227f
    ];

    address[] public wormholeCore = [
        0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B,
        0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B,
        0x54a8e5f9c4CbA08F9943965859F6c34eAF03E26c,
        0x7A4B5a56256163F07b2C80A7cA55aBE66c4ec4d7,
        0xa5f208e072434bC67592E4C49C1B991BA79BCA46,
        0xEe91C335eab126dF5fDB3797EA9d6aD93aeC9722,
        0xbebdb6C8ddC678FfA9f8748f85C815C556Dd8ac6,
        0xa321448d90d4e5b0A732867c18eA198e75CAC48E
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
    uint64 public constant GNOSIS = 100;

    uint64[] public chainIds = [1, 56, 43_114, 137, 42_161, 10, 8453, 100];
    string[] public chainNames =
        ["Ethereum", "Binance", "Avalanche", "Polygon", "Arbitrum", "Optimism", "Base", "Gnosis"];

    /// @dev vendor chain ids
    uint16[] public lz_chainIds = [101, 102, 106, 109, 110, 111, 184, 145];
    uint32[] public hyperlane_chainIds = [1, 56, 43_114, 137, 42_161, 10, 8453, 100];
    uint16[] public wormhole_chainIds = [2, 4, 6, 5, 23, 24, 30, 25];

    uint256 public constant milionTokensE18 = 1 ether;

    /// @dev check https://api-utils.superform.xyz/docs#/Utils/get_gas_prices_gwei_gas_get
    uint256[] public gasPrices = [
        50_000_000_000, // ETH
        3_000_000_000, // BSC
        25_000_000_000, // AVAX
        50_000_000_000, // POLY
        100_000_000, // ARBI
        4_000_000, // OP
        1_000_000, // BASE
        4 * 10e9 // GNOSIS
    ];

    /// @dev check https://api-utils.superform.xyz/docs#/Utils/get_native_prices_chainlink_native_get
    uint256[] public nativePrices = [
        253_400_000_000, // ETH
        31_439_000_000, // BSC
        3_529_999_999, // AVAX
        81_216_600, // POLY
        253_400_000_000, // ARBI
        253_400_000_000, // OP
        253_400_000_000, // BASE
        4 * 10e9 // GNOSIS
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

    address public EMERGENCY_ADMIN = 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490;

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
        /// @dev GNOSIS FIXME - PROTOCOL ADMIN NOT SET FOR GNOSIS
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

    function getContract(uint64 chainId, string memory _name) public view returns (address) {
        return contracts[chainId][bytes32(bytes(_name))];
    }

    function setUp() public virtual {
        _preDeploymentSetup();

        for (uint256 j = 0; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
            uint256 trueIndex;
            for (uint256 i = 0; i < chainIds.length; i++) {
                if (TARGET_DEPLOYMENT_CHAINS[j] == chainIds[i]) {
                    trueIndex = i;

                    break;
                }
            }

            _grabAddresses(j, trueIndex, Cycle.Prod, TARGET_DEPLOYMENT_CHAINS);
        }
    }

    function _grabAddresses(
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory targetDeploymentChains
    )
        internal
        setEnvDeploy(cycle)
    {
        uint64 chainId = targetDeploymentChains[i];

        /// @dev 1 -  SuperRBAC
        contracts[chainId][bytes32(bytes("SuperRBAC"))] = _readContract(chainNames[trueIndex], chainId, "SuperRBAC");

        /// @dev 2 -  SuperRegistry
        contracts[chainId][bytes32(bytes("SuperRegistry"))] =
            _readContract(chainNames[trueIndex], chainId, "SuperRegistry");

        /// @dev 2.1 - Core State Registry
        contracts[chainId][bytes32(bytes("CoreStateRegistry"))] =
            _readContract(chainNames[trueIndex], chainId, "CoreStateRegistry");

        /// @dev 2,2 - Broadcast State Registry
        contracts[chainId][bytes32(bytes("BroadcastRegistry"))] =
            _readContract(chainNames[trueIndex], chainId, "BroadcastRegistry");

        /// @dev 3- Payment Helper
        contracts[chainId][bytes32(bytes("PaymentHelper"))] =
            _readContract(chainNames[trueIndex], chainId, "PaymentHelper");

        /// @dev 4.1-  Layerzero Implementation
        contracts[chainId][bytes32(bytes("LayerzeroImplementation"))] =
            _readContract(chainNames[trueIndex], chainId, "LayerzeroImplementation");

        /// @dev 4.2-  Hyperlane Implementation
        contracts[chainId][bytes32(bytes("HyperlaneImplementation"))] =
            _readContract(chainNames[trueIndex], chainId, "HyperlaneImplementation");

        /// @dev 4.3-  Wormhole Automatic Relayer Implementation
        contracts[chainId][bytes32(bytes("WormholeARImplementation"))] =
            _readContract(chainNames[trueIndex], chainId, "WormholeARImplementation");

        /// @dev 4.4-  Wormhole Specialized Relayer Implementation
        contracts[chainId][bytes32(bytes("WormholeSRImplementation"))] =
            _readContract(chainNames[trueIndex], chainId, "WormholeSRImplementation");

        /// @dev 5-  liquidity validators
        contracts[chainId][bytes32(bytes("LiFiValidator"))] =
            _readContract(chainNames[trueIndex], chainId, "LiFiValidator");

        contracts[chainId][bytes32(bytes("SocketValidator"))] =
            _readContract(chainNames[trueIndex], chainId, "SocketValidator");

        /// @dev 6 -  SuperformFactory
        contracts[chainId][bytes32(bytes("SuperformFactory"))] =
            _readContract(chainNames[trueIndex], chainId, "SuperformFactory");

        /// @dev 7 -  4626Form implementations
        // Standard ERC4626 Form
        contracts[chainId][bytes32(bytes("ERC4626Form"))] = _readContract(chainNames[trueIndex], chainId, "ERC4626Form");

        /// @dev 8 -  SuperformRouter
        contracts[chainId][bytes32(bytes("SuperformRouter"))] =
            _readContract(chainNames[trueIndex], chainId, "SuperformRouter");

        /// @dev 9 -  SuperPositions
        contracts[chainId][bytes32(bytes("SuperPositions"))] =
            _readContract(chainNames[trueIndex], chainId, "SuperPositions");

        /// @dev 10 -  Payload Helper
        contracts[chainId][bytes32(bytes("PayloadHelper"))] =
            _readContract(chainNames[trueIndex], chainId, "PayloadHelper");

        /// @dev 11 -  PayMaster
        contracts[chainId][bytes32(bytes32("PayMaster"))] = _readContract(chainNames[trueIndex], chainId, "PayMaster");

        /// @dev 12 -  Dst Swapper
        contracts[chainId][bytes32(bytes("DstSwapper"))] = _readContract(chainNames[trueIndex], chainId, "DstSwapper");

        /// @dev 13  emergency queue
        contracts[chainId][bytes32(bytes("EmergencyQueue"))] =
            _readContract(chainNames[trueIndex], chainId, "EmergencyQueue");

        /// @dev 14  vault claimer
        contracts[chainId][bytes32(bytes("VaultClaimer"))] =
            _readContract(chainNames[trueIndex], chainId, "VaultClaimer");
    }

    function _preDeploymentSetup() internal {
        mapping(uint64 => uint256) storage forks = FORKS;
        forks[ETH] = vm.createFork(ETHEREUM_RPC_URL);
        forks[BSC] = vm.createFork(BSC_RPC_URL);
        forks[AVAX] = vm.createFork(AVALANCHE_RPC_URL);
        forks[POLY] = vm.createFork(POLYGON_RPC_URL);
        forks[ARBI] = vm.createFork(ARBITRUM_RPC_URL);
        forks[OP] = vm.createFork(OPTIMISM_RPC_URL);
        forks[BASE] = vm.createFork(BASE_RPC_URL);

        mapping(uint64 => string) storage rpcURLs = RPC_URLS;
        rpcURLs[ETH] = ETHEREUM_RPC_URL;
        rpcURLs[BSC] = BSC_RPC_URL;
        rpcURLs[AVAX] = AVALANCHE_RPC_URL;
        rpcURLs[POLY] = POLYGON_RPC_URL;
        rpcURLs[ARBI] = ARBITRUM_RPC_URL;
        rpcURLs[OP] = OPTIMISM_RPC_URL;
        rpcURLs[BASE] = BASE_RPC_URL;

        mapping(uint64 => address) storage lzEndpointsStorage = LZ_ENDPOINTS;
        lzEndpointsStorage[ETH] = ETH_lzEndpoint;
        lzEndpointsStorage[BSC] = BSC_lzEndpoint;
        lzEndpointsStorage[AVAX] = AVAX_lzEndpoint;
        lzEndpointsStorage[POLY] = POLY_lzEndpoint;
        lzEndpointsStorage[ARBI] = ARBI_lzEndpoint;
        lzEndpointsStorage[OP] = OP_lzEndpoint;
        lzEndpointsStorage[BASE] = BASE_lzEndpoint;
        lzEndpointsStorage[GNOSIS] = GNOSIS_lzEndpoint;

        mapping(uint64 chainId => address[] bridgeAddresses) storage bridgeAddresses = BRIDGE_ADDRESSES;
        bridgeAddresses[ETH] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE, 0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0
        //0x2ddf16BA6d0180e5357d5e170eF1917a01b41fc0
        ];
        bridgeAddresses[BSC] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE, 0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0
        //0xd286595d2e3D879596FAB51f83A702D10a6db27b
        ];
        bridgeAddresses[AVAX] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE, 0x2b42AFFD4b7C14d9B7C2579229495c052672Ccd3
        //0xbDf50eAe568ECef74796ed6022a0d453e8432410
        ];
        bridgeAddresses[POLY] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE, 0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0
        //0x2ddf16BA6d0180e5357d5e170eF1917a01b41fc0
        ];
        bridgeAddresses[ARBI] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE, 0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0
        //0xaa3d9fA3aB930aE635b001d00C612aa5b14d750e
        ];
        bridgeAddresses[OP] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE, 0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0
        //0xbDf50eAe568ECef74796ed6022a0d453e8432410
        ];
        bridgeAddresses[BASE] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE, address(0)];
        bridgeAddresses[GNOSIS] = [
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0
            //0x565810cbfa3Cf1390963E5aFa2fB953795686339
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
        priceFeeds[ETH][GNOSIS] = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;

        /// BSC
        priceFeeds[BSC][BSC] = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        priceFeeds[BSC][ETH] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][AVAX] = address(0);
        priceFeeds[BSC][POLY] = 0x7CA57b0cA6367191c94C8914d7Df09A57655905f;
        priceFeeds[BSC][OP] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][ARBI] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][BASE] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][GNOSIS] = 0x132d3C0B1D2cEa0BC552588063bdBb210FDeecfA;

        /// AVAX
        priceFeeds[AVAX][AVAX] = 0x0A77230d17318075983913bC2145DB16C7366156;
        priceFeeds[AVAX][BSC] = address(0);
        priceFeeds[AVAX][ETH] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][POLY] = address(0);
        priceFeeds[AVAX][OP] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][ARBI] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][BASE] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][GNOSIS] = 0x51D7180edA2260cc4F6e4EebB82FEF5c3c2B8300;

        /// POLYGON
        priceFeeds[POLY][POLY] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        priceFeeds[POLY][AVAX] = address(0);
        priceFeeds[POLY][BSC] = 0x82a6c4AF830caa6c97bb504425f6A66165C2c26e;
        priceFeeds[POLY][ETH] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][OP] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][ARBI] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][BASE] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][GNOSIS] = 0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D;

        /// OPTIMISM
        priceFeeds[OP][OP] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][POLY] = address(0);
        priceFeeds[OP][AVAX] = address(0);
        priceFeeds[OP][BSC] = address(0);
        priceFeeds[OP][ETH] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][ARBI] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][BASE] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][GNOSIS] = 0x8dBa75e83DA73cc766A7e5a0ee71F656BAb470d6;

        /// ARBITRUM
        priceFeeds[ARBI][ARBI] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][OP] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][POLY] = 0x52099D4523531f678Dfc568a7B1e5038aadcE1d6;
        priceFeeds[ARBI][AVAX] = address(0);
        priceFeeds[ARBI][BSC] = address(0);
        priceFeeds[ARBI][ETH] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][BASE] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][GNOSIS] = 0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB;

        /// BASE
        priceFeeds[BASE][BASE] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][OP] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][POLY] = address(0);
        priceFeeds[BASE][AVAX] = address(0);
        priceFeeds[BASE][BSC] = address(0);
        priceFeeds[BASE][ETH] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][ARBI] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][GNOSIS] = 0x591e79239a7d679378eC8c847e5038150364C78F;

        /// GNOSIS
        priceFeeds[GNOSIS][GNOSIS] = 0x678df3415fc31947dA4324eC63212874be5a82f8;
        priceFeeds[GNOSIS][OP] = 0xa767f745331D267c7751297D982b050c93985627;
        priceFeeds[GNOSIS][POLY] = address(0);
        priceFeeds[GNOSIS][AVAX] = 0x911e08A32A6b7671A80387F93147Ab29063DE9A2;
        priceFeeds[GNOSIS][BSC] = 0x6D42cc26756C34F26BEcDD9b30a279cE9Ea8296E;
        priceFeeds[GNOSIS][ETH] = 0xa767f745331D267c7751297D982b050c93985627;
        priceFeeds[GNOSIS][BASE] = 0xa767f745331D267c7751297D982b050c93985627;
        priceFeeds[GNOSIS][ARBI] = 0xa767f745331D267c7751297D982b050c93985627;
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
        json = string(abi.encodePacked(root, folderToRead, vm.toString(uint256(chainId)), "/", name, "-latest.json"));
        string memory file = vm.readFile(json);
        return vm.parseJsonAddress(file, string(abi.encodePacked(".", contractName)));
    }
}

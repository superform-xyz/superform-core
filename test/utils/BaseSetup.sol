// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @dev lib imports
import "forge-std/Test.sol";

import { StdInvariant } from "forge-std/StdInvariant.sol";

import { LayerZeroHelper } from "pigeon/layerzero/LayerZeroHelper.sol";
import { LayerZeroV2Helper } from "pigeon/layerzero-v2/LayerZeroV2Helper.sol";
import { HyperlaneHelper } from "pigeon/hyperlane/HyperlaneHelper.sol";
import { AxelarHelper } from "pigeon/axelar/AxelarHelper.sol";
import { WormholeHelper } from "pigeon/wormhole/automatic-relayer/WormholeHelper.sol";
import "pigeon/wormhole/specialized-relayer/WormholeHelper.sol" as WormholeBroadcastHelper;

import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

/// @dev test utils & mocks
import { LiFiMock } from "../mocks/LiFiMock.sol";
import { SocketMock } from "../mocks/SocketMock.sol";
import { SocketOneInchMock } from "../mocks/SocketOneInchMock.sol";
import { LiFiMockRugpull } from "../mocks/LiFiMockRugpull.sol";
import { LiFiMockBlacklisted } from "../mocks/LiFiMockBlacklisted.sol";
import { LiFiMockSwapToAttacker } from "../mocks/LiFiMockSwapToAttacker.sol";
import { DeBridgeMock } from "../mocks/DeBridgeMock.sol";
import { DeBridgeForwarderMock } from "../mocks/DeBridgeForwarderMock.sol";
import { OneInchMock } from "../mocks/OneInchMock.sol";

import { MockERC20 } from "../mocks/MockERC20.sol";
import { VaultMock } from "../mocks/VaultMock.sol";
import { VaultMockRevertDeposit } from "../mocks/VaultMockRevertDeposit.sol";
import { VaultMockRevertWithdraw } from "../mocks/VaultMockRevertWithdraw.sol";
import { Permit2Clone } from "../mocks/Permit2Clone.sol";

/// @dev Protocol imports
import { CoreStateRegistry } from "src/crosschain-data/extensions/CoreStateRegistry.sol";
import { BroadcastRegistry } from "src/crosschain-data/BroadcastRegistry.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";
import { SuperformRouter } from "src/SuperformRouter.sol";
import { PayMaster } from "src/payments/PayMaster.sol";
import { EmergencyQueue } from "src/EmergencyQueue.sol";
import { SuperRegistry } from "src/settings/SuperRegistry.sol";
import { SuperRBAC } from "src/settings/SuperRBAC.sol";
import { SuperPositions } from "src/SuperPositions.sol";
import { SuperformFactory } from "src/SuperformFactory.sol";
import { ERC4626Form } from "src/forms/ERC4626Form.sol";
import { ERC5115Form } from "src/forms/ERC5115Form.sol";
import { ERC5115To4626Wrapper } from "src/forms/wrappers/ERC5115To4626Wrapper.sol";
import { ERC7540Form } from "src/forms/ERC7540Form.sol";
import { DstSwapper } from "src/crosschain-liquidity/DstSwapper.sol";
import { LiFiValidator } from "src/crosschain-liquidity/lifi/LiFiValidator.sol";
import { SocketValidator } from "src/crosschain-liquidity/socket/SocketValidator.sol";
import { DeBridgeValidator } from "src/crosschain-liquidity/debridge/DeBridgeValidator.sol";
import { DeBridgeForwarderValidator } from "src/crosschain-liquidity/debridge/DeBridgeForwarderValidator.sol";

import { SocketOneInchValidator } from "src/crosschain-liquidity/socket/SocketOneInchValidator.sol";
import { OneInchValidator } from "src/crosschain-liquidity/1inch/OneInchValidator.sol";

import { LayerzeroImplementation } from "src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol";
import { LayerzeroV2Implementation } from "src/crosschain-data/adapters/layerzero-v2/LayerzeroV2Implementation.sol";
import { HyperlaneImplementation } from "src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol";
import { WormholeARImplementation } from
    "src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol";
import { WormholeSRImplementation } from
    "src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol";
import {
    AxelarImplementation,
    IAxelarGateway,
    IAxelarGasService,
    IInterchainGasEstimation
} from "src/crosschain-data/adapters/axelar/AxelarImplementation.sol";

import { ERC5115To4626WrapperFactory } from "src/forms/wrappers/ERC5115To4626WrapperFactory.sol";
import { IMailbox } from "src/vendor/hyperlane/IMailbox.sol";
import { IInterchainGasPaymaster } from "src/vendor/hyperlane/IInterchainGasPaymaster.sol";
import ".././utils/AmbParams.sol";
import { IPermit2 } from "src/vendor/dragonfly-xyz/IPermit2.sol";
import { ERC7540AsyncDepositMock } from "../mocks/ERC7540AsyncDepositMock.sol";
import { ERC7540AsyncDepositMockRevert } from "../mocks/ERC7540AsyncDepositMockRevert.sol";
import { ERC7540AsyncDepositMockRedeemRevert } from "../mocks/ERC7540AsyncDepositMockRedeemRevert.sol";

import { ERC7540AsyncRedeemMock } from "../mocks/ERC7540AsyncRedeemMock.sol";
import { ERC7540AsyncRedeemMockRevert } from "../mocks/ERC7540AsyncRedeemMockRevert.sol";
import { ERC7540FullyAsyncMock } from "../mocks/ERC7540FullyAsyncMock.sol";

import { TrancheTokenLike } from "../mocks/7540MockUtils/TrancheTokenLike.sol";
import { RestrictionManagerLike } from "../mocks/7540MockUtils/RestrictionManagerLike.sol";
import { IAuthorizeOperator } from "src/vendor/centrifuge/IERC7540.sol";

import { IERC7540Vault as IERC7540 } from "src/vendor/centrifuge/IERC7540.sol";
import { AsyncStateRegistry } from "src/crosschain-data/extensions/AsyncStateRegistry.sol";
import { RequestConfig } from "src/interfaces/IAsyncStateRegistry.sol";
import { PayloadHelper as PayloadHelperV1 } from "src/crosschain-data/utils/PayloadHelper.sol";
import { PayloadHelper } from "src/crosschain-data/utils/PayloadHelperV2.sol";
import { PaymentHelper } from "src/payments/PaymentHelper.sol";
import { IPaymentHelperV2 as IPaymentHelper } from "src/interfaces/IPaymentHelperV2.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { Error } from "src/libraries/Error.sol";
import { RewardsDistributor } from "src/RewardsDistributor.sol";

import { SuperformRouterPlus } from "src/router-plus/SuperformRouterPlus.sol";
import { SuperformRouterPlusAsync } from "src/router-plus/SuperformRouterPlusAsync.sol";

import "src/types/DataTypes.sol";
import "./TestTypes.sol";

import "forge-std/console.sol";

abstract contract BaseSetup is StdInvariant, Test {
    bool public DEBUG_MODE = vm.envBool("DEBUG_MODE"); // Native token: ETH

    /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
    //////////////////////////////////////////////////////////////*/
    bytes32 constant TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");
    bytes32 constant PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );
    bytes32 constant AUTHORIZE_OPERATOR_TYPEHASH =
        keccak256("AuthorizeOperator(address controller,address operator,bool approved,bytes32 nonce,uint256 deadline)");

    /// @dev ETH mainnet values as on 22nd Aug, 2023
    uint256 public constant TOTAL_SUPPLY_DAI = 3_961_541_270_138_222_277_363_935_051;
    uint256 public constant TOTAL_SUPPLY_USDC = 23_581_451_089_110_212;
    uint256 public constant TOTAL_SUPPLY_WETH = 3_293_797_048_454_740_686_583_782;
    uint256 public constant TOTAL_SUPPLY_ETH = 120_000_000e18;

    /// @dev
    address public constant CANONICAL_PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    /// @dev for mainnet deployment
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// CREATE2 assumption but it works otherwise too
    address public deployer = vm.addr(777);
    address[] public users;
    uint256[] public userKeys;

    uint256 public trustedRemote;
    bytes32 public salt;
    mapping(uint64 chainId => mapping(bytes32 implementation => address at)) public contracts;

    string[44] public contractNames = [
        "CoreStateRegistry",
        "AsyncStateRegistry",
        "BroadcastRegistry",
        "LayerzeroImplementation",
        "LayerzeroV2Implementation",
        "HyperlaneImplementation",
        "WormholeARImplementation",
        "WormholeSRImplementation",
        "AxelarImplementation",
        "LiFiValidator",
        "SocketValidator",
        "DstSwapper",
        "SuperformFactory",
        "ERC4626Form",
        "ERC5115Form",
        "ERC7540Form",
        "SuperformRouter",
        "SuperPositions",
        "SuperRegistry",
        "SuperRBAC",
        "PayloadHelper",
        "PayloadHelperV1",
        "PaymentHelper",
        "PayMaster",
        "LayerZeroHelper",
        "LayerZeroV2Helper",
        "HyperlaneHelper",
        "WormholeHelper",
        "AxelarHelper",
        "WormholeBroadcastHelper",
        "LiFiMock",
        "DeBridgeMock",
        "DeBridgeForwarderMock",
        "KYCDAOMock",
        "CanonicalPermit2",
        "EmergencyQueue",
        "SocketOneInchValidator",
        "OneInchValidator",
        "DeBridgeValidator",
        "DeBridgeForwarderValidator",
        "RewardsDistributor",
        "ERC5115To4626WrapperFactory",
        "SuperformRouterPlus",
        "SuperformRouterPlusAsync"
    ];

    /*//////////////////////////////////////////////////////////////
                        PROTOCOL VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev we should fork these instead of mocking.
    /// @notice tUSD is a test token on sepolia
    string[] public UNDERLYING_TOKENS = ["DAI", "USDC", "WETH", "ezETH", "wstETH", "sUSDe", "USDe", "tUSD"];

    /// @dev 1 = ERC4626Form, 3 = ERC5115,  4 is ERC7540,
    uint32[] public FORM_IMPLEMENTATION_IDS = [uint32(1), uint32(3), uint32(4)];

    /// @dev WARNING!! THESE VAULT NAMES MUST BE THE EXACT NAMES AS FILLED IN vaultKinds
    string[] public VAULT_KINDS = [
        "VaultMock",
        "VaultMockRevertDeposit",
        "VaultMockRevertWithdraw",
        "ERC5115",
        "ERC7540FullyAsyncMock",
        "ERC7540AsyncDepositMock",
        "ERC7540AsyncRedeemMock",
        "ERC7540AsyncDepositMockRevert",
        "ERC7540AsyncRedeemMockRevert",
        "ERC7540AsyncDepositMockRedeemRevert"
    ];

    struct VaultInfo {
        bytes[] vaultBytecode;
        string[] vaultKinds;
    }

    mapping(uint32 formImplementationId => VaultInfo vaultInfo) vaultBytecodes2;

    mapping(uint256 vaultId => string[] names) VAULT_NAMES;

    mapping(uint64 chainId => mapping(uint32 formImplementationId => address[][] vaults)) public vaults;
    mapping(uint64 chainId => address[] wrapped5115vaults) public wrapped5115vaults;
    mapping(uint64 chainId => uint256 payloadId) PAYLOAD_ID;

    mapping(uint64 chainId => uint256 payloadId) ASYNC_DEPOSIT_PAYLOAD_ID;
    mapping(uint64 chainId => uint256 payloadId) SYNC_WITHDRAW_PAYLOAD_ID;

    /// @dev liquidity bridge ids
    uint8[] bridgeIds;
    /// @dev liquidity bridge addresses
    address[] bridgeAddresses;
    /// @dev liquidity validator addresses
    address[] bridgeValidators;

    /// @dev setup amb bridges
    /// @notice id 1 is layerzero
    /// @notice id 2 is hyperlane
    /// @notice id 3 is wormhole (Automatic Relayer)
    /// @notice id 4 is wormhole (Specialized Relayer)
    /// @notice id 5 is axelar
    /// @notice id 6 is layerzero-v2

    uint8[] public ambIds = [uint8(1), 2, 3, 4, 5, 6];
    bool[] public isBroadcastAMB = [false, false, false, true, false, false];

    /*//////////////////////////////////////////////////////////////
                        AMB VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(uint64 => address) public LZ_ENDPOINTS;
    mapping(uint64 => uint16) public WORMHOLE_CHAIN_IDS;
    mapping(uint64 => address) public HYPERLANE_MAILBOXES;
    mapping(uint64 => string) public AXELAR_CHAIN_IDS;
    mapping(uint64 => address) public AXELAR_GATEWAYS;

    address public constant ETH_lzEndpoint = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
    address public constant BSC_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant AVAX_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant POLY_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant ARBI_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant OP_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant BASE_lzEndpoint = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;
    address public constant FANTOM_lzEndpoint = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;
    address public constant SEPOLIA_lzEndpoint = 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1;
    address public constant BSC_TESTNET_lzEndpoint = 0x6Fcb97553D41516Cb228ac03FdC8B9a0a9df04A1;
    address public constant LINEA_lzEndpoint = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;
    address public constant BLAST_lzEndpoint = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;

    address[] public lzEndpoints = [
        0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7,
        0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7,
        0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1,
        0x6Fcb97553D41516Cb228ac03FdC8B9a0a9df04A1,
        0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7,
        0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7,
        address(0)
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
        0xfFAEF09B3cd11D9b20d1a19bECca54EEC2884766,
        0xF9F6F5646F478d5ab4e20B0F910C92F1CCC9Cc6D,
        0x02d16BC51af6BfD153d67CA61754cF912E82C4d9,
        0x3a867fCfFeC2B790970eeBDC9023E75B0a172aa7,
        0xDDcFEcF17586D08A5740B7D91735fcCE3dfe3eeD
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
        0x6f2756380FD49228ae25Aa7F2817993cB74Ecc56,
        0x0dD20e410bdB95404f71c5a4e7Fa67B892A5f949,
        0x8105a095368f1a184CceA86cCe21318B5Ee5BE28,
        0xB3fCcD379ad66CED0c91028520C64226611A48c9,
        0x04438ef7622f5412f82915F59caD4f704C61eA48
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
        0x4a8bc80Ed5a4067f1CCf107057b8270E0cC11A78,
        0x68605AD7b15c732a30b1BbC62BE8F2A509D74b4D,
        address(0),
        0xbebdb6C8ddC678FfA9f8748f85C815C556Dd8ac6,
        address(0)
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
        0x4D147dCb984e6affEEC47e44293DA442580A3Ec0,
        0xe432150cce91c13a887f7D836923d5597adD8E31,
        0xe432150cce91c13a887f7D836923d5597adD8E31,
        address(0)
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
        0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6,
        0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6,
        0x2d5d7d31F671F86C782533cc367F14109a082712,
        0x2d5d7d31F671F86C782533cc367F14109a082712,
        0x2d5d7d31F671F86C782533cc367F14109a082712,
        address(0)
    ];

    /*//////////////////////////////////////////////////////////////
                        WORMHOLE VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev uses CREATE2
    address public wormholeRelayer = 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911;
    address public wormholeBaseRelayer = 0x706F82e9bb5b0813501714Ab5974216704980e31;

    /*//////////////////////////////////////////////////////////////
                        LAYERZERO V2 VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev uses CREATE2
    address public lzV2Endpoint = 0x1a44076050125825900e736c501f859c50fE728c;
    address public lzV2Endpoint_TESTNET = 0x6EDCE65403992e310A62460808c4b910D972f10f;

    uint32 public constant LZ_V2_ETH = 30_101;
    uint32 public constant LZ_V2_BSC = 30_102;
    uint32 public constant LZ_V2_AVAX = 30_106;
    uint32 public constant LZ_V2_POLY = 30_109;
    uint32 public constant LZ_V2_ARBI = 30_110;
    uint32 public constant LZ_V2_OP = 30_111;
    uint32 public constant LZ_V2_BASE = 30_184;
    uint32 public constant LZ_V2_FANTOM = 30_112;
    uint32 public constant LZ_V2_SEPOLIA = 40_161;
    uint32 public constant LZ_V2_BSC_TESTNET = 40_102;
    uint32 public constant LZ_V2_LINEA = 30_183;
    uint32 public constant LZ_V2_BLAST = 30_243;
    uint32 public constant LZ_V2_BARTIO = 40_291;

    address[] public SuperformDVNs = [
        0x7518f30bd5867b5fA86702556245Dead173afE46,
        0xF4c489AfD83625F510947e63ff8F90dfEE0aE46C,
        0x8fb0B7D74B557e4b45EF89648BAc197EAb2E4325,
        0x1E4CE74ccf5498B19900649D9196e64BAb592451,
        0x5496d03d9065B08e5677E1c5D1107110Bb05d445,
        0xb0B2EF168F52F6d1e42f461e11117295eF992daf,
        0xEb62f578497Bdc351dD650853a751135212fAF49,
        0x2EdfE0220A74d9609c79711a65E3A2F2A85Dc83b,
        0x7A205ED4e3d7f9d0777594501705D8CD405c3B05,
        0x0E95cf21aD9376A26997c97f326C5A0a267bB8FF
    ];

    address[] public LzDVNs = [
        0x589dEDbD617e0CBcB916A9223F4d1300c294236b,
        0xfD6865c841c2d64565562fCc7e05e619A30615f0,
        0x962F502A63F5FBeB44DC9ab932122648E8352959,
        0x23DE2FE932d9043291f870324B74F820e11dc81A,
        0x2f55C492897526677C5B68fb199ea31E2c126416,
        0x6A02D83e8d433304bba74EF1c427913958187142,
        0x9e059a54699a285714207b43B055483E78FAac25,
        0xE60A3959Ca23a92BF5aAf992EF837cA7F828628a,
        0x129Ee430Cb2Ff2708CCADDBDb408a88Fe4FFd480,
        0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f
    ];

    /*//////////////////////////////////////////////////////////////
                        HYPERLANE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint64 public constant ETH = 1;
    uint64 public constant BSC = 56;
    uint64 public constant AVAX = 43_114;
    uint64 public constant POLY = 137;
    uint64 public constant ARBI = 42_161;
    uint64 public constant OP = 10;
    uint64 public constant BASE = 8453;
    uint64 public constant FANTOM = 250;
    uint64 public constant SEPOLIA = 11_155_111;
    uint64 public constant BSC_TESTNET = 97;
    uint64 public constant LINEA = 59_144;
    uint64 public constant BLAST = 81_457;
    uint64 public constant BARTIO = 80_084;

    uint64[] public chainIds = [1, 56, 43_114, 137, 42_161, 10, 8453, 250, 11_155_111, 97, 59_144, 81_457, 80_084];
    uint64[] public defaultChainIds =
        [1, 56, 43_114, 137, 42_161, 10, 8453, 250, 11_155_111, 97, 59_144, 81_457, 80_084];

    mapping(uint64 chainId => bool selected) selectedChainIds;
    /// @dev reference for chain ids https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
    uint16 public constant LZ_ETH = 101;
    uint16 public constant LZ_BSC = 102;
    uint16 public constant LZ_AVAX = 106;
    uint16 public constant LZ_POLY = 109;
    uint16 public constant LZ_ARBI = 110;
    uint16 public constant LZ_OP = 111;
    uint16 public constant LZ_BASE = 184;
    uint16 public constant LZ_FANTOM = 112;
    uint16 public constant LZ_SEPOLIA = 10_161;
    uint16 public constant LZ_BSC_TESTNET = 10_102;
    uint16 public constant LZ_LINEA = 183;
    uint32 public constant LZ_BLAST = 243;

    uint16[] public lz_chainIds = [101, 102, 106, 109, 110, 111, 184, 112, 10_161, 10_102, 183, 243, 0];
    uint32[] public lz_v2_chainIds =
        [30_101, 30_102, 30_106, 30_109, 30_110, 30_111, 30_184, 30_112, 40_161, 40_102, 30_183, 30_243, 40_291];
    uint32[] public hyperlane_chainIds =
        [1, 56, 43_114, 137, 42_161, 10, 8453, 250, 11_155_111, 97, 59_144, 81_457, 80_084];
    uint16[] public wormhole_chainIds = [2, 4, 6, 5, 23, 24, 30, 10, 10_002, 10_003, 38, 36, 0];
    string[] public axelar_chainIds = [
        "Ethereum",
        "binance",
        "Avalanche",
        "Polygon",
        "arbitrum",
        "optimism",
        "base",
        "Fantom",
        "ethereum-sepolia",
        "binance-testnet",
        "linea",
        "blast",
        ""
    ];

    /// @dev minting enough tokens to be able to fuzz with bigger amounts (DAI's 3.6B supply etc)
    uint256 public constant hundredBilly = 100 * 1e9 * 1e18;

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
        4 * 10e9, // FANTOM
        50_000_000_000, // SEPOLIA
        3_000_000_000, // BSC
        60_000_000, // LINEA
        60_000_000, // BLAST
        60_000_000 // BARTIO
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
        4 * 10e9, // FANTOM
        253_400_000_000, // SEPOLIA
        31_439_000_000, // BSC
        253_400_000_000, // LINEA
        253_400_000_000, // BLAST
        253_400_000_000 // BARTIO
    ];

    /*//////////////////////////////////////////////////////////////
                        CHAINLINK VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(uint64 => mapping(uint64 => address)) public PRICE_FEEDS;
    mapping(uint64 => mapping(address => address)) public tokenPriceFeeds;

    /*//////////////////////////////////////////////////////////////
                        RPC VARIABLES
    //////////////////////////////////////////////////////////////*/

    // chainID => FORK
    mapping(uint64 chainId => uint256 fork) public FORKS;
    mapping(uint64 chainId => string forkUrl) public RPC_URLS;
    mapping(uint64 chainId => mapping(string underlying => address realAddress)) public UNDERLYING_EXISTING_TOKENS;
    mapping(
        uint64 chainId
            => mapping(
                uint32 formImplementationId
                    => mapping(string underlying => mapping(uint256 vaultKindIndex => address realVault))
            )
    ) public REAL_VAULT_ADDRESS;

    mapping(uint64 chainId => uint256 nVaults) public NUMBER_OF_5115S;
    mapping(uint64 chainId => mapping(uint256 market => address realVault)) public ERC5115_VAULTS;
    mapping(uint64 chainId => mapping(uint256 market => string name)) public ERC5115_VAULTS_NAMES;

    struct ChosenAssets {
        address assetIn;
        address assetOut;
    }

    mapping(uint64 chainId => mapping(address realVault => ChosenAssets chosenAssets)) public ERC5115S_CHOSEN_ASSETS;

    string public ETHEREUM_RPC_URL = vm.envString("ETHEREUM_RPC_URL"); // Native token: ETH
    string public BSC_RPC_URL = vm.envString("BSC_RPC_URL"); // Native token: BNB
    string public AVALANCHE_RPC_URL = vm.envString("AVALANCHE_RPC_URL"); // Native token: AVAX
    string public POLYGON_RPC_URL = vm.envString("POLYGON_RPC_URL"); // Native token: MATIC
    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL"); // Native token: ETH
    string public OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC_URL"); // Native token: ETH
    string public BASE_RPC_URL = vm.envString("BASE_RPC_URL"); // Native token: BASE
    string public FANTOM_RPC_URL = vm.envString("FANTOM_RPC_URL"); // Native token: FTM
    string public LINEA_RPC_URL = vm.envString("LINEA_RPC_URL"); // Native token: ETH
    string public BLAST_RPC_URL = vm.envString("BLAST_RPC_URL"); // Native token: ETH
    string public BARTIO_RPC_URL = vm.envString("BARTIO_RPC_URL"); // Native token: ETH (fake)

    string public ETHEREUM_RPC_URL_QN = vm.envString("ETHEREUM_RPC_URL_QN"); // Native token: ETH
    string public BSC_RPC_URL_QN = vm.envString("BSC_RPC_URL_QN"); // Native token: BNB
    string public AVALANCHE_RPC_URL_QN = vm.envString("AVALANCHE_RPC_URL_QN"); // Native token: AVAX
    string public POLYGON_RPC_URL_QN = vm.envString("POLYGON_RPC_URL_QN"); // Native token: MATIC
    string public ARBITRUM_RPC_URL_QN = vm.envString("ARBITRUM_RPC_URL_QN"); // Native token: ETH
    string public OPTIMISM_RPC_URL_QN = vm.envString("OPTIMISM_RPC_URL_QN"); // Native token: ETH
    string public BASE_RPC_URL_QN = vm.envString("BASE_RPC_URL_QN"); // Native token: ETH
    string public FANTOM_RPC_URL_QN = vm.envString("FANTOM_RPC_URL_QN"); // Native token: FTM
    string public SEPOLIA_RPC_URL_QN = vm.envString("SEPOLIA_RPC_URL_QN"); // Native token: ETH
    string public BSC_TESTNET_RPC_URL_QN = vm.envString("BSC_TESTNET_RPC_URL_QN"); // Native token: BNB
    string public LINEA_RPC_URL_QN = vm.envString("LINEA_RPC_URL_QN"); // Native token: ETH
    string public BLAST_RPC_URL_QN = vm.envString("BLAST_RPC_URL_QN"); // Native token: ETH
    string public BARTIO_RPC_URL_QN = vm.envString("BARTIO_RPC_URL_QN"); // Native token: ETH (fake)

    bool public LAUNCH_TESTNETS = false;
    /*//////////////////////////////////////////////////////////////
                        KYC DAO VALIDITY VARIABLES
    //////////////////////////////////////////////////////////////*/

    address[] public kycDAOValidityAddresses =
        [address(0), address(0), address(0), 0x205E10d3c4C87E26eB66B1B270b71b7708494dB9, address(0), address(0)];

    function setUp() public virtual {
        //if (!LAUNCH_TESTNETS) chainIds = [1, 56, 43_114, 137, 42_161, 10, 8453, 250];

        _preDeploymentSetup(true, false);

        _fundNativeTokens();

        _deployProtocol();

        _fundUnderlyingTokens(100);
    }

    function getContract(uint64 chainId, string memory _name) internal view returns (address) {
        return contracts[chainId][bytes32(bytes(_name))];
    }

    function getAccessControlErrorMsg(address _addr, bytes32 _role) internal pure returns (bytes memory errorMsg) {
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

        /// @dev 1 - Pigeon helpers allow us to fullfill cross-chain messages in a manner as close to mainnet as
        /// possible
        vars.lzHelper = address(new LayerZeroHelper{ salt: salt }());
        vm.allowCheatcodes(vars.lzHelper);
        vm.makePersistent(vars.lzHelper);

        vars.lzV2Helper = address(new LayerZeroV2Helper{ salt: salt }());
        vm.allowCheatcodes(vars.lzV2Helper);
        vm.makePersistent(vars.lzV2Helper);

        vars.hyperlaneHelper = address(new HyperlaneHelper{ salt: salt }());
        vm.allowCheatcodes(vars.hyperlaneHelper);
        vm.makePersistent(vars.hyperlaneHelper);

        vars.wormholeHelper = address(new WormholeHelper{ salt: salt }());
        vm.allowCheatcodes(vars.wormholeHelper);
        vm.makePersistent(vars.wormholeHelper);

        vars.wormholeBroadcastHelper = address(new WormholeBroadcastHelper.WormholeHelper{ salt: salt }());
        vm.allowCheatcodes(vars.wormholeBroadcastHelper);
        vm.makePersistent(vars.wormholeBroadcastHelper);

        vars.axelarHelper = address(new AxelarHelper{ salt: salt }());
        vm.allowCheatcodes(vars.axelarHelper);
        vm.makePersistent(vars.axelarHelper);

        /// @dev deploy  LiFiRouterMock. This mock is a very minimal versions to allow
        /// liquidity bridge testing
        vars.lifiRouter = address(new LiFiMock{ salt: salt }());
        vm.allowCheatcodes(vars.lifiRouter);
        vm.makePersistent(vars.lifiRouter);

        /// @dev deploy SocketMock. This mock is a very minimal versions to allow
        /// liquidity bridge testing
        vars.socketRouter = address(new SocketMock{ salt: salt }());
        vm.allowCheatcodes(vars.socketRouter);
        vm.makePersistent(vars.socketRouter);

        /// @dev deploy SocketOneInchMock. This mock is a very minimal versions to allow
        /// socket same chain swaps
        vars.socketOneInch = address(new SocketOneInchMock{ salt: salt }());
        vm.allowCheatcodes(vars.socketOneInch);
        vm.makePersistent(vars.socketOneInch);

        /// @dev deploy LiFiMockRugpull. This mock tests a behaviour where the bridge is malicious and tries
        /// to steal tokens
        vars.liFiMockRugpull = address(new LiFiMockRugpull{ salt: salt }());
        vm.allowCheatcodes(vars.liFiMockRugpull);
        vm.makePersistent(vars.liFiMockRugpull);

        /// @dev deploy LiFiMockBlacklisted. This mock tests the behaviour of blacklisted selectors
        vars.liFiMockBlacklisted = address(new LiFiMockBlacklisted{ salt: salt }());
        vm.allowCheatcodes(vars.liFiMockBlacklisted);
        vm.makePersistent(vars.liFiMockBlacklisted);

        /// @dev deploy LiFiMockSwapToAttacker. This mock tests the behaviour of blacklisted selectors
        vars.liFiMockSwapToAttacker = address(new LiFiMockSwapToAttacker{ salt: salt }());
        vm.allowCheatcodes(vars.liFiMockSwapToAttacker);
        vm.makePersistent(vars.liFiMockSwapToAttacker);

        /// @dev 7.1.7 deploy DeBridgeMock. This mocks tests the behavior of debridge
        vars.deBridgeMock = address(new DeBridgeMock{ salt: salt }());
        vm.allowCheatcodes(vars.deBridgeMock);
        vm.makePersistent(vars.deBridgeMock);

        /// @dev 7.1.7 deploy DeBridgeForwarderMock. This mocks tests the behavior of debridge forwarder
        vars.debridgeForwarderMock = address(new DeBridgeForwarderMock{ salt: salt }());
        vm.allowCheatcodes(vars.debridgeForwarderMock);
        vm.makePersistent(vars.debridgeForwarderMock);

        /// @dev 7.1.8 deploy OneInchMock. This mocks the beahvior of 1inch
        vars.oneInchMock = address(new OneInchMock{ salt: salt }());
        vm.allowCheatcodes(vars.oneInchMock);
        vm.makePersistent(vars.oneInchMock);

        /// @dev deployments
        for (uint256 i = 0; i < chainIds.length; ++i) {
            vars.chainId = chainIds[i];

            for (uint256 j = 0; j < defaultChainIds.length; j++) {
                if (vars.chainId == defaultChainIds[j]) {
                    vars.trueChainIdIndex = j;
                    break;
                }
            }

            vars.fork = FORKS[vars.chainId];
            vars.ambAddresses = new address[](ambIds.length);
            /// @dev salt unique to each chain
            salt = keccak256(abi.encodePacked("SUPERFORM_ON_CHAIN", vars.chainId));

            /// @dev first 4 chains have the same salt. This allows us to test a create2 deployment both with chains
            /// with same addresses and others without
            if (i < 4) {
                salt = keccak256(abi.encodePacked("SUPERFORM_ON_CHAIN"));
            }

            vm.selectFork(vars.fork);
            /// @dev preference for a local deployment of Permit2 over mainnet version. Has same bytecode
            vars.canonicalPermit2 = address(new Permit2Clone{ salt: salt }());
            contracts[vars.chainId][bytes32(bytes("CanonicalPermit2"))] = vars.canonicalPermit2;

            /// @dev 1 - Pigeon helpers allow us to fullfill cross-chain messages in a manner as close to mainnet as
            /// possible
            /// @dev 1.1.1- LZ Helper from Pigeon
            contracts[vars.chainId][bytes32(bytes("LayerZeroHelper"))] = vars.lzHelper;

            /// @dev 1.1.2- deploy LZ v2 Helper from Pigeon
            contracts[vars.chainId][bytes32(bytes("LayerZeroV2Helper"))] = vars.lzV2Helper;

            /// @dev 1.2-  Hyperlane Helper from Pigeon
            contracts[vars.chainId][bytes32(bytes("HyperlaneHelper"))] = vars.hyperlaneHelper;

            /// @dev 1.3-  Wormhole Automatic Relayer Helper from Pigeon
            contracts[vars.chainId][bytes32(bytes("WormholeHelper"))] = vars.wormholeHelper;

            /// @dev 1.4-  Wormhole Specialized Relayer Helper from Pigeon
            contracts[vars.chainId][bytes32(bytes("WormholeBroadcastHelper"))] = vars.wormholeBroadcastHelper;

            /// @dev 1.5- deploy axelar from Pigeon
            contracts[vars.chainId][bytes32(bytes("AxelarHelper"))] = vars.axelarHelper;

            /// @dev 2 - Deploy SuperRBAC
            vars.superRBAC = address(
                new SuperRBAC{ salt: salt }(
                    ISuperRBAC.InitialRoleSetup({
                        admin: deployer,
                        emergencyAdmin: deployer,
                        paymentAdmin: deployer,
                        csrProcessor: deployer,
                        tlProcessor: deployer,
                        brProcessor: deployer,
                        csrUpdater: deployer,
                        srcVaaRelayer: vars.wormholeBroadcastHelper,
                        dstSwapper: deployer,
                        csrRescuer: deployer,
                        csrDisputer: deployer
                    })
                )
            );
            contracts[vars.chainId][bytes32(bytes("SuperRBAC"))] = vars.superRBAC;

            vars.superRBACC = SuperRBAC(vars.superRBAC);

            /// @dev 3 - Deploy SuperRegistry
            vars.superRegistry = address(new SuperRegistry{ salt: salt }(vars.superRBAC));
            contracts[vars.chainId][bytes32(bytes("SuperRegistry"))] = vars.superRegistry;
            vars.superRegistryC = SuperRegistry(vars.superRegistry);

            vars.superRBACC.setSuperRegistry(vars.superRegistry);

            vm.expectRevert(Error.ZERO_ADDRESS.selector);
            vars.superRegistryC.PERMIT2();
            vars.superRegistryC.setPermit2(vars.canonicalPermit2);

            assert(vars.superRBACC.hasProtocolAdminRole(deployer));

            /// @dev 4.1 - deploy Core State Registry
            vars.coreStateRegistry = address(new CoreStateRegistry{ salt: salt }(SuperRegistry(vars.superRegistry)));
            contracts[vars.chainId][bytes32(bytes("CoreStateRegistry"))] = vars.coreStateRegistry;

            vars.superRegistryC.setAddress(
                vars.superRegistryC.CORE_STATE_REGISTRY(), vars.coreStateRegistry, vars.chainId
            );

            /// @dev 4.2 - deploy Broadcast State Registry
            vars.broadcastRegistry = address(new BroadcastRegistry{ salt: salt }(vars.superRegistryC));
            contracts[vars.chainId][bytes32(bytes("BroadcastRegistry"))] = vars.broadcastRegistry;

            vars.superRegistryC.setAddress(
                vars.superRegistryC.BROADCAST_REGISTRY(), vars.broadcastRegistry, vars.chainId
            );

            /// @dev 4.4 - deploy Async State Registry
            vars.asyncStateRegistry = address(new AsyncStateRegistry{ salt: salt }(vars.superRegistryC));
            contracts[vars.chainId][bytes32(bytes("AsyncStateRegistry"))] = vars.asyncStateRegistry;

            vars.superRegistryC.setAddress(keccak256("ASYNC_STATE_REGISTRY"), vars.asyncStateRegistry, vars.chainId);
            vars.superRBACC.setRoleAdmin(
                keccak256("ASYNC_STATE_REGISTRY_PROCESSOR_ROLE"), vars.superRBACC.PROTOCOL_ADMIN_ROLE()
            );
            vars.superRBACC.grantRole(keccak256("ASYNC_STATE_REGISTRY_PROCESSOR_ROLE"), deployer);

            address[] memory registryAddresses = new address[](3);
            registryAddresses[0] = vars.coreStateRegistry;
            registryAddresses[1] = vars.broadcastRegistry;
            registryAddresses[2] = vars.asyncStateRegistry;

            uint8[] memory registryIds = new uint8[](3);
            registryIds[0] = 1;
            registryIds[1] = 2;
            registryIds[2] = 4;

            vars.superRegistryC.setStateRegistryAddress(registryIds, registryAddresses);

            /// @dev 5- deploy Payment Helper
            vars.paymentHelper = address(new PaymentHelper{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("PaymentHelper"))] = vars.paymentHelper;

            vars.superRegistryC.setAddress(vars.superRegistryC.PAYMENT_HELPER(), vars.paymentHelper, vars.chainId);

            /// @dev 6.1 - deploy Layerzero Implementation
            if (vars.chainId != BARTIO) {
                vars.lzImplementation = address(new LayerzeroImplementation{ salt: salt }(vars.superRegistryC));
                contracts[vars.chainId][bytes32(bytes("LayerzeroImplementation"))] = vars.lzImplementation;

                LayerzeroImplementation(payable(vars.lzImplementation)).setLzEndpoint(
                    lzEndpoints[vars.trueChainIdIndex]
                );
            }

            /// @dev 6.1.1 - deploy Layerzero v2 implementation
            vars.lzV2Implementation = address(new LayerzeroV2Implementation{ salt: salt }(vars.superRegistryC));
            contracts[vars.chainId][bytes32(bytes("LayerzeroV2Implementation"))] = vars.lzV2Implementation;
            if (!(vars.chainId == BARTIO || vars.chainId == SEPOLIA || vars.chainId == BSC_TESTNET)) {
                LayerzeroV2Implementation(payable(vars.lzV2Implementation)).setLzEndpoint(lzV2Endpoint);
            } else {
                LayerzeroV2Implementation(payable(vars.lzV2Implementation)).setLzEndpoint(lzV2Endpoint_TESTNET);
            }

            /// @dev 6.2 - deploy Hyperlane Implementation
            if (vars.chainId != FANTOM) {
                vars.hyperlaneImplementation =
                    address(new HyperlaneImplementation{ salt: salt }(SuperRegistry(vars.superRegistry)));
                HyperlaneImplementation(vars.hyperlaneImplementation).setHyperlaneConfig(
                    IMailbox(hyperlaneMailboxes[vars.trueChainIdIndex]),
                    IInterchainGasPaymaster(hyperlanePaymasters[vars.trueChainIdIndex])
                );
                contracts[vars.chainId][bytes32(bytes("HyperlaneImplementation"))] = vars.hyperlaneImplementation;
            }

            if (!(vars.chainId == LINEA || vars.chainId == BARTIO)) {
                /// @dev 6.3- deploy Wormhole Automatic Relayer Implementation
                vars.wormholeImplementation = address(new WormholeARImplementation{ salt: salt }(vars.superRegistryC));
                contracts[vars.chainId][bytes32(bytes("WormholeARImplementation"))] = vars.wormholeImplementation;

                WormholeARImplementation(vars.wormholeImplementation).setWormholeRelayer(wormholeRelayer);
                /// set refund chain id to wormhole chain id
                WormholeARImplementation(vars.wormholeImplementation).setRefundChainId(
                    wormhole_chainIds[vars.trueChainIdIndex]
                );

                /// @dev 6.4- deploy Wormhole Specialized Relayer Implementation
                vars.wormholeSRImplementation =
                    address(new WormholeSRImplementation{ salt: salt }(vars.superRegistryC, 2));
                contracts[vars.chainId][bytes32(bytes("WormholeSRImplementation"))] = vars.wormholeSRImplementation;

                WormholeSRImplementation(vars.wormholeSRImplementation).setWormholeCore(
                    wormholeCore[vars.trueChainIdIndex]
                );

                WormholeSRImplementation(vars.wormholeSRImplementation).setRelayer(deployer);
            }

            /// @dev 6.5- deploy Axelar Implementation
            if (vars.chainId != BARTIO) {
                vars.axelarImplementation = address(new AxelarImplementation{ salt: salt }(vars.superRegistryC));
                contracts[vars.chainId][bytes32(bytes("AxelarImplementation"))] = vars.axelarImplementation;

                AxelarImplementation(vars.axelarImplementation).setAxelarConfig(
                    IAxelarGateway(axelarGateway[vars.trueChainIdIndex])
                );
                AxelarImplementation(vars.axelarImplementation).setAxelarGasService(
                    IAxelarGasService(axelarGasService[vars.trueChainIdIndex]),
                    IInterchainGasEstimation(axelarGasService[vars.trueChainIdIndex])
                );
            }

            vars.ambAddresses[0] = vars.lzImplementation;
            vars.ambAddresses[1] = vars.hyperlaneImplementation;
            vars.ambAddresses[2] = vars.wormholeImplementation;
            vars.ambAddresses[3] = vars.wormholeSRImplementation;
            vars.ambAddresses[4] = vars.axelarImplementation;
            vars.ambAddresses[5] = vars.lzV2Implementation;

            contracts[vars.chainId][bytes32(bytes("LiFiMock"))] = vars.lifiRouter;

            contracts[vars.chainId][bytes32(bytes("SocketMock"))] = vars.socketRouter;

            contracts[vars.chainId][bytes32(bytes("SocketOneInchMock"))] = vars.socketOneInch;

            contracts[vars.chainId][bytes32(bytes("LiFiMockRugpull"))] = vars.liFiMockRugpull;

            contracts[vars.chainId][bytes32(bytes("LiFiMockBlacklisted"))] = vars.liFiMockBlacklisted;

            contracts[vars.chainId][bytes32(bytes("LiFiMockBlacklisted"))] = vars.liFiMockSwapToAttacker;

            contracts[vars.chainId][bytes32(bytes("DeBridgeMock"))] = vars.deBridgeMock;

            contracts[vars.chainId][bytes32(bytes("DeBridgeForwarderMock"))] = vars.debridgeForwarderMock;

            contracts[vars.chainId][bytes32(bytes("OneInchMock"))] = vars.debridgeForwarderMock;

            /// @dev 7.2.1- deploy  lifi validator
            vars.lifiValidator = address(new LiFiValidator{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("LiFiValidator"))] = vars.lifiValidator;

            /// @dev 7.2.2- deploy socket validator
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

            /// @dev 7.2.3- deploy socket one inch validator
            vars.socketOneInchValidator = address(new SocketOneInchValidator{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("SocketOneInchValidator"))] = vars.socketOneInchValidator;

            /// @dev 7.2.4- deploy deBridge validator
            vars.debridgeValidator = address(new DeBridgeValidator{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("DeBridgeValidator"))] = vars.debridgeValidator;

            /// @dev 7.2.5- deploy deBridge forwarder validator
            vars.debridgeForwarderValidator = address(new DeBridgeForwarderValidator{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("DeBridgeForwarderValidator"))] = vars.debridgeForwarderValidator;

            /// @dev 7.2.6- deploy socket one inch validator
            vars.oneInchValidator = address(new OneInchValidator{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("OneInchValidator"))] = vars.oneInchValidator;

            bridgeAddresses.push(vars.lifiRouter);
            bridgeAddresses.push(vars.socketRouter);
            bridgeAddresses.push(vars.socketOneInch);
            bridgeAddresses.push(vars.liFiMockRugpull);
            bridgeAddresses.push(vars.liFiMockBlacklisted);
            bridgeAddresses.push(vars.liFiMockSwapToAttacker);
            bridgeAddresses.push(vars.deBridgeMock);
            bridgeAddresses.push(vars.debridgeForwarderMock);
            bridgeAddresses.push(vars.oneInchMock);

            bridgeValidators.push(vars.lifiValidator);
            bridgeValidators.push(vars.socketValidator);
            bridgeValidators.push(vars.socketOneInchValidator);
            bridgeValidators.push(vars.lifiValidator);
            bridgeValidators.push(vars.lifiValidator);
            bridgeValidators.push(vars.lifiValidator);
            bridgeValidators.push(vars.debridgeValidator);
            bridgeValidators.push(vars.debridgeForwarderValidator);
            bridgeValidators.push(vars.oneInchValidator);

            /// @dev 8.1 - Deploy UNDERLYING_TOKENS and VAULTS
            for (uint256 j = 0; j < UNDERLYING_TOKENS.length; ++j) {
                vm.selectFork(FORKS[vars.chainId]);
                vars.UNDERLYING_TOKEN = UNDERLYING_EXISTING_TOKENS[vars.chainId][UNDERLYING_TOKENS[j]];

                if (vars.UNDERLYING_TOKEN == address(0)) {
                    vars.UNDERLYING_TOKEN = address(
                        new MockERC20{ salt: salt }(UNDERLYING_TOKENS[j], UNDERLYING_TOKENS[j], deployer, hundredBilly)
                    );
                } else {
                    deal(vars.UNDERLYING_TOKEN, deployer, hundredBilly);
                }
                contracts[vars.chainId][bytes32(bytes(UNDERLYING_TOKENS[j]))] = vars.UNDERLYING_TOKEN;
            }

            bytes memory bytecodeWithArgs;
            /// NOTE: This loop deploys all vaults on all chainIds with all of the UNDERLYING TOKENS (id x form) x
            /// chainId
            for (uint32 j; j < FORM_IMPLEMENTATION_IDS.length; ++j) {
                /// @dev don't do this for 5115
                if (j != 1) {
                    address[][] memory doubleVaults = new address[][](UNDERLYING_TOKENS.length);

                    for (uint256 k = 0; k < UNDERLYING_TOKENS.length; ++k) {
                        uint256 lenBytecodes = vaultBytecodes2[FORM_IMPLEMENTATION_IDS[j]].vaultBytecode.length;
                        address[] memory vaultsT = new address[](lenBytecodes);
                        for (uint256 l = 0; l < lenBytecodes; l++) {
                            vars.vault =
                                REAL_VAULT_ADDRESS[vars.chainId][FORM_IMPLEMENTATION_IDS[j]][UNDERLYING_TOKENS[k]][l];

                            if (vars.vault == address(0)) {
                                /// @dev 8.2 - Deploy mock Vault
                                if (j == 0) {
                                    bytecodeWithArgs = abi.encodePacked(
                                        vaultBytecodes2[FORM_IMPLEMENTATION_IDS[j]].vaultBytecode[l],
                                        abi.encode(
                                            MockERC20(getContract(vars.chainId, UNDERLYING_TOKENS[k])),
                                            VAULT_NAMES[l][k],
                                            VAULT_NAMES[l][k]
                                        )
                                    );

                                    vars.vault = _deployWithCreate2(bytecodeWithArgs, 1);
                                } else if (j == 2) {
                                    /// deploy the 7540 wrappers (skips j = 1 which is 5115)
                                    /// @dev all wrappers created with rids = 0
                                    /// TODO create a wrapper with fungible rid later
                                    bytecodeWithArgs = abi.encodePacked(
                                        vaultBytecodes2[FORM_IMPLEMENTATION_IDS[j]].vaultBytecode[l],
                                        abi.encode(MockERC20(getContract(vars.chainId, UNDERLYING_TOKENS[k])), false)
                                    );

                                    vars.vault = _deployWithCreate2(bytecodeWithArgs, 1);
                                }
                            }
                            /// @dev Add VaultMock
                            contracts[vars.chainId][bytes32(
                                bytes(
                                    string.concat(
                                        UNDERLYING_TOKENS[k], vaultBytecodes2[FORM_IMPLEMENTATION_IDS[j]].vaultKinds[l]
                                    )
                                )
                            )] = vars.vault;
                            vaultsT[l] = vars.vault;
                        }
                        doubleVaults[k] = vaultsT;
                    }
                    vaults[vars.chainId][FORM_IMPLEMENTATION_IDS[j]] = doubleVaults;
                }
            }

            /// @dev deploy wrapper factory
            vars.eRC5115To4626WrapperFactory =
                address(new ERC5115To4626WrapperFactory{ salt: salt }(vars.superRegistry));

            contracts[vars.chainId][bytes32(bytes("ERC5115To4626WrapperFactory"))] = vars.eRC5115To4626WrapperFactory;

            if (NUMBER_OF_5115S[vars.chainId] > 0) {
                for (uint256 j = 0; j < NUMBER_OF_5115S[vars.chainId]; ++j) {
                    address new5115WrapperVault = ERC5115To4626WrapperFactory(vars.eRC5115To4626WrapperFactory)
                        .createWrapper(
                        ERC5115_VAULTS[vars.chainId][j],
                        ERC5115S_CHOSEN_ASSETS[vars.chainId][ERC5115_VAULTS[vars.chainId][j]].assetIn,
                        ERC5115S_CHOSEN_ASSETS[vars.chainId][ERC5115_VAULTS[vars.chainId][j]].assetOut
                    );

                    wrapped5115vaults[vars.chainId].push(new5115WrapperVault);
                }
            }

            /// @dev 9 - Deploy SuperformFactory
            vars.factory = address(new SuperformFactory{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("SuperformFactory"))] = vars.factory;

            vars.superRegistryC.setAddress(vars.superRegistryC.SUPERFORM_FACTORY(), vars.factory, vars.chainId);
            vars.superRBACC.grantRole(vars.superRBACC.BROADCASTER_ROLE(), vars.factory);

            /// @dev 10 - Deploy 4626Form implementations
            // Standard ERC4626 Form
            vars.erc4626Form = address(new ERC4626Form{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("ERC4626Form"))] = vars.erc4626Form;

            // Pendle ERC5115 Form
            vars.erc5115form = address(new ERC5115Form{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("ERC5115Form"))] = vars.erc5115form;

            //  ERC7540 Form
            vars.erc7540form = address(new ERC7540Form{ salt: salt }(vars.superRegistry, 4));
            contracts[vars.chainId][bytes32(bytes("ERC7540Form"))] = vars.erc7540form;

            /// @dev 11 - Add newly deployed form implementations to Factory
            ISuperformFactory(vars.factory).addFormImplementation(vars.erc4626Form, FORM_IMPLEMENTATION_IDS[0], 1);
            ISuperformFactory(vars.factory).addFormImplementation(vars.erc5115form, FORM_IMPLEMENTATION_IDS[1], 1);
            ISuperformFactory(vars.factory).addFormImplementation(vars.erc7540form, FORM_IMPLEMENTATION_IDS[2], 4);

            /// @dev 12 - Deploy SuperformRouter
            vars.superformRouter = address(new SuperformRouter{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("SuperformRouter"))] = vars.superformRouter;

            vars.superRegistryC.setAddress(vars.superRegistryC.SUPERFORM_ROUTER(), vars.superformRouter, vars.chainId);

            /// @dev 13 - Deploy SuperPositions
            vars.superPositions = address(
                new SuperPositions{ salt: salt }(
                    "https://ipfs-gateway.superform.xyz/ipns/k51qzi5uqu5dg90fqdo9j63m556wlddeux4mlgyythp30zousgh3huhyzouyq8/JSON/",
                    vars.superRegistry,
                    "SuperPositions",
                    "SP"
                )
            );

            contracts[vars.chainId][bytes32(bytes("SuperPositions"))] = vars.superPositions;
            vars.superRegistryC.setAddress(vars.superRegistryC.SUPER_POSITIONS(), vars.superPositions, vars.chainId);

            vars.superRBACC.grantRole(
                vars.superRBACC.BROADCASTER_ROLE(), contracts[vars.chainId][bytes32(bytes("SuperPositions"))]
            );

            /// @dev 14- deploy Payload Helper V2 and v1
            vars.PayloadHelper = address(new PayloadHelper{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("PayloadHelper"))] = vars.PayloadHelper;
            vars.superRegistryC.setAddress(vars.superRegistryC.PAYLOAD_HELPER(), vars.PayloadHelper, vars.chainId);

            contracts[vars.chainId][bytes32(bytes("PayloadHelperV1"))] =
                address(new PayloadHelperV1{ salt: salt }(vars.superRegistry));

            /// @dev 15 - Deploy PayMaster
            vars.payMaster = address(new PayMaster{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes32("PayMaster"))] = vars.payMaster;

            vars.superRegistryC.setAddress(vars.superRegistryC.PAYMASTER(), vars.payMaster, vars.chainId);

            /// @dev 16 - Deploy Dst Swapper
            vars.dstSwapper = address(new DstSwapper{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes32("DstSwapper"))] = vars.dstSwapper;

            vars.superRegistryC.setAddress(vars.superRegistryC.DST_SWAPPER(), vars.dstSwapper, vars.chainId);

            /// @dev 17 - Super Registry extra setters
            /// @dev BASE does not have SocketV1 available
            if (vars.chainId == BASE) {
                uint8[] memory bridgeIdsBase = new uint8[](6);
                bridgeIdsBase[0] = bridgeIds[0];
                bridgeIdsBase[1] = bridgeIds[3];
                bridgeIdsBase[2] = bridgeIds[4];
                bridgeIdsBase[3] = bridgeIds[5];
                bridgeIdsBase[4] = bridgeIds[6];
                bridgeIdsBase[5] = bridgeIds[7];

                address[] memory bridgeAddressesBase = new address[](6);
                bridgeAddressesBase[0] = bridgeAddresses[0];
                bridgeAddressesBase[1] = bridgeAddresses[3];
                bridgeAddressesBase[2] = bridgeAddresses[4];
                bridgeAddressesBase[3] = bridgeAddresses[5];
                bridgeAddressesBase[4] = bridgeAddresses[6];
                bridgeAddressesBase[5] = bridgeAddresses[7];

                address[] memory bridgeValidatorsBase = new address[](6);
                bridgeValidatorsBase[0] = bridgeValidators[0];
                bridgeValidatorsBase[1] = bridgeValidators[3];
                bridgeValidatorsBase[2] = bridgeValidators[4];
                bridgeValidatorsBase[3] = bridgeValidators[5];
                bridgeValidatorsBase[4] = bridgeValidators[6];
                bridgeValidatorsBase[5] = bridgeValidators[7];

                vars.superRegistryC.setBridgeAddresses(bridgeIdsBase, bridgeAddressesBase, bridgeValidatorsBase);
            } else {
                SuperRegistry(vars.superRegistry).setBridgeAddresses(bridgeIds, bridgeAddresses, bridgeValidators);
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
            } else if (vars.chainId == BARTIO) {
                uint8[] memory ambIdsBera = new uint8[](2);
                ambIdsBera[0] = 6;
                ambIdsBera[1] = 2;

                address[] memory ambAddressesBera = new address[](2);
                ambAddressesBera[0] = vars.lzV2Implementation;
                ambAddressesBera[1] = vars.hyperlaneImplementation;

                bool[] memory broadcastAmbBera = new bool[](2);
                broadcastAmbBera[0] = false;
                broadcastAmbBera[1] = false;

                SuperRegistry(payable(getContract(vars.chainId, "SuperRegistry"))).setAmbAddress(
                    ambIdsBera, ambAddressesBera, broadcastAmbBera
                );
            } else {
                vars.superRegistryC.setAmbAddress(ambIds, vars.ambAddresses, isBroadcastAMB);
            }

            /// @dev 18 setup setup srcChain keepers
            vars.superRegistryC.setAddress(vars.superRegistryC.PAYMENT_ADMIN(), deployer, vars.chainId);
            vars.superRegistryC.setAddress(vars.superRegistryC.CORE_REGISTRY_PROCESSOR(), deployer, vars.chainId);
            vars.superRegistryC.setAddress(vars.superRegistryC.BROADCAST_REGISTRY_PROCESSOR(), deployer, vars.chainId);
            vars.superRegistryC.setAddress(vars.superRegistryC.TIMELOCK_REGISTRY_PROCESSOR(), deployer, vars.chainId);
            vars.superRegistryC.setAddress(vars.superRegistryC.CORE_REGISTRY_UPDATER(), deployer, vars.chainId);
            vars.superRegistryC.setAddress(vars.superRegistryC.CORE_REGISTRY_RESCUER(), deployer, vars.chainId);
            vars.superRegistryC.setAddress(vars.superRegistryC.CORE_REGISTRY_DISPUTER(), deployer, vars.chainId);
            vars.superRegistryC.setAddress(vars.superRegistryC.DST_SWAPPER_PROCESSOR(), deployer, vars.chainId);
            vars.superRegistryC.setAddress(vars.superRegistryC.SUPERFORM_RECEIVER(), deployer, vars.chainId);

            vars.superRegistryC.setDelay(86_400);
            /// @dev 19 deploy emergency queue
            vars.emergencyQueue = address(new EmergencyQueue{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("EmergencyQueue"))] = vars.emergencyQueue;
            vars.superRegistryC.setAddress(vars.superRegistryC.EMERGENCY_QUEUE(), vars.emergencyQueue, vars.chainId);
            delete bridgeAddresses;
            delete bridgeValidators;

            /// @dev 20 deploy Rewards Distributor
            vars.rewardsDistributor = address(new RewardsDistributor{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("RewardsDistributor"))] = vars.rewardsDistributor;

            bytes32 rewardsId = keccak256("REWARDS_DISTRIBUTOR");
            vars.superRegistryC.setAddress(rewardsId, vars.rewardsDistributor, vars.chainId);
            vars.superRBACC.setRoleAdmin(keccak256("REWARDS_ADMIN_ROLE"), vars.superRBACC.PROTOCOL_ADMIN_ROLE());
            vars.superRBACC.grantRole(keccak256("REWARDS_ADMIN_ROLE"), deployer);

            /// @dev 21 deploy Superform Router Plus
            vars.superformRouterPlus = address(new SuperformRouterPlus{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("SuperformRouterPlus"))] = vars.superformRouterPlus;

            /// Set the global slippage
            SuperformRouterPlus(vars.superformRouterPlus).setGlobalSlippage(100);

            /// @dev deploy Superform Router Plus Async
            vars.superformRouterPlusAsync = address(new SuperformRouterPlusAsync{ salt: salt }(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("SuperformRouterPlusAsync"))] = vars.superformRouterPlusAsync;

            bytes32 routerPlusId = keccak256("SUPERFORM_ROUTER_PLUS");
            vars.superRegistryC.setAddress(routerPlusId, vars.superformRouterPlus, vars.chainId);

            bytes32 routerPlusAsyncId = keccak256("SUPERFORM_ROUTER_PLUS_ASYNC");
            vars.superRegistryC.setAddress(routerPlusAsyncId, vars.superformRouterPlusAsync, vars.chainId);

            vars.superRBACC.setRoleAdmin(keccak256("ROUTER_PLUS_PROCESSOR_ROLE"), vars.superRBACC.PROTOCOL_ADMIN_ROLE());
            vars.superRBACC.grantRole(keccak256("ROUTER_PLUS_PROCESSOR_ROLE"), deployer);
        }

        for (uint256 i = 0; i < chainIds.length; ++i) {
            vars.chainId = chainIds[i];
            vars.fork = FORKS[vars.chainId];

            vm.selectFork(vars.fork);

            vars.lzImplementation = getContract(vars.chainId, "LayerzeroImplementation");
            vars.lzV2Implementation = getContract(vars.chainId, "LayerzeroV2Implementation");
            vars.hyperlaneImplementation = getContract(vars.chainId, "HyperlaneImplementation");
            vars.wormholeImplementation = getContract(vars.chainId, "WormholeARImplementation");
            vars.wormholeSRImplementation = getContract(vars.chainId, "WormholeSRImplementation");
            vars.axelarImplementation = getContract(vars.chainId, "AxelarImplementation");
            vars.superRBAC = getContract(vars.chainId, "SuperRBAC");

            vars.superRegistry = getContract(vars.chainId, "SuperRegistry");
            vars.paymentHelper = getContract(vars.chainId, "PaymentHelper");
            vars.superRegistryC = SuperRegistry(payable(vars.superRegistry));
            vars.superRegistryC.setVaultLimitPerDestination(vars.chainId, 5);

            /// @dev Set all trusted remotes for each chain, configure amb chains ids, setupQuorum for all chains as
            /// 1
            /// and setup PaymentHelper
            /// @dev has to be performed after all main contracts have been deployed on all chains
            for (uint256 j = 0; j < chainIds.length; ++j) {
                uint256 trueChainIdIndex;

                // find selected chain ids and assign to selectedChainIds mapping
                for (uint256 k = 0; k < defaultChainIds.length; k++) {
                    if (chainIds[j] == defaultChainIds[k]) {
                        trueChainIdIndex = k;
                        break;
                    }
                }

                if (vars.chainId != chainIds[j]) {
                    vars.dstChainId = chainIds[j];

                    vars.dstLzChainId = lz_chainIds[trueChainIdIndex];
                    vars.dstHypChainId = hyperlane_chainIds[trueChainIdIndex];
                    vars.dstWormholeChainId = wormhole_chainIds[trueChainIdIndex];

                    vars.dstLzImplementation = getContract(vars.dstChainId, "LayerzeroImplementation");
                    vars.dstHyperlaneImplementation = getContract(vars.dstChainId, "HyperlaneImplementation");
                    vars.dstWormholeARImplementation = getContract(vars.dstChainId, "WormholeARImplementation");
                    vars.dstWormholeSRImplementation = getContract(vars.dstChainId, "WormholeSRImplementation");
                    vars.dstwormholeBroadcastHelper = getContract(vars.dstChainId, "WormholeBroadcastHelper");
                    vars.dstAxelarImplementation = getContract(vars.dstChainId, "AxelarImplementation");

                    if (!(vars.chainId == BARTIO || vars.dstChainId == BARTIO)) {
                        LayerzeroImplementation(payable(vars.lzImplementation)).setTrustedRemote(
                            vars.dstLzChainId, abi.encodePacked(vars.dstLzImplementation, vars.lzImplementation)
                        );
                        LayerzeroImplementation(payable(vars.lzImplementation)).setChainId(
                            vars.dstChainId, vars.dstLzChainId
                        );
                    }

                    LayerzeroV2Implementation(payable(vars.lzV2Implementation)).setPeer(
                        lz_v2_chainIds[trueChainIdIndex],
                        bytes32(uint256(uint160(getContract(vars.dstChainId, "LayerzeroV2Implementation"))))
                    );

                    LayerzeroV2Implementation(payable(vars.lzV2Implementation)).setChainId(
                        vars.dstChainId, lz_v2_chainIds[trueChainIdIndex]
                    );

                    if (!(vars.chainId == FANTOM || vars.dstChainId == FANTOM)) {
                        HyperlaneImplementation(payable(vars.hyperlaneImplementation)).setReceiver(
                            vars.dstHypChainId, vars.dstHyperlaneImplementation
                        );

                        HyperlaneImplementation(payable(vars.hyperlaneImplementation)).setChainId(
                            vars.dstChainId, vars.dstHypChainId
                        );
                    }

                    if (
                        !(
                            vars.chainId == LINEA || vars.dstChainId == LINEA || vars.chainId == BARTIO
                                || vars.dstChainId == BARTIO
                        )
                    ) {
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
                    if (!(vars.chainId == BARTIO || vars.dstChainId == BARTIO)) {
                        AxelarImplementation(payable(vars.axelarImplementation)).setChainId(
                            vars.dstChainId, axelar_chainIds[trueChainIdIndex]
                        );

                        AxelarImplementation(payable(vars.axelarImplementation)).setReceiver(
                            axelar_chainIds[trueChainIdIndex], vars.dstAxelarImplementation
                        );
                    }

                    /// sets the relayer address on all subsequent chains
                    SuperRBAC(vars.superRBAC).grantRole(
                        SuperRBAC(vars.superRBAC).WORMHOLE_VAA_RELAYER_ROLE(), vars.dstwormholeBroadcastHelper
                    );

                    vars.superRegistryC.setRequiredMessagingQuorum(vars.dstChainId, 1);
                    vars.superRegistryC.setVaultLimitPerDestination(vars.dstChainId, 5);
                    vars.superRegistryC.setAddress(
                        keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE"), deployer, vars.dstChainId
                    );

                    /// swap gas cost: 50000
                    /// update gas cost: 40000
                    /// deposit gas cost: 70000
                    /// withdraw gas cost: 80000
                    /// default gas price: 50 Gwei
                    PaymentHelper(payable(vars.paymentHelper)).addRemoteChain(
                        vars.dstChainId,
                        IPaymentHelper.PaymentHelperConfig(
                            PRICE_FEEDS[vars.chainId][vars.dstChainId],
                            address(0),
                            abi.decode(GAS_USED[vars.dstChainId][3], (uint256)),
                            abi.decode(GAS_USED[vars.dstChainId][4], (uint256)),
                            vars.dstChainId == ARBI ? 1_000_000 : 200_000,
                            abi.decode(GAS_USED[vars.dstChainId][6], (uint256)),
                            nativePrices[trueChainIdIndex],
                            gasPrices[trueChainIdIndex],
                            750,
                            2_000_000,
                            /// @dev ackGasCost to move a msg from dst to source
                            10_000,
                            10_000,
                            abi.decode(GAS_USED[vars.dstChainId][13], (uint256))
                        )
                    );

                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.SUPERFORM_ROUTER(),
                        getContract(vars.dstChainId, "SuperformRouter"),
                        vars.dstChainId
                    );

                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.SUPERFORM_FACTORY(),
                        getContract(vars.dstChainId, "SuperformFactory"),
                        vars.dstChainId
                    );

                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.PAYMASTER(), getContract(vars.dstChainId, "PayMaster"), vars.dstChainId
                    );

                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.PAYMENT_HELPER(),
                        getContract(vars.dstChainId, "PaymentHelper"),
                        vars.dstChainId
                    );

                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.CORE_STATE_REGISTRY(),
                        getContract(vars.dstChainId, "CoreStateRegistry"),
                        vars.dstChainId
                    );

                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.DST_SWAPPER(), getContract(vars.dstChainId, "DstSwapper"), vars.dstChainId
                    );

                    vars.superRegistryC.setAddress(
                        keccak256("ASYNC_STATE_REGISTRY"),
                        getContract(vars.dstChainId, "AsyncStateRegistry"),
                        vars.dstChainId
                    );

                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.BROADCAST_REGISTRY(),
                        getContract(vars.dstChainId, "BroadcastRegistry"),
                        vars.dstChainId
                    );

                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.SUPER_POSITIONS(),
                        getContract(vars.dstChainId, "SuperPositions"),
                        vars.dstChainId
                    );

                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.SUPER_RBAC(), getContract(vars.dstChainId, "SuperRBAC"), vars.dstChainId
                    );

                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.PAYLOAD_HELPER(),
                        getContract(vars.dstChainId, "PayloadHelper"),
                        vars.dstChainId
                    );

                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.EMERGENCY_QUEUE(),
                        getContract(vars.dstChainId, "EmergencyQueue"),
                        vars.dstChainId
                    );

                    vars.superRegistryC.setAddress(vars.superRegistryC.PAYMENT_ADMIN(), deployer, vars.dstChainId);
                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.CORE_REGISTRY_PROCESSOR(), deployer, vars.dstChainId
                    );
                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.CORE_REGISTRY_UPDATER(), deployer, vars.dstChainId
                    );
                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.BROADCAST_REGISTRY_PROCESSOR(), deployer, vars.dstChainId
                    );
                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.TIMELOCK_REGISTRY_PROCESSOR(), deployer, vars.dstChainId
                    );

                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.CORE_REGISTRY_RESCUER(), deployer, vars.dstChainId
                    );
                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.CORE_REGISTRY_DISPUTER(), deployer, vars.dstChainId
                    );
                    vars.superRegistryC.setAddress(
                        vars.superRegistryC.DST_SWAPPER_PROCESSOR(), deployer, vars.dstChainId
                    );
                    vars.superRegistryC.setAddress(vars.superRegistryC.SUPERFORM_RECEIVER(), deployer, vars.dstChainId);

                    vars.superRegistryC.setAddress(keccak256("REWARDS_DISTRIBUTOR"), deployer, vars.dstChainId);
                } else {
                    /// ack gas cost: 40000
                    /// timelock step form cost: 50000
                    /// default gas price: 50 Gwei
                    PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(
                        vars.chainId, 1, abi.encode(PRICE_FEEDS[vars.chainId][vars.chainId])
                    );
                    PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(
                        vars.chainId, 7, abi.encode(nativePrices[trueChainIdIndex])
                    );
                    PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(
                        vars.chainId, 8, abi.encode(gasPrices[trueChainIdIndex])
                    );

                    /// @dev gas per byte
                    PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(vars.chainId, 9, abi.encode(750));

                    /// @dev ackGasCost to mint superPositions
                    PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(
                        vars.chainId, 10, abi.encode(vars.chainId == ARBI ? 500_000 : 150_000)
                    );

                    PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(vars.chainId, 11, abi.encode(50_000));

                    PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(vars.chainId, 12, abi.encode(10_000));

                    /// @dev !WARNING - Default value for updateWithdrawGas for now
                    /// @dev 0.01 ether is just a mock value. Wormhole fees are currently 0 on mainnet
                    PaymentHelper(payable(vars.paymentHelper)).updateRegisterAERC20Params(
                        generateBroadcastParams(0.01 ether)
                    );
                }
            }
        }

        for (uint256 i = 0; i < chainIds.length; ++i) {
            vm.selectFork(FORKS[chainIds[i]]);

            /// @dev 18 - create test superforms when the whole state registry is configured
            for (uint256 j = 0; j < FORM_IMPLEMENTATION_IDS.length; ++j) {
                if (j != 1) {
                    for (uint256 k = 0; k < UNDERLYING_TOKENS.length; ++k) {
                        uint256 lenBytecodes = vaultBytecodes2[FORM_IMPLEMENTATION_IDS[j]].vaultBytecode.length;

                        for (uint256 l = 0; l < lenBytecodes; l++) {
                            address vault = vaults[chainIds[i]][FORM_IMPLEMENTATION_IDS[j]][k][l];

                            if (vault == address(0)) continue;

                            uint256 superformId;
                            (superformId, vars.superform) = ISuperformFactory(
                                contracts[chainIds[i]][bytes32(bytes("SuperformFactory"))]
                            ).createSuperform(FORM_IMPLEMENTATION_IDS[j], vault);

                            if (FORM_IMPLEMENTATION_IDS[j] == 4) {
                                // triggers _vaultKindCheck to set async type
                                ERC7540Form(vars.superform).forwardDustToPaymaster(
                                    ERC7540Form(vars.superform).getVaultAsset()
                                );
                                /// @dev activating centrifuge real vault (note: this flow will be needed in
                                /// production)
                                if (
                                    (vault == 0x3b33D257E77E018326CCddeCA71cf9350C585A66 && LAUNCH_TESTNETS)
                                        || vault == 0x1d01Ef1997d44206d839b78bA6813f60F1B3A970
                                ) {
                                    vars.token = IERC7540(vault).share();
                                    vars.mgr = TrancheTokenLike(vars.token).hook();
                                    vm.startPrank(RestrictionManagerLike(vars.mgr).root());

                                    /// @dev TODO remove updateMemeber can be removed for superform
                                    RestrictionManagerLike(vars.mgr).updateMember(
                                        vars.token, vars.superform, type(uint64).max
                                    );
                                    RestrictionManagerLike(vars.mgr).updateMember(
                                        vars.token, users[0], type(uint64).max
                                    );
                                    RestrictionManagerLike(vars.mgr).updateMember(
                                        vars.token, users[1], type(uint64).max
                                    );
                                    RestrictionManagerLike(vars.mgr).updateMember(
                                        vars.token, users[2], type(uint64).max
                                    );

                                    vm.startPrank(deployer);
                                }
                            }

                            contracts[chainIds[i]][bytes32(
                                bytes(
                                    string.concat(
                                        UNDERLYING_TOKENS[k],
                                        vaultBytecodes2[FORM_IMPLEMENTATION_IDS[j]].vaultKinds[l],
                                        "Superform",
                                        Strings.toString(FORM_IMPLEMENTATION_IDS[j])
                                    )
                                )
                            )] = vars.superform;
                        }
                    }
                } else if (j == 1) {
                    if (NUMBER_OF_5115S[chainIds[i]] > 0) {
                        for (uint256 k = 0; k < NUMBER_OF_5115S[chainIds[i]]; ++k) {
                            uint256 lenBytecodes = vaultBytecodes2[FORM_IMPLEMENTATION_IDS[j]].vaultBytecode.length;

                            for (uint256 l = 0; l < lenBytecodes; l++) {
                                /// @dev warning: the true vault for 5115 is the one underneath the wrapped version
                                (, vars.superform) = ISuperformFactory(
                                    contracts[chainIds[i]][bytes32(bytes("SuperformFactory"))]
                                ).createSuperform(FORM_IMPLEMENTATION_IDS[j], wrapped5115vaults[chainIds[i]][k]);

                                contracts[chainIds[i]][bytes32(
                                    bytes(
                                        string.concat(
                                            ERC5115_VAULTS_NAMES[chainIds[i]][k],
                                            vaultBytecodes2[FORM_IMPLEMENTATION_IDS[j]].vaultKinds[l],
                                            "Superform",
                                            Strings.toString(FORM_IMPLEMENTATION_IDS[j])
                                        )
                                    )
                                )] = vars.superform;
                            }
                        }
                    }
                }
            }
        }

        _setTokenPriceFeeds();

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        MISC. HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _setTokenPriceFeeds() internal {
        /// @dev set chainlink price feeds
        /// ETH
        tokenPriceFeeds[ETH][getContract(ETH, "DAI")] = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
        tokenPriceFeeds[ETH][getContract(ETH, "USDC")] = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
        /// @dev note using ETH's price feed for WETH (as 1 WETH = 1 ETH), also coz chainlink doesn't provide
        tokenPriceFeeds[ETH][getContract(ETH, "WETH")] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        tokenPriceFeeds[ETH][NATIVE_TOKEN] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        tokenPriceFeeds[ETH][getContract(ETH, "ezETH")] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        tokenPriceFeeds[ETH][getContract(ETH, "wstETH")] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        /// @dev using USDC price feed
        tokenPriceFeeds[ETH][getContract(ETH, "sUSDe")] = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
        tokenPriceFeeds[ETH][getContract(ETH, "USDe")] = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
        tokenPriceFeeds[ETH][getContract(ETH, "tUSD")] = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;

        /// BSC
        tokenPriceFeeds[BSC][getContract(BSC, "DAI")] = 0x132d3C0B1D2cEa0BC552588063bdBb210FDeecfA;
        tokenPriceFeeds[BSC][getContract(BSC, "USDC")] = 0x51597f405303C4377E36123cBc172b13269EA163;
        /// @dev note using ETH's price feed for WETH (as 1 WETH = 1 ETH)
        tokenPriceFeeds[BSC][getContract(BSC, "WETH")] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        tokenPriceFeeds[BSC][NATIVE_TOKEN] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        tokenPriceFeeds[BSC][getContract(BSC, "ezETH")] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        tokenPriceFeeds[BSC][getContract(BSC, "wstETH")] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        /// @dev using USDC price feed
        tokenPriceFeeds[BSC][getContract(BSC, "sUSDe")] = 0x51597f405303C4377E36123cBc172b13269EA163;
        tokenPriceFeeds[BSC][getContract(BSC, "USDe")] = 0x51597f405303C4377E36123cBc172b13269EA163;
        tokenPriceFeeds[BSC][getContract(BSC, "tUSD")] = 0x51597f405303C4377E36123cBc172b13269EA163;

        /// AVAX
        tokenPriceFeeds[AVAX][getContract(AVAX, "DAI")] = 0x51D7180edA2260cc4F6e4EebB82FEF5c3c2B8300;
        tokenPriceFeeds[AVAX][getContract(AVAX, "USDC")] = 0xF096872672F44d6EBA71458D74fe67F9a77a23B9;
        /// @dev note using ETH's price feed for WETH (as 1 WETH = 1 ETH)
        tokenPriceFeeds[AVAX][getContract(AVAX, "WETH")] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        tokenPriceFeeds[AVAX][NATIVE_TOKEN] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        tokenPriceFeeds[AVAX][getContract(AVAX, "ezETH")] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        tokenPriceFeeds[AVAX][getContract(AVAX, "wstETH")] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        /// @dev using USDC price feed
        tokenPriceFeeds[AVAX][getContract(AVAX, "sUSDe")] = 0xF096872672F44d6EBA71458D74fe67F9a77a23B9;
        tokenPriceFeeds[AVAX][getContract(AVAX, "USDe")] = 0xF096872672F44d6EBA71458D74fe67F9a77a23B9;
        tokenPriceFeeds[AVAX][getContract(AVAX, "tUSD")] = 0xF096872672F44d6EBA71458D74fe67F9a77a23B9;

        /// POLYGON
        tokenPriceFeeds[POLY][getContract(POLY, "DAI")] = 0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D;
        tokenPriceFeeds[POLY][getContract(POLY, "USDC")] = 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7;
        /// @dev note using ETH's price feed for WETH (as 1 WETH = 1 ETH)
        tokenPriceFeeds[POLY][getContract(POLY, "WETH")] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        tokenPriceFeeds[POLY][NATIVE_TOKEN] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        tokenPriceFeeds[POLY][getContract(POLY, "ezETH")] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        tokenPriceFeeds[POLY][getContract(POLY, "wstETH")] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        /// @dev using USDC price feed
        tokenPriceFeeds[POLY][getContract(POLY, "sUSDe")] = 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7;
        tokenPriceFeeds[POLY][getContract(POLY, "USDe")] = 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7;
        tokenPriceFeeds[POLY][getContract(POLY, "tUSD")] = 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7;

        /// OPTIMISM
        tokenPriceFeeds[OP][getContract(OP, "DAI")] = 0x8dBa75e83DA73cc766A7e5a0ee71F656BAb470d6;
        tokenPriceFeeds[OP][getContract(OP, "USDC")] = 0x16a9FA2FDa030272Ce99B29CF780dFA30361E0f3;
        /// @dev note using ETH's price feed for WETH (as 1 WETH = 1 ETH)
        tokenPriceFeeds[OP][getContract(OP, "WETH")] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        tokenPriceFeeds[OP][NATIVE_TOKEN] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        tokenPriceFeeds[OP][getContract(OP, "ezETH")] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        tokenPriceFeeds[OP][getContract(OP, "wstETH")] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        /// @dev using USDC price feed
        tokenPriceFeeds[OP][getContract(OP, "sUSDe")] = 0x16a9FA2FDa030272Ce99B29CF780dFA30361E0f3;
        tokenPriceFeeds[OP][getContract(OP, "USDe")] = 0x16a9FA2FDa030272Ce99B29CF780dFA30361E0f3;
        tokenPriceFeeds[OP][getContract(OP, "tUSD")] = 0x16a9FA2FDa030272Ce99B29CF780dFA30361E0f3;

        /// ARBITRUM
        tokenPriceFeeds[ARBI][getContract(ARBI, "DAI")] = 0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB;
        tokenPriceFeeds[ARBI][getContract(ARBI, "USDC")] = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
        /// @dev note using ETH's price feed for WETH (as 1 WETH = 1 ETH)
        tokenPriceFeeds[ARBI][getContract(ARBI, "WETH")] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        tokenPriceFeeds[ARBI][NATIVE_TOKEN] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        tokenPriceFeeds[ARBI][getContract(ARBI, "ezETH")] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        tokenPriceFeeds[ARBI][getContract(ARBI, "wstETH")] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        /// @dev using USDC price feed
        tokenPriceFeeds[ARBI][getContract(ARBI, "sUSDe")] = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
        tokenPriceFeeds[ARBI][getContract(ARBI, "USDe")] = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
        tokenPriceFeeds[ARBI][getContract(ARBI, "tUSD")] = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;

        /// BASE
        tokenPriceFeeds[BASE][getContract(BASE, "DAI")] = 0x591e79239a7d679378eC8c847e5038150364C78F;
        tokenPriceFeeds[BASE][getContract(BASE, "USDC")] = 0x7e860098F58bBFC8648a4311b374B1D669a2bc6B;
        /// @dev note using ETH's price feed for WETH (as 1 WETH = 1 ETH)
        tokenPriceFeeds[BASE][getContract(BASE, "WETH")] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        tokenPriceFeeds[BASE][NATIVE_TOKEN] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        tokenPriceFeeds[BASE][getContract(BASE, "ezETH")] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        tokenPriceFeeds[BASE][getContract(BASE, "wstETH")] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        /// @dev using USDC price feed
        tokenPriceFeeds[BASE][getContract(BASE, "sUSDe")] = 0x7e860098F58bBFC8648a4311b374B1D669a2bc6B;
        tokenPriceFeeds[BASE][getContract(BASE, "USDe")] = 0x7e860098F58bBFC8648a4311b374B1D669a2bc6B;
        tokenPriceFeeds[BASE][getContract(BASE, "tUSD")] = 0x7e860098F58bBFC8648a4311b374B1D669a2bc6B;

        /// FANTOM
        tokenPriceFeeds[FANTOM][getContract(FANTOM, "DAI")] = 0x91d5DEFAFfE2854C7D02F50c80FA1fdc8A721e52;
        tokenPriceFeeds[FANTOM][getContract(FANTOM, "USDC")] = 0x2553f4eeb82d5A26427b8d1106C51499CBa5D99c;
        /// @dev note using ETH's price feed for WETH (as 1 WETH = 1 ETH)
        tokenPriceFeeds[FANTOM][getContract(FANTOM, "WETH")] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        tokenPriceFeeds[FANTOM][NATIVE_TOKEN] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        tokenPriceFeeds[FANTOM][getContract(FANTOM, "ezETH")] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        tokenPriceFeeds[FANTOM][getContract(FANTOM, "wstETH")] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        /// @dev using USDC price feed
        tokenPriceFeeds[FANTOM][getContract(FANTOM, "sUSDe")] = 0x2553f4eeb82d5A26427b8d1106C51499CBa5D99c;
        tokenPriceFeeds[FANTOM][getContract(FANTOM, "USDe")] = 0x2553f4eeb82d5A26427b8d1106C51499CBa5D99c;
        tokenPriceFeeds[FANTOM][getContract(FANTOM, "tUSD")] = 0x2553f4eeb82d5A26427b8d1106C51499CBa5D99c;

        /// SEPOLIA
        tokenPriceFeeds[SEPOLIA][getContract(SEPOLIA, "DAI")] = 0x14866185B1962B63C3Ea9E03Bc1da838bab34C19;
        tokenPriceFeeds[SEPOLIA][getContract(SEPOLIA, "USDC")] = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
        /// @dev note using ETH's price feed for WETH (as 1 WETH = 1 ETH)
        tokenPriceFeeds[SEPOLIA][getContract(SEPOLIA, "WETH")] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        tokenPriceFeeds[SEPOLIA][NATIVE_TOKEN] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        tokenPriceFeeds[SEPOLIA][getContract(SEPOLIA, "ezETH")] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        tokenPriceFeeds[SEPOLIA][getContract(SEPOLIA, "wstETH")] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        /// @dev using USDC price feed
        tokenPriceFeeds[SEPOLIA][getContract(SEPOLIA, "sUSDe")] = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
        tokenPriceFeeds[SEPOLIA][getContract(SEPOLIA, "USDe")] = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
        tokenPriceFeeds[SEPOLIA][getContract(SEPOLIA, "tUSD")] = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;

        /// BSC_TESTNET
        tokenPriceFeeds[BSC_TESTNET][getContract(BSC_TESTNET, "DAI")] = 0xE4eE17114774713d2De0eC0f035d4F7665fc025D;
        tokenPriceFeeds[BSC_TESTNET][getContract(BSC_TESTNET, "USDC")] = 0x90c069C4538adAc136E051052E14c1cD799C41B7;
        /// @dev note using ETH's price feed for WETH (as 1 WETH = 1 ETH)
        tokenPriceFeeds[BSC_TESTNET][getContract(BSC_TESTNET, "WETH")] = 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7;
        tokenPriceFeeds[BSC_TESTNET][NATIVE_TOKEN] = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;
        tokenPriceFeeds[BSC_TESTNET][getContract(BSC_TESTNET, "ezETH")] = 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7;
        tokenPriceFeeds[BSC_TESTNET][getContract(BSC_TESTNET, "wstETH")] = 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7;
        /// @dev using USDC price feed
        tokenPriceFeeds[BSC_TESTNET][getContract(BSC_TESTNET, "sUSDe")] = 0x90c069C4538adAc136E051052E14c1cD799C41B7;
        tokenPriceFeeds[BSC_TESTNET][getContract(BSC_TESTNET, "USDe")] = 0x90c069C4538adAc136E051052E14c1cD799C41B7;
        tokenPriceFeeds[BSC_TESTNET][getContract(BSC_TESTNET, "tUSD")] = 0x90c069C4538adAc136E051052E14c1cD799C41B7;

        /// LINEA
        tokenPriceFeeds[LINEA][getContract(LINEA, "DAI")] = 0xAADAa473C1bDF7317ec07c915680Af29DeBfdCb5;
        tokenPriceFeeds[LINEA][getContract(LINEA, "USDC")] = 0xAADAa473C1bDF7317ec07c915680Af29DeBfdCb5;
        /// @dev note using ETH's price feed for WETH (as 1 WETH = 1 ETH)
        tokenPriceFeeds[LINEA][getContract(LINEA, "WETH")] = 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA;
        tokenPriceFeeds[LINEA][NATIVE_TOKEN] = 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA;
        tokenPriceFeeds[LINEA][getContract(LINEA, "ezETH")] = 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA;
        tokenPriceFeeds[LINEA][getContract(LINEA, "wstETH")] = 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA;
        /// @dev using USDC price feed
        tokenPriceFeeds[LINEA][getContract(LINEA, "sUSDe")] = 0xAADAa473C1bDF7317ec07c915680Af29DeBfdCb5;
        tokenPriceFeeds[LINEA][getContract(LINEA, "USDe")] = 0xAADAa473C1bDF7317ec07c915680Af29DeBfdCb5;

        /// BARTIO
        tokenPriceFeeds[BARTIO][getContract(BARTIO, "DAI")] = 0x44d8Fa336d836D4fCC1f55B3B3764bE5a3982836;
        tokenPriceFeeds[BARTIO][getContract(BARTIO, "USDC")] = 0x0cE68166FBD4D7e8688B9C462A254e095cBd8FC1;
        tokenPriceFeeds[BARTIO][getContract(BARTIO, "WETH")] = 0x42324DA2cB327D9DDE198d10A7A68870d761C390;
    }

    function _preDeploymentSetup(bool pinnedBlock, bool invariant) internal {
        /// @dev These blocks have been chosen arbitrarily - can be updated to other values
        mapping(uint64 => uint256) storage forks = FORKS;
        for (uint256 i = 0; i < chainIds.length; i++) {
            // find selected chain ids and assign to selectedChainIds mapping
            for (uint256 j = 0; j < defaultChainIds.length; j++) {
                if (chainIds[i] == defaultChainIds[j]) {
                    selectedChainIds[chainIds[i]] = true;
                    break;
                }
            }
        }
        if (!invariant) {
            forks[ETH] = selectedChainIds[ETH]
                ? pinnedBlock ? vm.createFork(ETHEREUM_RPC_URL, 20_574_913) : vm.createFork(ETHEREUM_RPC_URL_QN)
                : 999;
            forks[BSC] = selectedChainIds[BSC]
                ? pinnedBlock ? vm.createFork(BSC_RPC_URL, 42_996_977) : vm.createFork(BSC_RPC_URL_QN)
                : 999;
            forks[AVAX] = selectedChainIds[AVAX]
                ? pinnedBlock ? vm.createFork(AVALANCHE_RPC_URL, 46_289_230) : vm.createFork(AVALANCHE_RPC_URL_QN)
                : 999;
            forks[POLY] = selectedChainIds[POLY]
                ? pinnedBlock ? vm.createFork(POLYGON_RPC_URL, 60_619_414) : vm.createFork(POLYGON_RPC_URL_QN)
                : 999;
            forks[ARBI] = selectedChainIds[ARBI]
                ? pinnedBlock ? vm.createFork(ARBITRUM_RPC_URL, 262_379_111) : vm.createFork(ARBITRUM_RPC_URL_QN)
                : 999;
            forks[OP] = selectedChainIds[OP]
                ? pinnedBlock ? vm.createFork(OPTIMISM_RPC_URL, 126_486_035) : vm.createFork(OPTIMISM_RPC_URL_QN)
                : 999;
            forks[BASE] = selectedChainIds[BASE]
                ? pinnedBlock ? vm.createFork(BASE_RPC_URL) : vm.createFork(BASE_RPC_URL_QN)
                : 999;
            forks[FANTOM] = selectedChainIds[FANTOM]
                ? pinnedBlock ? vm.createFork(FANTOM_RPC_URL, 94_220_643) : vm.createFork(FANTOM_RPC_URL_QN)
                : 999;
            forks[SEPOLIA] = selectedChainIds[SEPOLIA]
                ? pinnedBlock ? vm.createFork(SEPOLIA_RPC_URL_QN, 6_624_692) : vm.createFork(SEPOLIA_RPC_URL_QN)
                : 999;
            forks[BSC_TESTNET] = selectedChainIds[BSC_TESTNET]
                ? pinnedBlock ? vm.createFork(BSC_TESTNET_RPC_URL_QN, 41_624_319) : vm.createFork(BSC_TESTNET_RPC_URL_QN)
                : 999;
            forks[LINEA] = selectedChainIds[LINEA]
                ? pinnedBlock ? vm.createFork(LINEA_RPC_URL, 12_323_016) : vm.createFork(LINEA_RPC_URL_QN)
                : 999;
            forks[BLAST] = selectedChainIds[BLAST]
                ? pinnedBlock ? vm.createFork(BLAST_RPC_URL, 9_880_537) : vm.createFork(BLAST_RPC_URL_QN)
                : 999;
            forks[BARTIO] = selectedChainIds[BARTIO]
                ? pinnedBlock ? vm.createFork(BARTIO_RPC_URL, 5_274_270) : vm.createFork(BARTIO_RPC_URL_QN)
                : 999;
        }

        mapping(uint64 => string) storage rpcURLs = RPC_URLS;
        rpcURLs[ETH] = ETHEREUM_RPC_URL;
        rpcURLs[BSC] = BSC_RPC_URL;
        rpcURLs[AVAX] = AVALANCHE_RPC_URL;
        rpcURLs[POLY] = POLYGON_RPC_URL;
        rpcURLs[ARBI] = ARBITRUM_RPC_URL;
        rpcURLs[OP] = OPTIMISM_RPC_URL;
        rpcURLs[BASE] = BASE_RPC_URL;
        rpcURLs[FANTOM] = FANTOM_RPC_URL;
        rpcURLs[SEPOLIA] = SEPOLIA_RPC_URL_QN;
        rpcURLs[BSC_TESTNET] = BSC_TESTNET_RPC_URL_QN;

        rpcURLs[LINEA] = LINEA_RPC_URL;
        rpcURLs[BLAST] = BLAST_RPC_URL;
        rpcURLs[BARTIO] = BARTIO_RPC_URL;

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
        gasUsed[SEPOLIA][3] = abi.encode(400_000);
        gasUsed[BSC_TESTNET][3] = abi.encode(650_000);
        gasUsed[LINEA][3] = abi.encode(600_000);
        gasUsed[BLAST][3] = abi.encode(600_000);
        gasUsed[BARTIO][3] = abi.encode(600_000);

        // updateDepositGasUsed == 4 (only used on deposits for now)
        gasUsed[ETH][4] = abi.encode(225_000);
        gasUsed[BSC][4] = abi.encode(225_000);
        gasUsed[AVAX][4] = abi.encode(200_000);
        gasUsed[POLY][4] = abi.encode(200_000);
        gasUsed[OP][4] = abi.encode(200_000);
        gasUsed[ARBI][4] = abi.encode(1_400_000);
        gasUsed[BASE][4] = abi.encode(200_000);
        gasUsed[FANTOM][4] = abi.encode(734_757);
        gasUsed[SEPOLIA][4] = abi.encode(225_000);
        gasUsed[BSC_TESTNET][4] = abi.encode(225_000);
        gasUsed[LINEA][4] = abi.encode(200_000);
        gasUsed[BLAST][4] = abi.encode(200_000);
        gasUsed[BARTIO][4] = abi.encode(200_000);

        // withdrawGasUsed == 6
        gasUsed[ETH][6] = abi.encode(1_272_330);
        gasUsed[BSC][6] = abi.encode(837_167);
        gasUsed[AVAX][6] = abi.encode(1_494_028);
        gasUsed[POLY][6] = abi.encode(1_119_242);
        gasUsed[OP][6] = abi.encode(1_716_146);
        gasUsed[ARBI][6] = abi.encode(1_654_955);
        gasUsed[BASE][6] = abi.encode(1_178_778);
        gasUsed[FANTOM][6] = abi.encode(567_881);
        gasUsed[SEPOLIA][6] = abi.encode(1_272_330);
        gasUsed[BSC_TESTNET][6] = abi.encode(837_167);
        gasUsed[LINEA][6] = abi.encode(1_178_778);
        gasUsed[BLAST][6] = abi.encode(1_178_778);
        gasUsed[BARTIO][6] = abi.encode(1_178_778);

        // updateWithdrawGasUsed == 13
        gasUsed[ETH][13] = abi.encode(356_828);
        gasUsed[BSC][13] = abi.encode(900_085);
        gasUsed[AVAX][13] = abi.encode(600_746);
        gasUsed[POLY][13] = abi.encode(597_978);
        gasUsed[OP][13] = abi.encode(649_240);
        gasUsed[ARBI][13] = abi.encode(1_366_122);
        gasUsed[BASE][13] = abi.encode(919_466);
        gasUsed[FANTOM][13] = abi.encode(2_003_157);
        gasUsed[SEPOLIA][13] = abi.encode(356_828);
        gasUsed[BSC_TESTNET][13] = abi.encode(900_085);
        gasUsed[LINEA][13] = abi.encode(919_466);
        gasUsed[BLAST][13] = abi.encode(919_466);
        gasUsed[BARTIO][13] = abi.encode(919_466);

        mapping(uint64 => address) storage lzEndpointsStorage = LZ_ENDPOINTS;
        lzEndpointsStorage[ETH] = ETH_lzEndpoint;
        lzEndpointsStorage[BSC] = BSC_lzEndpoint;
        lzEndpointsStorage[AVAX] = AVAX_lzEndpoint;
        lzEndpointsStorage[POLY] = POLY_lzEndpoint;
        lzEndpointsStorage[ARBI] = ARBI_lzEndpoint;
        lzEndpointsStorage[OP] = OP_lzEndpoint;
        lzEndpointsStorage[BASE] = BASE_lzEndpoint;
        lzEndpointsStorage[FANTOM] = FANTOM_lzEndpoint;
        lzEndpointsStorage[SEPOLIA] = SEPOLIA_lzEndpoint;
        lzEndpointsStorage[BSC_TESTNET] = BSC_TESTNET_lzEndpoint;
        lzEndpointsStorage[LINEA] = LINEA_lzEndpoint;
        lzEndpointsStorage[BLAST] = BLAST_lzEndpoint;

        mapping(uint64 => address) storage hyperlaneMailboxesStorage = HYPERLANE_MAILBOXES;
        hyperlaneMailboxesStorage[ETH] = hyperlaneMailboxes[0];
        hyperlaneMailboxesStorage[BSC] = hyperlaneMailboxes[1];
        hyperlaneMailboxesStorage[AVAX] = hyperlaneMailboxes[2];
        hyperlaneMailboxesStorage[POLY] = hyperlaneMailboxes[3];
        hyperlaneMailboxesStorage[ARBI] = hyperlaneMailboxes[4];
        hyperlaneMailboxesStorage[OP] = hyperlaneMailboxes[5];
        hyperlaneMailboxesStorage[BASE] = hyperlaneMailboxes[6];
        hyperlaneMailboxesStorage[FANTOM] = hyperlaneMailboxes[7];
        hyperlaneMailboxesStorage[SEPOLIA] = hyperlaneMailboxes[8];
        hyperlaneMailboxesStorage[BSC_TESTNET] = hyperlaneMailboxes[9];
        hyperlaneMailboxesStorage[LINEA] = hyperlaneMailboxes[10];
        hyperlaneMailboxesStorage[BLAST] = hyperlaneMailboxes[11];
        hyperlaneMailboxesStorage[BARTIO] = hyperlaneMailboxes[12];

        mapping(uint64 => uint16) storage wormholeChainIdsStorage = WORMHOLE_CHAIN_IDS;

        for (uint256 i = 0; i < chainIds.length; ++i) {
            uint256 trueChainIdIndex;

            for (uint256 j = 0; j < defaultChainIds.length; j++) {
                if (chainIds[i] == defaultChainIds[j]) {
                    trueChainIdIndex = j;
                    break;
                }
            }
            wormholeChainIdsStorage[chainIds[i]] = wormhole_chainIds[trueChainIdIndex];
            AXELAR_GATEWAYS[chainIds[i]] = axelarGateway[trueChainIdIndex];
            AXELAR_CHAIN_IDS[chainIds[i]] = axelar_chainIds[trueChainIdIndex];
        }

        /// price feeds on all chains, for paymentHelper: chain => asset => priceFeed (against USD)
        mapping(uint64 => mapping(uint64 => address)) storage priceFeeds = PRICE_FEEDS;

        /// ETH
        priceFeeds[ETH][ETH] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][BSC] = 0x14e613AC84a31f709eadbdF89C6CC390fDc9540A;
        priceFeeds[ETH][AVAX] = 0xFF3EEb22B5E3dE6e705b44749C2559d704923FD7;
        priceFeeds[ETH][POLY] = 0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676;
        priceFeeds[ETH][OP] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][ARBI] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][BASE] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][FANTOM] = address(0);
        priceFeeds[ETH][SEPOLIA] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][BSC_TESTNET] = 0x14e613AC84a31f709eadbdF89C6CC390fDc9540A;
        priceFeeds[ETH][LINEA] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][BLAST] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][BARTIO] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

        /// BSC
        priceFeeds[BSC][BSC] = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        priceFeeds[BSC][ETH] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][AVAX] = 0x5974855ce31EE8E1fff2e76591CbF83D7110F151;
        priceFeeds[BSC][POLY] = 0x7CA57b0cA6367191c94C8914d7Df09A57655905f;
        priceFeeds[BSC][OP] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][ARBI] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][BASE] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][FANTOM] = 0xe2A47e87C0f4134c8D06A41975F6860468b2F925;
        priceFeeds[BSC][SEPOLIA] = address(0);
        priceFeeds[BSC][BSC_TESTNET] = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        priceFeeds[BSC][LINEA] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][BLAST] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][BARTIO] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;

        /// AVAX
        priceFeeds[AVAX][AVAX] = 0x0A77230d17318075983913bC2145DB16C7366156;
        priceFeeds[AVAX][BSC] = address(0);
        priceFeeds[AVAX][ETH] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][POLY] = 0x1db18D41E4AD2403d9f52b5624031a2D9932Fd73;
        priceFeeds[AVAX][OP] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][ARBI] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][BASE] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][FANTOM] = 0x2dD517B2f9ba49CedB0573131FD97a5AC19ff648;
        priceFeeds[AVAX][SEPOLIA] = address(0);
        priceFeeds[AVAX][BSC_TESTNET] = address(0);
        priceFeeds[AVAX][LINEA] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][BLAST] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][BARTIO] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;

        /// POLYGON
        priceFeeds[POLY][POLY] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        priceFeeds[POLY][AVAX] = 0xe01eA2fbd8D76ee323FbEd03eB9a8625EC981A10;
        priceFeeds[POLY][BSC] = 0x82a6c4AF830caa6c97bb504425f6A66165C2c26e;
        priceFeeds[POLY][ETH] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][OP] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][ARBI] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][BASE] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][FANTOM] = 0x58326c0F831b2Dbf7234A4204F28Bba79AA06d5f;
        priceFeeds[POLY][SEPOLIA] = address(0);
        priceFeeds[POLY][BSC_TESTNET] = 0x82a6c4AF830caa6c97bb504425f6A66165C2c26e;
        priceFeeds[POLY][LINEA] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][BLAST] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][BARTIO] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;

        /// OPTIMISM
        priceFeeds[OP][OP] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][POLY] = 0x0ded608AFc23724f614B76955bbd9dFe7dDdc828;
        priceFeeds[OP][AVAX] = 0x5087Dc69Fd3907a016BD42B38022F7f024140727;
        priceFeeds[OP][BSC] = 0xD38579f7cBD14c22cF1997575eA8eF7bfe62ca2c;
        priceFeeds[OP][ETH] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][ARBI] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][BASE] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][FANTOM] = 0xc19d58652d6BfC6Db6FB3691eDA6Aa7f3379E4E9;
        priceFeeds[OP][SEPOLIA] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][BSC_TESTNET] = 0xD38579f7cBD14c22cF1997575eA8eF7bfe62ca2c;
        priceFeeds[OP][LINEA] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][BLAST] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][BARTIO] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;

        /// ARBITRUM
        priceFeeds[ARBI][ARBI] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][OP] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][POLY] = 0x52099D4523531f678Dfc568a7B1e5038aadcE1d6;
        priceFeeds[ARBI][AVAX] = 0x8bf61728eeDCE2F32c456454d87B5d6eD6150208;
        priceFeeds[ARBI][BSC] = 0x6970460aabF80C5BE983C6b74e5D06dEDCA95D4A;
        priceFeeds[ARBI][ETH] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][BASE] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][FANTOM] = 0xFeaC1A3936514746e70170c0f539e70b23d36F19;
        priceFeeds[ARBI][SEPOLIA] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][BSC_TESTNET] = 0x6970460aabF80C5BE983C6b74e5D06dEDCA95D4A;
        priceFeeds[ARBI][LINEA] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][BLAST] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][BARTIO] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;

        /// BASE
        priceFeeds[BASE][BASE] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][OP] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][POLY] = 0x12129aAC52D6B0f0125677D4E1435633E61fD25f;
        priceFeeds[BASE][AVAX] = 0xE70f2D34Fd04046aaEC26a198A35dD8F2dF5cd92;
        priceFeeds[BASE][BSC] = 0x4b7836916781CAAfbb7Bd1E5FDd20ED544B453b1;
        priceFeeds[BASE][ETH] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][ARBI] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][FANTOM] = address(0);
        priceFeeds[BASE][SEPOLIA] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][BSC_TESTNET] = 0x4b7836916781CAAfbb7Bd1E5FDd20ED544B453b1;
        priceFeeds[BASE][LINEA] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][BLAST] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][BARTIO] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;

        /// FANTOM
        priceFeeds[FANTOM][FANTOM] = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc;
        priceFeeds[FANTOM][OP] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][POLY] = address(0);
        priceFeeds[FANTOM][AVAX] = address(0);
        priceFeeds[FANTOM][BSC] = 0x6dE70f4791C4151E00aD02e969bD900DC961f92a;
        priceFeeds[FANTOM][ETH] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][BASE] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][ARBI] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][SEPOLIA] = address(0);
        priceFeeds[FANTOM][BSC_TESTNET] = 0x6dE70f4791C4151E00aD02e969bD900DC961f92a;
        priceFeeds[FANTOM][LINEA] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][BLAST] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][BARTIO] = 0x11DdD3d147E5b83D01cee7070027092397d63658;

        /// SEPOLIA
        priceFeeds[SEPOLIA][SEPOLIA] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        priceFeeds[SEPOLIA][FANTOM] = address(0);
        priceFeeds[SEPOLIA][OP] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        priceFeeds[SEPOLIA][POLY] = address(0);
        priceFeeds[SEPOLIA][AVAX] = address(0);
        priceFeeds[SEPOLIA][BSC] = address(0);
        priceFeeds[SEPOLIA][ETH] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        priceFeeds[SEPOLIA][BASE] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        priceFeeds[SEPOLIA][ARBI] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        priceFeeds[SEPOLIA][BSC_TESTNET] = address(0);
        priceFeeds[SEPOLIA][LINEA] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        priceFeeds[SEPOLIA][BLAST] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        priceFeeds[SEPOLIA][BARTIO] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        /// BSC_TESTNET
        priceFeeds[BSC_TESTNET][BSC_TESTNET] = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;
        priceFeeds[BSC_TESTNET][SEPOLIA] = 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7;
        priceFeeds[BSC_TESTNET][FANTOM] = address(0);
        priceFeeds[BSC_TESTNET][OP] = 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7;
        priceFeeds[BSC_TESTNET][POLY] = address(0);
        priceFeeds[BSC_TESTNET][AVAX] = address(0);
        priceFeeds[BSC_TESTNET][BSC] = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;
        priceFeeds[BSC_TESTNET][ETH] = 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7;
        priceFeeds[BSC_TESTNET][BASE] = 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7;
        priceFeeds[BSC_TESTNET][ARBI] = 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7;
        priceFeeds[BSC_TESTNET][LINEA] = 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7;
        priceFeeds[BSC_TESTNET][BLAST] = 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7;
        priceFeeds[BSC_TESTNET][BARTIO] = 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7;
        /// LINEA
        priceFeeds[LINEA][LINEA] = 0x22C942d2DE7673435Cc0D10278c8D5e0d8284c65;
        priceFeeds[LINEA][OP] = 0x22C942d2DE7673435Cc0D10278c8D5e0d8284c65;
        priceFeeds[LINEA][POLY] = 0x2AFFD07522147fba37Da08f938cA22Eaa02CEF25;
        priceFeeds[LINEA][AVAX] = 0xEcD363e4ffe9D0004451648DA2b45E1158c00bF8;
        priceFeeds[LINEA][BSC] = 0x7464Cc4f3100Cd2e2169d7918030025C8d3E114C;
        priceFeeds[LINEA][ETH] = 0x22C942d2DE7673435Cc0D10278c8D5e0d8284c65;
        priceFeeds[LINEA][BASE] = 0x22C942d2DE7673435Cc0D10278c8D5e0d8284c65;
        priceFeeds[LINEA][ARBI] = 0x22C942d2DE7673435Cc0D10278c8D5e0d8284c65;
        priceFeeds[LINEA][FANTOM] = 0x5CC126760258e319548fc8740d7656B08550BF54;
        priceFeeds[LINEA][BLAST] = 0x22C942d2DE7673435Cc0D10278c8D5e0d8284c65;
        priceFeeds[LINEA][BSC_TESTNET] = address(0);
        priceFeeds[LINEA][SEPOLIA] = 0x22C942d2DE7673435Cc0D10278c8D5e0d8284c65;
        priceFeeds[LINEA][BARTIO] = 0x22C942d2DE7673435Cc0D10278c8D5e0d8284c65;

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
        priceFeeds[BLAST][BSC_TESTNET] = address(0);
        priceFeeds[BLAST][SEPOLIA] = address(0);
        priceFeeds[BLAST][BARTIO] = 0x4AB67C7e24d94bd70502c44051274195215d8071;

        /// BARTIO
        priceFeeds[BARTIO][BARTIO] = 0x42324DA2cB327D9DDE198d10A7A68870d761C390;
        priceFeeds[BARTIO][OP] = 0x42324DA2cB327D9DDE198d10A7A68870d761C390;
        priceFeeds[BARTIO][POLY] = address(0);
        priceFeeds[BARTIO][AVAX] = address(0);
        priceFeeds[BARTIO][BSC] = address(0);
        priceFeeds[BARTIO][ETH] = 0x42324DA2cB327D9DDE198d10A7A68870d761C390;
        priceFeeds[BARTIO][BASE] = 0x42324DA2cB327D9DDE198d10A7A68870d761C390;
        priceFeeds[BARTIO][ARBI] = 0x42324DA2cB327D9DDE198d10A7A68870d761C390;
        priceFeeds[BARTIO][FANTOM] = address(0);
        priceFeeds[BARTIO][LINEA] = 0x42324DA2cB327D9DDE198d10A7A68870d761C390;
        priceFeeds[BARTIO][SEPOLIA] = 0x42324DA2cB327D9DDE198d10A7A68870d761C390;
        priceFeeds[BARTIO][BLAST] = 0x42324DA2cB327D9DDE198d10A7A68870d761C390;

        /// @dev setup bridges.
        /// 1 is lifi
        /// 2 is socket
        /// 3 is socket one inch impl
        /// 4 is lifi rugpull
        /// 5 is lifi blacklist
        /// 6 is lifi swap to attacker
        /// 7 is debridge
        /// 8 is debridge forwarder
        /// 9 is one inch

        bridgeIds.push(1);
        bridgeIds.push(2);
        bridgeIds.push(3);
        bridgeIds.push(4);
        bridgeIds.push(5);
        bridgeIds.push(6);
        bridgeIds.push(7);
        bridgeIds.push(8);
        bridgeIds.push(9);

        /// @dev setup users
        userKeys.push(1);
        userKeys.push(2);
        userKeys.push(3);

        users.push(vm.addr(userKeys[0]));
        users.push(vm.addr(userKeys[1]));
        users.push(vm.addr(userKeys[2]));

        /// @dev setup vault bytecodes
        /// @dev NOTE: do not change order of these pushes
        /// @dev WARNING: Must fill VAULT_NAMES with exact same names as here!!!!!
        /// @dev form 1 (normal 4626)
        vaultBytecodes2[1].vaultBytecode.push(type(VaultMock).creationCode);
        vaultBytecodes2[1].vaultBytecode.push(type(VaultMockRevertDeposit).creationCode);
        vaultBytecodes2[1].vaultBytecode.push(type(VaultMockRevertWithdraw).creationCode);

        vaultBytecodes2[1].vaultKinds.push("VaultMock");
        vaultBytecodes2[1].vaultKinds.push("VaultMockRevertDeposit");
        vaultBytecodes2[1].vaultKinds.push("VaultMockRevertWithdraw");

        /// @dev form 4 (pendle 5115)
        vaultBytecodes2[3].vaultBytecode.push(type(ERC5115To4626Wrapper).creationCode);
        vaultBytecodes2[3].vaultKinds.push("ERC5115");

        /// @dev form 3 (7540)
        vaultBytecodes2[4].vaultBytecode.push(type(ERC7540FullyAsyncMock).creationCode);
        vaultBytecodes2[4].vaultKinds.push("ERC7540FullyAsyncMock");
        vaultBytecodes2[4].vaultBytecode.push(type(ERC7540AsyncDepositMock).creationCode);
        vaultBytecodes2[4].vaultKinds.push("ERC7540AsyncDepositMock");
        vaultBytecodes2[4].vaultBytecode.push(type(ERC7540AsyncRedeemMock).creationCode);
        vaultBytecodes2[4].vaultKinds.push("ERC7540AsyncRedeemMock");
        vaultBytecodes2[4].vaultBytecode.push(type(ERC7540AsyncDepositMockRevert).creationCode);
        vaultBytecodes2[4].vaultKinds.push("ERC7540AsyncDepositMockRevert");
        vaultBytecodes2[4].vaultBytecode.push(type(ERC7540AsyncRedeemMockRevert).creationCode);
        vaultBytecodes2[4].vaultKinds.push("ERC7540AsyncRedeemMockRevert");
        vaultBytecodes2[4].vaultBytecode.push(type(ERC7540AsyncDepositMockRedeemRevert).creationCode);
        vaultBytecodes2[4].vaultKinds.push("ERC7540AsyncDepositMockRedeemRevert");

        /// @dev populate VAULT_NAMES state arg with tokenNames + vaultKinds names
        string[] memory underlyingTokens = UNDERLYING_TOKENS;
        for (uint256 i = 0; i < VAULT_KINDS.length; ++i) {
            for (uint256 j = 0; j < underlyingTokens.length; ++j) {
                VAULT_NAMES[i].push(string.concat(underlyingTokens[j], VAULT_KINDS[i]));
            }
        }

        mapping(uint64 chainId => mapping(string underlying => address realAddress)) storage existingTokens =
            UNDERLYING_EXISTING_TOKENS;

        existingTokens[43_114]["DAI"] = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
        existingTokens[43_114]["USDC"] = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
        existingTokens[43_114]["WETH"] = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;

        existingTokens[42_161]["DAI"] = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
        existingTokens[42_161]["USDC"] = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
        existingTokens[42_161]["WETH"] = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        existingTokens[42_161]["wstETH"] = 0x5979D7b546E38E414F7E9822514be443A4800529;

        existingTokens[10]["DAI"] = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
        existingTokens[10]["USDC"] = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
        existingTokens[10]["WETH"] = 0x4200000000000000000000000000000000000006;
        existingTokens[10]["wstETH"] = 0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb;

        existingTokens[1]["DAI"] = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        existingTokens[1]["USDC"] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        existingTokens[1]["WETH"] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        existingTokens[1]["sUSDe"] = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;
        existingTokens[1]["ezETH"] = 0xbf5495Efe5DB9ce00f80364C8B423567e58d2110;
        existingTokens[1]["USDe"] = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;

        existingTokens[137]["DAI"] = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
        existingTokens[137]["USDC"] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        existingTokens[137]["WETH"] = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

        existingTokens[56]["DAI"] = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        existingTokens[56]["USDC"] = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
        existingTokens[56]["WETH"] = address(0);
        existingTokens[56]["ezETH"] = 0x2416092f143378750bb29b79eD961ab195CcEea5;

        existingTokens[8453]["DAI"] = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
        existingTokens[8453]["USDC"] = address(0);
        existingTokens[8453]["WETH"] = address(0);

        existingTokens[250]["DAI"] = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;
        existingTokens[250]["USDC"] = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
        existingTokens[250]["WETH"] = address(0);

        existingTokens[11_155_111]["DAI"] = address(0);
        existingTokens[11_155_111]["USDC"] = address(0);
        existingTokens[11_155_111]["WETH"] = address(0);
        existingTokens[11_155_111]["tUSD"] = 0x8503b4452Bf6238cC76CdbEE223b46d7196b1c93;

        existingTokens[80_084]["DAI"] = address(0);
        existingTokens[80_084]["USDC"] = 0xd6D83aF58a19Cd14eF3CF6fe848C9A4d21e5727c;
        existingTokens[80_084]["WETH"] = 0xE28AfD8c634946833e89ee3F122C06d7C537E8A8;

        mapping(
            uint64 chainId
                => mapping(
                    uint32 formImplementationId
                        => mapping(string underlying => mapping(uint256 vaultKindIndex => address realVault))
                )
        ) storage existingVaults = REAL_VAULT_ADDRESS;

        existingVaults[43_114][1]["DAI"][0] = 0x75A8cFB425f366e424259b114CaeE5f634C07124;
        existingVaults[43_114][1]["USDC"][0] = 0xB4001622c02F1354A3CfF995b7DaA15b1d47B0fe;
        existingVaults[43_114][1]["WETH"][0] = 0x1a225008efffB6e07D01671127c9E40f6f787c8C;

        existingVaults[42_161][1]["DAI"][0] = address(0);
        existingVaults[42_161][1]["USDC"][0] = address(0);
        existingVaults[42_161][1]["WETH"][0] = 0xe4c2A17f38FEA3Dcb3bb59CEB0aC0267416806e2;

        existingVaults[1][1]["DAI"][0] = address(0);
        existingVaults[1][1]["USDC"][0] = address(0);
        existingVaults[1][1]["WETH"][0] = address(0);
        existingVaults[1][1]["USDe"][0] = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;

        existingVaults[10][1]["DAI"][0] = address(0);
        existingVaults[10][1]["USDC"][0] = address(0);
        existingVaults[10][1]["WETH"][0] = address(0);

        existingVaults[137][1]["DAI"][0] = 0x4A7CfE3ccE6E88479206Fefd7b4dcD738971e723;
        existingVaults[137][1]["USDC"][0] = 0x277ba089b4CF2AF32589D98aA839Bf8c35A30Da3;
        existingVaults[137][1]["WETH"][0] = 0x0D0188268D0693e2494989dc3DA5e64F0D6BA972;

        existingVaults[56][1]["DAI"][0] = 0x6A354D50fC2476061F378390078e30F9782C5266;
        existingVaults[56][1]["USDC"][0] = 0x32307B89a1c59Ea4EBaB1Fde6bD37b1139D06759;
        existingVaults[56][1]["WETH"][0] = address(0);

        existingVaults[8453][1]["DAI"][0] = 0x88510ced6F82eFd3ddc4599B72ad8ac2fF172043;
        existingVaults[8453][1]["USDC"][0] = address(0);
        existingVaults[8453][1]["WETH"][0] = address(0);

        existingVaults[250][1]["DAI"][0] = address(0);
        existingVaults[250][1]["USDC"][0] = 0xd55C59Da5872DE866e39b1e3Af2065330ea8Acd6;
        existingVaults[250][1]["WETH"][0] = address(0);

        /// @dev 7540 real centrifuge vaults on mainnet & testnet
        existingVaults[1][4]["USDC"][0] = 0x1d01Ef1997d44206d839b78bA6813f60F1B3A970;
        existingVaults[11_155_111][4]["tUSD"][0] = 0x3b33D257E77E018326CCddeCA71cf9350C585A66;

        mapping(uint64 chainId => mapping(uint256 market => address realVault)) storage erc5115Vaults = ERC5115_VAULTS;
        mapping(uint64 chainId => mapping(uint256 market => string name)) storage erc5115VaultsNames =
            ERC5115_VAULTS_NAMES;
        mapping(uint64 chainId => uint256 nVaults) storage numberOf5115s = NUMBER_OF_5115S;
        mapping(uint64 chainId => mapping(address realVault => ChosenAssets chosenAssets)) storage erc5115ChosenAssets =
            ERC5115S_CHOSEN_ASSETS;

        numberOf5115s[1] = 2;
        numberOf5115s[10] = 1;
        numberOf5115s[42_161] = 2;
        numberOf5115s[56] = 1;
        numberOf5115s[8453] = 0;
        numberOf5115s[250] = 0;
        numberOf5115s[137] = 0;
        numberOf5115s[43_114] = 0;

        /// @dev  pendle ethena - market: SUSDE-MAINNET-SEP2024
        /// sUSDe sUSDe
        erc5115Vaults[1][0] = 0x4139cDC6345aFFbaC0692b43bed4D059Df3e6d65;
        erc5115VaultsNames[1][0] = "sUSDe";
        erc5115ChosenAssets[1][0x4139cDC6345aFFbaC0692b43bed4D059Df3e6d65].assetIn =
            0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;
        erc5115ChosenAssets[1][0x4139cDC6345aFFbaC0692b43bed4D059Df3e6d65].assetOut =
            0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;

        /// ezETH
        /// @dev pendle renzo - market:  SY ezETH
        erc5115Vaults[1][1] = 0x22E12A50e3ca49FB183074235cB1db84Fe4C716D;
        erc5115VaultsNames[1][1] = "ezETH";
        erc5115ChosenAssets[1][0x22E12A50e3ca49FB183074235cB1db84Fe4C716D].assetIn =
            0xbf5495Efe5DB9ce00f80364C8B423567e58d2110;
        erc5115ChosenAssets[1][0x22E12A50e3ca49FB183074235cB1db84Fe4C716D].assetOut =
            0xbf5495Efe5DB9ce00f80364C8B423567e58d2110;

        /// ezETH
        /// @dev pendle aave usdt - market:  SY aUSDT
        erc5115Vaults[1][2] = 0x8c28D28bAd669afadC37b034A8070D6d7B9dFB74;
        erc5115VaultsNames[1][2] = "aUSDT";
        erc5115ChosenAssets[1][0x8c28D28bAd669afadC37b034A8070D6d7B9dFB74].assetIn =
            0xdAC17F958D2ee523a2206206994597C13D831ec7;
        erc5115ChosenAssets[1][0x8c28D28bAd669afadC37b034A8070D6d7B9dFB74].assetOut =
            0x23878914EFE38d27C4D67Ab83ed1b93A74D4086a;

        /// wstETH
        /// @dev pendle wrapped st ETH from LDO - market:  SY wstETH
        erc5115Vaults[10][0] = 0x96A528f4414aC3CcD21342996c93f2EcdEc24286;
        erc5115VaultsNames[10][0] = "wstETH";
        erc5115ChosenAssets[10][0x96A528f4414aC3CcD21342996c93f2EcdEc24286].assetIn =
            0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb;
        erc5115ChosenAssets[10][0x96A528f4414aC3CcD21342996c93f2EcdEc24286].assetOut =
            0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb;

        /// ezETH
        /// @dev pendle renzo - market: EZETH-BSC-SEP2024
        erc5115Vaults[56][0] = 0xe49269B5D31299BcE407c8CcCf241274e9A93C9A;
        erc5115VaultsNames[56][0] = "ezETH";
        erc5115ChosenAssets[56][0xe49269B5D31299BcE407c8CcCf241274e9A93C9A].assetIn =
            0x2416092f143378750bb29b79eD961ab195CcEea5;
        erc5115ChosenAssets[56][0xe49269B5D31299BcE407c8CcCf241274e9A93C9A].assetOut =
            0x2416092f143378750bb29b79eD961ab195CcEea5;

        /// USDC aARBUsdc
        /// @dev pendle aave - market: SY aUSDC
        erc5115Vaults[42_161][0] = 0x50288c30c37FA1Ec6167a31E575EA8632645dE20;
        erc5115VaultsNames[42_161][0] = "USDC";
        erc5115ChosenAssets[42_161][0x50288c30c37FA1Ec6167a31E575EA8632645dE20].assetIn =
            0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
        erc5115ChosenAssets[42_161][0x50288c30c37FA1Ec6167a31E575EA8632645dE20].assetOut =
            0x724dc807b04555b71ed48a6896b6F41593b8C637;

        /// wstETH
        /// @dev pendle wrapped st ETH from LDO - market: SY wstETH
        erc5115Vaults[42_161][1] = 0x80c12D5b6Cc494632Bf11b03F09436c8B61Cc5Df;
        erc5115VaultsNames[42_161][1] = "wstETH";
        erc5115ChosenAssets[42_161][0x80c12D5b6Cc494632Bf11b03F09436c8B61Cc5Df].assetIn =
            0x5979D7b546E38E414F7E9822514be443A4800529;
        erc5115ChosenAssets[42_161][0x80c12D5b6Cc494632Bf11b03F09436c8B61Cc5Df].assetOut =
            0x5979D7b546E38E414F7E9822514be443A4800529;
    }

    function _fundNativeTokens() internal {
        for (uint256 i = 0; i < chainIds.length; ++i) {
            vm.selectFork(FORKS[chainIds[i]]);

            uint256 amountDeployer = 1e24;
            uint256 amountUSER = 1e24;

            vm.deal(deployer, amountDeployer);

            vm.deal(users[0], amountUSER);
            vm.deal(users[1], amountUSER);
            vm.deal(users[2], amountUSER);
        }
    }

    function _fundUnderlyingTokens(uint256 amount) internal {
        for (uint256 j = 0; j < UNDERLYING_TOKENS.length; ++j) {
            if (getContract(chainIds[0], UNDERLYING_TOKENS[j]) == address(0)) {
                revert INVALID_UNDERLYING_TOKEN_NAME();
            }

            for (uint256 i = 0; i < chainIds.length; ++i) {
                vm.selectFork(FORKS[chainIds[i]]);
                address token = getContract(chainIds[i], UNDERLYING_TOKENS[j]);
                deal(token, users[0], 1 ether * amount);
                deal(token, users[1], 1 ether * amount);
                deal(token, users[2], 1 ether * amount);
            }
        }
    }

    /// @dev will sync the payloads for broadcast
    function _broadcastPayloadHelper(uint64 currentChainId, Vm.Log[] memory logs) internal {
        vm.stopPrank();

        address[] memory dstTargets = new address[](chainIds.length - 5);
        address[] memory dstWormhole = new address[](chainIds.length - 5);
        uint256[] memory forkIds = new uint256[](chainIds.length - 5);

        uint16 currWormholeChainId;

        uint256 j;
        for (uint256 i = 0; i < chainIds.length; ++i) {
            if (chainIds[i] == LINEA || chainIds[i] == SEPOLIA || chainIds[i] == BSC_TESTNET || chainIds[i] == BARTIO) {
                continue;
            }

            if (chainIds[i] != currentChainId) {
                dstWormhole[j] = wormholeCore[i];
                dstTargets[j] = getContract(chainIds[i], "WormholeSRImplementation");

                forkIds[j] = FORKS[chainIds[i]];

                ++j;
            } else {
                currWormholeChainId = wormhole_chainIds[i];
            }
        }

        WormholeBroadcastHelper.WormholeHelper(getContract(currentChainId, "WormholeBroadcastHelper")).help(
            currWormholeChainId, forkIds, dstWormhole, dstTargets, logs
        );

        vm.startPrank(deployer);
    }

    function _deployWithCreate2(bytes memory bytecode_, uint256 salt_) internal returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(0, add(bytecode_, 0x20), mload(bytecode_), salt_)

            if iszero(extcodesize(addr)) { revert(0, 0) }
        }

        return addr;
    }

    function _randomBytes32() internal view returns (bytes32) {
        return keccak256(
            abi.encode(tx.origin, block.number, block.timestamp, block.coinbase, address(this).codehash, gasleft())
        );
    }

    function _randomUint256() internal view returns (uint256) {
        return uint256(_randomBytes32());
    }

    // Generate a signature for a permit message.
    function _signPermit(
        IPermit2.PermitTransferFrom memory permit,
        address spender,
        uint256 signerKey,
        uint64 chainId
    )
        internal
        view
        returns (bytes memory sig)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, _getPermitEIP712Hash(permit, spender, chainId));
        return abi.encodePacked(r, s, v);
    }

    // Compute the EIP712 hash of the permit object.
    // Normally this would be implemented off-chain.
    function _getPermitEIP712Hash(
        IPermit2.PermitTransferFrom memory permit,
        address spender,
        uint64 chainId
    )
        internal
        view
        returns (bytes32 h)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                Permit2Clone(getContract(chainId, "CanonicalPermit2")).DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TRANSFER_FROM_TYPEHASH,
                        keccak256(
                            abi.encode(TOKEN_PERMISSIONS_TYPEHASH, permit.permitted.token, permit.permitted.amount)
                        ),
                        spender,
                        permit.nonce,
                        permit.deadline
                    )
                )
            )
        );
    }

    struct AuthorizeOperator {
        address controller;
        address operator;
        bool approved;
        uint256 deadline;
        bytes32 nonce;
    }
    // Generate a signature for an authorize operator message.

    function _signAuthorizeOperator(
        AuthorizeOperator memory authorizeOperator,
        address vault,
        uint256 signerKey
    )
        internal
        view
        returns (bytes memory sig)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, _getAuthorizeOperatorEIP712Hash(authorizeOperator, vault));
        return abi.encodePacked(r, s, v);
    }

    // Compute the EIP712 hash of the authorize operator arguments
    // Normally this would be implemented off-chain.
    function _getAuthorizeOperatorEIP712Hash(
        AuthorizeOperator memory authorizeOperator,
        address vault
    )
        internal
        view
        returns (bytes32 h)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                IAuthorizeOperator(vault).DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        AUTHORIZE_OPERATOR_TYPEHASH,
                        authorizeOperator.controller,
                        authorizeOperator.operator,
                        authorizeOperator.approved,
                        authorizeOperator.nonce,
                        authorizeOperator.deadline
                    )
                )
            )
        );
    }

    ///@dev Compute the address of the contract to be deployed
    function getAddress(bytes memory bytecode_, bytes32 salt_, address deployer_) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), deployer_, salt_, keccak256(bytecode_)));

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    /*//////////////////////////////////////////////////////////////
                GAS ESTIMATION & PAYLOAD HELPERS
    //////////////////////////////////////////////////////////////*/

    struct LocalAckVars {
        uint256 totalFees;
        uint256 ambCount;
        uint64 srcChainId;
        uint64 dstChainId;
        PaymentHelper paymentHelper;
        PayloadHelper payloadHelper;
        bytes message;
    }

    /// @dev Generates the acknowledgement amb params for the async deposit action
    function _generateAckGasFeesAndParamsForAsyncDepositCallback(
        bytes memory chainIds_,
        uint8[] memory selectedAmbIds,
        address user_,
        uint256 superformId_
    )
        internal
        view
        returns (uint256 msgValue)
    {
        LocalAckVars memory vars;
        (vars.srcChainId, vars.dstChainId) = abi.decode(chainIds_, (uint64, uint64));

        AsyncStateRegistry asr = AsyncStateRegistry(contracts[vars.dstChainId][bytes32(bytes("AsyncStateRegistry"))]);

        RequestConfig memory config = asr.getRequestConfig(user_, superformId_);

        vars.message = abi.encode(
            AMBMessage(
                2 ** 256 - 1,
                abi.encode(ReturnSingleData(config.currentReturnDataPayloadId, superformId_, type(uint256).max))
            )
        );

        vars.paymentHelper = PaymentHelper(contracts[vars.dstChainId][bytes32(bytes("PaymentHelper"))]);
        (msgValue,) = vars.paymentHelper.calculateAMBData(vars.srcChainId, selectedAmbIds, vars.message);
    }

    /// @dev Generates the acknowledgement amb params for the sync deposit action
    function _generateAckGasFeesAndParamsForSyncWithdrawCallback(
        bytes memory chainIds_,
        uint8[] memory selectedAmbIds,
        uint256 asyncDepositPayloadId
    )
        internal
        view
        returns (uint256 msgValue)
    {
        LocalAckVars memory vars;
        (vars.srcChainId, vars.dstChainId) = abi.decode(chainIds_, (uint64, uint64));

        address _paymentHelper = contracts[vars.dstChainId][bytes32(bytes("PaymentHelper"))];
        vars.paymentHelper = PaymentHelper(_paymentHelper);

        address _payloadHelper = contracts[vars.dstChainId][bytes32(bytes("PayloadHelper"))];
        vars.payloadHelper = PayloadHelper(_payloadHelper);

        (,, uint256 payloadId, uint256 superformId, uint256 amount) =
            vars.payloadHelper.decodeSyncWithdrawPayload(asyncDepositPayloadId);

        vars.message =
            abi.encode(AMBMessage(2 ** 256 - 1, abi.encode(ReturnSingleData(payloadId, superformId, amount))));

        (msgValue,) = vars.paymentHelper.calculateAMBData(vars.srcChainId, selectedAmbIds, vars.message);
    }

    function _payload(address registry, uint64 chainId, uint256 payloadId_) internal returns (bytes memory payload_) {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[chainId]);
        uint256 payloadHeader = IBaseStateRegistry(registry).payloadHeader(payloadId_);
        bytes memory payloadBody = IBaseStateRegistry(registry).payloadBody(payloadId_);
        if (payloadHeader == 0 || payloadBody.length == 0) {
            vm.selectFork(initialFork);

            return bytes("");
        }
        vm.selectFork(initialFork);

        return abi.encode(AMBMessage(payloadHeader, payloadBody));
    }
}

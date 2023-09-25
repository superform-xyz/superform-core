/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

/// @dev lib imports
import "forge-std/Test.sol";
import "ds-test/test.sol";
import { LayerZeroHelper } from "pigeon/layerzero/LayerZeroHelper.sol";
import { HyperlaneHelper } from "pigeon/hyperlane/HyperlaneHelper.sol";

import { WormholeHelper } from "pigeon/wormhole/automatic-relayer/WormholeHelper.sol";
import "pigeon/wormhole/specialized-relayer/WormholeHelper.sol" as WormholeBroadcastHelper;

import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import { IERC1155A } from "ERC1155A/interfaces/IERC1155A.sol";

/// @dev test utils & mocks
import { LiFiMock } from "../mocks/LiFiMock.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { VaultMock } from "../mocks/VaultMock.sol";
import { VaultMockRevertDeposit } from "../mocks/VaultMockRevertDeposit.sol";
import { VaultMockRevertWithdraw } from "../mocks/VaultMockRevertWithdraw.sol";
import { ERC4626TimelockMockRevertWithdrawal } from "../mocks/ERC4626TimelockMockRevertWithdrawal.sol";
import { ERC4626TimelockMockRevertDeposit } from "../mocks/ERC4626TimelockMockRevertDeposit.sol";
import { ERC4626TimelockMock } from "../mocks/ERC4626TimelockMock.sol";
import { kycDAO4626 } from "super-vaults/kycdao-4626/kycdao4626.sol";
import { kycDAO4626RevertDeposit } from "../mocks/kycDAO4626RevertDeposit.sol";
import { kycDAO4626RevertWithdraw } from "../mocks/kycDAO4626RevertWithdraw.sol";
import { Permit2Clone } from "../mocks/Permit2Clone.sol";
import { KYCDaoNFTMock } from "../mocks/KYCDaoNFTMock.sol";

/// @dev Protocol imports
import { CoreStateRegistry } from "src/crosschain-data/extensions/CoreStateRegistry.sol";
import { BroadcastRegistry } from "src/crosschain-data/BroadcastRegistry.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import { SuperformRouter } from "src/SuperformRouter.sol";
import { PayMaster } from "src/payments/PayMaster.sol";
import { SuperRegistry } from "src/settings/SuperRegistry.sol";
import { SuperRBAC } from "src/settings/SuperRBAC.sol";
import { SuperPositions } from "src/SuperPositions.sol";
import { SuperformFactory } from "src/SuperformFactory.sol";
import { ERC4626Form } from "src/forms/ERC4626Form.sol";
import { ERC4626TimelockForm } from "src/forms/ERC4626TimelockForm.sol";
import { ERC4626KYCDaoForm } from "src/forms/ERC4626KYCDaoForm.sol";
import { DstSwapper } from "src/crosschain-liquidity/DstSwapper.sol";
import { LiFiValidator } from "src/crosschain-liquidity/lifi/LiFiValidator.sol";
import { LayerzeroImplementation } from "src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol";
import { HyperlaneImplementation } from "src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol";
import { WormholeARImplementation } from
    "src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol";
import { WormholeSRImplementation } from
    "src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol";
import { IMailbox } from "src/vendor/hyperlane/IMailbox.sol";
import { IInterchainGasPaymaster } from "src/vendor/hyperlane/IInterchainGasPaymaster.sol";
import ".././utils/AmbParams.sol";
import { IPermit2 } from "src/vendor/dragonfly-xyz/IPermit2.sol";
import { TimelockStateRegistry } from "src/crosschain-data/extensions/TimelockStateRegistry.sol";
import { PayloadHelper } from "src/crosschain-data/utils/PayloadHelper.sol";
import { PaymentHelper } from "src/payments/PaymentHelper.sol";
import { IPaymentHelper } from "src/interfaces/IPaymentHelper.sol";
import { SuperTransmuter } from "src/SuperTransmuter.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import "src/types/DataTypes.sol";
import "./TestTypes.sol";

abstract contract BaseSetup is DSTest, Test {
    /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
    //////////////////////////////////////////////////////////////*/
    bytes32 constant TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");
    bytes32 constant PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    /// @dev ETH mainnet values as on 22nd Aug, 2023
    uint256 public constant TOTAL_SUPPLY_DAI = 3_961_541_270_138_222_277_363_935_051;
    uint256 public constant TOTAL_SUPPLY_USDT = 39_026_949_359_163_005;
    uint256 public constant TOTAL_SUPPLY_WETH = 3_293_797_048_454_740_686_583_782;
    uint256 public constant TOTAL_SUPPLY_ETH = 120_000_000e18;

    /// @dev
    address public constant CANONICAL_PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    /// @dev for mainnet deployment
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public deployer = vm.addr(777);
    address[] public users;
    uint256[] public userKeys;

    uint256 public trustedRemote;
    bytes32 public salt;
    mapping(uint64 chainId => mapping(bytes32 implementation => address at)) public contracts;

    /*//////////////////////////////////////////////////////////////
                        PROTOCOL VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev we should fork these instead of mocking
    string[] public UNDERLYING_TOKENS = ["DAI", "USDC", "WETH"];

    /// @dev 1 = ERC4626Form, 2 = ERC4626TimelockForm, 3 = KYCDaoForm
    uint32[] public FORM_BEACON_IDS = [uint32(1), uint32(2), uint32(3)];

    /// @dev WARNING!! THESE VAULT NAMES MUST BE THE EXACT NAMES AS FILLED IN vaultKinds
    string[] public VAULT_KINDS = [
        "VaultMock",
        "ERC4626TimelockMock",
        "kycDAO4626",
        "VaultMockRevertDeposit",
        "ERC4626TimelockMockRevertWithdrawal",
        "ERC4626TimelockMockRevertDeposit",
        "kycDAO4626RevertDeposit",
        "kycDAO4626RevertWithdraw",
        "VaultMockRevertWithdraw"
    ];

    struct VaultInfo {
        bytes[] vaultBytecode;
        string[] vaultKinds;
    }

    mapping(uint32 formBeaconId => VaultInfo vaultInfo) vaultBytecodes2;

    mapping(uint256 vaultId => string[] names) VAULT_NAMES;

    mapping(uint64 chainId => mapping(uint32 formBeaconId => IERC4626[][] vaults)) public vaults;
    mapping(uint64 chainId => uint256 payloadId) PAYLOAD_ID;
    mapping(uint64 chainId => uint256 payloadId) TWO_STEP_PAYLOAD_ID;

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

    uint8[] public ambIds = [uint8(1), 2, 3, 4];
    bool[] public isBroadcastAMB = [false, false, false, true];

    /*//////////////////////////////////////////////////////////////
                        AMB VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(uint64 => address) public LZ_ENDPOINTS;
    mapping(uint64 => uint16) public WORMHOLE_CHAIN_IDS;

    address public constant ETH_lzEndpoint = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
    address public constant BSC_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant AVAX_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant POLY_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant ARBI_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant OP_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address public constant FTM_lzEndpoint = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;
    /// @dev removed FTM temporarily

    address[] public lzEndpoints = [
        0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62,
        0x3c2269811836af69497E5F486A85D7316753cf62
    ];

    address[] public hyperlaneMailboxes = [
        0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70,
        0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70,
        0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70,
        0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70,
        0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70,
        0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70
    ];

    address[] public wormholeCore = [
        0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B,
        0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B,
        0x54a8e5f9c4CbA08F9943965859F6c34eAF03E26c,
        0x7A4B5a56256163F07b2C80A7cA55aBE66c4ec4d7,
        0xa5f208e072434bC67592E4C49C1B991BA79BCA46,
        0xEe91C335eab126dF5fDB3797EA9d6aD93aeC9722
    ];

    /*//////////////////////////////////////////////////////////////
                        WORMHOLE VARIABLES
    //////////////////////////////////////////////////////////////*/
    address public ETH_wormholeCore = 0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B;
    address public ARBI_wormholeCore = 0xa5f208e072434bC67592E4C49C1B991BA79BCA46;
    address public AVAX_wormholeCore = 0x54a8e5f9c4CbA08F9943965859F6c34eAF03E26c;
    address public BSC_wormholeCore = 0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B;
    address public OP_wormholeCore = 0xEe91C335eab126dF5fDB3797EA9d6aD93aeC9722;
    address public POLY_wormholeCore = 0x7A4B5a56256163F07b2C80A7cA55aBE66c4ec4d7;

    /// @dev uses CREATE2
    address public wormholeRelayer = 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911;

    /*//////////////////////////////////////////////////////////////
                        HYPERLANE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IMailbox public constant HyperlaneMailbox = IMailbox(0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70);
    IInterchainGasPaymaster public constant HyperlaneGasPaymaster =
        IInterchainGasPaymaster(0x6cA0B6D22da47f091B7613223cD4BB03a2d77918);

    uint64 public constant ETH = 1;
    uint64 public constant BSC = 56;
    uint64 public constant AVAX = 43_114;
    uint64 public constant POLY = 137;
    uint64 public constant ARBI = 42_161;
    uint64 public constant OP = 10;
    //uint64 public constant FTM = 250;

    uint64[] public chainIds = [1, 56, 43_114, 137, 42_161, 10];

    /// @dev reference for chain ids https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
    uint16 public constant LZ_ETH = 101;
    uint16 public constant LZ_BSC = 102;
    uint16 public constant LZ_AVAX = 106;
    uint16 public constant LZ_POLY = 109;
    uint16 public constant LZ_ARBI = 110;
    uint16 public constant LZ_OP = 111;
    //uint16 public constant LZ_FTM = 112;

    uint16[] public lz_chainIds = [101, 102, 106, 109, 110, 111];
    uint32[] public hyperlane_chainIds = [1, 56, 43_114, 137, 42_161, 10];
    uint16[] public wormhole_chainIds = [2, 6, 23, 5, 4, 24];

    /// @dev minting enough tokens to be able to fuzz with bigger amounts (DAI's 3.6B supply etc)
    uint256 public constant hundredBilly = 100 * 1e9 * 1e18;

    /*//////////////////////////////////////////////////////////////
                        CHAINLINK VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(uint64 => mapping(uint64 => address)) public PRICE_FEEDS;

    /*//////////////////////////////////////////////////////////////
                        RPC VARIABLES
    //////////////////////////////////////////////////////////////*/

    // chainID => FORK
    mapping(uint64 chainId => uint256 fork) public FORKS;
    mapping(uint64 chainId => string forkUrl) public RPC_URLS;
    mapping(uint64 chainId => mapping(string underlying => address realAddress)) public UNDERLYING_EXISTING_TOKENS;

    string public ETHEREUM_RPC_URL = vm.envString("ETHEREUM_RPC_URL"); // Native token: ETH
    string public BSC_RPC_URL = vm.envString("BSC_RPC_URL"); // Native token: BNB
    string public AVALANCHE_RPC_URL = vm.envString("AVALANCHE_RPC_URL"); // Native token: AVAX
    string public POLYGON_RPC_URL = vm.envString("POLYGON_RPC_URL"); // Native token: MATIC
    string public ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL"); // Native token: ETH
    string public OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC_URL"); // Native token: ETH
    string public FANTOM_RPC_URL = vm.envString("FANTOM_RPC_URL"); // Native token: FTM

    /*//////////////////////////////////////////////////////////////
                        KYC DAO VALIDITY VARIABLES
    //////////////////////////////////////////////////////////////*/

    address[] public kycDAOValidityAddresses =
        [address(0), address(0), address(0), 0x205E10d3c4C87E26eB66B1B270b71b7708494dB9, address(0), address(0)];

    function setUp() public virtual {
        _preDeploymentSetup();

        _fundNativeTokens();

        _deployProtocol();

        _fundUnderlyingTokens(100);
    }

    function getContract(uint64 chainId, string memory _name) public view returns (address) {
        return contracts[chainId][bytes32(bytes(_name))];
    }

    function getAccessControlErrorMsg(address _addr, bytes32 _role) public pure returns (bytes memory errorMsg) {
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
            vars.ambAddresses = new address[](ambIds.length);
            /// @dev salt unique to each chain
            salt = keccak256(abi.encodePacked("SUPERFORM_ON_CHAIN", vars.chainId));

            /// @dev first 4 chains have the same salt. This allows us to test a create2 deployment both with chains
            /// with same addresses and others without
            if (i < 4) {
                salt = keccak256(abi.encodePacked("SUPERFORM_ON_CHAIN"));
            }

            vm.selectFork(vars.fork);

            /// @dev preference for a local deployment of Permit2 over mainnet version. Has same bytcode
            vars.canonicalPermit2 = address(new Permit2Clone{salt: salt}());
            contracts[vars.chainId][bytes32(bytes("CanonicalPermit2"))] = vars.canonicalPermit2;

            /// @dev 1 - Pigeon helpers allow us to fullfill cross-chain messages in a manner as close to mainnet as
            /// possible
            /// @dev 1.1- deploy LZ Helper from Pigeon
            vars.lzHelper = address(new LayerZeroHelper{salt: salt}());
            vm.allowCheatcodes(vars.lzHelper);

            contracts[vars.chainId][bytes32(bytes("LayerZeroHelper"))] = vars.lzHelper;

            /// @dev 1.2- deploy Hyperlane Helper from Pigeon
            vars.hyperlaneHelper = address(new HyperlaneHelper{salt: salt}());
            vm.allowCheatcodes(vars.hyperlaneHelper);

            contracts[vars.chainId][bytes32(bytes("HyperlaneHelper"))] = vars.hyperlaneHelper;

            /// @dev 1.3- deploy Wormhole Automatic Relayer Helper from Pigeon
            vars.wormholeHelper = address(new WormholeHelper{salt: salt}());
            vm.allowCheatcodes(vars.wormholeHelper);

            contracts[vars.chainId][bytes32(bytes("WormholeHelper"))] = vars.wormholeHelper;

            /// @dev 1.4- deploy Wormhole Specialized Relayer Helper from Pigeon
            vars.wormholeBroadcastHelper = address(new WormholeBroadcastHelper.WormholeHelper{salt: salt}());
            vm.allowCheatcodes(vars.wormholeBroadcastHelper);

            contracts[vars.chainId][bytes32(bytes("WormholeBroadcastHelper"))] = vars.wormholeBroadcastHelper;

            /// @dev 2 - Deploy SuperRBAC
            vars.superRBAC = address(new SuperRBAC{salt: salt}(deployer));
            contracts[vars.chainId][bytes32(bytes("SuperRBAC"))] = vars.superRBAC;

            vars.superRBACC = SuperRBAC(vars.superRBAC);
            /// @dev 3 - Deploy SuperRegistry and assign roles
            vars.superRegistry = address(new SuperRegistry{salt: salt}(vars.superRBAC));
            contracts[vars.chainId][bytes32(bytes("SuperRegistry"))] = vars.superRegistry;
            vars.superRegistryC = SuperRegistry(vars.superRegistry);

            vars.superRBACC.setSuperRegistry(vars.superRegistry);
            vars.superRegistryC.setPermit2(vars.canonicalPermit2);

            assert(vars.superRBACC.hasProtocolAdminRole(deployer));

            vars.superRBACC.grantRole(vars.superRBACC.WORMHOLE_VAA_RELAYER_ROLE(), vars.wormholeBroadcastHelper);
            assert(vars.superRBACC.hasRole(vars.superRBACC.WORMHOLE_VAA_RELAYER_ROLE(), vars.wormholeBroadcastHelper));

            /// @dev FIXME: in reality who should have the EMERGENCY_ADMIN_ROLE?
            vars.superRBACC.grantRole(vars.superRBACC.EMERGENCY_ADMIN_ROLE(), deployer);
            assert(vars.superRBACC.hasEmergencyAdminRole(deployer));

            /// @dev FIXME: in reality who should have the PAYMENT_ADMIN_ROLE?
            vars.superRBACC.grantRole(vars.superRBACC.PAYMENT_ADMIN_ROLE(), deployer);
            assert(vars.superRBACC.hasRole(vars.superRBACC.PAYMENT_ADMIN_ROLE(), deployer));

            /// @dev FIXME: in reality who should have the CORE_STATE_REGISTRY_PROCESSOR_ROLE for state registry?
            vars.superRBACC.grantRole(vars.superRBACC.CORE_STATE_REGISTRY_PROCESSOR_ROLE(), deployer);
            assert(vars.superRBACC.hasRole(vars.superRBACC.CORE_STATE_REGISTRY_PROCESSOR_ROLE(), deployer));

            /// @dev FIXME: in reality who should have the TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE for state registry?
            vars.superRBACC.grantRole(vars.superRBACC.TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE(), deployer);
            assert(vars.superRBACC.hasRole(vars.superRBACC.TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE(), deployer));

            /// @dev FIXME: in reality who should have the BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE for state registry?
            vars.superRBACC.grantRole(vars.superRBACC.BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE(), deployer);
            assert(vars.superRBACC.hasRole(vars.superRBACC.BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE(), deployer));

            /// @dev FIXME: in reality who should have the CORE_STATE_REGISTRY_UPDATER_ROLE for state registry?
            vars.superRBACC.grantRole(vars.superRBACC.CORE_STATE_REGISTRY_UPDATER_ROLE(), deployer);
            assert(vars.superRBACC.hasRole(vars.superRBACC.CORE_STATE_REGISTRY_UPDATER_ROLE(), deployer));

            /// @dev FIXME: in reality who should have the CORE_STATE_REGISTRY_RESCUER_ROLE for state registry?
            vars.superRBACC.grantRole(vars.superRBACC.CORE_STATE_REGISTRY_RESCUER_ROLE(), deployer);
            assert(vars.superRBACC.hasRole(vars.superRBACC.CORE_STATE_REGISTRY_RESCUER_ROLE(), deployer));

            /// @dev FIXME: in reality who should have the CORE_STATE_REGISTRY_DISPUTER_ROLE for state registry?
            vars.superRBACC.grantRole(vars.superRBACC.CORE_STATE_REGISTRY_DISPUTER_ROLE(), deployer);
            assert(vars.superRBACC.hasRole(vars.superRBACC.CORE_STATE_REGISTRY_DISPUTER_ROLE(), deployer));

            /// @dev FIXME: in reality who should have the DST_SWAPPER_ROLE for dst swapper?
            vars.superRBACC.grantRole(vars.superRBACC.DST_SWAPPER_ROLE(), deployer);
            assert(vars.superRBACC.hasRole(vars.superRBACC.DST_SWAPPER_ROLE(), deployer));

            vars.superRBACC.grantRole(vars.superRBACC.BROADCASTER_ROLE(), vars.superRBAC);
            assert(vars.superRBACC.hasRole(vars.superRBACC.BROADCASTER_ROLE(), vars.superRBAC));

            /// @dev 4.1 - deploy Core State Registry
            vars.coreStateRegistry = address(
                new CoreStateRegistry{salt: salt}(
                    SuperRegistry(vars.superRegistry)
                )
            );
            contracts[vars.chainId][bytes32(bytes("CoreStateRegistry"))] = vars.coreStateRegistry;

            vars.superRegistryC.setAddress(
                vars.superRegistryC.CORE_STATE_REGISTRY(), vars.coreStateRegistry, vars.chainId
            );

            /// @dev 4.2 - deploy Form State Registry
            vars.twoStepsFormStateRegistry = address(new TimelockStateRegistry{salt: salt}(vars.superRegistryC));
            contracts[vars.chainId][bytes32(bytes("TimelockStateRegistry"))] = vars.twoStepsFormStateRegistry;

            vars.superRegistryC.setAddress(
                vars.superRegistryC.TIMELOCK_STATE_REGISTRY(), vars.twoStepsFormStateRegistry, vars.chainId
            );
            vars.superRBACC.grantRole(vars.superRBACC.SUPERPOSITIONS_MINTER_ROLE(), vars.twoStepsFormStateRegistry);

            /// @dev 4.3 - deploy Broadcast State Registry
            vars.broadcastRegistry = address(new BroadcastRegistry{salt: salt}(vars.superRegistryC));
            contracts[vars.chainId][bytes32(bytes("BroadcastRegistry"))] = vars.broadcastRegistry;

            vars.superRegistryC.setAddress(
                vars.superRegistryC.BROADCAST_REGISTRY(), vars.broadcastRegistry, vars.chainId
            );

            address[] memory registryAddresses = new address[](3);
            registryAddresses[0] = vars.coreStateRegistry;
            registryAddresses[1] = vars.twoStepsFormStateRegistry;
            registryAddresses[2] = vars.broadcastRegistry;

            uint8[] memory registryIds = new uint8[](3);
            registryIds[0] = 1;
            registryIds[1] = 2;
            registryIds[2] = 3;

            vars.superRegistryC.setStateRegistryAddress(registryIds, registryAddresses);
            vars.superRBACC.grantRole(vars.superRBACC.MINTER_STATE_REGISTRY_ROLE(), vars.coreStateRegistry);
            vars.superRBACC.grantRole(vars.superRBACC.MINTER_STATE_REGISTRY_ROLE(), vars.twoStepsFormStateRegistry);

            /// @dev 5- deploy Payment Helper
            vars.paymentHelper = address(new PaymentHelper{salt: salt}(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("PaymentHelper"))] = vars.paymentHelper;

            vars.superRegistryC.setAddress(vars.superRegistryC.PAYMENT_HELPER(), vars.paymentHelper, vars.chainId);

            /// @dev 6.1 - deploy Layerzero Implementation
            vars.lzImplementation = address(new LayerzeroImplementation{salt: salt}(vars.superRegistryC));
            contracts[vars.chainId][bytes32(bytes("LayerzeroImplementation"))] = vars.lzImplementation;

            LayerzeroImplementation(payable(vars.lzImplementation)).setLzEndpoint(lzEndpoints[i]);

            /// @dev 6.2 - deploy Hyperlane Implementation
            vars.hyperlaneImplementation = address(
                new HyperlaneImplementation{salt: salt}(
                    SuperRegistry(vars.superRegistry)
                )
            );
            HyperlaneImplementation(vars.hyperlaneImplementation).setHyperlaneConfig(
                HyperlaneMailbox, HyperlaneGasPaymaster
            );
            contracts[vars.chainId][bytes32(bytes("HyperlaneImplementation"))] = vars.hyperlaneImplementation;

            /// @dev 6.3- deploy Wormhole Automatic Relayer Implementation
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

            WormholeSRImplementation(vars.wormholeSRImplementation).setWormholeCore(wormholeCore[i]);

            vars.ambAddresses[0] = vars.lzImplementation;
            vars.ambAddresses[1] = vars.hyperlaneImplementation;
            vars.ambAddresses[2] = vars.wormholeImplementation;
            vars.ambAddresses[3] = vars.wormholeSRImplementation;

            /// @dev 7.1 deploy  LiFiRouterMock. This mock is a very minimal versions to allow
            /// liquidity bridge testing

            vars.lifiRouter = address(new LiFiMock{salt: salt}());
            contracts[vars.chainId][bytes32(bytes("LiFiMock"))] = vars.lifiRouter;
            vm.allowCheatcodes(vars.lifiRouter);

            /// @dev 7.2- deploy  lifi validator
            vars.lifiValidator = address(new LiFiValidator{salt: salt}(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("LiFiValidator"))] = vars.lifiValidator;

            /// @dev 7.3- kycDAO NFT used to test kycDAO vaults
            vars.kycDAOMock = address(new KYCDaoNFTMock{salt: salt}());
            contracts[vars.chainId][bytes32(bytes("KYCDAOMock"))] = vars.kycDAOMock;

            bridgeAddresses.push(vars.lifiRouter);
            bridgeValidators.push(vars.lifiValidator);

            /// @dev 8.1 - Deploy UNDERLYING_TOKENS and VAULTS
            for (uint256 j = 0; j < UNDERLYING_TOKENS.length; j++) {
                vars.UNDERLYING_TOKEN = UNDERLYING_EXISTING_TOKENS[vars.chainId][UNDERLYING_TOKENS[j]];

                if (vars.UNDERLYING_TOKEN == address(0)) {
                    vars.UNDERLYING_TOKEN = address(
                        new MockERC20{salt: salt}(UNDERLYING_TOKENS[j], UNDERLYING_TOKENS[j], deployer, hundredBilly)
                    );
                } else {
                    deal(vars.UNDERLYING_TOKEN, deployer, hundredBilly);
                }
                contracts[vars.chainId][bytes32(bytes(UNDERLYING_TOKENS[j]))] = vars.UNDERLYING_TOKEN;
            }
            bytes memory bytecodeWithArgs;

            /// NOTE: This loop deploys all vaults on all chainIds with all of the UNDERLYING TOKENS (id x form) x
            /// chainId
            for (uint32 j = 0; j < FORM_BEACON_IDS.length; j++) {
                IERC4626[][] memory doubleVaults = new IERC4626[][](
                    UNDERLYING_TOKENS.length
                );

                for (uint256 k = 0; k < UNDERLYING_TOKENS.length; k++) {
                    uint256 lenBytecodes = vaultBytecodes2[FORM_BEACON_IDS[j]].vaultBytecode.length;
                    IERC4626[] memory vaultsT = new IERC4626[](lenBytecodes);
                    for (uint256 l = 0; l < lenBytecodes; l++) {
                        /// @dev 8.2 - Deploy mock Vault

                        if (j != 2) {
                            bytecodeWithArgs = abi.encodePacked(
                                vaultBytecodes2[FORM_BEACON_IDS[j]].vaultBytecode[l],
                                abi.encode(
                                    MockERC20(getContract(vars.chainId, UNDERLYING_TOKENS[k])),
                                    VAULT_NAMES[l][k],
                                    VAULT_NAMES[l][k]
                                )
                            );

                            vars.vault = _deployWithCreate2(bytecodeWithArgs, 1);
                        } else {
                            /// deploy the kycDAOVault wrapper with different args
                            bytecodeWithArgs = abi.encodePacked(
                                vaultBytecodes2[FORM_BEACON_IDS[j]].vaultBytecode[l],
                                abi.encode(MockERC20(getContract(vars.chainId, UNDERLYING_TOKENS[k])), vars.kycDAOMock)
                            );

                            vars.vault = _deployWithCreate2(bytecodeWithArgs, 1);
                        }

                        /// @dev Add ERC4626Vault
                        contracts[vars.chainId][bytes32(bytes(string.concat(VAULT_NAMES[l][k])))] = vars.vault;
                        vaultsT[l] = IERC4626(vars.vault);
                    }
                    doubleVaults[k] = vaultsT;
                }
                vaults[vars.chainId][FORM_BEACON_IDS[j]] = doubleVaults;
            }

            /// @dev 9 - Deploy SuperformFactory
            vars.factory = address(new SuperformFactory{salt: salt}(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("SuperformFactory"))] = vars.factory;

            vars.superRegistryC.setAddress(vars.superRegistryC.SUPERFORM_FACTORY(), vars.factory, vars.chainId);
            vars.superRBACC.grantRole(vars.superRBACC.BROADCASTER_ROLE(), vars.factory);

            /// @dev 9 - Deploy 4626Form implementations
            // Standard ERC4626 Form
            vars.erc4626Form = address(new ERC4626Form{salt: salt}(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("ERC4626Form"))] = vars.erc4626Form;

            // Timelock + ERC4626 Form
            vars.erc4626TimelockForm = address(new ERC4626TimelockForm{salt: salt}(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("ERC4626TimelockForm"))] = vars.erc4626TimelockForm;

            // KYCDao ERC4626 Form
            vars.kycDao4626Form = address(new ERC4626KYCDaoForm{salt: salt}(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("ERC4626KYCDaoForm"))] = vars.kycDao4626Form;

            /// @dev 10 - Add newly deployed form implementations to Factory
            ISuperformFactory(vars.factory).addFormBeacon(vars.erc4626Form, FORM_BEACON_IDS[0], salt);

            ISuperformFactory(vars.factory).addFormBeacon(vars.erc4626TimelockForm, FORM_BEACON_IDS[1], salt);

            ISuperformFactory(vars.factory).addFormBeacon(vars.kycDao4626Form, FORM_BEACON_IDS[2], salt);

            /// @dev 11 - Deploy SuperformRouter
            vars.superformRouter = address(new SuperformRouter{salt: salt}(vars.superRegistry, 1, 1));
            contracts[vars.chainId][bytes32(bytes("SuperformRouter"))] = vars.superformRouter;

            vars.superRegistryC.setAddress(vars.superRegistryC.SUPERFORM_ROUTER(), vars.superformRouter, vars.chainId);
            /// @dev grant extra roles to superformRouter
            vars.superRBACC.grantRole(vars.superRBACC.SUPERPOSITIONS_MINTER_ROLE(), vars.superformRouter);
            vars.superRBACC.grantRole(vars.superRBACC.SUPERPOSITIONS_BURNER_ROLE(), vars.superformRouter);

            /// @dev 12 - Deploy SuperPositions and SuperTransmuter
            vars.superPositions =
                address(new SuperPositions{salt: salt}("https://apiv2-dev.superform.xyz/", vars.superRegistry, 1));

            contracts[vars.chainId][bytes32(bytes("SuperPositions"))] = vars.superPositions;
            vars.superRegistryC.setAddress(vars.superRegistryC.SUPER_POSITIONS(), vars.superPositions, vars.chainId);

            contracts[vars.chainId][bytes32(bytes("SuperTransmuter"))] = address(
                new SuperTransmuter{salt: salt}(
                    IERC1155A(vars.superPositions),
                    vars.superRegistry,
                    2
                )
            );

            vars.superRegistryC.setAddress(
                vars.superRegistryC.SUPER_TRANSMUTER(),
                contracts[vars.chainId][bytes32(bytes("SuperTransmuter"))],
                vars.chainId
            );

            vars.superRBACC.grantRole(
                vars.superRBACC.BROADCASTER_ROLE(), contracts[vars.chainId][bytes32(bytes("SuperTransmuter"))]
            );

            /// @dev 12.1 Set Router Info
            uint8[] memory superformRouterIds = new uint8[](1);
            superformRouterIds[0] = 1;

            address[] memory stateSyncers = new address[](1);
            stateSyncers[0] = vars.superPositions;

            address[] memory routers = new address[](1);
            routers[0] = vars.superformRouter;

            vars.superRegistryC.setRouterInfo(superformRouterIds, stateSyncers, routers);

            /// @dev 13- deploy Payload Helper
            vars.PayloadHelper = address(
                new PayloadHelper{salt: salt}(
                    vars.coreStateRegistry,
                    vars.superRegistry,
                    vars.twoStepsFormStateRegistry
                )
            );
            contracts[vars.chainId][bytes32(bytes("PayloadHelper"))] = vars.PayloadHelper;
            vars.superRegistryC.setAddress(vars.superRegistryC.PAYLOAD_HELPER(), vars.PayloadHelper, vars.chainId);

            /// @dev 14 - Deploy PayMaster
            vars.payMaster = address(new PayMaster{salt: salt}(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes32("PayMaster"))] = vars.payMaster;

            vars.superRegistryC.setAddress(vars.superRegistryC.PAYMASTER(), vars.payMaster, vars.chainId);

            /// @dev 15 - Deploy Dst Swapper
            vars.dstSwapper = address(new DstSwapper{salt: salt}(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes32("DstSwapper"))] = vars.dstSwapper;

            vars.superRegistryC.setAddress(vars.superRegistryC.DST_SWAPPER(), vars.dstSwapper, vars.chainId);

            /// @dev 15 - Super Registry extra setters
            SuperRegistry(vars.superRegistry).setBridgeAddresses(bridgeIds, bridgeAddresses, bridgeValidators);

            /// @dev configures lzImplementation and hyperlane to super registry
            vars.superRegistryC.setAmbAddress(ambIds, vars.ambAddresses, isBroadcastAMB);

            /// @dev 16 setup setup srcChain keepers
            vars.superRegistryC.setAddress(vars.superRegistryC.PAYMENT_ADMIN(), deployer, vars.chainId);
            vars.superRegistryC.setAddress(vars.superRegistryC.CORE_REGISTRY_PROCESSOR(), deployer, vars.chainId);
            vars.superRegistryC.setAddress(vars.superRegistryC.CORE_REGISTRY_UPDATER(), deployer, vars.chainId);
            vars.superRegistryC.setAddress(vars.superRegistryC.BROADCAST_REGISTRY_PROCESSOR(), deployer, vars.chainId);
            vars.superRegistryC.setAddress(vars.superRegistryC.TWO_STEPS_REGISTRY_PROCESSOR(), deployer, vars.chainId);

            delete bridgeAddresses;
            delete bridgeValidators;
        }

        for (uint256 i = 0; i < chainIds.length; i++) {
            vars.chainId = chainIds[i];
            vars.fork = FORKS[vars.chainId];

            vm.selectFork(vars.fork);

            vars.lzImplementation = getContract(vars.chainId, "LayerzeroImplementation");
            vars.hyperlaneImplementation = getContract(vars.chainId, "HyperlaneImplementation");
            vars.wormholeImplementation = getContract(vars.chainId, "WormholeARImplementation");
            vars.wormholeSRImplementation = getContract(vars.chainId, "WormholeSRImplementation");
            vars.superRBAC = getContract(vars.chainId, "SuperRBAC");

            vars.superRegistry = getContract(vars.chainId, "SuperRegistry");
            vars.paymentHelper = getContract(vars.chainId, "PaymentHelper");
            vars.superRegistryC = SuperRegistry(payable(vars.superRegistry));

            /// @dev Set all trusted remotes for each chain, configure amb chains ids, setupQuorum for all chains as 1
            /// and setup PaymentHelper
            /// @dev has to be performed after all main contracts have been deployed on all chains
            for (uint256 j = 0; j < chainIds.length; j++) {
                if (vars.chainId != chainIds[j]) {
                    vars.dstChainId = chainIds[j];

                    vars.dstLzChainId = lz_chainIds[j];
                    vars.dstHypChainId = hyperlane_chainIds[j];
                    vars.dstWormholeChainId = wormhole_chainIds[j];

                    vars.dstLzImplementation = getContract(vars.dstChainId, "LayerzeroImplementation");
                    vars.dstHyperlaneImplementation = getContract(vars.dstChainId, "HyperlaneImplementation");
                    vars.dstWormholeARImplementation = getContract(vars.dstChainId, "WormholeARImplementation");
                    vars.dstWormholeSRImplementation = getContract(vars.dstChainId, "WormholeSRImplementation");
                    vars.dstwormholeBroadcastHelper = getContract(vars.dstChainId, "WormholeBroadcastHelper");

                    LayerzeroImplementation(payable(vars.lzImplementation)).setTrustedRemote(
                        vars.dstLzChainId, abi.encodePacked(vars.dstLzImplementation, vars.lzImplementation)
                    );
                    LayerzeroImplementation(payable(vars.lzImplementation)).setChainId(
                        vars.dstChainId, vars.dstLzChainId
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

                    /// sets the relayer address on all subsequent chains
                    SuperRBAC(vars.superRBAC).grantRole(
                        SuperRBAC(vars.superRBAC).WORMHOLE_VAA_RELAYER_ROLE(), vars.dstwormholeBroadcastHelper
                    );

                    vars.superRegistryC.setRequiredMessagingQuorum(vars.dstChainId, 1);

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
                        vars.superRegistryC.TIMELOCK_STATE_REGISTRY(),
                        getContract(vars.dstChainId, "TimelockStateRegistry"),
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
                        vars.superRegistryC.SUPER_TRANSMUTER(),
                        getContract(vars.dstChainId, "SuperTransmuter"),
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

                    /// @dev FIXME - in mainnet who is this?
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
                        vars.superRegistryC.TWO_STEPS_REGISTRY_PROCESSOR(), deployer, vars.dstChainId
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
        }

        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.selectFork(FORKS[chainIds[i]]);

            /// @dev 18 - create test superforms when the whole state registry is configured

            for (uint256 j = 0; j < FORM_BEACON_IDS.length; j++) {
                for (uint256 k = 0; k < UNDERLYING_TOKENS.length; k++) {
                    uint256 lenBytecodes = vaultBytecodes2[FORM_BEACON_IDS[j]].vaultBytecode.length;

                    for (uint256 l = 0; l < lenBytecodes; l++) {
                        address vault = address(vaults[chainIds[i]][FORM_BEACON_IDS[j]][k][l]);

                        uint256 superformId;
                        (superformId, vars.superform) = ISuperformFactory(
                            contracts[chainIds[i]][bytes32(bytes("SuperformFactory"))]
                        ).createSuperform(FORM_BEACON_IDS[j], vault);

                        if (FORM_BEACON_IDS[j] == 3) {
                            /// mint a kycDAO Nft to the newly kycDAO superform
                            KYCDaoNFTMock(getContract(chainIds[i], "KYCDAOMock")).mint(vars.superform);
                        }

                        contracts[chainIds[i]][bytes32(
                            bytes(
                                string.concat(
                                    UNDERLYING_TOKENS[k],
                                    vaultBytecodes2[FORM_BEACON_IDS[j]].vaultKinds[l],
                                    "Superform",
                                    Strings.toString(FORM_BEACON_IDS[j])
                                )
                            )
                        )] = vars.superform;
                    }
                }
            }

            /// mint a kycDAO Nft to the test users in all chains
            KYCDaoNFTMock(getContract(chainIds[i], "KYCDAOMock")).mint(users[0]);
            KYCDaoNFTMock(getContract(chainIds[i], "KYCDAOMock")).mint(users[1]);
            KYCDaoNFTMock(getContract(chainIds[i], "KYCDAOMock")).mint(users[2]);
        }

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        MISC. HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _preDeploymentSetup() private {
        /// @dev These blocks have been chosen arbitrarily - can be updated to other values
        mapping(uint64 => uint256) storage forks = FORKS;
        forks[ETH] = vm.createFork(ETHEREUM_RPC_URL, 18_092_097);
        forks[BSC] = vm.createFork(BSC_RPC_URL, 31_564_343);
        forks[AVAX] = vm.createFork(AVALANCHE_RPC_URL, 34_923_446);
        forks[POLY] = vm.createFork(POLYGON_RPC_URL, 47_296_382);
        forks[ARBI] = vm.createFork(ARBITRUM_RPC_URL, 129_217_926);
        forks[OP] = vm.createFork(OPTIMISM_RPC_URL, 109_291_345);
        //forks[FTM] = vm.createFork(FANTOM_RPC_URL, 56806404);

        mapping(uint64 => string) storage rpcURLs = RPC_URLS;
        rpcURLs[ETH] = ETHEREUM_RPC_URL;
        rpcURLs[BSC] = BSC_RPC_URL;
        rpcURLs[AVAX] = AVALANCHE_RPC_URL;
        rpcURLs[POLY] = POLYGON_RPC_URL;
        rpcURLs[ARBI] = ARBITRUM_RPC_URL;
        rpcURLs[OP] = OPTIMISM_RPC_URL;
        //rpcURLs[FTM] = FANTOM_RPC_URL;

        mapping(uint64 => address) storage lzEndpointsStorage = LZ_ENDPOINTS;
        lzEndpointsStorage[ETH] = ETH_lzEndpoint;
        lzEndpointsStorage[BSC] = BSC_lzEndpoint;
        lzEndpointsStorage[AVAX] = AVAX_lzEndpoint;
        lzEndpointsStorage[POLY] = POLY_lzEndpoint;
        lzEndpointsStorage[ARBI] = ARBI_lzEndpoint;
        lzEndpointsStorage[OP] = OP_lzEndpoint;
        //lzEndpointsStorage[FTM] = FTM_lzEndpoint;

        mapping(uint64 => uint16) storage wormholeChainIdsStorage = WORMHOLE_CHAIN_IDS;

        for (uint256 i = 0; i < chainIds.length; i++) {
            wormholeChainIdsStorage[chainIds[i]] = wormhole_chainIds[i];
        }

        /// price feeds on all chains, for paymentHelper
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

        /// @dev setup bridges. 1 is lifi
        bridgeIds.push(1);

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

        /// @dev form 2 (timelocked 4626)
        vaultBytecodes2[2].vaultBytecode.push(type(ERC4626TimelockMock).creationCode);
        vaultBytecodes2[2].vaultKinds.push("ERC4626TimelockMock");
        vaultBytecodes2[2].vaultBytecode.push(type(ERC4626TimelockMockRevertWithdrawal).creationCode);
        vaultBytecodes2[2].vaultKinds.push("ERC4626TimelockMockRevertWithdrawal");
        vaultBytecodes2[2].vaultBytecode.push(type(ERC4626TimelockMockRevertDeposit).creationCode);
        vaultBytecodes2[2].vaultKinds.push("ERC4626TimelockMockRevertDeposit");

        /// @dev form 3 (kycdao 4626)
        vaultBytecodes2[3].vaultBytecode.push(type(kycDAO4626).creationCode);
        vaultBytecodes2[3].vaultKinds.push("kycDAO4626");
        vaultBytecodes2[3].vaultBytecode.push(type(kycDAO4626RevertDeposit).creationCode);
        vaultBytecodes2[3].vaultKinds.push("kycDAO4626RevertDeposit");
        vaultBytecodes2[3].vaultBytecode.push(type(kycDAO4626RevertWithdraw).creationCode);
        vaultBytecodes2[3].vaultKinds.push("kycDAO4626RevertWithdraw");

        /// @dev populate VAULT_NAMES state arg with tokenNames + vaultKinds names
        string[] memory underlyingTokens = UNDERLYING_TOKENS;
        for (uint256 i = 0; i < VAULT_KINDS.length; i++) {
            for (uint256 j = 0; j < underlyingTokens.length; j++) {
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

        existingTokens[10]["DAI"] = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
        existingTokens[10]["USDC"] = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;
        existingTokens[10]["WETH"] = 0x4200000000000000000000000000000000000006;

        existingTokens[1]["DAI"] = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        existingTokens[1]["USDC"] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        existingTokens[1]["WETH"] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        existingTokens[137]["DAI"] = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
        existingTokens[137]["USDC"] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        existingTokens[137]["WETH"] = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

        existingTokens[56]["DAI"] = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        existingTokens[56]["USDC"] = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
        existingTokens[56]["WETH"] = address(0);
    }

    function _fundNativeTokens() private {
        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.selectFork(FORKS[chainIds[i]]);

            uint256 amountDeployer = 1e24;
            uint256 amountUSER = 1e24;

            vm.deal(deployer, amountDeployer);

            vm.deal(users[0], amountUSER);
            vm.deal(users[1], amountUSER);
            vm.deal(users[2], amountUSER);
        }
    }

    function _fundUnderlyingTokens(uint256 amount) private {
        for (uint256 j = 0; j < UNDERLYING_TOKENS.length; j++) {
            if (getContract(chainIds[0], UNDERLYING_TOKENS[j]) == address(0)) {
                revert INVALID_UNDERLYING_TOKEN_NAME();
            }

            for (uint256 i = 0; i < chainIds.length; i++) {
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

        address[] memory dstTargets = new address[](5);
        address[] memory dstWormhole = new address[](5);

        uint256[] memory forkIds = new uint256[](5);

        uint16 currWormholeChainId;

        uint256 j;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] != currentChainId) {
                dstWormhole[j] = wormholeCore[i];
                dstTargets[j] = getContract(chainIds[i], "WormholeSRImplementation");

                forkIds[j] = FORKS[chainIds[i]];

                j++;
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
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, _getEIP712Hash(permit, spender, chainId));
        return abi.encodePacked(r, s, v);
    }

    // Compute the EIP712 hash of the permit object.
    // Normally this would be implemented off-chain.
    function _getEIP712Hash(
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

    ///@dev Compute the address of the contract to be deployed
    function getAddress(bytes memory bytecode_, bytes32 salt_, address deployer_) public pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), deployer_, salt_, keccak256(bytecode_)));

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    /*//////////////////////////////////////////////////////////////
                GAS ESTIMATION & PAYLOAD HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Generates the extraData for each amb
    /// @dev TODO - Sujith to comment further
    function _generateExtraData(uint8[] memory selectedAmbIds) internal pure returns (bytes[] memory) {
        bytes[] memory ambParams = new bytes[](selectedAmbIds.length);

        for (uint256 i; i < selectedAmbIds.length; i++) {
            /// @dev 1 = Lz
            if (selectedAmbIds[i] == 1) {
                ambParams[i] = bytes("");
            }

            /// @dev 2 = Hyperlane
            if (selectedAmbIds[i] == 2) {
                ambParams[i] = abi.encode(500_000);
            }

            /// @dev 3 = Wormhole
            if (selectedAmbIds[i] == 3) {
                ambParams[i] = abi.encode(0, 500_000);
            }
        }

        return ambParams;
    }

    struct LocalAckVars {
        uint256 totalFees;
        uint256 ambCount;
        uint64 srcChainId;
        uint64 dstChainId;
        PaymentHelper paymentHelper;
        PayloadHelper payloadHelper;
        bytes message;
    }

    /// @dev Generates the acknowledgement amb params for the entire action
    /// @dev TODO - Sujith to comment further
    function _generateAckGasFeesAndParams(
        uint64 srcChainId,
        uint64 dstChainId,
        uint8[] memory selectedAmbIds,
        uint256 payloadId
    )
        internal
        view
        returns (uint256 msgValue, bytes memory ackData)
    {
        LocalAckVars memory vars;

        vars.ambCount = selectedAmbIds.length;

        bytes[] memory paramsPerAMB = new bytes[](vars.ambCount);
        paramsPerAMB = _generateExtraData(selectedAmbIds);

        uint256[] memory gasPerAMB = new uint256[](vars.ambCount);

        address _payloadHelper = contracts[dstChainId][bytes32(bytes("PayloadHelper"))];
        vars.payloadHelper = PayloadHelper(_payloadHelper);

        (,,,, uint256[] memory amounts,, uint256[] memory superformIds,,) =
            vars.payloadHelper.decodeCoreStateRegistryPayload(payloadId);

        vars.message = abi.encode(
            AMBMessage(2 ** 256 - 1, abi.encode(ReturnMultiData(2 ** 8 - 1, payloadId, superformIds, amounts)))
        );

        address _paymentHelper = contracts[dstChainId][bytes32(bytes("PaymentHelper"))];
        vars.paymentHelper = PaymentHelper(_paymentHelper);

        (vars.totalFees, gasPerAMB) =
            vars.paymentHelper.estimateAMBFees(selectedAmbIds, srcChainId, abi.encode(vars.message), paramsPerAMB);

        AMBExtraData memory extraData = AMBExtraData(gasPerAMB, paramsPerAMB);

        return (vars.totalFees, abi.encode(AckAMBData(selectedAmbIds, abi.encode(extraData))));
    }

    /// @dev Generates the acknowledgement amb params for the entire action
    /// @dev TODO - Sujith to comment further
    function _generateAckGasFeesAndParamsForTimeLock(
        bytes memory chainIds_,
        uint8[] memory selectedAmbIds,
        uint256 timelockPayloadId
    )
        internal
        view
        returns (uint256 msgValue, bytes memory)
    {
        LocalAckVars memory vars;
        (vars.srcChainId, vars.dstChainId) = abi.decode(chainIds_, (uint64, uint64));

        vars.ambCount = selectedAmbIds.length;

        bytes[] memory paramsPerAMB = new bytes[](vars.ambCount);
        paramsPerAMB = _generateExtraData(selectedAmbIds);

        uint256[] memory gasPerAMB = new uint256[](vars.ambCount);

        address _paymentHelper = contracts[vars.dstChainId][bytes32(bytes("PaymentHelper"))];
        vars.paymentHelper = PaymentHelper(_paymentHelper);

        address _payloadHelper = contracts[vars.dstChainId][bytes32(bytes("PayloadHelper"))];
        vars.payloadHelper = PayloadHelper(_payloadHelper);

        (,, uint256 payloadId, uint256 superformId, uint256 amount) =
            vars.payloadHelper.decodeTimeLockPayload(timelockPayloadId);

        vars.message = abi.encode(
            AMBMessage(2 ** 256 - 1, abi.encode(ReturnSingleData(2 ** 8 - 1, payloadId, superformId, amount)))
        );

        (vars.totalFees, gasPerAMB) =
            vars.paymentHelper.estimateAMBFees(selectedAmbIds, vars.srcChainId, abi.encode(vars.message), paramsPerAMB);

        AMBExtraData memory extraData = AMBExtraData(gasPerAMB, paramsPerAMB);

        return (vars.totalFees, abi.encode(AckAMBData(selectedAmbIds, abi.encode(extraData))));
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

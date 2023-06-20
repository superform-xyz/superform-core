/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @dev lib imports
import "forge-std/Test.sol";
import "ds-test/test.sol";
import "./TestTypes.sol";
import {LayerZeroHelper} from "pigeon/src/layerzero/LayerZeroHelper.sol";
import {HyperlaneHelper} from "pigeon/src/hyperlane/HyperlaneHelper.sol";
import {CelerHelper} from "pigeon/src/celer/CelerHelper.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {kycDAO4626} from "super-vaults/kycdao-4626/kycdao4626.sol";

/// @dev test utils & mocks
import {SocketRouterMock} from "../mocks/SocketRouterMock.sol";
import {LiFiMock} from "../mocks/LiFiMock.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {VaultMock} from "../mocks/VaultMock.sol";
import {VaultMockRevertDeposit} from "../mocks/VaultMockRevertDeposit.sol";
import {ERC4626TimelockMock} from "../mocks/ERC4626TimelockMock.sol";
import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";
import {Permit2Clone} from "../mocks/Permit2Clone.sol";
import {KYCDaoNFTMock} from "../mocks/KYCDaoNFTMock.sol";

/// @dev Protocol imports
import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {CoreStateRegistry} from "../../crosschain-data/CoreStateRegistry.sol";
import {RolesStateRegistry} from "../../crosschain-data/RolesStateRegistry.sol";
import {FactoryStateRegistry} from "../../crosschain-data/FactoryStateRegistry.sol";
import {ISuperFormRouter} from "../../interfaces/ISuperFormRouter.sol";
import {ISuperFormFactory} from "../../interfaces/ISuperFormFactory.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {IBaseForm} from "../../interfaces/IBaseForm.sol";
import {SuperFormRouter} from "../../SuperFormRouter.sol";
import {SuperRegistry} from "../../settings/SuperRegistry.sol";
import {SuperRBAC} from "../../settings/SuperRBAC.sol";
import {SuperPositions} from "../../SuperPositions.sol";
import {SuperFormFactory} from "../../SuperFormFactory.sol";
import {ERC4626Form} from "../../forms/ERC4626Form.sol";
import {ERC4626TimelockForm} from "../../forms/ERC4626TimelockForm.sol";
import {ERC4626KYCDaoForm} from "../../forms/ERC4626KYCDaoForm.sol";
import {MultiTxProcessor} from "../../crosschain-liquidity/MultiTxProcessor.sol";
import {LiFiValidator} from "../../crosschain-liquidity/lifi/LiFiValidator.sol";
import {SocketValidator} from "../../crosschain-liquidity/socket/SocketValidator.sol";
import {LayerzeroImplementation} from "../../crosschain-data/layerzero/LayerzeroImplementation.sol";
import {HyperlaneImplementation} from "../../crosschain-data/hyperlane/HyperlaneImplementation.sol";
import {CelerImplementation} from "../../crosschain-data/celer/CelerImplementation.sol";
import {IMailbox} from "../../vendor/hyperlane/IMailbox.sol";
import {IInterchainGasPaymaster} from "../../vendor/hyperlane/IInterchainGasPaymaster.sol";
import {IMessageBus} from "../../vendor/celer/IMessageBus.sol";
import ".././utils/AmbParams.sol";
import {IPermit2} from "../../vendor/dragonfly-xyz/IPermit2.sol";
import {ISuperPositions} from "../../interfaces/ISuperPositions.sol";
import {TwoStepsFormStateRegistry} from "../../crosschain-data/TwoStepsFormStateRegistry.sol";
import {CoreStateRegistryHelper} from "../../crosschain-data/helpers/CoreStateRegistryHelper.sol";

abstract contract BaseSetup is DSTest, Test {
    /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
    //////////////////////////////////////////////////////////////*/
    bytes32 constant TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");
    bytes32 constant PERMIT_TRANSFER_FROM_TYPEHASH =
        keccak256(
            "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
        );

    /// @dev
    address public constant CANONICAL_PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3; /// @dev for mainnet deployment
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public deployer = address(777);
    address[] public users;
    uint256[] public userKeys;

    uint256 public trustedRemote;
    bytes32 public constant salt = "SUPERFORM";
    mapping(uint64 chainId => mapping(bytes32 implementation => address at)) public contracts;

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

    /// @dev we should fork these instead of mocking
    string[] public UNDERLYING_TOKENS = ["DAI", "USDT", "WETH"];

    /// @dev 1 = ERC4626Form, 2 = ERC4626TimelockForm, 3 = KYCDaoForm
    uint32[] public FORM_BEACON_IDS = [uint32(1), uint32(2), uint32(3)];

    /// @dev WARNING!! THESE VAULT NAMES MUST BE THE EXACT NAMES AS FILLED IN vaultKinds
    string[] public VAULT_KINDS = ["VaultMock", "ERC4626TimelockMock", "kycDAO4626", "VaultMockRevertDeposit"];
    struct VaultInfo {
        bytes[] vaultBytecode;
        string[] vaultKinds;
    }
    mapping(uint32 formBeaconId => VaultInfo vaultInfo) vaultBytecodes2;

    bytes[] public vault4626Bytecodes;
    bytes[] public vaultKycBytecodes;
    bytes[] public vaultTiemlockedBytecodes;

    mapping(uint256 vaultId => string[] names) VAULT_NAMES;

    /// FIXME: We need to map individual formBeaconId to individual vault to have access to ERC4626Form previewFunctions
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

    address[] public celerMessageBusses = [
        0x4066D196A423b2b3B8B054f4F40efB47a74E200C,
        0x95714818fdd7a5454F73Da9c777B3ee6EbAEEa6B,
        0x5a926eeeAFc4D217ADd17e9641e8cE23Cd01Ad57,
        0xaFDb9C40C7144022811F034EE07Ce2E110093fe6,
        0x3Ad9d0648CDAA2426331e894e980D0a5Ed16257f,
        0x0D71D18126E03646eb09FEc929e2ae87b7CAE69d
    ];

    /*////////////////////////////////////////////////////zr//////////
                        HYPERLANE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IMailbox public constant HyperlaneMailbox = IMailbox(0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70);
    IInterchainGasPaymaster public constant HyperlaneGasPaymaster =
        IInterchainGasPaymaster(0x6cA0B6D22da47f091B7613223cD4BB03a2d77918);

    /*////////////////////////////////////////////////////zr//////////
                        CELER VARIABLES
    //////////////////////////////////////////////////////////////*/
    address public constant ETH_messageBus = 0x4066D196A423b2b3B8B054f4F40efB47a74E200C;
    address public constant BSC_messageBus = 0x95714818fdd7a5454F73Da9c777B3ee6EbAEEa6B;
    address public constant AVAX_messageBus = 0x5a926eeeAFc4D217ADd17e9641e8cE23Cd01Ad57;
    address public constant POLY_messageBus = 0xaFDb9C40C7144022811F034EE07Ce2E110093fe6;
    address public constant ARBI_messageBus = 0x3Ad9d0648CDAA2426331e894e980D0a5Ed16257f;
    address public constant OP_messageBus = 0x0D71D18126E03646eb09FEc929e2ae87b7CAE69d;
    address public constant FTM_messageBus = 0xFF4E183a0Ceb4Fa98E63BbF8077B929c8E5A2bA4;

    uint64 public constant ETH = 1;
    uint64 public constant BSC = 56;
    uint64 public constant AVAX = 43114;
    uint64 public constant POLY = 137;
    uint64 public constant ARBI = 42161;
    uint64 public constant OP = 10;
    //uint64 public constant FTM = 250;

    uint64[] public chainIds = [1, 56, 43114, 137, 42161, 10];

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
    uint64[] public celer_chainIds = [1, 56, 43114, 137, 42161, 10];

    uint256[] public llChainIds = [1, 56, 43114, 137, 42161, 10];

    uint256 public constant milionTokensE18 = 1 ether;

    /*//////////////////////////////////////////////////////////////
                        CHAINLINK VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(uint64 => address) public PRICE_FEEDS;

    address public constant ETHEREUM_ETH_USD_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public constant BSC_BNB_USD_FEED = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    address public constant AVALANCHE_AVAX_USD_FEED = 0x0A77230d17318075983913bC2145DB16C7366156;
    address public constant POLYGON_MATIC_USD_FEED = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
    address public constant FANTOM_FTM_USD_FEED = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc;

    /*//////////////////////////////////////////////////////////////
                        RPC VARIABLES
    //////////////////////////////////////////////////////////////*/

    // chainID => FORK
    mapping(uint64 chainId => uint256 fork) public FORKS;
    mapping(uint64 chainId => string forkUrl) public RPC_URLS;

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

    address[] public kycDAOValidityAddresses = [
        address(0),
        address(0),
        address(0),
        0x205E10d3c4C87E26eB66B1B270b71b7708494dB9,
        address(0),
        address(0)
    ];

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
            vm.selectFork(vars.fork);

            vars.canonicalPermit2 = address(new Permit2Clone{salt: salt}());
            contracts[vars.chainId][bytes32(bytes("CanonicalPermit2"))] = vars.canonicalPermit2;

            /// @dev 1.1- deploy LZ Helper from Pigeon
            vars.lzHelper = address(new LayerZeroHelper{salt: salt}());
            vm.allowCheatcodes(vars.lzHelper);

            contracts[vars.chainId][bytes32(bytes("LayerZeroHelper"))] = vars.lzHelper;

            /// @dev 1.2- deploy Hyperlane Helper from Pigeon
            vars.hyperlaneHelper = address(new HyperlaneHelper{salt: salt}());
            vm.allowCheatcodes(vars.hyperlaneHelper);

            contracts[vars.chainId][bytes32(bytes("HyperlaneHelper"))] = vars.hyperlaneHelper;

            /// @dev 1.3- deploy Celer Helper from Pigeon
            vars.celerHelper = address(new CelerHelper{salt: salt}());
            vm.allowCheatcodes(vars.celerHelper);

            contracts[vars.chainId][bytes32(bytes("CelerHelper"))] = vars.celerHelper;

            /// @dev 2 - Deploy SuperRBAC
            vars.superRBAC = address(new SuperRBAC{salt: salt}(deployer));
            contracts[vars.chainId][bytes32(bytes("SuperRBAC"))] = vars.superRBAC;

            /// @dev 3 - Deploy SuperRegistry and assign roles
            vars.superRegistry = address(new SuperRegistry{salt: salt}(vars.superRBAC));
            contracts[vars.chainId][bytes32(bytes("SuperRegistry"))] = vars.superRegistry;

            SuperRBAC(vars.superRBAC).setSuperRegistry(vars.superRegistry);
            SuperRegistry(vars.superRegistry).setImmutables(vars.chainId, vars.canonicalPermit2);

            assert(SuperRBAC(vars.superRBAC).hasProtocolAdminRole(deployer));

            /// @dev FIXME: in reality who should have the EMERGENCY_ADMIN_ROLE?
            SuperRBAC(vars.superRBAC).grantEmergencyAdminRole(deployer);
            assert(SuperRBAC(vars.superRBAC).hasEmergencyAdminRole(deployer));

            /// @dev FIXME: in reality who should have the SWAPPER_ROLE for multiTxProcessor?
            SuperRBAC(vars.superRBAC).grantSwapperRole(deployer);
            assert(SuperRBAC(vars.superRBAC).hasSwapperRole(deployer));

            /// @dev FIXME: in reality who should have the PROCESSOR_ROLE for state registry?
            SuperRBAC(vars.superRBAC).grantProcessorRole(deployer);
            assert(SuperRBAC(vars.superRBAC).hasProcessorRole(deployer));

            /// @dev FIXME: in reality who should have the UPDATER_ROLE for state registry?
            SuperRBAC(vars.superRBAC).grantUpdaterRole(deployer);
            assert(SuperRBAC(vars.superRBAC).hasUpdaterRole(deployer));

            /// @dev FIXME: in reality who should have the TWOSTEPS_PROCESSOR_ROLE for state registry?
            SuperRBAC(vars.superRBAC).grantTwoStepsProcessorRole(deployer);
            assert(SuperRBAC(vars.superRBAC).hasTwoStepsProcessorRole(deployer));

            /// @dev 4.1 - deploy Core State Registry

            vars.coreStateRegistry = address(new CoreStateRegistry{salt: salt}(SuperRegistry(vars.superRegistry), 1));
            contracts[vars.chainId][bytes32(bytes("CoreStateRegistry"))] = vars.coreStateRegistry;

            SuperRegistry(vars.superRegistry).setCoreStateRegistry(vars.coreStateRegistry);

            /// @dev 4.1.1- deploy Core State Registry Helper
            vars.coreStateRegistryHelper = address(
                new CoreStateRegistryHelper{salt: salt}(vars.coreStateRegistry, vars.superRegistry)
            );
            contracts[vars.chainId][bytes32(bytes("CoreStateRegistryHelper"))] = vars.coreStateRegistryHelper;

            /// @dev 4.2- deploy Factory State Registry
            vars.factoryStateRegistry = address(
                new FactoryStateRegistry{salt: salt}(SuperRegistry(vars.superRegistry), 2)
            );

            contracts[vars.chainId][bytes32(bytes("FactoryStateRegistry"))] = vars.factoryStateRegistry;

            SuperRegistry(vars.superRegistry).setFactoryStateRegistry(vars.factoryStateRegistry);

            /// @dev 4.3 - deploy Form State Registry
            vars.twoStepsFormStateRegistry = address(
                new TwoStepsFormStateRegistry{salt: salt}(SuperRegistry(vars.superRegistry), 4)
            );

            contracts[vars.chainId][bytes32(bytes("TwoStepsFormStateRegistry"))] = vars.twoStepsFormStateRegistry;

            SuperRegistry(vars.superRegistry).setTwoStepsFormStateRegistry(vars.twoStepsFormStateRegistry);

            /// @dev 4.4- deploy Roles State Registry
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

            /// @dev 5.1 - deploy Layerzero Implementation
            vars.lzImplementation = address(new LayerzeroImplementation{salt: salt}(SuperRegistry(vars.superRegistry)));
            contracts[vars.chainId][bytes32(bytes("LayerzeroImplementation"))] = vars.lzImplementation;

            LayerzeroImplementation(payable(vars.lzImplementation)).setLzEndpoint(lzEndpoints[i]);

            /// @dev 5.2 - deploy Hyperlane Implementation
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

            CelerImplementation(payable(vars.celerImplementation)).setCelerBus(celerMessageBusses[i]);

            vars.ambAddresses[0] = vars.lzImplementation;
            vars.ambAddresses[1] = vars.hyperlaneImplementation;
            vars.ambAddresses[2] = vars.celerImplementation;

            /// @dev 6.1 deploy SocketRouterMock and LiFiRouterMock
            vars.socketRouter = address(new SocketRouterMock{salt: salt}());
            contracts[vars.chainId][bytes32(bytes("SocketRouterMock"))] = vars.socketRouter;
            vm.allowCheatcodes(vars.socketRouter);

            vars.lifiRouter = address(new LiFiMock{salt: salt}());
            contracts[vars.chainId][bytes32(bytes("LiFiMock"))] = vars.lifiRouter;
            vm.allowCheatcodes(vars.lifiRouter);

            /// @dev 6.2- deploy socket and lifi validator
            vars.socketValidator = address(new SocketValidator{salt: salt}(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("SocketValidator"))] = vars.socketValidator;

            SocketValidator(vars.socketValidator).setChainIds(chainIds, llChainIds);

            vars.lifiValidator = address(new LiFiValidator{salt: salt}(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("LiFiValidator"))] = vars.lifiValidator;

            LiFiValidator(vars.lifiValidator).setChainIds(chainIds, llChainIds);

            vars.kycDAOMock = address(new KYCDaoNFTMock{salt: salt}());
            contracts[vars.chainId][bytes32(bytes("KYCDAOMock"))] = vars.kycDAOMock;

            if (i == 0) {
                bridgeAddresses.push(vars.socketRouter);
                bridgeValidators.push(vars.socketValidator);
                bridgeAddresses.push(vars.lifiRouter);
                bridgeValidators.push(vars.lifiValidator);
            }

            /// @dev 7.1 - Deploy UNDERLYING_TOKENS and VAULTS
            /// NOTE: This loop deploys all Forms on all chainIds with all of the UNDERLYING TOKENS (id x form) x chainId
            for (uint256 j = 0; j < UNDERLYING_TOKENS.length; j++) {
                vars.UNDERLYING_TOKEN = address(
                    new MockERC20{salt: salt}(UNDERLYING_TOKENS[j], UNDERLYING_TOKENS[j], deployer, milionTokensE18)
                );
                contracts[vars.chainId][bytes32(bytes(UNDERLYING_TOKENS[j]))] = vars.UNDERLYING_TOKEN;
            }
            uint256 vaultId = 0;
            bytes memory bytecodeWithArgs;

            for (uint32 j = 0; j < FORM_BEACON_IDS.length; j++) {
                IERC4626[][] memory doubleVaults = new IERC4626[][](UNDERLYING_TOKENS.length);

                for (uint256 k = 0; k < UNDERLYING_TOKENS.length; k++) {
                    uint256 lenBytecodes = vaultBytecodes2[FORM_BEACON_IDS[j]].vaultBytecode.length;
                    IERC4626[] memory vaultsT = new IERC4626[](lenBytecodes);
                    for (uint256 l = 0; l < lenBytecodes; l++) {
                        /// @dev 7.2 - Deploy mock Vault

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
                            /// deploy the kycDAOVault wrapper with different args only in Polygon

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

            /// @dev 8 - Deploy SuperFormFactory
            vars.factory = address(new SuperFormFactory{salt: salt}(vars.superRegistry));

            contracts[vars.chainId][bytes32(bytes("SuperFormFactory"))] = vars.factory;

            SuperRegistry(vars.superRegistry).setSuperFormFactory(vars.factory);

            /// @dev 9 - Deploy 4626Form implementations
            // Standard ERC4626 Form
            vars.erc4626Form = address(new ERC4626Form{salt: salt}(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("ERC4626Form"))] = vars.erc4626Form;

            // Timelock + ERC4626 Form
            vars.erc4626TimelockForm = address(new ERC4626TimelockForm{salt: salt}(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("ERC4626TimelockForm"))] = vars.erc4626TimelockForm;

            /// @dev 10 - Add newly deployed form  implementation to Factory, formBeaconId 1
            ISuperFormFactory(vars.factory).addFormBeacon(vars.erc4626Form, FORM_BEACON_IDS[0], salt);

            ISuperFormFactory(vars.factory).addFormBeacon(vars.erc4626TimelockForm, FORM_BEACON_IDS[1], salt);

            // KYCDao ERC4626 Form (only for Polygon)
            vars.kycDao4626Form = address(new ERC4626KYCDaoForm{salt: salt}(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("ERC4626KYCDaoForm"))] = vars.kycDao4626Form;

            ISuperFormFactory(vars.factory).addFormBeacon(vars.kycDao4626Form, FORM_BEACON_IDS[2], salt);

            /// @dev 12 - Deploy SuperFormRouter
            vars.superRouter = address(new SuperFormRouter{salt: salt}(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("SuperFormRouter"))] = vars.superRouter;

            SuperRegistry(vars.superRegistry).setSuperRouter(vars.superRouter);

            /// @dev 13 - Deploy SuperPositions
            vars.superPositions = address(new SuperPositions{salt: salt}("test.com/", vars.superRegistry));

            contracts[vars.chainId][bytes32(bytes("SuperPositions"))] = vars.superPositions;

            SuperRegistry(vars.superRegistry).setSuperPositions(vars.superPositions);

            /// @dev 14 - Deploy MultiTx Processor
            vars.multiTxProcessor = address(new MultiTxProcessor{salt: salt}(vars.superRegistry));
            contracts[vars.chainId][bytes32(bytes("MultiTxProcessor"))] = vars.multiTxProcessor;

            SuperRegistry(vars.superRegistry).setMultiTxProcessor(vars.multiTxProcessor);

            /// @dev 15 - Super Registry extra setters

            SuperRegistry(vars.superRegistry).setBridgeAddresses(bridgeIds, bridgeAddresses, bridgeValidators);

            /// @dev configures lzImplementation and hyperlane to super registry
            SuperRegistry(payable(getContract(vars.chainId, "SuperRegistry"))).setAmbAddress(ambIds, vars.ambAddresses);

            /// @dev 16 Setup extra RBAC

            SuperRBAC(vars.superRBAC).grantCoreContractsRole(vars.superRouter);
            SuperRBAC(vars.superRBAC).grantCoreContractsRole(vars.factory);

            /// FIXME: check if this is safe in all aspects
            SuperRBAC(vars.superRBAC).grantProtocolAdminRole(vars.rolesStateRegistry);

            /// @dev Set all trusted remotes for each chain & configure amb chains ids
            /// @dev Set message quorum for all chain ids (as 1)
            for (uint256 j = 0; j < chainIds.length; j++) {
                if (vars.chainId != chainIds[j]) {
                    vars.dstChainId = chainIds[j];
                    vars.dstLzChainId = lz_chainIds[j];
                    vars.dstHypChainId = hyperlane_chainIds[j];
                    vars.dstCelerChainId = celer_chainIds[j];

                    /// @dev this is possible because our contracts are Create2 (same address)
                    vars.dstLzImplementation = getContract(vars.chainId, "LayerzeroImplementation");
                    vars.dstHyperlaneImplementation = getContract(vars.chainId, "HyperlaneImplementation");
                    vars.dstCelerImplementation = getContract(vars.chainId, "CelerImplementation");

                    LayerzeroImplementation(payable(vars.lzImplementation)).setTrustedRemote(
                        vars.dstLzChainId,
                        abi.encodePacked(vars.dstLzImplementation, vars.lzImplementation)
                    );
                    LayerzeroImplementation(payable(vars.lzImplementation)).setChainId(
                        vars.dstChainId,
                        vars.dstLzChainId
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

                    CelerImplementation(payable(vars.celerImplementation)).setReceiver(
                        vars.dstCelerChainId,
                        vars.dstCelerImplementation
                    );

                    CelerImplementation(payable(vars.celerImplementation)).setChainId(
                        vars.dstChainId,
                        vars.dstCelerChainId
                    );

                    CoreStateRegistry(payable(vars.coreStateRegistry)).setRequiredMessagingQuorum(vars.dstChainId, 1);
                }
            }
        }

        /// @dev 17 - create superforms when the whole state registry is configured
        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.selectFork(FORKS[chainIds[i]]);
            for (uint256 j = 0; j < FORM_BEACON_IDS.length; j++) {
                for (uint256 k = 0; k < UNDERLYING_TOKENS.length; k++) {
                    uint256 lenBytecodes = vaultBytecodes2[FORM_BEACON_IDS[j]].vaultBytecode.length;

                    for (uint256 l = 0; l < lenBytecodes; l++) {
                        address vault = address(vaults[chainIds[i]][FORM_BEACON_IDS[j]][k][l]);

                        uint256 superFormId;
                        (superFormId, vars.superForm) = ISuperFormFactory(
                            contracts[chainIds[i]][bytes32(bytes("SuperFormFactory"))]
                        ).createSuperForm(FORM_BEACON_IDS[j], vault);

                        if (FORM_BEACON_IDS[j] == 3) {
                            /// mint a kycDAO Nft to superForm on polygon
                            KYCDaoNFTMock(getContract(chainIds[i], "KYCDAOMock")).mint(vars.superForm);
                        }

                        contracts[chainIds[i]][
                            bytes32(
                                bytes(
                                    string.concat(
                                        UNDERLYING_TOKENS[k],
                                        vaultBytecodes2[FORM_BEACON_IDS[j]].vaultKinds[l],
                                        "SuperForm",
                                        Strings.toString(FORM_BEACON_IDS[j])
                                    )
                                )
                            )
                        ] = vars.superForm;
                    }
                }
            }

            /// mint a kycDAO Nft to a few users
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
        mapping(uint64 => uint256) storage forks = FORKS;
        forks[ETH] = vm.createFork(ETHEREUM_RPC_URL, 16742187);
        forks[BSC] = vm.createFork(BSC_RPC_URL, 26121321);
        forks[AVAX] = vm.createFork(AVALANCHE_RPC_URL, 26933006);
        forks[POLY] = vm.createFork(POLYGON_RPC_URL, 39887036);
        forks[ARBI] = vm.createFork(ARBITRUM_RPC_URL, 66125184);
        forks[OP] = vm.createFork(OPTIMISM_RPC_URL, 78219242);
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

        mapping(uint64 => address) storage celerMessageBusStorage = CELER_BUSSES;
        celerMessageBusStorage[ETH] = ETH_messageBus;
        celerMessageBusStorage[BSC] = BSC_messageBus;
        celerMessageBusStorage[AVAX] = AVAX_messageBus;
        celerMessageBusStorage[POLY] = POLY_messageBus;
        celerMessageBusStorage[ARBI] = ARBI_messageBus;
        celerMessageBusStorage[OP] = OP_messageBus;

        mapping(uint64 => uint64) storage celerChainIdsStorage = CELER_CHAIN_IDS;

        for (uint256 i = 0; i < chainIds.length; i++) {
            celerChainIdsStorage[chainIds[i]] = celer_chainIds[i];
        }

        mapping(uint64 => address) storage priceFeeds = PRICE_FEEDS;
        priceFeeds[ETH] = ETHEREUM_ETH_USD_FEED;
        priceFeeds[BSC] = BSC_BNB_USD_FEED;
        priceFeeds[AVAX] = AVALANCHE_AVAX_USD_FEED;
        priceFeeds[POLY] = POLYGON_MATIC_USD_FEED;
        priceFeeds[ARBI] = address(0);
        priceFeeds[OP] = address(0);
        //priceFeeds[FTM] = FANTOM_FTM_USD_FEED;

        /// @dev setup bridges. 1 is the socket mock
        bridgeIds.push(1);
        bridgeIds.push(2);

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
        vaultBytecodes2[1].vaultKinds.push("VaultMock");
        vaultBytecodes2[1].vaultKinds.push("VaultMockRevertDeposit");

        /// @dev form 2 (timelocked 4626)
        vaultBytecodes2[2].vaultBytecode.push(type(ERC4626TimelockMock).creationCode);
        vaultBytecodes2[2].vaultKinds.push("ERC4626TimelockMock");

        /// @dev form 3 (kycdao 4626)
        vaultBytecodes2[3].vaultBytecode.push(type(kycDAO4626).creationCode);
        vaultBytecodes2[3].vaultKinds.push("kycDAO4626");

        string[] memory underlyingTokens = UNDERLYING_TOKENS;
        for (uint256 i = 0; i < VAULT_KINDS.length; i++) {
            for (uint256 j = 0; j < underlyingTokens.length; j++) {
                VAULT_NAMES[i].push(string.concat(underlyingTokens[j], VAULT_KINDS[i]));
            }
        }
    }

    function _fundNativeTokens() private {
        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.selectFork(FORKS[chainIds[i]]);

            uint256 multiplier = _getPriceMultiplier(chainIds[i]);

            uint256 amountDeployer = 10000000 * multiplier * 1e18;
            uint256 amountUSER = 1000 * multiplier * 1e18;

            vm.deal(deployer, amountDeployer);

            vm.deal(users[0], amountUSER);
            vm.deal(users[1], amountUSER);
            vm.deal(users[2], amountUSER);
        }
    }

    function _getPriceMultiplier(uint64 targetChainId_) internal returns (uint256) {
        uint256 multiplier;

        if (targetChainId_ == ETH || targetChainId_ == ARBI || targetChainId_ == OP) {
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

    function _getLatestPrice(address priceFeed_) internal view returns (int256) {
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

        address[] memory toMailboxes = new address[](6);
        uint32[] memory expDstDomains = new uint32[](6);

        address[] memory endpoints = new address[](6);
        uint16[] memory lzChainIds = new uint16[](6);

        uint256[] memory forkIds = new uint256[](6);

        uint256 j;
        for (uint256 i = 0; i < chainIds.length; i++) {
            toMailboxes[j] = hyperlaneMailboxes[i];
            expDstDomains[j] = hyperlane_chainIds[i];

            endpoints[j] = lzEndpoints[i];
            lzChainIds[j] = lz_chainIds[i];

            forkIds[j] = FORKS[chainIds[i]];

            j++;
        }

        HyperlaneHelper(getContract(currentChainId, "HyperlaneHelper")).help(
            address(HyperlaneMailbox),
            toMailboxes,
            expDstDomains,
            forkIds,
            logs
        );

        LayerZeroHelper(getContract(currentChainId, "LayerZeroHelper")).help(
            endpoints,
            lzChainIds,
            1000000, /// (change to 2000000) @dev This is the gas value to send - value needs to be tested and probably be lower
            forkIds,
            logs
        );

        vm.startPrank(deployer);
    }

    /// @dev will sync the broadcasted factory payloads
    function _processFactoryPayloads(uint256 superFormsToProcess_) private {
        for (uint256 j = 0; j < chainIds.length; j++) {
            vm.selectFork(FORKS[chainIds[j]]);
            for (uint256 k = 1; k < superFormsToProcess_; k++) {
                FactoryStateRegistry(payable(getContract(chainIds[j], "FactoryStateRegistry"))).processPayload(k, "");
            }
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

    function _randomBytes32() internal view returns (bytes32) {
        return
            keccak256(
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
    ) internal returns (bytes memory sig) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, _getEIP712Hash(permit, spender, chainId));
        return abi.encodePacked(r, s, v);
    }

    // Compute the EIP712 hash of the permit object.
    // Normally this would be implemented off-chain.
    function _getEIP712Hash(
        IPermit2.PermitTransferFrom memory permit,
        address spender,
        uint64 chainId
    ) internal view returns (bytes32 h) {
        return
            keccak256(
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
    function getAddress(bytes memory bytecode_, uint salt_) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt_, keccak256(bytecode_)));

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }
}

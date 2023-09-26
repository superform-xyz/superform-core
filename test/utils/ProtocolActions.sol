/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "./BaseSetup.sol";
import { IPermit2 } from "src/vendor/dragonfly-xyz/IPermit2.sol";
import { ILiFi } from "src/vendor/lifi/ILiFi.sol";
import { LibSwap } from "src/vendor/lifi/LibSwap.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { LiFiMock } from "../mocks/LiFiMock.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { ITimelockStateRegistry } from "src/interfaces/ITimelockStateRegistry.sol";
import { IERC1155A } from "ERC1155A/interfaces/IERC1155A.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { Error } from "src/utils/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";

abstract contract ProtocolActions is BaseSetup {
    using DataLib for uint256;

    /// out of 10000
    int256 totalSlippage = 200;

    event FailedXChainDeposits(uint256 indexed payloadId);

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
    uint256 public dstValue;

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

    /// @dev percentage of total slippage that is used for dstSwap
    uint256 MULTI_TX_SLIPPAGE_SHARE;

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

    /// @dev if the action is a partial withdraw (has no effect for deposits) - important for assertions
    mapping(uint64 chainId => mapping(uint256 index => bool[] partials)) public PARTIAL;

    /// @dev holds txData for destination updates
    mapping(uint64 chainId => bytes[] generatedTxData) public TX_DATA_TO_UPDATE_ON_DST;

    mapping(uint64 chainId => mapping(uint256 index => uint8[] liqBridgeId)) public LIQ_BRIDGES;

    mapping(uint64 chainId => uint64[] liqDstChainId) public FINAL_LIQ_DST_WITHDRAW;

    mapping(uint64 chainId => mapping(uint256 index => TestType testType)) public TEST_TYPE_PER_DST;

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
        /// and similarly for USDT, WETH and ETH
        if (action.externalToken == 3) {
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
        for (uint256 i = 0; i < chainIds.length; i++) {
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
        for (uint256 i = 0; i < vars.nDestinations; i++) {
            for (uint256 j = 0; j < chainIds.length; j++) {
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
                vars.vaultMock,
                vars.partialWithdrawVaults
            ) = _targetVaults(CHAIN_0, DST_CHAINS[i], actionIndex, i);

            vars.toDst = new address[](vars.targetSuperformIds.length);

            /// @dev action is sameChain, if there is a liquidity swap it should go to the same form. In adition, in
            /// this case, if action is cross chain withdraw, user can select to receive a different kind of underlying
            /// from source
            /// @dev if action is cross-chain deposit, destination for liquidity is coreStateRegistry
            for (uint256 k = 0; k < vars.targetSuperformIds.length; k++) {
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

            vars.liqBridges = LIQ_BRIDGES[DST_CHAINS[i]][actionIndex];

            if (action.multiVaults) {
                multiSuperformsData[i] = _buildMultiVaultCallData(
                    MultiVaultCallDataArgs(
                        action.user,
                        vars.fromSrc,
                        action.externalToken == 3
                            ? NATIVE_TOKEN
                            : getContract(CHAIN_0, UNDERLYING_TOKENS[action.externalToken]),
                        vars.toDst,
                        vars.underlyingSrcToken,
                        vars.underlyingDstToken,
                        vars.targetSuperformIds,
                        vars.amounts,
                        vars.liqBridges,
                        MAX_SLIPPAGE,
                        vars.vaultMock,
                        CHAIN_0,
                        DST_CHAINS[i],
                        uint256(chainIds[vars.chain0Index]),
                        i,
                        vars.chainDstIndex,
                        action.dstSwap,
                        action.action,
                        action.slippage,
                        vars.partialWithdrawVaults
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
                    action.externalToken == 3
                        ? NATIVE_TOKEN
                        : getContract(CHAIN_0, UNDERLYING_TOKENS[action.externalToken]),
                    vars.toDst[0],
                    vars.underlyingSrcToken[0],
                    vars.underlyingDstToken[0],
                    vars.targetSuperformIds[0],
                    finalAmount,
                    vars.liqBridges[0],
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
                    vars.partialWithdrawVaults.length > 0 ? vars.partialWithdrawVaults[0] : false,
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
                    (,, dstValue, msgValue) = CHAIN_0 != DST_CHAINS[0]
                        ? paymentHelper.estimateSingleXChainMultiVault(vars.singleDstMultiVaultStateReq, true)
                        : paymentHelper.estimateSingleDirectMultiVault(
                            SingleDirectMultiVaultStateReq(multiSuperformsData[0]), true
                        );

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
                    (,, dstValue, msgValue) = CHAIN_0 != DST_CHAINS[0]
                        ? paymentHelper.estimateSingleXChainMultiVault(vars.singleDstMultiVaultStateReq, false)
                        : paymentHelper.estimateSingleDirectMultiVault(
                            SingleDirectMultiVaultStateReq(multiSuperformsData[0]), false
                        );

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

                    (,, dstValue, msgValue) =
                        paymentHelper.estimateMultiDstMultiVault(vars.multiDstMultiVaultStateReq, true);
                    vm.prank(users[action.user]);

                    if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                        vm.expectRevert();
                    }

                    /// @dev the actual call to the entry point
                    superformRouter.multiDstMultiVaultDeposit{ value: msgValue }(vars.multiDstMultiVaultStateReq);
                } else if (action.action == Actions.Withdraw) {
                    /// @dev payment estimation, differs according to the type of entry point used

                    (,, dstValue, msgValue) =
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

                        (,, dstValue, msgValue) =
                            paymentHelper.estimateSingleXChainSingleVault(vars.singleXChainSingleVaultStateReq, true);
                        vm.prank(users[action.user]);

                        if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                            vm.expectRevert();
                        }
                        /// @dev the actual call to the entry point

                        superformRouter.singleXChainSingleVaultDeposit{ value: msgValue }(
                            vars.singleXChainSingleVaultStateReq
                        );
                    } else if (action.action == Actions.Withdraw) {
                        /// @dev payment estimation, differs according to the type of entry point used

                        (,, dstValue, msgValue) =
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

                        (,, dstValue, msgValue) =
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

                        (,, dstValue, msgValue) =
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
                    (,, dstValue, msgValue) =
                        paymentHelper.estimateMultiDstSingleVault(vars.multiDstSingleVaultStateReq, true);
                    vm.prank(users[action.user]);

                    if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                        vm.expectRevert();
                    }
                    /// @dev the actual call to the entry point

                    superformRouter.multiDstSingleVaultDeposit{ value: msgValue }(vars.multiDstSingleVaultStateReq);
                } else if (action.action == Actions.Withdraw) {
                    /// @dev payment estimation, differs according to the type of entry point used

                    (,, dstValue, msgValue) =
                        paymentHelper.estimateMultiDstSingleVault(vars.multiDstSingleVaultStateReq, true);
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
        uint16[] lzChainIds;
        address[] wormholeRelayers;
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
        returns (MessagingAssertVars[] memory)
    {
        Stage3InternalVars memory internalVars;

        for (uint256 i = 0; i < vars.nDestinations; i++) {
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
        internalVars.lzChainIds = new uint16[](vars.nUniqueDsts);

        internalVars.wormholeRelayers = new address[](vars.nUniqueDsts);
        internalVars.expDstChainAddresses = new address[](vars.nUniqueDsts);

        internalVars.forkIds = new uint256[](vars.nUniqueDsts);

        internalVars.k = 0;
        for (uint256 i = 0; i < chainIds.length; i++) {
            for (uint256 j = 0; j < vars.nUniqueDsts; j++) {
                if (uniqueDSTs[j] == chainIds[i] && chainIds[i] != CHAIN_0) {
                    internalVars.toMailboxes[internalVars.k] = hyperlaneMailboxes[i];
                    internalVars.expDstDomains[internalVars.k] = hyperlane_chainIds[i];

                    internalVars.endpoints[internalVars.k] = lzEndpoints[i];
                    internalVars.lzChainIds[internalVars.k] = lz_chainIds[i];

                    internalVars.forkIds[internalVars.k] = FORKS[chainIds[i]];

                    internalVars.wormholeRelayers[internalVars.k] = wormholeRelayer;
                    internalVars.expDstChainAddresses[internalVars.k] =
                        getContract(chainIds[i], "WormholeARImplementation");

                    internalVars.k++;
                }
            }
        }
        delete uniqueDSTs;
        vars.logs = vm.getRecordedLogs();

        for (uint256 index; index < AMBs.length; index++) {
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

            if (AMBs[index] == 2) {
                /// @dev see pigeon for this implementation
                HyperlaneHelper(getContract(CHAIN_0, "HyperlaneHelper")).help(
                    address(HyperlaneMailbox),
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
        }

        MessagingAssertVars[] memory aV = new MessagingAssertVars[](
            vars.nDestinations
        );

        CoreStateRegistry stateRegistry;
        /// @dev assert good delivery of message on destination by analyzing superformIds and mounts
        for (uint256 i = 0; i < vars.nDestinations; i++) {
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
            for (uint256 i = 0; i < vars.nDestinations; i++) {
                aV[i].toChainId = DST_CHAINS[i];
                if (CHAIN_0 != aV[i].toChainId) {
                    vm.selectFork(FORKS[aV[i].toChainId]);

                    if (action.action == Actions.Deposit || action.action == Actions.DepositPermit2) {
                        unchecked {
                            PAYLOAD_ID[aV[i].toChainId]++;
                        }

                        vars.multiVaultsPayloadArg = updateMultiVaultDepositPayloadArgs(
                            PAYLOAD_ID[aV[i].toChainId],
                            aV[i].receivedMultiVaultData.amounts,
                            action.slippage,
                            aV[i].toChainId,
                            action.testType,
                            action.revertError,
                            action.revertRole,
                            action.dstSwap
                        );

                        vars.singleVaultsPayloadArg = updateSingleVaultDepositPayloadArgs(
                            PAYLOAD_ID[aV[i].toChainId],
                            aV[i].receivedSingleVaultData.amount,
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
                                (,, vars.underlyingDstToken,,) = _targetVaults(CHAIN_0, DST_CHAINS[i], actionIndex, i);
                                vars.liqBridges = LIQ_BRIDGES[DST_CHAINS[i]][actionIndex];

                                /// @dev dst swap is performed to ensure tokens reach CoreStateRegistry on deposits
                                if (action.multiVaults) {
                                    vars.amounts = AMOUNTS[DST_CHAINS[i]][actionIndex];
                                    _batchProcessDstSwap(
                                        vars.liqBridges,
                                        CHAIN_0,
                                        aV[i].toChainId,
                                        vars.underlyingDstToken,
                                        vars.amounts,
                                        action.slippage
                                    );
                                } else {
                                    _processDstSwap(
                                        vars.liqBridges[0],
                                        CHAIN_0,
                                        aV[i].toChainId,
                                        vars.underlyingDstToken[0],
                                        singleSuperformsData[i].amount,
                                        action.slippage
                                    );
                                }
                            }

                            /// @dev this is the step where the amounts are updated taking into account the final
                            /// slippage
                            if (action.multiVaults) {
                                _updateMultiVaultDepositPayload(vars.multiVaultsPayloadArg);
                            } else if (singleSuperformsData.length > 0) {
                                _updateSingleVaultDepositPayload(vars.singleVaultsPayloadArg);
                            }
                            console.log("grabbing logs");

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
                                _updateMultiVaultDepositPayload(vars.multiVaultsPayloadArg);
                            } else if (singleSuperformsData.length > 0) {
                                _updateSingleVaultDepositPayload(vars.singleVaultsPayloadArg);
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
                                success = _updateMultiVaultDepositPayload(vars.multiVaultsPayloadArg);
                            } else {
                                success = _updateSingleVaultDepositPayload(vars.singleVaultsPayloadArg);
                            }

                            if (!success) {
                                return success;
                            }
                        }
                    } else if (
                        action.action == Actions.Withdraw
                            && (action.testType == TestType.Pass || action.testType == TestType.RevertVaultsWithdraw)
                    ) {
                        unchecked {
                            PAYLOAD_ID[aV[i].toChainId]++;
                        }

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
                        console.log("grabbing logs");

                        vm.recordLogs();

                        /// @dev payload processing. This performs the action down to the form level and builds any
                        /// acknowledgement data needed to bring it back to source
                        /// @dev hence the record logs before and after and payload delivery to source
                        success = _processPayload(PAYLOAD_ID[aV[i].toChainId], aV[i].toChainId, action.testType);
                        vars.logs = vm.getRecordedLogs();

                        _payloadDeliveryHelper(CHAIN_0, aV[i].toChainId, vars.logs);
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

        console.log("stage5");
        vm.selectFork(FORKS[CHAIN_0]);

        uint256 toChainId;
        for (uint256 i = 0; i < vars.nDestinations; i++) {
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
                    unchecked {
                        PAYLOAD_ID[CHAIN_0]++;
                    }

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

        for (uint256 i = 0; i < vars.nDestinations; i++) {
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
                    unchecked {
                        PAYLOAD_ID[CHAIN_0]++;
                    }

                    _processPayload(PAYLOAD_ID[CHAIN_0], CHAIN_0, action.testType);
                }
            }
        }
    }

    /// @dev STEP 7 DIRECT AND X-CHAIN: Finalize timelocked payload after time has passed
    function _stage7_finalize_timelocked_payload(StagesLocalVars memory vars) internal {
        uint256 initialFork;
        uint256 currentUnlockId;

        for (uint256 i = 0; i < vars.nDestinations; i++) {
            if (countTimelocked[i] > 0) {
                initialFork = vm.activeFork();

                vm.selectFork(FORKS[DST_CHAINS[i]]);

                ITimelockStateRegistry twoStepsFormStateRegistry =
                    ITimelockStateRegistry(contracts[DST_CHAINS[i]][bytes32(bytes("TimelockStateRegistry"))]);

                currentUnlockId = twoStepsFormStateRegistry.timelockPayloadCounter();
                if (currentUnlockId > 0) {
                    vm.recordLogs();

                    /// @dev performs unlock before the time ends
                    for (uint256 j = countTimelocked[i]; j > 0; j--) {
                        (uint256 nativeFee,) = _generateAckGasFeesAndParamsForTimeLock(
                            abi.encode(CHAIN_0, DST_CHAINS[i]), AMBs, currentUnlockId - j + 1
                        );

                        vm.prank(deployer);
                        /// @dev tries to process the payload during lock-in period
                        vm.expectRevert(Error.LOCKED.selector);
                        twoStepsFormStateRegistry.finalizePayload{ value: nativeFee }(
                            currentUnlockId - j + 1,
                            GENERATE_WITHDRAW_TX_DATA_ON_DST
                                ? TX_DATA_TO_UPDATE_ON_DST[DST_CHAINS[i]][timeLockedIndexes[DST_CHAINS[i]][j]]
                                : bytes("")
                        );
                    }

                    /// @dev perform the calls from beginning to last because of easiness in passing unlock id
                    for (uint256 j = countTimelocked[i]; j > 0; j--) {
                        (uint256 nativeFee,) = _generateAckGasFeesAndParamsForTimeLock(
                            abi.encode(CHAIN_0, DST_CHAINS[i]), AMBs, currentUnlockId - j + 1
                        );

                        /// @dev increase time by 5 days
                        vm.warp(block.timestamp + (86_400 * 5));
                        vm.prank(deployer);

                        /// @dev if needed in certain test scenarios, re-feed txData for timelocked here
                        twoStepsFormStateRegistry.finalizePayload{ value: nativeFee }(
                            currentUnlockId - j + 1,
                            GENERATE_WITHDRAW_TX_DATA_ON_DST
                                ? TX_DATA_TO_UPDATE_ON_DST[DST_CHAINS[i]][timeLockedIndexes[DST_CHAINS[i]][j]]
                                : bytes("")
                        );

                        /// @dev tries to process already finalized payload
                        vm.prank(deployer);
                        vm.expectRevert(Error.INVALID_PAYLOAD_STATUS.selector);
                        twoStepsFormStateRegistry.finalizePayload{ value: nativeFee }(
                            currentUnlockId - j + 1,
                            GENERATE_WITHDRAW_TX_DATA_ON_DST
                                ? TX_DATA_TO_UPDATE_ON_DST[DST_CHAINS[i]][timeLockedIndexes[DST_CHAINS[i]][j]]
                                : bytes("")
                        );
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

        for (uint256 i = 0; i < vars.nDestinations; i++) {
            if (CHAIN_0 != DST_CHAINS[i] && revertingWithdrawTimelockedSFs[i].length > 0) {
                IBaseStateRegistry twoStepsFormStateRegistry =
                    IBaseStateRegistry(contracts[CHAIN_0][bytes32(bytes("TimelockStateRegistry"))]);

                /// @dev if a payload exists to be processed, process it
                if (_payload(address(twoStepsFormStateRegistry), CHAIN_0, TWO_STEP_PAYLOAD_ID[CHAIN_0] + 1).length > 0)
                {
                    unchecked {
                        TWO_STEP_PAYLOAD_ID[CHAIN_0]++;
                    }

                    (address srcSender, uint64 srcChainId,,,) = PayloadHelper(getContract(CHAIN_0, "PayloadHelper"))
                        .decodeTimeLockFailedPayload(TWO_STEP_PAYLOAD_ID[CHAIN_0]);

                    assertEq(srcChainId, DST_CHAINS[i]);
                    assertEq(srcSender, users[action.user]);

                    success = _processTwoStepPayload(
                        TWO_STEP_PAYLOAD_ID[CHAIN_0], DST_CHAINS[i], CHAIN_0, action.testType, action.revertError
                    );
                }
            }
        }
    }

    /// @dev 'n' deposits rescued per payloadId per destination chain
    /// @dev TODO - Smit to add better comments
    function _rescueFailedDeposits(TestAction memory action, uint256 actionIndex) internal {
        if (action.action == Actions.RescueFailedDeposit && action.testType == TestType.Pass) {
            /// @dev currently testing rescuing deposits with dstSwap false
            MULTI_TX_SLIPPAGE_SHARE = 0;

            vm.selectFork(FORKS[DST_CHAINS[0]]);
            uint256 userWethBalanceBefore =
                MockERC20(getContract(DST_CHAINS[0], UNDERLYING_TOKENS[2])).balanceOf(users[0]);
            address payable coreStateRegistryDst = payable(getContract(DST_CHAINS[0], "CoreStateRegistry"));

            uint256[] memory rescueSuperformIds;
            (rescueSuperformIds,) = CoreStateRegistry(coreStateRegistryDst).getFailedDeposits(PAYLOAD_ID[DST_CHAINS[0]]);

            uint256[] memory amounts = new uint256[](rescueSuperformIds.length);

            uint256 stuckAmount;
            /// @dev simulating slippage from bridges
            for (uint256 i; i < AMOUNTS[DST_CHAINS[0]][actionIndex].length; ++i) {
                /// @dev this is the amount that is stuck in CoreStateRegistry
                stuckAmount += (AMOUNTS[DST_CHAINS[0]][actionIndex][i] * (10_000 - uint256(action.slippage))) / 10_000;
            }

            for (uint256 i = 0; i < rescueSuperformIds.length; ++i) {
                /// @dev slippage adjusted amount that'll be withdrawn i.e. amount stuck in CoreStateRegistry
                amounts[i] = (AMOUNTS[DST_CHAINS[0]][actionIndex][i] * (10_000 - uint256(action.slippage))) / 10_000;
            }

            vm.prank(deployer);
            vm.expectRevert(Error.INVALID_RESCUE_DATA.selector);
            CoreStateRegistry(coreStateRegistryDst).proposeRescueFailedDeposits(
                PAYLOAD_ID[DST_CHAINS[0]], new uint256[](0)
            );

            vm.prank(deployer);

            CoreStateRegistry(coreStateRegistryDst).proposeRescueFailedDeposits(PAYLOAD_ID[DST_CHAINS[0]], amounts);

            vm.warp(block.timestamp + 12 hours);
            CoreStateRegistry(coreStateRegistryDst).finalizeRescueFailedDeposits(PAYLOAD_ID[DST_CHAINS[0]]);

            uint256 userWethBalanceAfter =
                MockERC20(getContract(DST_CHAINS[0], UNDERLYING_TOKENS[2])).balanceOf(users[0]);
            assertEq(userWethBalanceAfter, userWethBalanceBefore + stuckAmount);
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
        for (uint256 i = 0; i < len; i++) {
            finalAmounts[i] = args.amounts[i];

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
                args.superformIds[i],
                finalAmounts[i],
                args.liqBridges[i],
                args.maxSlippage,
                args.vaultMock[i],
                args.srcChainId,
                args.toChainId,
                liqDstChainId,
                args.liquidityBridgeSrcChainId,
                uint256(args.toChainId),
                args.dstSwap,
                args.partialWithdrawVaults.length > 0 ? args.partialWithdrawVaults[i] : false,
                args.slippage
            );
            if (args.action == Actions.Deposit || args.action == Actions.DepositPermit2) {
                superformData = _buildSingleVaultDepositCallData(callDataArgs, args.action);
            } else if (args.action == Actions.Withdraw) {
                superformData = _buildSingleVaultWithdrawCallData(callDataArgs);
            }
            liqRequests[i] = superformData.liqRequest;
            maxSlippageTemp[i] = args.maxSlippage;
            v.totalAmount += finalAmounts[i];
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
            for (uint256 i; i < hasDstSwap.length; i++) {
                hasDstSwap[i] = true;
            }
        }

        superformsData = MultiVaultSFData(
            args.superformIds,
            finalAmounts,
            maxSlippageTemp,
            hasDstSwap,
            liqRequests,
            v.permit2data,
            users[args.user],
            abi.encode(args.partialWithdrawVaults)
        );
    }

    struct LiqBridgeTxDataArgs {
        uint256 liqBridgeKind;
        address externalToken; // this is underlyingTokenDst for withdraws
        address underlyingToken;
        address underlyingTokenDst; // this is external token (to receive in the end) for withdraws
        address from;
        uint64 srcChainId;
        uint64 toChainId;
        uint64 liqDstChainId;
        bool dstSwap;
        address toDst;
        uint256 liqBridgeToChainId;
        uint256 amount;
        bool withdraw;
        int256 slippage;
    }

    function _buildLiqBridgeTxData(
        LiqBridgeTxDataArgs memory args,
        bool sameChain
    )
        internal
        view
        returns (bytes memory txData)
    {
        if (args.liqBridgeKind == 1) {
            if (!sameChain) {
                ILiFi.BridgeData memory bridgeData;
                LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);

                swapData[0] = LibSwap.SwapData(
                    address(0),
                    /// @dev  callTo (arbitrary)
                    address(0),
                    /// @dev  callTo (approveTo)
                    args.externalToken,
                    args.withdraw ? args.externalToken : args.underlyingToken,
                    /// @dev initial token to extract will be externalToken in args, which is the actual
                    /// underlyingTokenDst
                    /// for withdraws (check how the call is made in _buildSingleVaultWithdrawCallData )
                    args.amount,
                    abi.encode(
                        args.from,
                        FORKS[args.liqDstChainId],
                        args.underlyingTokenDst,
                        args.slippage,
                        false,
                        MULTI_TX_SLIPPAGE_SHARE,
                        args.srcChainId == args.toChainId
                    ),
                    /// @dev this bytes param is used for testing purposes only and easiness of mocking, does not
                    /// resemble
                    /// mainnet
                    false
                );
                /// @dev  arbitrary

                if (args.externalToken != args.underlyingToken) {
                    bridgeData = ILiFi.BridgeData(
                        bytes32("1"),
                        /// @dev request id, arbitrary number
                        "",
                        /// @dev unused in tests
                        "",
                        /// @dev unused in tests
                        address(0),
                        /// @dev unused in tests
                        args.withdraw ? args.externalToken : args.underlyingToken,
                        /// @dev initial token to extract will be externalToken in args, which is the actual
                        /// underlyingTokenDst for withdraws (check how the call is made in
                        /// _buildSingleVaultWithdrawCallData )
                        args.dstSwap && CHAIN_0 != args.toChainId
                            ? getContract(args.toChainId, "DstSwapper")
                            : args.toDst,
                        args.amount,
                        args.liqBridgeToChainId,
                        true,
                        /// @dev if external != underlying, this is true
                        false
                    );
                    /// @dev always false for mocking purposes
                } else {
                    bridgeData = ILiFi.BridgeData(
                        bytes32("1"),
                        /// @dev request id, arbitrary number
                        "",
                        /// @dev unused in tests
                        "",
                        /// @dev unused in tests
                        address(0),
                        args.withdraw ? args.externalToken : args.underlyingToken,
                        /// @dev initial token to extract will be externalToken in args, which is the actual
                        /// underlyingTokenDst for withdraws (check how the call is made in
                        /// _buildSingleVaultWithdrawCallData )
                        args.dstSwap && CHAIN_0 != args.toChainId
                            ? getContract(args.toChainId, "DstSwapper")
                            : args.toDst,
                        args.amount,
                        args.liqBridgeToChainId,
                        false,
                        false
                    );
                    /// @dev always false for mocking purposes
                }

                txData =
                    abi.encodeWithSelector(LiFiMock.swapAndStartBridgeTokensViaBridge.selector, bridgeData, swapData);
            } else {
                LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);

                swapData[0] = LibSwap.SwapData(
                    address(0),
                    /// @dev  callTo (arbitrary)
                    address(0),
                    /// @dev  callTo (approveTo)
                    args.externalToken,
                    args.withdraw ? args.externalToken : args.underlyingToken,
                    /// @dev initial token to extract will be externalToken in args, which is the actual
                    /// underlyingTokenDst
                    /// for withdraws (check how the call is made in _buildSingleVaultWithdrawCallData )
                    args.amount,
                    abi.encode(
                        args.from,
                        FORKS[args.liqDstChainId],
                        args.underlyingTokenDst,
                        args.slippage,
                        false,
                        MULTI_TX_SLIPPAGE_SHARE,
                        args.srcChainId == args.toChainId
                    ),
                    /// @dev this bytes param is used for testing purposes only and easiness of mocking, does not
                    /// resemble
                    /// mainnet
                    false
                );

                txData = abi.encodeWithSelector(
                    LiFiMock.swapTokensGeneric.selector, bytes32(0), "", "", args.toDst, 0, swapData
                );
            }
        }
    }

    function _buildLiqBridgeTxDataDstSwap(
        uint8 liqBridgeKind_,
        address sendingTokenDst_,
        address receivingTokenDst_,
        address from_,
        uint64 toChainId_,
        uint256 amount_,
        int256 slippage_
    )
        internal
        view
        returns (bytes memory txData)
    {
        /// @dev amount_ adjusted after bridge slippage
        amount_ = (amount_ * uint256(10_000 - slippage_)) / 10_000;

        /// @dev amount_ adjusted after swap slippage
        int256 swapSlippage = (slippage_ * int256(MULTI_TX_SLIPPAGE_SHARE)) / 100;
        amount_ = (amount_ * uint256(10_000 - swapSlippage)) / 10_000;

        if (liqBridgeKind_ == 1) {
            /// @dev for lifi
            LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);

            swapData[0] = LibSwap.SwapData(
                address(0),
                ///  @dev  callTo (arbitrary)
                address(0),
                ///  @dev  callTo (approveTo)
                sendingTokenDst_,
                /// @dev in dst swap, assumes a swap between same token - FIXME
                receivingTokenDst_,
                /// @dev in dst swap, assumes a swap between same token - FIXME
                amount_,
                /// @dev _buildLiqBridgeTxDataMultiTx() will only be called when multiTx is true
                /// @dev and multiTx means cross-chain (last arg)
                abi.encode(
                    from_, FORKS[toChainId_], receivingTokenDst_, slippage_, true, MULTI_TX_SLIPPAGE_SHARE, false
                ),
                false // arbitrary
            );

            txData = abi.encodeWithSelector(
                LiFiMock.swapTokensGeneric.selector,
                bytes32(0),
                "",
                "",
                getContract(toChainId_, "CoreStateRegistry"),
                0,
                swapData
            );
        }
    }

    function _buildDummyTxDataUnitTests(
        uint8 liqBridgeKind_,
        address underlyingToken_,
        address underlyingTokenDst_,
        address from_,
        uint64 toChainId_,
        uint256 amount_,
        address receiver_,
        bool sameChain_
    )
        internal
        view
        returns (bytes memory txData)
    {
        if (liqBridgeKind_ == 1) {
            if (!sameChain_) {
                ILiFi.BridgeData memory bridgeData;
                LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);

                swapData[0] = LibSwap.SwapData(
                    address(0),
                    /// callTo (arbitrary)
                    address(0),
                    /// callTo (approveTo)
                    underlyingToken_,
                    underlyingToken_,
                    amount_,
                    abi.encode(from_, FORKS[toChainId_], underlyingTokenDst_, totalSlippage, false, 0, false),
                    false // arbitrary
                );

                bridgeData = ILiFi.BridgeData(
                    bytes32("1"),
                    /// request id
                    "",
                    "",
                    address(0),
                    underlyingToken_,
                    receiver_,
                    amount_,
                    uint256(toChainId_),
                    false,
                    false
                );

                txData =
                    abi.encodeWithSelector(LiFiMock.swapAndStartBridgeTokensViaBridge.selector, bridgeData, swapData);
            } else {
                LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);

                swapData[0] = LibSwap.SwapData(
                    address(0),
                    /// callTo (arbitrary)
                    address(0),
                    /// callTo (approveTo)
                    underlyingToken_,
                    underlyingToken_,
                    amount_,
                    abi.encode(from_, FORKS[toChainId_], underlyingTokenDst_, totalSlippage, false, 0, false),
                    false // arbitrary
                );

                txData = abi.encodeWithSelector(
                    LiFiMock.swapTokensGeneric.selector, bytes32(0), "", "", receiver_, 0, swapData
                );
            }
        }
    }

    struct SingleVaultDepositLocalVars {
        uint256 initialFork;
        address from;
        IPermit2.PermitTransferFrom permit;
        bytes txData;
        bytes sig;
        bytes permit2Calldata;
        LiqRequest liqReq;
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

        if (args.srcChainId == args.toChainId) {
            /// @dev same chain deposit, from is superform (which is inscribed in toDst in the beginning of stage 1)
            v.from = args.toDst;
        }

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            args.liqBridge,
            args.externalToken,
            args.underlyingToken,
            args.underlyingTokenDst,
            v.from,
            args.srcChainId,
            args.toChainId,
            args.toChainId,
            args.dstSwap,
            args.toDst,
            args.liquidityBridgeToChainId,
            args.amount,
            false,
            args.slippage
        );

        v.txData = _buildLiqBridgeTxData(liqBridgeTxDataArgs, args.srcChainId == args.toChainId);

        /// @dev to also inscribe the token address in the Struct
        address liqRequestToken = args.externalToken != args.underlyingToken ? args.externalToken : args.underlyingToken;

        /// @dev build permit2 calldata
        vm.selectFork(FORKS[args.srcChainId]);
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
            args.liqBridge, v.txData, liqRequestToken, args.toChainId, liqRequestToken == NATIVE_TOKEN ? args.amount : 0
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
        vm.selectFork(v.initialFork);

        /// @dev extraData is unused here so false is encoded (it is currently used to send in the partialWithdraw
        /// vaults without resorting to extra args, just for withdraws)
        superformData = SingleVaultSFData(
            args.superformId,
            args.amount,
            args.maxSlippage,
            args.dstSwap,
            v.liqReq,
            v.permit2Calldata,
            users[args.user],
            abi.encode(false)
        );
    }

    struct SingleVaultWithdrawLocalVars {
        address superformRouter;
        address stateRegistry;
        IERC1155A superPositions;
        bytes txData;
        LiqRequest liqReq;
        address superform;
        uint256 actualWithdrawAmount;
    }

    function _buildSingleVaultWithdrawCallData(SingleVaultCallDataArgs memory args)
        internal
        returns (SingleVaultSFData memory superformData)
    {
        SingleVaultWithdrawLocalVars memory vars;

        uint256 initialFork = vm.activeFork();
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
            args.slippage
        );

        vars.txData = _buildLiqBridgeTxData(liqBridgeTxDataArgs, args.toChainId == args.liqDstChainId);

        /// @dev push all txData to this state var to re-feed in certain test cases
        if (GENERATE_WITHDRAW_TX_DATA_ON_DST) {
            TX_DATA_TO_UPDATE_ON_DST[args.toChainId].push(vars.txData);
        }

        vars.liqReq = LiqRequest(
            args.liqBridge,
            GENERATE_WITHDRAW_TX_DATA_ON_DST ? bytes("") : vars.txData,
            /// @dev for certain test cases, insert txData as null here
            args.underlyingTokenDst,
            args.liqDstChainId,
            0
        );

        /// @dev extraData is currently used to send in the partialWithdraw vaults without resorting to extra args, just
        /// for withdraws
        superformData = SingleVaultSFData(
            args.superformId,
            args.amount,
            args.maxSlippage,
            args.dstSwap,
            vars.liqReq,
            "",
            users[args.user],
            abi.encode(args.partialWithdrawVault)
        );
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
            address[] memory vaultMocksMem,
            bool[] memory partialWithdrawVaults
        )
    {
        TargetVaultsVars memory vars;
        vars.underlyingTokens = TARGET_UNDERLYINGS[chain1][action];
        vars.vaultIds = TARGET_VAULTS[chain1][action];
        vars.formKinds = TARGET_FORM_KINDS[chain1][action];

        partialWithdrawVaults = PARTIAL[chain1][action];

        /// @dev constructs superFormIds from provided input info
        vars.superformIdsTemp = _superformIds(vars.underlyingTokens, vars.vaultIds, vars.formKinds, chain1);

        vars.len = vars.superformIdsTemp.length;

        if (vars.len == 0) revert LEN_VAULTS_ZERO();

        targetSuperformsMem = new uint256[](vars.len);
        underlyingSrcTokensMem = new address[](vars.len);
        underlyingDstTokensMem = new address[](vars.len);
        vaultMocksMem = new address[](vars.len);

        /// @dev this loop assigns the information in the correct output arrays the best way possible
        for (uint256 i = 0; i < vars.len; i++) {
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
        for (uint256 j; j < vars.formKinds.length; j++) {
            if (vars.formKinds[j] == 1) ++countTimelocked[dst];
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
        for (uint256 i = 0; i < vaultIds_.length; i++) {
            address superform = getContract(
                chainId_,
                string.concat(
                    UNDERLYING_TOKENS[underlyingTokens_[i]],
                    VAULT_KINDS[vaultIds_[i]],
                    "Superform",
                    Strings.toString(FORM_BEACON_IDS[formKinds_[i]])
                )
            );

            /// @dev superformids are built here
            superformIds_[i] = DataLib.packSuperform(superform, FORM_BEACON_IDS[formKinds_[i]], chainId_);
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

        for (uint256 i = 0; i < superformIds.length; i++) {
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
        uint256[] memory superPositionBalances = new uint256[] (superformIds.length);
        previewRedeemAmounts = new uint256[] (superformIds.length);
        address superRegistryAddress = getContract(CHAIN_0, "SuperRegistry");

        address superPositionsAddress =
            ISuperRegistry(superRegistryAddress).getAddress(ISuperRegistry(superRegistryAddress).SUPER_POSITIONS());

        IERC1155A superPositions = IERC1155A(superPositionsAddress);

        for (uint256 i = 0; i < superformIds.length; i++) {
            vm.selectFork(FORKS[CHAIN_0]);
            uint256 nRepetitions;

            for (uint256 j = 0; j < superformIds.length; j++) {
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

    function _updateMultiVaultDepositPayload(updateMultiVaultDepositPayloadArgs memory args) internal returns (bool) {
        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[args.targetChainId]);
        uint256 len = args.amounts.length;
        uint256[] memory finalAmounts = new uint256[](len);

        int256 dstSwapSlippage;

        /// @dev slippage calculation
        for (uint256 i = 0; i < len; i++) {
            finalAmounts[i] = args.amounts[i];
            if (args.slippage > 0) {
                finalAmounts[i] = (finalAmounts[i] * uint256(10_000 - args.slippage)) / 10_000;

                if (args.isdstSwap) {
                    dstSwapSlippage = (args.slippage * int256(MULTI_TX_SLIPPAGE_SHARE)) / 100;
                    finalAmounts[i] = (finalAmounts[i] * uint256(10_000 - dstSwapSlippage)) / 10_000;
                }
            }
        }

        /// @dev if test type is RevertProcessPayload, revert is further down the call chain
        if (args.testType == TestType.Pass || args.testType == TestType.RevertProcessPayload) {
            vm.prank(deployer);
            CoreStateRegistry(payable(getContract(args.targetChainId, "CoreStateRegistry"))).updateDepositPayload(
                args.payloadId, finalAmounts
            );

            /// @dev if scenario is meant to revert here (e.g invalid slippage)
        } else if (args.testType == TestType.RevertUpdateStateSlippage) {
            vm.prank(deployer);
            vm.expectRevert(args.revertError);
            /// @dev removed string here: come to this later

            CoreStateRegistry(payable(getContract(args.targetChainId, "CoreStateRegistry"))).updateDepositPayload(
                args.payloadId, finalAmounts
            );

            return false;
            /// @dev if scenario is meant to revert here (e.g invalid role)
        } else if (args.testType == TestType.RevertUpdateStateRBAC) {
            vm.prank(users[2]);
            bytes memory errorMsg = getAccessControlErrorMsg(users[2], args.revertRole);
            vm.expectRevert(errorMsg);

            CoreStateRegistry(payable(getContract(args.targetChainId, "CoreStateRegistry"))).updateDepositPayload(
                args.payloadId, finalAmounts
            );

            return false;
        }

        vm.selectFork(initialFork);

        return true;
    }

    function _updateSingleVaultDepositPayload(updateSingleVaultDepositPayloadArgs memory args)
        internal
        returns (bool)
    {
        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[args.targetChainId]);
        uint256 finalAmount;

        finalAmount = args.amount;

        int256 dstSwapSlippage;

        finalAmount = (finalAmount * uint256(10_000 - args.slippage)) / 10_000;

        if (args.isdstSwap) {
            dstSwapSlippage = (args.slippage * int256(MULTI_TX_SLIPPAGE_SHARE)) / 100;
            finalAmount = (finalAmount * uint256(10_000 - dstSwapSlippage)) / 10_000;
        }

        /// @dev if test type is RevertProcessPayload, revert is further down the call chain
        if (args.testType == TestType.Pass || args.testType == TestType.RevertProcessPayload) {
            vm.prank(deployer);

            uint256[] memory finalAmounts = new uint256[](1);
            finalAmounts[0] = finalAmount;

            CoreStateRegistry(payable(getContract(args.targetChainId, "CoreStateRegistry"))).updateDepositPayload(
                args.payloadId, finalAmounts
            );
            /// @dev if scenario is meant to revert here (e.g invalid slippage)
        } else if (args.testType == TestType.RevertUpdateStateSlippage) {
            vm.prank(deployer);

            vm.expectRevert(args.revertError);

            /// @dev removed string here: come to this later

            uint256[] memory finalAmounts = new uint256[](1);
            finalAmounts[0] = finalAmount;

            CoreStateRegistry(payable(getContract(args.targetChainId, "CoreStateRegistry"))).updateDepositPayload(
                args.payloadId, finalAmounts
            );

            return false;

            /// @dev if scenario is meant to revert here (e.g invalid role)
        } else if (args.testType == TestType.RevertUpdateStateRBAC) {
            vm.prank(users[2]);
            bytes memory errorMsg = getAccessControlErrorMsg(users[2], args.revertRole);
            vm.expectRevert(errorMsg);

            uint256[] memory finalAmounts = new uint256[](1);
            finalAmounts[0] = finalAmount;

            CoreStateRegistry(payable(getContract(args.targetChainId, "CoreStateRegistry"))).updateDepositPayload(
                args.payloadId, finalAmounts
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
        bytes memory ackAmbParams;

        /// @dev only generate if acknowledgement is needed
        if (targetChainId_ != CHAIN_0) {
            (nativeFee, ackAmbParams) = _generateAckGasFeesAndParams(CHAIN_0, targetChainId_, AMBs, payloadId_);
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

    function _processTwoStepPayload(
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
        vm.expectRevert(Error.QUORUM_NOT_REACHED.selector);
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
        uint256 amount_,
        int256 slippage_
    )
        internal
    {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[targetChainId_]);

        /// @dev liqData is rebuilt here to perform to send the tokens from dstSwapProcessor to CoreStateRegistry
        bytes memory txData = _buildLiqBridgeTxDataDstSwap(
            liqBridgeKind_,
            underlyingTokenDst_,
            underlyingTokenDst_,
            getContract(targetChainId_, "DstSwapper"),
            targetChainId_,
            amount_,
            slippage_
        );

        vm.prank(deployer);

        DstSwapper(payable(getContract(targetChainId_, "DstSwapper"))).processTx(1, 0, liqBridgeKind_, txData);
        vm.selectFork(initialFork);
    }

    function _batchProcessDstSwap(
        uint8[] memory liqBridgeKinds_,
        uint64, /*srcChainId_*/
        uint64 targetChainId_,
        address[] memory underlyingTokensDst_,
        uint256[] memory amounts_,
        int256 slippage_
    )
        internal
    {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[targetChainId_]);
        bytes[] memory txDatas = new bytes[](underlyingTokensDst_.length);

        /// @dev liqData is rebuilt here to perform to send the tokens from dstSwapProcessor to CoreStateRegistry
        for (uint256 i = 0; i < underlyingTokensDst_.length; i++) {
            txDatas[i] = _buildLiqBridgeTxDataDstSwap(
                liqBridgeKinds_[i],
                underlyingTokensDst_[i],
                underlyingTokensDst_[i],
                getContract(targetChainId_, "DstSwapper"),
                targetChainId_,
                amounts_[i],
                slippage_
            );
        }

        vm.prank(deployer);

        uint256[] memory indices = new uint256[](amounts_.length);

        for (uint256 i; i < amounts_.length; i++) {
            indices[i] = i;
        }

        DstSwapper(payable(getContract(targetChainId_, "DstSwapper"))).batchProcessTx(
            1, indices, liqBridgeKinds_, txDatas
        );
        vm.selectFork(initialFork);
    }

    function _payloadDeliveryHelper(uint64 FROM_CHAIN, uint64 TO_CHAIN, Vm.Log[] memory logs) internal {
        for (uint256 i; i < AMBs.length; i++) {
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

            /// @notice ID: 2 Hyperlane
            if (AMBs[i] == 2) {
                HyperlaneHelper(getContract(TO_CHAIN, "HyperlaneHelper")).help(
                    address(HyperlaneMailbox), address(HyperlaneMailbox), FORKS[FROM_CHAIN], logs
                );
            }

            /// @notice ID: 3 Wormhole
            if (AMBs[i] == 3) {
                WormholeHelper(getContract(TO_CHAIN, "WormholeHelper")).help(
                    WORMHOLE_CHAIN_IDS[TO_CHAIN], FORKS[FROM_CHAIN], wormholeRelayer, logs
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
        for (uint256 i = 0; i < vars.nDestinations; i++) {
            if (action.multiVaults) {
                amountsToRemint = new uint256[](
                    multiSuperformsData[i].superformIds.length
                );

                for (uint256 j = 0; j < multiSuperformsData[i].superformIds.length; j++) {
                    amountsToRemint[j] = multiSuperformsData[i].amounts[j];
                    bool found = false;
                    for (uint256 k = 0; k < revertingWithdrawTimelockedSFs[i].length; k++) {
                        if (revertingWithdrawTimelockedSFs[i][k] == multiSuperformsData[i].superformIds[j]) {
                            found = true;
                            break;
                        }
                    }
                    for (uint256 k = 0; k < revertingWithdrawSFs[i].length; k++) {
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

                for (uint256 k = 0; k < revertingWithdrawTimelockedSFs[i].length; k++) {
                    if (revertingWithdrawTimelockedSFs[i][k] == singleSuperformsData[i].superformId) {
                        found = true;
                        break;
                    }
                }
                for (uint256 k = 0; k < revertingWithdrawSFs[i].length; k++) {
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
        for (uint256 i = 0; i < vars.nDestinations; i++) {
            if (action.multiVaults) {
                amountsToRemint = new uint256[](
                    multiSuperformsData[i].superformIds.length
                );

                for (uint256 j = 0; j < multiSuperformsData[i].superformIds.length; j++) {
                    amountsToRemint[j] = multiSuperformsData[i].amounts[j];
                    bool found = false;

                    for (uint256 k = 0; k < revertingWithdrawSFs[i].length; k++) {
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

                for (uint256 k = 0; k < revertingWithdrawSFs[i].length; k++) {
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
    function _assertMultiVaultBalance(
        uint256 user,
        uint256[] memory superformIds,
        uint256[] memory amountsToAssert,
        bool[] memory partialWithdrawVaults
    )
        internal
    {
        address superRegistryAddress = getContract(CHAIN_0, "SuperRegistry");
        vm.selectFork(FORKS[CHAIN_0]);

        address superPositionsAddress =
            ISuperRegistry(superRegistryAddress).getAddress(ISuperRegistry(superRegistryAddress).SUPER_POSITIONS());

        IERC1155A superPositions = IERC1155A(superPositionsAddress);

        uint256 currentBalanceOfSp;

        bool partialWithdraw = partialWithdrawVaults.length > 0;
        for (uint256 i = 0; i < superformIds.length; i++) {
            currentBalanceOfSp = superPositions.balanceOf(users[user], superformIds[i]);

            if (partialWithdrawVaults.length > 0) {
                partialWithdraw = partialWithdrawVaults[i];
            }

            if (!partialWithdraw) {
                /// @dev <= 1 due to off by one issues with vault.previewRedeem(), leading to
                /// currentBalanceOfSp being 1 more than expected
                //assertLe(currentBalanceOfSp - amountsToAssert[i], 1);
                assertEq(currentBalanceOfSp, amountsToAssert[i]);
            } else {
                assertGt(currentBalanceOfSp, amountsToAssert[i]);
            }
        }
    }

    /// @dev generalized internal function to assert single superPosition balances.
    function _assertSingleVaultBalance(uint256 user, uint256 superformId, uint256 amountToAssert) internal {
        address superRegistryAddress = getContract(CHAIN_0, "SuperRegistry");
        vm.selectFork(FORKS[CHAIN_0]);

        address superPositionsAddress =
            ISuperRegistry(superRegistryAddress).getAddress(ISuperRegistry(superRegistryAddress).SUPER_POSITIONS());

        IERC1155A superPositions = IERC1155A(superPositionsAddress);

        uint256 currentBalanceOfSp = superPositions.balanceOf(users[user], superformId);

        assertEq(currentBalanceOfSp, amountToAssert);
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

        int256 dstSwapSlippage;

        /// @dev create an array of amounts summing the amounts of the same superform ids
        for (v.i = 0; v.i < v.lenSuperforms; v.i++) {
            totalSpAmount += args.multiSuperformsData.amounts[v.i];
            for (v.j = 0; v.j < v.lenSuperforms; v.j++) {
                v.foundRevertingDeposit = false;
                /// @dev find if a superform is a reverting
                if (args.lenRevertDeposit > 0) {
                    for (v.k = 0; v.k < args.lenRevertDeposit; v.k++) {
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

                    if (args.assertWithSlippage && args.slippage != 0 && !args.sameChain) {
                        /// @dev applying bridge slippage
                        v.finalAmount = (v.finalAmount * uint256(10_000 - args.slippage)) / 10_000;

                        /// @dev applying dstSwap slippage
                        if (args.isdstSwap) {
                            dstSwapSlippage = (args.slippage * int256(MULTI_TX_SLIPPAGE_SHARE)) / 100;
                            v.finalAmount = (v.finalAmount * uint256(10_000 - dstSwapSlippage)) / 10_000;
                        }
                    }
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
            for (uint256 i = 0; i < lenSuperforms; i++) {
                spAmountFinal[i] = currentSPBeforeWithdaw[i];

                for (uint256 j = 0; j < lenSuperforms; j++) {
                    foundRevertingWithdraw = false;
                    foundRevertingWithdrawTimelocked = false;

                    if (lenRevertWithdraw > 0) {
                        for (uint256 k = 0; k < lenRevertWithdraw; k++) {
                            foundRevertingWithdraw =
                                revertingWithdrawSFs[dstIndex][k] == multiSuperformsData.superformIds[i];
                            if (foundRevertingWithdraw) break;
                        }
                    }

                    if (lenRevertWithdrawTimelocked > 0) {
                        for (uint256 k = 0; k < lenRevertWithdrawTimelocked; k++) {
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

        for (uint256 i = 0; i < lenSuperforms; i++) {
            spAmountFinal[i] = currentSPBeforeWithdaw[i];
            for (uint256 j = 0; j < lenSuperforms; j++) {
                foundRevertingWithdraw = false;
                foundRevertingWithdrawTimelocked = false;

                if (lenRevertWithdraw > 0) {
                    for (uint256 k = 0; k < lenRevertWithdraw; k++) {
                        foundRevertingWithdraw =
                            revertingWithdrawSFs[dstIndex][k] == multiSuperformsData.superformIds[i];
                        if (foundRevertingWithdraw) break;
                    }
                }
                if (lenRevertWithdrawTimelocked > 0) {
                    for (uint256 k = 0; k < lenRevertWithdrawTimelocked; k++) {
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

        for (uint256 i = 0; i < lenSuperforms; i++) {
            spAmountFinal[i] = currentSPBeforeWithdaw[i];

            for (uint256 j = 0; j < lenSuperforms; j++) {
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
    }

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
            uint256[] memory spAmountSummedPerDst;
            spAmountSummed = new uint256[][](vars.nDestinations);

            for (uint256 i = 0; i < vars.nDestinations; i++) {
                v.partialWithdrawVaults = abi.decode(multiSuperformsData[i].extraFormData, (bool[]));
                /// @dev obtain amounts to assert
                (emptyAmount, spAmountSummedPerDst,) = _spAmountsMultiBeforeActionOrAfterSuccessDeposit(
                    SpAmountsMultiBeforeActionOrAfterSuccessDepositArgs(
                        multiSuperformsData[i], false, 0, false, 1, 0, i, action.dstSwap
                    )
                );

                /// @dev assert
                _assertMultiVaultBalance(
                    action.user,
                    multiSuperformsData[i].superformIds,
                    action.action == Actions.Withdraw ? spAmountSummedPerDst : emptyAmount,
                    v.partialWithdrawVaults
                );
                spAmountSummed[i] = spAmountSummedPerDst;
            }
        } else {
            v.token = singleSuperformsData[0].liqRequest.token;
            if (action.action != Actions.Withdraw) {
                inputBalanceBefore =
                    v.token != NATIVE_TOKEN ? IERC20(v.token).balanceOf(users[action.user]) : users[action.user].balance;
            }
            spAmountBeforeWithdrawPerDestination = new uint256[](
                vars.nDestinations
            );
            for (uint256 i = 0; i < vars.nDestinations; i++) {
                (v.superform,,) = singleSuperformsData[i].superformId.getSuperform();
                v.partialWithdrawVault = abi.decode(singleSuperformsData[i].extraFormData, (bool));
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
                        action.action == Actions.Withdraw ? spAmountBeforeWithdrawPerDestination[i] : 0
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

        for (uint256 i = 0; i < vars.nDestinations; i++) {
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
                        new uint256[](
                            multiSuperformsData[i].superformIds.length
                        ),
                        new bool[](multiSuperformsData[i].superformIds.length)
                    );
                } else {
                    /// @dev assert spToken Balance
                    _assertMultiVaultBalance(
                        action.user,
                        multiSuperformsData[i].superformIds,
                        spAmountSummed,
                        new bool[](multiSuperformsData[i].superformIds.length)
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

                if (action.slippage != 0 && CHAIN_0 != DST_CHAINS[i]) {
                    /// @dev applying bridge slippage
                    finalAmount = (finalAmount * uint256(10_000 - action.slippage)) / 10_000;

                    /// @dev applying dst swap slippage
                    if (action.dstSwap) {
                        vars.slippage = (action.slippage * int256(MULTI_TX_SLIPPAGE_SHARE)) / 100;
                        finalAmount = (finalAmount * uint256(10_000 - vars.slippage)) / 10_000;
                    }
                }

                finalAmount = repetitions * finalAmount;
                /// @dev assert spToken Balance. If reverting amount of sp should be 0 (assuming no action before this
                /// one)
                _assertSingleVaultBalance(
                    action.user, singleSuperformsData[i].superformId, foundRevertingDeposit ? 0 : finalAmount
                );
            }
        }
        /// @dev TODO
        if (token == NATIVE_TOKEN) {
            console.log("balance now", users[action.user].balance);
            console.log("balance Before action", inputBalanceBefore);
            console.log("msgValue", msgValue);
            console.log("balance now + msgValue", msgValue + users[action.user].balance);
        }
        /// @dev assert user input token balance

        // assertEq(
        //     token != NATIVE_TOKEN ? IERC20(token).balanceOf(users[action.user]) : users[action.user].balance,
        //     inputBalanceBefore - totalSpAmountAllDestinations - msgValue
        // );
        // console.log("Asserted after deposit");
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

        for (uint256 i = 0; i < vars.nDestinations; i++) {
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
                v.partialWithdrawVaults = abi.decode(multiSuperformsData[i].extraFormData, (bool[]));
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
                    action.user, multiSuperformsData[i].superformIds, v.spAmountFinal, v.partialWithdrawVaults
                );
            } else {
                v.foundRevertingWithdraw = false;
                v.foundRevertingWithdrawTimelocked = false;
                v.partialWithdrawVault = abi.decode(singleSuperformsData[i].extraFormData, (bool));

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
                            : spAmountBeforeWithdrawPerDst[i] - singleSuperformsData[i].amount
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

        for (uint256 i = 0; i < vars.nDestinations; i++) {
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
                    v.partialWithdrawVaults = abi.decode(multiSuperformsData[i].extraFormData, (bool[]));
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
                        action.user, multiSuperformsData[i].superformIds, v.spAmountFinal, v.partialWithdrawVaults
                    );
                }
            } else {
                v.foundRevertingWithdraw = false;
                v.foundRevertingWithdrawTimelocked = false;
                v.partialWithdrawVault = abi.decode(singleSuperformsData[i].extraFormData, (bool));

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
                            : spAmountBeforeWithdrawPerDst[i] - singleSuperformsData[i].amount
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

        for (uint256 i = 0; i < vars.nDestinations; i++) {
            if (action.multiVaults && amountsToRemintPerDst[i].length > 0) {
                partialWithdrawVaults = abi.decode(multiSuperformsData[i].extraFormData, (bool[]));
                /// @dev obtain amounts to assert
                spAmountFinal = _spAmountsMultiAfterFailedWithdraw(
                    multiSuperformsData[i], action.user, spAmountsBeforeWithdraw[i], amountsToRemintPerDst[i]
                );

                /// @dev assert
                _assertMultiVaultBalance(
                    action.user, multiSuperformsData[i].superformIds, spAmountFinal, partialWithdrawVaults
                );
            } else if (!action.multiVaults) {
                partialWithdrawVault = abi.decode(singleSuperformsData[i].extraFormData, (bool));
                if (amountsToRemintPerDst[i].length > 0 && amountsToRemintPerDst[i][0] != 0) {
                    if (!partialWithdrawVault) {
                        /// @dev this assertion assumes the withdraw is happening on the same superformId as the
                        /// previous deposit
                        _assertSingleVaultBalance(
                            action.user, singleSuperformsData[i].superformId, spAmountBeforeWithdrawPerDst[i]
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

        for (uint256 i = 0; i < vars.nDestinations; i++) {
            if (!(CHAIN_0 == DST_CHAINS[i] && revertingWithdrawSFs[i].length > 0)) {
                if (revertingWithdrawTimelockedSFs[i].length > 0) {
                    if (action.multiVaults) {
                        v.partialWithdrawVaults = abi.decode(multiSuperformsData[i].extraFormData, (bool[]));
                        /// @dev this obtains amounts that failed from returned data obtained as a return from process
                        /// payload

                        /// @dev obtains final amounts to assert considering the amounts that failed to be withdrawn
                        v.spAmountFinal = _spAmountsMultiAfterFailedWithdraw(
                            multiSuperformsData[i], action.user, spAmountsBeforeWithdraw[i], amountsToRemintPerDst[i]
                        );

                        /// @dev asserts
                        _assertMultiVaultBalance(
                            action.user, multiSuperformsData[i].superformIds, v.spAmountFinal, v.partialWithdrawVaults
                        );
                    } else {
                        v.partialWithdrawVault = abi.decode(singleSuperformsData[i].extraFormData, (bool));
                        if (!v.partialWithdrawVault) {
                            /// @dev this assertion assumes the withdraw is happening on the same superformId as the
                            /// previous deposit
                            _assertSingleVaultBalance(
                                action.user, singleSuperformsData[i].superformId, spAmountBeforeWithdrawPerDst[i]
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
}

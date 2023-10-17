/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "./CommonProtocolActions.sol";
import { IPermit2 } from "src/vendor/dragonfly-xyz/IPermit2.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IERC1155A } from "ERC1155A/interfaces/IERC1155A.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { Error } from "src/utils/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";

abstract contract InvariantProtocolActions is CommonProtocolActions {
    using DataLib for uint256;

    /// @dev TODO - sujith to comment
    uint8[][] public MultiDstAMBs;

    /// @dev for multiDst tests with repeating destinations
    struct UniqueDSTInfo {
        uint256 payloadNumber;
        uint256 nRepetitions;
    }
    /// @dev used for assertions to calculate proper amounts per dst

    /// @dev bool flag to detect on each action if a given destination has a reverting vault (action is stoped in stage
    /// 2)
    bool sameChainDstHasRevertingVault;

    /// @dev to be aware which destinations have been 'used' already

    function setUp() public virtual override {
        super.setUp();
    }

    /*///////////////////////////////////////////////////////////////
                            MAIN INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _runMainStages(
        TestAction memory action,
        MultiVaultSFData[] memory multiSuperformsData,
        SingleVaultSFData[] memory singleSuperformsData,
        MessagingAssertVars[] memory aV,
        StagesLocalVars memory vars,
        bool success
    )
        internal
    {
        console.log("--new-action");
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[vars.CHAIN_0]);

        address token;
        /// @dev assumption here is DAI has total supply of TOTAL_SUPPLY_DAI on all chains
        /// and similarly for USDT, WETH and ETH
        if (action.externalToken == 3) {
            deal(users[action.user], TOTAL_SUPPLY_ETH);
        } else {
            token = getContract(vars.CHAIN_0, UNDERLYING_TOKENS[action.externalToken]);

            if (action.externalToken == 0) {
                deal(token, users[action.user], TOTAL_SUPPLY_DAI);
            } else if (action.externalToken == 1) {
                deal(token, users[action.user], TOTAL_SUPPLY_USDC * 1e12);
            } else if (action.externalToken == 2) {
                deal(token, users[action.user], TOTAL_SUPPLY_WETH);
            }
        }

        /// @dev depositing underlying tokens in underlying vault to simulate yield after
        /// deposit
        if (action.action == Actions.Withdraw) {
            for (uint256 i = 0; i < vars.DST_CHAINS.length; ++i) {
                vm.selectFork(FORKS[vars.DST_CHAINS[i]]);

                vars.superformIds = _superformIds(
                    vars.targetUnderlyings[i], vars.targetVaults[i], vars.targetFormKinds[i], vars.DST_CHAINS[i]
                );
                for (uint256 j = 0; j < vars.targetUnderlyings[i].length; ++j) {
                    token = getContract(vars.DST_CHAINS[i], UNDERLYING_TOKENS[vars.targetUnderlyings[i][j]]);
                    (vars.superformT,,) = vars.superformIds[j].getSuperform();
                    /// @dev grabs amounts in deposits (assumes deposit is action 0)
                    deal(token, IBaseForm(vars.superformT).getVaultAddress(), vars.amounts[i]);
                }
            }
        }

        vm.selectFork(initialFork);

        if (action.dstSwap) MULTI_TX_SLIPPAGE_SHARE = 40;
        /// @dev builds superformRouter request data
        (multiSuperformsData, singleSuperformsData, vars) = _stage1_buildReqData(action, vars);
        console.log("Stage 1 complete");

        uint256 msgValue;
        /// @dev passes request data and performs initial call
        /// @dev returns sameChainDstHasRevertingVault - this means that the request reverted, thus no payloadId
        /// increase happened nor there is any need for payload update or further assertion
        (vars, msgValue) = _stage2_run_src_action(action, multiSuperformsData, singleSuperformsData, vars);
        console.log("Stage 2 complete");
        UniqueDSTInfo[] memory usedDsts;
        /// @dev simulation of cross-chain message delivery (for x-chain actions) (With no assertions)
        (aV, usedDsts) = _stage3_src_to_dst_amb_delivery(action, vars, multiSuperformsData, singleSuperformsData);
        console.log("Stage 3 complete");

        /// @dev processing of message delivery on destination   (for x-chain actions)
        success = _stage4_process_src_dst_payload(action, vars, aV, singleSuperformsData, usedDsts);
        if (!success) {
            console.log("Stage 4 failed");
            return;
        } else {
            console.log("Stage 4 complete");
        }

        if (
            (action.action == Actions.Deposit || action.action == Actions.DepositPermit2)
                && !(action.testType == TestType.RevertXChainDeposit)
        ) {
            /// @dev processing of superPositions mint from destination callback on source (for successful deposits)

            success = _stage5_process_superPositions_mint(action, vars);
            if (!success) {
                console.log("Stage 5 failed");

                return;
            } else if (action.testType != TestType.RevertMainAction) {
                console.log("Stage 5 complete");
            }
        }

        MULTI_TX_SLIPPAGE_SHARE = 0;

        console.log("Done -");
    }

    /// @dev STEP 1: Build Request Data for SuperformRouter
    function _stage1_buildReqData(
        TestAction memory action,
        StagesLocalVars memory vars
    )
        internal
        returns (MultiVaultSFData[] memory, SingleVaultSFData[] memory, StagesLocalVars memory)
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
            if (vars.CHAIN_0 == chainIds[i]) {
                vars.chain0Index = i;
                break;
            }
        }

        vars.lzEndpoint_0 = LZ_ENDPOINTS[vars.CHAIN_0];
        vars.fromSrc = payable(getContract(vars.CHAIN_0, "SuperformRouter"));

        vars.nDestinations = vars.DST_CHAINS.length;

        vars.lzEndpoints_1 = new address[](vars.nDestinations);
        vars.toDst = new address[](vars.nDestinations);

        MultiVaultSFData[] memory multiSuperformsData = new MultiVaultSFData[](vars.nDestinations);
        SingleVaultSFData[] memory singleSuperformsData = new SingleVaultSFData[](vars.nDestinations);

        /// @dev in each destination we want to build our request data
        for (uint256 i = 0; i < vars.nDestinations; i++) {
            for (uint256 j = 0; j < chainIds.length; j++) {
                if (vars.DST_CHAINS[i] == chainIds[j]) {
                    vars.chainDstIndex = j;
                    break;
                }
            }
            vars.lzEndpoints_1[i] = LZ_ENDPOINTS[vars.DST_CHAINS[i]];
            /// @dev first the superformIds are obtained, together with token addresses for src and dst, vault addresses
            /// and information about vaults with partial withdraws (for assertions)
            (vars.targetSuperformIds, vars.underlyingSrcToken, vars.underlyingDstToken, vars.vaultMock) = _targetVaults(
                vars.CHAIN_0,
                vars.DST_CHAINS[i],
                vars.targetVaults[i],
                vars.targetFormKinds[i],
                vars.targetUnderlyings[i]
            );

            vars.toDst = new address[](vars.targetSuperformIds.length);

            /// @dev action is sameChain, if there is a liquidity swap it should go to the same form. In adition, in
            /// this case, if action is cross chain withdraw, user can select to receive a different kind of underlying
            /// from source
            /// @dev if action is cross-chain deposit, destination for liquidity is coreStateRegistry
            for (uint256 k = 0; k < vars.targetSuperformIds.length; k++) {
                if (
                    vars.CHAIN_0 == vars.DST_CHAINS[i]
                        || (action.action == Actions.Withdraw && vars.CHAIN_0 != vars.DST_CHAINS[i])
                ) {
                    (vars.superformT,,) = vars.targetSuperformIds[k].getSuperform();
                    vars.toDst[k] = payable(vars.superformT);
                } else {
                    vars.toDst[k] = action.dstSwap
                        ? payable(getContract(vars.DST_CHAINS[i], "DstSwapper"))
                        : payable(getContract(vars.DST_CHAINS[i], "CoreStateRegistry"));
                }
            }

            vars.amounts = vars.targetAmounts[i];

            vars.liqBridges = vars.targetLiqBridges[i];

            if (action.multiVaults) {
                multiSuperformsData[i] = _buildMultiVaultCallData(
                    MultiVaultCallDataArgs(
                        action.user,
                        vars.fromSrc,
                        action.externalToken == 3
                            ? NATIVE_TOKEN
                            : getContract(vars.CHAIN_0, UNDERLYING_TOKENS[action.externalToken]),
                        vars.toDst,
                        vars.underlyingSrcToken,
                        vars.underlyingDstToken,
                        vars.targetSuperformIds,
                        vars.amounts,
                        vars.liqBridges,
                        1000,
                        vars.vaultMock,
                        vars.CHAIN_0,
                        vars.DST_CHAINS[i],
                        uint256(chainIds[vars.chain0Index]),
                        i,
                        vars.chainDstIndex,
                        action.dstSwap,
                        action.action,
                        action.slippage,
                        new bool[](0)
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
                            vars.CHAIN_0 == vars.DST_CHAINS[i]
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
                        : getContract(vars.CHAIN_0, UNDERLYING_TOKENS[action.externalToken]),
                    vars.toDst[0],
                    vars.underlyingSrcToken[0],
                    vars.underlyingDstToken[0],
                    vars.targetSuperformIds[0],
                    finalAmount,
                    vars.liqBridges[0],
                    1000,
                    vars.vaultMock[0],
                    vars.CHAIN_0,
                    vars.DST_CHAINS[i],
                    vars.DST_CHAINS[i],
                    uint256(chainIds[vars.chain0Index]),
                    /// @dev these are just the originating and dst chain ids casted to uint256 (the liquidity bridge
                    /// chain ids)
                    uint256(vars.DST_CHAINS[i]),
                    /// @dev these are just the originating and dst chain ids casted to uint256 (the liquidity bridge
                    /// chain ids)
                    action.dstSwap,
                    false,
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

        vm.selectFork(FORKS[vars.CHAIN_0]);

        return (multiSuperformsData, singleSuperformsData, vars);
    }

    /// @dev STEP 2: Run Source Chain Action
    function _stage2_run_src_action(
        TestAction memory action,
        MultiVaultSFData[] memory multiSuperformsData,
        SingleVaultSFData[] memory singleSuperformsData,
        StagesLocalVars memory vars
    )
        internal
        returns (StagesLocalVars memory, uint256 msgValue)
    {
        vm.selectFork(FORKS[vars.CHAIN_0]);
        SuperformRouter superformRouter = SuperformRouter(vars.fromSrc);

        PaymentHelper paymentHelper = PaymentHelper(getContract(vars.CHAIN_0, "PaymentHelper"));

        /// @dev pigeon requires event logs to be recorded so that it can properly capture the variables it needs to
        /// fullfil messages. Check pigeon library docs for more info
        vm.recordLogs();
        if (action.multiVaults) {
            if (vars.nDestinations == 1) {
                /// @dev data built in step 1 is aggregated with AMBS and dstChains info
                vars.singleDstMultiVaultStateReq =
                    SingleXChainMultiVaultStateReq(vars.AMBs, vars.DST_CHAINS[0], multiSuperformsData[0]);

                if (action.action == Actions.Deposit || action.action == Actions.DepositPermit2) {
                    /// @dev payment estimation, differs according to the type of entry point used
                    (,,, msgValue) = vars.CHAIN_0 != vars.DST_CHAINS[0]
                        ? paymentHelper.estimateSingleXChainMultiVault(vars.singleDstMultiVaultStateReq, true)
                        : paymentHelper.estimateSingleDirectMultiVault(
                            SingleDirectMultiVaultStateReq(multiSuperformsData[0]), true
                        );

                    vm.prank(users[action.user]);

                    if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                        vm.expectRevert();
                    }
                    /// @dev the actual call to the entry point

                    vars.CHAIN_0 != vars.DST_CHAINS[0]
                        ? superformRouter.singleXChainMultiVaultDeposit{ value: msgValue }(vars.singleDstMultiVaultStateReq)
                        : superformRouter.singleDirectMultiVaultDeposit{ value: msgValue }(
                            SingleDirectMultiVaultStateReq(multiSuperformsData[0])
                        );
                } else if (action.action == Actions.Withdraw) {
                    /// @dev payment estimation, differs according to the type of entry point used
                    (,,, msgValue) = vars.CHAIN_0 != vars.DST_CHAINS[0]
                        ? paymentHelper.estimateSingleXChainMultiVault(vars.singleDstMultiVaultStateReq, false)
                        : paymentHelper.estimateSingleDirectMultiVault(
                            SingleDirectMultiVaultStateReq(multiSuperformsData[0]), false
                        );

                    vm.prank(users[action.user]);

                    if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                        vm.expectRevert();
                    }
                    /// @dev the actual call to the entry point

                    vars.CHAIN_0 != vars.DST_CHAINS[0]
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
                    MultiDstMultiVaultStateReq(MultiDstAMBs, vars.DST_CHAINS, multiSuperformsData);

                if (action.action == Actions.Deposit || action.action == Actions.DepositPermit2) {
                    /// @dev payment estimation, differs according to the type of entry point used

                    (,,, msgValue) = paymentHelper.estimateMultiDstMultiVault(vars.multiDstMultiVaultStateReq, true);
                    vm.prank(users[action.user]);

                    if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                        vm.expectRevert();
                    }

                    /// @dev the actual call to the entry point
                    superformRouter.multiDstMultiVaultDeposit{ value: msgValue }(vars.multiDstMultiVaultStateReq);
                } else if (action.action == Actions.Withdraw) {
                    /// @dev payment estimation, differs according to the type of entry point used

                    (,,, msgValue) = paymentHelper.estimateMultiDstMultiVault(vars.multiDstMultiVaultStateReq, false);
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
                if (vars.CHAIN_0 != vars.DST_CHAINS[0]) {
                    vars.singleXChainSingleVaultStateReq =
                        SingleXChainSingleVaultStateReq(vars.AMBs, vars.DST_CHAINS[0], singleSuperformsData[0]);

                    if (action.action == Actions.Deposit || action.action == Actions.DepositPermit2) {
                        /// @dev payment estimation, differs according to the type of entry point used

                        (,,, msgValue) =
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

                        (,,, msgValue) =
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

                        (,,, msgValue) =
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

                        (,,, msgValue) =
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
                    MultiDstSingleVaultStateReq(MultiDstAMBs, vars.DST_CHAINS, singleSuperformsData);
                if (action.action == Actions.Deposit || action.action == Actions.DepositPermit2) {
                    /// @dev payment estimation, differs according to the type of entry point used
                    (,,, msgValue) = paymentHelper.estimateMultiDstSingleVault(vars.multiDstSingleVaultStateReq, true);
                    vm.prank(users[action.user]);

                    if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                        vm.expectRevert();
                    }
                    /// @dev the actual call to the entry point

                    superformRouter.multiDstSingleVaultDeposit{ value: msgValue }(vars.multiDstSingleVaultStateReq);
                } else if (action.action == Actions.Withdraw) {
                    /// @dev payment estimation, differs according to the type of entry point used

                    (,,, msgValue) = paymentHelper.estimateMultiDstSingleVault(vars.multiDstSingleVaultStateReq, true);
                    vm.prank(users[action.user]);

                    if (sameChainDstHasRevertingVault || action.testType == TestType.RevertMainAction) {
                        vm.expectRevert();
                    }
                    /// @dev the actual call to the entry point

                    superformRouter.multiDstSingleVaultWithdraw{ value: msgValue }(vars.multiDstSingleVaultStateReq);
                }
            }
        }

        return (vars, msgValue);
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

    function _stage3_src_to_dst_amb_delivery(
        TestAction memory action,
        StagesLocalVars memory vars,
        MultiVaultSFData[] memory multiSuperformsData,
        SingleVaultSFData[] memory singleSuperformsData
    )
        internal
        returns (MessagingAssertVars[] memory, UniqueDSTInfo[] memory)
    {
        Stage3InternalVars memory internalVars;
        UniqueDSTInfo[] memory usedDSTs = new UniqueDSTInfo[](vars.nDestinations);
        uint64[] memory uniqueDsts;
        for (uint256 i = 0; i < vars.nDestinations; i++) {
            if (usedDSTs[i].payloadNumber == 0) {
                ++usedDSTs[i].payloadNumber;
                if (vars.DST_CHAINS[i] != vars.CHAIN_0) {
                    ++vars.nUniqueDsts;
                }
            } else {
                /// @dev add repetitions (for non unique destinations)
                ++usedDSTs[i].payloadNumber;
            }
        }
        uniqueDsts = new uint64[](vars.nUniqueDsts);
        uint256 countUnique;
        for (uint256 i = 0; i < vars.nDestinations; i++) {
            /// @dev if nRepetitions is = 0 still it means uniqueDst has not been found yet (1 repetition)
            if (usedDSTs[i].nRepetitions == 0) {
                ++usedDSTs[i].nRepetitions;
                if (vars.DST_CHAINS[i] != vars.CHAIN_0) {
                    uniqueDsts[countUnique] = vars.DST_CHAINS[i];
                    ++countUnique;
                }
            } else {
                /// @dev add repetitions (for non unique destinations)
                ++usedDSTs[i].nRepetitions;
            }
        }
        if (countUnique != vars.nUniqueDsts) revert("InvalidCount");

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
                if (uniqueDsts[j] == chainIds[i] && chainIds[i] != vars.CHAIN_0) {
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
        vars.logs = vm.getRecordedLogs();

        for (uint256 index; index < vars.AMBs.length; index++) {
            if (vars.AMBs[index] == 1) {
                LayerZeroHelper(getContract(vars.CHAIN_0, "LayerZeroHelper")).help(
                    internalVars.endpoints,
                    internalVars.lzChainIds,
                    5_000_000,
                    /// note: using some max limit
                    internalVars.forkIds,
                    vars.logs
                );
            }

            if (vars.AMBs[index] == 2) {
                /// @dev see pigeon for this implementation
                HyperlaneHelper(getContract(vars.CHAIN_0, "HyperlaneHelper")).help(
                    address(HyperlaneMailbox),
                    internalVars.toMailboxes,
                    internalVars.expDstDomains,
                    internalVars.forkIds,
                    vars.logs
                );
            }

            if (vars.AMBs[index] == 3) {
                WormholeHelper(getContract(vars.CHAIN_0, "WormholeHelper")).help(
                    WORMHOLE_CHAIN_IDS[vars.CHAIN_0],
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

        /// @dev assert good delivery of message on destination by analyzing superformIds and mounts
        for (uint256 i = 0; i < vars.nDestinations; i++) {
            aV[i].toChainId = vars.DST_CHAINS[i];
            if (vars.CHAIN_0 != aV[i].toChainId && !sameChainDstHasRevertingVault) {
                if (action.multiVaults) {
                    aV[i].expectedMultiVaultsData = multiSuperformsData[i];
                } else {
                    aV[i].expectedSingleVaultData = singleSuperformsData[i];
                }
            }
        }

        return (aV, usedDSTs);
    }

    /// @dev STEP 4 X-CHAIN: Update state (for deposits) and process src to dst payload (for deposits/withdraws)
    function _stage4_process_src_dst_payload(
        TestAction memory action,
        StagesLocalVars memory vars,
        MessagingAssertVars[] memory aV,
        SingleVaultSFData[] memory singleSuperformsData,
        UniqueDSTInfo[] memory usedDSTs
    )
        internal
        returns (bool success)
    {
        success = true;
        if (!sameChainDstHasRevertingVault) {
            for (uint256 i = 0; i < vars.nDestinations; i++) {
                aV[i].toChainId = vars.DST_CHAINS[i];
                if (vars.CHAIN_0 != aV[i].toChainId) {
                    vm.selectFork(FORKS[aV[i].toChainId]);

                    if (action.action == Actions.Deposit || action.action == Actions.DepositPermit2) {
                        uint256 payloadCount = CoreStateRegistry(
                            payable(getContract(aV[i].toChainId, "CoreStateRegistry"))
                        ).payloadsCount();

                        PAYLOAD_ID[aV[i].toChainId] = payloadCount - usedDSTs[i].payloadNumber + 1;

                        --usedDSTs[i].payloadNumber;

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
                                (,, vars.underlyingDstToken,) = _targetVaults(
                                    vars.CHAIN_0,
                                    vars.DST_CHAINS[i],
                                    vars.targetVaults[i],
                                    vars.targetFormKinds[i],
                                    vars.targetUnderlyings[i]
                                );
                                vars.liqBridges = vars.targetLiqBridges[i];

                                /// @dev dst swap is performed to ensure tokens reach CoreStateRegistry on deposits
                                if (action.multiVaults) {
                                    vars.amounts = vars.targetAmounts[i];
                                    _batchProcessDstSwap(
                                        vars.liqBridges,
                                        vars.CHAIN_0,
                                        aV[i].toChainId,
                                        vars.underlyingDstToken,
                                        vars.multiVaultsPayloadArg.amounts,
                                        action.slippage
                                    );
                                } else {
                                    _processDstSwap(
                                        vars.liqBridges[0],
                                        vars.CHAIN_0,
                                        aV[i].toChainId,
                                        vars.underlyingDstToken[0],
                                        vars.singleVaultsPayloadArg.amount,
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

                            vm.recordLogs();
                            /// @dev payload processing. This performs the action down to the form level and builds any
                            /// acknowledgement data needed to bring it back to source
                            /// @dev hence the record logs before and after and payload delivery to source
                            success = _processPayload(
                                PAYLOAD_ID[aV[i].toChainId], vars.CHAIN_0, aV[i].toChainId, vars.AMBs, action.testType
                            );

                            vars.logs = vm.getRecordedLogs();

                            _payloadDeliveryHelper(vars.CHAIN_0, aV[i].toChainId, vars.AMBs, vars.logs);
                        } else if (action.testType == TestType.RevertProcessPayload) {
                            /// @dev this logic is essentially repeated from above
                            if (action.multiVaults) {
                                _updateMultiVaultDepositPayload(vars.multiVaultsPayloadArg);
                            } else if (singleSuperformsData.length > 0) {
                                _updateSingleVaultDepositPayload(vars.singleVaultsPayloadArg);
                            }
                            /// @dev process payload will revert in here
                            success = _processPayload(
                                PAYLOAD_ID[aV[i].toChainId], vars.CHAIN_0, aV[i].toChainId, vars.AMBs, action.testType
                            );
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
                        PAYLOAD_ID[aV[i].toChainId] = CoreStateRegistry(
                            payable(getContract(aV[i].toChainId, "CoreStateRegistry"))
                        ).payloadsCount() - usedDSTs[i].payloadNumber + 1;
                        --usedDSTs[i].payloadNumber;

                        vm.recordLogs();

                        /// @dev payload processing. This performs the action down to the form level and builds any
                        /// acknowledgement data needed to bring it back to source
                        /// @dev hence the record logs before and after and payload delivery to source
                        success = _processPayload(
                            PAYLOAD_ID[aV[i].toChainId], vars.CHAIN_0, aV[i].toChainId, vars.AMBs, action.testType
                        );
                        vars.logs = vm.getRecordedLogs();

                        _payloadDeliveryHelper(vars.CHAIN_0, aV[i].toChainId, vars.AMBs, vars.logs);
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
        StagesLocalVars memory vars
    )
        internal
        returns (bool success)
    {
        ///@dev assume it will pass by default
        success = true;

        vm.selectFork(FORKS[vars.CHAIN_0]);

        uint256 toChainId;
        for (uint256 i = 0; i < vars.nDestinations; i++) {
            toChainId = vars.DST_CHAINS[i];

            if (vars.CHAIN_0 != toChainId) {
                if (action.testType == TestType.Pass) {
                    unchecked {
                        PAYLOAD_ID[vars.CHAIN_0]++;
                    }

                    success = _processPayload(
                        PAYLOAD_ID[vars.CHAIN_0], vars.CHAIN_0, vars.CHAIN_0, vars.AMBs, action.testType
                    );
                }
            }
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
            uint64 liqDstChainId = args.toChainId;

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
                false,
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

            finalAmounts[i] = superformData.amount;
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
            abi.encode(false)
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
        uint256 amountTemp;
        uint256 amount;
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
        /// @dev build permit2 calldata
        vm.selectFork(FORKS[args.toChainId]);
        v.decimal2 = args.underlyingTokenDst != NATIVE_TOKEN ? MockERC20(args.underlyingTokenDst).decimals() : 18;

        (, int256 USDPerUnderlyingTokenDst,,,) =
            AggregatorV3Interface(tokenPriceFeeds[args.toChainId][args.underlyingTokenDst]).latestRoundData();

        vm.selectFork(FORKS[args.srcChainId]);
        v.decimal1 = args.externalToken != NATIVE_TOKEN ? MockERC20(args.externalToken).decimals() : 18;
        v.decimal3 = args.underlyingToken != NATIVE_TOKEN ? MockERC20(args.underlyingToken).decimals() : 18;
        (, int256 USDPerExternalToken,,,) =
            AggregatorV3Interface(tokenPriceFeeds[args.srcChainId][args.externalToken]).latestRoundData();
        (, int256 USDPerUnderlyingToken,,,) =
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
            args.underlyingTokenDst,
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
            uint256(USDPerExternalToken),
            uint256(USDPerUnderlyingTokenDst),
            uint256(USDPerUnderlyingToken)
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

        /// @dev for e.g. externalToken = DAI, underlyingTokenDst = USDC, daiAmount = 100
        /// => usdcAmount = ((USDPerDai / 10e18) / (USDPerUsdc / 10e6)) * daiAmount
        console.log("test amount pre-swap", args.amount);
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
                args.amount = (args.amount * uint256(USDPerExternalToken))
                    / (uint256(USDPerUnderlyingToken) * 10 ** (decimal1 - decimal2));
            } else {
                args.amount = ((args.amount * uint256(USDPerExternalToken)) * 10 ** (decimal2 - decimal1))
                    / uint256(USDPerUnderlyingToken);
            }
            console.log("test amount post-swap", args.amount);
        }

        int256 slippage = args.slippage;
        if (args.srcChainId == args.toChainId) slippage = 0;

        /// @dev applying 100% x-chain slippage at once i.e. bridge + dstSwap slippage (as opposed to 2 steps in
        /// LiFiMock) coz this code will only be executed once (as opposed to twice in LiFiMock, once for bridge and
        /// other for dstSwap)
        args.amount = (args.amount * uint256(10_000 - slippage)) / 10_000;
        console.log("test amount pre-bridge, post-slippage", v.amount);

        /// @dev if args.externalToken == args.underlyingToken, USDPerExternalToken == USDPerUnderlyingToken
        /// @dev v.decimal3 = decimals of args.underlyingToken (args.externalToken too if above holds true) (src chain),
        /// v.decimal2 = decimals of args.underlyingTokenDst (dst chain)
        if (v.decimal3 > v.decimal2) {
            v.amount = (args.amount * uint256(USDPerUnderlyingToken))
                / (uint256(USDPerUnderlyingTokenDst) * 10 ** (v.decimal3 - v.decimal2));
        } else {
            v.amount = (args.amount * uint256(USDPerUnderlyingToken) * 10 ** (v.decimal2 - v.decimal3))
                / uint256(USDPerUnderlyingTokenDst);
        }
        console.log("test amount post-bridge", v.amount);

        vm.selectFork(v.initialFork);

        /// @dev extraData is unused here so false is encoded (it is currently used to send in the partialWithdraw
        /// vaults without resorting to extra args, just for withdraws)
        superformData = SingleVaultSFData(
            args.superformId,
            v.amount,
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

        vm.selectFork(FORKS[args.srcChainId]);

        vars.superformRouter = contracts[args.srcChainId][bytes32(bytes("SuperformRouter"))];
        vars.stateRegistry = contracts[args.srcChainId][bytes32(bytes("SuperRegistry"))];
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
            //vars.actualWithdrawAmount,
            true,
            /// @dev putting a placeholder value for now (not really used)
            args.slippage,
            /// @dev switching USDPerExternalToken with USDPerUnderlyingTokenDst as above
            uint256(USDPerUnderlyingTokenDst),
            uint256(USDPerExternalToken),
            uint256(USDPerUnderlyingToken)
        );

        vars.txData = _buildLiqBridgeTxData(liqBridgeTxDataArgs, args.toChainId == args.liqDstChainId);

        vars.liqReq = LiqRequest(
            args.liqBridge,
            vars.txData,
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
            abi.encode(false)
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
        uint256[] memory targetVaultsPerDst,
        uint32[] memory targetFormKindsPerDst,
        uint256[] memory targetUnderlyingsPerDst
    )
        internal
        view
        returns (
            uint256[] memory targetSuperformsMem,
            address[] memory underlyingSrcTokensMem,
            address[] memory underlyingDstTokensMem,
            address[] memory vaultMocksMem
        )
    {
        TargetVaultsVars memory vars;

        /// @dev constructs superFormIds from provided input info
        vars.superformIdsTemp =
            _superformIds(targetUnderlyingsPerDst, targetVaultsPerDst, targetFormKindsPerDst, chain1);

        vars.len = vars.superformIdsTemp.length;

        if (vars.len == 0) revert LEN_VAULTS_ZERO();

        targetSuperformsMem = new uint256[](vars.len);
        underlyingSrcTokensMem = new address[](vars.len);
        underlyingDstTokensMem = new address[](vars.len);
        vaultMocksMem = new address[](vars.len);

        /// @dev this loop assigns the information in the correct output arrays the best way possible
        for (uint256 i = 0; i < vars.len; i++) {
            vars.underlyingToken = UNDERLYING_TOKENS[targetUnderlyingsPerDst[i]]; // 1

            targetSuperformsMem[i] = vars.superformIdsTemp[i];
            underlyingSrcTokensMem[i] = getContract(chain0, vars.underlyingToken);
            underlyingDstTokensMem[i] = getContract(chain1, vars.underlyingToken);
            vaultMocksMem[i] = getContract(chain1, VAULT_NAMES[targetVaultsPerDst[i]][targetUnderlyingsPerDst[i]]);
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
                    Strings.toString(FORM_IMPLEMENTATION_IDS[formKinds_[i]])
                )
            );
            /// @dev superformids are built here
            superformIds_[i] = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[formKinds_[i]], chainId_);
        }

        return superformIds_;
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
                /// @dev bridge slippage is already applied in _buildSingleVaultDepositCallData()
                //finalAmounts[i] = (finalAmounts[i] * uint256(10_000 - args.slippage)) / 10_000;

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

    function _processPayload(
        uint256 payloadId_,
        uint64 srcChainId_,
        uint64 targetChainId_,
        uint8[] memory,
        TestType testType
    )
        internal
        returns (bool)
    {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[targetChainId_]);

        uint256 nativeFee;

        /// @dev only generate if acknowledgement is needed
        if (targetChainId_ != srcChainId_) {
            (nativeFee,) = PaymentHelper(getContract(targetChainId_, "PaymentHelper")).estimateAckCost(payloadId_);
        }

        vm.prank(deployer);
        if (testType == TestType.Pass) {
            CoreStateRegistry(payable(getContract(targetChainId_, "CoreStateRegistry"))).processPayload{
                value: nativeFee
            }(payloadId_);
        }

        vm.selectFork(initialFork);
        return true;
    }

    function _processTwoStepPayload(
        uint256 payloadId_,
        uint64 srcChainId_,
        uint64 targetChainId_,
        TestType, /*testType*/
        bytes4,
        uint256 msgValue
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

    function _payloadDeliveryHelper(
        uint64 FROM_CHAIN,
        uint64 TO_CHAIN,
        uint8[] memory AMBs,
        Vm.Log[] memory logs
    )
        internal
    {
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
}

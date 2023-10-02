/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "./BaseProtocolActions.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { DataLib } from "src/libraries/DataLib.sol";

abstract contract InvariantProtocolActions is BaseProtocolActions {
    using DataLib for uint256;

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
        override
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
        console.log("Stage 1 complete");
        console.log("BBBB");

        /// @dev passes request data and performs initial call
        /// @dev returns sameChainDstHasRevertingVault - this means that the request reverted, thus no payloadId
        /// increase happened nor there is any need for payload update or further assertion
        vars = _stage2_run_src_action(action, multiSuperformsData, singleSuperformsData, vars);
        console.log("Stage 2 complete");
        console.log("C");
        /*
        /// @dev simulation of cross-chain message delivery (for x-chain actions) (With no assertions)
        aV = _stage3_src_to_dst_amb_delivery(action, vars, multiSuperformsData, singleSuperformsData);
        console.log("Stage 3 complete");


        /// @dev processing of message delivery on destination   (for x-chain actions)
        success = _stage4_process_src_dst_payload(action, vars, aV, singleSuperformsData, act);
        if (!success) {
            console.log("Stage 4 failed");
            return;
        } else if (action.action == Actions.Withdraw && action.testType == TestType.Pass) {
            console.log("Stage 4 complete");
        }
        console.log("B");
        console.log("C");

        /*
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
            }
        }

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
            } else {
                console.log("Stage 6 complete");
            }
        }

        /// @dev stage 7 and 8 are only required for timelocked forms, but also including direct chain actions
        if (action.action == Actions.Withdraw) {
            _stage7_finalize_timelocked_payload(vars);

            console.log("Stage 7 complete");
        }

        if (action.action == Actions.Withdraw) {
        /// @dev Process payload received on source from destination (withdraw callback, for failed withdraws)
            _stage8_process_failed_timelocked_xchain_remint(action, vars);

            console.log("Stage 8 complete");
        }

        delete revertingDepositSFs;
        delete revertingWithdrawSFs;
        delete revertingWithdrawTimelockedSFs;
        delete sameChainDstHasRevertingVault;
        delete actualAmountWithdrawnPerDst;
        sameChainDstHasRevertingVault = false;
        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            delete countTimelocked[i];
            delete TX_DATA_TO_UPDATE_ON_DST[DST_CHAINS[i]];
        }
        MULTI_TX_SLIPPAGE_SHARE = 0;
               */
    }

    function _stage3_src_to_dst_amb_delivery(
        TestAction memory action,
        StagesLocalVars memory vars,
        MultiVaultSFData[] memory multiSuperformsData,
        SingleVaultSFData[] memory singleSuperformsData
    )
        internal
        override
        returns (MessagingAssertVars[] memory)
    {
        Stage3InternalVars memory internalVars;

        for (uint256 i = 0; i < vars.nDestinations; i++) {
            console.log("usedDSTs[DST_CHAINS[i]].payloadNumber", usedDSTs[DST_CHAINS[i]].payloadNumber);

            /// @dev if payloadNumber is = 0 still it means uniqueDst has not been found yet (1 repetition)
            if (usedDSTs[DST_CHAINS[i]].payloadNumber == 0) {
                console.log("START HERE");
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

        console.log("vars.nUniqueDsts", vars.nUniqueDsts);

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

        /// @dev assert good delivery of message on destination by analyzing superformIds and mounts
        for (uint256 i = 0; i < vars.nDestinations; i++) {
            aV[i].toChainId = DST_CHAINS[i];
            if (CHAIN_0 != aV[i].toChainId && !sameChainDstHasRevertingVault) {
                if (action.multiVaults) {
                    aV[i].expectedMultiVaultsData = multiSuperformsData[i];
                } else {
                    aV[i].expectedSingleVaultData = singleSuperformsData[i];
                }
            }
        }

        return aV;
    }
}

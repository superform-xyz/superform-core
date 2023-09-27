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
                deal(token, users[action.user], TOTAL_SUPPLY_USDT);
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

        for (uint256 i = 0; i < vars.nDestinations; ++i) {
            delete countTimelocked[i];
            delete TX_DATA_TO_UPDATE_ON_DST[DST_CHAINS[i]];
        }
        MULTI_TX_SLIPPAGE_SHARE = 0;
    }

    function _getSuperpositionsForDstChainFromSrcChain(
        uint256 user_,
        uint256[] memory underlyingTokens_,
        uint256[] memory vaultIds_,
        uint32[] memory formKinds_,
        uint64 srcChain_,
        uint64 dstChain_
    )
        internal
        returns (uint256[] memory superPositionBalances)
    {
        uint256[] memory superformIds = _superformIds(underlyingTokens_, vaultIds_, formKinds_, dstChain_);
        address superRegistryAddress = getContract(srcChain_, "SuperRegistry");
        vm.selectFork(FORKS[srcChain_]);

        superPositionBalances = new uint256[](superformIds.length);
        address superPositionsAddress =
            ISuperRegistry(superRegistryAddress).getAddress(ISuperRegistry(superRegistryAddress).SUPER_POSITIONS());

        IERC1155A superPositions = IERC1155A(superPositionsAddress);

        console.log("superformIds", superformIds.length);
        for (uint256 i = 0; i < superformIds.length; i++) {
            superPositionBalances[i] = superPositions.balanceOf(users[user_], superformIds[i]);
        }
    }
}

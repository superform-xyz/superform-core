/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "../../utils/ProtocolActions.sol";
import "forge-std/Test.sol";
import "../VaultShares.invariant.t.sol";

contract VaultSharesHandler is ProtocolActions {
    // constructor() {
    //     super.setUp();
    // }

    function singleDirectSingleVaultDeposit() public {
        AMBs = [2, 3];
        CHAIN_0 = AVAX;
        DST_CHAINS = [AVAX];
        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [2];
        TARGET_VAULTS[AVAX][0] = [0];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[AVAX][0] = [0];
        MAX_SLIPPAGE = 1000;
        LIQ_BRIDGES[AVAX][0] = [0];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 999, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        AMOUNTS[AVAX][0] = [8_000_000];

        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }

        actions.pop();
        console.log("dep");
    }

    function singleDirectSingleVaultWithdraw() public {
        AMBs = [2, 3];
        CHAIN_0 = ETH;
        DST_CHAINS = [ETH];
        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ETH][0] = [2];
        TARGET_VAULTS[ETH][0] = [0];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ETH][0] = [0];
        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ETH][1] = [2];
        TARGET_VAULTS[ETH][1] = [0];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ETH][1] = [0];
        MAX_SLIPPAGE = 1000;
        LIQ_BRIDGES[ETH][0] = [1];
        LIQ_BRIDGES[ETH][1] = [1];
        FINAL_LIQ_DST_WITHDRAW[ETH] = [ETH];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 421, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        actions.push(
            TestAction({
                action: Actions.Withdraw,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 421, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        AMOUNTS[ETH][0] = [9_000_000];

        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            if (act == 1) {
                for (uint256 i = 0; i < DST_CHAINS.length; i++) {
                    uint256[] memory superPositions = _getSuperpositionsForDstChain(
                        actions[1].user,
                        TARGET_UNDERLYINGS[DST_CHAINS[i]][1],
                        TARGET_VAULTS[DST_CHAINS[i]][1],
                        TARGET_FORM_KINDS[DST_CHAINS[i]][1],
                        DST_CHAINS[i]
                    );

                    AMOUNTS[DST_CHAINS[i]][1] = [superPositions[0]];
                }
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
            console.log("depwith");
        }
        actions.pop();
        actions.pop();
    }

    function singleXChainRescueFailedDeposit() public {
        AMBs = [1, 3];

        CHAIN_0 = OP;
        DST_CHAINS = [POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[POLY][0] = [2];
        TARGET_VAULTS[POLY][0] = [3];
        /// @dev vault index 3 is failedDepositMock, check VAULT_KINDS
        TARGET_FORM_KINDS[POLY][0] = [0];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][1] = [2];
        TARGET_VAULTS[OP][1] = [3];
        /// @dev vault index 3 is failedDepositMock, check VAULT_KINDS
        TARGET_FORM_KINDS[OP][1] = [0];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[POLY][0] = [1];
        LIQ_BRIDGES[OP][1] = [1];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.RevertProcessPayload,
                revertError: "",
                revertRole: "",
                slippage: 312, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        actions.push(
            TestAction({
                action: Actions.RescueFailedDeposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 312, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        AMOUNTS[POLY][0] = [7_000_000];
        /// @dev specifying the amount that was deposited earlier, as the amount to be rescued
        AMOUNTS[POLY][1] = [7_000_000];

        for (uint256 act; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;
            if (action.action == Actions.RescueFailedDeposit) _rescueFailedDeposits(action, act);
            else _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
    }
}

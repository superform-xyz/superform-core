/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDSVWNormal4626NativeSlippageAMB23 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [2, 3];
        MultiDstAMBs = [AMBs, AMBs];

        CHAIN_0 = POLY;
        DST_CHAINS = [OP, AVAX];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][0] = [0];
        TARGET_UNDERLYINGS[AVAX][0] = [2];

        TARGET_VAULTS[OP][0] = [0];

        /// @dev id 0 is normal 4626
        TARGET_VAULTS[AVAX][0] = [0];
        /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[OP][0] = [0];
        TARGET_FORM_KINDS[AVAX][0] = [0];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][1] = [0];
        TARGET_UNDERLYINGS[AVAX][1] = [2];

        TARGET_VAULTS[OP][1] = [0];

        /// @dev id 0 is normal 4626
        TARGET_VAULTS[AVAX][1] = [0];
        /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[OP][1] = [0];
        TARGET_FORM_KINDS[AVAX][1] = [0];

        PARTIAL[OP][1] = [true];
        PARTIAL[AVAX][1] = [true];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[OP][0] = [1];
        LIQ_BRIDGES[OP][1] = [1];

        LIQ_BRIDGES[AVAX][0] = [1];
        LIQ_BRIDGES[AVAX][1] = [1];

        FINAL_LIQ_DST_WITHDRAW[OP] = [POLY];
        FINAL_LIQ_DST_WITHDRAW[AVAX] = [POLY];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 743, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
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
                slippage: 743, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(
        uint128 amountOne_,
        uint128 amountOneWithdraw_,
        uint128 amountTwo_,
        uint128 /*amountTwoWithdraw_*/
    )
        public
    {
        amountOne_ = uint128(bound(amountOne_, 11, TOTAL_SUPPLY_ETH / 2));
        amountTwo_ = uint128(bound(amountTwo_, 11, TOTAL_SUPPLY_ETH / 2));

        AMOUNTS[OP][0] = [amountOne_];
        AMOUNTS[AVAX][0] = [amountTwo_];

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

                    /// @dev bounded to 1 less due to partial withdrawals
                    amountOneWithdraw_ = uint128(bound(amountOneWithdraw_, 1, superPositions[0] - 1));
                    AMOUNTS[DST_CHAINS[i]][1] = [amountOneWithdraw_];
                }
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
    }
}

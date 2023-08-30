/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SDiMVW142TokenInputSlippageL1AMB12 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/

        AMBs = [1, 3];

        CHAIN_0 = AVAX;
        DST_CHAINS = [AVAX];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [1, 1, 1];
        TARGET_VAULTS[AVAX][0] = [1, 4, 2];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[AVAX][0] = [1, 1, 2];

        TARGET_UNDERLYINGS[AVAX][1] = [1, 1, 1];
        TARGET_VAULTS[AVAX][1] = [1, 4, 2];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[AVAX][1] = [1, 1, 2];

        PARTIAL[AVAX][1] = [true, false, true];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[AVAX][0] = [1, 1, 1];
        LIQ_BRIDGES[AVAX][1] = [1, 1, 1];

        FINAL_LIQ_DST_WITHDRAW[AVAX] = [AVAX, AVAX, AVAX];

        /// @dev push in order the actions should be executed
        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 86, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: true,
                externalToken: 1 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        actions.push(
            TestAction({
                action: Actions.Withdraw,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 86, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                externalToken: 1 // 0 = DAI, 1 = USDT, 2 = WETH
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
        uint128 amountThree_,
        uint128 amountThreeWithdraw_
    )
        public
    {
        /// @dev min amountOne_ and amountThree_ need to be 3 as their withdraw amount >= 2
        amountOne_ = uint128(bound(amountOne_, 3, TOTAL_SUPPLY_USDT / 3));
        amountTwo_ = uint128(bound(amountTwo_, 2, TOTAL_SUPPLY_USDT / 3));
        amountThree_ = uint128(bound(amountThree_, 3, TOTAL_SUPPLY_USDT / 3));
        AMOUNTS[AVAX][0] = [amountOne_, amountTwo_, amountThree_];

        /// @dev bound to amountOne_ - 1 as partial is true for first vault
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amountOneWithdraw_ = uint128(bound(amountOneWithdraw_, 2, amountOne_ - 1));
        /// @dev bound to amountThree_ - 1 as partial is true for third vault
        amountThreeWithdraw_ = uint128(bound(amountThreeWithdraw_, 2, amountThree_ - 1));
        AMOUNTS[AVAX][1] = [amountOneWithdraw_, amountTwo_, amountThreeWithdraw_];

        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
    }
}

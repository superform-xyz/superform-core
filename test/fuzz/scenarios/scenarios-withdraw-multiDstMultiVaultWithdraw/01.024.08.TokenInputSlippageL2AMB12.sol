/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDMVW0102408NativeInputSlipapgeL2AMB12 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev singleDestinationMultiVault, large test

        AMBs = [1, 2];
        MultiDstAMBs = [AMBs, AMBs, AMBs];

        CHAIN_0 = ETH;
        DST_CHAINS = [ETH, POLY, AVAX];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        /// first 3 superforms are equal
        TARGET_UNDERLYINGS[ETH][0] = [2, 2];
        TARGET_VAULTS[ETH][0] = [0, 1];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ETH][0] = [0, 1];

        /// all superforms are different
        TARGET_UNDERLYINGS[POLY][0] = [0, 1, 2];
        TARGET_VAULTS[POLY][0] = [0, 2, 4];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[POLY][0] = [0, 2, 1];

        /// all superforms are different
        TARGET_UNDERLYINGS[AVAX][0] = [2, 2];
        TARGET_VAULTS[AVAX][0] = [0, 8];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[AVAX][0] = [0, 0];

        TARGET_UNDERLYINGS[ETH][1] = [2, 2];
        TARGET_VAULTS[ETH][1] = [0, 1];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ETH][1] = [0, 1];

        /// all superforms are different
        TARGET_UNDERLYINGS[POLY][1] = [0, 1, 2];
        TARGET_VAULTS[POLY][1] = [0, 2, 4];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[POLY][1] = [0, 2, 1];

        /// all superforms are different
        TARGET_UNDERLYINGS[AVAX][1] = [2, 2];
        TARGET_VAULTS[AVAX][1] = [0, 8];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[AVAX][1] = [0, 0];

        PARTIAL[ETH][1] = [true, false];

        PARTIAL[POLY][1] = [false, false, true];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ETH][0] = [2, 2, 2, 2];
        LIQ_BRIDGES[ETH][1] = [2, 2, 2, 2];

        LIQ_BRIDGES[POLY][0] = [2, 2, 2, 2];
        LIQ_BRIDGES[POLY][1] = [2, 2, 2, 2];

        LIQ_BRIDGES[AVAX][0] = [2, 2, 2, 2];
        LIQ_BRIDGES[AVAX][1] = [2, 2, 2, 2];

        FINAL_LIQ_DST_WITHDRAW[ETH] = [ETH, ETH, ETH, ETH];
        FINAL_LIQ_DST_WITHDRAW[POLY] = [ETH, ETH, ETH, ETH];
        FINAL_LIQ_DST_WITHDRAW[AVAX] = [ETH, ETH, ETH, ETH];

        /// @dev push in order the actions should be executed
        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 1,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 643, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: true,
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        actions.push(
            TestAction({
                action: Actions.Withdraw,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 1,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 643, // 0% <- if we are testing a pass this must be below each maxSlippage,
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
        uint128 amountThree_
    )
        public
    {
        /// @dev min amountOne_ needs to be 3 as its withdraw amount >= 2
        /// @dev 7 => 2 * amountOne_ + 3 * amountTwo_ + 2 * amountThree_ during deposits
        amountOne_ = uint128(bound(amountOne_, 3, TOTAL_SUPPLY_ETH / 7));
        amountTwo_ = uint128(bound(amountTwo_, 2, TOTAL_SUPPLY_ETH / 7));
        amountThree_ = uint128(bound(amountThree_, 2, TOTAL_SUPPLY_ETH / 7));

        /// @dev bound to amountOne_ - 1 as partial is true for first vault
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amountOneWithdraw_ = uint128(bound(amountOneWithdraw_, 2, amountOne_ - 1));

        /// @dev notice partial withdrawals in ETH->0 and POLY->2
        AMOUNTS[ETH][0] = [amountOne_, amountTwo_];
        AMOUNTS[ETH][1] = [amountOneWithdraw_, amountTwo_];

        AMOUNTS[POLY][0] = [amountTwo_, amountThree_, amountOne_];
        AMOUNTS[POLY][1] = [amountTwo_, amountThree_, amountOneWithdraw_];

        /// @dev shuffled order of amounts to randomise
        AMOUNTS[AVAX][0] = [amountThree_, amountTwo_];
        AMOUNTS[AVAX][1] = [amountThree_, amountTwo_];

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

/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SDMVW0TokenInputNoSlippageL2AMB13 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/

        AMBs = [1, 3];

        CHAIN_0 = POLY;
        DST_CHAINS = [ARBI];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ARBI][0] = [1];
        TARGET_VAULTS[ARBI][0] = [0];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ARBI][0] = [0];

        TARGET_UNDERLYINGS[ARBI][1] = [1];
        TARGET_VAULTS[ARBI][1] = [0];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ARBI][1] = [0];

        PARTIAL[ARBI][1] = [true];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ARBI][0] = [1];
        LIQ_BRIDGES[ARBI][1] = [1];

        FINAL_LIQ_DST_WITHDRAW[ARBI] = [POLY];

        /// @dev push in order the actions should be executed
        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
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
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_, uint128 amountTwo_) public {
        amountOne_ = uint128(bound(amountOne_, 2, TOTAL_SUPPLY_USDT));
        AMOUNTS[ARBI][0] = [amountOne_];
        /// @dev partial is true
        amountTwo_ = uint128(bound(amountTwo_, 1, amountOne_ - 1));
        AMOUNTS[ARBI][1] = [amountTwo_];

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

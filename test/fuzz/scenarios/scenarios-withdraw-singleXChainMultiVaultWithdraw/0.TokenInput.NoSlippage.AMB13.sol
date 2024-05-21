// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SDMVW0TokenInputNoSlippageAMB1323 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/

        AMBs = [1, 3];

        CHAIN_0 = POLY;
        DST_CHAINS = [AVAX];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [1];
        TARGET_VAULTS[AVAX][0] = [0];

        TARGET_FORM_KINDS[AVAX][0] = [0];

        TARGET_UNDERLYINGS[AVAX][1] = [1];
        TARGET_VAULTS[AVAX][1] = [0];
        

        TARGET_FORM_KINDS[AVAX][1] = [0];

        PARTIAL[AVAX][1] = [true];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[AVAX][0] = [1];
        LIQ_BRIDGES[AVAX][1] = [1];

        RECEIVE_4626[AVAX][0] = [false];
        RECEIVE_4626[AVAX][1] = [false];

        FINAL_LIQ_DST_WITHDRAW[AVAX] = [POLY];

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
                dstSwap: false,
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
                dstSwap: false,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_, uint128 amountTwo_) public {
        amountOne_ = uint128(bound(amountOne_, 2 * 10 ** 6, TOTAL_SUPPLY_USDC));
        AMOUNTS[AVAX][0] = [amountOne_];
        /// @dev partial is true
        amountTwo_ = uint128(bound(amountTwo_, 10, amountOne_ - 1));
        AMOUNTS[AVAX][1] = [amountTwo_];

        for (uint256 act = 0; act < actions.length; ++act) {
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

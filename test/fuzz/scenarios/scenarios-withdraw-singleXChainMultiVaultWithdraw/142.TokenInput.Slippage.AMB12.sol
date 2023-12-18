// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SDMVW142TokenInputSlippageAMB12 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/

        AMBs = [1, 3];

        CHAIN_0 = ETH;
        DST_CHAINS = [AVAX];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [1, 1, 2];
        TARGET_VAULTS[AVAX][0] = [1, 4, 1];
        TARGET_FORM_KINDS[AVAX][0] = [1, 1, 1];

        TARGET_UNDERLYINGS[AVAX][1] = [1, 1, 2];
        TARGET_VAULTS[AVAX][1] = [1, 4, 1];
        TARGET_FORM_KINDS[AVAX][1] = [1, 1, 1];

        PARTIAL[AVAX][1] = [true, false, false];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[AVAX][0] = [1, 1, 1];
        LIQ_BRIDGES[AVAX][1] = [1, 1, 1];

        RECEIVE_4626[AVAX][0] = [false, false, false];
        RECEIVE_4626[AVAX][1] = [false, false, false];

        FINAL_LIQ_DST_WITHDRAW[AVAX] = [ETH, ETH, ETH];

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
                slippage: 86, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
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
        amountOne_ = uint128(bound(amountOne_, 12 * 10 ** 6, TOTAL_SUPPLY_USDC / 3));
        amountTwo_ = uint128(bound(amountTwo_, 11 * 10 ** 6, TOTAL_SUPPLY_USDC / 3));
        amountThree_ = uint128(bound(amountThree_, 12 * 10 ** 6, TOTAL_SUPPLY_USDC / 3));

        AMOUNTS[AVAX][0] = [amountOne_, amountTwo_, amountThree_];

        for (uint256 act = 0; act < actions.length; ++act) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            if (act == 1) {
                uint256[] memory superPositions = _getSuperpositionsForDstChain(
                    actions[1].user,
                    TARGET_UNDERLYINGS[DST_CHAINS[0]][1],
                    TARGET_VAULTS[DST_CHAINS[0]][1],
                    TARGET_FORM_KINDS[DST_CHAINS[0]][1],
                    DST_CHAINS[0]
                );

                /// @dev bound to 1 less as partial is true for first vault
                /// @dev amount = 1 after slippage will become 0, hence starting with 2
                amountOneWithdraw_ = uint128(bound(amountOneWithdraw_, 2, superPositions[0] - 1));

                AMOUNTS[AVAX][1] = [amountOneWithdraw_, superPositions[1], superPositions[2]];
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
    }
}

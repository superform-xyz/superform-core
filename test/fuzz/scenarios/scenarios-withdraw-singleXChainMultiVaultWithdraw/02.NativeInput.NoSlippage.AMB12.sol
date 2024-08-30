// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SDMVW02NativeInputNoSlippageAMB12 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/

        AMBs = [1, 2];

        CHAIN_0 = AVAX;
        DST_CHAINS = [OP];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][0] = [1, 2];
        TARGET_VAULTS[OP][0] = [0, 0];

        TARGET_FORM_KINDS[OP][0] = [0, 0];

        TARGET_UNDERLYINGS[OP][1] = [1, 2];
        TARGET_VAULTS[OP][1] = [0, 0];

        TARGET_FORM_KINDS[OP][1] = [0, 0];

        PARTIAL[OP][1] = [false, true];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[OP][0] = [1, 1];
        LIQ_BRIDGES[OP][1] = [1, 1];

        RECEIVE_4626[OP][0] = [false, false];
        RECEIVE_4626[OP][1] = [false, false];

        GENERATE_WITHDRAW_TX_DATA_ON_DST = true;

        FINAL_LIQ_DST_WITHDRAW[OP] = [AVAX, AVAX];

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
                externalToken: 69_420 // 0 = DAI, 1 = USDT, 2 = WETH
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
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_, uint128 amountTwo_, uint128 amountTwoWithdraw_) public {
        amountOne_ = uint128(bound(amountOne_, 1 * 10 ** 18, TOTAL_SUPPLY_ETH / 3));
        amountTwo_ = uint128(bound(amountTwo_, 2 * 10 ** 18, TOTAL_SUPPLY_ETH / 3));
        AMOUNTS[OP][0] = [amountOne_, amountTwo_];

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
                /// @dev bound to amountTwo_ - 1 as partial is true for second vault
                amountTwoWithdraw_ = uint128(bound(amountTwoWithdraw_, 10, superPositions[1] - 1));
                AMOUNTS[OP][1] = [superPositions[0], amountTwoWithdraw_];
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
    }
}

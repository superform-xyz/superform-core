// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDSVW10NativeSlippageAMB23 is ProtocolActions {
    function setUp() public override {
        chainIds = [ETH, ARBI, OP, AVAX];

        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [2, 3];
        MultiDstAMBs = [AMBs, AMBs];

        CHAIN_0 = AVAX;
        DST_CHAINS = [OP, ARBI];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][0] = [2];
        TARGET_UNDERLYINGS[ARBI][0] = [1];

        TARGET_VAULTS[OP][0] = [0];
        TARGET_VAULTS[ARBI][0] = [0];

        TARGET_FORM_KINDS[OP][0] = [0];
        TARGET_FORM_KINDS[ARBI][0] = [0];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][1] = [2];
        TARGET_UNDERLYINGS[ARBI][1] = [1];

        TARGET_VAULTS[OP][1] = [0];
        TARGET_VAULTS[ARBI][1] = [0];

        TARGET_FORM_KINDS[OP][1] = [0];
        TARGET_FORM_KINDS[ARBI][1] = [0];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[OP][0] = [1];
        LIQ_BRIDGES[OP][1] = [1];

        LIQ_BRIDGES[ARBI][0] = [1];
        LIQ_BRIDGES[ARBI][1] = [2];

        RECEIVE_4626[OP][0] = [false];
        RECEIVE_4626[OP][1] = [false];

        RECEIVE_4626[ARBI][0] = [false];
        RECEIVE_4626[ARBI][1] = [false];

        FINAL_LIQ_DST_WITHDRAW[OP] = [AVAX];
        FINAL_LIQ_DST_WITHDRAW[ARBI] = [AVAX];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 124, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
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
                slippage: 124, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 1 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_, uint128 amountTwo_) public {
        amountOne_ = uint128(bound(amountOne_, 11 * 10 ** 18, TOTAL_SUPPLY_WETH / 2));
        amountTwo_ = uint128(bound(amountTwo_, 11 * 10 ** 18, TOTAL_SUPPLY_WETH / 2));

        AMOUNTS[OP][0] = [amountOne_];
        AMOUNTS[ARBI][0] = [amountTwo_];

        for (uint256 act = 0; act < actions.length; ++act) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            if (act == 1) {
                for (uint256 i = 0; i < DST_CHAINS.length; ++i) {
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
        }
    }
}

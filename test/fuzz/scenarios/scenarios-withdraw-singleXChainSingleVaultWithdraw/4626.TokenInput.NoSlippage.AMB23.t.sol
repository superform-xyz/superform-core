// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SXSVWNormal4626NativeNoSlippageAMB23 is ProtocolActions {
    function setUp() public override {
        chainIds = [ETH, ARBI, AVAX];

        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [2, 3];

        CHAIN_0 = ARBI; // 4
        DST_CHAINS = [AVAX]; // 2

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [1];

        TARGET_VAULTS[AVAX][0] = [0];

        TARGET_FORM_KINDS[AVAX][0] = [0];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][1] = [1];

        TARGET_VAULTS[AVAX][1] = [0];

        TARGET_FORM_KINDS[AVAX][1] = [0];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[AVAX][0] = [1];
        LIQ_BRIDGES[AVAX][1] = [1];

        RECEIVE_4626[AVAX][0] = [false];
        RECEIVE_4626[AVAX][1] = [false];

        FINAL_LIQ_DST_WITHDRAW[AVAX] = [ARBI];

        /// @dev push in order the actions should be executed
        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
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
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_) public {
        amountOne_ = uint128(bound(amountOne_, 2 * 10 ** 18, TOTAL_SUPPLY_DAI));
        AMOUNTS[AVAX][0] = [amountOne_];

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

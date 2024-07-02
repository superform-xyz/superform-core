// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SXSVW7540WithdrawAsyncNativeRevertingDstSwapSlippageAMB23 is ProtocolActions {
    function setUp() public override {
        super.setUp();

        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/
        AMBs = [1, 3];

        CHAIN_0 = ETH;
        DST_CHAINS = [ARBI];

        TARGET_UNDERLYINGS[ARBI][0] = [4];

        TARGET_VAULTS[ARBI][0] = [14];

        TARGET_FORM_KINDS[ARBI][0] = [4];

        TARGET_UNDERLYINGS[ARBI][1] = [4];

        TARGET_VAULTS[ARBI][1] = [14];

        TARGET_FORM_KINDS[ARBI][1] = [4];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ARBI][0] = [2];
        LIQ_BRIDGES[ARBI][1] = [2];

        RECEIVE_4626[ARBI][0] = [false];
        RECEIVE_4626[ARBI][1] = [false];

        GENERATE_WITHDRAW_TX_DATA_ON_DST = true;

        FINAL_LIQ_DST_WITHDRAW[ARBI] = [ETH];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 44, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: true,
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
                slippage: 22, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_) public {
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amountOne_ = uint128(bound(amountOne_, 2e18, 10e18));
        AMOUNTS[ARBI][0] = [amountOne_];

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

                AMOUNTS[ARBI][1] = [superPositions[0]];
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
    }
}

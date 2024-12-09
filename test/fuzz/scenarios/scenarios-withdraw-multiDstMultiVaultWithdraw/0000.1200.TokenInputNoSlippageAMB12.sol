// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils

import "../../../utils/ProtocolActions.sol";

contract MDMVW00001200TokenInputSlippageAMB12 is ProtocolActions {
    function setUp() public override {
        chainIds = [ETH, ARBI, POLY];

        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev singleDestinationMultiVault, large test

        AMBs = [1, 2];
        MultiDstAMBs = [AMBs, AMBs];

        CHAIN_0 = ETH;
        DST_CHAINS = [ARBI, POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        /// first 3 superforms are equal
        TARGET_UNDERLYINGS[ARBI][0] = [2, 0];
        TARGET_VAULTS[ARBI][0] = [0, 0];
        TARGET_FORM_KINDS[ARBI][0] = [0, 0];

        TARGET_UNDERLYINGS[ARBI][1] = [2, 0];
        TARGET_VAULTS[ARBI][1] = [0, 0];
        TARGET_FORM_KINDS[ARBI][1] = [0, 0];

        /// all superforms are different
        TARGET_UNDERLYINGS[POLY][0] = [0, 2];
        TARGET_VAULTS[POLY][0] = [0, 0];
        TARGET_FORM_KINDS[POLY][0] = [0, 0];

        TARGET_UNDERLYINGS[POLY][1] = [0, 2];
        TARGET_VAULTS[POLY][1] = [0, 0];
        TARGET_FORM_KINDS[POLY][1] = [0, 0];

        /// @dev first 3 vaults are equal, we mark them all as partial, even if only 1 amount is partial, otherwise
        /// assertions do not pass
        PARTIAL[ARBI][1] = [true, true];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ARBI][0] = [1, 1];
        LIQ_BRIDGES[ARBI][1] = [1, 1];

        LIQ_BRIDGES[POLY][0] = [1, 1];
        LIQ_BRIDGES[POLY][1] = [1, 1];

        RECEIVE_4626[ARBI][0] = [false, false];
        RECEIVE_4626[ARBI][1] = [false, false];

        RECEIVE_4626[POLY][0] = [false, false];
        RECEIVE_4626[POLY][1] = [false, false];

        FINAL_LIQ_DST_WITHDRAW[ARBI] = [ETH, ETH];
        FINAL_LIQ_DST_WITHDRAW[POLY] = [ETH, ETH];

        /// @dev push in order the actions should be executed
        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 1,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 222, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
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
                slippage: 222, // 0% <- if we are testing a pass this must be below each maxSlippage,
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
        uint128 amountTwoWithdraw_
    )
        public
    {
        /// @dev min amountOne_ and amountThree_ need to be 3 as their withdraw amount >= 2
        amountOne_ = uint128(bound(amountOne_, 2e6, 2e10));
        amountTwo_ = uint128(bound(amountTwo_, 2e6, 2e10));

        AMOUNTS[ARBI][0] = [amountOne_, amountTwo_];
        AMOUNTS[POLY][0] = [amountOne_, amountOne_];

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

                    /// @dev superPostions[0] = superPositions[1] = superPositions[2] for ARBI (as it's the same
                    /// superform)
                    amountOneWithdraw_ = uint128(bound(amountOneWithdraw_, 0.1e6, (superPositions[0] / 3) + 1));
                    amountTwoWithdraw_ = uint128(bound(amountTwoWithdraw_, 0.1e6, (superPositions[1] / 3) + 1));

                    if (PARTIAL[DST_CHAINS[i]][1].length > 0) {
                        AMOUNTS[DST_CHAINS[i]][1] = [amountOneWithdraw_, amountTwoWithdraw_];
                    } else {
                        AMOUNTS[DST_CHAINS[i]][1] = [superPositions[0], superPositions[1]];
                    }
                }
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
    }
}

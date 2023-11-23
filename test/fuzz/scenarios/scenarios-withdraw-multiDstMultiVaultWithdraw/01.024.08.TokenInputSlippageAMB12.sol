/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDMVW0102408NativeInputSlippageAMB12 is ProtocolActions {
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

        TARGET_FORM_KINDS[ETH][0] = [0, 1];

        /// all superforms are different
        TARGET_UNDERLYINGS[POLY][0] = [0, 1, 2];
        TARGET_VAULTS[POLY][0] = [0, 1, 4];

        TARGET_FORM_KINDS[POLY][0] = [0, 1, 1];

        /// all superforms are different
        TARGET_UNDERLYINGS[AVAX][0] = [2, 2];
        TARGET_VAULTS[AVAX][0] = [0, 8];

        TARGET_FORM_KINDS[AVAX][0] = [0, 0];

        TARGET_UNDERLYINGS[ETH][1] = [2, 2];
        TARGET_VAULTS[ETH][1] = [0, 1];

        TARGET_FORM_KINDS[ETH][1] = [0, 1];

        /// all superforms are different
        TARGET_UNDERLYINGS[POLY][1] = [0, 1, 2];
        TARGET_VAULTS[POLY][1] = [0, 1, 4];

        TARGET_FORM_KINDS[POLY][1] = [0, 1, 1];

        /// all superforms are different
        TARGET_UNDERLYINGS[AVAX][1] = [2, 2];
        TARGET_VAULTS[AVAX][1] = [0, 8];

        TARGET_FORM_KINDS[AVAX][1] = [0, 0];

        PARTIAL[ETH][1] = [true, false];

        PARTIAL[POLY][1] = [false, false, true];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ETH][0] = [1, 1, 1, 1];
        LIQ_BRIDGES[ETH][1] = [1, 1, 1, 1];

        LIQ_BRIDGES[POLY][0] = [1, 1, 1, 1];
        LIQ_BRIDGES[POLY][1] = [1, 1, 1, 1];

        LIQ_BRIDGES[AVAX][0] = [1, 1, 1, 1];
        LIQ_BRIDGES[AVAX][1] = [1, 1, 1, 1];

        RECEIVE_4626[ETH][0] = [false, false, false, false];
        RECEIVE_4626[ETH][1] = [false, false, false, false];

        RECEIVE_4626[POLY][0] = [false, false, false, false];
        RECEIVE_4626[POLY][1] = [false, false, false, false];

        RECEIVE_4626[AVAX][0] = [false, false, false, false];
        RECEIVE_4626[AVAX][1] = [false, false, false, false];

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
                dstSwap: false,
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
        amountOne_ = uint128(bound(amountOne_, 12e18, 20e18));
        amountTwo_ = uint128(bound(amountTwo_, 11e18, 20e18));
        amountThree_ = uint128(bound(amountThree_, 11e18, 20e18));

        AMOUNTS[ETH][0] = [amountOne_, amountTwo_];
        AMOUNTS[POLY][0] = [amountTwo_, amountThree_, amountOne_];
        /// @dev shuffled order of amounts to randomise
        AMOUNTS[AVAX][0] = [amountThree_, amountTwo_];

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

                    /// @dev notice partial withdrawals in ETH->0 and POLY->2
                    if (DST_CHAINS[i] == ETH) {
                        amountOneWithdraw_ = uint128(bound(amountOneWithdraw_, 1, superPositions[0] - 1));
                        AMOUNTS[DST_CHAINS[i]][1] = [amountOneWithdraw_, superPositions[1]];
                    } else if (DST_CHAINS[i] == POLY) {
                        amountOneWithdraw_ = uint128(bound(amountOneWithdraw_, 1, superPositions[2] - 1));
                        AMOUNTS[POLY][1] = [superPositions[0], superPositions[1], amountOneWithdraw_];
                    } else if (DST_CHAINS[i] == AVAX) {
                        AMOUNTS[DST_CHAINS[i]][1] = [superPositions[0], superPositions[1]];
                    }
                }
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
    }
}

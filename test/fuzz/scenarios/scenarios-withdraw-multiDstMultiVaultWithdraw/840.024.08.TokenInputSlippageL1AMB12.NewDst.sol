/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDMVW84002408NativeInputSlipapgeL1AMB12NewDst is ProtocolActions {
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
        TARGET_UNDERLYINGS[ETH][0] = [2, 2, 1];
        TARGET_VAULTS[ETH][0] = [8, 4, 0];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ETH][0] = [0, 1, 0];

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

        TARGET_UNDERLYINGS[ETH][1] = [2, 2, 1];
        TARGET_VAULTS[ETH][1] = [8, 4, 0];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ETH][1] = [0, 1, 0];

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

        PARTIAL[ETH][1] = [true, false, false];

        PARTIAL[POLY][1] = [false, false, true];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ETH][0] = [1, 1, 1, 1];
        LIQ_BRIDGES[ETH][1] = [1, 1, 1, 1];

        LIQ_BRIDGES[POLY][0] = [1, 1, 1, 1];
        LIQ_BRIDGES[POLY][1] = [1, 1, 1, 1];

        LIQ_BRIDGES[AVAX][0] = [1, 1, 1, 1];
        LIQ_BRIDGES[AVAX][1] = [1, 1, 1, 1];

        FINAL_LIQ_DST_WITHDRAW[ETH] = [ETH, ARBI, OP, POLY];
        FINAL_LIQ_DST_WITHDRAW[POLY] = [POLY, ETH, ETH, ETH];
        FINAL_LIQ_DST_WITHDRAW[AVAX] = [ETH, AVAX, AVAX, ETH];

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
        amountOne_ = uint128(bound(amountOne_, 12, TOTAL_SUPPLY_ETH / 7));
        amountTwo_ = uint128(bound(amountTwo_, 11, TOTAL_SUPPLY_ETH / 7));
        amountThree_ = uint128(bound(amountThree_, 11, TOTAL_SUPPLY_ETH / 7));

        /// @dev notice partial withdrawals in ETH->0 and POLY->2
        AMOUNTS[ETH][0] = [amountOne_, amountTwo_, amountThree_];
        AMOUNTS[POLY][0] = [amountTwo_, amountThree_, amountOne_];
        /// @dev shuffled order of amounts to randomise
        AMOUNTS[AVAX][0] = [amountThree_, amountTwo_];

        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            if (act == 1) {
                for (uint256 i = 0; i < DST_CHAINS.length; i++) {
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
                        AMOUNTS[DST_CHAINS[i]][1] = [amountOneWithdraw_, superPositions[1], superPositions[2]];
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

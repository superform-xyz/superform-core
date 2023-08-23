/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../utils/ProtocolActions.sol";

contract SDMVW02NativeInputNoSlippageL2AMB12 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/

        AMBs = [1, 2];

        CHAIN_0 = AVAX;
        DST_CHAINS = [OP];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][0] = [2, 2];
        TARGET_VAULTS[OP][0] = [0, 2];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[OP][0] = [0, 2];

        TARGET_UNDERLYINGS[OP][1] = [2, 2];
        TARGET_VAULTS[OP][1] = [0, 2];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[OP][1] = [0, 2];

        AMOUNTS[OP][0] = [12, 21_312_312];
        AMOUNTS[OP][1] = [12, 2222];

        PARTIAL[OP][1] = [false, true];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[OP][0] = [2, 2, 2];
        LIQ_BRIDGES[OP][1] = [2, 2, 2];

        GENERATE_WITHDRAW_TX_DATA_ON_DST = true;

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
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
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
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario() public {
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

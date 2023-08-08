/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../utils/ProtocolActions.sol";

contract SDMVW142TokenInputSlippageL1AMB12 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/

        AMBs = [1, 3];

        CHAIN_0 = ETH;
        DST_CHAINS = [AVAX];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [1, 1, 1];
        TARGET_VAULTS[AVAX][0] = [1, 4, 2]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[AVAX][0] = [1, 1, 2];

        TARGET_UNDERLYINGS[AVAX][1] = [1, 1, 1];
        TARGET_VAULTS[AVAX][1] = [1, 4, 2]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[AVAX][1] = [1, 1, 2];

        AMOUNTS[AVAX][0] = [421412, 88888, 7777];
        AMOUNTS[AVAX][1] = [214, 88888, 777];

        PARTIAL[AVAX][1] = [true, false, true];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[AVAX][0] = [1, 1, 1];
        LIQ_BRIDGES[AVAX][1] = [1, 1, 1];

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
                multiTx: true,
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
                multiTx: false,
                externalToken: 1 // 0 = DAI, 1 = USDT, 2 = WETH
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

/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../utils/ProtocolActions.sol";

contract SXSVWRevertTimelockedNativeSlippage is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 2];

        CHAIN_0 = ARBI;
        DST_CHAINS = [ARBI];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ARBI][0] = [0];

        TARGET_VAULTS[ARBI][0] = [4]; /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[ARBI][0] = [1];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ARBI][1] = [0];

        TARGET_VAULTS[ARBI][1] = [4]; /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[ARBI][1] = [1];

        AMOUNTS[ARBI][0] = [111];
        AMOUNTS[ARBI][1] = [111];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[ARBI][0] = [2];
        LIQ_BRIDGES[ARBI][1] = [2];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 224, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
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
                slippage: 224, // 0% <- if we are testing a pass this must be below each maxSlippage,
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

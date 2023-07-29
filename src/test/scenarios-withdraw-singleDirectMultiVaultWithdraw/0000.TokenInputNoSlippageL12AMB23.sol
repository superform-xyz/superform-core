/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../utils/ProtocolActions.sol";

contract SDMVW0000TokenInputNoSlipapgeL12AMB23 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev singleDestinationMultiVault, large test

        AMBs = [3, 2];

        CHAIN_0 = ETH;
        DST_CHAINS = [ETH];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ETH][0] = [1, 1, 1, 0];
        TARGET_VAULTS[ETH][0] = [0, 0, 0, 0]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ETH][0] = [0, 0, 0, 0];

        TARGET_UNDERLYINGS[ETH][1] = [1, 1, 1, 0];
        TARGET_VAULTS[ETH][1] = [0, 0, 0, 0]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ETH][1] = [0, 0, 0, 0];

        AMOUNTS[ETH][0] = [7722, 11, 3, 54218];
        AMOUNTS[ETH][1] = [7722, 11, 3, 54218];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ETH][0] = [1, 2, 1, 2];
        LIQ_BRIDGES[ETH][1] = [1, 1, 2, 2];

        /// @dev push in order the actions should be executed
        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 1,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
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
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
            })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario() public {
        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperFormsData;
            SingleVaultSFData[] memory singleSuperFormsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            _runMainStages(action, act, multiSuperFormsData, singleSuperFormsData, aV, vars, success);
        }
    }
}

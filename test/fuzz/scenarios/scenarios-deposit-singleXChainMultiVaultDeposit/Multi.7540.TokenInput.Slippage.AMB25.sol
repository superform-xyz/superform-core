// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SDMVDMulti7540NoTokenInputSlippageAMB25 is ProtocolActions {
    function setUp() public override {
        chainIds = [ETH, OP];

        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/

        AMBs = [2, 5];

        CHAIN_0 = ETH;
        DST_CHAINS = [OP];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][0] = [2, 2, 4];

        TARGET_VAULTS[OP][0] = [0, 4, 3];

        TARGET_FORM_KINDS[OP][0] = [0, 2, 1];

        AMOUNTS[OP][0] = [214 * 10e18, 798 * 10e18, 55_312 * 10e18];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[OP][0] = [1, 1, 1];

        RECEIVE_4626[OP][0] = [false, false, false];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 512, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario() public {
        for (uint256 act; act < actions.length; ++act) {
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

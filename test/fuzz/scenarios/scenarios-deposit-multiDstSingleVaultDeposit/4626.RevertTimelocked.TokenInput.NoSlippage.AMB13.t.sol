/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDSVD4626RevertTimelockedNoTokenInputNoSlippageAMB24 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 3];
        MultiDstAMBs = [AMBs, AMBs, AMBs];

        CHAIN_0 = OP;
        DST_CHAINS = [ETH, ARBI, POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ETH][0] = [0];
        TARGET_UNDERLYINGS[ARBI][0] = [1];
        TARGET_UNDERLYINGS[POLY][0] = [2];

        TARGET_VAULTS[ETH][0] = [0];
        TARGET_VAULTS[ARBI][0] = [5];
        TARGET_VAULTS[POLY][0] = [5];

        TARGET_FORM_KINDS[ETH][0] = [0];
        TARGET_FORM_KINDS[ARBI][0] = [1];
        TARGET_FORM_KINDS[POLY][0] = [1];

        AMOUNTS[ETH][0] = [421];
        AMOUNTS[ARBI][0] = [666];
        AMOUNTS[POLY][0] = [22];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ETH][0] = [1];
        LIQ_BRIDGES[ARBI][0] = [1];
        LIQ_BRIDGES[POLY][0] = [1];

        /// if testing a revert, do we test the revert on the whole destination?
        /// to assert values, it is best to find the indexes that didn't revert

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
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH, 3 = NATIVE_TOKEN
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario() public {
        for (uint256 act; act < actions.length; act++) {
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

/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDSVD4626RevertTimelockedNativeNoSlippageAMB23 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [2, 3];
        MultiDstAMBs = [AMBs, AMBs, AMBs];

        CHAIN_0 = OP;
        DST_CHAINS = [ETH, ARBI];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ETH][0] = [0];
        TARGET_UNDERLYINGS[ARBI][0] = [1];

        TARGET_VAULTS[ETH][0] = [0];
        TARGET_VAULTS[ARBI][0] = [5];

        TARGET_FORM_KINDS[ETH][0] = [0];
        TARGET_FORM_KINDS[ARBI][0] = [1];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ETH][0] = [1];
        LIQ_BRIDGES[ARBI][0] = [1];

        RECEIVE_4626[ETH][0] = [false];
        RECEIVE_4626[ARBI][0] = [false];

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
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_, uint128 amountTwo_) public {
        amountOne_ = uint128(bound(amountOne_, 1e18, 5e18));
        amountTwo_ = uint128(bound(amountTwo_, 1e18, 5e18));
        AMOUNTS[ETH][0] = [amountOne_];
        AMOUNTS[ARBI][0] = [amountTwo_];

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SXSVDTimelocked2TokenInputSlippageAMB13 is ProtocolActions {
    function setUp() public override {
        chainIds = [ETH, BSC];

        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/
        AMBs = [1, 2];

        CHAIN_0 = BSC;
        DST_CHAINS = [ETH];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ETH][0] = [0];

        TARGET_VAULTS[ETH][0] = [1];

        TARGET_FORM_KINDS[ETH][0] = [1];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ETH][0] = [2];

        RECEIVE_4626[ETH][0] = [false];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 321, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 69_420 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amount_) public {
        /// @dev bounding to 0.9 of ETH SUPPLY coz user account (with 120m ETH) runs short of ETH
        amount_ = uint128(bound(amount_, 11 * 10 ** 18, (TOTAL_SUPPLY_ETH * 9) / 10));
        AMOUNTS[ETH][0] = [amount_];

        for (uint256 act = 0; act < actions.length; ++act) {
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

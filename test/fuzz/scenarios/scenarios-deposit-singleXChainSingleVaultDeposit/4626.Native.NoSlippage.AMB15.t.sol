// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SXSVDNormal4626NoNativeNoSlippageAMB15 is ProtocolActions {
    function setUp() public override {
        chainIds = [ETH, ARBI, POLY];

        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 5];

        CHAIN_0 = ARBI;
        DST_CHAINS = [POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[POLY][0] = [0];

        TARGET_VAULTS[POLY][0] = [0];

        TARGET_FORM_KINDS[POLY][0] = [0];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[POLY][0] = [2];

        RECEIVE_4626[POLY][0] = [false];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: true,
                externalToken: 69_420 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amount_) public {
        amount_ = uint128(bound(amount_, 1 * 10 ** 18, TOTAL_SUPPLY_ETH));
        AMOUNTS[POLY][0] = [amount_];

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

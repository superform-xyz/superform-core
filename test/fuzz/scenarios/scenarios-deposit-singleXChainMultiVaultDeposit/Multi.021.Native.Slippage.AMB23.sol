// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SDMVDMulti021NoNativeSlippageAMB23 is ProtocolActions {
    function setUp() public override {
        chainIds = [ETH, ARBI];

        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/

        AMBs = [3, 2];

        CHAIN_0 = ARBI;
        DST_CHAINS = [ETH];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ETH][0] = [1, 1, 1];

        TARGET_VAULTS[ETH][0] = [0, 1, 1];

        TARGET_FORM_KINDS[ETH][0] = [0, 1, 1];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ETH][0] = [2, 2, 1];

        RECEIVE_4626[ETH][0] = [false, false, false];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 777, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 69_420 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_, uint128 amountTwo_, uint128 amountThree_) public {
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amountOne_ = uint128(bound(amountOne_, 2 * 10 ** 18, TOTAL_SUPPLY_ETH / 3));
        amountTwo_ = uint128(bound(amountTwo_, 2 * 10 ** 18, TOTAL_SUPPLY_ETH / 3));
        amountThree_ = uint128(bound(amountThree_, 2 * 10 ** 18, TOTAL_SUPPLY_ETH / 3));
        AMOUNTS[ETH][0] = [amountOne_, amountTwo_, amountThree_];

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

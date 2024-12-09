// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDMVDMulti102115000NativeSlippageAMB13 is ProtocolActions {
    function setUp() public override {
        chainIds = [ETH, ARBI, AVAX, OP];

        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/

        AMBs = [1, 3];
        MultiDstAMBs = [AMBs, AMBs, AMBs];

        CHAIN_0 = OP;
        DST_CHAINS = [ARBI, ETH, AVAX];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ARBI][0] = [0, 1, 0];
        TARGET_UNDERLYINGS[ETH][0] = [1, 1, 0];
        TARGET_UNDERLYINGS[AVAX][0] = [1, 1, 0];

        TARGET_VAULTS[ARBI][0] = [0, 0, 0];
        TARGET_VAULTS[ETH][0] = [0, 0, 0];
        TARGET_VAULTS[AVAX][0] = [0, 0, 0];

        TARGET_FORM_KINDS[ARBI][0] = [0, 0, 0];
        TARGET_FORM_KINDS[ETH][0] = [0, 0, 0];
        TARGET_FORM_KINDS[AVAX][0] = [0, 0, 0];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ARBI][0] = [1, 1, 1];
        LIQ_BRIDGES[ETH][0] = [1, 1, 1];
        LIQ_BRIDGES[AVAX][0] = [1, 1, 1];

        RECEIVE_4626[ARBI][0] = [false, false, false];
        RECEIVE_4626[ETH][0] = [false, false, false];
        RECEIVE_4626[AVAX][0] = [false, false, false];

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
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_, uint128 amountTwo_, uint128 amountThree_) public {
        amountOne_ = uint128(bound(amountOne_, 11e18, 20e18));
        amountTwo_ = uint128(bound(amountTwo_, 11e18, 20e18));
        amountThree_ = uint128(bound(amountThree_, 1e18, 20e18));
        AMOUNTS[ARBI][0] = [amountOne_, amountTwo_, amountThree_];
        AMOUNTS[ETH][0] = [amountThree_, amountOne_, amountTwo_];
        AMOUNTS[AVAX][0] = [amountTwo_, amountThree_, amountOne_];

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

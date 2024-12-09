// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDSVDNormal4626NoNativeNoSlippageAMB12 is ProtocolActions {
    function setUp() public override {
        chainIds = [ETH, OP, AVAX, POLY];

        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 2];
        MultiDstAMBs = [AMBs, AMBs, AMBs];

        CHAIN_0 = OP;
        DST_CHAINS = [AVAX, ETH, POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [0];
        TARGET_UNDERLYINGS[ETH][0] = [0];
        TARGET_UNDERLYINGS[POLY][0] = [1];

        TARGET_VAULTS[AVAX][0] = [0];

        TARGET_VAULTS[ETH][0] = [0];

        TARGET_VAULTS[POLY][0] = [0];

        TARGET_FORM_KINDS[AVAX][0] = [0];
        TARGET_FORM_KINDS[ETH][0] = [0];
        TARGET_FORM_KINDS[POLY][0] = [0];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[AVAX][0] = [2];
        LIQ_BRIDGES[ETH][0] = [2];
        LIQ_BRIDGES[POLY][0] = [2];

        RECEIVE_4626[AVAX][0] = [false];
        RECEIVE_4626[ETH][0] = [false];
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

    function test_scenario(uint128 amountOne_, uint128 amountTwo_, uint128 amountThree_) public {
        amountOne_ = uint128(bound(amountOne_, 1e18, 2e18));
        amountTwo_ = uint128(bound(amountTwo_, 1e18, 2e18));
        amountThree_ = uint128(bound(amountThree_, 1e18, 2e18));
        AMOUNTS[AVAX][0] = [amountOne_];
        AMOUNTS[ETH][0] = [amountTwo_];
        AMOUNTS[POLY][0] = [amountThree_];

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

/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDSVDNormal4626RevertNoTokenInputSlippageAMB1 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 3];
        MultiDstAMBs = [AMBs, AMBs, AMBs];

        CHAIN_0 = OP;
        DST_CHAINS = [OP, ETH, POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][0] = [2];
        TARGET_UNDERLYINGS[ETH][0] = [2];
        TARGET_UNDERLYINGS[POLY][0] = [1];

        TARGET_VAULTS[OP][0] = [0];
        TARGET_VAULTS[ETH][0] = [3];
        TARGET_VAULTS[POLY][0] = [0];

        TARGET_FORM_KINDS[OP][0] = [0];
        TARGET_FORM_KINDS[ETH][0] = [0];
        TARGET_FORM_KINDS[POLY][0] = [0];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[OP][0] = [1];
        LIQ_BRIDGES[ETH][0] = [1];
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
                slippage: 312, // 0% <- if we are testing a pass this must be below each maxSlippage,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_, uint128 amountTwo_, uint128 amountThree_) public {
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amountOne_ = uint128(bound(amountOne_, 2, TOTAL_SUPPLY_DAI / 3));
        amountTwo_ = uint128(bound(amountTwo_, 2, TOTAL_SUPPLY_DAI / 3));
        amountThree_ = uint128(bound(amountThree_, 2, TOTAL_SUPPLY_DAI / 3));
        AMOUNTS[OP][0] = [amountOne_];
        AMOUNTS[ETH][0] = [amountTwo_];
        AMOUNTS[POLY][0] = [amountThree_];

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

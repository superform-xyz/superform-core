/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SXSVWRevertKycNativeNoSlippageAMB13 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 3];

        CHAIN_0 = OP;
        DST_CHAINS = [AVAX];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [2];

        TARGET_VAULTS[AVAX][0] = [7];

        /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[AVAX][0] = [2];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][1] = [2];

        TARGET_VAULTS[AVAX][1] = [7];

        /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[AVAX][1] = [2];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[AVAX][0] = [1];
        LIQ_BRIDGES[AVAX][1] = [1];

        FINAL_LIQ_DST_WITHDRAW[AVAX] = [OP];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
        actions.push(
            TestAction({
                action: Actions.Withdraw,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_) public {
        amountOne_ = uint128(bound(amountOne_, 2, TOTAL_SUPPLY_DAI));
        AMOUNTS[AVAX][0] = [amountOne_];
        AMOUNTS[AVAX][1] = [amountOne_];

        for (uint256 act = 0; act < actions.length; act++) {
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

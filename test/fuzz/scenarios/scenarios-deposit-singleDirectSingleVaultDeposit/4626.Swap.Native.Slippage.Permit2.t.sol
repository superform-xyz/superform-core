/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SDSVD4626SwapNativeSlippagePermit2 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [2, 3];

        CHAIN_0 = ARBI;
        DST_CHAINS = [ARBI];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ARBI][0] = [2];

        TARGET_VAULTS[ARBI][0] = [0];

        /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[ARBI][0] = [0];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ARBI][0] = [1];

        actions.push(
            TestAction({
                action: Actions.DepositPermit2,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 11, // 0% <- if we are testing a pass this must be below each maxSlippage,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amount_) public {
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amount_ = uint128(bound(amount_, 2, TOTAL_SUPPLY_WETH));
        AMOUNTS[ARBI][0] = [amount_];

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

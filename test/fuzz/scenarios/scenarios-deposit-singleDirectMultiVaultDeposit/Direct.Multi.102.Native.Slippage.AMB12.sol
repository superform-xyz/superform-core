/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SDiMVDMulti102NativeSlippageAMB12 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/

        AMBs = [1, 2];

        CHAIN_0 = OP;
        DST_CHAINS = [OP];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][0] = [2, 1, 0];

        TARGET_VAULTS[OP][0] = [1, 0, 2];

        /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[OP][0] = [1, 0, 2];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[OP][0] = [1, 1, 1];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 774, // 0% <- if we are testing a pass this must be below each maxSlippage,
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_, uint128 amountTwo_, uint128 amountThree_) public {
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amountOne_ = uint128(bound(amountOne_, 2, TOTAL_SUPPLY_ETH / 3));
        amountTwo_ = uint128(bound(amountTwo_, 2, TOTAL_SUPPLY_ETH / 3));
        amountThree_ = uint128(bound(amountThree_, 2, TOTAL_SUPPLY_ETH / 3));
        AMOUNTS[OP][0] = [amountOne_, amountTwo_, amountThree_];

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

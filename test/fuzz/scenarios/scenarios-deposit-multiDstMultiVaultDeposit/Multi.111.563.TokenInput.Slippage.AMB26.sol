// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDMVDMulti111563NoTokenInputSlippageAMB26 is ProtocolActions {
    function setUp() public override {
        chainIds = [ETH, AVAX, OP];

        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/

        AMBs = [2, 6];
        MultiDstAMBs = [AMBs, AMBs];

        CHAIN_0 = ETH;
        DST_CHAINS = [AVAX, OP];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [2, 2, 2];
        TARGET_UNDERLYINGS[OP][0] = [2, 2, 2];

        TARGET_VAULTS[AVAX][0] = [0, 0, 0];

        TARGET_VAULTS[OP][0] = [0, 0, 0];

        TARGET_FORM_KINDS[AVAX][0] = [0, 0, 0];
        TARGET_FORM_KINDS[OP][0] = [0, 0, 0];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[AVAX][0] = [1, 1, 1];
        LIQ_BRIDGES[OP][0] = [1, 1, 1];

        RECEIVE_4626[AVAX][0] = [false, false, false];
        RECEIVE_4626[OP][0] = [false, false, false];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 512, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_, uint128 amountTwo_, uint128 amountThree_) public {
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amountOne_ = uint128(bound(amountOne_, 2 * 10 ** 18, TOTAL_SUPPLY_WETH / 6));
        amountTwo_ = uint128(bound(amountTwo_, 2 * 10 ** 18, TOTAL_SUPPLY_WETH / 6));
        amountThree_ = uint128(bound(amountThree_, 2 * 10 ** 18, TOTAL_SUPPLY_WETH / 6));
        AMOUNTS[AVAX][0] = [amountOne_, amountTwo_, amountThree_];
        AMOUNTS[OP][0] = [amountThree_, amountOne_, amountTwo_];

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

/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDSVTimelocked4626TokenInputSlippageAMB13 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 3];
        MultiDstAMBs = [AMBs, AMBs, AMBs];

        CHAIN_0 = BSC;
        DST_CHAINS = [AVAX, BSC, ETH];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [2];
        TARGET_UNDERLYINGS[BSC][0] = [2];
        TARGET_UNDERLYINGS[ETH][0] = [2];

        TARGET_VAULTS[AVAX][0] = [1];
        TARGET_VAULTS[BSC][0] = [1];
        TARGET_VAULTS[ETH][0] = [1];

        TARGET_FORM_KINDS[AVAX][0] = [1];
        TARGET_FORM_KINDS[BSC][0] = [1];
        TARGET_FORM_KINDS[ETH][0] = [1];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[AVAX][0] = [1];
        LIQ_BRIDGES[BSC][0] = [1];
        LIQ_BRIDGES[ETH][0] = [1];

        RECEIVE_4626[AVAX][0] = [false];
        RECEIVE_4626[BSC][0] = [false];
        RECEIVE_4626[ETH][0] = [false];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 412, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 1 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_, uint128 amountTwo_, uint128 amountThree_) public {
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amountOne_ = uint128(bound(amountOne_, 11 * 10 ** 6, TOTAL_SUPPLY_USDC / 3));
        amountTwo_ = uint128(bound(amountTwo_, 11 * 10 ** 6, TOTAL_SUPPLY_USDC / 3));
        amountThree_ = uint128(bound(amountThree_, 11 * 10 ** 6, TOTAL_SUPPLY_USDC / 3));
        AMOUNTS[AVAX][0] = [amountOne_];
        AMOUNTS[BSC][0] = [amountTwo_];
        AMOUNTS[ETH][0] = [amountThree_];

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

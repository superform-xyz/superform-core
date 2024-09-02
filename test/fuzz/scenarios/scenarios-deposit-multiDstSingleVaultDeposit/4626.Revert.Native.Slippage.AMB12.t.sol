// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDSVDNormal4626RevertTokenInputSlippageAMB1 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 2];
        MultiDstAMBs = [AMBs, AMBs, AMBs];

        CHAIN_0 = OP;
        DST_CHAINS = [POLY, AVAX, OP];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[POLY][0] = [0];
        TARGET_UNDERLYINGS[AVAX][0] = [1];
        TARGET_UNDERLYINGS[OP][0] = [2];

        TARGET_VAULTS[POLY][0] = [1];
        TARGET_VAULTS[AVAX][0] = [1];
        TARGET_VAULTS[OP][0] = [1];

        TARGET_FORM_KINDS[POLY][0] = [0];
        TARGET_FORM_KINDS[AVAX][0] = [0];
        TARGET_FORM_KINDS[OP][0] = [0];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[POLY][0] = [1];
        LIQ_BRIDGES[AVAX][0] = [1];
        LIQ_BRIDGES[OP][0] = [1];

        RECEIVE_4626[POLY][0] = [false];
        RECEIVE_4626[AVAX][0] = [false];
        RECEIVE_4626[OP][0] = [false];

        /// @dev define the test type for every destination chain and for every action
        /// should allow us to revert on specific destination calls, such as specific updatePayloads, specific
        /// processPayloads, etc.

        TEST_TYPE_PER_DST[POLY][0] = TestType.Pass;
        TEST_TYPE_PER_DST[AVAX][0] = TestType.Pass;
        TEST_TYPE_PER_DST[OP][0] = TestType.Pass;

        actions.push(
            TestAction({
                action: Actions.DepositPermit2,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 742, // 0% <- if we are testing a pass this must be below each maxSlippage,
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
        AMOUNTS[POLY][0] = [amountOne_];
        AMOUNTS[AVAX][0] = [amountTwo_];
        AMOUNTS[OP][0] = [amountThree_];

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

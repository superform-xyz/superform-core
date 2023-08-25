/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDMVDMulti0026MultiTxNativeSlippageL1AMB23 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/

        AMBs = [2, 3];
        MultiDstAMBs = [AMBs, AMBs];

        CHAIN_0 = OP;
        DST_CHAINS = [POLY, ETH];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[POLY][0] = [0, 1];
        TARGET_UNDERLYINGS[ETH][0] = [1, 1];

        TARGET_VAULTS[POLY][0] = [0, 0];

        /// @dev id 0 is normal 4626
        TARGET_VAULTS[ETH][0] = [2, 6];
        /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[POLY][0] = [0, 0];
        TARGET_FORM_KINDS[ETH][0] = [2, 2];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[POLY][0] = [1, 1];
        LIQ_BRIDGES[ETH][0] = [1, 1];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 421, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: true,
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_, uint128 amountTwo_) public {
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amountOne_ = uint128(bound(amountOne_, 2, TOTAL_SUPPLY_ETH / 4));
        amountTwo_ = uint128(bound(amountTwo_, 2, TOTAL_SUPPLY_ETH / 4));
        AMOUNTS[POLY][0] = [amountOne_, amountTwo_];
        AMOUNTS[ETH][0] = [amountTwo_, amountOne_];

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

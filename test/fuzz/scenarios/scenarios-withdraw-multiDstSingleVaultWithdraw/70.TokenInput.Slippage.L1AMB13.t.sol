/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDSVW70TokenInputSlippageL1AMB13 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 3];
        MultiDstAMBs = [AMBs, AMBs];

        CHAIN_0 = POLY;
        DST_CHAINS = [OP, ETH];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][0] = [2];
        TARGET_UNDERLYINGS[ETH][0] = [2];

        TARGET_VAULTS[OP][0] = [7];

        /// @dev id 0 is normal 4626
        TARGET_VAULTS[ETH][0] = [0];
        /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[OP][0] = [0];
        TARGET_FORM_KINDS[ETH][0] = [0];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][1] = [2];
        TARGET_UNDERLYINGS[ETH][1] = [2];

        TARGET_VAULTS[OP][1] = [7];

        /// @dev id 0 is normal 4626
        TARGET_VAULTS[ETH][1] = [0];
        /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[OP][1] = [0];
        TARGET_FORM_KINDS[ETH][1] = [0];

        PARTIAL[OP][1] = [true];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[OP][0] = [1];
        LIQ_BRIDGES[OP][1] = [1];

        LIQ_BRIDGES[ETH][0] = [1];
        LIQ_BRIDGES[ETH][1] = [1];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 999, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
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
                slippage: 999, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_, uint128 amountOneWithdraw_, uint128 amountTwo_) public {
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amountOne_ = uint128(bound(amountOne_, 3, TOTAL_SUPPLY_WETH / 2));
        amountTwo_ = uint128(bound(amountTwo_, 2, TOTAL_SUPPLY_WETH / 2));

        AMOUNTS[OP][0] = [amountOne_];
        amountOneWithdraw_ = uint128(bound(amountOneWithdraw_, 2, amountOne_ - 1));
        AMOUNTS[OP][1] = [amountOneWithdraw_];

        AMOUNTS[ETH][0] = [amountTwo_];
        AMOUNTS[ETH][1] = [amountTwo_];

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

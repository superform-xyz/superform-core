/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../utils/ProtocolActions.sol";

contract SDMVDMulti111RescueFailedDepositsNoMultiTxTokenInputSlippageL1AMB12 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/

        AMBs = [1, 2];

        CHAIN_0 = ETH;
        DST_CHAINS = [AVAX];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [2, 2, 2];
        TARGET_VAULTS[AVAX][0] = [3, 3, 3];
        /// @dev vault index 3 is failedDepositMock, check VAULT_KINDS
        TARGET_FORM_KINDS[AVAX][0] = [0, 0, 0];
        AMOUNTS[AVAX][0] = [214, 798, 55_312];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ETH][1] = [2, 2, 2];
        TARGET_VAULTS[ETH][1] = [3, 3, 3];
        /// @dev vault index 3 is failedDepositMock, check VAULT_KINDS
        TARGET_FORM_KINDS[ETH][1] = [0, 0, 0];
        AMOUNTS[ETH][1] = [10, 40, 2800];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[AVAX][0] = [1, 1, 1];
        LIQ_BRIDGES[ETH][1] = [1, 1, 1];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.RevertProcessPayload,
                revertError: "",
                revertRole: "",
                slippage: 512, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        actions.push(
            TestAction({
                action: Actions.RescueFailedDeposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 400, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(
        uint128 amountOne_,
        uint128 amountOneRescue_,
        uint128 amountTwo_,
        uint128 amountTwoRescue_,
        uint128 amountThree_,
        uint128 amountThreeRescue_
    ) public {
        /// @dev amount = 2 after two slippages will become 0, hence starting with 3
        amountOne_ = uint128(bound(amountOne_, 3, TOTAL_SUPPLY_WETH / 3));
        amountTwo_ = uint128(bound(amountTwo_, 3, TOTAL_SUPPLY_WETH / 3));
        amountThree_ = uint128(bound(amountThree_, 3, TOTAL_SUPPLY_WETH / 3));
        AMOUNTS[AVAX][0] = [amountOne_, amountTwo_, amountThree_];

        uint256 dstAmountOne = (AMOUNTS[AVAX][0][0] * uint256(10000 - actions[0].slippage)) / 10000;
        uint256 dstAmountTwo = (AMOUNTS[AVAX][0][1] * uint256(10000 - actions[0].slippage)) / 10000;
        uint256 dstAmountThree = (AMOUNTS[AVAX][0][2] * uint256(10000 - actions[0].slippage)) / 10000;

        /// @dev amount = 1 after one slippage will become 0, hence starting with 2
        amountOneRescue_ = uint128(bound(amountOneRescue_, 2, dstAmountOne));
        amountTwoRescue_ = uint128(bound(amountTwoRescue_, 2, dstAmountTwo));
        amountThreeRescue_ = uint128(bound(amountThreeRescue_, 2, dstAmountThree));
        AMOUNTS[ETH][1] = [amountOneRescue_, amountTwoRescue_, amountThreeRescue_];

        for (uint256 act; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;
            if (action.action == Actions.RescueFailedDeposit) _rescueFailedDeposits(action, act);
            else _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
    }
}

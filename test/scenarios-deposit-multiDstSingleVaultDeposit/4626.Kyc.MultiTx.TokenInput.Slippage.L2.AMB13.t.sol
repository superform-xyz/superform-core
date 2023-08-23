/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../utils/ProtocolActions.sol";

contract MDSVDKYC4626MultiTxTokenInputSlippageL2AMB13 is ProtocolActions {
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

        TARGET_VAULTS[AVAX][0] = [2];

        /// @dev id 0 is normal 4626
        TARGET_VAULTS[BSC][0] = [2];
        /// @dev id 0 is normal 4626
        TARGET_VAULTS[ETH][0] = [2];
        /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[AVAX][0] = [2];
        TARGET_FORM_KINDS[BSC][0] = [2];
        TARGET_FORM_KINDS[ETH][0] = [2];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[AVAX][0] = [2];
        LIQ_BRIDGES[BSC][0] = [2];
        LIQ_BRIDGES[ETH][0] = [2];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 412, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: true,
                externalToken: 1 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_, uint128 amountTwo_, uint128 amountThree_) public {
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amountOne_ = uint128(bound(amountOne_, 2, TOTAL_SUPPLY_USDT / 3));
        amountTwo_ = uint128(bound(amountTwo_, 2, TOTAL_SUPPLY_USDT / 3));
        amountThree_ = uint128(bound(amountThree_, 2, TOTAL_SUPPLY_USDT / 3));
        AMOUNTS[AVAX][0] = [amountOne_];
        AMOUNTS[BSC][0] = [amountTwo_];
        AMOUNTS[ETH][0] = [amountThree_];

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

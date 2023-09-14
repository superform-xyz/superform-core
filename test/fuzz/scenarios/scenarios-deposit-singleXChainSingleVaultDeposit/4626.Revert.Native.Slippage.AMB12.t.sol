/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SXSVDNormal4626RevertTokenInputSlippageAMB1 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 2];

        CHAIN_0 = POLY;
        DST_CHAINS = [AVAX];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [2];

        TARGET_VAULTS[AVAX][0] = [3];
        /// @dev vault index 3 is failedDepositMock, check VAULT_KINDS

        TARGET_FORM_KINDS[AVAX][0] = [0];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[AVAX][0] = [1];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.RevertProcessPayload,
                revertError: "",
                revertRole: "",
                slippage: 742, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amount_) public {
        /// @dev bounding to 0.9 of ETH SUPPLY coz user account (with 120m ETH) runs short of ETH
        amount_ = uint128(bound(amount_, 11, (TOTAL_SUPPLY_ETH * 9) / 10));
        AMOUNTS[AVAX][0] = [amount_];

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

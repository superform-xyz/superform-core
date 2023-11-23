/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SXSVDNormal4626RevertNoTokenInputSlippageAMB1 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 3];

        CHAIN_0 = OP;
        DST_CHAINS = [POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[POLY][0] = [1];

        TARGET_VAULTS[POLY][0] = [3];
        /// @dev vault index 3 is failedDepositMock, check VAULT_KINDS

        TARGET_FORM_KINDS[POLY][0] = [0];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[POLY][0] = [1];

        RECEIVE_4626[POLY][0] = [false];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.RevertProcessPayload,
                revertError: "",
                revertRole: "",
                slippage: 312, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amount_) public {
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amount_ = uint128(bound(amount_, 2 * 10 ** 18, TOTAL_SUPPLY_WETH));
        AMOUNTS[POLY][0] = [amount_];

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

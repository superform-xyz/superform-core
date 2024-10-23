// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SXSVDNormal4626MultiTokenInputToBeraNoSlippageAMB23 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [2, 6];

        CHAIN_0 = SEPOLIA;
        DST_CHAINS = [BARTIO];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[BARTIO][0] = [0];
        TARGET_VAULTS[BARTIO][0] = [0];
        TARGET_FORM_KINDS[BARTIO][0] = [0];

        AMOUNTS[BARTIO][0] = [133];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[BARTIO][0] = [1];
        RECEIVE_4626[BARTIO][0] = [false];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 0 // 0 = DAI, 1 = USDC, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amount_) public {
        amount_ = uint128(bound(amount_, 1 * 10 ** 18, TOTAL_SUPPLY_DAI));
        AMOUNTS[BARTIO][0] = [amount_];

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

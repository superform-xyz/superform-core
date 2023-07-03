/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../../types/LiquidityTypes.sol";
import "../../types/DataTypes.sol";
// Test Utils
import "../utils/ProtocolActions.sol";
import "../utils/AmbParams.sol";

/// @dev TODO - we should do assertions on final balances of users at the end of each test scenario
/// @dev FIXME - using unoptimized multiDstMultivault function
contract Scenario4Test is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev singleDestinationXChainDeposit Full singleDestinationXChainWithdraw Deposit test case

        AMBs = [1, 2];

        CHAIN_0 = ETH;
        DST_CHAINS = [ARBI];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ARBI][0] = [1];
        TARGET_VAULTS[ARBI][0] = [0]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ARBI][0] = [0];

        TARGET_UNDERLYINGS[ARBI][1] = [1];
        TARGET_VAULTS[ARBI][1] = [0]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ARBI][1] = [0];

        AMOUNTS[ARBI][0] = [3213];
        AMOUNTS[ARBI][1] = [3213];

        MAX_SLIPPAGE[ARBI][0] = [1000];
        MAX_SLIPPAGE[ARBI][1] = [1000];

        LIQ_BRIDGES[ARBI][0] = [1];
        LIQ_BRIDGES[ARBI][1] = [1];

        /// @dev check if we need to have this here (it's being overriden)
        // uint256 msgValue = 1 * _getPriceMultiplier(CHAIN_0) * 1e18;

        /// @dev push in order the actions should be executed
        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                ambParams: generateAmbParams(DST_CHAINS.length, 2),
                msgValue: 50 * 10 ** 18,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
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
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                ambParams: generateAmbParams(DST_CHAINS.length, 2),
                msgValue: 50 * 10 ** 18,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
            })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario() public {
        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultsSFData[] memory multiSuperFormsData;
            SingleVaultSFData[] memory singleSuperFormsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            _runMainStages(action, act, multiSuperFormsData, singleSuperFormsData, aV, vars, success);
        }
    }
}

/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../types/LiquidityTypes.sol";
import "../types/DataTypes.sol";
// Test Utils
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/ProtocolActions.sol";
import "./utils/AmbParams.sol";

/// @dev TODO - we should do assertions on final balances of users at the end of each test scenario
/// @dev FIXME - using unoptimized multiDstMultivault function
contract Scenario3Test is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev MultiDestinationMultiVault Deposit test case

        AMBs = [1, 2];

        CHAIN_0 = OP;
        DST_CHAINS = [ARBI, ETH]; // 42161 , 1

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ARBI][0] = [1, 2];
        TARGET_VAULTS[ARBI][0] = [1, 2];
        TARGET_FORM_KINDS[ARBI][0] = [0, 0];

        TARGET_UNDERLYINGS[ETH][0] = [1, 2];
        TARGET_VAULTS[ETH][0] = [0];
        TARGET_FORM_KINDS[ETH][0] = [0];

        AMOUNTS[ARBI][0] = [8422, 321];
        AMOUNTS[ETH][0] = [2];

        MAX_SLIPPAGE[ARBI][0] = [1000, 1000];
        MAX_SLIPPAGE[ETH][0] = [1000];

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[ARBI][0] = [1, 1];
        LIQ_BRIDGES[ETH][0] = [1];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
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

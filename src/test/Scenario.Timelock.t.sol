/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../types/LiquidityTypes.sol";
import "../types/DataTypes.sol";
// import "forge-std/console.sol";

// Test Utils
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/ProtocolActions.sol";

/// @dev TODO - we should do assertions on final balances of users at the end of each test scenario
/// @dev FIXME - using unoptimized multiDstMultivault function
contract ScenarioTimelockTest is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/

        /// @dev singleDestinationSingleVault Deposit test case
        /// ^^^^
        /// NOTE: What if we want to run multiple scenarios for given TARGET_UNDERLYING_VAULTS/FORMS? 
        /// NOTE: BaseScenario to inherit for custom forms and other infra?

        primaryAMB = 1;

        secondaryAMBs = [2];

        CHAIN_0 = OP;
        DST_CHAINS = [POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        
        /// @dev Deposit Action
        /// chainID => actionID => vaultID
        TARGET_UNDERLYING_VAULTS[POLY][0] = [1];
        /// chainID => actionID => formID
        TARGET_FORM_KINDS[POLY][0] = [1];
        /// chainID => actionID => amount
        AMOUNTS[POLY][0] = [1000];
        /// chainID => actionID => slippage
        MAX_SLIPPAGE[POLY][0] = [1000];

        /// @dev Withdraw action
        TARGET_UNDERLYING_VAULTS[POLY][1] = [1];
        TARGET_FORM_KINDS[POLY][1] = [1];
        AMOUNTS[POLY][1] = [1000];
        MAX_SLIPPAGE[POLY][1] = [1000];

        /// @dev check if we need to have this here (it's being overriden)
        uint256 msgValue = 1 * _getPriceMultiplier(CHAIN_0) * 1e18;
        
        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: users[0],
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                adapterParam: "",
                msgValue: msgValue
            })
        );

        /// NOTE: We need some way to control execution of chained actions
        /// NOTE: In this case, Withdraw is executed immediately after Deposit (we can't roll block)
        /// NOTE: We also may want to have multiple testFunctions for different actions
        /// NOTE: Other edge cases possible in future?
        actions.push(
            TestAction({
                action: Actions.Withdraw,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: users[0],
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                adapterParam: "",
                msgValue: msgValue
            })
        );

    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario() public {
        /// NOTE: Shouldn't this return something to allow us to assert?
        /// NOTE: We may want to make asserts about state of the vault/form/tokenbank/etc.. too, not only user balances

        /// NOTE: E.g. This call succeeds with requestUnlock as it should, but we have no way to assert that here if withdraw or request happen
        _run_actions();
        
        /// NOTE: E.g No access to revert msg. We get EvmError while we should get TimeLock error
        // vm.expectRevert();
    }
}

/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../types/LiquidityTypes.sol";
import "../types/DataTypes.sol";
import "forge-std/console.sol";

// Test Utils
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/ProtocolActions.sol";

/// @dev TODO - we should do assertions on final balances of users at the end of each test scenario
/// @dev FIXME - using unoptimized multiDstMultivault function
contract Scenario3Test is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev MultiDestinationMultiVault Deposit test case

        primaryAMB = 1;

        secondaryAMBs = [2];

        CHAIN_0 = OP;
        DST_CHAINS = [ARBI, ETH];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYING_VAULTS[ARBI][0] = [1, 2];
        TARGET_UNDERLYING_VAULTS[ETH][0] = [0];

        AMOUNTS[ARBI][0] = [1000, 500];
        AMOUNTS[ETH][0] = [100];

        MAX_SLIPPAGE[ARBI][0] = [1000, 1000];
        MAX_SLIPPAGE[ETH][0] = [1000];

        /// @dev check if we need to have this here (it's being overriden)
        uint256 msgValue = 1 * _getPriceMultiplier(CHAIN_0) * 1e18;

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
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

    /// @dev FIXME: MULTI VAULTS TESTS WON'T WORK WITH CURRENT LAYERZERO HELPER!!
    function xtest_scenario() public {
        _run_actions();
    }
}

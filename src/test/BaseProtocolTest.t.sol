// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// Contracts
import "contracts/types/socketTypes.sol";
import "contracts/types/lzTypes.sol";

// Test Utils
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/BaseSetup.sol";

/// @dev interchain test cases to do
/// FTM=>BSC: user withdrawing tokens from a vault on BSC from/to Fantom
/// BSC=>FTM: user depositing to a vault on Fantom from BSC
/// BSC=>FTM: user withdrawing tokens from a vault on Fantom from/to BSC
/// FTM=>BSC: multiple LiqReq/StateReq for multi-deposit
/// FTM=>BSC: user depositing to a vault requiring swap (stays pending) - REVERTS
/// FTM=>BSC: cross-chain slippage update beyond max slippage - REVERTS
/// FTM=>BSC: cross-chain slippage update above received value - REVERTS
/// FTM=>BSC: cross-chain slippage update from unauthorized wallet - REVERTS

contract BaseProtocolTest is BaseSetup {
    /*//////////////////////////////////////////////////////////////
                    !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/
    uint256 internal constant numberOfTestActions = 4;

    function setUp() public override {
        /*//////////////////////////////////////////////////////////////
                    !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/

        UNDERLYING_TOKEN = "DAI";

        super.setUp();
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO DEFINITION
    //////////////////////////////////////////////////////////////*/

    function _getTestAction(uint256 index_)
        internal
        view
        returns (TestAction memory)
    {
        TestAction[numberOfTestActions] memory testActionCases = [
            TestAction({
                action: Actions.Deposit,
                CHAIN_0: FTM,
                CHAIN_1: POLY,
                vault: 1,
                amount: 1000,
                user: users[0]
            }),
            TestAction({
                action: Actions.Withdraw,
                CHAIN_0: FTM,
                CHAIN_1: POLY,
                vault: 1,
                amount: 1000,
                user: users[0]
            }),
            TestAction({
                action: Actions.Deposit,
                CHAIN_0: POLY,
                CHAIN_1: BSC,
                vault: 1,
                amount: 2000,
                user: users[2]
            }),
            TestAction({
                action: Actions.Withdraw,
                CHAIN_0: POLY,
                CHAIN_1: BSC,
                vault: 1,
                amount: 2000,
                user: users[2]
            })
        ];

        return testActionCases[index_];
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_actions() public {
        for (uint256 i = 0; i < numberOfTestActions; i++) {
            TestAction memory action = _getTestAction(i);

            ActionLocalVars memory vars;

            vars.lzEndpoint_0 = LZ_ENDPOINTS[action.CHAIN_0];
            vars.lzEndpoint_1 = LZ_ENDPOINTS[action.CHAIN_1];
            vars.underlyingSrcToken = getContract(
                action.CHAIN_0,
                UNDERLYING_TOKEN
            );
            vars.underlyingDstToken = getContract(
                action.CHAIN_1,
                UNDERLYING_TOKEN
            );
            vars.fromSrc = payable(getContract(action.CHAIN_0, "SuperRouter"));
            vars.toDst = payable(
                getContract(action.CHAIN_1, "SuperDestination")
            );
            vars.vaultMock = getContract(action.CHAIN_1, VAULT_NAME);
            vars.TARGET_VAULT = MockERC20(
                getContract(action.CHAIN_1, UNDERLYING_TOKEN)
            );
            if (action.action == Actions.Deposit) {
                deposit(action, vars);
            } else if (action.action == Actions.Withdraw) {
                withdraw(action, vars);
            }
        }
        _resetPayloadIDs();
    }
}

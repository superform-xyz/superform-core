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
contract Scenario1Test is ProtocolActions {
    /// @dev Access SuperFormRouter interface
    ISuperFormRouter superRouter;

    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev singleDestinationSingleVault Deposit test case
        AMBs = [2, 3];

        CHAIN_0 = OP;
        DST_CHAINS = [POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action

        TARGET_UNDERLYINGS[POLY][0] = [0];

        TARGET_VAULTS[POLY][0] = [0]; /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[POLY][0] = [0];

        AMOUNTS[POLY][0] = [23183];

        MAX_SLIPPAGE[POLY][0] = [1000];

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[POLY][0] = [1];

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
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario1() public {
        address _superRouter = contracts[CHAIN_0][bytes32(bytes("SuperFormRouter"))];
        superRouter = ISuperFormRouter(_superRouter);

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

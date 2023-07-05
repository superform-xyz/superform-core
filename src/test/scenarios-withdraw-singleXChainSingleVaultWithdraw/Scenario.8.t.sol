/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../../types/LiquidityTypes.sol";
import "../../types/DataTypes.sol";
// import "forge-std/console.sol";

// Test Utils
import "../utils/ProtocolActions.sol";
import "../utils/AmbParams.sol";

/// @dev TODO - we should do assertions on final balances of users at the end of each test scenario
/// @dev FIXME - using unoptimized multiDstMultivault function
contract Scenario8Test is ProtocolActions {
    /// @dev Access SuperFormRouter interface
    ISuperFormRouter superRouter;

    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev singleDestinationSingleVault Deposit test case with permit2

        AMBs = [1, 2];

        CHAIN_0 = OP;
        DST_CHAINS = [POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[POLY][0] = [2];
        TARGET_VAULTS[POLY][0] = [0]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[POLY][0] = [0];

        TARGET_UNDERLYINGS[POLY][1] = [2];
        TARGET_VAULTS[POLY][1] = [0]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[POLY][1] = [0];

        AMOUNTS[POLY][0] = [47212];
        AMOUNTS[POLY][1] = [47212];

        MAX_SLIPPAGE[POLY][0] = [1000];
        MAX_SLIPPAGE[POLY][1] = [1000];

        LIQ_BRIDGES[POLY][0] = [1];
        LIQ_BRIDGES[POLY][1] = [1];

        /// @dev check if we need to have this here (it's being overriden)
        uint256 msgValue = 1 * _getPriceMultiplier(CHAIN_0) * 1e18;
        actions.push(
            TestAction({
                action: Actions.DepositPermit2,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                ambParams: generateAmbParams(DST_CHAINS.length, 2),
                msgValue: msgValue,
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
                msgValue: msgValue,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
            })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario() public {
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

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
    mapping(uint256 => Actions) public ACTION_TYPE;

    uint256 actionId;

    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/

        /// @dev singleDestinationSingleVault Deposit test case

        primaryAMB = 1;

        secondaryAMBs = [2];

        CHAIN_0 = OP;
        DST_CHAINS = [POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        /// NOTE: PACK THIS INTO MAPPING? TIE TO ACTION HERE?
        /// @dev Deposit Action
        /// chainID => actionID => vaultID
        // TARGET_UNDERLYING_VAULTS[POLY][0] = [1];
        // /// chainID => actionID => formID
        // TARGET_FORM_KINDS[POLY][0] = [1];
        // /// chainID => actionID => amount
        // AMOUNTS[POLY][0] = [1000];
        // /// chainID => actionID => slippage
        // MAX_SLIPPAGE[POLY][0] = [1000];

        // /// @dev Withdraw action
        // TARGET_UNDERLYING_VAULTS[POLY][1] = [1];
        // TARGET_FORM_KINDS[POLY][1] = [1];
        // AMOUNTS[POLY][1] = [1000];
        // MAX_SLIPPAGE[POLY][1] = [1000];

        // /// @dev check if we need to have this here (it's being overriden)
        // uint256 msgValue = 1 * _getPriceMultiplier(CHAIN_0) * 1e18;

        // actions.push(
        //     TestAction({
        //         action: Actions.Deposit,
        //         multiVaults: false, //!!WARNING turn on or off multi vaults
        //         user: users[0],
        //         testType: TestType.Pass,
        //         revertError: "",
        //         revertRole: "",
        //         slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
        //         multiTx: false,
        //         adapterParam: "",
        //         msgValue: msgValue
        //     })
        // );

        // actions.push(
        //     TestAction({
        //         action: Actions.Withdraw,
        //         multiVaults: false, //!!WARNING turn on or off multi vaults
        //         user: users[0],
        //         testType: TestType.Pass,
        //         revertError: "",
        //         revertRole: "",
        //         slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
        //         multiTx: false,
        //         adapterParam: "",
        //         msgValue: msgValue
        //     })
        // );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    /// NOTE: Individual tests target validation of each possible condition for form deposit/withdraw to fail

    /// @dev This test uses only 1 action
    /// assert revert on WITHDRAW_COOLDOWN_PERIOD();
    // function testFail_scenario_request_unlock_cooldown() public {}

    /// @dev This test uses only 1 action
    /// assert revert on LOCKED(); - requestUnlock() was called but user wants to overwithdraw
    // function testFail_scenario_request_unlock_overwithdraw() public {}

    /// @dev This test uses 2 actions and rolls block between
    function test_scenario_request_unlock_withdraw() public {
        /// NOTE: Execute single action by calling it
        
        TestAction memory action = _depositAction(
            POLY,
            1,
            1,
            1000,
            1000,
            TestType.Pass
        );

        MultiVaultsSFData[] memory multiSuperFormsData;
        SingleVaultSFData[] memory singleSuperFormsData;
        MessagingAssertVars memory aV;
        StagesLocalVars memory vars;
        bool success;

        /// NOTE: What if we want to send from different EOA than deployer's?
        /// NOTE: Unsure if we need multi/singleSuperFormsData returned here if we can read state between calls now
        
        console.log("stage0 buildReqData");
        console.log("actionId", actionId);   
        /// @dev User builds his request data for src (deposit action)
        (
            multiSuperFormsData,
            singleSuperFormsData,
            vars
        ) = _stage1_buildReqData(action, actionId);

        actionId++;

        console.log("stage1 done");

        /// @dev User sends his request data to the src (deposit action)
        (vars, aV) = _stage2_run_src_action(
            action,
            multiSuperFormsData,
            singleSuperFormsData,
            vars
        );

        console.log("stage2 done");

        /// @dev FIXME? SuperForm Keepers operation, not relevant to deposit, should be separated for Form testing (internal processing)
        _stage3_src_to_dst_amb_delivery(
            action,
            vars,
            aV,
            multiSuperFormsData,
            singleSuperFormsData
        );

        console.log("stage3 done");

        /// @dev FIXME? SuperForm Keepers operation, not relevant to deposit, should be separated for Form testing (internal processing)
        success = _stage4_process_src_dst_payload(
            action,
            vars,
            aV,
            singleSuperFormsData,
            actionId
        );

        console.log("stage4 done");

        /// @dev FIXME? SuperForm Keepers operation, not relevant to deposit, should be separated for Form testing (internal processing)
        success = _stage5_process_superPositions_mint(action, vars, aV);

        console.log("stage5 done");
        
    }

    function _depositAction(
        uint16 chainID,
        uint256 vaultID,
        uint256 formID,
        uint256 amount,
        uint256 slippage,
        TestType testType /// ProtocolActions invariant
    ) internal returns (TestAction memory depositAction) {

        /// @dev check if we need to have this here (it's being overriden)
        uint256 msgValue = 1 * _getPriceMultiplier(CHAIN_0) * 1e18;

        TARGET_UNDERLYING_VAULTS[chainID][actionId] = [vaultID];
        TARGET_FORM_KINDS[chainID][actionId] = [formID];
        AMOUNTS[chainID][actionId] = [amount];
        MAX_SLIPPAGE[chainID][actionId] = [slippage];

        depositAction = TestAction({
            action: Actions.Deposit,
            multiVaults: false, //!!WARNING turn on or off multi vaults
            user: users[0],
            testType: TestType.Pass, /// NOTE: TestType should be low level invariant
            revertError: "",
            revertRole: "",
            slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
            multiTx: false,
            adapterParam: "",
            msgValue: msgValue
        });

    }

    function _withdrawAction(
        uint16 chainID,
        uint256 vaultID,
        uint256 formID,
        uint256 amount,
        uint256 slippage,
        TestType testType /// ProtocolActions invariant
    ) internal returns (TestAction memory withdrawAction) {
        
        /// @dev check if we need to have this here (it's being overriden)
        uint256 msgValue = 1 * _getPriceMultiplier(CHAIN_0) * 1e18;

        TARGET_UNDERLYING_VAULTS[chainID][actionId] = [vaultID];
        TARGET_FORM_KINDS[chainID][actionId] = [formID];
        AMOUNTS[chainID][actionId] = [amount];
        MAX_SLIPPAGE[chainID][actionId] = [slippage];

        withdrawAction = TestAction({
            action: Actions.Withdraw,
            multiVaults: false, //!!WARNING turn on or off multi vaults
            user: users[0],
            testType: TestType.Pass, /// NOTE: TestType should be low level invariant
            revertError: "",
            revertRole: "",
            slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
            multiTx: false,
            adapterParam: "",
            msgValue: msgValue
        });
        
    }

    // function test_scenario() public {
    //     /// NOTE: Execute single action by calling it
    //     for (uint256 act = 0; act < actions.length; act++) {
    //         TestAction memory action = actions[act];
    //         MultiVaultsSFData[] memory multiSuperFormsData;
    //         SingleVaultSFData[] memory singleSuperFormsData;
    //         MessagingAssertVars memory aV;
    //         StagesLocalVars memory vars;
    //         bool success;

    //         /// NOTE: What if we want to send from different EOA than deployer's?
    //         /// NOTE: Unsure if we need multi/singleSuperFormsData returned here if we can read state between calls now
    //         /// @dev User builds his request data for src (deposit action)
    //         (
    //             multiSuperFormsData,
    //             singleSuperFormsData,
    //             vars
    //         ) = _stage1_buildReqData(action, act);

    //         /// @dev User sends his request data to the src (deposit action)
    //         (vars, aV) = _stage2_run_src_action(
    //             action,
    //             multiSuperFormsData,
    //             singleSuperFormsData,
    //             vars
    //         );

    //         /// @dev SuperForm Keepers operation, no user's input here (process)
    //         /// NOTE: Here msg.sender context should be different from first two user actions to reliably test
    //         _stage3_src_to_dst_amb_delivery(
    //             action,
    //             vars,
    //             aV,
    //             multiSuperFormsData,
    //             singleSuperFormsData
    //         );

    //         /// @dev SuperForm Keepers operation, no user's input here
    //         success = _stage4_process_src_dst_payload(
    //             action,
    //             vars,
    //             aV,
    //             singleSuperFormsData,
    //             act
    //         );

    //         if (!success) {
    //             continue;
    //         }

    //         if (action.action == Actions.Deposit) {
    //             success = _stage5_process_superPositions_mint(action, vars, aV);
    //             if (!success) {
    //                 continue;
    //             }
    //         }
    //     }
    // }
}

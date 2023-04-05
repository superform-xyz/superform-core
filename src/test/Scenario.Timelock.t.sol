/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../types/LiquidityTypes.sol";
import "../types/DataTypes.sol";
// import "forge-std/console.sol";

// Test Utils
import {ISuperRouter} from "../interfaces/ISuperRouter.sol";
import {ITimelockForm} from "./interfaces/ITimelockForm.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/ProtocolActions.sol";

/// @dev we can't use it because it shadows existing declaration at the BaseSetup level
// import {ERC4626TimelockForm} from "../forms/ERC4626TimelockForm.sol"; 

/// @dev TODO - we should do assertions on final balances of users at the end of each test scenario
/// @dev FIXME - using unoptimized multiDstMultivault function
contract ScenarioTimelockTest is ProtocolActions {

    /// @dev Global counter for actions sent to the protocol
    uint256 actionId;

    /// @dev Access Form interface to call form functions for assertions
    // ERC4626TimelockForm public erc4626TimelockForm;

    /// @dev Access SuperRouter interface
    ISuperRouter superRouter;

    /// @dev singleDestinationSingleVault Deposit test case
    function setUp() public override {
        super.setUp();

        /// FIXME: We need to map individual formBeaconId to individual vault to have access to ERC4626Form previewFunctions
        /// see BaseSetup FIXME L87
        // address targetForm = address(vaults[DST_CHAINS[0]][1][1]);
        // ITimelockForm form = ITimelockForm(targetForm);

        primaryAMB = 1;
        secondaryAMBs = [2];
        CHAIN_0 = OP; /// @dev source chain
        DST_CHAINS = [POLY]; /// @dev destination chain(s)

        /// @dev You can define settings here or pass them as arguments to _depositAction()/_withdrawAction()
        // TARGET_UNDERLYING_VAULTS[chainID][actionId] = [vaultID];
        // TARGET_FORM_KINDS[chainID][actionId] = [formID];
        // AMOUNTS[chainID][actionId] = [amount];
        // MAX_SLIPPAGE[chainID][actionId] = [slippage];
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    /// NOTE: Individual tests target validation of each possible condition for form deposit/withdraw to fail

    /// @dev TODO: This test uses only 1 action
    /// assert revert on WITHDRAW_COOLDOWN_PERIOD();
    // function testFail_scenario_request_unlock_cooldown() public {}

    /// @dev TODO: This test uses only 1 action
    /// assert revert on LOCKED(); - requestUnlock() was called but user wants to overwithdraw
    // function testFail_scenario_request_unlock_overwithdraw() public {}

    /// @dev This test uses 2 actions, rolls block between and make assertions about states in between
    function test_scenario_request_unlock_full_withdraw() public {

        address _superRouter = contracts[CHAIN_0][bytes32(bytes("SuperRouter"))];
        superRouter = ISuperRouter(_superRouter);

        /*///////////////////////////////////////////////////////////////
                                DEPOSIT ACTION
        //////////////////////////////////////////////////////////////*/
        
        TestAction memory action = _depositAction(
            DST_CHAINS[0], // chainID (destination)
            1, // vaultID
            1, // formID, 0 == ERC4626Form, 1 == ERC4626Timelock
            1000, // amount
            1000, // slippage 
            TestType.Pass // testType
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
        /// NOTE: SuperForm API operation, could be separated from individual test-flow  (internal processing)
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

        /// @dev FIXME? SuperForm Keepers operation, could be separated from individual test-flow (internal processing)
        _stage3_src_to_dst_amb_delivery(
            action,
            vars,
            aV,
            multiSuperFormsData,
            singleSuperFormsData
        );

        console.log("stage3 done");

        /// @dev FIXME? SuperForm Keepers operation, could be separated from individual test-flow (internal processing)
        success = _stage4_process_src_dst_payload(
            action,
            vars,
            aV,
            singleSuperFormsData,
            actionId
        );

        console.log("stage4 done");

        /// @dev FIXME? SuperForm Keepers operation, not relevant to depositor, should be separated for Form testing (internal processing)
        success = _stage5_process_superPositions_mint(action, vars, aV);

        console.log("stage5 done");

        /*///////////////////////////////////////////////////////////////
                                DEPOSIT ASSERTS
        //////////////////////////////////////////////////////////////*/

        uint256 balanceOfAlice = superRouter.balanceOf(users[0], 1);
        console.log("ASSERT FAILS HERE, NO SUPERPOSITION OWNED!!!");
        assertEq(balanceOfAlice, 1000);

        /*///////////////////////////////////////////////////////////////
                                WITHDRAW ACTION
        //////////////////////////////////////////////////////////////*/

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

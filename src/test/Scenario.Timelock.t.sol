/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../types/LiquidityTypes.sol";
import "../types/DataTypes.sol";
// import "forge-std/console.sol";

// Test Utils
import {ISuperRouter} from "../interfaces/ISuperRouter.sol";
import {IERC4626TimelockForm} from "./interfaces/IERC4626TimelockForm.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/ProtocolActions.sol";
import {_packSuperForm} from "../utils/DataPacking.sol";

/// @dev we can't use it because it shadows existing declaration at the BaseSetup level
// import {ERC4626TimelockForm} from "../forms/ERC4626TimelockForm.sol";

/// @dev TODO - we should do assertions on final balances of users at the end of each test scenario
/// @dev FIXME - using unoptimized multiDstMultivault function
contract ScenarioTimelockTest is ProtocolActions {

    /// @dev Global counter for actions sent to the protocol
    uint256 actionId;
    
    /// @dev Global variable for timelockForm type. Different from dstFormID which is an index to access FORM_BEACON_IDS in BaseSetup
    uint256 timelockFormType = 2;

    /// @dev Global and default set of variables for setting single action to build deposit/withdraw requests
    uint16 dstChainID;
    uint256 dstVaultID;
    uint256 dstFormID;
    uint256 amount;
    uint256 slippage;

    /// @dev Access SuperRouter interface
    ISuperRouter superRouter;

    /// @dev Access Form interface to call form functions for assertions
    IERC4626TimelockForm public erc4626TimelockForm;

    /// @dev singleDestinationSingleVault Deposit test case
    function setUp() public override {
        super.setUp();

        primaryAMB = 1;
        secondaryAMBs = [2];
        CHAIN_0 = OP; /// @dev source chain id6
        DST_CHAINS = [POLY]; /// @dev destination chain(s) id4

        /// @dev You can define settings here or at the level of individual tests
        dstChainID = DST_CHAINS[0]; /// id4
        dstVaultID = 0; /// vault 
        dstFormID = 1; /// index to access in array of forms at BaseSetup level
        amount = 1000;
        slippage = 1000;
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

        /*///////////////////////////////////////////////////////////////
                                STATE SETUP
        //////////////////////////////////////////////////////////////*/
        
        address _superRouter = contracts[CHAIN_0][
            bytes32(bytes("SuperRouter"))
        ];
        
        address _superForm = getContract(
            dstChainID,
            string.concat(
                UNDERLYING_TOKENS[0],
                "SuperForm",
                Strings.toString(FORM_BEACON_IDS[1])
            )
        );

        console.log("selected superForm", _superForm);

        superRouter = ISuperRouter(_superRouter);
        erc4626TimelockForm = IERC4626TimelockForm(_superForm);

        /// @dev Here, however, dstFormId == 2, as that's the indexing inside of an array. 1 = erc4626form, 2 = erc4626timelockform
        uint256 _formId = _packSuperForm(_superForm, timelockFormType, dstChainID);
        
        /// @dev Individual setting for deposit call (overwrite again for withdraw)
        dstChainID = DST_CHAINS[0];
        dstVaultID = 0;
        dstFormID = 1;
        amount = 1000;
        slippage = 1000;

        /*///////////////////////////////////////////////////////////////
                                DEPOSIT ACTION
        //////////////////////////////////////////////////////////////*/

        /// NOTE: Individual deposit/withdraw invocation allows to make asserts in between
        TestAction memory action = _depositAction(
            dstChainID,
            dstVaultID,
            dstFormID, // formID, 0 == ERC4626Form, 1 == ERC4626Timelock
            amount,
            slippage,
            TestType.Pass
        );

        MultiVaultsSFData[] memory multiSuperFormsData;
        SingleVaultSFData[] memory singleSuperFormsData;
        MessagingAssertVars memory aV;
        StagesLocalVars memory vars;
        bool success;

        /// NOTE: What if we want to send from different EOA than deployer's?
        /// NOTE: Unsure if we need multi/singleSuperFormsData returned here if we can read state between calls now

        console.log("stage0 deposit");

        /// @dev User builds his request data for src (deposit action)
        /// NOTE: SuperForm API operation, could be separated from individual test-flow  (internal processing)
        (
            multiSuperFormsData,
            singleSuperFormsData,
            vars
        ) = _stage1_buildReqData(action, actionId);

        /// @dev Increment actionId AFTER each buildReqData() call
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
                            TODO: DEPOSIT ASSERTS
        //////////////////////////////////////////////////////////////*/

        uint256 balanceOfAlice = superRouter.balanceOf(users[0], _formId);
        assertEq(balanceOfAlice, 1000);

        /*///////////////////////////////////////////////////////////////
                                WITHDRAW ACTION
        //////////////////////////////////////////////////////////////*/

        /// @dev Individual setting for deposit call (overwrite again for withdraw)
        /// NOTE: Having mutability for those allows to test with fuzzing on range of random params
        dstChainID = DST_CHAINS[0];
        dstVaultID = 0;
        dstFormID = 1;
        amount = 1000;
        slippage = 1000;

        action = _withdrawAction(
            dstChainID,
            dstVaultID,
            dstFormID, // formID, 0 == ERC4626Form, 1 == ERC4626Timelock
            amount,
            slippage,
            TestType.Pass
        );

        /// @dev TODO: Repeated
        (
            multiSuperFormsData,
            singleSuperFormsData,
            vars
        ) = _stage1_buildReqData(action, actionId);

        /// @dev Increment after building request
        actionId++;

        console.log("stage1 done");

        /// @dev User sends his request data to the src (withdraw action)
        (vars, aV) = _stage2_run_src_action(
            action,
            multiSuperFormsData,
            singleSuperFormsData,
            vars
        );

        console.log("stage2 done");

        /// @dev TODO Repeated
        _stage3_src_to_dst_amb_delivery(
            action,
            vars,
            aV,
            multiSuperFormsData,
            singleSuperFormsData
        );

        console.log("stage3 done");

        /// @dev TODO Repeated
        success = _stage4_process_src_dst_payload(
            action,
            vars,
            aV,
            singleSuperFormsData,
            actionId
        );

        /*///////////////////////////////////////////////////////////////
                            TODO: WITHDRAW ASSERTS
        //////////////////////////////////////////////////////////////*/

        /// FIXME: This test actually proves that we burn shares but don't send anything back because we only requestUnlock!!! 
        balanceOfAlice = superRouter.balanceOf(users[0], _formId);
        assertEq(balanceOfAlice, 0);

    }

    /*///////////////////////////////////////////////////////////////
                        TEST INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _depositAction(
        uint16 chainID_,
        uint256 vaultID_,
        uint256 formID_,
        uint256 amount_,
        uint256 slippage_,
        TestType testType /// ProtocolActions invariant
    ) internal returns (TestAction memory depositAction) {
        /// @dev check if we need to have this here (it's being overriden)
        uint256 msgValue = 1 * _getPriceMultiplier(CHAIN_0) * 1e18;

        TARGET_UNDERLYING_VAULTS[chainID_][actionId] = [vaultID_];
        TARGET_FORM_KINDS[chainID_][actionId] = [formID_]; /// <= 1 for timelock, this accesses array by index (0 for standard)
        AMOUNTS[chainID_][actionId] = [amount_];
        MAX_SLIPPAGE[chainID_][actionId] = [slippage_];

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
        uint16 chainID_,
        uint256 vaultID_,
        uint256 formID_,
        uint256 amount_,
        uint256 slippage_,
        TestType testType /// ProtocolActions invariant
    ) internal returns (TestAction memory withdrawAction) {
        /// @dev check if we need to have this here (it's being overriden)
        uint256 msgValue = 1 * _getPriceMultiplier(CHAIN_0) * 1e18;

        TARGET_UNDERLYING_VAULTS[chainID_][actionId] = [vaultID_];
        TARGET_FORM_KINDS[chainID_][actionId] = [formID_];
        AMOUNTS[chainID_][actionId] = [amount_];
        MAX_SLIPPAGE[chainID_][actionId] = [slippage_];

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

}

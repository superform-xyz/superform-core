/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../types/LiquidityTypes.sol";
import "../types/DataTypes.sol";
import "forge-std/console.sol";

// Test Utils
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/ProtocolActions.sol";

import {ISuperRouter} from "../interfaces/ISuperRouter.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import {IERC4626Form} from "./interfaces/IERC4626Form.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @dev TODO - we should do assertions on final balances of users at the end of each test scenario
/// @dev FIXME - using unoptimized multiDstMultivault function
contract Scenario4Test is ProtocolActions {
    /// @dev Global counter for actions sent to the protocol
    uint256 actionId;

    /// @dev Access SuperRouter interface
    ISuperRouter superRouter;

    /// @dev Access SuperPositions interface
    IERC1155 superPositions;

    /// @dev Access Form interface to call form functions for assertions
    IERC4626Form public erc4626Form;

    address _superRouter;
    address _stateRegistry;
    address _superPositions;

    /// @dev Global variable for timelockForm type. Different from dstFormID which is an index to access FORM_BEACON_IDS in BaseSetup
    uint256 formType = 1;

    /// @dev Global and default set of variables for setting single action to build deposit/withdraw requests
    uint16[] dstChainID;
    uint256[] dstVaultID;
    uint256[] dstFormID;
    uint256[] amount;
    uint256[] slippage;

    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev singleDestinationXChainDeposit Full singleDestinationXChainWithdraw Deposit test case

        primaryAMB = 1;

        secondaryAMBs = [2];

        CHAIN_0 = ETH;
        DST_CHAINS = [ARBI];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYING_VAULTS[ARBI][0] = [2];
        TARGET_FORM_KINDS[ARBI][0] = [0];

        TARGET_UNDERLYING_VAULTS[ARBI][1] = [2];
        TARGET_FORM_KINDS[ARBI][1] = [0];

        AMOUNTS[ARBI][0] = [1000];
        AMOUNTS[ARBI][1] = [1000];

        MAX_SLIPPAGE[ARBI][0] = [1000];
        MAX_SLIPPAGE[ARBI][1] = [1000];

        /// @dev check if we need to have this here (it's being overriden)
        uint256 msgValue = 1 * _getPriceMultiplier(CHAIN_0) * 1e18;

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
                adapterParam: "",
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
                adapterParam: "",
                msgValue: msgValue,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
            })
        );

        // dstChainID = DST_CHAINS; /// id4
        // dstVaultID = [0]; /// vault
        // dstFormID = [0]; /// index to access in array of forms at BaseSetup level == TimelockForm == FORM_BEACON_IDS[1]
        // amount = [1000];
        // slippage = [1000];

        /*///////////////////////////////////////////////////////////////
                                STATE SETUP
        //////////////////////////////////////////////////////////////*/

        _superRouter = contracts[CHAIN_0][bytes32(bytes("SuperRouter"))];

        _stateRegistry = contracts[CHAIN_0][bytes32(bytes("SuperRegistry"))];

        superRouter = ISuperRouter(_superRouter);

        /// TODO: User ERC1155s
        superPositions = IERC1155(
            ISuperRegistry(_stateRegistry).superPositions()
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

            (
                multiSuperFormsData,
                singleSuperFormsData,
                vars
            ) = _stage1_buildReqData(action, act);

            /// @dev NOTE: setApprovalForAll happens in _buildSingleVaultWithdrawCallData

            vars = _stage2_run_src_action(
                action,
                multiSuperFormsData,
                singleSuperFormsData,
                vars
            );

            aV = _stage3_src_to_dst_amb_delivery(
                action,
                vars,
                multiSuperFormsData,
                singleSuperFormsData
            );

            success = _stage4_process_src_dst_payload(
                action,
                vars,
                aV,
                singleSuperFormsData,
                act
            );

            if (!success) {
                continue;
            }

            if (
                action.action == Actions.Deposit ||
                action.action == Actions.DepositPermit2
            ) {
                success = _stage5_process_superPositions_mint(action, vars);
                if (!success) {
                    continue;
                }
            }

            if (action.action == Actions.Withdraw) {
                /// @dev Process payload received on source from destination (withdraw callback)
                success = _stage6_process_superPositions_withdraw(action, vars);
            }
        }
    }

    // function test_scenario_full_withdraw() public {
    //     /*///////////////////////////////////////////////////////////////
    //                             STATE SETUP
    //     //////////////////////////////////////////////////////////////*/

    //     address _superForm = getContract(
    //         dstChainID[0], /// temp select by index
    //         string.concat(
    //             UNDERLYING_TOKENS[0], /// <= Arbitrary choice as BaseSetup deploys all vaults & deals all tokens to users TODO: cleanup
    //             "SuperForm",
    //             Strings.toString(FORM_BEACON_IDS[0])
    //         )
    //     );

    //     erc4626Form = IERC4626Form(_superForm);

    //     /// @dev Here, however, dstFormId == 2, as that's the indexing inside of an array. 1 = erc4626form, 2 = erc4626Form
    //     uint256 _formId = _packSuperForm(
    //         _superForm,
    //         formType,
    //         dstChainID[0] /// temp select by index
    //     );

    //     /// @dev Individual setting for deposit call (overwrite again for withdraw)
    //     dstChainID = DST_CHAINS; /// id4
    //     dstVaultID = [0]; /// vault
    //     dstFormID = [0]; /// index to access in array of forms at BaseSetup level == TimelockForm == FORM_BEACON_IDS[1]
    //     amount = [1000];
    //     slippage = [1000];

    //     /*///////////////////////////////////////////////////////////////
    //                             DEPOSIT ACTION
    //     //////////////////////////////////////////////////////////////*/

    //     uint256 currentBalanceOfAliceSP = superPositions.balanceOf(
    //         users[0],
    //         _formId
    //     );

    //     uint256 currentBalanceOfAliceUnderlying = IERC20(
    //         erc4626Form.getUnderlyingOfVault()
    //     ).balanceOf(users[0]);
    //     uint256 previewDepositToExpectedAmountOfSP = erc4626Form
    //         .previewDepositTo(amount[0]); /// temp select by index

    //     assertEq(currentBalanceOfAliceSP, 0);

    //     /// NOTE: Individual deposit/withdraw invocation allows to make asserts in between
    //     TestAction memory action = _createAction(
    //         dstChainID,
    //         dstVaultID,
    //         dstFormID, // formID, 0 == ERC4626Form, 1 == ERC4626Timelock
    //         amount,
    //         slippage,
    //         Actions.Deposit,
    //         TestType.Pass
    //     );

    //     MultiVaultsSFData[] memory multiSuperFormsData;
    //     SingleVaultSFData[] memory singleSuperFormsData;
    //     MessagingAssertVars[] memory aV;
    //     StagesLocalVars memory vars;
    //     bool success;

    //     /// NOTE: What if we want to send from different EOA than deployer's?
    //     /// NOTE: Unsure if we need multi/singleSuperFormsData returned here if we can read state between calls now

    //     console.log("stage0 deposit");

    //     /// @dev User builds his request data for src (deposit action)
    //     /// NOTE: SuperForm API operation, could be separated from individual test-flow  (internal processing)
    //     (
    //         multiSuperFormsData,
    //         singleSuperFormsData,
    //         vars
    //     ) = _stage1_buildReqData(action, actionId);

    //     /// @dev Increment actionId AFTER each buildReqData() call
    //     actionId++;

    //     console.log("stage1 done");

    //     /// @dev User sends his request data to the src (deposit action)
    //     vars = _stage2_run_src_action(
    //         action,
    //         multiSuperFormsData,
    //         singleSuperFormsData,
    //         vars
    //     );

    //     console.log("stage2 done");

    //     /// @dev FIXME? SuperForm Keepers operation, could be separated from individual test-flow (internal processing)
    //     aV = _stage3_src_to_dst_amb_delivery(
    //         action,
    //         vars,
    //         multiSuperFormsData,
    //         singleSuperFormsData
    //     );

    //     console.log("stage3 done");

    //     /// @dev FIXME? SuperForm Keepers operation, could be separated from individual test-flow (internal processing)
    //     success = _stage4_process_src_dst_payload(
    //         action,
    //         vars,
    //         aV,
    //         singleSuperFormsData,
    //         actionId
    //     );

    //     console.log("stage4 done");

    //     /// @dev FIXME? SuperForm Keepers operation, not relevant to depositor, should be separated for Form testing (internal processing)
    //     success = _stage5_process_superPositions_mint(action, vars);

    //     console.log("stage5 done");

    //     /*///////////////////////////////////////////////////////////////
    //                         TODO: DEPOSIT ASSERTS
    //     //////////////////////////////////////////////////////////////*/

    //     /// assert alice balanceOf SuperPositions before && after
    //     currentBalanceOfAliceSP = superPositions.balanceOf(users[0], _formId);
    //     assertEq(currentBalanceOfAliceSP, 1000);
    //     /// assert alice balanceOf underlying token before && after
    //     uint256 newBalanceOfAliceUnderlying = IERC20(
    //         erc4626Form.getUnderlyingOfVault()
    //     ).balanceOf(users[0]);

    //     assertEq(
    //         newBalanceOfAliceUnderlying,
    //         currentBalanceOfAliceUnderlying - amount[0] /// temp select by index
    //     );
    //     /// assert expected amount of SuperPosition (shares on Form) token received from previewDepositTo
    //     assertEq(previewDepositToExpectedAmountOfSP, currentBalanceOfAliceSP);

    //     /*///////////////////////////////////////////////////////////////
    //                             WITHDRAW ACTION
    //     //////////////////////////////////////////////////////////////*/

    //     /// @dev Individual setting for deposit call (overwrite again for withdraw)
    //     /// NOTE: Having mutability for those allows to test with fuzzing on range of random params
    //     dstChainID = DST_CHAINS; /// id4
    //     dstVaultID = [0]; /// vault
    //     dstFormID = [0]; /// index to access in array of forms at BaseSetup level == TimelockForm == FORM_BEACON_IDS[1]
    //     amount = [1000];
    //     slippage = [1000];

    //     action = _createAction(
    //         dstChainID,
    //         dstVaultID,
    //         dstFormID, // formID, 0 == ERC4626Form, 1 == ERC4626Timelock
    //         amount,
    //         slippage,
    //         Actions.Withdraw,
    //         TestType.Pass
    //     );

    //     /// @dev TODO: Repeated
    //     (
    //         multiSuperFormsData,
    //         singleSuperFormsData,
    //         vars
    //     ) = _stage1_buildReqData(action, actionId);

    //     /// @dev Increment after building request
    //     actionId++;

    //     console.log("stage1 done");

    //     /// @dev TODO: Remove MAX APPROVE and use SINGLE APPROVE with amount
    //     vm.prank(action.user);
    //     superPositions.setApprovalForAll(address(superRouter), true);

    //     vars = _stage2_run_src_action(
    //         action,
    //         multiSuperFormsData,
    //         singleSuperFormsData,
    //         vars
    //     );

    //     console.log("stage2 done");

    //     /// @dev Deliver message from source to destination (withdraw action)
    //     aV = _stage3_src_to_dst_amb_delivery(
    //         action,
    //         vars,
    //         multiSuperFormsData,
    //         singleSuperFormsData
    //     );

    //     console.log("stage3 done");

    //     /// @dev Process payload stored on destination to be delivered on source (withdraw callback)
    //     success = _stage4_process_src_dst_payload(
    //         action,
    //         vars,
    //         aV,
    //         singleSuperFormsData,
    //         actionId
    //     );

    //     console.log("stage4 done");

    //     /// @dev Process payload received on source from destination (withdraw callback)
    //     success = _stage6_process_superPositions_withdraw(action, vars);

    //     /*///////////////////////////////////////////////////////////////
    //                         TODO: WITHDRAW ASSERTS
    //     //////////////////////////////////////////////////////////////*/

    //     /// FIXME: This test actually proves that we burn shares but don't send anything back because we only requestUnlock!!!
    //     currentBalanceOfAliceSP = superPositions.balanceOf(users[0], _formId);
    //     /// FIXME: 0 Set only so test would pass!!! This is upstream problem!!!
    //     assertEq(currentBalanceOfAliceSP, 0);

    //     /// TODO:
    //     /// assert alice balanceOf SuperPositions before && after
    //     /// assert alice balanceOf underlying token before && after
    //     /// assert expected amount of underlying token received from previewWithdrawFrom
    // }

    // /*///////////////////////////////////////////////////////////////
    //                     TEST INTERNAL HELPERS
    // //////////////////////////////////////////////////////////////*/

    // function _createAction(
    //     uint16[] memory chainID_,
    //     uint256[] memory vaultIDs_,
    //     uint256[] memory formIDs_,
    //     uint256[] memory amounts_,
    //     uint256[] memory slippages_,
    //     Actions kind_, /// deposit or withdraw
    //     TestType testType /// ProtocolActions invariant
    // )
    //     internal
    //     returns (
    //         // bool multiVaults_
    //         TestAction memory action_
    //     )
    // {
    //     /// @dev check if we need to have this here (it's being overriden)
    //     uint256 msgValue = 1 * _getPriceMultiplier(CHAIN_0) * 1e18;

    //     for (uint256 i = 0; i < chainID_.length; i++) {
    //         /// temp select by index. TODO: actionId mechanics requires update!
    //         TARGET_UNDERLYING_VAULTS[chainID_[i]][actionId] = vaultIDs_;
    //         TARGET_FORM_KINDS[chainID_[i]][actionId] = formIDs_; /// <= 1 for timelock, this accesses array by index (0 for standard)
    //         AMOUNTS[chainID_[i]][actionId] = amounts_;
    //         MAX_SLIPPAGE[chainID_[i]][actionId] = slippages_;

    //         if (kind_ == Actions.Deposit) {
    //             action_ = TestAction({
    //                 action: Actions.Deposit,
    //                 multiVaults: false, //!!WARNING turn on or off multi vaults
    //                 user: users[0],
    //                 testType: TestType.Pass, /// NOTE: TestType should be low level invariant
    //                 revertError: "",
    //                 revertRole: "",
    //                 slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
    //                 multiTx: false,
    //                 adapterParam: "",
    //                 msgValue: msgValue
    //             });
    //         } else if (kind_ == Actions.Withdraw) {
    //             action_ = TestAction({
    //                 action: Actions.Withdraw,
    //                 multiVaults: false, //!!WARNING turn on or off multi vaults
    //                 user: users[0],
    //                 testType: TestType.Pass, /// NOTE: TestType should be low level invariant
    //                 revertError: "",
    //                 revertRole: "",
    //                 slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
    //                 multiTx: false,
    //                 adapterParam: "",
    //                 msgValue: msgValue
    //             });
    //         } else {
    //             revert("Action not supported");
    //         }
    //     }
    // }
}

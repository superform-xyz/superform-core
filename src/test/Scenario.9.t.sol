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
contract Scenario9Test is ProtocolActions {
    /// @dev Access SuperRouter interface
    ISuperRouter superRouter;

    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev singleDestinationSingleVault Deposit test case
        AMBs = [1, 2, 3];

        CHAIN_0 = OP;
        DST_CHAINS = [POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYING_VAULTS[POLY][0] = [1];

        TARGET_FORM_KINDS[POLY][0] = [0];

        AMOUNTS[POLY][0] = [231];

        MAX_SLIPPAGE[POLY][0] = [1000];

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
                msgValue: 75 * 10 ** 18,
                ambParams: generateAmbParams(DST_CHAINS.length, 3),
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
            })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario() public {
        address _superRouter = contracts[CHAIN_0][
            bytes32(bytes("SuperRouter"))
        ];
        superRouter = ISuperRouter(_superRouter);

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
                (action.action == Actions.Deposit ||
                    action.action == Actions.DepositPermit2) &&
                !(action.testType == TestType.RevertXChainDeposit)
            ) {
                success = _stage5_process_superPositions_mint(action, vars);
                if (!success) {
                    continue;
                }
            }
        }
    }
}

/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../types/LiquidityTypes.sol";
import "../types/DataTypes.sol";

// Test Utils
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/ProtocolActions.sol";
import "./utils/AmbParams.sol";

import {ISuperRouter} from "../interfaces/ISuperRouter.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

/// @dev TODO - we should do assertions on final balances of users at the end of each test scenario
/// @dev FIXME - using unoptimized multiDstMultivault function
contract Scenario11Test is ProtocolActions {
    /// @dev Access SuperRouter interface
    ISuperRouter superRouter;

    /// @dev Access SuperPositions interface
    IERC1155 superPositions;

    address _superRouter;
    address _stateRegistry;
    address _superPositions;

    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev singleDestinationMultiVault, same underlying test.
        /// @dev FIXME: currently not testing the case where we mix liq bridges but underlyings are the same (protocol actions is only picking up the first liq bridge kind)

        AMBs = [1, 2];

        CHAIN_0 = ETH;
        DST_CHAINS = [ARBI];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYING_VAULTS[ARBI][0] = [1, 1, 1];
        TARGET_FORM_KINDS[ARBI][0] = [0, 0, 0];

        TARGET_UNDERLYING_VAULTS[ARBI][1] = [1, 1, 1];
        TARGET_FORM_KINDS[ARBI][1] = [0, 0, 0];

        AMOUNTS[ARBI][0] = [7000, 1000, 2000];
        AMOUNTS[ARBI][1] = [7000, 1000, 2000];

        MAX_SLIPPAGE[ARBI][0] = [1000, 1000, 1000];
        MAX_SLIPPAGE[ARBI][1] = [1000, 1000, 1000];

        LIQ_BRIDGES[ARBI][0] = [1, 2, 1];
        LIQ_BRIDGES[ARBI][1] = [1, 1, 2];

        /// @dev check if we need to have this here (it's being overriden)
        uint256 msgValue = 5 * _getPriceMultiplier(CHAIN_0) * 1e18;

        /// @dev push in order the actions should be executed
        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
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
                multiVaults: true, //!!WARNING turn on or off multi vaults
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

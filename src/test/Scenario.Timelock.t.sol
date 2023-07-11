/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../types/LiquidityTypes.sol";
import "../types/DataTypes.sol";

// Test Utils
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/ProtocolActions.sol";
import "./utils/AmbParams.sol";

import {ISuperFormRouter} from "../interfaces/ISuperFormRouter.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

contract ScenarioTimelockTest is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev singleDestinationSingleVault, Timelocked, same underlying test.

        AMBs = [1, 2];

        CHAIN_0 = POLY;
        DST_CHAINS = [POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[POLY][0] = [1];
        TARGET_VAULTS[POLY][0] = [1];
        TARGET_FORM_KINDS[POLY][0] = [1];

        TARGET_UNDERLYINGS[POLY][1] = [1];
        TARGET_VAULTS[POLY][1] = [1];
        TARGET_FORM_KINDS[POLY][1] = [1];

        AMOUNTS[POLY][0] = [7722];
        AMOUNTS[POLY][1] = [7722];

        MAX_SLIPPAGE[POLY][0] = [1000];
        MAX_SLIPPAGE[POLY][1] = [1000];

        LIQ_BRIDGES[POLY][0] = [1];
        LIQ_BRIDGES[POLY][1] = [1];

        vm.selectFork(FORKS[CHAIN_0]);

        /// @dev push in order the actions should be executed
        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 1,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                ambParams: generateCoreStateRegistryParams(DST_CHAINS, AMBs),
                msgValue: estimateMsgValue(DST_CHAINS, AMBs, generateExtraData(AMBs)),
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
            })
        );

        actions.push(
            TestAction({
                action: Actions.Withdraw,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 1,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                ambParams: generateCoreStateRegistryParams(DST_CHAINS, AMBs),
                msgValue: estimateMsgValue(DST_CHAINS, AMBs, generateExtraData(AMBs)),
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
            })
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

            _runMainStages(action, act, multiSuperFormsData, singleSuperFormsData, aV, vars, success);
        }
    }
}

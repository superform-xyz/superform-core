/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../../types/LiquidityTypes.sol";
import "../../types/DataTypes.sol";

// Test Utils
import {MockERC20} from "../mocks/MockERC20.sol";
import "../utils/ProtocolActions.sol";
import "../utils/AmbParams.sol";

import {ISuperFormRouter} from "../../interfaces/ISuperFormRouter.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

/// @dev TODO - we should do assertions on final balances of users at the end of each test scenario
/// @dev FIXME - using unoptimized multiDstMultivault function
contract MDMVW00001200TokenInputSlipapgeL1AMB12 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev singleDestinationMultiVault, large test

        AMBs = [1, 2];
        MultiDstAMBs = [AMBs, AMBs];

        CHAIN_0 = ETH;
        DST_CHAINS = [ARBI, POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        /// first 3 superforms are equal
        TARGET_UNDERLYINGS[ARBI][0] = [1, 1, 1, 0];
        TARGET_VAULTS[ARBI][0] = [0, 0, 0, 0]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ARBI][0] = [0, 0, 0, 0];

        /// all superforms are different
        TARGET_UNDERLYINGS[POLY][0] = [0, 0, 0, 2];
        TARGET_VAULTS[POLY][0] = [1, 2, 0, 0]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[POLY][0] = [1, 2, 0, 0];

        TARGET_UNDERLYINGS[ARBI][1] = [1, 1, 1, 0];
        TARGET_VAULTS[ARBI][1] = [0, 0, 0, 0]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ARBI][1] = [0, 0, 0, 0];

        TARGET_UNDERLYINGS[POLY][1] = [0, 0, 0, 2];
        TARGET_VAULTS[POLY][1] = [1, 2, 0, 0]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[POLY][1] = [1, 2, 0, 0];

        AMOUNTS[ARBI][0] = [111, 222, 333, 444];
        AMOUNTS[ARBI][1] = [11, 222, 333, 444];

        /// @dev first 3 vaults are equal, we mark them all as partial, even if only 1 amount is partial, otherwise assertions do not pass
        PARTIAL[ARBI][1] = [true, true, true, false];

        AMOUNTS[POLY][0] = [2, 3, 4, 5];
        AMOUNTS[POLY][1] = [2, 3, 4, 5];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ARBI][0] = [1, 2, 1, 2];
        LIQ_BRIDGES[ARBI][1] = [1, 1, 2, 2];

        LIQ_BRIDGES[POLY][0] = [1, 2, 1, 2];
        LIQ_BRIDGES[POLY][1] = [1, 1, 2, 2];

        /// @dev push in order the actions should be executed
        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 1,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 222, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                externalToken: 1 // 0 = DAI, 1 = USDT, 2 = WETH
            })
        );

        actions.push(
            TestAction({
                action: Actions.Withdraw,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 1,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 222, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
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

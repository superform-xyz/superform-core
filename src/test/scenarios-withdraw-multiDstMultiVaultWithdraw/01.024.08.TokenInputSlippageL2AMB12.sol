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
contract MDMVW0102408NativeInputSlipapgeL2AMB12 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev singleDestinationMultiVault, large test

        AMBs = [1, 2];
        MultiDstAMBs = [AMBs, AMBs, AMBs];

        CHAIN_0 = ETH;
        DST_CHAINS = [ETH, POLY, AVAX];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        /// first 3 superforms are equal
        TARGET_UNDERLYINGS[ETH][0] = [2, 2];
        TARGET_VAULTS[ETH][0] = [0, 1]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ETH][0] = [0, 1];

        /// all superforms are different
        TARGET_UNDERLYINGS[POLY][0] = [0, 1, 2];
        TARGET_VAULTS[POLY][0] = [0, 2, 4]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[POLY][0] = [0, 2, 1];

        /// all superforms are different
        TARGET_UNDERLYINGS[AVAX][0] = [2, 2];
        TARGET_VAULTS[AVAX][0] = [0, 8]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[AVAX][0] = [0, 0];

        TARGET_UNDERLYINGS[ETH][1] = [2, 2];
        TARGET_VAULTS[ETH][1] = [0, 1]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ETH][1] = [0, 1];

        /// all superforms are different
        TARGET_UNDERLYINGS[POLY][1] = [0, 1, 2];
        TARGET_VAULTS[POLY][1] = [0, 2, 4]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[POLY][1] = [0, 2, 1];

        /// all superforms are different
        TARGET_UNDERLYINGS[AVAX][1] = [2, 2];
        TARGET_VAULTS[AVAX][1] = [0, 8]; /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[AVAX][1] = [0, 0];

        AMOUNTS[ETH][0] = [25, 5235];
        AMOUNTS[ETH][1] = [11, 5235];

        PARTIAL[ETH][1] = [true, false];

        AMOUNTS[POLY][0] = [9765, 9765, 222];
        AMOUNTS[POLY][1] = [9765, 9765, 2];

        PARTIAL[POLY][1] = [false, false, true];

        AMOUNTS[AVAX][0] = [7342, 1243];
        AMOUNTS[AVAX][1] = [7342, 1243];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ETH][0] = [2, 2, 2, 2];
        LIQ_BRIDGES[ETH][1] = [2, 2, 2, 2];

        LIQ_BRIDGES[POLY][0] = [2, 2, 2, 2];
        LIQ_BRIDGES[POLY][1] = [2, 2, 2, 2];

        LIQ_BRIDGES[AVAX][0] = [2, 2, 2, 2];
        LIQ_BRIDGES[AVAX][1] = [2, 2, 2, 2];

        /// @dev push in order the actions should be executed
        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 1,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 643, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: true,
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
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
                slippage: 643, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                externalToken: 1 // 0 = DAI, 1 = USDT, 2 = WETH
            })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario() public {
        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperFormsData;
            SingleVaultSFData[] memory singleSuperFormsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            _runMainStages(action, act, multiSuperFormsData, singleSuperFormsData, aV, vars, success);
        }
    }
}

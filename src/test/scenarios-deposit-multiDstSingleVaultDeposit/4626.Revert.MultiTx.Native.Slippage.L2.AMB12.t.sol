/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../../types/LiquidityTypes.sol";
import "../../types/DataTypes.sol";

// Test Utils
import {MockERC20} from "../mocks/MockERC20.sol";
import "../utils/ProtocolActions.sol";
import "../utils/AmbParams.sol";

contract MDSVDNormal4626RevertMultiTxTokenInputSlippageL2AMB1 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 2];
        MultiDstAMBs = [AMBs, AMBs, AMBs];

        CHAIN_0 = OP;
        DST_CHAINS = [POLY, AVAX, OP];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[POLY][0] = [0];
        TARGET_UNDERLYINGS[AVAX][0] = [1];
        TARGET_UNDERLYINGS[OP][0] = [2];

        TARGET_VAULTS[POLY][0] = [3];
        TARGET_VAULTS[AVAX][0] = [3];
        TARGET_VAULTS[OP][0] = [3];

        TARGET_FORM_KINDS[POLY][0] = [0];
        TARGET_FORM_KINDS[AVAX][0] = [0];
        TARGET_FORM_KINDS[OP][0] = [0];

        AMOUNTS[POLY][0] = [4214];
        AMOUNTS[AVAX][0] = [6562];
        AMOUNTS[OP][0] = [7777];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[POLY][0] = [2];
        LIQ_BRIDGES[AVAX][0] = [2];
        LIQ_BRIDGES[OP][0] = [2];

        /// @dev define the test type for every destination chain and for every action
        /// should allow us to revert on specific destination calls, such as specific updatePayloads, specific processPayloads, etc.

        TEST_TYPE_PER_DST[POLY][0] = TestType.Pass;
        TEST_TYPE_PER_DST[AVAX][0] = TestType.Pass;
        TEST_TYPE_PER_DST[OP][0] = TestType.Pass;

        actions.push(
            TestAction({
                action: Actions.DepositPermit2,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 742, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: true,
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
            })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario() public {
        for (uint256 act; act < actions.length; act++) {
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

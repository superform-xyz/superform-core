/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../../types/LiquidityTypes.sol";
import "../../types/DataTypes.sol";

// Test Utils
import "../utils/ProtocolActions.sol";
import "../utils/AmbParams.sol";

/// @dev TODO - we should do assertions on final balances of users at the end of each test scenario
/// @dev FIXME - using unoptimized multiDstMultivault function
contract MDMVDMulti01NoMultiTxTokenInputNoSlippageL2AMB13 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev singleDestinationMultiVault Deposit test case
        AMBs = [1, 3];
        MultiDstAMBs = [AMBs, AMBs];

        CHAIN_0 = ARBI;
        DST_CHAINS = [ETH, AVAX];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ETH][0] = [0];
        TARGET_UNDERLYINGS[AVAX][0] = [1];

        TARGET_VAULTS[ETH][0] = [0]; /// @dev id 0 is normal 4626
        TARGET_VAULTS[AVAX][0] = [0]; /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[ETH][0] = [0];
        TARGET_FORM_KINDS[AVAX][0] = [0];

        AMOUNTS[ETH][0] = [45512];
        AMOUNTS[AVAX][0] = [123333123131];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[ETH][0] = [2];
        LIQ_BRIDGES[AVAX][0] = [2];

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
                externalToken: 1 // 0 = DAI, 1 = USDT, 2 = WETH
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

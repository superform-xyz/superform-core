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
contract MDMVDMulti102115000MultiTxNativeSlippageL12AMB13 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/

        AMBs = [1, 3];
        MultiDstAMBs = [AMBs, AMBs, AMBs];

        CHAIN_0 = OP;
        DST_CHAINS = [ARBI, ETH, AVAX];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ARBI][0] = [0, 1, 0];
        TARGET_UNDERLYINGS[ETH][0] = [1, 1, 0];
        TARGET_UNDERLYINGS[AVAX][0] = [1, 1, 0];

        TARGET_VAULTS[ARBI][0] = [1, 0, 2]; /// @dev id 0 is normal 4626
        TARGET_VAULTS[ETH][0] = [1, 1, 5]; /// @dev id 0 is normal 4626
        TARGET_VAULTS[AVAX][0] = [0, 0, 0]; /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[ARBI][0] = [1, 0, 2];
        TARGET_FORM_KINDS[ETH][0] = [1, 1, 1];
        TARGET_FORM_KINDS[AVAX][0] = [0, 0, 0];

        AMOUNTS[ARBI][0] = [766324, 987, 132];
        AMOUNTS[ETH][0] = [1233, 4421, 2];
        AMOUNTS[AVAX][0] = [11, 22, 33];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[ARBI][0] = [2, 2, 1];
        LIQ_BRIDGES[ETH][0] = [2, 1, 2];
        LIQ_BRIDGES[AVAX][0] = [1, 2, 1];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 777, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: true,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
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

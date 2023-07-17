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
contract MDMVDMulti111563NoMultiTxTokenInputSlippageL1AMB12 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/

        AMBs = [1, 2];
        MultiDstAMBs = [AMBs, AMBs];

        CHAIN_0 = ETH;
        DST_CHAINS = [AVAX, OP];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [2, 2, 2];
        TARGET_UNDERLYINGS[OP][0] = [2, 2, 2];

        TARGET_VAULTS[AVAX][0] = [1, 1, 1]; /// @dev id 0 is normal 4626
        TARGET_VAULTS[OP][0] = [5, 6, 3]; /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[AVAX][0] = [1, 1, 1];
        TARGET_FORM_KINDS[OP][0] = [1, 2, 0];

        AMOUNTS[AVAX][0] = [999, 9999, 99999];
        AMOUNTS[OP][0] = [5435, 5543, 5557];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[AVAX][0] = [1, 1, 1];
        LIQ_BRIDGES[OP][0] = [1, 1, 1];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 512, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
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

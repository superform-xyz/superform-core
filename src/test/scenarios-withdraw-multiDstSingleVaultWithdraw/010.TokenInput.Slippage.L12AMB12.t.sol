/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../../types/LiquidityTypes.sol";
import "../../types/DataTypes.sol";

// Test Utils
import "../utils/ProtocolActions.sol";
import "../utils/AmbParams.sol";

contract MDSVW010NativeSlippageL12AMB12 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 2];
        MultiDstAMBs = [AMBs, AMBs, AMBs];

        CHAIN_0 = ARBI;
        DST_CHAINS = [ARBI, OP, AVAX];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ARBI][0] = [2];
        TARGET_UNDERLYINGS[OP][0] = [1];
        TARGET_UNDERLYINGS[AVAX][0] = [1];

        TARGET_VAULTS[ARBI][0] = [0]; /// @dev id 0 is normal 4626
        TARGET_VAULTS[OP][0] = [1]; /// @dev id 0 is normal 4626
        TARGET_VAULTS[AVAX][0] = [0]; /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[ARBI][0] = [0];
        TARGET_FORM_KINDS[OP][0] = [1];
        TARGET_FORM_KINDS[AVAX][0] = [0];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ARBI][1] = [2];
        TARGET_UNDERLYINGS[OP][1] = [1];
        TARGET_UNDERLYINGS[AVAX][1] = [1];

        TARGET_VAULTS[ARBI][1] = [0]; /// @dev id 0 is normal 4626
        TARGET_VAULTS[OP][1] = [1]; /// @dev id 0 is normal 4626
        TARGET_VAULTS[AVAX][1] = [0]; /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[ARBI][1] = [0];
        TARGET_FORM_KINDS[OP][1] = [1];
        TARGET_FORM_KINDS[AVAX][1] = [0];

        AMOUNTS[ARBI][0] = [777];
        AMOUNTS[OP][0] = [955];
        AMOUNTS[AVAX][0] = [42141];

        AMOUNTS[ARBI][1] = [777];
        AMOUNTS[OP][1] = [955];
        AMOUNTS[AVAX][1] = [42141];

        MAX_SLIPPAGE[ARBI][0] = [1000];
        MAX_SLIPPAGE[OP][0] = [1000];
        MAX_SLIPPAGE[AVAX][0] = [1000];

        MAX_SLIPPAGE[ARBI][1] = [1000];
        MAX_SLIPPAGE[OP][1] = [1000];
        MAX_SLIPPAGE[AVAX][1] = [1000];

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[ARBI][0] = [1];
        LIQ_BRIDGES[OP][0] = [1];
        LIQ_BRIDGES[AVAX][0] = [1];

        LIQ_BRIDGES[ARBI][1] = [2];
        LIQ_BRIDGES[OP][1] = [2];
        LIQ_BRIDGES[AVAX][1] = [2];

        vm.selectFork(FORKS[CHAIN_0]);

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 775, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                ambParams: generateCoreStateRegistryParams(DST_CHAINS, AMBs),
                msgValue: estimateMsgValue(DST_CHAINS, AMBs, generateExtraData(AMBs)),
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
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
                ambParams: generateCoreStateRegistryParams(DST_CHAINS, AMBs),
                msgValue: estimateMsgValue(DST_CHAINS, AMBs, generateExtraData(AMBs)),
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
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

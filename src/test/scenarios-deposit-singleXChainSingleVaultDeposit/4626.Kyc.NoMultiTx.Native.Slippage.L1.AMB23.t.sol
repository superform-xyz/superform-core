/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../../types/LiquidityTypes.sol";
import "../../types/DataTypes.sol";

// Test Utils
import "../utils/ProtocolActions.sol";
import "../utils/AmbParams.sol";

contract SXSVDKyc4626NoMultiTxNativeSlippageL1AMB23 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [2, 3];

        CHAIN_0 = ETH;
        DST_CHAINS = [ARBI];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ARBI][0] = [1];

        TARGET_VAULTS[ARBI][0] = [2]; /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[ARBI][0] = [2];

        AMOUNTS[ARBI][0] = [8213];

        MAX_SLIPPAGE[ARBI][0] = [1000];

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[ARBI][0] = [1];

        vm.selectFork(FORKS[CHAIN_0]);

        uint256 nativeTokenAmounts = 8213;

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 600, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                ambParams: generateCoreStateRegistryParams(DST_CHAINS, AMBs),
                msgValue: estimateMsgValue(DST_CHAINS, AMBs, generateExtraData(AMBs)) + nativeTokenAmounts,
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

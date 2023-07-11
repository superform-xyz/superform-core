/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../../types/LiquidityTypes.sol";
import "../../types/DataTypes.sol";

// Test Utils
import "../utils/ProtocolActions.sol";
import "../utils/AmbParams.sol";

contract MDSVDKYC4626MultiTxTokenInputSlippageL2AMB13 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 3];
        MultiDstAMBs = [AMBs, AMBs, AMBs];

        CHAIN_0 = BSC;
        DST_CHAINS = [AVAX, BSC, ETH];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [2];
        TARGET_UNDERLYINGS[BSC][0] = [2];
        TARGET_UNDERLYINGS[ETH][0] = [2];

        TARGET_VAULTS[AVAX][0] = [2]; /// @dev id 0 is normal 4626
        TARGET_VAULTS[BSC][0] = [2]; /// @dev id 0 is normal 4626
        TARGET_VAULTS[ETH][0] = [2]; /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[AVAX][0] = [2];
        TARGET_FORM_KINDS[BSC][0] = [2];
        TARGET_FORM_KINDS[ETH][0] = [2];

        AMOUNTS[AVAX][0] = [78];
        AMOUNTS[BSC][0] = [2]; /// @dev NOTE: for direct chain transfers, 2 is the minimum otherwise it reverts with ZERO_SHARES()
        AMOUNTS[ETH][0] = [7999];

        MAX_SLIPPAGE[AVAX][0] = [1000];
        MAX_SLIPPAGE[BSC][0] = [1000];
        MAX_SLIPPAGE[ETH][0] = [1000];

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[AVAX][0] = [2];
        LIQ_BRIDGES[BSC][0] = [2];
        LIQ_BRIDGES[ETH][0] = [2];

        vm.selectFork(FORKS[CHAIN_0]);

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 412, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: true,
                ambParams: generateCoreStateRegistryParams(DST_CHAINS, AMBs),
                msgValue: estimateMsgValue(DST_CHAINS, AMBs, generateExtraData(AMBs)),
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
            MultiVaultsSFData[] memory multiSuperFormsData;
            SingleVaultSFData[] memory singleSuperFormsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            _runMainStages(action, act, multiSuperFormsData, singleSuperFormsData, aV, vars, success);
        }
    }
}

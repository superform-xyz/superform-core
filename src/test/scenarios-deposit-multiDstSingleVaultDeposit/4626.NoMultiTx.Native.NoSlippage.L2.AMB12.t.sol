/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../utils/ProtocolActions.sol";

contract MDSVDNormal4626NoMultiTxNativeNoSlippageL2AMB12 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 2];
        MultiDstAMBs = [AMBs, AMBs, AMBs];

        CHAIN_0 = OP;
        DST_CHAINS = [AVAX, ETH, POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[AVAX][0] = [0];
        TARGET_UNDERLYINGS[ETH][0] = [0];
        TARGET_UNDERLYINGS[POLY][0] = [1];

        TARGET_VAULTS[AVAX][0] = [0]; /// @dev id 0 is normal 4626
        TARGET_VAULTS[ETH][0] = [0]; /// @dev id 0 is normal 4626
        TARGET_VAULTS[POLY][0] = [0]; /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[AVAX][0] = [0];
        TARGET_FORM_KINDS[ETH][0] = [0];
        TARGET_FORM_KINDS[POLY][0] = [0];

        AMOUNTS[AVAX][0] = [98512890];
        AMOUNTS[ETH][0] = [421821994];
        AMOUNTS[POLY][0] = [42134];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[AVAX][0] = [2];
        LIQ_BRIDGES[ETH][0] = [2];
        LIQ_BRIDGES[POLY][0] = [2];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
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
            MultiVaultSFData[] memory multiSuperFormsData;
            SingleVaultSFData[] memory singleSuperFormsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            _runMainStages(action, act, multiSuperFormsData, singleSuperFormsData, aV, vars, success);
        }
    }
}

/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../utils/ProtocolActions.sol";

contract SDMVDMulti021NoMultiTxNativeSlippageL12AMB23 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/

        AMBs = [2, 3];

        CHAIN_0 = ARBI;
        DST_CHAINS = [ETH];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ETH][0] = [1, 1, 1];

        TARGET_VAULTS[ETH][0] = [0, 2, 1]; /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[ETH][0] = [0, 2, 1];

        AMOUNTS[ETH][0] = [4124, 144, 75];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[ETH][0] = [1, 2, 1];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 777, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
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
            MultiVaultSFData[] memory multiSuperFormsData;
            SingleVaultSFData[] memory singleSuperFormsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            _runMainStages(action, act, multiSuperFormsData, singleSuperFormsData, aV, vars, success);
        }
    }
}

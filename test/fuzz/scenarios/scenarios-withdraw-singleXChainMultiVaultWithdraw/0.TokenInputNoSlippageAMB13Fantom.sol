// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SDMVW0TokenInputNoSlippageAMB13Fantom is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/

        /// @dev singleDestinationMultiVault, large test
        AMBs = [3, 1];

        CHAIN_0 = ETH;
        DST_CHAINS = [FANTOM];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[FANTOM][0] = [1];
        TARGET_VAULTS[FANTOM][0] = [0];

        TARGET_FORM_KINDS[FANTOM][0] = [0];

        TARGET_UNDERLYINGS[FANTOM][1] = [1];
        TARGET_VAULTS[FANTOM][1] = [0];

        TARGET_FORM_KINDS[FANTOM][1] = [0];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[FANTOM][0] = [1];
        LIQ_BRIDGES[FANTOM][1] = [1];

        RECEIVE_4626[FANTOM][0] = [false];
        RECEIVE_4626[FANTOM][1] = [false];

        FINAL_LIQ_DST_WITHDRAW[FANTOM] = [ETH];

        /// @dev push in order the actions should be executed
        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 1,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        actions.push(
            TestAction({
                action: Actions.Withdraw,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 1,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 1 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario() public {
        AMOUNTS[FANTOM][0] = [3e18, 3e18, 3e18, 3e18];

        for (uint256 act = 0; act < actions.length; ++act) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            if (act == 1) {
                uint256[] memory superPositions = _getSuperpositionsForDstChain(
                    actions[1].user,
                    TARGET_UNDERLYINGS[DST_CHAINS[0]][1],
                    TARGET_VAULTS[DST_CHAINS[0]][1],
                    TARGET_FORM_KINDS[DST_CHAINS[0]][1],
                    DST_CHAINS[0]
                );

                AMOUNTS[FANTOM][1] = [superPositions[0]];
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
    }
}

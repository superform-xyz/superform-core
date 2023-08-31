/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SXSVWNormal4626NativeSlippageL1 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [2, 3];

        CHAIN_0 = OP;
        DST_CHAINS = [OP];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][0] = [0];

        TARGET_VAULTS[OP][0] = [0];

        /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[OP][0] = [0];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][1] = [0];

        TARGET_VAULTS[OP][1] = [0];

        /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[OP][1] = [0];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[OP][0] = [1];
        LIQ_BRIDGES[OP][1] = [1];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 312, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
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
                slippage: 312, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_) public {
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amountOne_ = uint128(bound(amountOne_, 2, TOTAL_SUPPLY_ETH));
        AMOUNTS[OP][0] = [amountOne_];
        /// @dev note that current socket/lifi mocks simulate swapping by directly minting WETH
        /// and burning DAI with a 1:1 price ratio, with no mint-cap on WETH supply hence these work
        /// off the hook, but should consider the correct price ratio to make it more mainnet-like

        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            if (act == 1) {
                for (uint256 i = 0; i < DST_CHAINS.length; i++) {
                    uint256[] memory superPositions = _getSuperpositionsForDstChain(
                        actions[1].user,
                        TARGET_UNDERLYINGS[DST_CHAINS[i]][1],
                        TARGET_VAULTS[DST_CHAINS[i]][1],
                        TARGET_FORM_KINDS[DST_CHAINS[i]][1],
                        DST_CHAINS[i]
                    );

                    AMOUNTS[DST_CHAINS[i]][1] = [superPositions[0]];
                }
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SXSVW5115NativeSlippageAMB23 is ProtocolActions {
    function setUp() public override {
        chainIds = [ETH, POLY, OP];

        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [2, 3];

        CHAIN_0 = POLY;
        DST_CHAINS = [OP];

        /// @dev "SY wstETH" vault on optimism. The base input token selected here is 4 (wstETH), but could be another
        /// supported by the vault (as long as there is a wrapper for it)
        TARGET_UNDERLYINGS[OP][0] = [4];

        TARGET_VAULTS[OP][0] = [9];

        TARGET_FORM_KINDS[OP][0] = [3];

        /// @dev The base output token selected here is 4 (wstETH), in the case of this vault it is the same as the
        /// input
        TARGET_UNDERLYINGS[OP][1] = [4];

        TARGET_VAULTS[OP][1] = [9];

        TARGET_FORM_KINDS[OP][1] = [3];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[OP][0] = [1];
        LIQ_BRIDGES[OP][1] = [1];

        RECEIVE_4626[OP][0] = [false];
        RECEIVE_4626[OP][1] = [false];

        GENERATE_WITHDRAW_TX_DATA_ON_DST = true;

        FINAL_LIQ_DST_WITHDRAW[OP] = [OP];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 312, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 69_420 // 0 = DAI, 1 = USDT, 2 = WETH
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
                slippage: 22, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_) public {
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amountOne_ = uint128(bound(amountOne_, 2e18, 10e18));
        AMOUNTS[OP][0] = [amountOne_];

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

                AMOUNTS[OP][1] = [superPositions[0]];
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
    }
}

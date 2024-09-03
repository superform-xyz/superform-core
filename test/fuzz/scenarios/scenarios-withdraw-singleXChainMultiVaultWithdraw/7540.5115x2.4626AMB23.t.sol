// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SXMVW754051154626SlippageAMB23 is ProtocolActions {
    function setUp() public override {
        chainIds = [ETH, OP];

        super.setUp();

        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/
        AMBs = [2, 1];

        CHAIN_0 = OP;
        DST_CHAINS = [ETH];

        TARGET_UNDERLYINGS[ETH][0] = [0, 3, 5, 4];
        TARGET_VAULTS[ETH][0] = [4, 3, 3, 0];
        TARGET_FORM_KINDS[ETH][0] = [2, 1, 1, 0];

        TARGET_UNDERLYINGS[ETH][1] = [0, 3, 5, 4];
        TARGET_VAULTS[ETH][1] = [4, 3, 3, 0];
        TARGET_FORM_KINDS[ETH][1] = [2, 1, 1, 0];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ETH][0] = [1, 1, 1, 1];
        LIQ_BRIDGES[ETH][1] = [1, 1, 1, 1];

        RECEIVE_4626[ETH][0] = [false, false, false, false];
        RECEIVE_4626[ETH][1] = [false, false, false, false];

        GENERATE_WITHDRAW_TX_DATA_ON_DST = true;

        FINAL_LIQ_DST_WITHDRAW[ETH] = [OP, OP, OP, OP];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 111, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        actions.push(
            TestAction({
                action: Actions.Withdraw,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 421, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_) public {
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amountOne_ = uint128(bound(amountOne_, 2e18, 10e18));
        AMOUNTS[ETH][0] = [amountOne_, amountOne_, amountOne_, amountOne_];

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

                AMOUNTS[ETH][1] = [superPositions[0], superPositions[1], superPositions[2], superPositions[3]];
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
    }
}

/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Test Utils
import "../utils/ProtocolActions.sol";

contract SDSVD4626TimelockedNoSwapTokenInputSlippageL1 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [2, 3];

        CHAIN_0 = ETH; /// @dev NOTE: polygon has an issue with permit2, avax doesn't have permit2
        DST_CHAINS = [ETH];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ETH][0] = [1];

        TARGET_VAULTS[ETH][0] = [1]; /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[ETH][0] = [1];

        AMOUNTS[ETH][0] = [100];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[ETH][0] = [0];

        actions.push(
            TestAction({
                action: Actions.DepositPermit2,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 11, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                externalToken: 1 // 0 = DAI, 1 = USDT, 2 = WETH
            })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amount_) public {
        /// @dev amount = 1 after slippage will become 0, hence starting with 2
        amount_ = uint128(bound(amount_, 2, TOTAL_SUPPLY_USDT));
        AMOUNTS[ETH][0] = [amount_];

        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
    }
}

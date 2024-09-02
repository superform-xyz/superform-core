// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract SXSVDNormal4626SepoliaNoSlippageAMB23 is ProtocolActions {
    function setUp() public override {
        chainIds = [ETH, SEPOLIA, BSC_TESTNET];

        LAUNCH_TESTNETS = true;

        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [2, 5];

        CHAIN_0 = SEPOLIA;
        DST_CHAINS = [BSC_TESTNET];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[BSC_TESTNET][0] = [1];

        TARGET_VAULTS[BSC_TESTNET][0] = [0];

        TARGET_FORM_KINDS[BSC_TESTNET][0] = [0];

        AMOUNTS[BSC_TESTNET][0] = [133];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[BSC_TESTNET][0] = [2];

        RECEIVE_4626[BSC_TESTNET][0] = [false];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: true,
                externalToken: 1 // 0 = DAI, 1 = USDC, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amount_) public {
        amount_ = uint128(bound(amount_, 1 * 10 ** 6, TOTAL_SUPPLY_USDC));
        AMOUNTS[BSC_TESTNET][0] = [amount_];

        for (uint256 act = 0; act < actions.length; ++act) {
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

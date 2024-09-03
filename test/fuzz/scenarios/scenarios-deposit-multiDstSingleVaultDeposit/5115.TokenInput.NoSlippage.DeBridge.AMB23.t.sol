// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

// Test Utils
import "../../../utils/ProtocolActions.sol";

contract MDSVDNormal5115MultiTokenInputNoSlippageDebridgeAMB23 is ProtocolActions {
    function setUp() public override {
        chainIds = [ETH, OP, POLY];

        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [2, 3];
        MultiDstAMBs = [AMBs, AMBs, AMBs];

        CHAIN_0 = ETH;
        DST_CHAINS = [ETH, OP, POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ETH][0] = [1];
        TARGET_UNDERLYINGS[OP][0] = [4];
        TARGET_UNDERLYINGS[POLY][0] = [1];

        TARGET_VAULTS[ETH][0] = [0];
        TARGET_VAULTS[OP][0] = [3];
        TARGET_VAULTS[POLY][0] = [0];

        TARGET_FORM_KINDS[ETH][0] = [0];
        TARGET_FORM_KINDS[OP][0] = [1];
        TARGET_FORM_KINDS[POLY][0] = [0];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ETH][0] = [1];
        LIQ_BRIDGES[OP][0] = [1];
        LIQ_BRIDGES[POLY][0] = [8];

        RECEIVE_4626[ETH][0] = [false];
        RECEIVE_4626[OP][0] = [false];
        RECEIVE_4626[POLY][0] = [false];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 1 // 0 = DAI, 1 = USDC, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario(uint128 amountOne_, uint128 amountTwo_, uint128 amountThree_) public {
        amountOne_ = uint128(bound(amountOne_, 1e6, 1e10));
        amountTwo_ = uint128(bound(amountTwo_, 1e6, 1e10));
        amountThree_ = uint128(bound(amountThree_, 1e6, 1e10));

        AMOUNTS[ETH][0] = [amountOne_];
        AMOUNTS[OP][0] = [amountTwo_];
        AMOUNTS[POLY][0] = [amountThree_];

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

// // SPDX-License-Identifier: BUSL-1.1
// pragma solidity ^0.8.23;

// // Test Utils
// import "../../../utils/ProtocolActions.sol";

// contract SDSVW7540WithdrawAsyncNativeDstSwapSlippage is ProtocolActions {
//     function setUp() public override {
//         chainIds = [ETH, OP];

//         super.setUp();

//         AMBs = [2, 1];

//         CHAIN_0 = OP;
//         DST_CHAINS = [OP];

//         TARGET_UNDERLYINGS[OP][0] = [3]; // WETH
//         TARGET_UNDERLYINGS[OP][1] = [3]; // WETH

//         TARGET_VAULTS[OP][0] = [14];
//         TARGET_VAULTS[OP][1] = [14];

//         TARGET_FORM_KINDS[OP][0] = [4];
//         TARGET_FORM_KINDS[OP][1] = [4];

//         MAX_SLIPPAGE = 1000; // 10%

//         LIQ_BRIDGES[OP][0] = [2];
//         LIQ_BRIDGES[OP][1] = [2];

//         RECEIVE_4626[OP][0] = [false];
//         RECEIVE_4626[OP][1] = [false];

//         GENERATE_WITHDRAW_TX_DATA_ON_DST = true;

//         FINAL_LIQ_DST_WITHDRAW[OP] = [ETH];

//         actions.push(
//             TestAction({
//                 action: Actions.Deposit,
//                 multiVaults: false,
//                 user: 0,
//                 testType: TestType.Pass,
//                 revertError: "",
//                 revertRole: "",
//                 slippage: 500, // 5%
//                 dstSwap: true,
//                 externalToken: 2 // WETH
//              })
//         );

//         actions.push(
//             TestAction({
//                 action: Actions.Withdraw,
//                 multiVaults: false,
//                 user: 0,
//                 testType: TestType.Pass,
//                 revertError: "",
//                 revertRole: "",
//                 slippage: 500, // 5%
//                 dstSwap: false,
//                 externalToken: 2 // WETH
//              })
//         );
//     }

//     function test_scenario(uint128 amountOne_) public {
//         amountOne_ = uint128(bound(amountOne_, 2e18, 10e18));
//         AMOUNTS[OP][0] = [amountOne_];

//         for (uint256 act = 0; act < actions.length; ++act) {
//             TestAction memory action = actions[act];
//             MultiVaultSFData[] memory multiSuperformsData;
//             SingleVaultSFData[] memory singleSuperformsData;
//             MessagingAssertVars[] memory aV;
//             StagesLocalVars memory vars;
//             bool success;

//             if (act == 1) {
//                 uint256[] memory superPositions = _getSuperpositionsForDstChain(
//                     actions[1].user,
//                     TARGET_UNDERLYINGS[DST_CHAINS[0]][1],
//                     TARGET_VAULTS[DST_CHAINS[0]][1],
//                     TARGET_FORM_KINDS[DST_CHAINS[0]][1],
//                     DST_CHAINS[0]
//                 );

//                 AMOUNTS[OP][1] = [superPositions[0]];
//             }

//             _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);

//             // Add assertions here to check the success of each action
//             assertTrue(success, string(abi.encodePacked("Action ", Strings.toString(act), " failed")));
//         }
//     }
// }

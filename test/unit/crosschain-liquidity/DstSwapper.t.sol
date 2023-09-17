// // SPDX-License-Identifier: Unlicense
// pragma solidity 0.8.21;

// import { Error } from "src/utils/Error.sol";
// import "test/utils/ProtocolActions.sol";

// contract DstSwapperTest is BaseSetup {
//     function setUp() public override {
//         super.setUp();
//     }

//     function test_token_emergency_withdraw() public {
//         uint256 transferAmount = 1 * 10 ** 18; // 1 token
//         address payable token = payable(getContract(ETH, "DAI"));
//         address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));

//         /// @dev admin transfers some ETH and DAI tokens to multi tx processor
//         vm.selectFork(FORKS[ETH]);
//         vm.startPrank(deployer);

//         uint256 balanceBefore = MockERC20(token).balanceOf(dstSwapper);
//         MockERC20(token).transfer(dstSwapper, transferAmount);
//         uint256 balanceAfter = MockERC20(token).balanceOf(dstSwapper);
//         assertEq(balanceBefore + transferAmount, balanceAfter);

//         balanceBefore = MockERC20(token).balanceOf(dstSwapper);
//         DstSwapper(dstSwapper).emergencyWithdrawToken(token, transferAmount);
//         balanceAfter = MockERC20(token).balanceOf(dstSwapper);
//         assertEq(balanceBefore - transferAmount, balanceAfter);
//     }

//     function test_native_token_emergency_withdraw() public {
//         uint256 transferAmount = 1e18; // 1 token
//         address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));

//         /// @dev admin transfers some ETH and DAI tokens to multi tx processor
//         vm.selectFork(FORKS[ETH]);
//         vm.startPrank(deployer);

//         uint256 balanceBefore = dstSwapper.balance;
//         (bool success,) = dstSwapper.call{ value: transferAmount }("");
//         uint256 balanceAfter = dstSwapper.balance;
//         assertEq(balanceBefore + transferAmount, balanceAfter);

//         balanceBefore = dstSwapper.balance;
//         DstSwapper(dstSwapper).emergencyWithdrawNativeToken(transferAmount);
//         balanceAfter = dstSwapper.balance;
//         assertEq(balanceBefore - transferAmount, balanceAfter);
//     }

//     function test_native_token_emergency_withdrawFailure() public {
//         uint256 transferAmount = 1e18; // 1 token
//         address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));

//         /// @dev admin transfers some ETH and DAI tokens to multi tx processor
//         vm.selectFork(FORKS[ETH]);

//         uint256 balanceBefore = dstSwapper.balance;

//         vm.startPrank(deployer);
//         (bool success,) = dstSwapper.call{ value: transferAmount }("");
//         uint256 balanceAfter = dstSwapper.balance;
//         assertEq(balanceBefore + transferAmount, balanceAfter);

//         SuperRBAC(getContract(ETH, "SuperRBAC")).grantRole(
//             SuperRBAC(getContract(ETH, "SuperRBAC")).EMERGENCY_ADMIN_ROLE(), address(this)
//         );
//         vm.stopPrank();
//         balanceBefore = dstSwapper.balance;
//         vm.expectRevert(Error.NATIVE_TOKEN_TRANSFER_FAILURE.selector);
//         DstSwapper(dstSwapper).emergencyWithdrawNativeToken(transferAmount);
//         balanceAfter = dstSwapper.balance;
//         assertEq(balanceBefore, balanceAfter);
//     }

//     function test_failed_native_process_tx() public {
//         address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));

//         vm.selectFork(FORKS[ETH]);
//         vm.startPrank(deployer);

//         address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

//         (bool success,) = payable(dstSwapper).call{ value: 1e18 }("");
//         DstSwapper(dstSwapper).processTx(1, _buildTxData(1, native, dstSwapper, ETH, 1e18), native, 1e18);

//         /// @dev no funds in multi-tx processor at this point; should revert
//         vm.expectRevert(Error.FAILED_TO_EXECUTE_TXDATA_NATIVE.selector);
//         DstSwapper(dstSwapper).processTx(1, _buildTxData(1, native, dstSwapper, ETH, 1e18), native, 1e18);
//     }

//     function test_failed_non_native_process_tx() public {
//         address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));

//         vm.selectFork(FORKS[ETH]);
//         vm.startPrank(deployer);

//         /// @dev no funds in multi-tx processor at this point; should revert
//         vm.expectRevert(Error.FAILED_TO_EXECUTE_TXDATA.selector);
//         DstSwapper(dstSwapper).processTx(
//             1, _buildTxData(1, getContract(ETH, "USDT"), dstSwapper, ETH, 1e18), getContract(ETH, "USDT"), 1e18
//         );
//     }

//     function test_failed_batch_process_tx() public {
//         address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));

//         vm.selectFork(FORKS[ETH]);
//         vm.startPrank(deployer);

//         address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

//         uint8[] memory bridgeId = new uint8[](2);
//         bridgeId[0] = 1;
//         bridgeId[1] = 1;

//         address[] memory approvalToken = new address[](2);
//         approvalToken[0] = native;
//         approvalToken[1] = native;

//         bytes[] memory txData = new bytes[](2);
//         txData[0] = _buildTxData(1, native, dstSwapper, ETH, 1e18);
//         txData[1] = _buildTxData(1, native, dstSwapper, ETH, 1e18);

//         uint256[] memory amounts = new uint256[](2);
//         amounts[0] = 1e18;
//         amounts[1] = 1e18;

//         (bool success,) = payable(dstSwapper).call{ value: 2e18 }("");
//         if (!success) revert();

//         DstSwapper(dstSwapper).batchProcessTx(1, 0, bridgeId, txData);

//         /// @dev no funds in multi-tx processor at this point; should revert
//         vm.expectRevert(Error.FAILED_TO_EXECUTE_TXDATA_NATIVE.selector);
//         DstSwapper(dstSwapper).batchProcessTx(1, 0, bridgeId, txData);
//     }

//     function _buildTxData(
//         uint8 liqBridgeKind_,
//         address underlyingToken_,
//         address from_,
//         uint64 toChainId_,
//         uint256 amount_
//     )
//         internal
//         returns (bytes memory txData)
//     {
//         if (liqBridgeKind_ == 1) {
//             ILiFi.BridgeData memory bridgeData;
//             LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);

//             swapData[0] = LibSwap.SwapData(
//                 address(0),
//                 /// callTo (arbitrary)
//                 address(0),
//                 /// callTo (approveTo)
//                 underlyingToken_,
//                 underlyingToken_,
//                 amount_,
//                 /// @dev arbitrary totalSlippage (200) and dstSwapSlippageShare (40)
//                 abi.encode(from_, FORKS[toChainId_], underlyingToken_, 200, true, 40, false),
//                 false // arbitrary
//             );

//             bridgeData = ILiFi.BridgeData(
//                 bytes32("1"),
//                 /// request id
//                 "",
//                 "",
//                 address(0),
//                 underlyingToken_,
//                 getContract(toChainId_, "CoreStateRegistry"),
//                 amount_,
//                 uint256(toChainId_),
//                 false,
//                 false
//             );

//             txData = abi.encodeWithSelector(LiFiMock.swapAndStartBridgeTokensViaBridge.selector, bridgeData,
// swapData);
//         }
//     }
// }

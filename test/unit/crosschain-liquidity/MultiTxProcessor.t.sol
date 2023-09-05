// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { Error } from "src/utils/Error.sol";
import "test/utils/ProtocolActions.sol";

contract MultiTxProcessorTest is BaseSetup {
    uint256 MULTI_TX_SLIPPAGE_SHARE = 0;

    function setUp() public override {
        super.setUp();
    }

    function test_token_emergency_withdraw() public {
        uint256 transferAmount = 1 * 10 ** 18; // 1 token
        address payable token = payable(getContract(ETH, "DAI"));
        address payable multiTxProcessor = payable(getContract(ETH, "MultiTxProcessor"));

        /// @dev admin transfers some ETH and DAI tokens to multi tx processor
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        uint256 balanceBefore = MockERC20(token).balanceOf(multiTxProcessor);
        MockERC20(token).transfer(multiTxProcessor, transferAmount);
        uint256 balanceAfter = MockERC20(token).balanceOf(multiTxProcessor);
        assertEq(balanceBefore + transferAmount, balanceAfter);

        balanceBefore = MockERC20(token).balanceOf(multiTxProcessor);
        MultiTxProcessor(multiTxProcessor).emergencyWithdrawToken(token, transferAmount);
        balanceAfter = MockERC20(token).balanceOf(multiTxProcessor);
        assertEq(balanceBefore - transferAmount, balanceAfter);
    }

    function test_native_token_emergency_withdraw() public {
        uint256 transferAmount = 1e18; // 1 token
        address payable multiTxProcessor = payable(getContract(ETH, "MultiTxProcessor"));

        /// @dev admin transfers some ETH and DAI tokens to multi tx processor
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        uint256 balanceBefore = multiTxProcessor.balance;
        (bool success,) = multiTxProcessor.call{ value: transferAmount }("");
        uint256 balanceAfter = multiTxProcessor.balance;
        assertEq(balanceBefore + transferAmount, balanceAfter);

        balanceBefore = multiTxProcessor.balance;
        MultiTxProcessor(multiTxProcessor).emergencyWithdrawNativeToken(transferAmount);
        balanceAfter = multiTxProcessor.balance;
        assertEq(balanceBefore - transferAmount, balanceAfter);
    }

    function test_native_token_emergency_withdrawFailure() public {
        uint256 transferAmount = 1e18; // 1 token
        address payable multiTxProcessor = payable(getContract(ETH, "MultiTxProcessor"));

        /// @dev admin transfers some ETH and DAI tokens to multi tx processor
        vm.selectFork(FORKS[ETH]);

        uint256 balanceBefore = multiTxProcessor.balance;

        vm.startPrank(deployer);
        (bool success,) = multiTxProcessor.call{ value: transferAmount }("");
        uint256 balanceAfter = multiTxProcessor.balance;
        assertEq(balanceBefore + transferAmount, balanceAfter);

        SuperRBAC(getContract(ETH, "SuperRBAC")).grantRole(
            SuperRBAC(getContract(ETH, "SuperRBAC")).EMERGENCY_ADMIN_ROLE(), address(this)
        );
        vm.stopPrank();
        balanceBefore = multiTxProcessor.balance;
        vm.expectRevert(Error.NATIVE_TOKEN_TRANSFER_FAILURE.selector);
        MultiTxProcessor(multiTxProcessor).emergencyWithdrawNativeToken(transferAmount);
        balanceAfter = multiTxProcessor.balance;
        assertEq(balanceBefore, balanceAfter);
    }

    function test_failed_native_process_tx() public {
        address payable multiTxProcessor = payable(getContract(ETH, "MultiTxProcessor"));

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (bool success,) = payable(multiTxProcessor).call{ value: 1e18 }("");
        MultiTxProcessor(multiTxProcessor).processTx(
            1, _buildTxData(1, native, native, multiTxProcessor, ETH, 1e18, 100), native, 1e18
        );

        /// @dev no funds in multi-tx processor at this point; should revert
        vm.expectRevert(Error.FAILED_TO_EXECUTE_TXDATA_NATIVE.selector);
        MultiTxProcessor(multiTxProcessor).processTx(
            1, _buildTxData(1, native, native, multiTxProcessor, ETH, 1e18, 100), native, 1e18
        );
    }

    function test_failed_non_native_process_tx() public {
        address payable multiTxProcessor = payable(getContract(ETH, "MultiTxProcessor"));

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// @dev no funds in multi-tx processor at this point; should revert
        vm.expectRevert(Error.FAILED_TO_EXECUTE_TXDATA.selector);
        MultiTxProcessor(multiTxProcessor).processTx(
            1,
            _buildTxData(1, getContract(ETH, "USDT"), getContract(ETH, "USDT"), multiTxProcessor, ETH, 1e18, 100),
            getContract(ETH, "USDT"),
            1e18
        );
    }

    function test_failed_batch_process_tx() public {
        address payable multiTxProcessor = payable(getContract(ETH, "MultiTxProcessor"));

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        uint8[] memory bridgeId = new uint8[](2);
        bridgeId[0] = 1;
        bridgeId[1] = 1;

        address[] memory approvalToken = new address[](2);
        approvalToken[0] = native;
        approvalToken[1] = native;

        bytes[] memory txData = new bytes[](2);
        txData[0] = _buildTxData(1, native, native, multiTxProcessor, ETH, 1e18, 100);
        txData[1] = _buildTxData(1, native, native, multiTxProcessor, ETH, 1e18, 100);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        (bool success,) = payable(multiTxProcessor).call{ value: 2e18 }("");
        if (!success) revert();

        MultiTxProcessor(multiTxProcessor).batchProcessTx(bridgeId, txData, approvalToken, amounts);

        /// @dev no funds in multi-tx processor at this point; should revert
        vm.expectRevert(Error.FAILED_TO_EXECUTE_TXDATA_NATIVE.selector);
        MultiTxProcessor(multiTxProcessor).batchProcessTx(bridgeId, txData, approvalToken, amounts);
    }

    function _buildTxData(
        uint8 liqBridgeKind_,
        address underlyingToken_,
        address underlyingTokenDst_,
        address from_,
        uint64 toChainId_,
        uint256 amount_,
        int256 slippage_
    )
        internal
        returns (bytes memory txData)
    {
        /// @dev amount_ adjusted after bridge slippage
        int256 bridgeSlippage = (slippage_ * int256(100 - MULTI_TX_SLIPPAGE_SHARE)) / 100;
        amount_ = (amount_ * uint256(10_000 - bridgeSlippage)) / 10_000;

        if (liqBridgeKind_ == 1) {
            /// @dev for lifi
            ILiFi.BridgeData memory bridgeData;
            ILiFi.SwapData[] memory swapData = new ILiFi.SwapData[](1);

            swapData[0] = ILiFi.SwapData(
                address(0),
                ///  @dev  callTo (arbitrary)
                address(0),
                ///  @dev  callTo (approveTo)
                underlyingToken_,
                underlyingToken_,
                amount_,
                /// @dev _buildLiqBridgeTxDataMultiTx() will only be called when multiTx is true
                /// @dev and multiTx means cross-chain (last arg)
                abi.encode(
                    from_, FORKS[toChainId_], underlyingTokenDst_, slippage_, true, MULTI_TX_SLIPPAGE_SHARE, false
                ),
                false // arbitrary
            );

            bridgeData = ILiFi.BridgeData(
                bytes32("1"),
                /// @dev request id, arbitrary number
                "",
                /// @dev unused in tests
                "",
                /// @dev unused in tests
                address(0),
                underlyingTokenDst_,
                getContract(toChainId_, "CoreStateRegistry"),
                /// @dev next destination
                amount_,
                uint256(toChainId_),
                false,
                /// @dev false in the case of multiTxProcessor to only perform _bridge call (assumes tokens are already
                /// swapped)
                true
            );
            /// @dev true in the case of multiTxProcessor to only perform _bridge call (assumes tokens are already
            /// swapped)

            txData = abi.encodeWithSelector(LiFiMock.swapAndStartBridgeTokensViaBridge.selector, bridgeData, swapData);
        }
    }
}

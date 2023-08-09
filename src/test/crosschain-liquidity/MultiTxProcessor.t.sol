// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {Error} from "../../utils/Error.sol";
import "../utils/ProtocolActions.sol";

contract MultiTxProcessorTest is BaseSetup {
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
        (bool success, ) = multiTxProcessor.call{value: transferAmount}("");
        uint256 balanceAfter = multiTxProcessor.balance;
        assertEq(balanceBefore + transferAmount, balanceAfter);

        balanceBefore = multiTxProcessor.balance;
        MultiTxProcessor(multiTxProcessor).emergencyWithdrawNativeToken(transferAmount);
        balanceAfter = multiTxProcessor.balance;
        assertEq(balanceBefore - transferAmount, balanceAfter);
    }

    function test_failed_native_process_tx() public {
        address payable multiTxProcessor = payable(getContract(ETH, "MultiTxProcessor"));

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (bool success, ) = payable(multiTxProcessor).call{value: 1e18}("");
        MultiTxProcessor(multiTxProcessor).processTx(
            1,
            _buildTxData(1, native, multiTxProcessor, ETH, 1e18),
            native,
            1e18
        );

        /// @dev no funds in multi-tx processor at this point; should revert
        vm.expectRevert(Error.FAILED_TO_EXECUTE_TXDATA_NATIVE.selector);
        MultiTxProcessor(multiTxProcessor).processTx(
            1,
            _buildTxData(1, native, multiTxProcessor, ETH, 1e18),
            native,
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
        bridgeId[1] = 2;

        address[] memory approvalToken = new address[](2);
        approvalToken[0] = native;
        approvalToken[1] = native;

        bytes[] memory txData = new bytes[](2);
        txData[0] = _buildTxData(1, native, multiTxProcessor, ETH, 1e18);
        txData[1] = _buildTxData(2, native, multiTxProcessor, ETH, 1e18);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        (bool success, ) = payable(multiTxProcessor).call{value: 2e18}("");
        if (!success) revert();

        MultiTxProcessor(multiTxProcessor).batchProcessTx(bridgeId, txData, approvalToken, amounts);

        /// @dev no funds in multi-tx processor at this point; should revert
        vm.expectRevert(Error.FAILED_TO_EXECUTE_TXDATA_NATIVE.selector);
        MultiTxProcessor(multiTxProcessor).batchProcessTx(bridgeId, txData, approvalToken, amounts);
    }

    function _buildTxData(
        uint8 liqBridgeKind_,
        address underlyingToken_,
        address from_,
        uint64 toChainId_,
        uint256 amount_
    ) internal returns (bytes memory txData) {
        if (liqBridgeKind_ == 1) {
            ISocketRegistry.BridgeRequest memory bridgeRequest;
            ISocketRegistry.MiddlewareRequest memory middlewareRequest;
            ISocketRegistry.UserRequest memory userRequest;
            /// @dev middlware request is used if there is a swap involved before the bridging action
            /// @dev the input token should be the token the user deposits, which will be swapped to the input token of bridging request
            middlewareRequest = ISocketRegistry.MiddlewareRequest(
                1, /// request id
                0,
                underlyingToken_,
                abi.encode(getContract(toChainId_, "MultiTxProcessor"), FORKS[toChainId_], underlyingToken_)
            );

            /// @dev empty bridge request
            bridgeRequest = ISocketRegistry.BridgeRequest(
                0, /// id
                0,
                underlyingToken_,
                abi.encode(getContract(toChainId_, "MultiTxProcessor"), FORKS[toChainId_], underlyingToken_)
            );

            userRequest = ISocketRegistry.UserRequest(
                getContract(toChainId_, "CoreStateRegistry"),
                uint256(toChainId_),
                amount_,
                middlewareRequest,
                bridgeRequest
            );

            txData = abi.encodeWithSelector(SocketRouterMock.outboundTransferTo.selector, userRequest);
        } else if (liqBridgeKind_ == 2) {
            ILiFi.BridgeData memory bridgeData;
            ILiFi.SwapData[] memory swapData = new ILiFi.SwapData[](1);

            swapData[0] = ILiFi.SwapData(
                address(0), /// callTo (arbitrary)
                address(0), /// callTo (approveTo)
                underlyingToken_,
                underlyingToken_,
                amount_,
                abi.encode(from_, FORKS[toChainId_], underlyingToken_),
                false // arbitrary
            );

            bridgeData = ILiFi.BridgeData(
                bytes32("1"), /// request id
                "",
                "",
                address(0),
                underlyingToken_,
                getContract(toChainId_, "CoreStateRegistry"),
                amount_,
                uint256(toChainId_),
                false,
                true
            );

            txData = abi.encodeWithSelector(LiFiMock.swapAndStartBridgeTokensViaBridge.selector, bridgeData, swapData);
        }
    }
}

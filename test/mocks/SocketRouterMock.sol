// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
/// Types Imports
import { ISocketRegistry } from "src/vendor/socket/ISocketRegistry.sol";

import "./MockERC20.sol";

/// @title Socket Router Mock
/// @dev eventually replace this by using a fork of the real registry contract
contract SocketRouterMock is ISocketRegistry, Test {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    receive() external payable { }

    function outboundTransferTo(ISocketRegistry.UserRequest calldata userRequest_) external payable override {
        ISocketRegistry.BridgeRequest memory bridgeRequest = userRequest_.bridgeRequest;

        ISocketRegistry.MiddlewareRequest memory middlewareRequest = userRequest_.middlewareRequest;

        if (middlewareRequest.id == 0 && bridgeRequest.id != 0) {
            /// @dev just mock bridge
            _bridge(
                userRequest_.amount,
                userRequest_.receiverAddress,
                userRequest_.bridgeRequest.inputToken,
                userRequest_.bridgeRequest.data,
                false
            );
        } else if (middlewareRequest.id != 0 && bridgeRequest.id != 0) {
            /// @dev else, assume according to socket a swap and bridge is involved
            _swap(
                userRequest_.amount,
                userRequest_.middlewareRequest.inputToken,
                userRequest_.bridgeRequest.inputToken,
                userRequest_.middlewareRequest.data
            );

            _bridge(
                userRequest_.amount,
                userRequest_.receiverAddress,
                userRequest_.bridgeRequest.inputToken,
                userRequest_.bridgeRequest.data,
                true
            );
        } else if (middlewareRequest.id != 0 && bridgeRequest.id == 0) {
            /// @dev assume, for mocking purposes that cases with just swap is for the same token
            /// @dev this is for direct actions and multiTx swap of destination
            /// @dev bridge is used here to mint tokens in a new contract, but actually it's just a swap (chain id is
            /// the same)
            _bridge(
                userRequest_.amount,
                userRequest_.receiverAddress,
                userRequest_.middlewareRequest.inputToken,
                userRequest_.middlewareRequest.data,
                false
            );
        }
    }

    function routes() external view override returns (RouteData[] memory) { }

    function _bridge(
        uint256 amount_,
        address receiver_,
        address inputToken_,
        bytes memory data_,
        bool prevSwap
    )
        internal
    {
        /// @dev encapsulating from
        (
            address from,
            uint256 toForkId,
            address outputToken,
            int256 slippage,
            bool isMultiTx,
            uint256 multiTxSlippageShare,
            bool isDirect
        ) = abi.decode(data_, (address, uint256, address, int256, bool, uint256, bool));

        if (inputToken_ != NATIVE) {
            if (!prevSwap) MockERC20(inputToken_).transferFrom(from, address(this), amount_);
            MockERC20(inputToken_).burn(address(this), amount_);
        } else {
            require(msg.value == amount_);
        }

        uint256 prevForkId = vm.activeFork();
        vm.selectFork(toForkId);

        uint256 amountOut;
        if (isDirect) slippage = 0;
        else if (isMultiTx) slippage = (slippage * int256(multiTxSlippageShare)) / 100;
        else slippage = (slippage * int256(100 - multiTxSlippageShare)) / 100;

        amountOut = (amount_ * uint256(10_000 - slippage)) / 10_000;

        if (outputToken != NATIVE) {
            MockERC20(outputToken).mint(receiver_, amountOut);
        } else {
            if (prevForkId != toForkId) vm.deal(address(this), amountOut);
            (bool success,) = payable(receiver_).call{ value: amountOut }("");
            require(success);
        }
        vm.selectFork(prevForkId);
    }

    function _swap(uint256 amount_, address inputToken_, address bridgeToken_, bytes memory data_) internal {
        /// @dev encapsulating from
        address from = abi.decode(data_, (address));
        if (inputToken_ != NATIVE) {
            MockERC20(inputToken_).transferFrom(from, address(this), amount_);
            MockERC20(inputToken_).burn(address(this), amount_);
        }
        /// @dev assume no swap slippage
        MockERC20(bridgeToken_).mint(address(this), amount_);
    }
}

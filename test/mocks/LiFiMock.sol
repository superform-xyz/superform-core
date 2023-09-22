// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
/// Types Imports
import { ILiFi } from "src/vendor/lifi/ILiFi.sol";
import { LibSwap } from "src/vendor/lifi/LibSwap.sol";
import "./MockERC20.sol";

/// @title Socket Router Mock
/// @dev eventually replace this by using a fork of the real registry contract

contract LiFiMock is Test {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    receive() external payable { }

    function swapAndStartBridgeTokensViaBridge(
        ILiFi.BridgeData calldata bridgeData,
        LibSwap.SwapData[] calldata swapData
    )
        external
        payable
    {
        if (!bridgeData.hasSourceSwaps) {
            _bridge(bridgeData.minAmount, bridgeData.receiver, bridgeData.sendingAssetId, swapData[0].callData, false);
        } else {
            _swap(
                swapData[0].fromAmount,
                swapData[0].sendingAssetId,
                swapData[0].receivingAssetId,
                swapData[0].callData,
                address(this)
            );

            _bridge(bridgeData.minAmount, bridgeData.receiver, bridgeData.sendingAssetId, swapData[0].callData, true);
        }
    }

    function swapTokensGeneric(
        bytes32, /*_transactionId*/
        string calldata, /*_integrator*/
        string calldata, /*_referrer*/
        address payable _receiver,
        uint256, /*_minAmount*/
        LibSwap.SwapData[] calldata _swapData
    )
        external
        payable
    {
        _swap(
            _swapData[0].fromAmount,
            _swapData[0].sendingAssetId,
            _swapData[0].receivingAssetId,
            _swapData[0].callData,
            _receiver
        );
    }

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

    function _swap(
        uint256 amount_,
        address inputToken_,
        address outputToken_,
        bytes memory data_,
        address receiver_
    )
        internal
    {
        /// @dev encapsulating from
        address from = abi.decode(data_, (address));
        if (inputToken_ != NATIVE) {
            MockERC20(inputToken_).transferFrom(from, address(this), amount_);
            MockERC20(inputToken_).burn(address(this), amount_);
        }
        /// @dev assume no swap slippage
        MockERC20(outputToken_).mint(receiver_, amount_);
    }
}

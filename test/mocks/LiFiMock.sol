// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

/// Types Imports
import { ILiFi } from "src/vendor/lifi/ILiFi.sol";
import { LibSwap } from "src/vendor/lifi/LibSwap.sol";
import "./MockERC20.sol";

/// @title LiFi Router Mock
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
            uint256 amount = _swap(
                swapData[0].fromAmount,
                swapData[0].sendingAssetId,
                swapData[0].receivingAssetId,
                swapData[0].callData,
                address(this)
            );

            _bridge(amount, bridgeData.receiver, bridgeData.sendingAssetId, swapData[0].callData, true);
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

    struct BridgeLocalVars {
        address from;
        uint256 toForkId;
        int256 slippage;
        bool isDstSwap;
        uint256 dstSwapSlippageShare;
        bool isDirect;
        uint256 prevForkId;
        uint256 amountOut;
        uint256 finalAmountDst;
    }

    function _bridge(
        uint256 amount_,
        address receiver_,
        address inputToken_,
        bytes memory data_,
        bool prevSwap_
    )
        internal
    {
        BridgeLocalVars memory v;
        (v.from, v.toForkId,, v.slippage, v.isDstSwap, v.dstSwapSlippageShare, v.isDirect,,) =
            abi.decode(data_, (address, uint256, address, int256, bool, uint256, bool, uint256, uint256));

        if (inputToken_ != NATIVE) {
            if (!prevSwap_) MockERC20(inputToken_).transferFrom(v.from, address(this), amount_);
        } else {
            require(msg.value == amount_);
        }

        v.prevForkId = vm.activeFork();
        vm.selectFork(v.toForkId);

        if (v.isDirect) v.slippage = 0;
        else if (v.isDstSwap) v.slippage = (v.slippage * int256(v.dstSwapSlippageShare)) / 100;
        else v.slippage = (v.slippage * int256(100 - v.dstSwapSlippageShare)) / 100;

        v.amountOut = (amount_ * uint256(10_000 - v.slippage)) / 10_000;

        console.log("amount pre-bridge", v.amountOut);

        _sendOutputTokenToReceiver(data_, inputToken_, receiver_, v.amountOut, v.prevForkId, v.toForkId);

        vm.selectFork(v.prevForkId);
    }

    function _sendOutputTokenToReceiver(
        bytes memory data_,
        address inputToken_,
        address receiver_,
        uint256 amountOut_,
        uint256 prevForkId_,
        uint256 toForkId_
    )
        internal
    {
        uint256 decimal1;
        uint256 decimal2;
        uint256 finalAmount;
        address outputToken;
        uint256 USDPerUnderlyingToken;
        uint256 USDPerUnderlyingTokenDst;

        (,, outputToken,,,,,, USDPerUnderlyingToken, USDPerUnderlyingTokenDst) =
            abi.decode(data_, (address, uint256, address, int256, bool, uint256, bool, uint256, uint256, uint256));

        vm.selectFork(prevForkId_);
        decimal1 = inputToken_ == NATIVE ? 18 : MockERC20(inputToken_).decimals();
        vm.selectFork(toForkId_);
        decimal2 = outputToken == NATIVE ? 18 : MockERC20(outputToken).decimals();

        if (decimal1 > decimal2) {
            finalAmount =
                (amountOut_ * USDPerUnderlyingToken) / (10 ** (decimal1 - decimal2) * USDPerUnderlyingTokenDst);
        } else {
            finalAmount =
                ((amountOut_ * USDPerUnderlyingToken) * 10 ** (decimal2 - decimal1)) / USDPerUnderlyingTokenDst;
        }

        console.log("amount post-bridge", finalAmount);

        if (outputToken != NATIVE) {
            deal(outputToken, receiver_, MockERC20(outputToken).balanceOf(receiver_) + finalAmount);
        } else {
            if (prevForkId_ != toForkId_) vm.deal(address(this), finalAmount);
            (bool success,) = payable(receiver_).call{ value: finalAmount }("");
            require(success);
        }
    }

    function _swap(
        uint256 amount_,
        address inputToken_,
        address outputToken_,
        bytes memory data_,
        address receiver_
    )
        internal
        returns (uint256)
    {
        address from;
        uint256 USDPerExternalToken;
        uint256 USDPerUnderlyingToken;
        (from,,,,,,, USDPerExternalToken, USDPerUnderlyingToken,) =
            abi.decode(data_, (address, uint256, address, int256, bool, uint256, bool, uint256, uint256, uint256));

        if (inputToken_ != NATIVE) {
            MockERC20(inputToken_).transferFrom(from, address(this), amount_);
        }

        /// @dev TODO: simulate dstSwap slippage here (currently in ProtocolActions._buildLiqBridgeTxDataDstSwap()), and
        /// remove from _bridge() above
        // if (isDstSwap) slippage = (slippage * int256(dstSwapSlippageShare)) / 100;
        // amount_ = (amount_ * uint256(10_000 - slippage)) / 10_000;

        uint256 decimal1 = inputToken_ == NATIVE ? 18 : MockERC20(inputToken_).decimals();
        uint256 decimal2 = outputToken_ == NATIVE ? 18 : MockERC20(outputToken_).decimals();

        console.log("amount pre-swap", amount_);
        /// @dev the results of this amount if there is a bridge are effectively ignored
        if (decimal1 > decimal2) {
            amount_ = (amount_ * USDPerExternalToken) / (USDPerUnderlyingToken * 10 ** (decimal1 - decimal2));
        } else {
            amount_ = (amount_ * USDPerExternalToken) * 10 ** (decimal2 - decimal1) / USDPerUnderlyingToken;
        }
        console.log("amount post-swap", amount_);
        /// @dev swap slippage if any, is applied in ProtocolActions._stage1_buildReqData() for direct
        /// actions and in ProtocolActions._buildLiqBridgeTxDataDstSwap() for dstSwaps.
        /// @dev Could allocate swap slippage share separately like for ProtocolActions.MULTI_TX_SLIPPAGE_SHARE
        deal(outputToken_, receiver_, MockERC20(outputToken_).balanceOf(receiver_) + amount_);
        return amount_;
    }
}

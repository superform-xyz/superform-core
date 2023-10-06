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
            _bridge(BridgeArgs(bridgeData.minAmount, bridgeData.receiver, bridgeData.sendingAssetId, swapData[0].callData, false));
        } else {
            uint256 amount = _swap(
                swapData[0].fromAmount,
                swapData[0].sendingAssetId,
                swapData[0].receivingAssetId,
                swapData[0].callData,
                address(this)
            );

            _bridge(BridgeArgs(amount, bridgeData.receiver, bridgeData.sendingAssetId, swapData[0].callData, true));
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
        address outputToken;
        int256 slippage;
        bool isMultiTx;
        uint256 multiTxSlippageShare;
        bool isDirect;
        uint256 prevForkId;
        uint256 amountOut;
        uint256 USDPerExternalToken;
        uint256 USDPerUnderlyingTokenDst;
    }

    struct BridgeArgs {
        uint256 amount,
        address receiver,
        address inputToken,
        bytes memory data,
        bool prevSwap
    }

    function _bridge(
        BridgeArgs memory args
    )
        internal
    {
        BridgeLocalVars memory v;
        /// @dev encapsulating from
        (
            v.from,
            v.toForkId,
            v.outputToken,
            v.slippage,
            v.isMultiTx,
            v.multiTxSlippageShare,
            v.isDirect,
            v.USDPerExternalToken,
            v.USDPerUnderlyingTokenDst
        ) = abi.decode(args.data, (address, uint256, address, int256, bool, uint256, bool, uint256, uint256));

        // v.decimal1 = inputToken_ == NATIVE ? 18 : MockERC20(inputToken_).decimals();
        if (args.inputToken != NATIVE) {
            if (!args.prevSwap) MockERC20(args.inputToken).transferFrom(v.from, address(this), args.amount);
            /// @dev not all tokens allow burn / transfer to zero address
            try MockERC20(args.inputToken).burn(address(this), args.amount) { } catch { }
        } else {
            require(msg.value == args.amount);
        }

        v.prevForkId = vm.activeFork();
        vm.selectFork(v.toForkId);

        // v.decimal2 = v.outputToken == NATIVE ? 18 : MockERC20(v.outputToken).decimals();

        if (v.isDirect) v.slippage = 0;
        else if (v.isMultiTx) v.slippage = (v.slippage * int256(v.multiTxSlippageShare)) / 100;
        else v.slippage = (v.slippage * int256(100 - v.multiTxSlippageShare)) / 100;

        v.amountOut = (args.amount * uint256(10_000 - v.slippage)) / 10_000;

        _sendOutputTokenToReceiver(
            args.inputToken,
            v.outputToken,
            args.receiver,
            v.amountOut,
            v.prevForkId,
            v.toForkId,
            v.USDPerExternalToken,
            v.USDPerUnderlyingTokenDst
        );

        vm.selectFork(v.prevForkId);
    }

    function _sendOutputTokenToReceiver(
        address inputToken_,
        address outputToken_,
        address receiver_,
        uint256 amountOut_,
        uint256 prevForkId_,
        uint256 toForkId_,
        uint256 USDPerExternalToken_,
        uint256 USDPerUnderlyingTokenDst_
    )
        internal
    {
        uint256 decimal1;
        uint256 decimal2;
        uint256 finalAmount;

        vm.selectFork(prevForkId_);
        decimal1 = inputToken_ == NATIVE ? 18 : MockERC20(inputToken_).decimals();
        vm.selectFork(toForkId_);
        decimal2 = outputToken_ == NATIVE ? 18 : MockERC20(outputToken_).decimals();

        if (decimal1 > decimal2) {
            finalAmount =
                (amountOut_ * USDPerExternalToken_) / (10 ** (decimal1 - decimal2) * USDPerUnderlyingTokenDst_);
        } else {
            finalAmount = (amountOut_ * USDPerExternalToken_) * 10 ** (decimal2 - decimal1) / USDPerUnderlyingTokenDst_;
        }

        if (outputToken_ != NATIVE) {
            deal(outputToken_, receiver_, MockERC20(outputToken_).balanceOf(receiver_) + finalAmount);
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
        uint256 USDPerUnderlyingTokenDst;
        /// @dev encapsulating from
        (from,,,,,,, USDPerExternalToken, USDPerUnderlyingTokenDst) =
            abi.decode(data_, (address, uint256, address, int256, bool, uint256, bool, uint256, uint256));
        if (inputToken_ != NATIVE) {
            MockERC20(inputToken_).transferFrom(from, address(this), amount_);
            /// @dev not all tokens allow burn / transfer to zero address
            try MockERC20(inputToken_).burn(address(this), amount_) { } catch { }
        }

        uint256 decimal1 = inputToken_ == NATIVE ? 18 : MockERC20(inputToken_).decimals();
        uint256 decimal2 = outputToken_ == NATIVE ? 18 : MockERC20(outputToken_).decimals();

        /// input token decimals are greater than output
        if (decimal1 > decimal2) {
            amount_ = (amount_ * USDPerExternalToken) / (USDPerUnderlyingTokenDst * 10 ** (decimal1 - decimal2));
        } else {
            amount_ = (amount_ * USDPerExternalToken) * 10 ** (decimal2 - decimal1) / USDPerUnderlyingTokenDst;
        }
        /// @dev assume no swap slippage
        deal(outputToken_, receiver_, MockERC20(outputToken_).balanceOf(receiver_) + amount_);
        return amount_;
    }
}

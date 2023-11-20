// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

/// local imports
import { ISocketRegistry } from "src/vendor/socket/ISocketRegistry.sol";
import "./MockERC20.sol";

/// @title Socket Mock
/// @dev eventually replace this by using a fork of the real registry contract
contract SocketMock is ISocketRegistry, Test {
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
            uint256 amount = _swap(
                userRequest_.amount,
                userRequest_.middlewareRequest.inputToken,
                userRequest_.bridgeRequest.inputToken,
                userRequest_.middlewareRequest.data
            );

            _bridge(
                amount,
                userRequest_.receiverAddress,
                userRequest_.bridgeRequest.inputToken,
                userRequest_.bridgeRequest.data,
                true
            );
        } else {
            revert();
        }
    }

    struct BridgeLocalVars {
        uint256 prevForkId;
        uint256 decimal1;
        uint256 decimal2;
        uint256 finalAmount;
        address from;
        address outputToken;
        uint256 USDPerUnderlyingToken;
        uint256 USDPerUnderlyingTokenDst;
        uint256 toForkId;
        int256 slippage;
        uint256 dstSwapSlippageShare;
        bool isDstSwap;
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
        BridgeLocalVars memory vars;
        vars.prevForkId = vm.activeFork();

        /// @dev decoding the data_
        (
            vars.from,
            vars.toForkId,
            vars.outputToken,
            vars.slippage,
            vars.isDstSwap,
            vars.dstSwapSlippageShare,
            ,
            vars.USDPerUnderlyingToken,
            vars.USDPerUnderlyingTokenDst
        ) = abi.decode(data_, (address, uint256, address, int256, bool, uint256, uint256, uint256, uint256));

        if (!prevSwap) {
            if (inputToken_ != NATIVE) {
                MockERC20(inputToken_).transferFrom(vars.from, address(this), amount_);
            } else {
                require(msg.value == amount_);
            }
        }

        amount_ = ((amount_ * uint256(10_000 - vars.slippage)) / 10_000);

        vm.selectFork(vars.prevForkId);
        vars.decimal1 = inputToken_ == NATIVE ? 18 : MockERC20(inputToken_).decimals();
        vm.selectFork(vars.toForkId);
        vars.decimal2 = vars.outputToken == NATIVE ? 18 : MockERC20(vars.outputToken).decimals();

        if (vars.isDstSwap) vars.slippage = (vars.slippage * int256(vars.dstSwapSlippageShare)) / 100;
        else vars.slippage = (vars.slippage * int256(100 - vars.dstSwapSlippageShare)) / 100;

        if (vars.decimal1 > vars.decimal2) {
            vars.finalAmount = (amount_ * vars.USDPerUnderlyingToken)
                / (10 ** (vars.decimal1 - vars.decimal2) * vars.USDPerUnderlyingTokenDst);
        } else {
            vars.finalAmount = ((amount_ * vars.USDPerUnderlyingToken) * 10 ** (vars.decimal2 - vars.decimal1))
                / vars.USDPerUnderlyingTokenDst;
        }

        vm.selectFork(vars.toForkId);

        if (vars.outputToken != NATIVE) {
            deal(vars.outputToken, receiver_, MockERC20(vars.outputToken).balanceOf(receiver_) + vars.finalAmount);
        } else {
            vm.deal(receiver_, vars.finalAmount);
        }
        vm.selectFork(vars.prevForkId);
    }

    function _swap(
        uint256 amount_,
        address inputToken_,
        address bridgeToken_,
        bytes memory data_
    )
        internal
        returns (uint256)
    {
        /// @dev encapsulating from
        (address from, uint256 USDPerExternalToken, uint256 USDPerUnderlyingToken) =
            abi.decode(data_, (address, uint256, uint256));

        if (inputToken_ != NATIVE) {
            MockERC20(inputToken_).transferFrom(address(from), address(this), amount_);
        } else {
            require(msg.value == amount_);
        }

        uint256 decimal1 = inputToken_ == NATIVE ? 18 : MockERC20(inputToken_).decimals();
        uint256 decimal2 = bridgeToken_ == NATIVE ? 18 : MockERC20(bridgeToken_).decimals();

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
        return amount_;
    }
}

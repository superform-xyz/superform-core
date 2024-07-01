// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

/// local imports
import "./MockERC20.sol";
import "src/vendor/1inch/IAggregationRouterV6.sol";

/// @title One Inch Mock
/// @dev eventually replace this by using a fork of the real 1inch contract
contract OneInchMock is Test {
    using AddressLib for Address;
    using ProtocolLib for Address;

    /// @dev will now transfer the minReturn
    function unoswapTo(
        Address to,
        Address token,
        uint256, /*amount*/
        uint256 minReturn,
        Address dex
    )
        external
        returns (uint256 returnAmount)
    {
        address fromToken = token.get();
        address receiver = to.get();

        address toToken;

        ProtocolLib.Protocol protocol = dex.protocol();

        /// @dev if protocol is uniswap v2 or uniswap v3
        if (protocol == ProtocolLib.Protocol.UniswapV2 || protocol == ProtocolLib.Protocol.UniswapV3) {
            toToken = IUniswapPair(dex.get()).token0();

            if (toToken == fromToken) {
                toToken = IUniswapPair(dex.get()).token1();
            }
        }
        /// @dev if protocol is curve
        else if (protocol == ProtocolLib.Protocol.Curve) {
            uint256 toTokenIndex = (Address.unwrap(dex) >> _CURVE_TO_COINS_ARG_OFFSET) & _CURVE_TO_COINS_ARG_MASK;
            toToken = ICurvePool(dex.get()).underlying_coins(int128(uint128(toTokenIndex)));
        }

        uint256 fromDecimal = MockERC20(fromToken).decimals();
        uint256 toDecimal = MockERC20(toToken).decimals();

        if (fromDecimal > toDecimal) {
            minReturn = minReturn / 10 ** (fromDecimal - toDecimal);
        } else if (toDecimal > fromDecimal) {
            minReturn = minReturn * 10 ** (toDecimal - fromDecimal);
        }

        deal(toToken, receiver, minReturn);
        returnAmount = minReturn;
    }

    function swap(
        IAggregationExecutor,
        IAggregationRouterV6.SwapDescription calldata desc,
        bytes calldata
    )
        external
        payable
    {
        deal(address(desc.dstToken), address(desc.dstReceiver), desc.minReturnAmount);
    }
}

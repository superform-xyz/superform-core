// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";

interface IPair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

library DexSwap {
    using SafeTransferLib for ERC20;

    /**
     * @notice Swap directly through a Pair
     * @param amountIn input amount
     * @param fromToken address
     * @param toToken address
     * @param pairToken Pair used for swap
     * @return output amount
     */
    function swap(
        uint256 amountIn,
        address fromToken,
        address toToken,
        address pairToken
    ) internal returns (uint256) {
        IPair pair = IPair(pairToken);
        (address token0, ) = sortTokens(fromToken, toToken);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        if (token0 != fromToken) (reserve0, reserve1) = (reserve1, reserve0);
        uint256 amountOut1 = 0;
        uint256 amountOut2 = getAmountOut(amountIn, reserve0, reserve1);
        if (token0 != fromToken)
            (amountOut1, amountOut2) = (amountOut2, amountOut1);
        ERC20(fromToken).safeTransfer(address(pair), amountIn);
        pair.swap(amountOut1, amountOut2, address(this), new bytes(0));
        return amountOut2 > amountOut1 ? amountOut2 : amountOut1;
    }

    /**
     * @notice Given an input amount of an asset and pair reserves, returns maximum output amount of the other asset
     * @dev Assumes swap fee is 0.30%
     * @param amountIn input asset
     * @param reserveIn size of input asset reserve
     * @param reserveOut size of output asset reserve
     * @return maximum output amount
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * (reserveOut);
        uint256 denominator = (reserveIn * 1000) + (amountInWithFee);
        return numerator / (denominator);
    }

    /**
     * @notice Given two tokens, it'll return the tokens in the right order for the tokens pair
     * @dev TokenA must be different from TokenB, and both shouldn't be address(0), no validations
     * @param tokenA address
     * @param tokenB address
     * @return sorted tokens
     */
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address, address)
    {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}

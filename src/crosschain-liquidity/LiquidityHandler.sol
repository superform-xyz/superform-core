/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPermit2 } from "../vendor/dragonfly-xyz/IPermit2.sol";
import { Error } from "../utils/Error.sol";

/**
 * @title LiquidityHandler
 * @author Zeropoint Labs.
 * @dev bridges tokens from Chain A -> Chain B. To be inherited by contracts that move liquidity
 */
abstract contract LiquidityHandler {
    using SafeERC20 for IERC20;

    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev dispatches tokens via a liquidity bridge
    /// @param bridge_ Bridge address to pass tokens to
    /// @param txData_ liquidity bridge data
    /// @param token_ Token caller deposits into superform
    /// @param amount_ Amount of tokens to deposit
    /// @param srcSender_ Owner of tokens
    /// @param nativeAmount_ msg.value or msg.value + native tokens
    function dispatchTokens(
        address bridge_,
        bytes memory txData_,
        address token_,
        uint256 amount_,
        address srcSender_,
        uint256 nativeAmount_
    )
        internal
        virtual
    {
        if (token_ != NATIVE) {
            IERC20 token = IERC20(token_);

            /// @dev call bridge with txData. Native amount here just contains liquidity bridge fees (if needed)
            token.safeIncreaseAllowance(bridge_, amount_);
            unchecked {
                (bool success,) = payable(bridge_).call{ value: nativeAmount_ }(txData_);
                if (!success) revert Error.FAILED_TO_EXECUTE_TXDATA();
            }
        } else {
            if (nativeAmount_ < amount_) revert Error.INSUFFICIENT_NATIVE_AMOUNT();

            /// @dev call bridge with txData. Native amount here contains liquidity bridge fees (if needed) + native
            /// tokens to swap
            unchecked {
                (bool success,) = payable(bridge_).call{ value: nativeAmount_ }(txData_);
                if (!success) revert Error.FAILED_TO_EXECUTE_TXDATA_NATIVE();
            }
        }
    }
}

/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { Error } from "../libraries/Error.sol";

/**
 * @title LiquidityHandler
 * @author Zeropoint Labs.
 * @dev Executes an action with tokens to either bridge from Chain A -> Chain B or swap on same chain.
 * @dev To be inherited by contracts that move liquidity
 */
abstract contract LiquidityHandler {
    using SafeERC20 for IERC20;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                         //
    //////////////////////////////////////////////////////////////

    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev dispatches tokens via a liquidity bridge or exchange
    /// @param bridge_ Bridge address to pass tokens to
    /// @param txData_ liquidity bridge data
    /// @param token_ Token caller deposits into superform
    /// @param amount_ Amount of tokens to deposit
    /// @param nativeAmount_ msg.value or msg.value + native tokens
    function _dispatchTokens(
        address bridge_,
        bytes memory txData_,
        address token_,
        uint256 amount_,
        uint256 nativeAmount_
    )
        internal
        virtual
    {
        if (bridge_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        if (token_ != NATIVE) {
            IERC20 token = IERC20(token_);
            token.safeIncreaseAllowance(bridge_, amount_);
        } else {
            if (nativeAmount_ < amount_) revert Error.INSUFFICIENT_NATIVE_AMOUNT();
        }

        (bool success,) = payable(bridge_).call{ value: nativeAmount_ }(txData_);
        if (!success) revert Error.FAILED_TO_EXECUTE_TXDATA(token_);
    }
}

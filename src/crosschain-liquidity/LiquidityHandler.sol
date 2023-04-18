/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPermit2} from "../interfaces/IPermit2.sol";
import {Error} from "../utils/Error.sol";

/**
 * @title Liquidity Handler.
 * @author Zeropoint Labs.
 * @dev bridges tokens from Chain A -> Chain B
 */
abstract contract LiquidityHandler {
    using SafeERC20 for IERC20;

    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev dispatches tokens via the socket bridge.
    /// Note: refer https://docs.socket.tech/socket-api/v2/guides/socket-smart-contract-integration
    /// Note: All the inputs are in array for processing multiple transactions.
    /// @param bridge_ Bridge address to pass tokens to
    /// @param txData_ Socket data
    /// @param token_ Token caller deposits into superform
    /// @param amount_ Amount of tokens to deposit
    /// @param owner_ Owner of tokens
    /// @param nativeAmount_ msg.value or msg.value + native tokens
    /// @param permit2Data_ abi.encode of nonce, deadline & signature for the amounts being transfered
    function dispatchTokens(
        address bridge_,
        bytes memory txData_,
        address token_,
        uint256 amount_,
        address owner_,
        uint256 nativeAmount_,
        bytes memory permit2Data_,
        address permit2_
    ) internal virtual {
        if (token_ != NATIVE) {
            IERC20 token = IERC20(token_);

            /// @dev only for deposits, otherwise amount already in contract
            if (owner_ != address(this)) {
                if (permit2Data_.length == 0) {
                    /// NOTE: Investiage if this can be consolidated in 1 op (permit? only approve to bridge?)
                    /// @dev FIXME: this fails with solmate safeTransferFrom on direct actions (transfer to beaconProxy 1st) - could it be because of beaconProxy?
                    // !! Warning: reported here https://github.com/transmissions11/solmate/issues/370
                    token.safeTransferFrom(owner_, address(this), amount_);
                } else {
                    (
                        uint256 nonce,
                        uint256 deadline,
                        bytes memory signature
                    ) = abi.decode(permit2Data_, (uint256, uint256, bytes));

                    IPermit2(permit2_).permitTransferFrom(
                        // The permit message.
                        IPermit2.PermitTransferFrom({
                            permitted: IPermit2.TokenPermissions({
                                token: token,
                                amount: amount_
                            }),
                            nonce: nonce,
                            deadline: deadline
                        }),
                        // The transfer recipient and amount.
                        IPermit2.SignatureTransferDetails({
                            to: address(this),
                            requestedAmount: amount_
                        }),
                        // The owner of the tokens, which must also be
                        // the signer of the message, otherwise this call
                        // will fail.
                        owner_,
                        // The packed signature that was the result of signing
                        // the EIP712 hash of `permit`.
                        signature
                    );
                }
            }
            token.safeApprove(bridge_, amount_);

            /// NOTE: Delegatecall is always risky. bridge_ address hardcoded now.
            /// Can't we just use bridge interface here?
            unchecked {
                (bool success, ) = payable(bridge_).call{value: nativeAmount_}(
                    txData_
                );
                if (!success) revert Error.FAILED_TO_EXECUTE_TXDATA();
            }
        } else {
            /// NOTE: Test if this is reachable
            if (nativeAmount_ < amount_)
                revert Error.INSUFFICIENT_NATIVE_AMOUNT();

            /// NOTE: Delegatecall is always risky. bridge_ address hardcoded now.
            /// Can't we just use bridge interface here?
            unchecked {
                (bool success, ) = payable(bridge_).call{value: nativeAmount_}(
                    txData_
                );
                if (!success) revert Error.FAILED_TO_EXECUTE_TXDATA_NATIVE();
            }
        }
    }
}

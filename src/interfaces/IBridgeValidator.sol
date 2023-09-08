// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title Bridge Handler Interface
/// @author Zeropoint Labs
interface IBridgeValidator {
    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev validates the destination chainId of the liquidity request
    /// @param txData_ the txData of the deposit
    /// @param liqDstChainId_ the chainId of the destination chain for liquidity
    function validateLiqDstChainId(bytes calldata txData_, uint64 liqDstChainId_) external pure returns (bool);

    /// @dev decoded txData and returns the receiver address
    /// @param txData_ is the txData of the cross chain deposit
    /// @param receiver_ is the address of the receiver to validate
    /// @return valid_ if the address is valid
    function validateReceiver(bytes calldata txData_, address receiver_) external pure returns (bool valid_);

    /// @dev validates the txData of a cross chain deposit
    /// @param txData_ the txData of the cross chain deposit
    /// @param srcChainId_ the chainId of the source chain
    /// @param dstChainId_ the chainId of the destination chain
    /// @param liqDstChainId_ the chainId of the destination chain for liquidity
    /// @param deposit_ true if the action is a deposit, false if it is a withdraw
    /// @param superform_ the address of the superform
    /// @param srcSender_ the address of the sender on the source chain
    /// @param liqDataToken_ the address of the liqDataToken
    function validateTxData(
        bytes calldata txData_,
        uint64 srcChainId_,
        uint64 dstChainId_,
        uint64 liqDstChainId_,
        bool deposit_,
        address superform_,
        address srcSender_,
        address liqDataToken_
    )
        external
        view;

    /// @dev decodes the txData and returns the minimum amount expected to receive on the destination
    /// @param txData_ is the txData of the cross chain deposit
    /// @param genericSwapDisallowed_ true if generic swaps are disallowed
    /// @return amount_ the amount expected
    function decodeMinAmountOut(
        bytes calldata txData_,
        bool genericSwapDisallowed_
    )
        external
        view
        returns (uint256 amount_);

    /// @dev decodes the txData and returns the amount of external token on source
    /// @param txData_ is the txData of the cross chain deposit
    /// @param genericSwapDisallowed_ true if generic swaps are disallowed
    /// @return amount_ the amount expected
    function decodeAmountIn(
        bytes calldata txData_,
        bool genericSwapDisallowed_
    )
        external
        view
        returns (uint256 amount_);
}

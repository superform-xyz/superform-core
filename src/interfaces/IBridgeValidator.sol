// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

/// @title Bridge Handler Interface
/// @author Zeropoint Labs
interface IBridgeValidator {
    /*///////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/
    struct ValidateTxDataArgs {
        bytes txData;
        uint64 srcChainId;
        uint64 dstChainId;
        uint64 liqDstChainId;
        bool deposit;
        address superform;
        address srcSender;
        address liqDataToken;
    }

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
    /// @param args_ the txData arguments to validate in txData
    function validateTxData(ValidateTxDataArgs calldata args_) external view;

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

    /// @dev decodes the amount in from the txData that just involves a swap
    /// @param txData_ is the txData to be decoded
    /// @return token_ is the address of the token
    /// @return amount_ the amount expected
    function decodeDstSwap(bytes calldata txData_) external pure returns (address token_, uint256 amount_);

    /// @dev decodes the final output token address (for only direct chain actions!)
    /// @param txData_ is the txData to be decoded
    /// @return token_ the address of the token
    function decodeSwapOutputToken(bytes calldata txData_) external view returns (address token_);
}

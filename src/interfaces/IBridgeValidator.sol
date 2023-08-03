// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title Bridge Handler Interface
/// @author Zeropoint Labs
interface IBridgeValidator {
    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev validates the amounts being sent in liqRequests
    /// @param txData_ the txData of the deposit
    /// @param amount_ the amount of the deposit
    function validateTxDataAmount(bytes calldata txData_, uint256 amount_) external view returns (bool);

    /// @dev validates the txData of a cross chain deposit
    /// @param txData_ the txData of the cross chain deposit
    /// @param srcChainId_ the chainId of the source chain
    /// @param dstChainId_ the chainId of the destination chain
    /// @param deposit_ true if the action is a deposit, false if it is a withdraw
    /// @param superForm_ the address of the superForm
    /// @param srcSender_ the address of the sender on the source chain
    /// @param liqDataToken_ the address of the liqDataToken
    function validateTxData(
        bytes calldata txData_,
        uint64 srcChainId_,
        uint64 dstChainId_,
        bool deposit_,
        address superForm_,
        address srcSender_,
        address liqDataToken_
    ) external view;

    /// @dev decoded txData and returns the receiver address
    /// @param txData_ is the txData of the cross chain deposit
    /// @param receiver_ is the address of the receiver to validate
    /// @return valid_ if the address is valid
    function validateReceiver(bytes calldata txData_, address receiver_) external pure returns (bool valid_);
}

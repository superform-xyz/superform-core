// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title IBaseStateRegistry
/// @author ZeroPoint Labs
/// @dev helps decoding the bytes payload and returns meaningful information
interface ICoreStateRegistryHelper {
    /// @dev reads the payload from the core state registry and decodes it in a more detailed manner.
    /// @param dstPayloadId_ is the unique identifier of the payload received in dst core state registry
    /// @return txType is the type of transaction. check {TransactionType} enum in DataTypes.sol
    /// @return callbackType is the type of payload. check {CallbackType} enum in DataTypes.sol
    /// @return srcSender is the user who initiated the transaction on the srcChain
    /// @return srcChainId is the unique identifier of the srcChain
    /// @return amounts is the amount to deposit/withdraw
    /// @return slippage is the max slippage configured by the user (only for deposits)
    /// @return superFormIds is the unique identifiers of the superForms
    /// @return srcPayloadId is the identifier of the corresponding payload on srcChain
    function decodePayload(
        uint256 dstPayloadId_
    )
        external
        view
        returns (
            uint8 txType,
            uint8 callbackType,
            address srcSender,
            uint64 srcChainId,
            uint256[] memory amounts,
            uint256[] memory slippage,
            uint256[] memory superFormIds,
            uint256 srcPayloadId
        );

    /// @dev returns the gas fees estimation in native tokens if we send message through a combination of AMBs
    /// @param ambIds_ is the identifier of different AMBs
    /// @param dstChainId_ is the identifier of the destination chain
    /// @param message_ is the cross-chain message
    /// @param extraData_ is any amb-specific information
    /// @return totalFees is the native_tokens to be sent along the transaction for all the ambIds_ included
    function estimateFees(
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes[] memory extraData_
    ) external view returns (uint256 totalFees, uint256[] memory);
}

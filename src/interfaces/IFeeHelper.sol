// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title IFeeHelper
/// @author ZeroPoint Labs
/// @dev helps decoding the bytes payload and returns meaningful information
interface IFeeHelper {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "../types/DataTypes.sol";

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

    /// @dev estimates the gas fees for multiple destination and multi vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @return totalFees is the native_tokens to be sent along the transaction
    function estimateMultiDstMultiVault(
        MultiDstMultiVaultsStateReq calldata req_,
        bool isDeposit
    ) external view returns (uint256 totalFees);

    /// @dev estimates the gas fees for single destination and multi vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @return totalFees is the native_tokens to be sent along the transaction
    function estimateSingleDstMultiVault(
        SingleDstMultiVaultsStateReq calldata req_,
        bool isDeposit
    ) external view returns (uint256 totalFees);

    /// @dev estimates the gas fees for multiple destination and single vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @return totalFees is the native_tokens to be sent along the transaction
    function estimateMultiDstSingleVault(
        MultiDstSingleVaultStateReq calldata req_,
        bool isDeposit
    ) external view returns (uint256 totalFees);

    /// @dev estimates the gas fees for single destination and single vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @return totalFees is the native_tokens to be sent along the transaction
    function estimateSingleXChainSingleVault(
        SingleXChainSingleVaultStateReq calldata req_,
        bool isDeposit
    ) external view returns (uint256 totalFees);

    /// @dev estimates the gas fees for same chain operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @return totalFees is the native_tokens to be sent along the transaction
    function estimateSingleDirectSingleVault(
        SingleDirectSingleVaultStateReq calldata req_,
        bool isDeposit
    ) external view returns (uint256 totalFees);
}

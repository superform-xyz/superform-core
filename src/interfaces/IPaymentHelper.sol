// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import "../types/DataTypes.sol";

/// @title IPaymentHelper
/// @author ZeroPoint Labs
/// @dev helps decoding the bytes payload and returns meaningful information
interface IPaymentHelper {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event ChainConfigUpdated(uint64 chainId_, uint256 configType_, bytes config_);

    /*///////////////////////////////////////////////////////////////
                        PRIVILEGED ADMIN ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev admin config destination chain config for estimation
    /// @param chainId_ is the identifier of new chain id
    /// @param nativeFeedOracle_ is the native price feed oracle
    /// @param gasPriceOracle_ is the gas price oracle
    /// @param swapGasUsed_ is the swap gas params
    /// @param updateGasUsed_ is the update gas params
    /// @param depositGasUsed_ is the deposit per vault gas on the chain
    /// @param withdrawGasUsed_ is the withdraw per vault gas on the chain
    /// @param defaultNativePrice_ is the native price on the specified chain
    /// @param defaultGasPrice_ is the gas price on the specified chain
    /// @param dstGasPerKB_ is the gas per size of data
    function addChain(
        uint64 chainId_,
        address nativeFeedOracle_,
        address gasPriceOracle_,
        uint256 swapGasUsed_,
        uint256 updateGasUsed_,
        uint256 depositGasUsed_,
        uint256 withdrawGasUsed_,
        uint256 defaultNativePrice_,
        uint256 defaultGasPrice_,
        uint256 dstGasPerKB_
    )
        external;

    /// @dev admin update remote chain config for estimation
    /// @param chainId_ is the remote chain's identifier
    /// @param configType_ is the type of config from 1 -> 6
    /// @param config_ is the encoded new configuration
    function updateChainConfig(uint64 chainId_, uint256 configType_, bytes memory config_) external;

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the amb overrides & gas to be used
    /// @param dstChainId_ is the unique dst chain identifier
    /// @param ambIds_ is the identifiers of arbitrary message bridges to be used
    /// @param message_ is the encoded cross-chain payload
    function calculateAMBData(
        uint64 dstChainId_,
        uint8[] calldata ambIds_,
        bytes memory message_
    )
        external
        view
        returns (uint256 totalFees, bytes memory extraData);

    /// @dev returns the gas fees estimation in native tokens if we send message through a combination of AMBs
    /// @param ambIds_ is the identifier of different AMBs
    /// @param dstChainId_ is the identifier of the destination chain
    /// @param message_ is the cross-chain message
    /// @param extraData_ is any amb-specific information
    /// @return ambFees is the native_tokens to be sent along the transaction for all the ambIds_ included
    function estimateAMBFees(
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes[] memory extraData_
    )
        external
        view
        returns (uint256 ambFees, uint256[] memory);

    /// @dev estimates the gas fees for multiple destination and multi vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return dstAmount is the gas expense on dst chain in terms of src chain's native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateMultiDstMultiVault(
        MultiDstMultiVaultStateReq calldata req_,
        bool isDeposit
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount);

    /// @dev estimates the gas fees for multiple destination and single vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return dstAmount is the gas expense on dst chain in terms of src chain's native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateMultiDstSingleVault(
        MultiDstSingleVaultStateReq calldata req_,
        bool isDeposit
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount);

    /// @dev estimates the gas fees for single destination and multi vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter    ///
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return dstAmount is the gas expense on dst chain in terms of src chain's native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateSingleXChainMultiVault(
        SingleXChainMultiVaultStateReq calldata req_,
        bool isDeposit
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount);

    /// @dev estimates the gas fees for single destination and single vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return dstAmount is the gas expense on dst chain in terms of src chain's native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateSingleXChainSingleVault(
        SingleXChainSingleVaultStateReq calldata req_,
        bool isDeposit
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount);

    /// @dev estimates the gas fees for same chain operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return dstAmount is the gas expense on dst chain in terms of src chain's native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateSingleDirectSingleVault(
        SingleDirectSingleVaultStateReq calldata req_,
        bool isDeposit
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount);

    /// @dev estimates the gas fees for multiple same chain operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return dstAmount is the gas expense on dst chain in terms of src chain's native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateSingleDirectMultiVault(
        SingleDirectMultiVaultStateReq calldata req_,
        bool isDeposit
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount);
}

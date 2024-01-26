// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {
    MultiDstMultiVaultStateReq,
    MultiDstSingleVaultStateReq,
    SingleXChainMultiVaultStateReq,
    SingleXChainSingleVaultStateReq,
    SingleDirectSingleVaultStateReq,
    SingleDirectMultiVaultStateReq
} from "src/types/DataTypes.sol";

/// @title IPaymentHelper
/// @dev Interface for PaymentHelper
/// @author ZeroPoint Labs
interface IPaymentHelper {
    //////////////////////////////////////////////////////////////
    //                           STRUCTS                         //
    //////////////////////////////////////////////////////////////

    /// @param nativeFeedOracle is the native price feed oracle
    /// @param gasPriceOracle is the gas price oracle
    /// @param swapGasUsed is the swap gas params
    /// @param updateGasUsed is the update gas params
    /// @param depositGasUsed is the deposit per vault gas on the chain
    /// @param withdrawGasUsed is the withdraw per vault gas on the chain
    /// @param defaultNativePrice is the native price on the specified chain
    /// @param defaultGasPrice is the gas price on the specified chain
    /// @param dstGasPerByte is the gas per size of data on the specified chain
    /// @param ackGasCost is the gas cost for sending and processing from dst->src
    /// @param timelockCost is the extra cost for processing timelocked payloads
    /// @param emergencyCost is the extra cost for processing emergency payloads
    struct PaymentHelperConfig {
        address nativeFeedOracle;
        address gasPriceOracle;
        uint256 swapGasUsed;
        uint256 updateGasUsed;
        uint256 depositGasUsed;
        uint256 withdrawGasUsed;
        uint256 defaultNativePrice;
        uint256 defaultGasPrice;
        uint256 dstGasPerByte;
        uint256 ackGasCost;
        uint256 timelockCost;
        uint256 emergencyCost;
    }

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    event ChainConfigUpdated(uint64 indexed chainId_, uint256 indexed configType_, bytes config_);
    event ChainConfigAdded(uint64 chainId_, PaymentHelperConfig config_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

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

    /// @dev returns the amb overrides & gas to be used
    /// @return extraData the amb specific override information
    function getRegisterTransmuterAMBData() external view returns (bytes memory extraData);

    /// @dev estimates the gas fees for multiple destination and multi vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @param isDeposit_ indicated if the datatype will be used for a deposit
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return dstAmount is the gas expense on dst chain in terms of src chain's native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateMultiDstMultiVault(
        MultiDstMultiVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount);

    /// @dev estimates the gas fees for multiple destination and single vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @param isDeposit_ indicated if the datatype will be used for a deposit
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return dstAmount is the gas expense on dst chain in terms of src chain's native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateMultiDstSingleVault(
        MultiDstSingleVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount);

    /// @dev estimates the gas fees for single destination and multi vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @param isDeposit_ indicated if the datatype will be used for a deposit
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return dstAmount is the gas expense on dst chain in terms of src chain's native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateSingleXChainMultiVault(
        SingleXChainMultiVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount);

    /// @dev estimates the gas fees for single destination and single vault operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @param isDeposit_ indicated if the datatype will be used for a deposit
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return dstAmount is the gas expense on dst chain in terms of src chain's native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateSingleXChainSingleVault(
        SingleXChainSingleVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount);

    /// @dev estimates the gas fees for same chain operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @param isDeposit_ indicated if the datatype will be used for a deposit
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateSingleDirectSingleVault(
        SingleDirectSingleVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 totalAmount);

    /// @dev estimates the gas fees for multiple same chain operation
    /// @param req_ is the request object containing all necessary data for the actual operation on SuperRouter
    /// @param isDeposit_ indicated if the datatype will be used for a deposit
    /// @return liqAmount is the amount of liquidity to be provided in native tokens
    /// @return srcAmount is the gas expense on source chain in native tokens
    /// @return totalAmount is the native_tokens to be sent along the transaction
    function estimateSingleDirectMultiVault(
        SingleDirectMultiVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 totalAmount);

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

    /// @dev helps estimate the acknowledgement costs for amb processing
    /// @param payloadId_ is the payload identifier
    /// @return totalFees is the total fees to be paid in native tokens
    function estimateAckCost(uint256 payloadId_) external view returns (uint256 totalFees);

    /// @dev helps estimate the acknowledgement costs for amb processing without relying on payloadId (using max values)
    /// @param multi is the flag indicating if the payload is multi or single
    /// @param ackAmbIds is the list of ambIds to be used for acknowledgement
    /// @param srcChainId is the source chain identifier
    /// @return totalFees is the total fees to be paid in native tokens
    function estimateAckCostDefault(
        bool multi,
        uint8[] memory ackAmbIds,
        uint64 srcChainId
    )
        external
        view
        returns (uint256 totalFees);

    /// @dev helps estimate the acknowledgement costs for amb processing without relying on payloadId (using max values)
    /// with source native amounts
    /// @param multi is the flag indicating if the payload is multi or single
    /// @param ackAmbIds is the list of ambIds to be used for acknowledgement
    /// @param srcChainId is the source chain identifier
    /// @return totalFees is the total fees to be paid in native tokens
    function estimateAckCostDefaultNativeSource(
        bool multi,
        uint8[] memory ackAmbIds,
        uint64 srcChainId
    )
        external
        view
        returns (uint256 totalFees);
    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev admin can configure a remote chain for first time
    /// @param chainId_ is the identifier of new chain id
    /// @param config_ is the chain config
    function addRemoteChain(uint64 chainId_, PaymentHelperConfig calldata config_) external;

    /// @dev admin can specifically configure/update certain configuration of a remote chain
    /// @param chainId_ is the remote chain's identifier
    /// @param configType_ is the type of config from 1 -> 6
    /// @param config_ is the encoded new configuration
    function updateRemoteChain(uint64 chainId_, uint256 configType_, bytes memory config_) external;

    /// @dev admin updates config for register transmuter amb params
    /// @param extraDataForTransmuter_ is the broadcast extra data
    function updateRegisterAERC20Params(bytes memory extraDataForTransmuter_) external;
}

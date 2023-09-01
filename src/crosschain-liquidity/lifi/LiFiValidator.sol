// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { BridgeValidator } from "../BridgeValidator.sol";
import { ILiFi } from "../../vendor/lifi/ILiFi.sol";
import { Error } from "../../utils/Error.sol";

/// @title LiFiValidator
/// @author Zeropoint Labs
/// @dev To assert input txData is valid
contract LiFiValidator is BridgeValidator {
    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) BridgeValidator(superRegistry_) { }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BridgeValidator
    function validateTxDataAmount(bytes calldata txData_, uint256 amount_) external pure override returns (bool) {
        (ILiFi.BridgeData memory bridgeData,) = _decodeCallData(txData_);

        return bridgeData.minAmount == amount_;
    }

    /// @inheritdoc BridgeValidator
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
        view
        override
    {
        (ILiFi.BridgeData memory bridgeData, ILiFi.SwapData[] memory swapData) = _decodeCallData(txData_);

        address sendingAssetId = bridgeData.hasSourceSwaps ? swapData[0].sendingAssetId : bridgeData.sendingAssetId;

        /// @dev 1. chainId validation
        /// @dev for deposits, liqDstChainId/toChainId will be the normal destination (where the target superform is)
        /// @dev for withdraws, liqDstChainId/toChainId will be the desired chain to where the underlying must be sent
        /// @dev to after vault redemption

        if (uint256(liqDstChainId_) != bridgeData.destinationChainId) revert Error.INVALID_TXDATA_CHAIN_ID();

        /// @dev 2. receiver address validation

        if (deposit_) {
            if (srcChainId_ == dstChainId_) {
                if (dstChainId_ != liqDstChainId_) revert Error.INVALID_DEPOSIT_LIQ_DST_CHAIN_ID();

                /// @dev If same chain deposits then receiver address must be the superform
                if (bridgeData.receiver != superform_) revert Error.INVALID_TXDATA_RECEIVER();
            } else {
                /// @dev if cross chain deposits, then receiver address must be CoreStateRegistry or MultiTxProcessor
                if (
                    !(
                        bridgeData.receiver
                            == superRegistry.getAddressByChainId(keccak256("CORE_STATE_REGISTRY"), dstChainId_)
                            || bridgeData.receiver
                                == superRegistry.getAddressByChainId(keccak256("MULTI_TX_PROCESSOR"), dstChainId_)
                    )
                ) revert Error.INVALID_TXDATA_RECEIVER();
            }
        } else {
            /// @dev if withdraws, then receiver address must be the srcSender
            if (bridgeData.receiver != srcSender_) revert Error.INVALID_TXDATA_RECEIVER();
        }

        /// @dev 3. token validations
        if (liqDataToken_ != sendingAssetId) revert Error.INVALID_TXDATA_TOKEN();
    }

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver_) external pure override returns (bool valid_) {
        (ILiFi.BridgeData memory bridgeData,) = _decodeCallData(txData_);

        return bridgeData.receiver == receiver_;
    }

    /// @inheritdoc BridgeValidator
    function decodeAmount(bytes calldata txData_) external pure override returns (uint256 amount_) {
        (ILiFi.BridgeData memory bridgeData,) = _decodeCallData(txData_);

        return bridgeData.minAmount;
    }

    /// @notice Decode lifi's calldata
    /// @param data LiFi call data
    /// @return bridgeData LiFi BridgeData
    function _decodeCallData(bytes calldata data)
        internal
        pure
        returns (ILiFi.BridgeData memory bridgeData, ILiFi.SwapData[] memory swapData)
    {
        (bridgeData) = abi.decode(data[4:], (ILiFi.BridgeData));

        if (bridgeData.hasSourceSwaps) {
            (, swapData) = abi.decode(data[4:], (ILiFi.BridgeData, ILiFi.SwapData[]));
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {BridgeValidator} from "../BridgeValidator.sol";
import {ILiFi} from "../../vendor/lifi/ILiFi.sol";
import {Error} from "../../utils/Error.sol";

/// @title lifi verification contract
/// @author Zeropoint Labs
/// @dev To assert input txData is valid
contract LiFiValidator is BridgeValidator {
    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) BridgeValidator(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BridgeValidator
    function validateTxDataAmount(bytes calldata txData_, uint256 amount_) external pure override returns (bool) {
        (ILiFi.BridgeData memory bridgeData, ) = _decodeCallData(txData_);

        return bridgeData.minAmount == amount_;
    }

    /// @inheritdoc BridgeValidator
    function validateTxData(
        bytes calldata txData_,
        uint64 srcChainId_,
        uint64 dstChainId_,
        bool deposit_,
        address superForm_,
        address srcSender_,
        address liqDataToken_
    ) external view override {
        (ILiFi.BridgeData memory bridgeData, ILiFi.SwapData[] memory swapData) = _decodeCallData(txData_);

        address sendingAssetId;
        if (bridgeData.hasSourceSwaps) {
            sendingAssetId = swapData[0].sendingAssetId;
        } else {
            sendingAssetId = bridgeData.sendingAssetId;
        }

        /// @dev 1. chainId validation
        if (uint256(dstChainId_) != bridgeData.destinationChainId) revert Error.INVALID_TXDATA_CHAIN_ID();

        /// @dev 2. receiver address validation

        if (deposit_) {
            if (srcChainId_ == dstChainId_) {
                /// @dev If same chain deposits then receiver address must be the superform

                if (bridgeData.receiver != superForm_) revert Error.INVALID_TXDATA_RECEIVER();
            } else {
                /// @dev if cross chain deposits, then receiver address must be CoreStateRegistry or MultiTxProcessor
                if (
                    !(bridgeData.receiver == superRegistry.coreStateRegistryCrossChain(dstChainId_) ||
                        bridgeData.receiver == superRegistry.multiTxProcessorCrossChain(dstChainId_))
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
        (ILiFi.BridgeData memory bridgeData, ) = _decodeCallData(txData_);

        return bridgeData.receiver == receiver_;
    }

    /// @notice Decode lifi's calldata
    /// @param data LiFi call data
    /// @return bridgeData LiFi BridgeData
    function _decodeCallData(
        bytes calldata data
    ) internal pure returns (ILiFi.BridgeData memory bridgeData, ILiFi.SwapData[] memory swapData) {
        (bridgeData) = abi.decode(data[4:], (ILiFi.BridgeData));

        if (bridgeData.hasSourceSwaps) {
            (, swapData) = abi.decode(data[4:], (ILiFi.BridgeData, ILiFi.SwapData[]));
        }
    }
}

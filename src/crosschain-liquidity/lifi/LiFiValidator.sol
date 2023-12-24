// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { Error } from "src/libraries/Error.sol";
import { LiFiTxDataExtractor } from "src/vendor/lifi/LiFiTxDataExtractor.sol";
import { LibSwap } from "src/vendor/lifi/LibSwap.sol";
import { ILiFi } from "src/vendor/lifi/ILiFi.sol";
import { StandardizedCallFacet } from "src/vendor/lifi/StandardizedCallFacet.sol";

/// @title LiFiValidator
/// @author Zeropoint Labs
/// @dev To assert input txData is valid
contract LiFiValidator is BridgeValidator, LiFiTxDataExtractor {
    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) BridgeValidator(superRegistry_) {
        if (address(superRegistry_) == address(0)) revert Error.DISABLED();
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver_) external pure override returns (bool valid_) {
        (, address receiver) = _extractBridgeData(txData_);
        return receiver == receiver_;
    }

    /// @inheritdoc BridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external view override returns (bool hasDstSwap) {
        /// @dev xchain actions can have bridgeData or bridgeData + swapData
        /// @dev direct actions with deposit, cannot have bridge data - goes into catch block
        /// @dev withdraw actions may have bridge data after withdrawing - goes into try block
        /// @dev withdraw actions without bridge data (just swap) - goes into catch block

        try this.extractMainParameters(args_.txData) returns (
            string memory, /*bridge*/
            address sendingAssetId,
            address receiver,
            uint256, /*amount*/
            uint256, /*minAmount*/
            uint256 destinationChainId,
            bool, /*hasSourceSwaps*/
            bool hasDestinationCall
        ) {
            /// @dev 0. Destination call validation
            if (hasDestinationCall) revert Error.INVALID_TXDATA_NO_DESTINATIONCALL_ALLOWED();

            /// @dev 1. chainId validation
            /// @dev for deposits, liqDstChainId/toChainId will be the normal destination (where the target superform
            /// is)
            /// @dev for withdraws, liqDstChainId will be the desired chain to where the underlying must be
            /// sent (post any bridge/swap). To ChainId is where the target superform is
            /// @dev to after vault redemption

            if (uint256(args_.liqDstChainId) != destinationChainId) revert Error.INVALID_TXDATA_CHAIN_ID();

            /// @dev 2. receiver address validation
            if (args_.deposit) {
                if (args_.srcChainId == args_.dstChainId) {
                    revert Error.INVALID_ACTION();
                } else {
                    hasDstSwap =
                        receiver == superRegistry.getAddressByChainId(keccak256("DST_SWAPPER"), args_.dstChainId);
                    /// @dev if cross chain deposits, then receiver address must be CoreStateRegistry (or) Dst Swapper
                    if (
                        !(
                            receiver
                                == superRegistry.getAddressByChainId(keccak256("CORE_STATE_REGISTRY"), args_.dstChainId)
                                || hasDstSwap
                        )
                    ) {
                        revert Error.INVALID_TXDATA_RECEIVER();
                    }

                    /// @dev forbid xChain deposits with destination swaps without interim token set (for user
                    /// protection)
                    if (hasDstSwap && args_.liqDataInterimToken == address(0)) {
                        revert Error.INVALID_INTERIM_TOKEN();
                    }
                }
            } else {
                /// @dev if withdraws, then receiver address must be the receiverAddress
                if (receiver != args_.receiverAddress) revert Error.INVALID_TXDATA_RECEIVER();
            }

            /// @dev remap of address 0 to NATIVE because of how LiFi produces txData
            if (sendingAssetId == address(0)) {
                sendingAssetId = NATIVE;
            }
            /// @dev 3. token validations
            if (args_.liqDataToken != sendingAssetId) revert Error.INVALID_TXDATA_TOKEN();
        } catch {
            (address sendingAssetId,, address receiver,,) = extractGenericSwapParameters(args_.txData);

            if (args_.deposit) {
                /// @dev 1. chainId validation
                if (args_.srcChainId != args_.dstChainId) revert Error.INVALID_TXDATA_CHAIN_ID();
                if (args_.dstChainId != args_.liqDstChainId) revert Error.INVALID_DEPOSIT_LIQ_DST_CHAIN_ID();

                /// @dev 2. receiver address validation
                /// @dev If same chain deposits then receiver address must be the superform
                if (receiver != args_.superform) revert Error.INVALID_TXDATA_RECEIVER();
            } else {
                /// @dev 2. receiver address validation
                /// @dev if withdraws, then receiver address must be the receiverAddress
                if (receiver != args_.receiverAddress) revert Error.INVALID_TXDATA_RECEIVER();
            }

            /// @dev remap of address 0 to NATIVE because of how LiFi produces txData
            if (sendingAssetId == address(0)) {
                sendingAssetId = NATIVE;
            }
            /// @dev 3. token validations
            if (args_.liqDataToken != sendingAssetId) revert Error.INVALID_TXDATA_TOKEN();
        }
    }

    /// @inheritdoc BridgeValidator
    function decodeAmountIn(
        bytes calldata txData_,
        bool genericSwapDisallowed_
    )
        external
        view
        override
        returns (uint256 amount_)
    {
        try this.extractMainParameters(txData_) returns (
            string memory, /*bridge*/
            address, /*sendingAssetId*/
            address, /*receiver*/
            uint256 amount,
            uint256, /*minAmount*/
            uint256, /*destinationChainId*/
            bool, /*hasSourceSwaps*/
            bool /*hasDestinationCall*/
        ) {
            /// @dev if there isn't a source swap, amount_ is minAmountOut from bridge data

            amount_ = amount;
        } catch {
            if (genericSwapDisallowed_) revert Error.INVALID_ACTION();
            /// @dev in the case of a generic swap, amount_ is the from amount

            (, amount_,,,) = extractGenericSwapParameters(txData_);
        }
    }

    /// @inheritdoc BridgeValidator
    function decodeDstSwap(bytes calldata txData_) external pure override returns (address token_, uint256 amount_) {
        (token_, amount_,,,) = extractGenericSwapParameters(txData_);
    }

    /// @inheritdoc BridgeValidator
    function decodeSwapOutputToken(bytes calldata txData_) external view override returns (address token_) {
        try this.extractMainParameters(txData_) returns (
            string memory, /*bridge*/
            address, /*sendingAssetId*/
            address, /*receiver*/
            uint256, /*amount*/
            uint256, /*minAmount*/
            uint256, /*destinationChainId*/
            bool, /*hasSourceSwaps*/
            bool /*hasDestinationCall*/
        ) {
            /// @dev if there isn't a source swap, amountIn is minAmountOut from bridge data?

            revert Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN();
        } catch {
            (,,, address receivingAssetId,) = extractGenericSwapParameters(txData_);
            token_ = receivingAssetId;
        }
    }

    /// @notice Extracts the main parameters from the calldata
    /// @param data_ The calldata to extract the main parameters from
    /// @return bridge The bridge extracted from the calldata
    /// @return sendingAssetId The sending asset id extracted from the calldata
    /// @return receiver The receiver extracted from the calldata
    /// @return amount The amount the calldata (which may be equal to bridge min amount)
    /// @return minAmount The min amount extracted from the bridgeData calldata
    /// @return destinationChainId The destination chain id extracted from the calldata
    /// @return hasSourceSwaps Whether the calldata has source swaps
    /// @return hasDestinationCall Whether the calldata has a destination call
    function extractMainParameters(bytes calldata data_)
        public
        pure
        returns (
            string memory bridge,
            address sendingAssetId,
            address receiver,
            uint256 amount,
            uint256 minAmount,
            uint256 destinationChainId,
            bool hasSourceSwaps,
            bool hasDestinationCall
        )
    {
        ILiFi.BridgeData memory bridgeData;
        (bridgeData, receiver) = _extractBridgeData(data_);

        if (bridgeData.hasSourceSwaps) {
            LibSwap.SwapData[] memory swapData = _extractSwapData(data_);
            sendingAssetId = swapData[0].sendingAssetId;
            amount = swapData[0].fromAmount;
        } else {
            sendingAssetId = bridgeData.sendingAssetId;
            amount = bridgeData.minAmount;
        }
        minAmount = bridgeData.minAmount;
        return (
            bridgeData.bridge,
            sendingAssetId,
            receiver,
            amount,
            minAmount,
            bridgeData.destinationChainId,
            bridgeData.hasSourceSwaps,
            bridgeData.hasDestinationCall
        );
    }

    /// @notice Extracts the generic swap parameters from the calldata
    /// @param data_ The calldata to extract the generic swap parameters from
    /// @return sendingAssetId The sending asset id extracted from the calldata
    /// @return amount The amount extracted from the calldata
    /// @return receiver The receiver extracted from the calldata
    /// @return receivingAssetId The receiving asset id extracted from the calldata
    /// @return receivingAmount The receiving amount extracted from the calldata
    function extractGenericSwapParameters(bytes calldata data_)
        public
        pure
        returns (
            address sendingAssetId,
            uint256 amount,
            address receiver,
            address receivingAssetId,
            uint256 receivingAmount
        )
    {
        LibSwap.SwapData[] memory swapData;
        bytes memory callData = data_;

        if (bytes4(data_[:4]) == StandardizedCallFacet.standardizedCall.selector) {
            // standardizedCall
            callData = abi.decode(data_[4:], (bytes));
        }
        (,,, receiver, receivingAmount, swapData) = abi.decode(
            _slice(callData, 4, callData.length - 4), (bytes32, string, string, address, uint256, LibSwap.SwapData[])
        );

        sendingAssetId = swapData[0].sendingAssetId;
        amount = swapData[0].fromAmount;
        receivingAssetId = swapData[swapData.length - 1].receivingAssetId;
    }
}

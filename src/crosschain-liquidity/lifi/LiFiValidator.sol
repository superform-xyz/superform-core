// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { Error } from "src/libraries/Error.sol";
import { LiFiTxDataExtractor } from "src/vendor/lifi/LiFiTxDataExtractor.sol";
import { LibSwap } from "src/vendor/lifi/LibSwap.sol";
import { ILiFi } from "src/vendor/lifi/ILiFi.sol";
import { StandardizedCallFacet } from "src/vendor/lifi/StandardizedCallFacet.sol";
import { GenericSwapFacet } from "src/vendor/lifi/GenericSwapFacet.sol";

/// @title LiFiValidator
/// @author Zeropoint Labs
/// @dev To assert input txData is valid

contract LiFiValidator is BridgeValidator, LiFiTxDataExtractor {
    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) BridgeValidator(superRegistry_) { }

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
        bytes4 selector = _extractSelector(args_.txData);

        address sendingAssetId;
        address receiver;
        bool hasDestinationCall;
        uint256 destinationChainId;

        /// @dev 1 - check if it is a swapTokensGeneric call (match via selector)
        if (selector == GenericSwapFacet.swapTokensGeneric.selector) {
            /// @dev GenericSwapFacet
            /// @dev direct actions with deposit, cannot have bridge data - goes in here
            /// @dev withdraw actions without bridge data (just swap) -  goes in here

            (sendingAssetId,, receiver,,) = extractGenericSwapParameters(args_.txData);
            _validateGenericParameters(args_, receiver, sendingAssetId);
            /// @dev if valid return here
            return false;
        }

        /// @dev 2 - check if it is any other blacklisted selector

        if (!_validateSelector(selector)) revert Error.BLACKLISTED_SELECTOR();

        /// @dev 3 - proceed with normal extraction
        (, sendingAssetId, receiver,,, destinationChainId,, hasDestinationCall) = extractMainParameters(args_.txData);

        /// @dev xchain actions can have bridgeData or bridgeData + swapData -  goes in here
        /// @dev withdraw actions may have bridge data after withdrawing -  goes in here

        hasDstSwap =
            _validateMainParameters(args_, hasDestinationCall, hasDstSwap, receiver, sendingAssetId, destinationChainId);

        return hasDstSwap;
    }

    /// @inheritdoc BridgeValidator
    function decodeAmountIn(
        bytes calldata txData_,
        bool genericSwapDisallowed_
    )
        external
        pure
        override
        returns (uint256 amount_)
    {
        bytes4 selector = _extractSelector(txData_);

        /// @dev 1 - check if it is a swapTokensGeneric call (match via selector)
        if (selector == GenericSwapFacet.swapTokensGeneric.selector && !genericSwapDisallowed_) {
            (, amount_,,,) = extractGenericSwapParameters(txData_);
            return amount_;
        } else if (selector == GenericSwapFacet.swapTokensGeneric.selector && genericSwapDisallowed_) {
            revert Error.INVALID_ACTION();
        }

        /// @dev 2 - check if it is any other blacklisted selector
        if (!_validateSelector(selector)) revert Error.BLACKLISTED_SELECTOR();

        /// @dev 3 - proceed with normal extraction
        (, /*bridgeId*/,, amount_, /*amount*/, /*minAmount*/,, /*hasSourceSwaps*/ ) = extractMainParameters(txData_);
        /// @dev if there isn't a source swap, amount_ is minAmountOut from bridge data

        return amount_;
    }

    /// @inheritdoc BridgeValidator
    function decodeDstSwap(bytes calldata txData_) external pure override returns (address token_, uint256 amount_) {
        bytes4 selector = _extractSelector(txData_);
        if (selector == GenericSwapFacet.swapTokensGeneric.selector) {
            (token_, amount_,,,) = extractGenericSwapParameters(txData_);
            return (token_, amount_);
        } else {
            revert Error.INVALID_ACTION();
        }
    }

    /// @inheritdoc BridgeValidator
    function decodeSwapOutputToken(bytes calldata txData_) external pure override returns (address token_) {
        bytes4 selector = _extractSelector(txData_);

        if (selector == GenericSwapFacet.swapTokensGeneric.selector) {
            (,,, token_,) = extractGenericSwapParameters(txData_);
            return token_;
        } else {
            revert Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN();
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
        return (sendingAssetId, amount, receiver, receivingAssetId, receivingAmount);
    }

    function _validateMainParameters(
        ValidateTxDataArgs calldata args_,
        bool hasDestinationCall,
        bool hasDstSwap,
        address receiver,
        address sendingAssetId,
        uint256 destinationChainId
    )
        internal
        view
        returns (bool)
    {
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
                hasDstSwap = receiver == superRegistry.getAddressByChainId(keccak256("DST_SWAPPER"), args_.dstChainId);
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

        return hasDstSwap;
    }

    function _validateGenericParameters(
        ValidateTxDataArgs calldata args_,
        address receiver,
        address sendingAssetId
    )
        internal
        pure
    {
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

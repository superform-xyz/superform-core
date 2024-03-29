// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { Error } from "src/libraries/Error.sol";
import { LiFiTxDataExtractor } from "src/vendor/lifi/LiFiTxDataExtractor.sol";
import { LibSwap } from "src/vendor/lifi/LibSwap.sol";
import { ILiFi } from "src/vendor/lifi/ILiFi.sol";
import { StandardizedCallFacet } from "src/vendor/lifi/StandardizedCallFacet.sol";
import { GenericSwapFacet } from "src/vendor/lifi/GenericSwapFacet.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ILiFiValidator } from "src/interfaces/ILiFiValidator.sol";
import { AmarokFacet } from "src/vendor/lifi/AmarokFacet.sol";
import { CBridgeFacetPacked } from "src/vendor/lifi/CBridgeFacetPacked.sol";
import { HopFacet } from "src/vendor/lifi/HopFacet.sol";
import { HopFacetOptimized } from "src/vendor/lifi/HopFacetOptimized.sol";
import { HopFacetPacked } from "src/vendor/lifi/HopFacetPacked.sol";

/// @title LiFiValidator
/// @dev Asserts LiFi input txData is valid
/// @author Zeropoint Labs
contract LiFiValidator is ILiFiValidator, BridgeValidator, LiFiTxDataExtractor {
    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    /// @dev mapping to store the blacklisted selectors
    mapping(bytes4 selector => bool blacklisted) private blacklistedSelectors;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyEmergencyAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasEmergencyAdminRole(msg.sender)) {
            revert Error.NOT_EMERGENCY_ADMIN();
        }
        _;
    }
    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) BridgeValidator(superRegistry_) {
        /// @dev this blacklists certain packed and min selectors. Aditionally, it also blacklists all Hop & Amarok
        /// @dev selectors as superform is not compatible with unexpected refund tokens
        /// @dev see
        /// https://docs.li.fi/li.fi-api/li.fi-api/checking-the-status-of-a-transaction#handling-unexpected-receiving-token
        /// @notice this is a patch to prevent a user to bypass txData validation checks

        /// @dev blacklist packed and min selectors
        blacklistedSelectors[CBridgeFacetPacked.startBridgeTokensViaCBridgeNativePacked.selector] = true;
        emit AddedToBlacklist(CBridgeFacetPacked.startBridgeTokensViaCBridgeNativePacked.selector);

        blacklistedSelectors[CBridgeFacetPacked.startBridgeTokensViaCBridgeNativeMin.selector] = true;
        emit AddedToBlacklist(CBridgeFacetPacked.startBridgeTokensViaCBridgeNativeMin.selector);

        blacklistedSelectors[CBridgeFacetPacked.startBridgeTokensViaCBridgeERC20Packed.selector] = true;
        emit AddedToBlacklist(CBridgeFacetPacked.startBridgeTokensViaCBridgeERC20Packed.selector);

        blacklistedSelectors[CBridgeFacetPacked.startBridgeTokensViaCBridgeERC20Min.selector] = true;
        emit AddedToBlacklist(CBridgeFacetPacked.startBridgeTokensViaCBridgeERC20Min.selector);

        blacklistedSelectors[HopFacetPacked.startBridgeTokensViaHopL2NativePacked.selector] = true;
        emit AddedToBlacklist(HopFacetPacked.startBridgeTokensViaHopL2NativePacked.selector);

        blacklistedSelectors[HopFacetPacked.startBridgeTokensViaHopL2NativeMin.selector] = true;
        emit AddedToBlacklist(HopFacetPacked.startBridgeTokensViaHopL2NativeMin.selector);

        blacklistedSelectors[HopFacetPacked.startBridgeTokensViaHopL2ERC20Packed.selector] = true;
        emit AddedToBlacklist(HopFacetPacked.startBridgeTokensViaHopL2ERC20Packed.selector);

        blacklistedSelectors[HopFacetPacked.startBridgeTokensViaHopL2ERC20Min.selector] = true;
        emit AddedToBlacklist(HopFacetPacked.startBridgeTokensViaHopL2ERC20Min.selector);

        blacklistedSelectors[HopFacetPacked.startBridgeTokensViaHopL1NativePacked.selector] = true;
        emit AddedToBlacklist(HopFacetPacked.startBridgeTokensViaHopL1NativePacked.selector);

        blacklistedSelectors[HopFacetPacked.startBridgeTokensViaHopL1NativeMin.selector] = true;
        emit AddedToBlacklist(HopFacetPacked.startBridgeTokensViaHopL1NativeMin.selector);

        blacklistedSelectors[HopFacetPacked.startBridgeTokensViaHopL1ERC20Packed.selector] = true;
        emit AddedToBlacklist(HopFacetPacked.startBridgeTokensViaHopL1ERC20Packed.selector);

        blacklistedSelectors[HopFacetPacked.startBridgeTokensViaHopL1ERC20Min.selector] = true;
        emit AddedToBlacklist(HopFacetPacked.startBridgeTokensViaHopL1ERC20Min.selector);

        /// @dev blacklist normal and optimized hop facet
        blacklistedSelectors[HopFacet.startBridgeTokensViaHop.selector] = true;
        emit AddedToBlacklist(HopFacet.startBridgeTokensViaHop.selector);

        blacklistedSelectors[HopFacet.swapAndStartBridgeTokensViaHop.selector] = true;
        emit AddedToBlacklist(HopFacet.swapAndStartBridgeTokensViaHop.selector);

        blacklistedSelectors[HopFacetOptimized.startBridgeTokensViaHopL1ERC20.selector] = true;
        emit AddedToBlacklist(HopFacetOptimized.startBridgeTokensViaHopL1ERC20.selector);

        blacklistedSelectors[HopFacetOptimized.startBridgeTokensViaHopL1Native.selector] = true;
        emit AddedToBlacklist(HopFacetOptimized.startBridgeTokensViaHopL1Native.selector);

        blacklistedSelectors[HopFacetOptimized.swapAndStartBridgeTokensViaHopL1ERC20.selector] = true;
        emit AddedToBlacklist(HopFacetOptimized.swapAndStartBridgeTokensViaHopL1ERC20.selector);

        blacklistedSelectors[HopFacetOptimized.swapAndStartBridgeTokensViaHopL1Native.selector] = true;
        emit AddedToBlacklist(HopFacetOptimized.swapAndStartBridgeTokensViaHopL1Native.selector);

        blacklistedSelectors[HopFacetOptimized.startBridgeTokensViaHopL2ERC20.selector] = true;
        emit AddedToBlacklist(HopFacetOptimized.startBridgeTokensViaHopL2ERC20.selector);

        blacklistedSelectors[HopFacetOptimized.startBridgeTokensViaHopL2Native.selector] = true;
        emit AddedToBlacklist(HopFacetOptimized.startBridgeTokensViaHopL2Native.selector);

        blacklistedSelectors[HopFacetOptimized.swapAndStartBridgeTokensViaHopL2ERC20.selector] = true;
        emit AddedToBlacklist(HopFacetOptimized.swapAndStartBridgeTokensViaHopL2ERC20.selector);

        blacklistedSelectors[HopFacetOptimized.swapAndStartBridgeTokensViaHopL2Native.selector] = true;
        emit AddedToBlacklist(HopFacetOptimized.swapAndStartBridgeTokensViaHopL2Native.selector);

        /// @dev blacklist amarok facet
        blacklistedSelectors[AmarokFacet.startBridgeTokensViaAmarok.selector] = true;
        emit AddedToBlacklist(AmarokFacet.startBridgeTokensViaAmarok.selector);

        blacklistedSelectors[AmarokFacet.swapAndStartBridgeTokensViaAmarok.selector] = true;
        emit AddedToBlacklist(AmarokFacet.swapAndStartBridgeTokensViaAmarok.selector);

        /// @dev prevent recursive calls
        blacklistedSelectors[StandardizedCallFacet.standardizedCall.selector] = true;
        emit AddedToBlacklist(StandardizedCallFacet.standardizedCall.selector);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL  FUNCTIONS                         //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ILiFiValidator
    function addToBlacklist(bytes4 selector_) external override onlyEmergencyAdmin {
        if (blacklistedSelectors[selector_]) revert Error.BLACKLISTED_SELECTOR();

        blacklistedSelectors[selector_] = true;
        emit AddedToBlacklist(selector_);
    }

    /// @inheritdoc ILiFiValidator
    function removeFromBlacklist(bytes4 selector_) external override onlyEmergencyAdmin {
        if (!blacklistedSelectors[selector_]) revert Error.NOT_BLACKLISTED_SELECTOR();

        delete blacklistedSelectors[selector_];
        emit RemovedFromBlacklist(selector_);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ILiFiValidator
    function isSelectorBlacklisted(bytes4 selector_) public view override returns (bool blacklisted) {
        return blacklistedSelectors[selector_];
    }

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver_) external view override returns (bool valid_) {
        bytes4 selector = _extractSelector(txData_);
        address receiver;
        /// @dev check if it is a blacklisted selector
        if (isSelectorBlacklisted(selector)) revert Error.BLACKLISTED_SELECTOR();

        /// @dev 2 - check if it is a swapTokensGeneric call (match via selector)
        if (selector == GenericSwapFacet.swapTokensGeneric.selector) {
            /// @dev GenericSwapFacet

            (,, receiver,,) = extractGenericSwapParameters(txData_);
        } else {
            /// @dev 3 - proceed with normal extraction
            (,, receiver,,,,,) = extractMainParameters(txData_);
        }

        return receiver == receiver_;
    }

    /// @inheritdoc BridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external view override returns (bool hasDstSwap) {
        bytes4 selector = _extractSelector(args_.txData);

        address sendingAssetId;
        address receiver;
        bool hasDestinationCall;
        uint256 destinationChainId;

        /// @dev 1 - check if it is a blacklisted selector
        if (isSelectorBlacklisted(selector)) revert Error.BLACKLISTED_SELECTOR();

        /// @dev 2 - check if it is a swapTokensGeneric call (match via selector)
        if (selector == GenericSwapFacet.swapTokensGeneric.selector) {
            /// @dev GenericSwapFacet

            (sendingAssetId,, receiver,,) = extractGenericSwapParameters(args_.txData);
            _validateGenericParameters(args_, receiver, sendingAssetId);
            /// @dev if valid return here
            return false;
        }

        /// @dev 3 - proceed with normal extraction
        (, sendingAssetId, receiver,,, destinationChainId,, hasDestinationCall) = extractMainParameters(args_.txData);

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
        view
        override
        returns (uint256 amount_)
    {
        bytes4 selector = _extractSelector(txData_);

        /// @dev 1 - check if it is a  blacklisted selector
        if (isSelectorBlacklisted(selector)) revert Error.BLACKLISTED_SELECTOR();

        /// @dev 2 - check if it is a swapTokensGeneric call (match via selector)
        if (selector == GenericSwapFacet.swapTokensGeneric.selector) {
            if (genericSwapDisallowed_) {
                revert Error.INVALID_ACTION();
            }
            (, amount_,,,) = extractGenericSwapParameters(txData_);
            return amount_;
        }

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

            /// @dev remap of address 0 to NATIVE because of how LiFi produces txData
            if (token_ == address(0)) {
                token_ = NATIVE;
            }

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
        /// @notice xchain actions can have bridgeData or swapData + bridgeData

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
        /// @notice direct actions with deposit, cannot have bridge data
        /// @notice withdraw actions without bridge data (just swap) also fall in GenericSwap
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

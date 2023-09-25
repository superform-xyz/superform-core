// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { Error } from "src/utils/Error.sol";
import { LiFiTxDataExtractor } from "src/vendor/lifi/LiFiTxDataExtractor.sol";
import { LibSwap } from "src/vendor/lifi/LibSwap.sol";
import { ILiFi } from "src/vendor/lifi/ILiFi.sol";

/// @title LiFiValidator
/// @author Zeropoint Labs
/// @dev To assert input txData is valid
contract LiFiValidator is BridgeValidator, LiFiTxDataExtractor {
    /*///////////////////////////////////////////////////////////////
                              Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) BridgeValidator(superRegistry_) { }

    /// @inheritdoc BridgeValidator
    function validateLiqDstChainId(
        bytes calldata txData_,
        uint64 liqDstChainId_
    )
        external
        pure
        override
        returns (bool)
    {
        return (uint256(liqDstChainId_) == _extractBridgeData(txData_).destinationChainId);
    }

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver_) external pure override returns (bool valid_) {
        return _extractBridgeData(txData_).receiver == receiver_;
    }

    /// @inheritdoc BridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external view override {
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
            /// @dev for withdraws, liqDstChainId/toChainId will be the desired chain to where the underlying must be
            /// sent
            /// @dev to after vault redemption

            if (uint256(args_.liqDstChainId) != destinationChainId) revert Error.INVALID_TXDATA_CHAIN_ID();

            /// @dev 2. receiver address validation
            if (args_.deposit) {
                if (args_.srcChainId == args_.dstChainId) {
                    revert Error.INVALID_ACTION();
                } else {
                    /// @dev if cross chain deposits, then receiver address must be CoreStateRegistry (or) Dst Swapper
                    if (
                        !(
                            receiver
                                == superRegistry.getAddressByChainId(keccak256("CORE_STATE_REGISTRY"), args_.dstChainId)
                                || receiver == superRegistry.getAddressByChainId(keccak256("DST_SWAPPER"), args_.dstChainId)
                        )
                    ) {
                        revert Error.INVALID_TXDATA_RECEIVER();
                    }
                }
            } else {
                /// @dev if withdraws, then receiver address must be the srcSender
                if (receiver != args_.srcSender) revert Error.INVALID_TXDATA_RECEIVER();
            }

            /// @dev 3. token validations
            if (args_.liqDataToken != sendingAssetId) revert Error.INVALID_TXDATA_TOKEN();
        } catch {
            (address sendingAssetId,, address receiver,,) = extractGenericSwapParameters(args_.txData);

            /// @dev 1. chainId validation

            if (args_.srcChainId != args_.dstChainId) revert Error.INVALID_ACTION();

            /// @dev 2. receiver address validation
            if (args_.deposit) {
                if (args_.dstChainId != args_.liqDstChainId) revert Error.INVALID_DEPOSIT_LIQ_DST_CHAIN_ID();
                /// @dev If same chain deposits then receiver address must be the superform
                if (receiver != args_.superform) revert Error.INVALID_TXDATA_RECEIVER();
            } else {
                /// @dev if withdraws, then receiver address must be the srcSender
                if (receiver != args_.srcSender) revert Error.INVALID_TXDATA_RECEIVER();
            }

            /// @dev 3. token validations
            if (args_.liqDataToken != sendingAssetId) revert Error.INVALID_TXDATA_TOKEN();
        }
    }

    /// @inheritdoc BridgeValidator
    function decodeMinAmountOut(
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
            uint256, /*amount*/
            uint256 minAmount,
            uint256, /*destinationChainId*/
            bool, /*hasSourceSwaps*/
            bool /*hasDestinationCall*/
        ) {
            /// @dev try is just used here to validate the txData. We need to always extract minAmount from bridge data
            amount_ = minAmount;
        } catch {
            if (genericSwapDisallowed_) revert Error.INVALID_ACTION();
            /// @dev in the case of a generic swap, minAmountOut is considered to be the receivedAmount
            (,,,, amount_) = extractGenericSwapParameters(txData_);
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
            /// @dev if there isn't a source swap, amountIn is minAmountOut from bridge data?

            amount_ = amount;
        } catch {
            if (genericSwapDisallowed_) revert Error.INVALID_ACTION();
            /// @dev in the case of a generic swap, amountIn is the from amount

            (, amount_,,,) = extractGenericSwapParameters(txData_);
        }
    }

    /// @inheritdoc BridgeValidator
    function decodeDstSwap(bytes calldata txData_) external pure override returns (address token_, uint256 amount_) {
        (token_, amount_,,,) = extractGenericSwapParameters(txData_);
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
        ILiFi.BridgeData memory bridgeData = _extractBridgeData(data_);

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
            bridgeData.receiver,
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

        if (bytes4(data_[:4]) == 0xd6a4bc50) {
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
}

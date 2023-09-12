// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { Error } from "src/utils/Error.sol";
import { IMinimalCalldataVerification } from "src/vendor/lifi/IMinimalCalldataVerification.sol";
import { LiFiTxDataExtractor } from "src/vendor/lifi/LiFiTxDataExtractor.sol";

/// @title LiFiValidator
/// @author Zeropoint Labs
/// @dev To assert input txData is valid
contract LiFiValidator is BridgeValidator, LiFiTxDataExtractor {
    IMinimalCalldataVerification public minimalCalldataVerification;

    /// @notice Emitted when the minimalCalldataVerification contract is set
    event CalldataVerificationSet(address minimalCalldataVerification);

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

    constructor(address superRegistry_, address minimalCalldataVerification_) BridgeValidator(superRegistry_) {
        minimalCalldataVerification = IMinimalCalldataVerification(minimalCalldataVerification_);
        emit CalldataVerificationSet(minimalCalldataVerification_);
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev allows the protocol admin to set the minimalCalldataVerification contract
    function setCalldataVerification(address minimalCalldataVerification_) external onlyProtocolAdmin {
        minimalCalldataVerification = IMinimalCalldataVerification(minimalCalldataVerification_);
        emit CalldataVerificationSet(minimalCalldataVerification_);
    }

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
        /// @dev xchain actions can have bridgeData or bridgeData + swapData
        /// @dev direct actions with deposit, cannot have bridge data - goes into catch block
        /// @dev withdraw actions may have bridge data after withdrawing - goes into try block
        /// @dev withdraw actions without bridge data (just swap) - goes into catch block

        try minimalCalldataVerification.extractMainParameters(txData_) returns (
            string memory bridge,
            address sendingAssetId,
            address receiver,
            uint256 amount,
            uint256 destinationChainId,
            bool hasSourceSwaps,
            bool hasDestinationCall
        ) {
            /// @dev 1. chainId validation
            /// @dev for deposits, liqDstChainId/toChainId will be the normal destination (where the target superform
            /// is)
            /// @dev for withdraws, liqDstChainId/toChainId will be the desired chain to where the underlying must be
            /// sent
            /// @dev to after vault redemption

            if (uint256(liqDstChainId_) != destinationChainId) revert Error.INVALID_TXDATA_CHAIN_ID();

            /// @dev 2. receiver address validation

            if (deposit_) {
                if (srcChainId_ == dstChainId_) {
                    revert Error.INVALID_ACTION();
                } else {
                    /// @dev if cross chain deposits, then receiver address must be CoreStateRegistry
                    if (receiver != superRegistry.getAddressByChainId(keccak256("CORE_STATE_REGISTRY"), dstChainId_)) {
                        revert Error.INVALID_TXDATA_RECEIVER();
                    }
                }
            } else {
                /// @dev if withdraws, then receiver address must be the srcSender
                if (receiver != srcSender_) revert Error.INVALID_TXDATA_RECEIVER();
            }

            /// @dev 3. token validations
            if (liqDataToken_ != sendingAssetId) revert Error.INVALID_TXDATA_TOKEN();
        } catch {
            (address sendingAssetId,, address receiver,,) =
                minimalCalldataVerification.extractGenericSwapParameters(txData_);

            /// @dev 1. chainId validation

            if (srcChainId_ != dstChainId_) revert Error.INVALID_ACTION();

            /// @dev 2. receiver address validation
            if (deposit_) {
                if (dstChainId_ != liqDstChainId_) revert Error.INVALID_DEPOSIT_LIQ_DST_CHAIN_ID();
                /// @dev If same chain deposits then receiver address must be the superform
                if (receiver != superform_) revert Error.INVALID_TXDATA_RECEIVER();
            } else {
                /// @dev if withdraws, then receiver address must be the srcSender
                if (receiver != srcSender_) revert Error.INVALID_TXDATA_RECEIVER();
            }

            /// @dev 3. token validations
            if (liqDataToken_ != sendingAssetId) revert Error.INVALID_TXDATA_TOKEN();
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
        try minimalCalldataVerification.extractMainParameters(txData_) returns (
            string memory bridge,
            address sendingAssetId,
            address receiver,
            uint256 amount,
            uint256 destinationChainId,
            bool hasSourceSwaps,
            bool hasDestinationCall
        ) {
            /// @dev this assumes no dst chain swap!!!? otherwise how can we get that value?

            amount_ = amount;
        } catch {
            if (genericSwapDisallowed_) revert Error.INVALID_ACTION();

            (,,,, amount_) = minimalCalldataVerification.extractGenericSwapParameters(txData_);
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
        try minimalCalldataVerification.extractMainParameters(txData_) returns (
            string memory bridge,
            address sendingAssetId,
            address receiver,
            uint256 amount,
            uint256 destinationChainId,
            bool hasSourceSwaps,
            bool hasDestinationCall
        ) {
            amount_ = amount;
        } catch {
            if (genericSwapDisallowed_) revert Error.INVALID_ACTION();

            (, amount_,,,) = minimalCalldataVerification.extractGenericSwapParameters(txData_);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { Error } from "src/libraries/Error.sol";
import { DeBridgeError } from "src/crosschain-liquidity/debridge/libraries/DeBridgeError.sol";
import { IDlnSource } from "src/vendor/deBridge/IDlnSource.sol";
import { DlnOrderLib } from "src/vendor/deBridge/DlnOrderLib.sol";

/// @title DeBridgeValidator
/// @dev Asserts if De-Bridge input txData is valid
/// @author Zeropoint Labs
contract DeBridgeValidator is BridgeValidator {
    //////////////////////////////////////////////////////////////
    //                       CONSTANTS                          //
    //////////////////////////////////////////////////////////////
    bytes private constant NATIVE_IN_BYTES = abi.encodePacked(NATIVE);

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) BridgeValidator(superRegistry_) { }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver) external pure override returns (bool) {
        DlnOrderLib.OrderCreation memory deBridgeQuote = _decodeTxData(txData_);

        return (receiver == _castToAddress(deBridgeQuote.receiverDst));
    }

    /// @inheritdoc BridgeValidator
    /// @dev make sure the OrderCreation.allowedCancelBeneficiarySrc and OrderCreation.givePatchAuthoritySrc is the user
    /// address on source
    function validateTxData(ValidateTxDataArgs calldata args_) external view override returns (bool hasDstSwap) {
        DlnOrderLib.OrderCreation memory deBridgeQuote = _decodeTxData(args_.txData);

        /// sanity check for allowed parameters of tx data
        if (deBridgeQuote.externalCall.length > 0) revert DeBridgeError.INVALID_EXTRA_CALL_DATA();

        if (deBridgeQuote.allowedTakerDst.length > 0) revert DeBridgeError.INVALID_TAKER_DST();

        /// @dev mandates the refund receiver to be args_.receiver
        if (_castToAddress(deBridgeQuote.allowedCancelBeneficiarySrc) != args_.receiverAddress) {
            revert DeBridgeError.INVALID_REFUND_ADDRESS();
        }

        /// @dev mandates the give patch authority src to be args_.receiver
        if (deBridgeQuote.givePatchAuthoritySrc != args_.receiverAddress) {
            revert DeBridgeError.INVALID_PATCH_ADDRESS();
        }

        if (
            superRegistry.getAddressByChainId(keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE"), args_.liqDstChainId)
                != _castToAddress(deBridgeQuote.orderAuthorityAddressDst)
        ) revert DeBridgeError.INVALID_DEBRIDGE_AUTHORITY();

        /// @dev 1. chain id validation
        if (
            uint64(deBridgeQuote.takeChainId) != args_.liqDstChainId
                || args_.liqDataToken != deBridgeQuote.giveTokenAddress
        ) revert Error.INVALID_TXDATA_CHAIN_ID();

        /// @dev 2. receiver address validation
        /// @dev allows dst swaps by coupling debridge with other bridges
        address receiver = _castToAddress(deBridgeQuote.receiverDst);

        if (args_.deposit) {
            if (args_.srcChainId == args_.dstChainId || args_.dstChainId != args_.liqDstChainId) {
                revert Error.INVALID_ACTION();
            }

            hasDstSwap = receiver == superRegistry.getAddressByChainId(keccak256("DST_SWAPPER"), args_.dstChainId);

            /// @dev if cross chain deposits, then receiver address must be CoreStateRegistry (or) Dst Swapper
            if (
                !(
                    receiver == superRegistry.getAddressByChainId(keccak256("CORE_STATE_REGISTRY"), args_.dstChainId)
                        || hasDstSwap
                )
            ) {
                revert Error.INVALID_TXDATA_RECEIVER();
            }

            /// @dev if there is a dst swap then the interim token should be the quote of debridge
            if (hasDstSwap && (args_.liqDataInterimToken != _castToAddress(deBridgeQuote.takeTokenAddress))) {
                revert Error.INVALID_INTERIM_TOKEN();
            }
        } else {
            /// @dev if withdrawal, then receiver address must be the receiverAddress
            if (receiver != args_.receiverAddress) revert Error.INVALID_TXDATA_RECEIVER();
        }
    }

    /// @inheritdoc BridgeValidator
    function decodeAmountIn(
        bytes calldata txData_,
        bool /*genericSwapDisallowed_*/
    )
        external
        pure
        override
        returns (uint256 amount_)
    {
        DlnOrderLib.OrderCreation memory deBridgeQuote = _decodeTxData(txData_);
        amount_ = deBridgeQuote.giveAmount;
    }

    /// @inheritdoc BridgeValidator
    function decodeDstSwap(bytes calldata /*txData_*/ )
        external
        pure
        override
        returns (address, /*token_*/ uint256 /*amount_*/ )
    {
        /// @dev debridge cannot be used for just swaps
        revert Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN();
    }

    /// @inheritdoc BridgeValidator
    function decodeSwapOutputToken(bytes calldata /*txData_*/ ) external pure override returns (address /*token_*/ ) {
        /// @dev debridge cannot be used for same chain swaps
        revert Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN();
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @notice supports both `createOrder` and `createSaltedOrder` functions for bridging using dln source
    function _decodeTxData(bytes calldata txData_)
        public
        pure
        returns (DlnOrderLib.OrderCreation memory deBridgeQuote)
    {
        /// @dev supports both the allowed order types by debridge
        bytes4 selector = bytes4(txData_[:4]);

        /// @dev we don't support permit envelope
        bytes memory permitEnvelope;

        if (selector == IDlnSource.createOrder.selector) {
            (deBridgeQuote,,, permitEnvelope) =
                abi.decode(_parseCallData(txData_), (DlnOrderLib.OrderCreation, bytes, uint32, bytes));
        } else if (selector == IDlnSource.createSaltedOrder.selector) {
            (deBridgeQuote,,,, permitEnvelope,) =
                abi.decode(_parseCallData(txData_), (DlnOrderLib.OrderCreation, uint64, bytes, uint32, bytes, bytes));
        } else {
            revert Error.BLACKLISTED_ROUTE_ID();
        }

        if (permitEnvelope.length > 0) {
            revert DeBridgeError.INVALID_PERMIT_ENVELOP();
        }

        /// @dev casting native tokens
        if (deBridgeQuote.giveTokenAddress == address(0)) deBridgeQuote.giveTokenAddress = NATIVE;
        if (_castToAddress(deBridgeQuote.takeTokenAddress) == address(0)) {
            deBridgeQuote.takeTokenAddress = NATIVE_IN_BYTES;
        }
    }

    /// @dev helps parsing debridge calldata and return the input parameters
    function _parseCallData(bytes calldata callData) internal pure returns (bytes calldata) {
        return callData[4:];
    }

    /// @dev helps cast bytes to address
    function _castToAddress(bytes memory address_) internal pure returns (address) {
        return address(uint160(bytes20(address_)));
    }
}

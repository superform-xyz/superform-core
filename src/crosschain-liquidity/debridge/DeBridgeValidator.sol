// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { Error } from "src/libraries/Error.sol";
import { IDlnSource } from "src/vendor/debridge/IDlnSource.sol";
import { DlnOrderLib } from "src/vendor/debridge/DlnOrderLib.sol";

/// @title DeBridgeValidator
/// @dev Asserts if De-Bridge input txData is valid
/// @author Zeropoint Labs
contract DeBridgeValidator is BridgeValidator {
    //////////////////////////////////////////////////////////////
    //                        ERRORS                            //
    //////////////////////////////////////////////////////////////

    /// @dev if permit envelop length is greater than zero
    error INVALID_PERMIT_ENVELOP();

    /// @dev if authority address is invalid
    error INVALID_DEBRIDGE_AUTHORITY();

    /// @dev if external call is allowed
    error INVALID_EXTRA_CALL_DATA();

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

    /// NOTE: check other parameters including: `givePatchAuthoritySrc`
    /// @inheritdoc BridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external view override returns (bool hasDstSwap) {
        DlnOrderLib.OrderCreation memory deBridgeQuote = _decodeTxData(args_.txData);

        if (deBridgeQuote.externalCall.length > 0) revert INVALID_EXTRA_CALL_DATA();

        if (
            superRegistry.getAddressByChainId(keccak256("DEBRIDGE_AUTHORITY"), args_.dstChainId)
                != _castToAddress(deBridgeQuote.orderAuthorityAddressDst)
        ) revert INVALID_DEBRIDGE_AUTHORITY();

        /// FIXME: add explicity revert message
        if (deBridgeQuote.allowedCancelBeneficiarySrc.length > 0) revert();

        /// @dev 1. chain id validation
        /// FIXME: check if this cast is right
        /// FIXME: check upstream if the srcChain in this context is the block.chainid
        if (
            uint64(deBridgeQuote.takeChainId) != args_.liqDstChainId
                || args_.liqDataToken != deBridgeQuote.giveTokenAddress
        ) revert Error.INVALID_TXDATA_CHAIN_ID();

        /// @dev 2. receiver address validation
        /// @dev allows dst swaps by coupling debridge with other bridges

        /// FIXME: check if this cast is right
        address receiver = _castToAddress(deBridgeQuote.receiverDst);
        if (args_.deposit) {
            if (args_.srcChainId == args_.dstChainId) {
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

    /// NOTE: we should only allow the `tradeXChainRFQT` identifier
    function _decodeTxData(bytes calldata txData_)
        internal
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
            revert INVALID_PERMIT_ENVELOP();
        }
    }

    /// @dev helps parsing debridge calldata and return the input parameters
    function _parseCallData(bytes calldata callData) internal pure returns (bytes calldata) {
        return callData[4:];
    }

    /// @dev helps cast bytes to address
    function _castToAddress(bytes memory address_) internal pure returns (address) {
        /// FIXME: check if address(uint160(uint256(b))) could be true ??
        return abi.decode(address_, (address));
    }
}

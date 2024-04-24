// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { Error } from "src/libraries/Error.sol";
import { IDlnSource } from "src/vendor/debridge/IDlnSource.sol";
import { DlnOrderLib } from "src/vendor/debridge/DlnOrderLib.sol";
import { ICrossChainForwarder } from "src/vendor/debridge/ICrossChainForwarder.sol";

/// @title DeBridgeForwarderValidator
/// @dev Asserts if De-Bridge swap + bridge input txData is valid
/// @author Zeropoint Labs
contract DeBridgeForwarderValidator is BridgeValidator {
    //////////////////////////////////////////////////////////////
    //                       CONSTANTS                          //
    //////////////////////////////////////////////////////////////
    address private constant DE_BRIDGE_SOURCE = 0xeF4fB24aD0916217251F553c0596F8Edc630EB66;

    //////////////////////////////////////////////////////////////
    //                       STRUCTS                            //
    //////////////////////////////////////////////////////////////

    struct DecodedQuote {
        address inputToken;
        uint256 inputAmount;
        uint256 dstChainId;
        address outputToken;
        uint256 outputAmount;
        address finalReceiver;
        address orderAuthorityAddressDst;
    }

    //////////////////////////////////////////////////////////////
    //                        ERRORS                            //
    //////////////////////////////////////////////////////////////

    /// @dev if permit envelop length is greater than zero
    error INVALID_PERMIT_ENVELOP();

    /// @dev if authority address is invalid
    error INVALID_DEBRIDGE_AUTHORITY();

    /// @dev if external call is allowed
    error INVALID_EXTRA_CALL_DATA();

    /// @dev if bridge data is invalid
    error INVALID_BRIDGE_DATA();

    /// @dev if swap token and bridge token mismatch
    error INVALID_BRIDGE_TOKEN();

    /// @dev if source authority address is invalid
    error INVALID_SRC_DEBRIDGE_AUTHORITY();

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) BridgeValidator(superRegistry_) { }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver) external view override returns (bool) {
        DecodedQuote memory deBridgeQuote = _decodeTxData(txData_);

        return (receiver == deBridgeQuote.finalReceiver);
    }

    /// NOTE: check other parameters including: `givePatchAuthoritySrc`
    /// @inheritdoc BridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external view override returns (bool hasDstSwap) {
        DecodedQuote memory deBridgeQuote = _decodeTxData(args_.txData);

        if (
            superRegistry.getAddressByChainId(keccak256("DEBRIDGE_AUTHORITY"), args_.dstChainId)
                != deBridgeQuote.orderAuthorityAddressDst
        ) revert INVALID_DEBRIDGE_AUTHORITY();

        /// @dev 1. chain id calidation
        /// FIXME: check if this cast is right
        /// FIXME: check upstream if the srcChain in this context is the block.chainid
        if (uint64(deBridgeQuote.dstChainId) != args_.liqDstChainId || args_.liqDataToken != deBridgeQuote.inputToken) {
            revert Error.INVALID_TXDATA_CHAIN_ID();
        }

        /// @dev 2. receiver address validation
        /// @dev allows dst swaps by coupling hashflow with other bridges
        if (args_.deposit) {
            if (args_.srcChainId == args_.dstChainId) {
                revert Error.INVALID_ACTION();
            }

            hasDstSwap = deBridgeQuote.finalReceiver
                == superRegistry.getAddressByChainId(keccak256("DST_SWAPPER"), args_.dstChainId);

            /// @dev if cross chain deposits, then receiver address must be CoreStateRegistry (or) Dst Swapper
            if (
                !(
                    deBridgeQuote.finalReceiver
                        == superRegistry.getAddressByChainId(keccak256("CORE_STATE_REGISTRY"), args_.dstChainId)
                        || hasDstSwap
                )
            ) {
                revert Error.INVALID_TXDATA_RECEIVER();
            }

            /// @dev if there is a dst swap then the interim token should be the quote of hashflow
            if (hasDstSwap && (args_.liqDataInterimToken != deBridgeQuote.outputToken)) {
                revert Error.INVALID_INTERIM_TOKEN();
            }
        } else {
            /// @dev if withdrawal, then receiver address must be the receiverAddress
            if (deBridgeQuote.finalReceiver != args_.receiverAddress) revert Error.INVALID_TXDATA_RECEIVER();
        }
    }

    /// @inheritdoc BridgeValidator
    function decodeAmountIn(
        bytes calldata txData_,
        bool /*genericSwapDisallowed_*/
    )
        external
        view
        override
        returns (uint256 amount_)
    {
        DecodedQuote memory deBridgeQuote = _decodeTxData(txData_);
        amount_ = deBridgeQuote.inputAmount;
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

    struct InternalVars {
        bytes4 selector;
        address swapOutputToken;
        address swapRefundAddress;
        address bridgeTarget;
        bytes bridgeTxData;
        bytes permitEnvelope;
        DlnOrderLib.OrderCreation xChainQuote;
    }

    /// NOTE: we should only allow the `tradeXChainRFQT` identifier
    function _decodeTxData(bytes calldata txData_) internal view returns (DecodedQuote memory deBridgeQuote) {
        InternalVars memory v;

        /// @dev supports both the allowed order types by debridge
        v.selector = bytes4(txData_[:4]);

        if (v.selector == ICrossChainForwarder.strictlySwapAndCall.selector) {
            /// @decode the input txdata
            (
                deBridgeQuote.inputToken,
                deBridgeQuote.inputAmount,
                ,
                ,
                ,
                v.swapOutputToken,
                ,
                v.swapRefundAddress,
                v.bridgeTarget,
                v.bridgeTxData
            ) = abi.decode(
                parseCallData(txData_),
                (address, uint256, bytes, address, bytes, address, uint256, address, address, bytes)
            );
        } else {
            revert Error.BLACKLISTED_ROUTE_ID();
        }

        /// bridge tx data shouldn't be empty
        if (v.bridgeTxData.length == 0 || v.bridgeTarget != DE_BRIDGE_SOURCE) revert INVALID_BRIDGE_DATA();

        /// now decoding the bridge data
        v.selector = _parseSelectorMem(v.bridgeTxData);
        if (v.selector == IDlnSource.createOrder.selector) {
            (v.xChainQuote,,, v.permitEnvelope) =
                abi.decode(this.parseCallData(v.bridgeTxData), (DlnOrderLib.OrderCreation, bytes, uint32, bytes));
        } else if (v.selector == IDlnSource.createSaltedOrder.selector) {
            abi.decode(
                this.parseCallData(v.bridgeTxData), (DlnOrderLib.OrderCreation, uint64, bytes, uint32, bytes, bytes)
            );
        } else {
            revert Error.BLACKLISTED_ROUTE_ID();
        }

        if (v.swapOutputToken != v.xChainQuote.giveTokenAddress) revert INVALID_BRIDGE_TOKEN();

        if (v.xChainQuote.givePatchAuthoritySrc != address(0) || v.xChainQuote.allowedCancelBeneficiarySrc.length > 0) {
            revert INVALID_SRC_DEBRIDGE_AUTHORITY();
        }

        if (v.permitEnvelope.length > 0) {
            revert INVALID_PERMIT_ENVELOP();
        }

        if (v.xChainQuote.externalCall.length > 0) {
            revert INVALID_EXTRA_CALL_DATA();
        }

        deBridgeQuote.outputToken = _castToAddress(v.xChainQuote.takeTokenAddress);
        deBridgeQuote.outputAmount = v.xChainQuote.takeAmount;
        deBridgeQuote.finalReceiver = _castToAddress(v.xChainQuote.receiverDst);
        deBridgeQuote.dstChainId = v.xChainQuote.takeChainId;
        deBridgeQuote.orderAuthorityAddressDst = _castToAddress(v.xChainQuote.orderAuthorityAddressDst);
    }

    /// @dev helps parsing debridge calldata and return the input parameters
    function parseCallData(bytes calldata callData) public pure returns (bytes calldata) {
        return callData[4:];
    }

    /// @dev helps parse bytes memory selector
    function _parseSelectorMem(bytes memory data) internal pure returns (bytes4 selector) {
        assembly {
            selector := mload(data)
        }
    }

    /// @dev helps cast bytes to address
    function _castToAddress(bytes memory address_) internal pure returns (address) {
        /// FIXME: check if address(uint160(uint256(b))) could be true ??
        return abi.decode(address_, (address));
    }
}

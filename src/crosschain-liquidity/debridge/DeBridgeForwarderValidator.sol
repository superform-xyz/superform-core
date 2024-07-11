// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { Error } from "src/libraries/Error.sol";
import { DeBridgeError } from "src/crosschain-liquidity/debridge/libraries/DeBridgeError.sol";
import { IDlnSource } from "src/vendor/deBridge/IDlnSource.sol";
import { DlnOrderLib } from "src/vendor/deBridge/DlnOrderLib.sol";
import { ICrossChainForwarder } from "src/vendor/deBridge/ICrossChainForwarder.sol";

/// @title DeBridgeForwarderValidator
/// @dev Asserts if De-Bridge swap + bridge input txData is valid
/// @author Zeropoint Labs
contract DeBridgeForwarderValidator is BridgeValidator {
    //////////////////////////////////////////////////////////////
    //                       CONSTANTS                          //
    //////////////////////////////////////////////////////////////
    address private constant DE_BRIDGE_SOURCE = 0xeF4fB24aD0916217251F553c0596F8Edc630EB66;
    ICrossChainForwarder private constant DE_BRIDGE_FORWARDER =
        ICrossChainForwarder(0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251);

    //////////////////////////////////////////////////////////////
    //                       STRUCTS                            //
    //////////////////////////////////////////////////////////////

    struct DecodedQuote {
        /// swap input token
        address inputToken;
        /// swap input amount
        uint256 inputAmount;
        /// final bridging dst chain id
        uint256 dstChainId;
        /// final take token (after swap + bridge)
        address outputToken;
        /// final take token amount
        uint256 outputAmount;
        /// excess swap output receiver
        address swapRefundRecipient;
        /// bridge cancel beneficiary
        address bridgeRefundRecipient;
        /// final take token receiver on dst chain
        address finalReceiver;
        address givePatchAuthoritySrc;
        address orderAuthorityAddressDst;
    }
    /// order authority for bridge on dst chain

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

    /// @inheritdoc BridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external view override returns (bool hasDstSwap) {
        DecodedQuote memory deBridgeQuote = _decodeTxData(args_.txData);

        /// @dev mandates the refund receiver to be args_.receiver
        if (
            deBridgeQuote.bridgeRefundRecipient != args_.receiverAddress
                || deBridgeQuote.swapRefundRecipient != args_.receiverAddress
        ) {
            revert DeBridgeError.INVALID_REFUND_ADDRESS();
        }

        /// @dev mandates the give patch authority src to be args_.receiver
        if (deBridgeQuote.givePatchAuthoritySrc != args_.receiverAddress) {
            revert DeBridgeError.INVALID_PATCH_ADDRESS();
        }

        if (
            superRegistry.getAddressByChainId(keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE"), args_.dstChainId)
                != deBridgeQuote.orderAuthorityAddressDst
        ) revert DeBridgeError.INVALID_DEBRIDGE_AUTHORITY();

        /// @dev 1. chain id validation
        if (uint64(deBridgeQuote.dstChainId) != args_.liqDstChainId || args_.liqDataToken != deBridgeQuote.inputToken) {
            revert Error.INVALID_TXDATA_CHAIN_ID();
        }

        /// @dev 2. receiver address validation
        /// @dev allows dst swaps by coupling debridge with other bridges
        if (args_.deposit) {
            if (args_.srcChainId == args_.dstChainId || args_.dstChainId != args_.liqDstChainId) {
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

            /// @dev if there is a dst swap then the interim token should be the quote of debridge
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
        revert DeBridgeError.ONLY_SWAPS_DISALLOWED();
    }

    /// @inheritdoc BridgeValidator
    function decodeSwapOutputToken(bytes calldata /*txData_*/ ) external pure override returns (address /*token_*/ ) {
        /// @dev debridge cannot be used for same chain swaps
        revert DeBridgeError.ONLY_SWAPS_DISALLOWED();
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    struct InternalVars {
        bytes4 selector;
        address swapOutputToken;
        address swapRouter;
        bytes swapPermitEnvelope;
        address bridgeTarget;
        bytes bridgeTxData;
        bytes permitEnvelope;
        DlnOrderLib.OrderCreation xChainQuote;
    }

    /// @notice supports `strictlySwapAndCall` function for swapping using forwarder
    function _decodeTxData(bytes calldata txData_) internal view returns (DecodedQuote memory deBridgeQuote) {
        InternalVars memory v;

        /// @dev supports both the allowed order types by debridge
        v.selector = bytes4(txData_[:4]);

        if (v.selector == ICrossChainForwarder.strictlySwapAndCall.selector) {
            /// @decode the input txdata
            (
                deBridgeQuote.inputToken,
                deBridgeQuote.inputAmount,
                v.swapPermitEnvelope,
                v.swapRouter,
                ,
                v.swapOutputToken,
                ,
                deBridgeQuote.swapRefundRecipient,
                v.bridgeTarget,
                v.bridgeTxData
            ) = abi.decode(
                parseCallData(txData_),
                (address, uint256, bytes, address, bytes, address, uint256, address, address, bytes)
            );
        } else {
            revert Error.BLACKLISTED_ROUTE_ID();
        }

        /// swap permit envelope should be empty
        if (v.swapPermitEnvelope.length > 0) {
            revert DeBridgeError.INVALID_SWAP_PERMIT_ENVELOP();
        }

        /// defensive check to protect against unknown swap routers
        /// this check is also made in the debridge forwarder contract
        if (!DE_BRIDGE_FORWARDER.supportedRouters(v.swapRouter)) {
            revert DeBridgeError.INVALID_SWAP_ROUTER();
        }

        /// bridge tx data shouldn't be empty
        if (v.bridgeTxData.length == 0 || v.bridgeTarget != DE_BRIDGE_SOURCE) {
            revert DeBridgeError.INVALID_BRIDGE_DATA();
        }

        _decodeBridgeData(v, deBridgeQuote);
    }

    /// @notice supports `createOrder` and `createSaltedOrder` for bridging using dln source
    function _decodeBridgeData(InternalVars memory v, DecodedQuote memory deBridgeQuote) internal view {
        /// now decoding the bridge data
        v.selector = _parseSelectorMem(v.bridgeTxData);

        if (v.selector == IDlnSource.createOrder.selector) {
            (v.xChainQuote,,, v.permitEnvelope) =
                abi.decode(this.parseCallData(v.bridgeTxData), (DlnOrderLib.OrderCreation, bytes, uint32, bytes));
        } else if (v.selector == IDlnSource.createSaltedOrder.selector) {
            (v.xChainQuote,,,, v.permitEnvelope,) = abi.decode(
                this.parseCallData(v.bridgeTxData), (DlnOrderLib.OrderCreation, uint64, bytes, uint32, bytes, bytes)
            );
        } else {
            revert Error.BLACKLISTED_ROUTE_ID();
        }

        if (v.swapOutputToken != v.xChainQuote.giveTokenAddress) {
            revert DeBridgeError.INVALID_BRIDGE_TOKEN();
        }

        if (v.permitEnvelope.length > 0) {
            revert DeBridgeError.INVALID_PERMIT_ENVELOP();
        }

        if (v.xChainQuote.externalCall.length > 0) {
            revert DeBridgeError.INVALID_EXTRA_CALL_DATA();
        }

        if (v.xChainQuote.allowedTakerDst.length > 0) {
            revert DeBridgeError.INVALID_TAKER_DST();
        }

        deBridgeQuote.outputToken = _castToAddress(v.xChainQuote.takeTokenAddress);
        deBridgeQuote.outputAmount = v.xChainQuote.takeAmount;
        deBridgeQuote.finalReceiver = _castToAddress(v.xChainQuote.receiverDst);
        deBridgeQuote.dstChainId = v.xChainQuote.takeChainId;
        deBridgeQuote.orderAuthorityAddressDst = _castToAddress(v.xChainQuote.orderAuthorityAddressDst);
        deBridgeQuote.bridgeRefundRecipient = _castToAddress(v.xChainQuote.allowedCancelBeneficiarySrc);
        deBridgeQuote.givePatchAuthoritySrc = v.xChainQuote.givePatchAuthoritySrc;

        if (deBridgeQuote.outputToken == address(0)) deBridgeQuote.outputToken = NATIVE;
        if (deBridgeQuote.inputToken == address(0)) deBridgeQuote.inputToken = NATIVE;
    }

    /// @dev helps parsing debridge calldata and return the input parameters
    function parseCallData(bytes calldata callData) public pure returns (bytes calldata) {
        return callData[4:];
    }

    /// @dev helps parse bytes memory selector
    function _parseSelectorMem(bytes memory data) internal pure returns (bytes4 selector) {
        assembly {
            selector := mload(add(data, 0x20))
        }
    }

    /// @dev helps cast bytes to address
    function _castToAddress(bytes memory address_) internal pure returns (address) {
        return address(uint160(bytes20(address_)));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { Error } from "src/libraries/Error.sol";
import { IQuote } from "src/vendor/hashflow/IQuote.sol";
import { IHashflowRouter } from "src/vendor/hashflow/IHashflowRouter.sol";

/// @title HashflowValidator
/// @dev Asserts if Hashflow input txData is valid
/// @author Zeropoint Labs
contract HashflowValidator is BridgeValidator {
    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) BridgeValidator(superRegistry_) { }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver) external pure override returns (bool) {
        (IQuote.XChainRFQTQuote memory hashflowQuote,,) = _decodeTxData(txData_);

        return (receiver == _castToAddress(hashflowQuote.dstTrader));
    }

    /// NOTE: check other parameters including: `srcExternalAccount`, `xChainMessenger `and `dstExternalAccount`
    /// @inheritdoc BridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external view override returns (bool hasDstSwap) {
        (IQuote.XChainRFQTQuote memory hashflowQuote, bytes32 dstContract, bytes memory dstCallData) =
            _decodeTxData(args_.txData);

        /// FIXME: add explicit revert messages
        if (dstContract != bytes32(0) || dstCallData.length > 0) revert();

        /// @dev 1. chain id calidation
        /// FIXME: check if this cast is right
        /// FIXME: check upstream if the srcChain in this context is the block.chainid
        if (
            uint64(hashflowQuote.dstChainId) != args_.liqDstChainId
                || uint64(hashflowQuote.srcChainId) != args_.srcChainId
                || args_.liqDataToken != _castToAddress(hashflowQuote.quoteToken)
        ) revert Error.INVALID_TXDATA_CHAIN_ID();

        /// @dev 2. receiver address validation
        /// @dev allows dst swaps by coupling hashflow with other bridges

        /// FIXME: check if this cast is right
        address receiver = _castToAddress(hashflowQuote.dstTrader);
        if (args_.deposit) {
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

            /// @dev if there is a dst swap then the interim token should be the quote of hashflow
            if (hasDstSwap && (args_.liqDataInterimToken != _castToAddress(hashflowQuote.quoteToken))) {
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
        (IQuote.XChainRFQTQuote memory xChainQuote,,) = _decodeTxData(txData_);
        amount_ = xChainQuote.baseTokenAmount;
    }

    /// @inheritdoc BridgeValidator
    function decodeDstSwap(bytes calldata /*txData_*/ )
        external
        pure
        override
        returns (address, /*token_*/ uint256 /*amount_*/ )
    {
        /// @dev hashflow cannot be used for just swaps
        revert Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN();
    }

    /// @inheritdoc BridgeValidator
    function decodeSwapOutputToken(bytes calldata /*txData_*/ ) external pure override returns (address /*token_*/ ) {
        /// @dev hashflow cannot be used for same chain swaps
        revert Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN();
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// NOTE: we should only allow the `tradeXChainRFQT` identifier
    function _decodeTxData(bytes calldata txData_)
        internal
        pure
        returns (IQuote.XChainRFQTQuote memory xChainQuote, bytes32 dstContract, bytes memory dstCallData)
    {
        /// FIXME: we support only one function identifier for now
        bytes4 selector = bytes4(txData_[:4]);
        if (selector != IHashflowRouter.tradeRFQT.selector) revert Error.BLACKLISTED_ROUTE_ID();

        (xChainQuote, dstContract, dstCallData) =
            abi.decode(_parseCallData(txData_), (IQuote.XChainRFQTQuote, bytes32, bytes));
    }

    /// @dev helps parsing hashflow calldata and return the input parameters
    function _parseCallData(bytes calldata callData) internal pure returns (bytes calldata) {
        return callData[4:];
    }

    /// @dev helps cast bytes32 to address
    function _castToAddress(bytes32 address_) internal pure returns (address) {
        /// FIXME: check if address(uint160(uint256(b))) could be true ??
        return address(uint160(bytes20(address_)));
    }
}

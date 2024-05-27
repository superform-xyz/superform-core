// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { Error } from "src/libraries/Error.sol";
import "src/vendor/1inch/IAggregationRouterV6.sol";

import "forge-std/console.sol";

/// @title OneInchValidator
/// @dev Asserts OneInch txData is valid
/// @author Zeropoint Labs

/// @notice this does not import BridgeValidator as decodeSwapOutpuToken cannot have `pure` as visibility identifier
contract OneInchValidator {
    using AddressLib for Address;
    using ProtocolLib for Address;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////
    ISuperRegistry public immutable superRegistry;

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) {
        if (superRegistry_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }
        superRegistry = ISuperRegistry(superRegistry_);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev validates the receiver of the liquidity request
    /// @param txData_ is the txData of the cross chain deposit
    /// @param receiver_ is the address of the receiver to validate
    /// @return valid_ if the address is valid
    function validateReceiver(bytes calldata txData_, address receiver_) external view returns (bool) {
        (,,, address decodedReceiver,) = _decodeTxData(txData_);
        console.log(decodedReceiver);
        return (receiver_ == decodedReceiver);
    }

    /// @dev validates the txData of a cross chain deposit
    /// @param args_ the txData arguments to validate in txData
    /// @return hasDstSwap if the txData contains a destination swap
    function validateTxData(IBridgeValidator.ValidateTxDataArgs calldata args_) external view returns (bool) {
        (address fromToken,,, address receiver,) = _decodeTxData(args_.txData);
        console.log(receiver);

        if (args_.deposit) {
            /// @dev 1. chain id validation (only allow samechain with this)
            if (args_.dstChainId != args_.srcChainId) revert Error.INVALID_TXDATA_CHAIN_ID();
            if (args_.dstChainId != args_.liqDstChainId) revert Error.INVALID_DEPOSIT_LIQ_DST_CHAIN_ID();

            /// @dev 2. receiver address validation
            /// @dev If same chain deposits then receiver address must be the superform
            if (receiver != args_.superform) revert Error.INVALID_TXDATA_RECEIVER();
        } else {
            /// @dev 2. receiver address validation
            /// @dev if withdraws, then receiver address must be the receiverAddress
            if (receiver != args_.receiverAddress) revert Error.INVALID_TXDATA_RECEIVER();
        }

        /// @dev 3. token validations
        if (args_.liqDataToken != fromToken) revert Error.INVALID_TXDATA_TOKEN();

        return false;
    }

    /// @dev decodes the txData and returns the amount of input token on source
    /// @param txData_ is the txData of the cross chain deposit
    /// @return amount_ the amount expected
    function decodeAmountIn(
        bytes calldata txData_,
        bool /*genericSwapDisallowed_*/
    )
        external
        pure
        returns (uint256 amount_)
    {
        (, amount_,,,) = _decodeTxData(txData_);
    }

    /// @dev decodes neccesary information for processing swaps on the destination chain
    /// @param txData_ is the txData to be decoded
    /// @return token_ is the address of the token
    /// @return amount_ the amount expected
    function decodeDstSwap(bytes calldata txData_) external pure returns (address token_, uint256 amount_) {
        (token_, amount_,,,) = _decodeTxData(txData_);
    }

    /// @dev decodes the final output token address (for only direct chain actions!)
    /// @param txData_ is the txData to be decoded
    /// @return token_ the address of the token
    function decodeSwapOutputToken(bytes calldata txData_) external view returns (address token_) {
        (address fromToken,, address toToken,, Address dex) = _decodeTxData(txData_);
        ProtocolLib.Protocol protocol = dex.protocol();

        if (toToken != address(0)) {
            token_ = toToken;
        } else {
            /// @dev if protocol is uniswap v2 or uniswap v3
            if (protocol == ProtocolLib.Protocol.UniswapV2 || protocol == ProtocolLib.Protocol.UniswapV3) {
                token_ = IUniswapV2Pair(dex.get()).token0();

                if (token_ == fromToken) {
                    token_ = IUniswapV2Pair(dex.get()).token1();
                }
            } else if (protocol == ProtocolLib.Protocol.Curve) {
                uint256 toTokenIndex = (Address.unwrap(dex) >> _CURVE_TO_COINS_ARG_OFFSET) & _CURVE_TO_COINS_ARG_MASK;
                token_ = ICurvePool(dex.get()).underlying_coins(int128(uint128(toTokenIndex)));
            }
        }
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev helps decode the 1inch user request
    /// returns useful parameters for validaiton
    function _decodeTxData(bytes calldata txData_)
        internal
        pure
        returns (address fromToken, uint256 fromAmount, address toToken, address receiver, Address dexAddress)
    {
        bytes4 selector = bytes4(txData_[:4]);

        /// @dev does not support any sequential pools with unoswap
        /// NOTE: support UNISWAP_V2, UNISWAP_V3, CURVE, SHIBASWAP
        if (selector == IAggregationRouterV6.unoswapTo.selector) {
            (Address receiverUint256, Address fromTokenUint256, uint256 decodedFromAmount,, Address dex) =
                abi.decode(_parseCallData(txData_), (Address, Address, uint256, uint256, Address));

            fromToken = fromTokenUint256.get();
            fromAmount = decodedFromAmount;
            receiver = receiverUint256.get();
            dexAddress = dex;
        }

        /// @dev decodes the clipperSwapTo selector
        if (selector == IAggregationRouterV6.clipperSwapTo.selector) {
            (, address decodedReceiver, Address fromTokenUint256, IERC20 decodedToToken, uint256 decodedFromAmount,,,,)
            = abi.decode(
                _parseCallData(txData_),
                (IClipperExchange, address, Address, IERC20, uint256, uint256, uint256, bytes32, bytes32)
            );

            fromToken = fromTokenUint256.get();
            fromAmount = decodedFromAmount;
            toToken = address(decodedToToken);
            receiver = decodedReceiver;
        }

        /// @dev decodes the generic router call
        if (selector == IAggregationRouterV6.swap.selector) {
            (, IAggregationRouterV6.SwapDescription memory swapDescription, bytes memory extCallData) =
                abi.decode(_parseCallData(txData_), (IAggregationExecutor, IAggregationRouterV6.SwapDescription, bytes));

            fromToken = address(swapDescription.srcToken);
            fromAmount = swapDescription.amount;
            toToken = address(swapDescription.dstToken);
            receiver = swapDescription.dstReceiver;
        }
    }

    /// @dev helps parse 1inch calldata
    function _parseCallData(bytes calldata callData_) internal pure returns (bytes calldata) {
        return callData_[4:];
    }
}

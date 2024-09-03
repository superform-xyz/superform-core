// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { Error } from "src/libraries/Error.sol";
import "src/vendor/1inch/IAggregationRouterV6.sol";

/// @title OneInchValidator
/// @dev Asserts OneInch txData is valid
/// @author Zeropoint Labs

/// @notice this does not import BridgeValidator as decodeSwapOutputToken cannot have `pure` as visibility identifier
contract OneInchValidator {
    using AddressLib for Address;
    using ProtocolLib for Address;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////
    ISuperRegistry public immutable superRegistry;
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    //////////////////////////////////////////////////////////////
    //                         ERROR                            //
    //////////////////////////////////////////////////////////////
    error INVALID_TOKEN_PAIR();
    error INVALID_PERMIT2_DATA();
    error PARTIAL_FILL_NOT_ALLOWED();

    //////////////////////////////////////////////////////////////
    //                        CONSTRUCTOR                       //
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
        (,,, address decodedReceiver) = _decodeTxData(txData_);
        return (receiver_ == decodedReceiver);
    }

    /// @dev validates the txData of a cross chain deposit
    /// @param args_ the txData arguments to validate in txData
    /// @return hasDstSwap if the txData contains a destination swap
    function validateTxData(IBridgeValidator.ValidateTxDataArgs calldata args_) external view returns (bool) {
        (address fromToken,,, address receiver) = _decodeTxData(args_.txData);

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
        view
        returns (uint256 amount_)
    {
        (, amount_,,) = _decodeTxData(txData_);
    }

    /// @dev decodes neccesary information for processing swaps on the destination chain
    /// @param txData_ is the txData to be decoded
    /// @return token_ is the address of the token
    /// @return amount_ the amount expected
    function decodeDstSwap(bytes calldata txData_) external view returns (address token_, uint256 amount_) {
        (token_, amount_,,) = _decodeTxData(txData_);
    }

    /// @dev decodes the final output token address (for only direct chain actions!)
    /// @param txData_ is the txData to be decoded
    /// @return token_ the address of the token
    function decodeSwapOutputToken(bytes calldata txData_) external view returns (address token_) {
        (,, token_,) = _decodeTxData(txData_);
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev helps decode the 1inch user request
    /// returns useful parameters for validaiton
    function _decodeTxData(bytes calldata txData_)
        internal
        view
        returns (address fromToken, uint256 fromAmount, address toToken, address receiver)
    {
        bytes4 selector = bytes4(txData_[:4]);

        /// @dev does not support any sequential pools with unoswap
        /// NOTE: support UNISWAP_V2, UNISWAP_V3, CURVE and all uniswap-based forks
        if (selector == IAggregationRouterV6.unoswapTo.selector) {
            (Address receiverUint256, Address fromTokenUint256, uint256 decodedFromAmount,, Address dex) =
                abi.decode(_parseCallData(txData_), (Address, Address, uint256, uint256, Address));

            if (dex.usePermit2()) {
                revert INVALID_PERMIT2_DATA();
            }

            fromToken = fromTokenUint256.get();
            fromAmount = decodedFromAmount;
            receiver = receiverUint256.get();

            ProtocolLib.Protocol protocol = dex.protocol();

            /// @dev if protocol is curve
            if (protocol == ProtocolLib.Protocol.Curve) {
                uint256 toTokenIndex = (Address.unwrap(dex) >> _CURVE_TO_COINS_ARG_OFFSET) & _CURVE_TO_COINS_ARG_MASK;
                toToken = ICurvePool(dex.get()).underlying_coins(int128(uint128(toTokenIndex)));
            }
            /// @dev if protocol is uniswap v2 or uniswap v3
            else {
                address token0 = IUniswapPair(dex.get()).token0();
                address token1 = IUniswapPair(dex.get()).token1();

                if (token0 == fromToken) {
                    toToken = token1;
                } else if (token1 == fromToken) {
                    toToken = token0;
                } else {
                    revert INVALID_TOKEN_PAIR();
                }
            }

            /// @dev remap of WETH to Native if unwrapWeth flag is true
            if (dex.shouldUnwrapWeth()) {
                toToken = NATIVE;
            }
        }
        /// @dev decodes the generic router call
        else if (selector == IAggregationRouterV6.swap.selector) {
            (, IAggregationRouterV6.SwapDescription memory swapDescription,) =
                abi.decode(_parseCallData(txData_), (IAggregationExecutor, IAggregationRouterV6.SwapDescription, bytes));

            fromToken = address(swapDescription.srcToken);
            fromAmount = swapDescription.amount;
            toToken = address(swapDescription.dstToken);
            receiver = swapDescription.dstReceiver;

            /// @dev validating the flags
            ///  @dev allows REQUIRES_EXTRA_ETH flag but blocks the USE_PERMIT2 & PARTIAL_FILL flags
            if (swapDescription.flags & _USE_PERMIT2 != 0) {
                revert INVALID_PERMIT2_DATA();
            }

            if (swapDescription.flags & _PARTIAL_FILL != 0) {
                revert PARTIAL_FILL_NOT_ALLOWED();
            }
        } else {
            /// @dev does not support clipper exchange
            revert Error.BLACKLISTED_SELECTOR();
        }
    }

    /// @dev helps parse 1inch calldata
    function _parseCallData(bytes calldata callData_) internal pure returns (bytes calldata) {
        return callData_[4:];
    }
}

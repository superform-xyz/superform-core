// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { Error } from "src/libraries/Error.sol";
import "src/vendor/1inch/IAggregationRouterV6.sol";

/// @title OneInchValidator
/// @dev Asserts OneInch txData is valid
/// @author Zeropoint Labs
contract OneInchValidator is BridgeValidator {
    using AddressLib for Address;
    using ProtocolLib for Address;

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) BridgeValidator(superRegistry_) { }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver_) external pure override returns (bool) {
        (,, address decodedReceiver,) = _decodeTxData(txData_);
        return (receiver_ == decodedReceiver);
    }

    /// @inheritdoc BridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external pure override returns (bool) { }

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
        (, amount_,,) = _decodeTxData(txData_);
    }

    /// @inheritdoc BridgeValidator
    function decodeDstSwap(bytes calldata txData_) external pure override returns (address token_, uint256 amount_) {
        (token_, amount_,,) = _decodeTxData(txData_);
    }

    /// @inheritdoc BridgeValidator
    function decodeSwapOutputToken(bytes calldata txData_) external view override returns (address token_) {
        (address fromToken,,, Address dex) = _decodeTxData(txData_);
        ProtocolLib.Protocol protocol = dex.protocol();

        /// @dev if protocol is uniswap v2
        if (protocol == ProtocolLib.Protocol.UniswapV2) {
            token_ = IUniswapV2Pair(dex.get()).token0();

            if (token_ == fromToken) {
                token_ = IUniswapV2Pair(dex.get()).token1();
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
        returns (address fromToken, uint256 fromAmount, address receiver, Address dexAddress)
    {
        bytes4 selector = bytes4(txData_[:4]);

        /// @dev does not support any sequential pools with unoswap
        if (selector == IAggregationRouterV6.unoswapTo.selector) {
            (Address receiverUint256, Address fromTokenUint256, uint256 decodedFromAmount,, Address dex) =
                abi.decode(_parseCallData(txData_), (Address, Address, uint256, uint256, Address));

            fromToken = fromTokenUint256.get();
            fromAmount = decodedFromAmount;
            receiver = receiverUint256.get();
            dexAddress = dex;
        }
    }

    /// @dev helps parse 1inch calldata
    function _parseCallData(bytes calldata callData_) internal pure returns (bytes calldata) {
        return callData_[4:];
    }
}

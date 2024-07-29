// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { Error } from "src/libraries/Error.sol";
import { ISocketOneInchImpl } from "src/vendor/socket/ISocketOneInchImpl.sol";

/// @title SocketOneInchValidator
/// @dev Asserts Socket same-chain txData is valid
/// @author Zeropoint Labs
contract SocketOneInchValidator is BridgeValidator {
    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) BridgeValidator(superRegistry_) { }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver) external pure override returns (bool) {
        return (receiver == _decodeTxData(txData_).receiver);
    }

    /// @inheritdoc BridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external pure override returns (bool) {
        ISocketOneInchImpl.SwapInput memory decodedReq = _decodeTxData(args_.txData);

        if (args_.deposit) {
            /// @dev 1. chain id validation (only allow samechain with this)
            if (args_.dstChainId != args_.srcChainId) revert Error.INVALID_TXDATA_CHAIN_ID();
            if (args_.dstChainId != args_.liqDstChainId) revert Error.INVALID_DEPOSIT_LIQ_DST_CHAIN_ID();

            /// @dev 2. receiver address validation
            /// @dev If same chain deposits then receiver address must be the superform
            if (decodedReq.receiver != args_.superform) revert Error.INVALID_TXDATA_RECEIVER();
        } else {
            /// @dev 2. receiver address validation
            /// @dev if withdraws, then receiver address must be the receiverAddress
            if (decodedReq.receiver != args_.receiverAddress) revert Error.INVALID_TXDATA_RECEIVER();
        }

        /// @dev 3. token validations
        if (args_.liqDataToken != decodedReq.fromToken) revert Error.INVALID_TXDATA_TOKEN();

        return false;
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
        amount_ = _decodeTxData(txData_).amount;
    }

    /// @inheritdoc BridgeValidator
    function decodeDstSwap(bytes calldata txData_) external pure override returns (address token_, uint256 amount_) {
        ISocketOneInchImpl.SwapInput memory swapInput = _decodeTxData(txData_);
        token_ = swapInput.fromToken;
        amount_ = swapInput.amount;
    }

    /// @inheritdoc BridgeValidator
    function decodeSwapOutputToken(bytes calldata txData_) external pure override returns (address token_) {
        ISocketOneInchImpl.SwapInput memory swapInput = _decodeTxData(txData_);
        token_ = swapInput.toToken;
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev helps decode socket user request
    /// returns the user request
    function _decodeTxData(bytes calldata txData_)
        internal
        pure
        returns (ISocketOneInchImpl.SwapInput memory swapInput)
    {
        (address fromToken, address toToken, address receiver, uint256 amount, bytes memory swapExtraData) =
            abi.decode(_parseCallData(txData_), (address, address, address, uint256, bytes));
        swapInput = ISocketOneInchImpl.SwapInput(fromToken, toToken, receiver, amount, swapExtraData);
    }

    /// @dev helps parsing socket calldata and return the socket request
    function _parseCallData(bytes calldata callData) internal pure returns (bytes calldata) {
        return callData[4:];
    }
}

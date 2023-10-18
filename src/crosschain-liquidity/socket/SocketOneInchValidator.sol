// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { Error } from "src/utils/Error.sol";

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { ISocketOneInchImpl } from "src/vendor/socket/ISocketOneInchImpl.sol";

/// @title SocketOneInchValidator
/// @author Zeropoint Labs
/// @dev to assert input txData is valid
contract SocketOneInchValidator is BridgeValidator {
    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address superRegistry_) BridgeValidator(superRegistry_) { }

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
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
        /// FIXME: come to this later
        revert();
    }

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver) external pure override returns (bool) {
        return (receiver == _decodeTxData(txData_).receiver);
    }

    /// @inheritdoc BridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external view override {
        ISocketOneInchImpl.SwapInput memory decodedReq = _decodeTxData(args_.txData);

        /// @dev 1. chain id validation (only allow samechain with this)
        if (args_.dstChainId != args_.srcChainId) revert Error.INVALID_ACTION();

        /// @dev 2. receiver address validation
        if (args_.deposit) {
            if (args_.dstChainId != args_.liqDstChainId) revert Error.INVALID_DEPOSIT_LIQ_DST_CHAIN_ID();

            /// @dev If same chain deposits then receiver address must be the superform
            if (decodedReq.receiver != args_.superform) revert Error.INVALID_TXDATA_RECEIVER();
        } else {
            /// @dev if withdraws, then receiver address must be the srcSender
            if (decodedReq.receiver != args_.srcSender) revert Error.INVALID_TXDATA_RECEIVER();
        }

        /// @dev FIXME: add  3. token validations
        if (args_.liqDataToken != decodedReq.fromToken) revert Error.INVALID_TXDATA_TOKEN();
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
    { }

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
        amount_ = _decodeTxData(txData_).amount;
    }

    /// @inheritdoc BridgeValidator
    function decodeDstSwap(bytes calldata txData_) external pure override returns (address token_, uint256 amount_) { }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev helps decode socket user request
    /// returns the user request
    function _decodeTxData(bytes calldata txData_)
        internal
        pure
        returns (ISocketOneInchImpl.SwapInput memory swapInput)
    {
        swapInput = abi.decode(_parseCallData(txData_), (ISocketOneInchImpl.SwapInput));
    }

    /// @dev helps parsing socket calldata and return the socket request
    function _parseCallData(bytes calldata callData) internal pure returns (bytes memory) {
        return callData[4:];
    }
}

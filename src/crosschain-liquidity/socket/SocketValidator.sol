// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { ISocketRegistry } from "src/vendor/socket/ISocketRegistry.sol";

/// @title SocketValidator
/// @author Zeropoint Labs
/// @dev to assert input txData is valid
contract SocketValidator is BridgeValidator {
    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////
    constructor(address superRegistry_) BridgeValidator(superRegistry_) { }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver) external pure override returns (bool) {
        return (receiver == _decodeTxData(txData_).receiverAddress);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc BridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external view override returns (bool hasDstSwap) {
        ISocketRegistry.UserRequest memory decodedReq = _decodeTxData(args_.txData);

        /// @dev 1. chain id validation (only allow xChain with this)
        if (decodedReq.toChainId != uint256(args_.liqDstChainId)) revert Error.INVALID_TXDATA_CHAIN_ID();

        /// @dev 2. receiver address validation
        if (args_.deposit) {
            if (args_.srcChainId == args_.dstChainId) {
                revert Error.INVALID_ACTION();
            } else {
                hasDstSwap = decodedReq.receiverAddress
                    == superRegistry.getAddressByChainId(keccak256("DST_SWAPPER"), args_.dstChainId);

                /// @dev if cross chain deposits, then receiver address must be CoreStateRegistry (or) Dst Swapper
                if (
                    !(
                        decodedReq.receiverAddress
                            == superRegistry.getAddressByChainId(keccak256("CORE_STATE_REGISTRY"), args_.dstChainId)
                            || hasDstSwap
                    )
                ) {
                    revert Error.INVALID_TXDATA_RECEIVER();
                }

                /// @dev forbid xChain deposits with destination swaps without interim token set (for user
                /// protection)
                if (hasDstSwap && args_.liqDataInterimToken == address(0)) {
                    revert Error.INVALID_INTERIM_TOKEN();
                }
            }
        } else {
            /// @dev if withdraws, then receiver address must be the srcSender
            if (decodedReq.receiverAddress != args_.srcSender) revert Error.INVALID_TXDATA_RECEIVER();
        }

        /// @dev FIXME: add  3. token validations
        if (
            (decodedReq.middlewareRequest.id == 0 && args_.liqDataToken != decodedReq.bridgeRequest.inputToken)
                || (decodedReq.middlewareRequest.id != 0 && args_.liqDataToken != decodedReq.middlewareRequest.inputToken)
        ) revert Error.INVALID_TXDATA_TOKEN();
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
    function decodeDstSwap(bytes calldata /*txData_*/ )
        external
        pure
        override
        returns (address, /*token_*/ uint256 /*amount_*/ )
    {
        revert();
    }

    function decodeSwapOutputToken(bytes calldata /*txData_*/ ) external pure override returns (address /*token_*/ ) {
        revert Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN();
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev helps decode socket user request
    /// returns the user request
    function _decodeTxData(bytes calldata txData_)
        internal
        pure
        returns (ISocketRegistry.UserRequest memory userRequest)
    {
        userRequest = abi.decode(_parseCallData(txData_), (ISocketRegistry.UserRequest));
    }

    /// @dev helps parsing socket calldata and return the socket request
    function _parseCallData(bytes calldata callData) internal pure returns (bytes memory) {
        return callData[4:];
    }
}

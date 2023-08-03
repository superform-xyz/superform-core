// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import {BridgeValidator} from "../BridgeValidator.sol";
import {ISocketRegistry} from "../../vendor/socket/ISocketRegistry.sol";
import {Error} from "../../utils/Error.sol";

/// @title Socket verification contract
/// @author Zeropoint Labs
/// @dev To assert input txData is valid
contract SocketValidator is BridgeValidator {
    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) BridgeValidator(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BridgeValidator
    function validateTxDataAmount(bytes calldata txData_, uint256 amount_) external pure override returns (bool) {
        return _decodeCallData(txData_).amount == amount_;
    }

    /// @inheritdoc BridgeValidator
    function validateTxData(
        bytes calldata txData_,
        uint64 srcChainId_,
        uint64 dstChainId_,
        bool deposit_,
        address superForm_,
        address srcSender_,
        address liqDataToken_
    ) external view override {
        ISocketRegistry.UserRequest memory userRequest = _decodeCallData(txData_);

        /// @dev 1. chainId validation
        if (uint256(dstChainId_) != userRequest.toChainId) revert Error.INVALID_TXDATA_CHAIN_ID();

        /// @dev 2. receiver address validation

        if (deposit_) {
            if (srcChainId_ == dstChainId_) {
                /// @dev If same chain deposits then receiver address must be the superform
                if (userRequest.receiverAddress != superForm_) revert Error.INVALID_TXDATA_RECEIVER();
            } else {
                /// @dev if cross chain deposits, then receiver address must be the token bank
                if (
                    !(userRequest.receiverAddress == superRegistry.coreStateRegistry() ||
                        userRequest.receiverAddress == superRegistry.multiTxProcessor())
                ) revert Error.INVALID_TXDATA_RECEIVER();
            }
        } else {
            /// @dev if withdraws, then receiver address must be the srcSender
            /// @dev what if SrcSender is a contract? can it be used to re-enter somewhere?
            /// https://linear.app/superform/issue/SUP-2024/reentrancy-vulnerability-prevent-crafting-arbitrary-txdata-to-reenter
            if (userRequest.receiverAddress != srcSender_) revert Error.INVALID_TXDATA_RECEIVER();
        }

        /// @dev 3. token validation
        if (
            (userRequest.middlewareRequest.id == 0 && liqDataToken_ != userRequest.bridgeRequest.inputToken) ||
            (userRequest.middlewareRequest.id != 0 && liqDataToken_ != userRequest.middlewareRequest.inputToken)
        ) revert Error.INVALID_TXDATA_TOKEN();
    }

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver_) external pure override returns (bool valid_) {
        ISocketRegistry.UserRequest memory userRequest = _decodeCallData(txData_);

        return userRequest.receiverAddress == receiver_;
    }

    /// @notice Decode the socket v2 calldata
    /// @param data Socket V2 outboundTransferTo call data
    /// @return userRequest socket UserRequest
    function _decodeCallData(
        bytes calldata data
    ) internal pure returns (ISocketRegistry.UserRequest memory userRequest) {
        (userRequest) = abi.decode(data[4:], (ISocketRegistry.UserRequest));
    }
}

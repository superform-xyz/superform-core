// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { ISocketRegistry } from "src/vendor/socket/ISocketRegistry.sol";

/// @title SocketValidator
/// @author Zeropoint Labs
/// @dev to assert input txData is valid
contract SocketValidator is BridgeValidator {
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
        return (uint256(liqDstChainId_) == _decodeTxData(txData_).toChainId);
    }

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver) external pure override returns (bool) {
        return (receiver == _decodeTxData(txData_).receiverAddress);
    }

    /// @inheritdoc BridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external view override { }

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
    { }

    /// @inheritdoc BridgeValidator
    function decodeDstSwap(bytes calldata txData_) external pure override returns (address token_, uint256 amount_) { }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev try to decode the txData_
    /// returns the user request
    function _decodeTxData(bytes calldata txData_)
        internal
        pure
        returns (ISocketRegistry.UserRequest memory userRequest)
    {
        userRequest = abi.decode(txData_[4:], (ISocketRegistry.UserRequest));
    }
}

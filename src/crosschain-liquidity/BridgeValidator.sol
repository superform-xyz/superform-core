// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { Error } from "src/libraries/Error.sol";

/// @title BridgeValidator
/// @dev Inherited by specific bridge handlers to verify the calldata being sent
/// @author Zeropoint Labs
abstract contract BridgeValidator is IBridgeValidator {
    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    ISuperRegistry public immutable superRegistry;
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

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

    /// @inheritdoc IBridgeValidator
    function validateReceiver(
        bytes calldata txData_,
        address receiver_
    )
        external
        view
        virtual
        override
        returns (bool valid_);

    /// @inheritdoc IBridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_)
        external
        view
        virtual
        override
        returns (bool hasDstSwap);

    /// @inheritdoc IBridgeValidator
    function decodeAmountIn(
        bytes calldata txData_,
        bool genericSwapDisallowed_
    )
        external
        view
        virtual
        override
        returns (uint256 amount_);

    /// @inheritdoc IBridgeValidator
    function decodeDstSwap(bytes calldata txData_)
        external
        pure
        virtual
        override
        returns (address token_, uint256 amount_);

    /// @inheritdoc IBridgeValidator
    function decodeSwapOutputToken(bytes calldata txData_)
        external
        view
        virtual
        override
        returns (address outputToken_);
}

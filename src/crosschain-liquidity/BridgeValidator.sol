// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";
import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";

/// @title BridgeValidator
/// @author Zeropoint Labs
/// @dev To be inherited by specific bridge handlers to verify the calldata being sent
abstract contract BridgeValidator is IBridgeValidator {
    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                         //
    //////////////////////////////////////////////////////////////
    ISuperRegistry public immutable superRegistry;
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) {
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
        pure
        virtual
        override
        returns (bool valid_);

    /// @inheritdoc IBridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external view virtual override;

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

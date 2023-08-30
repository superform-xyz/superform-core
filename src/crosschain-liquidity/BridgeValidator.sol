// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";
import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";
import { Error } from "../utils/Error.sol";

/// @title BridgeValidator
/// @author Zeropoint Labs
/// @dev To be inherited by specific bridge handlers to verify the calldata being sent
abstract contract BridgeValidator is IBridgeValidator {
    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public immutable superRegistry;

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBridgeValidator
    function validateTxDataAmount(
        bytes calldata txData_,
        uint256 amount_
    )
        external
        view
        virtual
        override
        returns (bool);

    /// @inheritdoc IBridgeValidator
    function validateTxData(
        bytes calldata txData_,
        uint64 srcChainId_,
        uint64 dstChainId_,
        uint64 liqDstChainId_,
        bool deposit_,
        address superform_,
        address srcSender_,
        address liqDataToken_
    )
        external
        view
        virtual
        override;

    /// @inheritdoc IBridgeValidator
    function validateReceiver(
        bytes calldata txData_,
        address _receiver
    )
        external
        pure
        virtual
        override
        returns (bool valid_);

    /// @inheritdoc IBridgeValidator
    function decodeAmount(bytes calldata txData_) external pure virtual override returns (uint256 amount_);
}

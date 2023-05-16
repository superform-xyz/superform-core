// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {MultiVaultsSFData, SingleVaultSFData} from "../types/DataTypes.sol";
import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {IBridgeValidator} from "../interfaces/IBridgeValidator.sol";
import {Error} from "../utils/Error.sol";

/// @title Bridge Handler abstract contract
/// @author Zeropoint Labs
/// @dev To be inherited by specific bridge handlers to verify the calldata being sent
abstract contract BridgeValidator is IBridgeValidator {
    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public immutable superRegistry;

    /*///////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyProtocolAdmin() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(
                msg.sender
            )
        ) revert Error.NOT_PROTOCOL_ADMIN();
        _;
    }

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
    ) external view virtual override returns (bool);

    /// @inheritdoc IBridgeValidator
    function validateTxData(
        bytes calldata txData_,
        uint16 srcChainId_,
        uint16 dstChainId_,
        bool deposit_,
        address superForm_,
        address srcSender_,
        address liqDataToken_
    ) external view virtual override;
}

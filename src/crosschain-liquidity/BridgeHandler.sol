// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {Error} from "../utils/Error.sol";
import "../utils/DataPacking.sol";

/// @title Bridge Handler abstract contract
/// @author Zeropoint Labs
/// @dev To be inherited by specific bridge handlers to verify and send the call
abstract contract BridgeHandler {
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

    constructor(ISuperRegistry superRegistry_) {
        superRegistry = superRegistry_;
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    function validateTxData(
        bytes memory txData,
        bytes memory expectedData
    ) external view virtual returns (bool);

    function performBridgeCall(
        address to,
        uint256 nativeAmount,
        bytes memory txData
    ) external virtual;
}

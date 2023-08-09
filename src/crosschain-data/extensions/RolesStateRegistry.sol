// SPDX-License-Identifer: Apache-2.0
pragma solidity 0.8.19;

import {Broadcaster} from "../utils/Broadcaster.sol";
import {ISuperRBAC} from "../../interfaces/ISuperRBAC.sol";
import {PayloadState} from "../../types/DataTypes.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {Error} from "../../utils/Error.sol";

/// @title RolesStateRegistry
/// @author Zeropoint Labs
/// @dev enables communication between SuperRBAC deployed on all supported networks
contract RolesStateRegistry is Broadcaster {
    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlySender() override {
        if (msg.sender != superRegistry.superRBAC()) revert Error.NOT_CORE_CONTRACTS();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(ISuperRegistry superRegistry_) Broadcaster(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function processPayload(
        uint256 payloadId_,
        bytes memory /// not useful here
    ) external payable virtual override onlyProcessor returns (bytes memory savedMessage, bytes memory returnMessage) {
        if (payloadId_ > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.PAYLOAD_ALREADY_PROCESSED();
        }

        payloadTracking[payloadId_] = PayloadState.PROCESSED;
        // ISuperRBAC(superRegistry.superRBAC()).stateSync(payloadBody[payloadId_]);
    }
}
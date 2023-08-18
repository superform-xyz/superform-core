// SPDX-License-Identifer: Apache-2.0
pragma solidity 0.8.19;

import {Broadcaster} from "../utils/Broadcaster.sol";
import {ISuperformFactory} from "../../interfaces/ISuperformFactory.sol";
import {PayloadState} from "../../types/DataTypes.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {Error} from "../../utils/Error.sol";
import {ISuperRBAC} from "../../interfaces/ISuperRBAC.sol";

/// @title FactoryStateRegistry
/// @author Zeropoint Labs
/// @dev enables communication between SuperformFactory deployed on all supported networks
contract FactoryStateRegistry is Broadcaster {
    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyFactoryStateRegistryProcessor() {
        if (
            !ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasFactoryStateRegistryProcessorRole(
                msg.sender
            )
        ) revert Error.NOT_PROCESSOR();
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
    ) external payable virtual override onlyFactoryStateRegistryProcessor returns (bytes memory, bytes memory) {
        if (payloadId_ > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.PAYLOAD_ALREADY_PROCESSED();
        }

        payloadTracking[payloadId_] = PayloadState.PROCESSED;
        ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).stateSync(payloadBody[payloadId_]);
    }
}

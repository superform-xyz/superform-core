// SPDX-License-Identifer: Apache-2.0
pragma solidity 0.8.19;

import {Broadcaster} from "../utils/Broadcaster.sol";
import {ISuperformFactory} from "../../interfaces/ISuperformFactory.sol";
import {IFactoryStateRegistry} from "../../interfaces/IFactoryStateRegistry.sol";
import {PayloadState} from "../../types/DataTypes.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {Error} from "../../utils/Error.sol";

/// @title FactoryStateRegistry
/// @author Zeropoint Labs
/// @dev enables communication between SuperformFactory deployed on all supported networks
contract FactoryStateRegistry is Broadcaster, IFactoryStateRegistry {
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
    ) external payable virtual override onlyProcessor returns (bytes memory, bytes memory) {
        if (payloadId_ > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.PAYLOAD_ALREADY_PROCESSED();
        }

        payloadTracking[payloadId_] = PayloadState.PROCESSED;
        ISuperformFactory(superRegistry.getAddress(superRegistry.SUPERFORM_FACTORY())).stateSync(
            payloadBody[payloadId_]
        );
    }
}

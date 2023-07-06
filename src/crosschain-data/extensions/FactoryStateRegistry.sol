// SPDX-License-Identifer: Apache-2.0
pragma solidity 0.8.19;

import {Broadcaster} from "../utils/Broadcaster.sol";
import {ISuperFormFactory} from "../../interfaces/ISuperFormFactory.sol";
import {IFactoryStateRegistry} from "../../interfaces/IFactoryStateRegistry.sol";
import {PayloadState} from "../../types/DataTypes.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {Error} from "../../utils/Error.sol";

/// @title FactoryStateRegistry
/// @author Zeropoint Labs
/// @dev enables communication between SuperFormFactory deployed on all supported networks
contract FactoryStateRegistry is Broadcaster, IFactoryStateRegistry {
    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlySender() override {
        if (msg.sender != superRegistry.superFormFactory()) revert Error.NOT_CORE_CONTRACTS();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(ISuperRegistry superRegistry_, uint8 registryType_) Broadcaster(superRegistry_, registryType_) {}

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function processPayload(
        uint256 payloadId_,
        bytes memory /// not useful here
    ) external payable virtual override onlyProcessor returns (bytes memory) {
        if (payloadId_ > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.INVALID_PAYLOAD_STATE();
        }

        payloadTracking[payloadId_] = PayloadState.PROCESSED;
        ISuperFormFactory(superRegistry.superFormFactory()).stateSync(payloadBody[payloadId_]);
    }
}

// SPDX-License-Identifer: Apache-2.0
pragma solidity 0.8.19;

import {BaseStateRegistry} from "./BaseStateRegistry.sol";
import {ISuperFormFactory} from "../interfaces/ISuperFormFactory.sol";
import {IFactoryStateRegistry} from "../interfaces/IFactoryStateRegistry.sol";
import {PayloadState} from "../types/DataTypes.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {Error} from "../utils/Error.sol";

contract FactoryStateRegistry is BaseStateRegistry, IFactoryStateRegistry {
    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    ///@dev set up admin during deployment.
    constructor(
        uint16 chainId_,
        ISuperRegistry superRegistry_
    ) BaseStateRegistry(chainId_, superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev allows accounts with {PROCESSOR_ROLE} to process any successful cross-chain payload.
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// NOTE: function can only process successful payloads.
    function processPayload(
        uint256 payloadId_,
        bytes memory /// not useful here
    ) external payable virtual override onlyProcessor {
        /// TODO sync factory data from crosschain
        if (payloadId_ > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.INVALID_PAYLOAD_STATE();
        }

        payloadTracking[payloadId_] = PayloadState.PROCESSED;
        ISuperFormFactory(superRegistry.superFormFactory()).stateSync(
            payload[payloadId_]
        );
    }
}

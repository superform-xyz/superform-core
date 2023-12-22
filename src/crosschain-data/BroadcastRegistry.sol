// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import { IBroadcastRegistry } from "src/interfaces/IBroadcastRegistry.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { BroadcastMessage, PayloadState } from "src/types/DataTypes.sol";
import { IBroadcastAmbImplementation } from "src/interfaces/IBroadcastAmbImplementation.sol";
import { ProofLib } from "../libraries/ProofLib.sol";

interface Target {
    function stateSyncBroadcast(bytes memory data_) external;
}

/// @title BroadcastRegistry
/// @author ZeroPoint Labs
/// @notice helps core contract communicate with multiple dst chains through supported AMBs
contract BroadcastRegistry is IBroadcastRegistry {
    using ProofLib for bytes;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                         //
    //////////////////////////////////////////////////////////////

    ISuperRegistry public immutable superRegistry;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    uint256 public payloadsCount;

    /// @dev stores the received payload after assigning
    mapping(uint256 => bytes) public payload;

    /// @dev stores the src chain of every payload
    mapping(uint256 => uint64) public srcChainId;

    /// @dev stores the status of the received payload
    mapping(uint256 => PayloadState) public payloadTracking;

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    /// @dev set up admin during deployment.
    constructor(ISuperRegistry superRegistry_) {
        superRegistry = superRegistry_;
    }

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    /// @notice sender should be a valid configured contract
    /// @dev should be factory or roles contract
    modifier onlySender() {
        if (
            !ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasRole(
                keccak256("BROADCASTER_ROLE"), msg.sender
            )
        ) {
            revert Error.NOT_ALLOWED_BROADCASTER();
        }
        _;
    }

    modifier onlyProcessor() {
        bytes32 role = keccak256("BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE");
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasRole(role, msg.sender)) {
            revert Error.NOT_PRIVILEGED_CALLER(role);
        }
        _;
    }

    modifier onlyBroadcasterAMBImplementation() {
        if (!superRegistry.isValidBroadcastAmbImpl(msg.sender)) {
            revert Error.NOT_BROADCAST_AMB_IMPLEMENTATION();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IBroadcastRegistry
    function broadcastPayload(
        address srcSender_,
        uint8 ambId_,
        uint256 gasFee_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        payable
        override
        onlySender
    {
        _broadcastPayload(srcSender_, ambId_, gasFee_, message_, extraData_);

        /// @dev refunds any overpaid msg.value
        uint256 refundAmt = msg.value - gasFee_;
        if (refundAmt > 0) {
            (bool success,) = payable(srcSender_).call{ value: refundAmt }("");

            if (!success) {
                revert Error.FAILED_TO_SEND_NATIVE();
            }
        }
    }

    /// @inheritdoc IBroadcastRegistry
    function receiveBroadcastPayload(
        uint64 srcChainId_,
        bytes memory message_
    )
        external
        override
        onlyBroadcasterAMBImplementation
    {
        ++payloadsCount;

        payload[payloadsCount] = message_;
        srcChainId[payloadsCount] = srcChainId_;
    }

    /// @inheritdoc IBroadcastRegistry
    function processPayload(uint256 payloadId) external override onlyProcessor {
        if (payloadId > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        if (payloadTracking[payloadId] != PayloadState.STORED) {
            revert Error.PAYLOAD_ALREADY_PROCESSED();
        }

        bytes memory payload_ = payload[payloadId];

        BroadcastMessage memory data = abi.decode(payload_, (BroadcastMessage));
        bytes32 targetId = keccak256(data.target);

        payloadTracking[payloadId] = PayloadState.PROCESSED;
        Target(superRegistry.getAddress(targetId)).stateSyncBroadcast(payload_);
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev broadcasts the payload(message_) through individual message bridge implementations
    function _broadcastPayload(
        address srcSender_,
        uint8 ambId_,
        uint256 gasFee_,
        bytes memory message_,
        bytes memory extraData_
    )
        internal
    {
        IBroadcastAmbImplementation(superRegistry.getAmbAddress(ambId_)).broadcastPayload{ value: gasFee_ }(
            srcSender_, message_, extraData_
        );
    }
}

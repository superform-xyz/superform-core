// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { QuorumManager } from "./utils/QuorumMAnager.sol";
import { Error } from "src/utils/Error.sol";
import { IBroadcastRegistry } from "src/interfaces/IBroadcastRegistry.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { IQuorumManager } from "src/interfaces/IQuorumManager.sol";
import { BroadcastMessage, AMBExtraData, PayloadState } from "src/types/DataTypes.sol";
import { IBroadcastAmbImplementation } from "src/interfaces/IBroadcastAmbImplementation.sol";
import { DataLib } from "src/libraries/DataLib.sol";

interface Target {
    function stateSync(bytes memory data_) external;
}

/// @title BaseStateRegistry
/// @author ZeroPoint Labs
/// @notice helps core contract communicate with multiple dst chains through supported AMBs
contract BroadcastRegistry is IBroadcastRegistry, QuorumManager {
    /*///////////////////////////////////////////////////////////////
                              STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public superRegistry;

    uint256 public payloadsCount;

    /// @dev stores the message quorum
    mapping(bytes32 => uint256) public messageQuorum;

    /// @dev stores the received payload after assigning
    mapping(uint256 => bytes) public payload;

    /// @dev stores the src chain of every payload
    mapping(uint256 => uint64) public srcChainId;

    /// @dev stores the status of the received payload
    mapping(uint256 => PayloadState) public payloadTracking;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev set up admin during deployment.
    constructor(ISuperRegistry superRegistry_) {
        superRegistry = superRegistry_;
    }

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice sender should be a valid configured contract
    /// @dev should be factory or roles contract
    modifier onlySender() {
        if (
            msg.sender != superRegistry.getAddress(keccak256("SUPER_RBAC"))
                && msg.sender != superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))
        ) {
            revert Error.NOT_ALLOWED_BROADCASTER();
        }
        _;
    }

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    /// @inheritdoc QuorumManager
    function setRequiredMessagingQuorum(uint64 srcChainId_, uint256 quorum_) external override onlyProtocolAdmin {
        requiredQuorum[srcChainId_] = quorum_;

        emit QuorumSet(srcChainId_, quorum_);
    }

    /// @inheritdoc IBroadcastRegistry
    function broadcastPayload(
        address srcSender_,
        uint8[] memory ambIds_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        payable
        override
        onlySender
    {
        AMBExtraData memory d = abi.decode(extraData_, (AMBExtraData));

        _broadcastPayload(srcSender_, ambIds_[0], d.gasPerAMB[0], message_, d.extraDataPerAMB[0]);

        if (ambIds_.length > 1) {
            _broadcastProof(srcSender_, ambIds_, d.gasPerAMB, message_, d.extraDataPerAMB);
        }
    }

    /// @inheritdoc IBroadcastRegistry
    function receiveBroadcastPayload(uint64 srcChainId_, bytes memory message_) external override {
        /// FIXME: add sender validations
        if (message_.length == 32) {
            ++messageQuorum[abi.decode(message_, (bytes32))];
        } else {
            ++payloadsCount;

            payload[payloadsCount] = message_;
            srcChainId[payloadsCount] = srcChainId_;
        }
    }

    /// @inheritdoc IBroadcastRegistry
    function processPayload(uint256 payloadId) external override {
        if (payloadId > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        if (payloadTracking[payloadId] != PayloadState.STORED) {
            revert Error.PAYLOAD_ALREADY_PROCESSED();
        }

        bytes memory payload_ = payload[payloadId];

        /// @dev The number of valid proofs (quorum) must be equal to the required messaging quorum
        if (messageQuorum[keccak256(payload_)] < getRequiredMessagingQuorum(srcChainId[payloadId])) {
            revert Error.QUORUM_NOT_REACHED();
        }

        BroadcastMessage memory data = abi.decode(payload_, (BroadcastMessage));
        bytes32 targetId = keccak256(data.target);

        payloadTracking[payloadId] = PayloadState.PROCESSED;
        Target(superRegistry.getAddress(targetId)).stateSync(payload_);
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev broadcasts the payload(message_) through individual message bridge implementations
    function _broadcastPayload(
        address srcSender_,
        uint8 ambId_,
        uint256 gasToPay_,
        bytes memory message_,
        bytes memory extraData_
    )
        internal
    {
        IBroadcastAmbImplementation ambImplementation = IBroadcastAmbImplementation(superRegistry.getAmbAddress(ambId_));

        /// @dev reverts if an unknown amb id is used
        if (address(ambImplementation) == address(0)) {
            revert Error.INVALID_BRIDGE_ID();
        }

        ambImplementation.broadcastPayload{ value: gasToPay_ }(srcSender_, message_, extraData_);
    }

    /// @dev broadcasts the proof(hash of the message_) through individual message bridge implementations
    function _broadcastProof(
        address srcSender_,
        uint8[] memory ambIds_,
        uint256[] memory gasToPay_,
        bytes memory message_,
        bytes[] memory extraData_
    )
        internal
    {
        for (uint8 i = 1; i < ambIds_.length;) {
            uint8 tempAmbId = ambIds_[i];

            /// @dev the loaded ambId cannot be the same as the ambId used for messaging
            if (tempAmbId == ambIds_[0]) {
                revert Error.INVALID_PROOF_BRIDGE_ID();
            }

            IBroadcastAmbImplementation tempImpl = IBroadcastAmbImplementation(superRegistry.getAmbAddress(tempAmbId));

            if (address(tempImpl) == address(0)) {
                revert Error.INVALID_BRIDGE_ID();
            }

            tempImpl.broadcastPayload{ value: gasToPay_[i] }(srcSender_, abi.encode(keccak256(message_)), extraData_[i]);

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "../types/DataTypes.sol";

/// @title IBaseStateRegistry
/// @author ZeroPoint Labs
/// @dev Is the crosschain interaction point. Send, store & process crosschain messages
interface IBaseStateRegistry {

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when a cross-chain payload is received in the state registry
    event PayloadReceived(uint64 srcChainId, uint64 dstChainId, uint256 payloadId);

    /// @dev is emitted when a cross-chain proof is received in the state registry
    /// NOTE: comes handy if quorum required is more than 0
    event ProofReceived(bytes proof);

    /// @dev is emitted when a payload id gets updated
    event PayloadUpdated(uint256 payloadId);

    /// @dev is emitted when a payload id gets processed
    event PayloadProcessed(uint256 payloadId);

    /// @dev is emitted when the super registry address is updated
    event SuperRegistryUpdated(address indexed superRegistry);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev allows users to read the total payloads received by the registry
    function payloadsCount() external view returns (uint256);

    /// @dev allows user to read the payload state
    /// uint256 payloadId_ is the unique payload identifier allocated on the destination chain
    function payloadTracking(uint256 payloadId_) external view returns (PayloadState payloadState_);

    /// @dev allows users to read the bytes payload_ stored per payloadId_
    /// @param payloadId_ is the unique payload identifier allocated on the destination chain
    /// @return payloadBody_ the crosschain data received
    function payloadBody(uint256 payloadId_) external view returns (bytes memory payloadBody_);

    /// @dev allows users to read the uint256 payloadHeader stored per payloadId_
    /// @param payloadId_ is the unique payload identifier allocated on the destination chain
    /// @return payloadHeader_ the crosschain header received
    function payloadHeader(uint256 payloadId_) external view returns (uint256 payloadHeader_);

    /// @dev allows users to read the ambs that delivered the payload id
    /// @param payloadId_ is the unique payload identifier allocated on the destination chain
    /// @return ambIds_ is the identifier of ambs that delivered the message and proof
    function getMessageAMB(uint256 payloadId_) external view returns (uint8[] memory ambIds_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev allows core contracts to send payload to a destination chain.
    /// @param srcSender_ is the caller of the function (used for gas refunds).
    /// @param ambIds_ is the identifier of the arbitrary message bridge to be used
    /// @param dstChainId_ is the internal chainId used throughout the protocol
    /// @param message_ is the crosschain payload to be sent
    /// @param extraData_ defines all the message bridge related overrides
    /// NOTE: dstChainId_ is mapped to message bridge's destination id inside it's implementation contract
    /// NOTE: ambIds_ are superform assigned unique identifier for arbitrary message bridges
    function dispatchPayload(
        address srcSender_,
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        payable;

    /// @dev allows state registry to receive messages from message bridge implementations
    /// @param srcChainId_ is the superform chainId from which the payload is dispatched/sent
    /// @param message_ is the crosschain payload received
    /// NOTE: Only {IMPLEMENTATION_CONTRACT} role can call this function.
    function receivePayload(uint64 srcChainId_, bytes memory message_) external;

    /// @dev allows privileged actors to process cross-chain payloads
    /// @param payloadId_ is the identifier of the cross-chain payload
    /// NOTE: Only {CORE_STATE_REGISTRY_PROCESSOR_ROLE} role can call this function
    /// NOTE: this should handle reverting the state on source chain in-case of failure
    /// (or) can implement scenario based reverting like in coreStateRegistry
    function processPayload(uint256 payloadId_) external payable;
}
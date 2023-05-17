// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title IBaseStateRegistry
/// @author ZeroPoint Labs
/// @dev is the crosschain interaction point. send, store & process Crosschain messages
interface IBaseStateRegistry {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    /// @dev is emitted when a cross-chain payload is received in the state registry
    event PayloadReceived(
        uint16 srcChainId,
        uint16 dstChainId,
        uint256 payloadId
    );

    /// @dev is emitted when a cross-chain proof is received in the state registry
    /// NOTE: comes handy if quorum required is more than 0
    event ProofReceived(bytes proof);

    /// @dev is emitted when a payload id gets updated
    event PayloadUpdated(uint256 payloadId);

    /// @dev is emitted when a payload id gets processed
    event PayloadProcessed(uint256 payloadId);

    /// @dev is emitted when the super registry address is updated
    event SuperRegistryUpdated(address indexed superRegistry);

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev allows core contracts to send payload to a destination chain.
    /// @param ambIds_ is the identifier of the arbitrary message bridge to be used
    /// @param dstChainId_ is the internal chainId used throughtout the protocol
    /// @param message_ is the crosschain payload to be sent
    /// @param extraData_ defines all the message bridge realted overrides
    /// NOTE: dstChainId_ is mapped to message bridge's destination id inside it's implementation contract
    /// NOTE: ambIds_ are superform assigned unique identifier for arbitrary message bridges
    function dispatchPayload(
        uint8[] memory ambIds_,
        uint16 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable;

    /// @dev allows core contracts to send payload to all configured destination chain.
    /// @param ambIds_ is the identifier of the arbitrary message bridge to be used
    /// @param message_ is the crosschain payload to be broadcasted
    /// @param extraData_ defines all the message bridge realted overrides
    function broadcastPayload(
        uint8[] memory ambIds_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable;

    /// @dev allows state registry to receive messages from message bridge implementations
    /// @param srcChainId_ is the superform chainId from which the payload is dispatched/sent
    /// @param message_ is the crosschain payload received
    /// NOTE: Only {IMPLEMENTATION_CONTRACT} role can call this function.
    function receivePayload(uint16 srcChainId_, bytes memory message_) external;

    /// @dev allows previlaged actors to process cross-chain payloads
    /// @param payloadId_ is the identifier of the cross-chain payload
    /// @param ambOverride_ is the message bridge configuration override when an acknowledgement to source chain is needed
    /// NOTE: Only {PROCESSOR_ROLE} role can call this function
    /// NOTE: sending `0x` in ambOverride_ will trigger no acknowledgement
    function processPayload(
        uint256 payloadId_,
        bytes memory ambOverride_
    ) external payable;

    /// @dev allows previlaged actors to revert cross-chain payloads to revert state changes on source chain
    /// @param payloadId_ is the identifier of the cross-chain payload
    /// @param ambId_ is the identifier of the cross-chain message bridge
    /// @param extraData_ defines all the message bridge realted overrides
    /// NOTE: Only {PROCESSOR_ROLE} role can call this function
    function revertPayload(
        uint256 payloadId_,
        uint256 ambId_,
        bytes memory extraData_
    ) external payable;
}

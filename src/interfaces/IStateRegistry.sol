// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title IStateRegistry
/// @author ZeroPoint Labs
/// @dev stores, updates & process cross-chain payloads
interface IStateRegistry {
    /*///////////////////////////////////////////////////////////////
                                Errors
    //////////////////////////////////////////////////////////////*/
    error INVALID_BRIDGE_ID();

    error INVALID_BRIDGE_ADDRESS();

    error INVALID_PAYLOAD_ID();

    error INVALID_PAYLOAD_STATE();

    error INVALID_PAYLOAD_UPDATE_REQUEST();

    error INVALID_ARR_LENGTH();

    error NEGATIVE_SLIPPAGE();

    error SLIPPAGE_OUT_OF_BOUNDS();

    error PAYLOAD_NOT_UPDATED();

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    /// @dev is emitted when a new cross-chain bridge is configured.
    event BridgeConfigured(uint8 bridgeId, address indexed bridgeImplAddress);

    /// @dev is emitted when a cross-chain payload is received in the state registry.
    event PayloadReceived(
        uint256 srcChainId,
        uint256 dstChainId,
        uint256 payloadId
    );

    /// @dev is emitted when a payload gets updated.
    event PayloadUpdated(uint256 payloadId);

    /// @dev is emitted when a payload gets processed.
    event PayloadProcessed(uint256 payloadId);

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev allows admin to update bridge implementations.
    /// @param bridgeId_ is the propreitory bridge id.
    /// @param bridgeImpl_ is the implementation address.
    function configureBridge(uint8 bridgeId_, address bridgeImpl_) external;

    /// @dev allows core contracts to send data to a destination chain.
    /// @param bridgeId_ is the identifier of the message bridge to be used.
    /// @param dstChainId_ is the internal chainId used throughtout the protocol.
    /// @param message_ is the crosschain data to be sent.
    /// @param extraData_ defines all the message bridge specific information.
    /// NOTE: dstChainId maps with the message bridge's propreitory chain Id.
    function dispatchPayload(
        uint8 bridgeId_,
        uint256 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable;

    /// @dev allows state registry to receive messages from bridge implementations.
    /// NOTE: Only {IMPLEMENTATION_CONTRACT} role can call this function.
    /// @param srcChainId_ is the internal chainId from which the data is sent.
    /// @param message_ is the crosschain data received.
    function receivePayload(uint256 srcChainId_, bytes memory message_)
        external;

    /// @dev allows accounts with {UPDATER_ROLE} to modify a received cross-chain payload.
    /// @param payloadId_ is the identifier of the cross-chain payload to be updated.
    /// @param finalAmounts_ is the amount to be updated.
    /// NOTE: amounts cannot be updated beyond user specified safe slippage limit.
    function updatePayload(uint256 payloadId_, uint256[] calldata finalAmounts_)
        external;

    /// @dev allows accounts with {PROCESSOR_ROLE} to process any successful cross-chain payload.
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// NOTE: function can only process successful payloads.
    function processPayload(uint256 payloadId_) external payable;

    /// @dev allows accounts with {PROCESSOR_ROLE} to revert payload that fail to revert state changes on source chain.
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @param bridgeId_ is the identifier of the cross-chain bridge to be used to send the acknowledgement.
    /// @param extraData_ is any message bridge specific override information.
    /// NOTE: function can only process failing payloads.
    function revertPayload(
        uint256 payloadId_,
        uint256 bridgeId_,
        bytes memory extraData_
    ) external payable;
}

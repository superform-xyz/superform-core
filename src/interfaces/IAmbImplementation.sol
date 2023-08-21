// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title IAmbImplementation
/// @author ZeroPoint Labs
/// @dev interface for arbitrary message bridge implementation
interface IAmbImplementation {
    /*///////////////////////////////////////////////////////////////
                    Events
    //////////////////////////////////////////////////////////////*/
    event ChainAdded(uint64 superChainId);

    /*///////////////////////////////////////////////////////////////
                    External Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev allows state registry to send message via implementation.
    /// @param srcSender_ is the caller (used for gas refunds)
    /// @param dstChainId_ is the identifier of the destination chain
    /// @param message_ is the cross-chain message to be sent
    /// @param extraData_ is message amb specific override information
    function dispatchPayload(
        address srcSender_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable;

    /// @dev allows state registry to send multiple messages via implementation
    /// @param srcSender_ is the caller (used for gas refunds)
    /// @param dstChainIds_ is the identifiers of destination chains
    /// @param message_ is the cross-chain message to be sent
    /// @param extraData_ is the message amb specific override information
    function broadcastPayload(
        address srcSender_,
        uint64[] memory dstChainIds_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable;

    /*///////////////////////////////////////////////////////////////
                    View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the gas fees estimation in native tokens
    /// @notice not all AMBs will have on-chain estimation for which this function will return 0
    /// @param dstChainId_ is the identifier of the destination chain
    /// @param message_ is the cross-chain message
    /// @param extraData_ is any amb-specific information
    /// @return fees is the native_tokens to be sent along the transaction
    function estimateFees(
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) external view returns (uint256 fees);
}

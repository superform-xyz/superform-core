// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title IAmbImplementation
/// @author ZeroPoint Labs
/// @dev interface for arbitrary message bridge implementation
interface IAmbImplementation {
    /*///////////////////////////////////////////////////////////////
                    Events
    //////////////////////////////////////////////////////////////*/
    event ChainAdded(uint16 superChainId);

    /*///////////////////////////////////////////////////////////////
                    External Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev allows state registry to send message via implementation.
    /// @param dstChainId_ is the identifier of the destination chain
    /// @param message_ is the cross-chain message to be sent
    /// @param extraData_ is message amb specific override information
    function dispatchPayload(uint16 dstChainId_, bytes memory message_, bytes memory extraData_) external payable;

    /// @dev allows state registry to send multiple messages via implementation
    /// @param message_ is the cross-chain message to be sent
    /// @param extraData_ is the message amb specific override information
    function broadcastPayload(bytes memory message_, bytes memory extraData_) external payable;
}

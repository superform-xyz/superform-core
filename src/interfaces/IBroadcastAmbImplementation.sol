// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

/// @title IBroadcastAmbImplementation
/// @author ZeroPoint Labs
/// @dev interface for arbitrary message bridge implementation the supports broadcasting
interface IBroadcastAmbImplementation {
    /*///////////////////////////////////////////////////////////////
                    Events
    //////////////////////////////////////////////////////////////*/
    event ChainAdded(uint64 superChainId);
    event AuthorizedImplAdded(uint64 superChainId, address authImpl);

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev allows state registry to send messages to multiple dst chains
    /// @param srcSender_ is the caller (used for gas refunds)
    /// @param message_ is the cross-chain message to be broadcasted
    /// @param extraData_ is optional broadcast override information
    function broadcastPayload(address srcSender_, bytes memory message_, bytes memory extraData_) external payable;

    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the gas fees estimation in native tokens
    /// @param message_ is the cross-chain message to be broadcasted
    /// @param extraData_  is optional broadcast override information
    /// @return fees is the native_tokens to be sent along the transaction
    /// @notice estimation differs for different message bridges.
    function estimateFees(bytes memory message_, bytes memory extraData_) external view returns (uint256 fees);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title IAmbImplementation
/// @dev Interface for arbitrary message bridge (AMB) implementations
/// @author ZeroPoint Labs
interface IAmbImplementation {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    event ChainAdded(uint64 indexed superChainId);
    event AuthorizedImplAdded(uint64 indexed superChainId, address indexed authImpl);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

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
    )
        external
        view
        returns (uint256 fees);

    /// @dev returns the extra data for the given gas request
    /// @param gasLimit is the amount of gas limit in wei to override
    /// @return extraData is the bytes encoded extra data
    /// NOTE: this process is unique to the message bridge
    function generateExtraData(uint256 gasLimit) external pure returns (bytes memory extraData);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

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
    )
        external
        payable;

    /// @dev allows for the permissionless calling of the retry mechanism for encoded data
    /// @param data_ is the encoded retry data (different per AMB implementation)
    function retryPayload(bytes memory data_) external payable;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title IFormStateRegistry
/// @author ZeroPoint Labs
/// @notice Interface for Form State Registry
interface IFormStateRegistry {
    /// @notice Receives request (payload) from TimelockForm to process later
    /// @param payloadId is constructed on TimelockForm, data is mapped also there, we only store pointer here
    /// @param superFormId is the id of TimelockForm sending this payloadId
    function receivePayload(uint256 payloadId, uint256 superFormId, address owner) external;

    /// @notice Form Keeper finalizes payload to process Timelock withdraw fully
    /// @param payloadId is the id of the payload to finalize
    /// @param ackExtraData_ is the AMBMessage data to send back to the source stateSync with request to re-mint SuperPositions
    function finalizePayload(uint256 payloadId, bytes memory ackExtraData_) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title ITwoStepsFormStateRegistry
/// @author ZeroPoint Labs
/// @notice Interface for Form State Registry
interface ITwoStepsFormStateRegistry {
    /// @notice Receives request (payload) from TimelockForm to process later
    /// @param payloadId is constructed on TimelockForm, data is mapped also there, we only store pointer here
    /// @param index is the index of the vault in-case of multi-tx transaction. `0` for singleVault Tx
    function receivePayload(uint256 payloadId, uint256 index, uint256 superFormId) external;

    /// @notice Form Keeper finalizes payload to process Timelock withdraw fully
    /// @param payloadId is the id of the payload to finalize
    /// @param ackExtraData_ is the AMBMessage data to send back to the source stateSync with request to re-mint SuperPositions
    function finalizePayload(uint256 payloadId, uint256 index, bytes memory ackExtraData_) external payable;
}

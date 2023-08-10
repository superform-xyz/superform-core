// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {InitSingleVaultData, TimeLockPayload} from "../types/DataTypes.sol";

/// @title ITwoStepsFormStateRegistry
/// @author ZeroPoint Labs
/// @notice Interface for Form State Registry
interface ITwoStepsFormStateRegistry {
    /// @notice Receives request (payload) from TimelockForm to process later
    function receivePayload(
        uint8 type_,
        address srcSender_,
        uint64 srcChainId_,
        uint256 lockedTill_,
        InitSingleVaultData memory data_
    ) external;

    /// @notice Form Keeper finalizes payload to process Timelock withdraw fully
    /// @param payloadId_ is the id of the payload to finalize
    /// @param txData_ is the off-chain generated transaction data
    /// @param ackExtraData_ is the AMBMessage data to send back to the source stateSync with request to re-mint SuperPositions
    function finalizePayload(
        uint256 payloadId_,
        bytes memory txData_,
        bytes memory ackExtraData_
    ) external payable returns (bytes memory returnMessage);

    /// @dev allows users to read the timeLockPayload_ stored per payloadId_
    /// @param payloadId_ is the unqiue payload identifier allocated on the destination chain
    /// @return timeLockPayload_ the timelock payload stored
    function getTimeLockPayload(uint256 payloadId_) external view returns (TimeLockPayload memory timeLockPayload_);

    /// @dev allows users to read the timeLockPayloadCounter
    function timeLockPayloadCounter() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {InitSingleVaultData} from "../types/DataTypes.sol";

/// @title ITwoStepsFormStateRegistry
/// @author ZeroPoint Labs
/// @notice Interface for Form State Registry
interface ITwoStepsFormStateRegistry {
    /// @notice Receives request (payload) from TimelockForm to process later
    function receivePayload(
        uint8 type_,
        address srcSender_,
        uint256 lockedTill_,
        InitSingleVaultData memory data_
    ) external;

    /// @notice Form Keeper finalizes payload to process Timelock withdraw fully
    /// @param payloadId is the id of the payload to finalize
    /// @param ackExtraData_ is the AMBMessage data to send back to the source stateSync with request to re-mint SuperPositions
    function finalizePayload(uint256 payloadId, bytes memory ackExtraData_) external payable;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { InitSingleVaultData, TwoStepsPayload } from "../types/DataTypes.sol";

/// @title ITwoStepsFormStateRegistry
/// @author ZeroPoint Labs
/// @notice Interface for Two Steps Form State Registry
interface ITwoStepsFormStateRegistry {
    /// @notice Receives request (payload) from two steps form to process later
    /// @param type_ is the nature of transaction (xChain: 1 or same chain: 0)
    /// @param srcSender_ is the address of the source chain caller
    /// @param lockedTill_ is the deadline for timelock (after which we can call `finalizePayload`)
    /// @param data_ is the basic information of superformId, amount to withdraw of type InitSingleVaultData
    function receivePayload(
        uint8 type_,
        address srcSender_,
        uint64 srcChainId_,
        uint256 lockedTill_,
        InitSingleVaultData memory data_
    )
        external;

    /// @notice Form Keeper finalizes payload to process two steps withdraw fully
    /// @param payloadId_ is the id of the payload to finalize
    /// @param txData_ is the off-chain generated transaction data
    /// @param ackExtraData_ is the AMBMessage data to send back to the source stateSync with request to re-mint shares
    function finalizePayload(uint256 payloadId_, bytes memory txData_, bytes memory ackExtraData_) external payable;

    /// @dev allows users to read the timeLockPayload_ stored per payloadId_
    /// @param payloadId_ is the unqiue payload identifier allocated on the destination chain
    /// @return timeLockPayload_ the timelock payload stored
    function getTwoStepsPayload(uint256 payloadId_) external view returns (TwoStepsPayload memory timeLockPayload_);

    /// @dev allows users to read the timeLockPayloadCounter
    function timeLockPayloadCounter() external view returns (uint256);
}

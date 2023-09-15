// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import { InitSingleVaultData, TimelockPayload } from "../types/DataTypes.sol";

/// @title ITimelockStateRegistry
/// @author ZeroPoint Labs
/// @notice Interface for Two Steps Form State Registry
interface ITimelockStateRegistry {
    /// @notice Receives request (payload) from two steps form to process later
    /// @param type_ is the nature of transaction (xChain: 1 or same chain: 0)
    /// @param srcSender_ is the address of the source chain caller
    /// @param srcChainId_ is the chainId of the source chain
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
    function finalizePayload(uint256 payloadId_, bytes memory txData_) external payable;

    /// @dev allows users to read the timeLockPayload_ stored per payloadId_
    /// @param payloadId_ is the unqiue payload identifier allocated on the destination chain
    /// @return timeLockPayload_ the timelock payload stored
    function getTimelockPayload(uint256 payloadId_) external view returns (TimelockPayload memory timeLockPayload_);

    /// @dev allows users to read the timelockPayloadCounter
    function timelockPayloadCounter() external view returns (uint256);
}

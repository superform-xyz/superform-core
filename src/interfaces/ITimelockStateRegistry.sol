// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { InitSingleVaultData, TimelockPayload } from "src/types/DataTypes.sol";

/// @title ITimelockStateRegistry
/// @dev Interface for TimelockStateRegistry
/// @author ZeroPoint Labs
interface ITimelockStateRegistry {
    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev allows users to read the timeLockPayload_ stored per payloadId_
    /// @param payloadId_ is the unique payload identifier allocated on the destination chain
    /// @return timeLockPayload_ the timelock payload stored
    function getTimelockPayload(uint256 payloadId_) external view returns (TimelockPayload memory timeLockPayload_);

    /// @dev allows users to read the timelockPayloadCounter
    function timelockPayloadCounter() external view returns (uint256);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @notice Receives request (payload) from timelock form to process later
    /// @param type_ is the nature of transaction (xChain: 1 or same chain: 0)
    /// @param srcChainId_ is the chainId of the source chain
    /// @param lockedTill_ is the deadline for timelock (after which we can call `finalizePayload`)
    /// @param data_ is the basic information of superformId, amount to withdraw of type InitSingleVaultData
    function receivePayload(
        uint8 type_,
        uint64 srcChainId_,
        uint256 lockedTill_,
        InitSingleVaultData memory data_
    )
        external;

    /// @notice Form Keeper finalizes payload to process timelock withdraw fully
    /// @param payloadId_ is the id of the payload to finalize
    /// @param txData_ is the off-chain generated transaction data
    function finalizePayload(uint256 payloadId_, bytes memory txData_) external payable;
}

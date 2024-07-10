// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { InitSingleVaultData } from "src/types/DataTypes.sol";
import { LiqRequest } from "src/types/DataTypes.sol";

//////////////////////////////////////////////////////////////
//                           ERRORS                        //
//////////////////////////////////////////////////////////////

error NOT_ASYNC_SUPERFORM();

//////////////////////////////////////////////////////////////
//                           ENUMS                        //
//////////////////////////////////////////////////////////////

/// @dev all statuses of the async payload
enum AsyncStatus {
    UNAVAILABLE,
    PENDING,
    PROCESSED
}

//////////////////////////////////////////////////////////////
//                           STRUCTS                        //
//////////////////////////////////////////////////////////////

/// @dev holds information about a sync withdraw txdata payload
struct SyncWithdrawTxDataPayload {
    uint64 srcChainId;
    InitSingleVaultData data;
    AsyncStatus status;
}

/// @title IBaseAsyncStateRegistry
/// @dev Interface forBase AsyncStateRegistry
/// @author ZeroPoint Labs
interface IBaseAsyncStateRegistry {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when a sync withdraw tx data payload is received
    event ReceivedSyncWithdrawTxDataPayload(uint256 indexed payloadId);

    /// @dev is emitted when a sync withdraw tx data payload is finalized
    event FinalizedSyncWithdrawTxDataPayload(uint256 indexed payloadId);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev allows users to read the syncWithdrawTxDataPayload stored per payloadId_
    /// @param payloadId_ is the unique payload identifier allocated on the destination chain
    /// @return syncWithdrawTxDataPayload_ the syncWithdrawTxData payload stored
    function getSyncWithdrawTxDataPayload(uint256 payloadId_)
        external
        view
        returns (SyncWithdrawTxDataPayload memory syncWithdrawTxDataPayload_);

    /// @dev allows users to read the syncWithdrawTxDataPayloadCounter
    function syncWithdrawTxDataPayloadCounter() external view returns (uint256);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @notice Receives the off-chain generated transaction data for the sync withdraw tx
    /// @param srcChainId_ is the chainId of the source chain
    /// @param data_ is the basic information of the action intent
    function receiveSyncWithdrawTxDataPayload(uint64 srcChainId_, InitSingleVaultData memory data_) external;

    /// @notice Form Keeper finalizes sync withdraw tx data payload to process the action fully.
    /// @param payloadId_ is the id of the payload to finalize
    /// @param txData_ is the off-chain generated transaction data
    function processSyncWithdrawWithUpdatedTxData(uint256 payloadId_, bytes memory txData_) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { InitSingleVaultData } from "src/types/DataTypes.sol";
import { LiqRequest } from "src/types/DataTypes.sol";
//////////////////////////////////////////////////////////////
//                           ERRORS                        //
//////////////////////////////////////////////////////////////

error NOT_ASYNC_SUPERFORM();
error NOT_READY_TO_CLAIM();
error ERC7540_AMBIDS_NOT_ENCODED();
error INVALID_AMOUNT_IN_TXDATA();

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

struct UserAccount {
    uint8 isXChain;
    bool retain4626;
    uint64 currentSrcChainId;
    uint256 currentReturnDataPayloadId;
    uint256 maxSlippageSetting;
    LiqRequest currentLiqRequest; // if different than address 0 signals keepers to update txData
    uint8[] ambIds;
}

/// @dev holds information about a sync withdraw txdata payload
struct SyncWithdrawTxDataPayload {
    uint64 srcChainId;
    InitSingleVaultData data;
    AsyncStatus status;
}

struct ClaimAvailableDepositsArgs {
    address user;
    uint256 superformId;
}

/// @title IAsyncStateRegistry
/// @dev Interface for AsyncStateRegistry
/// @author ZeroPoint Labs
interface IAsyncStateRegistry {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    event FailedDepositClaim(address indexed user_, uint256 indexed superformId_);

    event FailedRedeemClaim(address indexed user_, uint256 indexed superformId_);

    event UpdatedUserAccount(address indexed user_, uint256 indexed superformId_);

    event ClaimedAvailableDeposits(address indexed user_, uint256 indexed superformId_);

    event ClaimedAvailableRedeems(address indexed user_, uint256 indexed superformId_);

    /// @dev is emitted when a sync withdraw tx data payload is received
    event ReceivedSyncWithdrawTxDataPayload(uint256 indexed payloadId);

    /// @dev is emitted when a sync withdraw tx data payload is finalized
    event FinalizedSyncWithdrawTxDataPayload(uint256 indexed payloadId);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    function getUserAccount(
        address user_,
        uint256 superformId_
    )
        external
        view
        returns (UserAccount memory userAccount);

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

    function updateAccount(
        uint8 type_,
        uint64 srcChainId_,
        InitSingleVaultData memory data_,
        bool isDeposit_
    )
        external;

    /// @notice Receives the off-chain generated transaction data for the sync withdraw tx
    /// @param srcChainId_ is the chainId of the source chain
    /// @param data_ is the basic information of the action intent
    function receiveSyncWithdrawTxDataPayload(uint64 srcChainId_, InitSingleVaultData memory data_) external;

    function claimAvailableDeposits(ClaimAvailableDepositsArgs memory args) external payable;

    function claimAvailableRedeems(address user_, uint256 superformId_, bytes memory updatedTxData_) external;

    /// @notice Form Keeper finalizes sync withdraw tx data payload to process the action fully.
    /// @param payloadId_ is the id of the payload to finalize
    /// @param txData_ is the off-chain generated transaction data
    function processSyncWithdrawWithUpdatedTxData(uint256 payloadId_, bytes memory txData_) external payable;
}

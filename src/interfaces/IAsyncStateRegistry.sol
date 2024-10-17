// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { InitSingleVaultData } from "src/types/DataTypes.sol";
import { LiqRequest } from "src/types/DataTypes.sol";

//////////////////////////////////////////////////////////////
//                           ERRORS                        //
//////////////////////////////////////////////////////////////

error NOT_READY_TO_CLAIM();
error ERC7540_AMBIDS_NOT_ENCODED();
error INVALID_AMOUNT_IN_TXDATA();
error REQUEST_CONFIG_NON_EXISTENT();
error NOT_ASYNC_SUPERFORM();
error INVALID_UPDATED_TX_DATA();

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

struct RequestConfig {
    uint8 isXChain;
    bool retain4626;
    uint64 currentSrcChainId;
    uint256 requestId;
    uint256 currentReturnDataPayloadId;
    uint256 maxSlippageSetting;
    LiqRequest currentLiqRequest; // if different than address 0 signals keepers to update txData
    uint8[] ambIds;
}

struct ClaimAvailableDepositsLocalVars {
    address superformAddress;
    uint256 claimableDeposit;
}

/// @dev holds information about a sync withdraw txdata payload
struct SyncWithdrawTxDataPayload {
    uint64 srcChainId;
    InitSingleVaultData data;
    AsyncStatus status;
}

/// @title IAsyncStateRegistry
/// @dev Interface for AsyncStateRegistry
/// @author ZeroPoint Labs
interface IAsyncStateRegistry {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when a async deposit/redeem request is updated
    event UpdatedRequestsConfig(address indexed user_, uint256 indexed superformId_, uint256 indexed requestId_);

    /// @dev is emitted when shares are successfull claimed
    event ClaimedAvailableDeposits(address indexed user_, uint256 indexed superformId_, uint256 indexed requestId_);

    /// @dev is emitted when available funds are successfull redeemed
    event ClaimedAvailableRedeems(address indexed user_, uint256 indexed superformId_, uint256 indexed requestId_);

    /// @dev is emitted when async deposit fails
    event FailedDepositClaim(address indexed user_, uint256 indexed superformId_, uint256 indexed requestId_);

    /// @dev is emitted when async redeem fails
    event FailedRedeemClaim(address indexed user_, uint256 indexed superformId_, uint256 indexed requestId_);

    /// @dev is emitted when a sync redeem tx data payload is received
    event ReceivedSyncWithdrawTxDataPayload(uint256 indexed payloadId_);

    /// @dev is emitted when a sync redeem tx data payload is finalized
    event FinalizedSyncWithdrawTxDataPayload(uint256 indexed payloadId_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @notice retrieves the request configuration for a given user and superform
    /// @param user_ The address of the user
    /// @param superformId_ The ID of the superform
    /// @return requestConfig for the specified user and superform
    function getRequestConfig(
        address user_,
        uint256 superformId_
    )
        external
        view
        returns (RequestConfig memory requestConfig);

    /// @notice retrieves the sync withdraw txData payload for a given payload ID
    /// @param payloadId_ The ID of the payload
    /// @return syncWithdrawTxDataPayload_ for the specified payload ID
    function getSyncWithdrawTxDataPayload(uint256 payloadId_)
        external
        view
        returns (SyncWithdrawTxDataPayload memory syncWithdrawTxDataPayload_);

    /// @notice retrieves the current withdraw tx data payload counter
    function syncWithdrawTxDataPayloadCounter() external view returns (uint256);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @notice updates the request configuration for a given superform
    /// @dev the request parameters of the latest update overrides all preceding requests
    /// @param type_ The type of the request
    /// @param srcChainId_ The source chain ID
    /// @param isDeposit_ Whether the request is a deposit
    /// @param requestId_ The ID of the request
    /// @param data_ The InitSingleVaultData containing request information
    function updateRequestConfig(
        uint8 type_,
        uint64 srcChainId_,
        bool isDeposit_,
        uint256 requestId_,
        InitSingleVaultData memory data_
    )
        external;

    /// @notice claims available deposits for a user
    /// @param user_ The address of the user
    /// @param superformId_ the ID of the superform
    function claimAvailableDeposits(address user_, uint256 superformId_) external payable;

    /// @notice claims available redeems for a user
    /// @param user_ The address of the user
    /// @param superformId_ The ID of the superform
    /// @param updatedTxData_ The updated transaction data
    function claimAvailableRedeem(address user_, uint256 superformId_, bytes memory updatedTxData_) external;

    /// @notice Receives the off-chain generated transaction data for the sync withdraw tx
    /// @param srcChainId_ is the chainId of the source chain
    /// @param data_ is the basic information of the action intent
    function receiveSyncWithdrawTxDataPayload(uint64 srcChainId_, InitSingleVaultData memory data_) external;

    /// @notice Form Keeper finalizes sync withdraw tx data payload to process the action fully.
    /// @param payloadId_ is the id of the payload to finalize
    /// @param txData_ is the off-chain generated transaction data
    function processSyncWithdrawWithUpdatedTxData(uint256 payloadId_, bytes memory txData_) external payable;
}

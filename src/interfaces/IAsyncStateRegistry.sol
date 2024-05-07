// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { InitSingleVaultData } from "src/types/DataTypes.sol";

//////////////////////////////////////////////////////////////
//                           ERRORS                        //
//////////////////////////////////////////////////////////////
error NOT_ASYNC_SUPERFORM();
error NOT_READY_TO_CLAIM();

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

/// @dev holds information about the async deposit payload
struct AsyncDepositPayload {
    uint8 isXChain;
    uint64 srcChainId;
    uint256 assetsToDeposit;
    uint256 requestId;
    InitSingleVaultData data;
    AsyncStatus status;
}

/// @dev holds information about the async withdraw payload
struct AsyncWithdrawPayload {
    uint8 isXChain;
    uint64 srcChainId;
    uint256 requestId;
    InitSingleVaultData data;
    AsyncStatus status;
}

/// @title IAsyncCoreStateRegistry
/// @dev Interface for AsyncStateRegistry
/// @author ZeroPoint Labs
interface IAsyncStateRegistry {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when any deposit fails
    event FailedDeposit(uint256 indexed payloadId);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev allows users to read the deposit payload stored per payloadId_
    /// @param payloadId_ is the unique payload identifier allocated on the destination chain
    /// @return asyncDepositPayload_ the asyncDeposit payload stored
    function getAsyncDepositPayload(uint256 payloadId_)
        external
        view
        returns (AsyncDepositPayload memory asyncDepositPayload_);

    /// @dev allows users to read the withdraw payload stored per payloadId_
    /// @param payloadId_ is the unique payload identifier allocated on the destination chain
    /// @return asyncWithdrawPayload_ the asyncWithdraw payload stored
    function getAsyncWithdrawPayload(uint256 payloadId_)
        external
        view
        returns (AsyncWithdrawPayload memory asyncWithdrawPayload_);

    /// @dev allows users to read the asyncDepositPayloadCounter
    function asyncDepositPayloadCounter() external view returns (uint256);

    /// @dev allows users to read the asyncWithdrawPayloadCounter
    function asyncWithdrawPayloadCounter() external view returns (uint256);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @notice Receives deposit request (payload) from 7540 form to process later
    /// @notice There is an incremental asyncPayloadId that can be used to track in separate
    /// @param type_ is the nature of transaction (xChain: 1 or same chain: 0)
    /// @param srcChainId_ is the chainId of the source chain
    /// @param assetsToDeposit_ are the amount of assets to claim deposit into the vault
    /// @param requestId_ is the unique identifier of the request
    /// @param data_ is the basic information of the action intent
    function receiveDepositPayload(
        uint8 type_,
        uint64 srcChainId_,
        uint256 assetsToDeposit_,
        uint256 requestId_,
        InitSingleVaultData memory data_
    )
        external;

    /// @notice Receives withdraw request (payload) from 7540 form to process later
    /// @notice There is an incremental asyncPayloadId that can be used to track in separate
    /// @param type_ is the nature of transaction (xChain: 1 or same chain: 0)
    /// @param srcChainId_ is the chainId of the source chain
    /// @param requestId_ is the unique identifier of the request
    /// @param data_ is the basic information of the action intent
    function receiveWithdrawPayload(
        uint8 type_,
        uint64 srcChainId_,
        uint256 requestId_,
        InitSingleVaultData memory data_
    )
        external;

    /// @notice Form Keeper finalizes deposit payload to process the async action fully.
    /// @param payloadId_ is the id of the payload to finalize
    function finalizeDepositPayload(uint256 payloadId_) external payable;

    /// @notice Form Keeper finalizes withdraw payload to process the async action fully.
    /// @param payloadId_ is the id of the payload to finalize
    /// @param txData_ is the off-chain generated transaction data
    function finalizeWithdrawPayload(uint256 payloadId_, bytes memory txData_) external payable;
}

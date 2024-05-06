// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { InitSingleVaultData } from "src/types/DataTypes.sol";
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

/// @dev holds all information about a failed deposit mapped to a payload id
/// @param superformIds is an array of failing superform ids
/// @param settlementToken is an array of tokens to be refunded for the failing superform
/// @param amounts is an array of amounts of settlementToken to be refunded
/// @param receiverAddress is the users refund address
/// @param lastProposedTime indicates the rescue proposal timestamp
struct FailedDeposit {
    uint256[] superformIds;
    address[] settlementToken;
    uint256[] amounts;
    bool[] settleFromDstSwapper;
    address receiverAddress;
    uint256 lastProposedTimestamp;
}

/// @dev holds information about the async withdraw payload
struct AsyncWithdrawPayload {
    uint8 isXChain;
    uint64 srcChainId;
    uint256 requestId_;
    InitSingleVaultData data;
    AsyncStatus status;
}

/// @dev holds information about the async deposit payload
struct AsyncDepositPayload {
    uint8 isXChain;
    uint64 srcChainId;
    uint256 assetsToDeposit;
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
    event FailedDeposits(uint256 indexed payloadId);

    /// @dev is emitted when a rescue is proposed for failed deposits in a payload
    event RescueProposed(
        uint256 indexed payloadId, uint256[] superformIds, uint256[] proposedAmount, uint256 proposedTime
    );

    /// @dev is emitted when an user disputed his refund amounts
    event RescueDisputed(uint256 indexed payloadId);

    /// @dev is emitted when deposit rescue is finalized
    event RescueFinalized(uint256 indexed payloadId);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev allows users to read the superformIds that failed in a specific payloadId_
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @return superformIds is the identifiers of superforms in the payloadId that got failed.
    /// @return amounts is the amounts of refund tokens issues
    /// @return lastProposedTime is the refund proposed time
    function getFailedDeposits(uint256 payloadId_)
        external
        view
        returns (uint256[] memory superformIds, uint256[] memory amounts, uint256 lastProposedTime);

    /// @dev allows users to read the deposit payload stored per payloadId_
    /// @param payloadId_ is the unique payload identifier allocated on the destination chain
    /// @return asyncPayload_ the asyncDeposit payload stored
    function getAsyncDepositPayload(uint256 payloadId_)
        external
        view
        returns (AsyncDepositPayload memory asyncPayload_);

    /// @dev allows users to read the withdraw payload stored per payloadId_
    /// @param payloadId_ is the unique payload identifier allocated on the destination chain
    /// @return asyncPayload_ the asyncWithdraw payload stored
    function getAsyncWithdrawPayload(uint256 payloadId_)
        external
        view
        returns (AsyncWithdrawPayload memory asyncPayload_);

    /// @dev allows users to read the asyncPayloadCounter
    function asyncPayloadCounter() external view returns (uint256);

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

    /// @notice Form Keeper finalizes payload to process the async action fully.
    /// @param payloadId_ is the id of the payload to finalize
    /// @param txData_ is the off-chain generated transaction data
    function finalizePayload(uint256 payloadId_, bytes memory txData_) external payable;

    /// @dev allows accounts with {ASYNC_STATE_REGISTRY_PROCESSOR_ROLE} to rescue tokens on failed deposits
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @param proposedAmounts_ is the array of proposed rescue amounts.
    function proposeRescueFailedDeposits(uint256 payloadId_, uint256[] memory proposedAmounts_) external;

    /// @dev allows refund receivers to challenge their final receiving token amounts on failed deposits
    /// @param payloadId_ is the identifier of the cross-chain payload
    /// @notice should challenge within the delay window configured on SuperRegistry
    function disputeRescueFailedDeposits(uint256 payloadId_) external;

    /// @dev allows anyone to settle refunds for unprocessed/failed deposits past the challenge period
    /// @param payloadId_ is the identifier of the cross-chain payload
    function finalizeRescueFailedDeposits(uint256 payloadId_) external;
}

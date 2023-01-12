// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.14;

/// @notice We should optimize those types more
enum TransactionType {
    DEPOSIT,
    WITHDRAW
}

enum CallbackType {
    INIT,
    RETURN
}

enum PayloadState {
    STORED,
    UPDATED,
    PROCESSED
}

struct StateReq {
    uint16 dstChainId;
    uint256[] amounts;
    uint256[] vaultIds;
    uint256[] maxSlippage;
    bytes adapterParam;
    uint256 msgValue;
}

/// Created during deposit by contract from Liq+StateReqs
/// @dev using this for communication between src & dst transfers
struct StateData {
    TransactionType txType;
    CallbackType flag;
    bytes params;
}

struct InitData {
    uint16 srcChainId;
    uint16 dstChainId;
    address user;
    uint256[] vaultIds;
    uint256[] amounts;
    uint256[] maxSlippage;
    uint256 txId;
    bytes liqData;
}

struct ReturnData {
    bool status;
    uint16 srcChainId;
    uint16 dstChainId;
    uint256 txId;
    uint256[] amounts;
}

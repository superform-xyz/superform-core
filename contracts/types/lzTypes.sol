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

// [["106", ["8720"], ["4311413"], ["1000"], "0x000100000000000000000000000000000000000000000000000000000000004c4b40", "1548277010953360"]]
// [["0", "0x", "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", "0", "0"]]

// ["0xbb906bc787fbc9207e254ff87be398f4e86ea39f"]["0xA36c9FEB786A79E60E5583622D1Fb42294003411"] = true
// [{operator: "0xA36c9FEB786A79E60E5583622D1Fb42294003411"}]

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

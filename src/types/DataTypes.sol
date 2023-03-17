// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @dev contains all the common struct and enums used for data communication between chains.

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
    uint8 ambId;
    uint80 dstChainId;
    uint256[] amounts;
    uint256[] superFormIds;
    uint256[] maxSlippage;
    bytes adapterParam;
    bytes extraFormData;
    uint256 msgValue;
}

/// @dev using this for communication between src & dst transfers
struct StateData {
    TransactionType txType; // <- 1
    CallbackType flag; // <- 2
    bytes params;
}

struct FormData {
    uint80 srcChainId;
    uint80 dstChainId;
    bytes commonData;
    bytes xChainData;
    bytes extraFormData;
}

struct FormCommonData {
    address srcSender;
    uint256[] superFormIds;
    uint256[] amounts;
    bytes liqData;
}

struct FormXChainData {
    uint256 txId;
    uint256[] maxSlippage;
}

struct XChainActionArgs {
    uint80 srcChainId;
    uint80 dstChainId;
    bytes commonData;
    bytes xChainData;
    bytes adapterParam;
}

struct ReturnData {
    bool status;
    uint80 srcChainId;
    uint80 dstChainId;
    uint256 txId;
    uint256[] amounts;
}

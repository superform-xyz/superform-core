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
    uint8 bridgeId;
    uint256 dstChainId;
    uint256[] amounts;
    uint256[] superFormIds;
    uint256[] maxSlippage;
    bytes adapterParam;
    bytes extraFormData;
    uint256 msgValue;
}

/// @dev using this for communication between src & dst transfers
struct StateData {
    TransactionType txType;
    CallbackType flag;
    bytes params;
}

struct InitData {
    uint256 srcChainId;
    uint256 dstChainId;
    address user;
    uint256[] vaultIds;
    uint256[] amounts;
    uint256[] maxSlippage;
    uint256 txId;
    bytes liqData;
}

struct FormData {
    uint256 srcChainId;
    uint256 dstChainId;
    bytes commonData;
    bytes xChainData;
    bytes extraFormData;
}

struct FormCommonData {
    address srcSender;
    address[] vaults;
    uint256[] amounts;
    bytes liqData;
}

struct FormXChainData {
    uint256 txId;
}

struct XChainActionArgs {
    uint256 srcChainId;
    uint256 dstChainId;
    bytes commonData;
    bytes xChainData;
    bytes adapterParam;
}

struct ReturnData {
    bool status;
    uint256 srcChainId;
    uint256 dstChainId;
    uint256 txId;
    uint256[] amounts;
}

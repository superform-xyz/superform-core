// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import "./LiquidityTypes.sol";

/// @dev contains all the common struct and enums used for data communication between chains.

enum TransactionType {
    DEPOSIT,
    WITHDRAW
}

enum CallbackType {
    INIT,
    RETURN,
    FAIL /// @dev Used only in withdraw flow now
}

enum PayloadState {
    STORED,
    UPDATED,
    PROCESSED
}

//; Liq Data: 0 (chainId 1) => [LiqData (SfData1)] | 1 (chainId 2) => [LiqData (SfData3 + SfData4)] | 2 (chainId 3) => [LiqData (SfData5) | 3 (chainId 3) => [LiqData (SfData6)]
struct MultiVaultSFData {
    // superFormids must have same destination. Can have different different underlyings
    uint256[] superFormIds;
    uint256[] amounts;
    uint256[] maxSlippages;
    LiqRequest[] liqRequests; // if length = 1; amount = sum(amounts)| else  amounts must match the amounts being sent
    bytes extraFormData; // extraFormData
}
struct SingleVaultSFData {
    // superFormids must have same destination. Can have different different underlyings
    uint256 superFormId;
    uint256 amount;
    uint256 maxSlippage;
    LiqRequest liqRequest; // if length = 1; amount = sum(amounts)| else  amounts must match the amounts being sent
    bytes extraFormData; // extraFormData
}

struct MultiDstMultiVaultsStateReq {
    uint8[][] ambIds;
    uint64[] dstChainIds;
    MultiVaultSFData[] superFormsData;
    bytes[] extraDataPerDst; /// encoded array of SingleDstAMBParams; length == no of dstChainIds
}

struct SingleDstMultiVaultsStateReq {
    uint8[] ambIds;
    uint64 dstChainId;
    MultiVaultSFData superFormsData;
    bytes extraData;
}

struct MultiDstSingleVaultStateReq {
    uint8[][] ambIds;
    uint64[] dstChainIds;
    SingleVaultSFData[] superFormsData;
    bytes[] extraDataPerDst;
}

struct SingleXChainSingleVaultStateReq {
    uint8[] ambIds;
    uint64 dstChainId;
    SingleVaultSFData superFormData;
    bytes extraData;
}

struct SingleDirectSingleVaultStateReq {
    uint64 dstChainId;
    SingleVaultSFData superFormData;
    bytes extraData;
}

struct InitMultiVaultData {
    uint256 payloadId;
    uint256[] superFormIds;
    uint256[] amounts;
    uint256[] maxSlippage;
    LiqRequest[] liqData;
    bytes extraFormData;
}

struct InitSingleVaultData {
    uint256 payloadId;
    uint256 superFormId;
    uint256 amount;
    uint256 maxSlippage;
    LiqRequest liqData;
    bytes extraFormData;
}

enum TimeLockStatus {
    UNAVAILABLE,
    PENDING,
    PROCESSED
}

struct TimeLockPayload {
    uint8 isXChain;
    address srcSender;
    uint64 srcChainId;
    uint256 lockedTill;
    InitSingleVaultData data;
    TimeLockStatus status;
}

struct AMBMessage {
    uint256 txInfo; // tight packing of  TransactionType txType,  CallbackType flag  if multi/single vault, registry id, srcSender and srcChainId
    bytes params; // decoding txInfo will point to the right datatype of params. Refer PayloadHelper.sol
}

struct AMBFactoryMessage {
    bytes32 messageType; /// keccak("ADD_FORM"), keccak("PAUSE_FORM")
    bytes message;
}

struct ReturnMultiData {
    uint256 payloadId;
    uint256[] superFormIds;
    uint256[] amounts;
}

struct ReturnSingleData {
    uint256 payloadId;
    uint256 superFormId;
    uint256 amount;
}

/**
 * if let's say its multi-dst / broadcasting
 * broadcasting is an extension of multi-dst
 *
 * splitting of the data types will reduce gas??
 * what would be an ideal data type??
 *
 * linear waterflow model??
 * where the top data type is encoded and the bottom level decodes it
 */
struct SingleDstAMBParams {
    uint256 gasToPay;
    bytes encodedAMBExtraData;
}

struct AMBExtraData {
    uint256[] gasPerAMB;
    bytes[] extraDataPerAMB;
}

struct BroadCastAMBExtraData {
    uint256[] gasPerDst;
    bytes[] extraDataPerDst;
}

/// acknowledgement extra data
struct AckAMBData {
    uint8[] ambIds;
    bytes extraData;
}

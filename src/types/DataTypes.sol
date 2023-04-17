// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import "./LiquidityTypes.sol";

/// @dev contains all the common struct and enums used for data communication between chains.

/// @notice We should optimize those types more
enum TransactionType {
    DEPOSIT,
    WITHDRAW
}

enum CallbackType {
    INIT,
    RETURN,
    FAIL
}

enum PayloadState {
    STORED,
    UPDATED,
    PROCESSED
}

//; Liq Data: 0 (chainId 1) => [LiqData (SfData1)] | 1 (chainId 2) => [LiqData (SfData3 + SfData4)] | 2 (chainId 3) => [LiqData (SfData5) | 3 (chainId 3) => [LiqData (SfData6)]
struct MultiVaultsSFData {
    // superFormids must have same destination. Can have different different underlyings
    uint256[] superFormIds;
    uint256[] amounts;
    uint256[] maxSlippage;
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
    uint8 primaryAmbId;
    uint8[] proofAmbId;
    uint16[] dstChainIds;
    MultiVaultsSFData[] superFormsData;
    bytes adapterParam;
    uint256 msgValue;
}

struct SingleDstMultiVaultsStateReq {
    uint8 primaryAmbId;
    uint8[] proofAmbId;
    uint16 dstChainId;
    MultiVaultsSFData superFormsData;
    bytes adapterParam;
    uint256 msgValue;
}

struct MultiDstSingleVaultStateReq {
    uint8 primaryAmbId;
    uint8[] proofAmbId;
    uint16[] dstChainIds;
    SingleVaultSFData[] superFormsData;
    bytes adapterParam;
    uint256 msgValue;
}

struct SingleXChainSingleVaultStateReq {
    uint8 primaryAmbId;
    uint8[] proofAmbId;
    uint16 dstChainId;
    SingleVaultSFData superFormData;
    bytes adapterParam;
    uint256 msgValue;
}

struct SingleDirectSingleVaultStateReq {
    uint16 dstChainId;
    SingleVaultSFData superFormData;
    bytes adapterParam;
    uint256 msgValue;
}

struct InitMultiVaultData {
    uint256 txData; // <- tight packing of (address srcSender (160 bits), srcChainId(uint16), txId (80bits))
    uint256[] superFormIds;
    uint256[] amounts;
    uint256[] maxSlippage;
    LiqRequest[] liqData;
    bytes extraFormData;
}

struct InitSingleVaultData {
    uint256 txData; // <- tight packing of (address srcSender (160 bits), srcChainId(uint16), txId (80bits))
    uint256 superFormId;
    uint256 amount;
    uint256 maxSlippage;
    LiqRequest liqData;
    bytes extraFormData;
}

struct AMBMessage {
    uint256 txInfo; // tight packing of  TransactionType txType,  CallbackType flag and if multi/single vault, uint8 = 1, 2, 3
    bytes params; // abi.encode (AMBInitData)
}

struct AMBFactoryMessage {
    uint256 superFormId;
    address vaultAddress;
}

struct ReturnMultiData {
    uint256 returnTxInfo; // tight packing of status, srcChainId, dstChainId and original txId
    uint256[] amounts;
}

struct ReturnSingleData {
    uint256 returnTxInfo; // tight packing of status, srcChainId, dstChainId and original txId
    uint256 amount;
}

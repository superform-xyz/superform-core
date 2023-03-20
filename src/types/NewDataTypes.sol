// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "./LiquidityTypes.sol";

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
    uint8[] secondaryAmbIds;
    uint16[] dstChainIds;
    MultiVaultsSFData[] superFormsData;
    bytes adapterParam;
    uint256 msgValue;
}

struct SingleDstMultiVaultsStateReq {
    uint8 primaryAmbId;
    uint8[] secondaryAmbIds;
    uint16 dstChainId;
    MultiVaultsSFData superFormsData;
    bytes adapterParam;
    uint256 msgValue;
}

struct MultiDstSingleVaultStateReq {
    uint8 primaryAmbId;
    uint8[] secondaryAmbIds;
    uint16[] dstChainIds;
    SingleVaultSFData[] superFormsData;
    bytes adapterParam;
    uint256 msgValue;
}

struct SingleXChainSingleVaultStateReq {
    uint8 primaryAmbId;
    uint8[] secondaryAmbIds;
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
    bytes extraFormData;
    bytes liqData;
}

struct InitSingleVaultData {
    uint256 txData; // <- tight packing of (address srcSender (160 bits), srcChainId(uint16), txId (80bits))
    uint256 superFormId;
    uint256 amount;
    uint256 maxSlippage;
    bytes extraFormData;
    bytes liqData;
}

struct AMBMessage {
    uint256 txInfo; // tight packing of  TransactionType txType and CallbackType flag;
    bytes params; // abi.encode (AMBInitData)
}

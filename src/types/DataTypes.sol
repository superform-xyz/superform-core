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

// MultiSuperForms

/*
struct SFData {
    uint256 superFormId;
    uint256 amount;
    uint256 maxSlippage;
    bytes extraFormData;
}

struct MultiSFStateReq {
    uint8 ambId;
    uint80[] dstChainIds; // 1, 2, 3             // <--- to know where message bundling should happen
    mapping(uint80 => SFData[]) superForms; // 1 => [SFData1], 2 => [SFData3, SFData4], 3 => [SFData5, SFData6]
    bytes adapterParam;
    uint256 msgValue;
}

struct SingleSFStateReq {
    uint8 ambId;
    SFData superFormData;
    bytes adapterParam;
    uint256 msgValue;
}
remove allowanceTarget
struct LiqRequest {
    uint8 bridgeId;
    bytes txData;
    address token;
    uint256 amount;
    uint256 nativeAmount;
}
source ChainId = 1

need a swap in chain 1; need bridging of token 3 in chain 2 (can sum the amounts?); need two bridgings in chain 3, of token 1 and token 2
Total of 4 LiqRequests

struct MultiXChainStateReq {
    uint8 primaryAmbId; 
    uint8[] secondaryAmbIds; 
    uint16[] dstChainIds;
    mapping(uint16 => FormData[]) formsData; Destinations: chainId 1 => [SFData1] | chainId 2 => [SFData3 (token 3), SFData4 (token 3)] | chainId 3 => [SFData5 (token 1), SFData6 (token 2)]
    mapping(uint16 => LiqRequest[]) liqRequests; Liq Data: 0 (chainId 1) => [LiqData (SfData1)] | 1 (chainId 2) => [LiqData (SfData3 + SfData4)] | 2 (chainId 3) => [LiqData (SfData5) | 3 (chainId 3) => [LiqData (SfData6)]
    bytes adapterParam;
    uint256 msgValue;
}
struct FormData {
    uint256 txInfo; // <- tight packing of (address srcSender (160 bits), srcChainId(uint16), txId (80bits)) -> must be 0 when being sent in the state req
    uint256[] superFormIds;
    uint256[] amounts;
    uint256[] maxSlippage;
    bytes extraData; // <- liqData + extraFormData
}

e.g entrypoint
problem: what if the same dstChainId is sent in dstChainIds array?
This is not an issue because it's up to the user if he wants to do repeating stuff in the same destination (without bundling messages)

function multiXChainDeposit (MultiXChainStateReq memory req, LiqRequest[] memory liqRequests) {
        for (i<dstChainIds.length) {
            uint16 dstChainId = dstChainIds[i];
            /// @dev increase txs

            for (j < formsData[dstChainId].length) {
                /// @dev validate slippage

                req.formsData[dstChainId][j].txData = srcSender + srcChainId + txId
                stateData [i] = StateData(TransactionType.DEPOSIT, CallbackType.INIT, abi.encode(req.formsData[dstChainId][j]);

            }

            for (j < liqRequests[dstChainId].length) {
                /// @dev validate liq request txData and etc
            }



            for (j<liqRequests.length) {
                /// @dev validate liqRequests
                dispatchTokens(liqRequests[j])
            }

            stateRegistry.dispatchPayload{value: stateData_.msgValue}(
                req[i].primaryAmbId,
                req[i].secondaryAmbIds,
                dstChainIds[i],
                abi.encode(stateData),
                stateData_.adapterParam

    }

struct FormData {
uint256 txInfo; // <- tight packing of (address srcSender (160 bits), srcChainId(uint16), txId (80bits))
uint256[] superFormIds;
uint256[] amounts;
uint256[] maxSlippage;
bytes extraData; // <- liqData + extraFormData
}
evertyhing else...

struct MultiDirectStateReq {
    SFData[] superForms
    bytes adapterParam;
    uint256 msgValue;
}

struct SFData {
    uint256 superFormId;
    uint256 amount;
    uint256 maxSlippage;
    bytes extraFormData;
}

struct SingleXChainStateReq {
    uint8 primaryAmbId;
    uint8[] secondaryAmbIds;
    SFData superFormData;
    bytes adapterParam;
    uint256 msgValue;
}

struct SingleDirectStateReq {
    SFData superFormData;
    bytes adapterParam;
    uint256 msgValue;
}


*/

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

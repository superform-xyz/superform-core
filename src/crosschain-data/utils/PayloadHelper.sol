// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";
import { IStateSyncer } from "../../interfaces/IStateSyncer.sol";
import { IBaseStateRegistry } from "../../interfaces/IBaseStateRegistry.sol";
import { ITimelockStateRegistry } from "../../interfaces/ITimelockStateRegistry.sol";
import { IPayloadHelper } from "../../interfaces/IPayloadHelper.sol";
import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";

import {
    CallbackType,
    ReturnMultiData,
    ReturnSingleData,
    InitMultiVaultData,
    InitSingleVaultData,
    TimelockPayload,
    LiqRequest
} from "../../types/DataTypes.sol";
import { DataLib } from "../../libraries/DataLib.sol";

/// @title PayloadHelper
/// @author ZeroPoint Labs
/// @dev helps decode payload data more easily. Used for off-chain purposes
contract PayloadHelper is IPayloadHelper {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct DecodeDstPayloadInternalVars {
        uint8 txType;
        uint8 callbackType;
        address srcSender;
        uint64 srcChainId;
        uint256[] amounts;
        uint256[] slippage;
        uint256[] superformIds;
        uint256 srcPayloadId;
        uint8 superformRouterId;
        uint8 multi;
        ReturnMultiData rd;
        ReturnSingleData rsd;
        InitMultiVaultData imvd;
        InitSingleVaultData isvd;
    }

    struct DecodeDstPayloadLiqDataInternalVars {
        uint8 callbackType;
        uint8 multi;
        uint8[] bridgeIds;
        bytes[] txDatas;
        address[] liqDataTokens;
        uint64[] liqDataChainIds;
        uint256[] liqDataAmountsIn;
        uint256[] liqDataAmountsOut;
        uint256[] liqDataNativeAmounts;
        InitMultiVaultData imvd;
        InitSingleVaultData isvd;
        uint256 i;
    }

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    IBaseStateRegistry public immutable coreStateRegistry;
    ISuperRegistry public immutable superRegistry;
    ITimelockStateRegistry public immutable twoStepRegistry;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address dstPayloadRegistry_, address superRegistry_, address twoStepRegistry_) {
        coreStateRegistry = IBaseStateRegistry(dstPayloadRegistry_);
        superRegistry = ISuperRegistry(superRegistry_);
        twoStepRegistry = ITimelockStateRegistry(twoStepRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPayloadHelper
    function decodeCoreStateRegistryPayload(uint256 dstPayloadId_)
        external
        view
        override
        returns (
            uint8 txType,
            uint8 callbackType,
            address srcSender,
            uint64 srcChainId,
            uint256[] memory amounts,
            uint256[] memory slippage,
            uint256[] memory superformIds,
            uint256 srcPayloadId,
            uint8 superformRouterId
        )
    {
        DecodeDstPayloadInternalVars memory v;

        (v.txType, v.callbackType, v.multi,, v.srcSender, v.srcChainId) =
            coreStateRegistry.payloadHeader(dstPayloadId_).decodeTxInfo();

        if (v.callbackType == uint256(CallbackType.RETURN) || v.callbackType == uint256(CallbackType.FAIL)) {
            if (v.multi == 1) {
                v.rd = abi.decode(coreStateRegistry.payloadBody(dstPayloadId_), (ReturnMultiData));
                v.amounts = v.rd.amounts;
                v.srcPayloadId = v.rd.payloadId;
                v.superformRouterId = v.rd.superformRouterId;
            } else {
                v.rsd = abi.decode(coreStateRegistry.payloadBody(dstPayloadId_), (ReturnSingleData));
                v.amounts = new uint256[](1);
                v.amounts[0] = v.rsd.amount;

                v.srcPayloadId = v.rsd.payloadId;
                v.superformRouterId = v.rsd.superformRouterId;
            }
        }

        if (v.callbackType == uint256(CallbackType.INIT)) {
            if (v.multi == 1) {
                v.imvd = abi.decode(coreStateRegistry.payloadBody(dstPayloadId_), (InitMultiVaultData));
                v.superformRouterId = v.imvd.superformRouterId;
                v.amounts = v.imvd.amounts;
                v.slippage = v.imvd.maxSlippage;
                v.superformIds = v.imvd.superformIds;
                v.srcPayloadId = v.imvd.payloadId;
            } else {
                v.isvd = abi.decode(coreStateRegistry.payloadBody(dstPayloadId_), (InitSingleVaultData));

                v.superformRouterId = v.isvd.superformRouterId;

                v.amounts = new uint256[](1);
                v.amounts[0] = v.isvd.amount;

                v.slippage = new uint256[](1);
                v.slippage[0] = v.isvd.maxSlippage;

                v.superformIds = new uint256[](1);
                v.superformIds[0] = v.isvd.superformId;

                v.srcPayloadId = v.isvd.payloadId;
            }
        }

        return (
            v.txType,
            v.callbackType,
            v.srcSender,
            v.srcChainId,
            v.amounts,
            v.slippage,
            v.superformIds,
            v.srcPayloadId,
            v.superformRouterId
        );
    }

    /// @inheritdoc IPayloadHelper
    function decodeCoreStateRegistryPayloadLiqData(uint256 dstPayloadId_)
        external
        view
        override
        returns (
            uint8[] memory bridgeIds,
            bytes[] memory txDatas,
            address[] memory tokens,
            uint64[] memory liqDstChainIds,
            uint256[] memory amountsIn,
            uint256[] memory amountsOut,
            uint256[] memory nativeAmounts
        )
    {
        DecodeDstPayloadLiqDataInternalVars memory v;

        (, v.callbackType, v.multi,,,) = coreStateRegistry.payloadHeader(dstPayloadId_).decodeTxInfo();
        if (v.multi == 1) {
            v.imvd = abi.decode(coreStateRegistry.payloadBody(dstPayloadId_), (InitMultiVaultData));

            v.bridgeIds = new uint8[](v.imvd.liqData.length);
            v.txDatas = new bytes[](v.imvd.liqData.length);
            v.liqDataTokens = new address[](v.imvd.liqData.length);
            v.liqDataChainIds = new uint64[](v.imvd.liqData.length);
            v.liqDataAmountsIn = new uint256[](v.imvd.liqData.length);
            v.liqDataAmountsOut = new uint256[](v.imvd.liqData.length);
            v.liqDataNativeAmounts = new uint256[](v.imvd.liqData.length);

            uint256 len = v.imvd.liqData.length;

            for (v.i; v.i < len;) {
                v.bridgeIds[v.i] = v.imvd.liqData[v.i].bridgeId;
                v.txDatas[v.i] = v.imvd.liqData[v.i].txData;
                v.liqDataTokens[v.i] = v.imvd.liqData[v.i].token;
                v.liqDataChainIds[v.i] = v.imvd.liqData[v.i].liqDstChainId;

                v.liqDataAmountsIn[v.i] = IBridgeValidator(superRegistry.getBridgeValidator(v.bridgeIds[v.i]))
                    .decodeAmountIn(v.txDatas[v.i], false);

                v.liqDataAmountsOut[v.i] = IBridgeValidator(superRegistry.getBridgeValidator(v.bridgeIds[v.i]))
                    .decodeMinAmountOut(v.txDatas[v.i], false);
                v.liqDataNativeAmounts[v.i] = v.imvd.liqData[v.i].nativeAmount;

                unchecked {
                    ++v.i;
                }
            }
        } else {
            v.isvd = abi.decode(coreStateRegistry.payloadBody(dstPayloadId_), (InitSingleVaultData));

            v.bridgeIds = new uint8[](1);
            v.bridgeIds[0] = v.isvd.liqData.bridgeId;

            v.txDatas = new bytes[](1);
            v.txDatas[0] = v.isvd.liqData.txData;

            v.liqDataTokens = new address[](1);
            v.liqDataTokens[0] = v.isvd.liqData.token;

            v.liqDataChainIds = new uint64[](1);
            v.liqDataChainIds[0] = v.isvd.liqData.liqDstChainId;

            v.liqDataAmountsIn = new uint256[](1);
            v.liqDataAmountsIn[0] =
                IBridgeValidator(superRegistry.getBridgeValidator(v.bridgeIds[0])).decodeAmountIn(v.txDatas[0], false);

            v.liqDataAmountsOut = new uint256[](1);
            v.liqDataAmountsOut[0] = IBridgeValidator(superRegistry.getBridgeValidator(v.bridgeIds[0]))
                .decodeMinAmountOut(v.txDatas[0], false);

            v.liqDataNativeAmounts = new uint256[](1);
            v.liqDataNativeAmounts[0] = v.isvd.liqData.nativeAmount;
        }

        return (
            v.bridgeIds,
            v.txDatas,
            v.liqDataTokens,
            v.liqDataChainIds,
            v.liqDataAmountsIn,
            v.liqDataAmountsOut,
            v.liqDataNativeAmounts
        );
    }

    /// @inheritdoc IPayloadHelper
    function decodeStateSyncerPayloadHistory(
        uint256 srcPayloadId_,
        uint8 superformRouterId_
    )
        external
        view
        override
        returns (uint8 txType, uint8 callbackType, uint8 multi, address srcSender, uint64 srcChainId)
    {
        uint256 txInfo = IStateSyncer(superRegistry.getStateSyncer(superformRouterId_)).txHistory(srcPayloadId_);

        if (txInfo != 0) {
            (txType, callbackType, multi,, srcSender, srcChainId) = txInfo.decodeTxInfo();
        }
    }

    /// @inheritdoc IPayloadHelper
    function decodeTimeLockPayload(uint256 timelockPayloadId_)
        external
        view
        override
        returns (address srcSender, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount)
    {
        TimelockPayload memory payload = twoStepRegistry.getTimelockPayload(timelockPayloadId_);

        return (
            payload.srcSender, payload.srcChainId, payload.data.payloadId, payload.data.superformId, payload.data.amount
        );
    }

    function decodeTimeLockFailedPayload(uint256 timelockPayloadId_)
        external
        view
        override
        returns (address srcSender, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount)
    {
        IBaseStateRegistry timelockPayloadRegistry = IBaseStateRegistry(address(twoStepRegistry));
        bytes memory payloadBody = timelockPayloadRegistry.payloadBody(timelockPayloadId_);
        uint256 payloadHeader = timelockPayloadRegistry.payloadHeader(timelockPayloadId_);

        (, uint8 callbackType_,,, address srcSender_, uint64 srcChainId_) = payloadHeader.decodeTxInfo();

        /// @dev callback type can never be INIT / RETURN
        if (callbackType_ == uint256(CallbackType.FAIL)) {
            ReturnSingleData memory rsd = abi.decode(payloadBody, (ReturnSingleData));
            amount = rsd.amount;
            superformId = rsd.superformId;
            srcPayloadId = rsd.payloadId;
        }

        srcSender = srcSender_;
        srcChainId = srcChainId_;
    }
}

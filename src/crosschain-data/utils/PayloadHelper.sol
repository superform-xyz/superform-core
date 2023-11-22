// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";
import { ISuperPositions } from "../../interfaces/ISuperPositions.sol";
import { IBaseStateRegistry } from "../../interfaces/IBaseStateRegistry.sol";
import { ITimelockStateRegistry } from "../../interfaces/ITimelockStateRegistry.sol";
import { IPayloadHelper } from "../../interfaces/IPayloadHelper.sol";
import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";
import { Error } from "../../libraries/Error.sol";
import {
    CallbackType,
    ReturnMultiData,
    ReturnSingleData,
    InitMultiVaultData,
    InitSingleVaultData,
    TimelockPayload,
    LiqRequest,
    AMBMessage
} from "../../types/DataTypes.sol";
import { DataLib } from "../../libraries/DataLib.sol";
import { ProofLib } from "../../libraries/ProofLib.sol";

/// @title PayloadHelper
/// @author ZeroPoint Labs
/// @dev helps decode payload data more easily. Used for off-chain purposes

contract PayloadHelper is IPayloadHelper {
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    ISuperRegistry public immutable superRegistry;

    //////////////////////////////////////////////////////////////
    //                           STRUCTS                        //
    //////////////////////////////////////////////////////////////

    struct DecodeDstPayloadInternalVars {
        uint8 txType;
        uint8 callbackType;
        address srcSender;
        uint64 srcChainId;
        uint256[] amounts;
        uint256[] slippages;
        uint256[] superformIds;
        bool[] hasDstSwaps;
        address receiverAddress;
        uint256 srcPayloadId;
        bytes extraFormData;
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
        uint256[] liqDataNativeAmounts;
        InitMultiVaultData imvd;
        InitSingleVaultData isvd;
        uint256 i;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

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
            uint256[] memory slippages,
            uint256[] memory superformIds,
            bool[] memory hasDstSwaps,
            bytes memory extraFormData,
            address receiverAddress,
            uint256 srcPayloadId
        )
    {
        IBaseStateRegistry coreStateRegistry = _getCoreStateRegistry();
        _isValidPayloadId(dstPayloadId_, coreStateRegistry);

        DecodeDstPayloadInternalVars memory v;
        (v.txType, v.callbackType, v.multi, v.srcSender, v.srcChainId) =
            _decodePayloadHeader(dstPayloadId_, coreStateRegistry);

        if (v.callbackType == uint256(CallbackType.RETURN) || v.callbackType == uint256(CallbackType.FAIL)) {
            (v.amounts, v.srcPayloadId) = _decodeReturnData(dstPayloadId_, v.multi, coreStateRegistry);
        } else if (v.callbackType == uint256(CallbackType.INIT)) {
            (v.amounts, v.slippages, v.superformIds, v.hasDstSwaps, v.extraFormData, v.receiverAddress, v.srcPayloadId)
            = _decodeInitData(dstPayloadId_, v.multi, coreStateRegistry);
        } else {
            revert Error.INVALID_PAYLOAD();
        }

        return (
            v.txType,
            v.callbackType,
            v.srcSender,
            v.srcChainId,
            v.amounts,
            v.slippages,
            v.superformIds,
            v.hasDstSwaps,
            v.extraFormData,
            v.receiverAddress,
            v.srcPayloadId
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
            uint256[] memory nativeAmounts
        )
    {
        IBaseStateRegistry coreStateRegistry = _getCoreStateRegistry();
        _isValidPayloadId(dstPayloadId_, coreStateRegistry);

        DecodeDstPayloadLiqDataInternalVars memory v;
        (, v.callbackType, v.multi,,) = _decodePayloadHeader(dstPayloadId_, coreStateRegistry);

        if (v.multi == 1) {
            return _decodeMultiLiqData(dstPayloadId_, coreStateRegistry);
        } else {
            return _decodeSingleLiqData(dstPayloadId_, coreStateRegistry);
        }
    }

    /// @inheritdoc IPayloadHelper
    function decodePayloadHistory(uint256 srcPayloadId_)
        external
        view
        override
        returns (uint8 txType, uint8 callbackType, uint8 multi, address srcSender, uint64 srcChainId)
    {
        uint256 txInfo =
            ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).txHistory(srcPayloadId_);

        if (txInfo == 0) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        (txType, callbackType, multi,, srcSender, srcChainId) = txInfo.decodeTxInfo();
    }

    /// @inheritdoc IPayloadHelper
    function decodeTimeLockPayload(uint256 timelockPayloadId_)
        external
        view
        override
        returns (address srcSender, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount)
    {
        ITimelockStateRegistry timelockStateRegistry =
            ITimelockStateRegistry(superRegistry.getAddress(keccak256("TIMELOCK_STATE_REGISTRY")));

        if (timelockPayloadId_ > timelockStateRegistry.timelockPayloadCounter()) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        TimelockPayload memory payload = timelockStateRegistry.getTimelockPayload(timelockPayloadId_);

        return (
            payload.srcSender, payload.srcChainId, payload.data.payloadId, payload.data.superformId, payload.data.amount
        );
    }

    /// @inheritdoc IPayloadHelper
    function getDstPayloadProof(uint256 dstPayloadId_) external view override returns (bytes32) {
        IBaseStateRegistry coreStateRegistry =
            IBaseStateRegistry(superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY")));

        return ProofLib.computeProof(
            AMBMessage(coreStateRegistry.payloadHeader(dstPayloadId_), coreStateRegistry.payloadBody(dstPayloadId_))
        );
    }

    /// @inheritdoc IPayloadHelper
    function decodeTimeLockFailedPayload(uint256 payloadId_)
        external
        view
        override
        returns (address srcSender, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount)
    {
        IBaseStateRegistry timelockPayloadRegistry =
            IBaseStateRegistry(superRegistry.getAddress(keccak256("TIMELOCK_STATE_REGISTRY")));

        _isValidPayloadId(payloadId_, timelockPayloadRegistry);

        bytes memory payloadBody = timelockPayloadRegistry.payloadBody(payloadId_);
        uint256 payloadHeader = timelockPayloadRegistry.payloadHeader(payloadId_);

        (, uint8 callbackType_,,, address srcSender_, uint64 srcChainId_) = payloadHeader.decodeTxInfo();

        /// @dev callback type can never be INIT / RETURN
        if (callbackType_ == uint256(CallbackType.FAIL)) {
            ReturnSingleData memory rsd = abi.decode(payloadBody, (ReturnSingleData));
            amount = rsd.amount;
            superformId = rsd.superformId;
            srcPayloadId = rsd.payloadId;
        } else {
            revert Error.INVALID_PAYLOAD();
        }

        srcSender = srcSender_;
        srcChainId = srcChainId_;
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    function _isValidPayloadId(uint256 payloadId_, IBaseStateRegistry stateRegistry) internal view {
        if (payloadId_ > stateRegistry.payloadsCount()) {
            revert Error.INVALID_PAYLOAD_ID();
        }
    }

    function _getCoreStateRegistry() internal view returns (IBaseStateRegistry) {
        return IBaseStateRegistry(superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY")));
    }

    function _decodePayloadHeader(
        uint256 dstPayloadId_,
        IBaseStateRegistry coreStateRegistry_
    )
        internal
        view
        returns (uint8 txType, uint8 callbackType, uint8 multi, address srcSender, uint64 srcChainId)
    {
        (txType, callbackType, multi,, srcSender, srcChainId) =
            coreStateRegistry_.payloadHeader(dstPayloadId_).decodeTxInfo();
    }

    function _decodeReturnData(
        uint256 dstPayloadId_,
        uint8 multi_,
        IBaseStateRegistry coreStateRegistry_
    )
        internal
        view
        returns (uint256[] memory amounts, uint256 srcPayloadId)
    {
        if (multi_ == 1) {
            ReturnMultiData memory rd = abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (ReturnMultiData));
            return (rd.amounts, rd.payloadId);
        } else {
            ReturnSingleData memory rsd = abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (ReturnSingleData));
            amounts = new uint256[](1);
            amounts[0] = rsd.amount;
            return (amounts, rsd.payloadId);
        }
    }

    function _decodeInitData(
        uint256 dstPayloadId_,
        uint8 multi_,
        IBaseStateRegistry coreStateRegistry_
    )
        internal
        view
        returns (
            uint256[] memory amounts,
            uint256[] memory slippages,
            uint256[] memory superformIds,
            bool[] memory hasDstSwaps,
            bytes memory extraFormData,
            address receiverAddress,
            uint256 srcPayloadId
        )
    {
        if (multi_ == 1) {
            InitMultiVaultData memory imvd =
                abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (InitMultiVaultData));

            return (
                imvd.amounts,
                imvd.maxSlippages,
                imvd.superformIds,
                imvd.hasDstSwaps,
                imvd.extraFormData,
                imvd.receiverAddress,
                imvd.payloadId
            );
        } else {
            InitSingleVaultData memory isvd =
                abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (InitSingleVaultData));

            amounts = new uint256[](1);
            amounts[0] = isvd.amount;

            slippages = new uint256[](1);
            slippages[0] = isvd.maxSlippage;

            superformIds = new uint256[](1);
            superformIds[0] = isvd.superformId;
            hasDstSwaps = new bool[](1);
            hasDstSwaps[0] = isvd.hasDstSwap;
            receiverAddress = isvd.receiverAddress;

            return (
                amounts, slippages, superformIds, hasDstSwaps, isvd.extraFormData, isvd.receiverAddress, isvd.payloadId
            );
        }
    }

    function _decodeMultiLiqData(
        uint256 dstPayloadId_,
        IBaseStateRegistry coreStateRegistry_
    )
        internal
        view
        returns (
            uint8[] memory bridgeIds,
            bytes[] memory txDatas,
            address[] memory tokens,
            uint64[] memory liqDstChainIds,
            uint256[] memory amountsIn,
            uint256[] memory nativeAmounts
        )
    {
        InitMultiVaultData memory imvd = abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (InitMultiVaultData));

        bridgeIds = new uint8[](imvd.liqData.length);
        txDatas = new bytes[](imvd.liqData.length);
        tokens = new address[](imvd.liqData.length);
        liqDstChainIds = new uint64[](imvd.liqData.length);
        amountsIn = new uint256[](imvd.liqData.length);
        nativeAmounts = new uint256[](imvd.liqData.length);

        uint256 len = imvd.liqData.length;

        for (uint256 i = 0; i < len; ++i) {
            bridgeIds[i] = imvd.liqData[i].bridgeId;
            txDatas[i] = imvd.liqData[i].txData;
            tokens[i] = imvd.liqData[i].token;
            liqDstChainIds[i] = imvd.liqData[i].liqDstChainId;

            /// @dev decodes amount from txdata only if its present
            if (imvd.liqData[i].txData.length != 0) {
                amountsIn[i] =
                    IBridgeValidator(superRegistry.getBridgeValidator(bridgeIds[i])).decodeAmountIn(txDatas[i], false);
            }

            nativeAmounts[i] = imvd.liqData[i].nativeAmount;
        }

        return (bridgeIds, txDatas, tokens, liqDstChainIds, amountsIn, nativeAmounts);
    }

    function _decodeSingleLiqData(
        uint256 dstPayloadId_,
        IBaseStateRegistry coreStateRegistry_
    )
        internal
        view
        returns (
            uint8[] memory bridgeIds,
            bytes[] memory txDatas,
            address[] memory tokens,
            uint64[] memory liqDstChainIds,
            uint256[] memory amountsIn,
            uint256[] memory nativeAmounts
        )
    {
        InitSingleVaultData memory isvd =
            abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (InitSingleVaultData));

        bridgeIds = new uint8[](1);
        bridgeIds[0] = isvd.liqData.bridgeId;

        txDatas = new bytes[](1);
        txDatas[0] = isvd.liqData.txData;

        tokens = new address[](1);
        tokens[0] = isvd.liqData.token;

        liqDstChainIds = new uint64[](1);
        liqDstChainIds[0] = isvd.liqData.liqDstChainId;

        amountsIn = new uint256[](1);

        /// @dev decodes amount from txdata only if its present
        if (isvd.liqData.txData.length != 0) {
            amountsIn[0] =
                IBridgeValidator(superRegistry.getBridgeValidator(bridgeIds[0])).decodeAmountIn(txDatas[0], false);
        }

        nativeAmounts = new uint256[](1);
        nativeAmounts[0] = isvd.liqData.nativeAmount;

        return (bridgeIds, txDatas, tokens, liqDstChainIds, amountsIn, nativeAmounts);
    }
}

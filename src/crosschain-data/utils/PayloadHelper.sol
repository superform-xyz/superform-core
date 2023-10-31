// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";
import { ISuperPositions } from "../../interfaces/ISuperPositions.sol";
import { IBaseStateRegistry } from "../../interfaces/IBaseStateRegistry.sol";
import { ITimelockStateRegistry } from "../../interfaces/ITimelockStateRegistry.sol";
import { IPayloadHelper } from "../../interfaces/IPayloadHelper.sol";
import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";
import { Error } from "../../utils/Error.sol";
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
        uint256[] slippages;
        uint256[] superformIds;
        bool[] hasDstSwaps;
        uint256 srcPayloadId;
        address receiverAddress;
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

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    ISuperRegistry public immutable superRegistry;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
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
            uint256[] memory slippages,
            uint256[] memory superformIds,
            uint256 srcPayloadId,
            bool[] memory hasDstSwaps,
            address receiverAddress
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
            (v.amounts, v.slippages, v.superformIds, v.srcPayloadId, v.hasDstSwaps, v.receiverAddress) =
                _decodeInitData(dstPayloadId_, v.multi, coreStateRegistry);
        }

        return (
            v.txType,
            v.callbackType,
            v.srcSender,
            v.srcChainId,
            v.amounts,
            v.slippages,
            v.superformIds,
            v.srcPayloadId,
            v.hasDstSwaps,
            v.receiverAddress
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
        TimelockPayload memory payload = ITimelockStateRegistry(
            superRegistry.getAddress(keccak256("TIMELOCK_STATE_REGISTRY"))
        ).getTimelockPayload(timelockPayloadId_);

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
        IBaseStateRegistry timelockPayloadRegistry =
            IBaseStateRegistry(superRegistry.getAddress(keccak256("TIMELOCK_STATE_REGISTRY")));
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

    /*///////////////////////////////////////////////////////////////
                        INTERNAL HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _isValidPayloadId(uint256 payloadId_, IBaseStateRegistry coreStateRegistry) internal view {
        if (payloadId_ > coreStateRegistry.payloadsCount()) {
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
        return (txType, callbackType, multi, srcSender, srcChainId);
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
            uint256 srcPayloadId,
            bool[] memory hasDstSwaps,
            address receiverAddress
        )
    {
        if (multi_ == 1) {
            InitMultiVaultData memory imvd =
                abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (InitMultiVaultData));

            return (
                imvd.amounts,
                imvd.maxSlippages,
                imvd.superformIds,
                imvd.payloadId,
                imvd.hasDstSwaps,
                imvd.receiverAddress
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

            return (amounts, slippages, superformIds, isvd.payloadId, hasDstSwaps, receiverAddress);
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

        for (uint256 i = 0; i < len;) {
            bridgeIds[i] = imvd.liqData[i].bridgeId;
            txDatas[i] = imvd.liqData[i].txData;
            tokens[i] = imvd.liqData[i].token;
            liqDstChainIds[i] = imvd.liqData[i].liqDstChainId;
            amountsIn[i] =
                IBridgeValidator(superRegistry.getBridgeValidator(bridgeIds[i])).decodeAmountIn(txDatas[i], false);
            nativeAmounts[i] = imvd.liqData[i].nativeAmount;
            unchecked {
                ++i;
            }
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
        amountsIn[0] =
            IBridgeValidator(superRegistry.getBridgeValidator(bridgeIds[0])).decodeAmountIn(txDatas[0], false);

        nativeAmounts = new uint256[](1);
        nativeAmounts[0] = isvd.liqData.nativeAmount;

        return (bridgeIds, txDatas, tokens, liqDstChainIds, amountsIn, nativeAmounts);
    }
}

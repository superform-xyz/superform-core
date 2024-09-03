// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { IAsyncStateRegistry, SyncWithdrawTxDataPayload } from "src/interfaces/IAsyncStateRegistry.sol";
import { IPayloadHelper } from "src/interfaces/IPayloadHelper.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { ISuperPositions } from "src/interfaces/ISuperPositions.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { ProofLib } from "src/libraries/ProofLib.sol";
import { Error } from "src/libraries/Error.sol";
import {
    CallbackType,
    ReturnMultiData,
    ReturnSingleData,
    InitMultiVaultData,
    InitSingleVaultData,
    TimelockPayload,
    AMBMessage
} from "src/types/DataTypes.sol";

/// @title PayloadHelper
/// @dev Helps decode payload data for off-chain purposes
/// @author ZeroPoint Labs
contract PayloadHelper is IPayloadHelper {
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    ISuperRegistry public immutable superRegistry;

    //////////////////////////////////////////////////////////////
    //                           STRUCTS                        //
    //////////////////////////////////////////////////////////////

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
        if (superRegistry_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }
        superRegistry = ISuperRegistry(superRegistry_);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IPayloadHelper
    function decodeCoreStateRegistryPayload(
        uint256 dstPayloadId_
    )
        external
        view
        override
        returns (DecodedDstPayload memory v)
    {
        _isValidPayloadId(dstPayloadId_, _getCoreStateRegistry());
        _decodePayloadHeader(v, dstPayloadId_, _getCoreStateRegistry());

        if (v.callbackType == uint256(CallbackType.RETURN) || v.callbackType == uint256(CallbackType.FAIL)) {
            _decodeReturnData(v, dstPayloadId_, _getCoreStateRegistry());
        } else if (v.callbackType == uint256(CallbackType.INIT)) {
            _decodeInitData(v, dstPayloadId_, v.multi, _getCoreStateRegistry());
        } else {
            revert Error.INVALID_PAYLOAD();
        }
    }

    /// @inheritdoc IPayloadHelper
    function decodeCoreStateRegistryPayloadLiqData(
        uint256 dstPayloadId_
    )
        external
        view
        override
        returns (
            bytes[] memory txDatas,
            address[] memory tokens,
            address[] memory interimTokens,
            uint8[] memory bridgeIds,
            uint64[] memory liqDstChainIds,
            uint256[] memory amountsIn,
            uint256[] memory nativeAmounts
        )
    {
        IBaseStateRegistry coreStateRegistry = _getCoreStateRegistry();
        _isValidPayloadId(dstPayloadId_, coreStateRegistry);

        DecodeDstPayloadLiqDataInternalVars memory v;
        (, v.callbackType, v.multi,,,) = coreStateRegistry.payloadHeader(dstPayloadId_).decodeTxInfo();

        if (v.multi == 1) {
            return _decodeMultiLiqData(dstPayloadId_, coreStateRegistry);
        } else {
            return _decodeSingleLiqData(dstPayloadId_, coreStateRegistry);
        }
    }

    /// @inheritdoc IPayloadHelper
    function decodePayloadHistory(
        uint256 srcPayloadId_
    )
        external
        view
        override
        returns (
            uint8 txType,
            uint8 callbackType,
            uint8 multi,
            address srcSender,
            address receiverAddressSP,
            uint64 srcChainId
        )
    {
        uint256 txInfo;
        (txInfo, receiverAddressSP) =
            ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).txHistory(srcPayloadId_);

        if (txInfo == 0) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        (txType, callbackType, multi,, srcSender, srcChainId) = txInfo.decodeTxInfo();
    }

    /// @inheritdoc IPayloadHelper
    function decodeSyncWithdrawPayload(
        uint256 syncWithdrawPayloadId_
    )
        external
        view
        override
        returns (address receiverAddress, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount)
    {
        IAsyncStateRegistry asyncStateRegistry =
            IAsyncStateRegistry(superRegistry.getAddress(keccak256("ASYNC_STATE_REGISTRY")));

        if (syncWithdrawPayloadId_ > asyncStateRegistry.syncWithdrawTxDataPayloadCounter()) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        SyncWithdrawTxDataPayload memory payload =
            asyncStateRegistry.getSyncWithdrawTxDataPayload(syncWithdrawPayloadId_);

        return (
            payload.data.receiverAddress,
            payload.srcChainId,
            payload.data.payloadId,
            payload.data.superformId,
            payload.data.amount
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
    function decodeTimeLockFailedPayload(
        uint256 payloadId_
    )
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

    /// @inheritdoc IPayloadHelper
    function decodeAsyncAckPayload(
        uint256 payloadId_
    )
        external
        view
        override
        returns (address srcSender, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount)
    {
        IBaseStateRegistry asyncStateRegistry =
            IBaseStateRegistry(superRegistry.getAddress(keccak256("ASYNC_STATE_REGISTRY")));

        _isValidPayloadId(payloadId_, asyncStateRegistry);

        bytes memory payloadBody = asyncStateRegistry.payloadBody(payloadId_);
        uint256 payloadHeader = asyncStateRegistry.payloadHeader(payloadId_);

        (, uint8 callbackType_,,, address srcSender_, uint64 srcChainId_) = payloadHeader.decodeTxInfo();

        /// @dev callback type can never be INIT
        if (callbackType_ == uint256(CallbackType.RETURN) || callbackType_ == uint256(CallbackType.FAIL)) {
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
        DecodedDstPayload memory v_,
        uint256 dstPayloadId_,
        IBaseStateRegistry coreStateRegistry_
    )
        internal
        view
    {
        (v_.txType, v_.callbackType, v_.multi,, v_.srcSender, v_.srcChainId) =
            coreStateRegistry_.payloadHeader(dstPayloadId_).decodeTxInfo();
    }

    function _decodeReturnData(
        DecodedDstPayload memory v_,
        uint256 dstPayloadId_,
        IBaseStateRegistry coreStateRegistry_
    )
        internal
        view
    {
        if (v_.multi == 1) {
            ReturnMultiData memory rd = abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (ReturnMultiData));
            v_.amounts = rd.amounts;
            v_.srcPayloadId = rd.payloadId;
        } else {
            ReturnSingleData memory rsd = abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (ReturnSingleData));
            v_.amounts = new uint256[](1);
            v_.amounts[0] = rsd.amount;

            v_.srcPayloadId = rsd.payloadId;
        }
    }

    function _decodeInitData(
        DecodedDstPayload memory v_,
        uint256 dstPayloadId_,
        uint8 multi_,
        IBaseStateRegistry coreStateRegistry_
    )
        internal
        view
    {
        if (v_.multi == 1) {
            InitMultiVaultData memory imvd =
                abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (InitMultiVaultData));

            v_.amounts = imvd.amounts;
            v_.outputAmounts = imvd.outputAmounts;
            v_.slippages = imvd.maxSlippages;
            v_.superformIds = imvd.superformIds;
            v_.hasDstSwaps = imvd.hasDstSwaps;
            v_.extraFormData = imvd.extraFormData;
            v_.receiverAddress = imvd.receiverAddress;
            v_.srcPayloadId = imvd.payloadId;
            v_.retain4626 = imvd.retain4626s;
        } else {
            InitSingleVaultData memory isvd =
                abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (InitSingleVaultData));

            v_.amounts = new uint256[](1);
            v_.amounts[0] = isvd.amount;

            v_.outputAmounts = new uint256[](1);
            v_.outputAmounts[0] = isvd.outputAmount;

            v_.slippages = new uint256[](1);
            v_.slippages[0] = isvd.maxSlippage;

            v_.superformIds = new uint256[](1);
            v_.superformIds[0] = isvd.superformId;

            v_.hasDstSwaps = new bool[](1);
            v_.hasDstSwaps[0] = isvd.hasDstSwap;

            v_.retain4626 = new bool[](1);
            v_.retain4626[0] = isvd.retain4626;

            v_.extraFormData = isvd.extraFormData;
            v_.receiverAddress = isvd.receiverAddress;
            v_.srcPayloadId = isvd.payloadId;
        }
    }

    function _decodeMultiLiqData(
        uint256 dstPayloadId_,
        IBaseStateRegistry coreStateRegistry_
    )
        internal
        view
        returns (
            bytes[] memory txDatas,
            address[] memory tokens,
            address[] memory interimTokens,
            uint8[] memory bridgeIds,
            uint64[] memory liqDstChainIds,
            uint256[] memory amountsIn,
            uint256[] memory nativeAmounts
        )
    {
        InitMultiVaultData memory imvd = abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (InitMultiVaultData));

        bridgeIds = new uint8[](imvd.liqData.length);
        txDatas = new bytes[](imvd.liqData.length);
        tokens = new address[](imvd.liqData.length);
        interimTokens = new address[](imvd.liqData.length);
        liqDstChainIds = new uint64[](imvd.liqData.length);
        amountsIn = new uint256[](imvd.liqData.length);
        nativeAmounts = new uint256[](imvd.liqData.length);

        uint256 len = imvd.liqData.length;

        for (uint256 i; i < len; ++i) {
            bridgeIds[i] = imvd.liqData[i].bridgeId;
            txDatas[i] = imvd.liqData[i].txData;
            tokens[i] = imvd.liqData[i].token;
            interimTokens[i] = imvd.liqData[i].interimToken;
            liqDstChainIds[i] = imvd.liqData[i].liqDstChainId;

            /// @dev decodes amount from txdata only if its present
            if (imvd.liqData[i].txData.length != 0) {
                amountsIn[i] =
                    IBridgeValidator(superRegistry.getBridgeValidator(bridgeIds[i])).decodeAmountIn(txDatas[i], false);
            }

            nativeAmounts[i] = imvd.liqData[i].nativeAmount;
        }
    }

    function _decodeSingleLiqData(
        uint256 dstPayloadId_,
        IBaseStateRegistry coreStateRegistry_
    )
        internal
        view
        returns (
            bytes[] memory txDatas,
            address[] memory tokens,
            address[] memory interimTokens,
            uint8[] memory bridgeIds,
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

        interimTokens = new address[](1);
        interimTokens[0] = isvd.liqData.interimToken;

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
    }
}

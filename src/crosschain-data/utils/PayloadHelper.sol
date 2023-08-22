// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { ISuperPositions } from "../../interfaces/ISuperPositions.sol";
import { IBaseStateRegistry } from "../../interfaces/IBaseStateRegistry.sol";
import { ITwoStepsFormStateRegistry } from "../../interfaces/ITwoStepsFormStateRegistry.sol";
import { IPayloadHelper } from "../../interfaces/IPayloadHelper.sol";
import {
    CallbackType,
    ReturnMultiData,
    ReturnSingleData,
    InitMultiVaultData,
    InitSingleVaultData,
    TwoStepsPayload
} from "../../types/DataTypes.sol";
import { DataLib } from "../../libraries/DataLib.sol";

/// @title PayloadHelper
/// @author ZeroPoint Labs
/// @dev helps decode payload data more easily. Used for off-chain purposes
contract PayloadHelper is IPayloadHelper {
    using DataLib for uint256;

    IBaseStateRegistry public immutable dstPayloadRegistry;
    ISuperPositions public immutable srcPayloadRegistry;

    ITwoStepsFormStateRegistry public immutable twoStepRegistry;

    constructor(address dstPayloadRegistry_, address srcPayloadRegistry_, address twoStepRegistry_) {
        dstPayloadRegistry = IBaseStateRegistry(dstPayloadRegistry_);
        srcPayloadRegistry = ISuperPositions(srcPayloadRegistry_);
        twoStepRegistry = ITwoStepsFormStateRegistry(twoStepRegistry_);
    }

    /// @inheritdoc IPayloadHelper
    function decodeDstPayload(uint256 dstPayloadId_)
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
            uint256 srcPayloadId
        )
    {
        bytes memory payloadBody = dstPayloadRegistry.payloadBody(dstPayloadId_);
        uint256 payloadHeader = dstPayloadRegistry.payloadHeader(dstPayloadId_);

        (uint8 txType_, uint8 callbackType_, uint8 multi_,, address srcSender_, uint64 srcChainId_) =
            payloadHeader.decodeTxInfo();

        if (callbackType_ == uint256(CallbackType.RETURN) || callbackType == uint256(CallbackType.FAIL)) {
            if (multi_ == 1) {
                ReturnMultiData memory rd = abi.decode(payloadBody, (ReturnMultiData));
                amounts = rd.amounts;
                srcPayloadId = rd.payloadId;
            } else {
                ReturnSingleData memory rsd = abi.decode(payloadBody, (ReturnSingleData));
                uint256[] memory amounts_ = new uint256[](1);
                amounts_[0] = rsd.amount;

                amounts = amounts_;
                srcPayloadId = rsd.payloadId;
            }
        }

        if (callbackType_ == uint256(CallbackType.INIT)) {
            if (multi_ == 1) {
                InitMultiVaultData memory imvd = abi.decode(payloadBody, (InitMultiVaultData));
                amounts = imvd.amounts;
                slippage = imvd.maxSlippage;
                superformIds = imvd.superformIds;
                srcPayloadId = imvd.payloadId;
            } else {
                InitSingleVaultData memory isvd = abi.decode(payloadBody, (InitSingleVaultData));

                uint256[] memory amounts_ = new uint256[](1);
                amounts_[0] = isvd.amount;
                amounts = amounts_;

                uint256[] memory slippage_ = new uint256[](1);
                slippage_[0] = isvd.maxSlippage;
                slippage = slippage_;

                uint256[] memory superformIds_ = new uint256[](1);
                superformIds_[0] = isvd.superformId;
                superformIds = superformIds_;

                srcPayloadId = isvd.payloadId;
            }
        }

        return (txType_, callbackType_, srcSender_, srcChainId_, amounts, slippage, superformIds, srcPayloadId);
    }

    /// @inheritdoc IPayloadHelper
    function decodeSrcPayload(uint256 srcPayloadId_)
        external
        view
        override
        returns (uint8 txType, uint8 callbackType, uint8 multi, address srcSender, uint64 srcChainId)
    {
        uint256 txInfo = srcPayloadRegistry.txHistory(srcPayloadId_);

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
        TwoStepsPayload memory payload = twoStepRegistry.getTwoStepsPayload(timelockPayloadId_);

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

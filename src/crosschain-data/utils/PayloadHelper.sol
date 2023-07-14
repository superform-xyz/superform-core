// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {ITwoStepsFormStateRegistry} from "../../interfaces/ITwoStepsFormStateRegistry.sol";

import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {IPayloadHelper} from "../../interfaces/IPayloadHelper.sol";
import {AMBMessage, CallbackType, ReturnMultiData, ReturnSingleData, InitMultiVaultData, InitSingleVaultData, TimeLockPayload} from "../../types/DataTypes.sol";
import {DataLib} from "../../libraries/DataLib.sol";

contract PayloadHelper is IPayloadHelper {
    using DataLib for uint256;

    IBaseStateRegistry public immutable payloadRegistry;
    ITwoStepsFormStateRegistry public immutable twoStepRegistry;

    constructor(address payloadRegistry_, address twoStepRegistry_) {
        payloadRegistry = IBaseStateRegistry(payloadRegistry_);
        twoStepRegistry = ITwoStepsFormStateRegistry(twoStepRegistry_);
    }

    /// @inheritdoc IPayloadHelper
    function decodePayload(
        uint256 dstPayloadId_
    )
        external
        view
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
        bytes memory payloadBody = payloadRegistry.payloadBody(dstPayloadId_);
        uint256 payloadHeader = payloadRegistry.payloadHeader(dstPayloadId_);

        (uint8 txType_, uint8 callbackType_, uint8 multi_, , address srcSender_, uint64 srcChainId_) = payloadHeader
            .decodeTxInfo();

        if (callbackType_ == uint256(CallbackType.RETURN)) {
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
                superformIds = imvd.superFormIds;
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
                superformIds_[0] = isvd.superFormId;
                superformIds = superformIds_;

                srcPayloadId = isvd.payloadId;
            }
        }

        return (txType_, callbackType_, srcSender_, srcChainId_, amounts, slippage, superformIds, srcPayloadId);
    }

    /// @inheritdoc IPayloadHelper
    function decodeTimeLockPayload(
        uint256 timelockPayloadId_
    )
        external
        view
        returns (address srcSender, uint64 srcChainId, uint256 srcPayloadId, uint256 superFormId, uint256 amount)
    {
        TimeLockPayload memory payload = twoStepRegistry.getTimeLockPayload(timelockPayloadId_);

        return (
            payload.srcSender,
            payload.srcChainId,
            payload.data.payloadId,
            payload.data.superFormId,
            payload.data.amount
        );
    }
}

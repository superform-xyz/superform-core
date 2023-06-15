// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {ICoreStateRegistryHelper} from "../../interfaces/ICoreStateRegistryHelper.sol";
import {AMBMessage, CallbackType, ReturnMultiData, ReturnSingleData, TransactionType, InitMultiVaultData, InitSingleVaultData} from "../../types/DataTypes.sol";

import "forge-std/console.sol";
import "../../utils/DataPacking.sol";

contract CoreStateRegistryHelper is ICoreStateRegistryHelper {
    IBaseStateRegistry public immutable payloadRegistry;

    constructor(address payloadRegistry_) {
        payloadRegistry = IBaseStateRegistry(payloadRegistry_);
    }

    /// @inheritdoc ICoreStateRegistryHelper
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
        bytes memory payload = payloadRegistry.payload(dstPayloadId_);
        AMBMessage memory message = abi.decode(payload, (AMBMessage));

        (uint8 txType_, uint8 callbackType_, uint8 multi_, , address srcSender_, uint64 srcChainId_) = _decodeTxInfo(
            message.txInfo
        );

        if (callbackType_ == uint256(CallbackType.RETURN)) {
            if (multi_ == 1) {
                ReturnMultiData memory rd = abi.decode(message.params, (ReturnMultiData));
                amounts = rd.amounts;
                srcPayloadId = rd.payloadId;
            } else {
                ReturnSingleData memory rsd = abi.decode(message.params, (ReturnSingleData));
                uint256[] memory amounts_ = new uint256[](1);
                amounts_[0] = rsd.amount;

                amounts = amounts_;
                srcPayloadId = rsd.payloadId;
            }
        }

        if (callbackType_ == uint256(CallbackType.INIT)) {
            if (multi_ == 1) {
                InitMultiVaultData memory imvd = abi.decode(message.params, (InitMultiVaultData));
                amounts = imvd.amounts;
                slippage = imvd.maxSlippage;
                superformIds = imvd.superFormIds;
                srcPayloadId = imvd.payloadId;
            } else {
                InitSingleVaultData memory isvd = abi.decode(message.params, (InitSingleVaultData));

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
}

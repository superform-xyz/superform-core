// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {ICoreStateRegistryHelper} from "../../interfaces/ICoreStateRegistryHelper.sol";
import {AMBMessage, CallbackType, ReturnMultiData, ReturnSingleData, InitMultiVaultData, InitSingleVaultData} from "../../types/DataTypes.sol";
import {DataLib} from "../../libraries/DataLib.sol";

contract CoreStateRegistryHelper is ICoreStateRegistryHelper {
    using DataLib for uint256;

    IBaseStateRegistry public immutable payloadRegistry;
    ISuperRegistry public immutable superRegistry;

    constructor(address payloadRegistry_, address superRegistry_) {
        payloadRegistry = IBaseStateRegistry(payloadRegistry_);
        superRegistry = ISuperRegistry(superRegistry_);
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

    /// @inheritdoc ICoreStateRegistryHelper
    function estimateFees(
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes[] memory extraData_
    ) external view returns (uint256 totalFees, uint256[] memory) {
        uint256 len = ambIds_.length;
        uint256[] memory fees = new uint256[](len);
        for (uint256 i; i < len; ) {
            fees[i] = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(
                dstChainId_,
                message_,
                extraData_[i]
            );

            totalFees += fees[i];

            unchecked {
                ++i;
            }
        }
    }
}

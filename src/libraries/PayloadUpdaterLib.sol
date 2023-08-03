// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import {DataLib} from "./DataLib.sol";
import {Error} from "../utils/Error.sol";
import {PayloadState, TransactionType, CallbackType} from "../types/DataTypes.sol";

/// @dev library to validate slippage updation
library PayloadUpdaterLib {
    function validateSlippage(uint256 newAmount, uint256 maxAmount, uint256 slippage) internal pure {
        if (newAmount > maxAmount) {
            revert Error.NEGATIVE_SLIPPAGE();
        }

        uint256 minAmount = (maxAmount * (10000 - slippage)) / 10000;

        if (newAmount < minAmount) {
            revert Error.SLIPPAGE_OUT_OF_BOUNDS();
        }
    }

    function validateSlippageArray(
        uint256[] memory newAmount,
        uint256[] memory maxAmount,
        uint256[] memory slippage
    ) internal pure {
        for (uint256 i; i < newAmount.length; ) {
            validateSlippage(newAmount[i], maxAmount[i], slippage[i]);

            unchecked {
                ++i;
            }
        }
    }

    function validatePayloadUpdate(uint256 txInfo_, PayloadState currentPayloadState_, uint8 isMulti) internal pure {
        (uint256 txType, uint256 callbackType, uint8 multi, , , ) = DataLib.decodeTxInfo(txInfo_);

        if (!(txType == uint256(TransactionType.DEPOSIT) && callbackType == uint256(CallbackType.INIT))) {
            revert Error.INVALID_PAYLOAD_UPDATE_REQUEST();
        }

        if (currentPayloadState_ != PayloadState.STORED) {
            revert Error.INVALID_PAYLOAD_STATE();
        }

        if (multi != isMulti) {
            revert Error.INVALID_PAYLOAD_UPDATE_REQUEST();
        }
    }
}

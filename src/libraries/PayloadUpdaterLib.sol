// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import { DataLib } from "./DataLib.sol";
import { Error } from "../utils/Error.sol";
import { LiqRequest } from "../types/LiquidityTypes.sol";
import { PayloadState, TransactionType, CallbackType } from "../types/DataTypes.sol";

/// @dev library to validate slippage updation
library PayloadUpdaterLib {
    function validateSlippage(
        uint256 newAmount_,
        uint256 maxAmount_,
        uint256 slippage_
    )
        internal
        pure
        returns (bool valid_)
    {
        /// @dev args validation
        if (newAmount_ > maxAmount_) {
            revert Error.NEGATIVE_SLIPPAGE();
        }

        uint256 minAmount = (maxAmount_ * (10_000 - slippage_)) / 10_000;

        /// @dev amount must fall within the slippage bounds
        if (newAmount_ < minAmount) {
            return false;
        }

        return true;
    }

    function strictValidateSlippage(
        uint256 newAmount_,
        uint256 maxAmount_,
        uint256 slippage_
    )
        internal
        pure
        returns (bool valid_)
    {
        /// @dev args validation
        if (newAmount_ > maxAmount_) {
            revert Error.NEGATIVE_SLIPPAGE();
        }

        uint256 minAmount = (maxAmount_ * (10_000 - slippage_)) / 10_000;

        /// @dev amount must fall within the slippage bounds
        if (newAmount_ < minAmount) {
            revert Error.SLIPPAGE_OUT_OF_BOUNDS();
        }

        return true;
    }

    function validateLiqReq(LiqRequest memory req_) internal pure {
        /// revert if token is address(0) -> user wants settlement without any liq data
        /// revert if token is not address(0) and txData is already present
        if (req_.token == address(0) || (req_.token != address(0) && req_.txData.length > 0)) {
            revert Error.CANNOT_UPDATE_WITHDRAW_TX_DATA();
        }
    }

    function validatePayloadUpdate(
        uint256 txInfo_,
        uint8 txType_,
        PayloadState currentPayloadState_,
        uint8 isMulti_
    )
        internal
        pure
    {
        (uint256 txType, uint256 callbackType, uint8 multi,,,) = DataLib.decodeTxInfo(txInfo_);

        if (!(txType == txType_ && callbackType == uint256(CallbackType.INIT))) {
            revert Error.INVALID_PAYLOAD_UPDATE_REQUEST();
        }

        if (currentPayloadState_ != PayloadState.STORED) {
            revert Error.PAYLOAD_ALREADY_UPDATED();
        }

        if (multi != isMulti_) {
            revert Error.INVALID_PAYLOAD_UPDATE_REQUEST();
        }
    }
}

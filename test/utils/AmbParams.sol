// SPDX-License-Identifier: BUSL-1.1
import { AMBExtraData, BroadCastAMBExtraData } from "src/types/DataTypes.sol";

pragma solidity ^0.8.23;

function generateBroadcastParams(uint256 gasFee_) pure returns (bytes memory) {
    uint8 ambId = 4;

    uint256 gasFee = gasFee_;
    bytes memory extraData;

    return abi.encode(ambId, abi.encode(gasFee, extraData));
}

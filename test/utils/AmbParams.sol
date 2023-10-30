// SPDX-License-Identifier: Apache-2.0
import { AMBExtraData, BroadCastAMBExtraData } from "src/types/DataTypes.sol";

pragma solidity ^0.8.21;

function generateBroadcastParams(uint256, uint256) pure returns (bytes memory) {
    uint8 ambId = 4;

    uint256 gasFee = 0;
    bytes memory extraData;

    return abi.encode(ambId, abi.encode(gasFee, extraData));
}

// SPDX-License-Identifier: Apache-2.0
import { AMBExtraData, BroadCastAMBExtraData } from "src/types/DataTypes.sol";

pragma solidity ^0.8.19;

function generateBroadcastParams(uint256 dstCount, uint256 ambCount) pure returns (bytes memory) {
    /// @dev TODO - Sujith to comment
    uint8[] memory ambIds = new uint8[](ambCount);
    ambIds[0] = 4;

    uint256[] memory gasPerAMB = new uint256[](ambCount);
    uint256[] memory gasPerDST = new uint256[](dstCount);

    bytes[] memory paramsPerDST = new bytes[](dstCount);
    bytes[] memory paramsPerAMB = new bytes[](ambCount);

    paramsPerAMB[0] = abi.encode(BroadCastAMBExtraData(gasPerDST, paramsPerDST));
    AMBExtraData memory extraData = AMBExtraData(gasPerAMB, paramsPerAMB);

    return abi.encode(ambIds, abi.encode(extraData));
}

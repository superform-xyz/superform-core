// SPDX-License-Identifier: Apache-2.0
import {SingleDstAMBParams, AMBExtraData, BroadCastAMBExtraData, AckAMBData} from "../../types/DataTypes.sol";

pragma solidity 0.8.19;

function generateAmbParams(uint256 dstCount, uint256 ambCount) pure returns (bytes[] memory) {
    uint256[] memory gasPerAMB = new uint256[](ambCount);

    for (uint256 index; index < ambCount; index++) {
        gasPerAMB[index] = 1 ether;
    }

    bytes[] memory paramsPerAMB = new bytes[](ambCount);

    AMBExtraData memory extraData = AMBExtraData(gasPerAMB, paramsPerAMB);

    bytes[] memory paramsPerDST = new bytes[](dstCount);

    for (uint256 i; i < dstCount; i++) {
        paramsPerDST[i] = abi.encode(SingleDstAMBParams(3 ether, abi.encode(extraData)));
    }

    return paramsPerDST;
}

function generateBroadcastParams(uint256 dstCount, uint256 ambCount) pure returns (bytes memory) {
    uint8[] memory ambIds = new uint8[](ambCount);
    ambIds[0] = 1;
    ambIds[1] = 2;

    uint256[] memory gasPerAMB = new uint256[](ambCount);
    gasPerAMB[0] = 400 ether;
    gasPerAMB[1] = 400 ether;

    uint256[] memory gasPerDST = new uint256[](dstCount);
    gasPerDST[0] = 80 ether;
    gasPerDST[1] = 80 ether;
    gasPerDST[2] = 80 ether;
    gasPerDST[3] = 80 ether;
    gasPerDST[4] = 80 ether;

    bytes[] memory paramsPerDST = new bytes[](dstCount);

    bytes[] memory paramsPerAMB = new bytes[](ambCount);
    paramsPerAMB[0] = abi.encode(BroadCastAMBExtraData(gasPerDST, paramsPerDST));
    paramsPerAMB[1] = abi.encode(BroadCastAMBExtraData(gasPerDST, paramsPerDST));

    AMBExtraData memory extraData = AMBExtraData(gasPerAMB, paramsPerAMB);

    return abi.encode(ambIds, abi.encode(extraData));
}

function generateAckParams(uint8[] memory ambIds) pure returns (bytes memory) {
    uint256 ambCount = ambIds.length;
    uint256[] memory gasPerAMB = new uint256[](ambCount);

    for (uint256 index; index < ambCount; index++) {
        gasPerAMB[index] = 80 ether;
    }

    bytes[] memory paramsPerAMB = new bytes[](ambCount);

    AMBExtraData memory extraData = AMBExtraData(gasPerAMB, paramsPerAMB);

    return abi.encode(AckAMBData(ambIds, abi.encode(extraData)));
}

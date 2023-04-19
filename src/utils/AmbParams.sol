// SPDX-License-Identifier: Apache-2.0
import {AMBOverride} from "../types/DataTypes.sol";

pragma solidity 0.8.19;

function encode(uint256 m1, uint256 m2) pure returns (bytes memory) {
    uint256[] memory a = new uint256[](2);
    a[0] = m1 * 1 ether;
    a[1] = m2 * 1 ether;

    bytes[] memory b = new bytes[](2);
    b[0] = "";
    b[1] = "";

    return abi.encode(AMBOverride(a, b));
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

library EIP712Lib {
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    function calculateDomainSeparator(bytes32 nameHash, bytes32 versionHash) internal view returns (bytes32) {
        return keccak256(abi.encode(EIP712_DOMAIN_TYPEHASH, nameHash, versionHash, block.chainid, address(this)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.23;

/// @title  EIP712 Lib
library EIP712Lib {
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    function calculateDomainSeparator(bytes32 nameHash, bytes32 versionHash) internal view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        return keccak256(abi.encode(EIP712_DOMAIN_TYPEHASH, nameHash, versionHash, chainId, address(this)));
    }
}

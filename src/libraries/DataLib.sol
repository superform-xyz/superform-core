// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { Error } from "../utils/Error.sol";

/// @dev rationale for "memory-safe" assembly: https://docs.soliditylang.org/en/v0.8.20/assembly.html#memory-safety
library DataLib {
    function packTxInfo(
        uint8 txType_,
        uint8 callbackType_,
        uint8 multi_,
        uint8 registryId_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        pure
        returns (uint256 txInfo)
    {
        txInfo = uint256(txType_);
        txInfo |= uint256(callbackType_) << 8;
        txInfo |= uint256(multi_) << 16;
        txInfo |= uint256(registryId_) << 24;
        txInfo |= uint256(uint160(srcSender_)) << 32;
        txInfo |= uint256(srcChainId_) << 192;
    }

    function decodeTxInfo(uint256 txInfo_)
        internal
        pure
        returns (uint8 txType, uint8 callbackType, uint8 multi, uint8 registryId, address srcSender, uint64 srcChainId)
    {
        txType = uint8(txInfo_);
        callbackType = uint8(txInfo_ >> 8);
        multi = uint8(txInfo_ >> 16);
        registryId = uint8(txInfo_ >> 24);
        srcSender = address(uint160(txInfo_ >> 32));
        srcChainId = uint64(txInfo_ >> 192);
    }

    /// @dev returns the vault-form-chain pair of a superform
    /// @param superformId_ is the id of the superform
    /// @return superform_ is the address of the superform
    /// @return formImplementationId_ is the form id
    /// @return chainId_ is the chain id
    function getSuperform(uint256 superformId_)
        internal
        pure
        returns (address superform_, uint32 formImplementationId_, uint64 chainId_)
    {
        superform_ = address(uint160(superformId_));
        formImplementationId_ = uint32(superformId_ >> 160);
        chainId_ = uint64(superformId_ >> 192);
    }

    /// @dev returns the vault-form-chain pair of an array of superforms
    /// @param superformIds_  array of superforms
    /// @return superforms_ are the address of the vaults
    /// @return formIds_ are the form ids
    /// @return chainIds_ are the chain ids
    function getSuperforms(uint256[] memory superformIds_)
        internal
        pure
        returns (address[] memory superforms_, uint32[] memory formIds_, uint64[] memory chainIds_)
    {
        superforms_ = new address[](superformIds_.length);
        formIds_ = new uint32[](superformIds_.length);
        chainIds_ = new uint64[](superformIds_.length);

        assembly ("memory-safe") {
            /// @dev pointer to the end of the superformIds_ array (shl(5, mload(superformIds_)) == mul(32,
            /// mload(superformIds_))
            let end := add(add(superformIds_, 0x20), shl(5, mload(superformIds_)))
            /// @dev initialize pointers for all the 4 arrays
            let i := add(superformIds_, 0x20)
            let j := add(superforms_, 0x20)
            let k := add(formIds_, 0x20)
            let l := add(chainIds_, 0x20)

            let superformId := 0
            for { } 1 { } {
                superformId := mload(i)
                /// @dev execute what getSuperform() does on a single superformId and store the results in the
                /// respective arrays
                mstore(j, superformId)
                mstore(k, shr(160, superformId))
                mstore(l, shr(192, superformId))
                /// @dev increment pointers
                i := add(i, 0x20)
                j := add(j, 0x20)
                k := add(k, 0x20)
                l := add(l, 0x20)
                /// @dev check if we've reached the end of the array
                if iszero(lt(i, end)) { break }
            }
        }
    }

    /// @dev returns the destination chain of a given superform
    /// @param superformId_ is the id of the superform
    /// @return chainId_ is the chain id
    function getDestinationChain(uint256 superformId_) internal pure returns (uint64 chainId_) {
        chainId_ = uint64(superformId_ >> 192);

        if (chainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }
    }

    /// @dev generates the superformId
    /// @param superform_ is the address of the superform
    /// @param formImplementationId_ is the type of the form
    /// @param chainId_ is the chain id on which the superform is deployed
    function packSuperform(
        address superform_,
        uint32 formImplementationId_,
        uint64 chainId_
    )
        internal
        pure
        returns (uint256 superformId_)
    {
        assembly ("memory-safe") {
            superformId_ := superform_
            superformId_ := or(superformId_, shl(160, formImplementationId_))
            superformId_ := or(superformId_, shl(192, chainId_))
        }
    }
}

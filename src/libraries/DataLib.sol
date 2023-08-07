// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {Error} from "../utils/Error.sol";

/// @dev rationale for "memory-safe" assembly: https://docs.soliditylang.org/en/v0.8.20/assembly.html#memory-safety
library DataLib {
    function packTxInfo(
        uint8 txType_,
        uint8 callbackType_,
        uint8 multi_,
        uint8 registryId_,
        address srcSender_,
        uint64 srcChainId_
    ) internal pure returns (uint256 txInfo) {
        assembly ("memory-safe") {
            txInfo := txType_
            txInfo := or(txInfo, shl(8, callbackType_))
            txInfo := or(txInfo, shl(16, multi_))
            txInfo := or(txInfo, shl(24, registryId_))
            txInfo := or(txInfo, shl(32, srcSender_))
            txInfo := or(txInfo, shl(192, srcChainId_))
        }
    }

    function decodeTxInfo(
        uint256 txInfo_
    )
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
    /// @param superFormId_ is the id of the superform
    /// @return superForm_ is the address of the superform
    /// @return formBeaconId_ is the form id
    /// @return chainId_ is the chain id
    function getSuperform(
        uint256 superFormId_
    ) internal pure returns (address superForm_, uint32 formBeaconId_, uint64 chainId_) {
        superForm_ = address(uint160(superFormId_));
        formBeaconId_ = uint32(superFormId_ >> 160);
        chainId_ = uint64(superFormId_ >> 192);
    }

    /// @dev returns the vault-form-chain pair of an array of superforms
    /// @param superFormIds_  array of superforms
    /// @return superForms_ are the address of the vaults
    /// @return formIds_ are the form ids
    /// @return chainIds_ are the chain ids
    function getSuperforms(
        uint256[] memory superFormIds_
    ) internal pure returns (address[] memory superForms_, uint32[] memory formIds_, uint64[] memory chainIds_) {
        superForms_ = new address[](superFormIds_.length);
        formIds_ = new uint32[](superFormIds_.length);
        chainIds_ = new uint64[](superFormIds_.length);

        assembly ("memory-safe") {
            /// @dev pointer to the end of the superFormIds_ array (shl(5, mload(superFormIds_)) == mul(32, mload(superFormIds_))
            let end := add(add(superFormIds_, 0x20), shl(5, mload(superFormIds_)))
            /// @dev initialize pointers for all the 4 arrays
            let i := add(superFormIds_, 0x20)
            let j := add(superForms_, 0x20)
            let k := add(formIds_, 0x20)
            let l := add(chainIds_, 0x20)

            let superFormId := 0
            for {

            } 1 {

            } {
                superFormId := mload(i)
                /// @dev execute what getSuperform() does on a single superFormId and store the results in the respective arrays
                mstore(j, superFormId)
                mstore(k, shr(160, superFormId))
                mstore(l, shr(192, superFormId))
                /// @dev increment pointers
                i := add(i, 0x20)
                j := add(j, 0x20)
                k := add(k, 0x20)
                l := add(l, 0x20)
                /// @dev check if we've reached the end of the array
                if iszero(lt(i, end)) {
                    break
                }
            }
        }
    }

    /// @dev validates if the superFormId_ belongs to the chainId_
    /// @param superFormId_ to validate
    /// @param chainId_ is the chainId to check if the superform id belongs to
    function validateSuperformChainId(uint256 superFormId_, uint64 chainId_) internal pure {
        /// @dev validates if superFormId exists on factory
        (, , uint64 chainId) = getSuperform(superFormId_);

        if (chainId != chainId_) {
            revert Error.INVALID_CHAIN_ID();
        }
    }

    /// @dev returns the destination chain of a given superForm
    /// @param superFormId_ is the id of the superform
    /// @return chainId_ is the chain id
    function getDestinationChain(uint256 superFormId_) internal pure returns (uint64 chainId_) {
        chainId_ = uint64(superFormId_ >> 192);
    }

    /// @dev generates the superFormId
    /// @param superForm_ is the address of the superForm
    /// @param formBeaconId_ is the type of the form
    /// @param chainId_ is the chain id on which the superForm is deployed
    function packSuperform(
        address superForm_,
        uint32 formBeaconId_,
        uint64 chainId_
    ) internal pure returns (uint256 superFormId_) {
        assembly ("memory-safe") {
            superFormId_ := superForm_
            superFormId_ := or(superFormId_, shl(160, formBeaconId_))
            superFormId_ := or(superFormId_, shl(192, chainId_))
        }
    }
}

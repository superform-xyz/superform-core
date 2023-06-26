// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {Error} from "../utils/Error.sol";

library DataLib {
    function packTxInfo(
        uint8 txType_,
        uint8 callbackType_,
        uint8 multi_,
        uint8 registryId_,
        address srcSender_,
        uint64 srcChainId_
    ) internal pure returns (uint256 txInfo) {
        txInfo = uint256(txType_);
        txInfo |= uint256(callbackType_) << 8;
        txInfo |= uint256(multi_) << 16;
        txInfo |= uint256(registryId_) << 24;
        txInfo |= uint256(uint160(srcSender_)) << 32;
        txInfo |= uint256(srcChainId_) << 192;
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
    function getSuperForm(
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
    function getSuperForms(
        uint256[] memory superFormIds_
    ) internal pure returns (address[] memory, uint32[] memory, uint64[] memory) {
        address[] memory superForms_ = new address[](superFormIds_.length);
        uint32[] memory formIds_ = new uint32[](superFormIds_.length);
        uint64[] memory chainIds_ = new uint64[](superFormIds_.length);
        for (uint256 i = 0; i < superFormIds_.length; i++) {
            (superForms_[i], formIds_[i], chainIds_[i]) = getSuperForm(superFormIds_[i]);
        }

        return (superForms_, formIds_, chainIds_);
    }

    /// @dev validates if the superFormId_ belongs to the chainId_
    /// @param superFormId_ to validate
    /// @param chainId_ is the chainId to check if the superform id belongs to
    function validateSuperFormChainId(uint256 superFormId_, uint64 chainId_) internal pure {
        /// @dev validates if superFormId exists on factory
        (, , uint64 chainId) = getSuperForm(superFormId_);

        if (chainId != chainId_) {
            revert Error.INVALID_CHAIN_ID();
        }
    }
}

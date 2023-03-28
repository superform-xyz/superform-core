// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @dev TODO: needs testing

function _packTxData(
    address srcSender_,
    uint16 srcChainId_,
    uint80 currentTotalTxs_
) pure returns (uint256 txData) {
    txData = uint256(uint160(srcSender_));
    txData |= uint256(srcChainId_) << 160;
    txData |= uint256(currentTotalTxs_) << 176;
}

function _packTxInfo(
    uint120 txType_,
    uint120 callbackType_,
    bool multi_
) pure returns (uint256 txInfo) {
    txInfo = uint256(txType_);
    txInfo |= uint256(callbackType_) << 120;
    txInfo |= uint256(uint8(multi_ ? 1 : 0)) << 240;
}

function _packReturnTxInfo(
    bool status_,
    uint16 srcChainId_,
    uint16 dstChainId_,
    uint80 txId_
) pure returns (uint256 returnTxInfo) {
    returnTxInfo = uint256(uint8(status_ ? 1 : 0));
    returnTxInfo |= uint256(srcChainId_) << 8;
    returnTxInfo |= uint256(dstChainId_) << 24;
    returnTxInfo |= uint256(txId_) << 40;
}

function _packSuperForm(
    address superForm_,
    uint256 formId_,
    uint16 chainId_
) pure returns (uint256 superFormId_) {
    superFormId_ = uint256(uint160(superForm_));
    superFormId_ |= formId_ << 160;
    superFormId_ |= uint256(chainId_) << 240;
}

function _decodeTxData(
    uint256 txData_
) pure returns (address srcSender, uint16 srcChainId, uint80 currentTotalTxs) {
    srcSender = address(uint160(txData_));
    srcChainId = uint16(txData_ >> 160);
    currentTotalTxs = uint80(txData_ >> 176);
}

function _decodeTxInfo(
    uint256 txInfo_
) pure returns (uint256 txType, uint256 callbackType, bool multi) {
    txType = uint256(uint120(txInfo_));
    callbackType = uint256(uint120(txInfo_ >> 120));
    multi = uint256(uint8(txInfo_ >> 240)) == 1 ? true : false;
}

function _decodeReturnTxInfo(
    uint256 returnTxInfo_
)
    pure
    returns (bool status, uint16 srcChainId, uint16 dstChainId, uint80 txId)
{
    status = uint256(uint8(returnTxInfo_)) == 1 ? true : false;
    srcChainId = uint16(returnTxInfo_ >> 8);
    dstChainId = uint16(returnTxInfo_ >> 24);
    txId = uint80(returnTxInfo_ >> 40);
}

/// @dev returns the destination chain of a given superForm
/// @param superFormId_ is the id of the superform
/// @return chainId_ is the chain id
function _getDestinationChain(
    uint256 superFormId_
) pure returns (uint16 chainId_) {
    chainId_ = uint16(superFormId_ >> 240);
}

/// @dev returns the vault-form-chain pair of a superform
/// @param superFormId_ is the id of the superform
/// @return superForm_ is the address of the superform
/// @return formId_ is the form id
/// @return chainId_ is the chain id
function _getSuperForm(
    uint256 superFormId_
) pure returns (address superForm_, uint256 formId_, uint16 chainId_) {
    superForm_ = address(uint160(superFormId_));
    formId_ = uint256(uint80(superFormId_ >> 160));
    chainId_ = uint16(superFormId_ >> 240);
}

/// @dev returns the vault-form-chain pair of an array of superforms
/// @param superFormIds_  array of superforms
/// @return superForms_ are the address of the vaults
/// @return formIds_ are the form ids
/// @return chainIds_ are the chain ids
function _getSuperForms(
    uint256[] memory superFormIds_
) pure returns (address[] memory, uint256[] memory, uint16[] memory) {
    address[] memory superForms_ = new address[](superFormIds_.length);
    uint256[] memory formIds_ = new uint256[](superFormIds_.length);
    uint16[] memory chainIds_ = new uint16[](superFormIds_.length);
    for (uint256 i = 0; i < superFormIds_.length; i++) {
        (superForms_[i], formIds_[i], chainIds_[i]) = _getSuperForm(
            superFormIds_[i]
        );
    }

    return (superForms_, formIds_, chainIds_);
}

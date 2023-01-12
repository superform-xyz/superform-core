// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.14;

interface IStateHandler {
    function dispatchState(
        uint16 dstChainId,
        bytes memory data,
        bytes memory adapterParam
    ) external payable;
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.19;
interface IWormholeReceiver {
    function receiveWormholeMessages(bytes[] memory vaas, bytes[] memory additionalData) external payable;
}
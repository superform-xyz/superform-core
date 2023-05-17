// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

/// @dev is imported from (https://github.com/wormhole-foundation/trustless-generic-relayer/blob/main/ethereum/contracts/interfaces/IWormholeReceiver.sol)
interface IWormholeReceiver {
    function receiveWormholeMessages(
        bytes[] memory vaas,
        bytes[] memory additionalData
    ) external payable;
}

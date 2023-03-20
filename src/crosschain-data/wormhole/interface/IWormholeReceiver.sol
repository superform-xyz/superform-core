// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.19;

/// @dev are inherited contracts for wormhole bridge
///
/// @notice see https://github.com/wormhole-foundation/trustless-generic-relayer/blob/main/ethereum/contracts/interfaces/IWormholeReceiver.sol
/// for more information
interface IWormholeReceiver {
    function receiveWormholeMessages(
        bytes[] memory vaas,
        bytes[] memory additionalData
    ) external payable;
}

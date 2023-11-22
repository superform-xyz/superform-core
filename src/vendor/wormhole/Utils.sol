// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

/// @notice imported from
/// https://github.com/wormhole-foundation/wormhole/blob/738486138462680dfeac5dec94fb0ce376154b94/ethereum/contracts/relayer/libraries/Utils.sol

error NotAnEvmAddress(bytes32);

function fromWormholeFormat(bytes32 whFormatAddress) pure returns (address) {
    if (uint256(whFormatAddress) >> 160 != 0) {
        revert NotAnEvmAddress(whFormatAddress);
    }
    return address(uint160(uint256(whFormatAddress)));
}

function fromWormholeFormatUnchecked(bytes32 whFormatAddress) pure returns (address) {
    return address(uint160(uint256(whFormatAddress)));
}

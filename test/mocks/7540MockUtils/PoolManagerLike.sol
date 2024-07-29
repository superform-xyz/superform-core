// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

interface PoolManagerLike {
    function assetToId(address) external view returns (uint128 assetId);

    function getTrancheTokenPrice(
        uint64 poolId,
        bytes16 trancheId,
        address asset
    )
        external
        view
        returns (uint128 price, uint64 computedAt);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

interface ERC7540VaultLike {
    function manager() external view returns (address);

    function poolId() external view returns (uint64);

    function trancheId() external view returns (bytes16);

    function priceLastUpdated() external view returns (uint64);
}

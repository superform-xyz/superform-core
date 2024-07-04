// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

interface InvestmentManagerLike {
    function fulfillDepositRequest(
        uint64 poolId,
        bytes16 trancheId,
        address user,
        uint128 assetId,
        uint128 assets,
        uint128 shares,
        uint128 fulfillment
    )
        external;

    function fulfillRedeemRequest(
        uint64 poolId,
        bytes16 trancheId,
        address user,
        uint128 assetId,
        uint128 assets,
        uint128 shares
    )
        external;

    function poolManager() external view returns (address);

    function root() external view returns (address);
}

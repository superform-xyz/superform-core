// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.14;

interface IInterestRateModel {
    function getBorrowRate(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);

    function getSupplyRate(
        uint256,
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);
}

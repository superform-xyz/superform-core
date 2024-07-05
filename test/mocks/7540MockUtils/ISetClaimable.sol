// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.23;

interface ISetClaimable {
    function moveSharesToClaimable(uint256 requestId, address controller) external;
    function moveAssetsToClaimable(uint256 requestId, address controller) external;
}

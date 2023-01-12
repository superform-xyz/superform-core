// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.14;

import {ICERC20} from "./ICERC20.sol";

interface IComptroller {
    function getCompAddress() external view returns (address);

    function getAllMarkets() external view returns (ICERC20[] memory);

    function allMarkets(uint256 index) external view returns (ICERC20);

    function claimComp(address holder, ICERC20[] memory cTokens) external;

    function mintGuardianPaused(ICERC20 cToken) external view returns (bool);
}

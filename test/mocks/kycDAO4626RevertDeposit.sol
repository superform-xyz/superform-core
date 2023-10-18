// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.21;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { kycDAO4626 } from "super-vaults/kycdao-4626/kycdao4626.sol";

contract kycDAO4626RevertDeposit is kycDAO4626 {
    constructor(ERC20 asset_, address kycValidity_) kycDAO4626(asset_, kycValidity_) { }

    function deposit(uint256, /*assets*/ address /*receiver*/ ) public pure override returns (uint256) {
        revert();
    }
}

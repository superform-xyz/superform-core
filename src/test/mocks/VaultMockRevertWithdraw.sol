// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract VaultMockRevertWithdraw is ERC4626 {
    using SafeERC20 for IERC20;

    constructor(IERC20 asset_, string memory name_, string memory symbol_) ERC4626(asset_) ERC20(name_, symbol_) {}

    function redeem(uint256, address, address) public virtual override returns (uint256) {
        revert();
    }
}

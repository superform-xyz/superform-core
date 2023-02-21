// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.18;

import {ERC4626} from "@rari-capital/solmate/src/mixins/ERC4626.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";

contract VaultMock is ERC4626 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    constructor(
        ERC20 asset,
        string memory name,
        string memory symbol
    ) ERC4626(asset, name, symbol) {}

    function totalAssets() public view override returns (uint256) {
        /// @dev placeholder, we just use it for mock
        return asset.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.23;

import { ERC20 } from "./7540MockUtils/ERC20.sol";
import { IERC20Callback } from "./7540MockUtils/IERC20.sol";
import { IERC7575Share, IERC165 } from "src/vendor/centrifuge/IERC7575.sol";

/// @title  Tranche ERC7575Mock
contract ERC7575Mock is ERC20, IERC7575Share {
    /// @inheritdoc IERC7575Share
    mapping(address asset => address) public vault;

    constructor(uint8 decimals_) ERC20(decimals_) { }

    function updateVault(address asset, address vault_) external {
        vault[asset] = vault_;
        emit VaultUpdate(asset, vault_);
    }

    // --- ERC165 support ---
    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC7575Share).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {IStateRegistry} from "../interfaces/IStateRegistry.sol";
import {ISuperFormFactory} from "../interfaces/ISuperFormFactory.sol";
import {BaseForm} from "../BaseForm.sol";

/// @title ERC20Form
/// @notice Abstract implementation of Form for protocols using ERC20 vault shares.
abstract contract ERC20Form is BaseForm {
    constructor(
        uint80 chainId_,
        IStateRegistry stateRegistry_,
        ISuperFormFactory superFormFactory_
    ) BaseForm(chainId_, stateRegistry_, superFormFactory_) {}

    /*///////////////////////////////////////////////////////////////
                            OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function vaultSharesIsERC20() public pure virtual override returns (bool) {
        return true;
    }

    /// @inheritdoc BaseForm
    function vaultSharesIsERC4626()
        public
        pure
        virtual
        override
        returns (bool)
    {
        return false;
    }

    /// @inheritdoc BaseForm
    function vaultSharesIsERC721() public pure virtual override returns (bool) {
        return false;
    }

    /// @inheritdoc BaseForm
    function superformYieldTokenName(
        address vault_
    ) external view virtual override returns (string memory) {
        return string(abi.encodePacked("Superform ", ERC20(vault_).name()));
    }

    /// @inheritdoc BaseForm
    function superformYieldTokenSymbol(
        address vault_
    ) external view virtual override returns (string memory) {
        return string(abi.encodePacked("SUP-", ERC20(vault_).symbol()));
    }

    /// @inheritdoc BaseForm
    function superformYieldTokenDecimals(
        address vault_
    ) external view virtual override returns (uint256 underlyingDecimals) {
        return ERC20(vault_).decimals();
    }
}

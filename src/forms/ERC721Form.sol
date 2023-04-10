// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {IBaseStateRegistry} from "../interfaces/IBaseStateRegistry.sol";
import {ISuperFormFactory} from "../interfaces/ISuperFormFactory.sol";
import {BaseForm} from "../BaseForm.sol";

/// @title ERC721Form
/// @notice Abstract implementation of BaseForm for protocols using ERC721 vault shares.
/// @notice WIP: likely not to be released in v1
abstract contract ERC721Form is BaseForm {
    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) BaseForm(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function getVaultShareBalance()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return ERC721(vault).balanceOf(address(this));
    }

    /// @inheritdoc BaseForm
    function vaultSharesIsERC20() public pure virtual override returns (bool) {
        return false;
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
        return true;
    }

    /// @inheritdoc BaseForm
    function superformYieldTokenName()
        external
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked("Superform ", ERC721(vault).name()));
    }

    /// @inheritdoc BaseForm
    function superformYieldTokenSymbol()
        external
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked("SUP-", ERC721(vault).symbol()));
    }

    /// @dev TODO - should this be 0?
    /// @inheritdoc BaseForm
    function superformYieldTokenDecimals()
        external
        view
        virtual
        override
        returns (uint256 underlyingDecimals)
    {
        return 0;
    }
}

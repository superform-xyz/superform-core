// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { InitSingleVaultData } from "src/types/DataTypes.sol";
import { ERC4626FormImplementation } from "src/forms/ERC4626FormImplementation.sol";
import { BaseForm } from "src/BaseForm.sol";

/// @title ERC4626Form
/// @notice The Form implementation for IERC4626 vaults
contract ERC4626FormExternal is ERC4626FormImplementation {
    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    constructor(address superRegistry_) ERC4626FormImplementation(superRegistry_, 1) { }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function _directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address /*srcSender_*/
    )
        internal
        override
        returns (uint256 shares)
    {
        shares = _processDirectDeposit(singleVaultData_);
    }

    /// @inheritdoc BaseForm
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address /*srcSender_*/
    )
        internal
        override
        returns (uint256 assets)
    {
        assets = _processDirectWithdraw(singleVaultData_);
    }

    /// @inheritdoc BaseForm
    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address, /*srcSender_*/
        uint64 srcChainId_
    )
        internal
        override
        returns (uint256 shares)
    {
        shares = _processXChainDeposit(singleVaultData_, srcChainId_);
    }

    /// @inheritdoc BaseForm
    function _xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address, /*srcSender_*/
        uint64 srcChainId_
    )
        internal
        override
        returns (uint256 assets)
    {
        assets = _processXChainWithdraw(singleVaultData_, srcChainId_);
    }

    /// @inheritdoc BaseForm
    function _emergencyWithdraw(address receiverAddress_, uint256 amount_) internal override {
        _processEmergencyWithdraw(receiverAddress_, amount_);
    }

    /// @inheritdoc BaseForm
    function _forwardDustToPaymaster() internal override {
        _processForwardDustToPaymaster();
    }
}

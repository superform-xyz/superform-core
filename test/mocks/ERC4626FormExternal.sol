// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

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
        returns (uint256 dstAmount)
    {
        dstAmount = _processDirectDeposit(singleVaultData_);
    }

    /// @inheritdoc BaseForm
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        internal
        override
        returns (uint256 dstAmount)
    {
        dstAmount = _processDirectWithdraw(singleVaultData_, srcSender_);
    }

    /// @inheritdoc BaseForm
    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address,
        uint64 srcChainId_
    )
        internal
        override
        returns (uint256 dstAmount)
    {
        dstAmount = _processXChainDeposit(singleVaultData_, srcChainId_);
    }

    /// @inheritdoc BaseForm
    function _xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        override
        returns (uint256 dstAmount)
    {
        dstAmount = _processXChainWithdraw(singleVaultData_, srcSender_, srcChainId_);
    }

    /// @inheritdoc BaseForm
    function _emergencyWithdraw(address refundAddress_, uint256 amount_) internal override {
        _processEmergencyWithdraw(refundAddress_, amount_);
    }

    /// @dev Wrapping Internal Functions
    function vaultSharesAmountToUnderlyingAmount(uint256 vaultSharesAmount_) public view returns (uint256) {
        return _vaultSharesAmountToUnderlyingAmount(vaultSharesAmount_, 0);
    }

    function vaultSharesAmountToUnderlyingAmountRoundingUp(uint256 vaultSharesAmount_) public view returns (uint256) {
        return _vaultSharesAmountToUnderlyingAmountRoundingUp(vaultSharesAmount_, 0);
    }

    function underlyingAmountToVaultSharesAmount(uint256 underlyingAmount_) public view returns (uint256) {
        return _underlyingAmountToVaultSharesAmount(underlyingAmount_, 0);
    }
}

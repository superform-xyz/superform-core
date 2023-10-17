// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { InitSingleVaultData } from "src/types/DataTypes.sol";
import { ERC4626FormImplementationInterfaceNotSupported } from "./ERC4626ImplementationInterfaceNotSupported.sol";
import { BaseForm } from "./BaseFormInterfaceNotSupported.sol";

/// @title ERC4626Form
/// @notice The Form implementation for IERC4626 vaults
contract ERC4626FormInterfaceNotSupported is ERC4626FormImplementationInterfaceNotSupported {
    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    constructor() ERC4626FormImplementationInterfaceNotSupported(1) { }

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
}

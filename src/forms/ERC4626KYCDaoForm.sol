// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { kycDAO4626 } from "super-vaults/kycdao-4626/kycdao4626.sol";
import { InitSingleVaultData } from "../types/DataTypes.sol";
import { ERC4626FormImplementation } from "./ERC4626FormImplementation.sol";
import { BaseForm } from "../BaseForm.sol";
import { Error } from "../utils/Error.sol";

/// @title ERC4626KYCDaoForm
/// @notice The Form implementation for IERC4626 vaults with kycDAO NFT checks
/// @notice This form must hold a kycDAO NFT to operate
contract ERC4626KYCDaoForm is ERC4626FormImplementation {

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    uint8 stateRegistryId = 1; // CoreStateRegistry

    constructor(address superRegistry_) 
        ERC4626FormImplementation(superRegistry_, stateRegistryId) {}


    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @dev this function calls the kycDAO vault kycCheck function to verify if the beneficiary holds a kycDAO token
    /// @dev note that this form must also be a holder of a kycDAO NFT
    modifier onlyKYC(address srcSender_) {
        if (!kycDAO4626(vault).kycCheck(srcSender_)) {
            revert Error.NO_VALID_KYC_TOKEN();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function _directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        internal
        override
        onlyKYC(srcSender_)
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
        onlyKYC(srcSender_)
        returns (uint256 dstAmount)
    {
        dstAmount = _processDirectWithdraw(singleVaultData_, srcSender_);
    }

    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        override
        onlyKYC(srcSender_)
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
        onlyKYC(srcSender_)
        returns (uint256 dstAmount)
    {
        dstAmount = _processXChainWithdraw(singleVaultData_, srcSender_, srcChainId_);
    }

    /// @inheritdoc BaseForm
    function _emergencyWithdraw(address refundAddress_, uint256 amount_) internal override {
        _processEmergencyWithdraw(refundAddress_, amount_);
    }

    /// @inheritdoc BaseForm
    function _forwardDustToPaymaster() internal override {
        _processForwardDustToPaymaster();
    }
}

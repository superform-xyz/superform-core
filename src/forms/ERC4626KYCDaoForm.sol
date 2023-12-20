// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { kycDAO4626 } from "super-vaults/kycdao-4626/kycdao4626.sol";
import { InitSingleVaultData } from "../types/DataTypes.sol";
import { ERC4626FormImplementation } from "./ERC4626FormImplementation.sol";
import { BaseForm } from "../BaseForm.sol";
import { Error } from "../libraries/Error.sol";

/// @title ERC4626KYCDaoForm
/// @notice The Form implementation for IERC4626 vaults with kycDAO NFT checks
/// @notice This form must hold a kycDAO NFT to operate
contract ERC4626KYCDaoForm is ERC4626FormImplementation {
    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    uint8 constant stateRegistryId = 1; // CoreStateRegistry

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) ERC4626FormImplementation(superRegistry_, stateRegistryId) { }

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    /// @dev this function calls the kycDAO vault kycCheck function to verify if the beneficiary holds a kycDAO token
    /// @dev note that this form must also be a holder of a kycDAO NFT
    modifier onlyKYC(address srcSender_) {
        if (!kycDAO4626(vault).kycCheck(srcSender_)) {
            revert Error.NO_VALID_KYC_TOKEN();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

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

    function _xChainDepositIntoVault(
        InitSingleVaultData memory, /*singleVaultData_*/
        address, /*srcSender_*/
        uint64 /*srcChainId_*/
    )
        internal
        pure
        override
        returns (uint256 /*dstAmount*/ )
    {
        revert Error.NOT_IMPLEMENTED();
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
        dstAmount = _processDirectWithdraw(singleVaultData_);
    }

    /// @inheritdoc BaseForm
    function _xChainWithdrawFromVault(
        InitSingleVaultData memory, /*singleVaultData_*/
        address, /*srcSender_*/
        uint64 /*srcChainId_*/
    )
        internal
        pure
        override
        returns (uint256 /*dstAmount*/ )
    {
        revert Error.NOT_IMPLEMENTED();
    }

    /// @inheritdoc BaseForm
    function _emergencyWithdraw(
        address srcSender_,
        address receiverAddress_,
        uint256 amount_
    )
        internal
        override
        onlyKYC(srcSender_)
    {
        _processEmergencyWithdraw(receiverAddress_, amount_);
    }

    /// @inheritdoc BaseForm
    function _forwardDustToPaymaster(address token_) internal override returns (uint256) {
        return _processForwardDustToPaymaster(token_);
    }
}

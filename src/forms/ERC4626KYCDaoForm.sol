// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { kycDAO4626 } from "super-vaults/kycdao-4626/kycdao4626.sol";
import { InitSingleVaultData } from "../types/DataTypes.sol";
import { ERC4626FormImplementation } from "./ERC4626FormImplementation.sol";
import { BaseForm } from "../BaseForm.sol";
import { Error } from "../utils/Error.sol";

/// @title ERC4626KYCDaoForm
/// @notice The Form implementation for IERC4626 vaults with kycDAO NFT checks
/// @notice This form must hold a kycDAO NFT to operate
contract ERC4626KYCDaoForm is ERC4626FormImplementation {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev error thrown when the sender doesn't the KYCDAO
    error NO_VALID_KYC_TOKEN();

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) ERC4626FormImplementation(superRegistry_, 1) { }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @dev this function calls the kycDAO vault kycCheck function to verify if the beneficiary holds a kycDAO token
    /// @dev note that this form must also be a holder of a kycDAO NFT
    function _kycCheck(address srcSender_) internal view {
        if (!kycDAO4626(vault).kycCheck(srcSender_)) revert NO_VALID_KYC_TOKEN();
    }

    /// @inheritdoc BaseForm
    function _directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        internal
        override
        returns (uint256 dstAmount)
    {
        _kycCheck(srcSender_);

        dstAmount = _processDirectDeposit(singleVaultData_, srcSender_);
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
        _kycCheck(srcSender_);

        dstAmount = _processDirectWithdraw(singleVaultData_, srcSender_);
    }

    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        override
        returns (uint256 dstAmount)
    {
        _kycCheck(srcSender_);

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
        _kycCheck(srcSender_);

        dstAmount = _processXChainWithdraw(singleVaultData_, srcSender_, srcChainId_);
    }
}

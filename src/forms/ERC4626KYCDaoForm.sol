// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { ERC4626FormImplementation } from "src/forms/ERC4626FormImplementation.sol";
import { BaseForm } from "src/BaseForm.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { IKycdaoNTNFT } from "src/vendor/kycDAO/IKycDAONTNFT.sol";
import { Error } from "src/libraries/Error.sol";
import { InitSingleVaultData } from "src/types/DataTypes.sol";
import { kycDAO4626 } from "super-vaults/kycdao-4626/kycdao4626.sol";
import { ERC721Holder } from "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";


/// @title ERC4626KYCDaoForm
/// @dev The Form implementation for kycDAO-gated ERC4626 vaults, must hold kycDAO NFT
/// @author Zeropoint Labs
contract ERC4626KYCDaoForm is ERC4626FormImplementation, ERC721Holder {

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    uint8 immutable stateRegistryId = 1; // CoreStateRegistry

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

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }
    //////////////////////////////////////////////////////////////
    //                  EXTERNAL ADMIN FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    function mintKYC(uint32 authCode_) external onlyProtocolAdmin {
        IKycdaoNTNFT(address(kycDAO4626(vault).kycValidity())).mintWithCode(authCode_);
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
        returns (uint256 shares)
    {
        shares = _processDirectDeposit(singleVaultData_);
    }

    function _xChainDepositIntoVault(
        InitSingleVaultData memory, /*singleVaultData_*/
        address, /*srcSender_*/
        uint64 /*srcChainId_*/
    )
        internal
        pure
        override
        returns (uint256 /*shares*/ )
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
        returns (uint256 assets)
    {
        assets = _processDirectWithdraw(singleVaultData_);
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
        returns (uint256 /*assets*/ )
    {
        revert Error.NOT_IMPLEMENTED();
    }

    /// @inheritdoc BaseForm
    function _emergencyWithdraw(address receiverAddress_, uint256 amount_) internal override {
        _processEmergencyWithdraw(receiverAddress_, amount_);
    }

    /// @inheritdoc BaseForm
    function _forwardDustToPaymaster(address token_) internal override {
        _processForwardDustToPaymaster(token_);
    }
}

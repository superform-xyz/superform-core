// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {LiquidityHandler} from "../crosschain-liquidity/LiquidityHandler.sol";
import {InitSingleVaultData} from "../types/DataTypes.sol";
import {BaseForm} from "../BaseForm.sol";
import {IBridgeValidator} from "../interfaces/IBridgeValidator.sol";
import {Error} from "../utils/Error.sol";
import {DataLib} from "../libraries/DataLib.sol";
import {IPermit2} from "../vendor/dragonfly-xyz/IPermit2.sol";

/// @title ERC4626FormImplementation
/// @notice Has common internal functions that can be re-used by actual form implementations
abstract contract ERC4626FormImplementation is BaseForm, LiquidityHandler {
    using SafeERC20 for IERC20;
    using DataLib for uint256;

    uint256 internal immutable STATE_REGISTRY_ID;

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    constructor(address superRegistry_, uint256 stateRegistryId_) BaseForm(superRegistry_) {
        STATE_REGISTRY_ID = stateRegistryId_;
    }

    /*///////////////////////////////////////////////////////////////
                            VIEW/PURE OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function getVaultAsset() public view virtual override returns (address) {
        return address(IERC4626(vault).asset());
    }

    /// @inheritdoc BaseForm
    function getVaultName() public view virtual override returns (string memory) {
        return IERC4626(vault).name();
    }

    /// @inheritdoc BaseForm
    function getVaultSymbol() public view virtual override returns (string memory) {
        return IERC4626(vault).symbol();
    }

    /// @inheritdoc BaseForm
    function getVaultDecimals() public view virtual override returns (uint256) {
        return uint256(IERC4626(vault).decimals());
    }

    /// @inheritdoc BaseForm
    function getPricePerVaultShare() public view virtual override returns (uint256) {
        uint256 vaultDecimals = IERC4626(vault).decimals();
        return IERC4626(vault).convertToAssets(10 ** vaultDecimals);
    }

    /// @inheritdoc BaseForm
    function getVaultShareBalance() public view virtual override returns (uint256) {
        return IERC4626(vault).balanceOf(address(this));
    }

    /// @inheritdoc BaseForm
    function getTotalAssets() public view virtual override returns (uint256) {
        return IERC4626(vault).totalAssets();
    }

    /// @inheritdoc BaseForm
    function getPreviewPricePerVaultShare() public view virtual override returns (uint256) {
        uint256 vaultDecimals = IERC4626(vault).decimals();
        return IERC4626(vault).previewRedeem(10 ** vaultDecimals);
    }

    /// @inheritdoc BaseForm
    function previewDepositTo(uint256 assets_) public view virtual override returns (uint256) {
        return IERC4626(vault).convertToShares(assets_);
    }

    /// @inheritdoc BaseForm
    function previewWithdrawFrom(uint256 assets_) public view virtual override returns (uint256) {
        return IERC4626(vault).previewWithdraw(assets_);
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @dev to avoid stack too deep errors
    struct directDepositLocalVars {
        uint64 chainId;
        address collateral;
        uint256 dstAmount;
        uint256 balanceBefore;
        uint256 balanceAfter;
    }

    function _processDirectDeposit(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    ) internal returns (uint256 dstAmount) {
        directDepositLocalVars memory vars;

        IERC4626 v = IERC4626(vault);
        vars.collateral = address(v.asset());
        vars.balanceBefore = IERC20(vars.collateral).balanceOf(address(this));

        /// @dev non empty txData means there is a swap needed before depositing (input asset not the same as vault asset)
        bool isSwap = singleVaultData_.liqData.txData.length > 0;
        /// @dev if the input asset was approved with permit2
        bool isPermit = singleVaultData_.liqData.permit2data.length > 0;

        IERC20 token = IERC20(singleVaultData_.liqData.token);
        uint256 amount = singleVaultData_.liqData.amount;

        if (!isSwap) {
            /// @dev handles the collateral token transfers.
            if (!isPermit) {
                if (token.allowance(srcSender_, address(this)) < amount)
                    revert Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();
                /// @dev transfers input token, which is the same as vault asset, to the form
                token.safeTransferFrom(srcSender_, address(this), amount);
            } else {
                (uint256 nonce, uint256 deadline, bytes memory signature) = abi.decode(
                    singleVaultData_.liqData.permit2data,
                    (uint256, uint256, bytes)
                );
                /// @dev does a permit2 transfer to this contract
                IPermit2(superRegistry.PERMIT2()).permitTransferFrom(
                    // The permit message.
                    IPermit2.PermitTransferFrom({
                        permitted: IPermit2.TokenPermissions(token, amount),
                        nonce: nonce,
                        deadline: deadline
                    }),
                    // The transfer recipient and amount.
                    IPermit2.SignatureTransferDetails({to: address(this), requestedAmount: amount}),
                    // The owner of the tokens, which must also be
                    // the signer of the message, otherwise this call
                    // will fail.
                    srcSender_,
                    // The packed signature that was the result of signing
                    // the EIP712 hash of `permit`.
                    signature
                );
            }
        } else {
            /// @dev in this case, a swap is needed, first the txData is validated and then the final asset is obtained
            vars.chainId = superRegistry.chainId();
            IBridgeValidator(superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId)).validateTxData(
                singleVaultData_.liqData.txData,
                vars.chainId,
                vars.chainId,
                true,
                address(this),
                srcSender_,
                address(token)
            );

            dispatchTokens(
                superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                singleVaultData_.liqData.txData,
                address(token),
                amount,
                srcSender_,
                singleVaultData_.liqData.nativeAmount,
                singleVaultData_.liqData.permit2data,
                superRegistry.PERMIT2()
            );
        }

        vars.balanceAfter = IERC20(vars.collateral).balanceOf(address(this));

        /// @dev the balance of vault tokens, ready to be deposited is compared with the previous balance
        if (vars.balanceAfter - vars.balanceBefore < singleVaultData_.amount)
            revert Error.DIRECT_DEPOSIT_INVALID_DATA();

        /// @dev the vault asset (collateral) is approved and deposited to the vault
        IERC20(vars.collateral).approve(vault, singleVaultData_.amount);
        dstAmount = v.deposit(singleVaultData_.amount, address(this));
    }

    function _processDirectWithdraw(
        InitSingleVaultData memory singleVaultData_,
        address srcSender
    ) internal returns (uint256 dstAmount) {
        uint256 len1 = singleVaultData_.liqData.txData.length;
        /// @dev if there is no txData, on withdraws the receiver is the original beneficiary (srcSender), otherwise it is this contract (before swap)
        address receiver = len1 == 0 ? srcSender : address(this);

        IERC4626 v = IERC4626(vault);
        address collateral = address(v.asset());

        /// @dev the token we are swapping from to our desired output token (if there is txData), must be the same as the vault asset
        if (singleVaultData_.liqData.token != collateral) revert Error.DIRECT_WITHDRAW_INVALID_COLLATERAL();

        /// @dev redeem the underlying
        dstAmount = v.redeem(singleVaultData_.amount, receiver, address(this));

        if (len1 != 0) {
            /// @dev this check here might be too much already, but can't hurt
            if (singleVaultData_.liqData.amount > dstAmount) revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

            uint64 chainId = superRegistry.chainId();

            /// @dev validate and perform the swap to desired output token and send to beneficiary
            IBridgeValidator(superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId)).validateTxData(
                singleVaultData_.liqData.txData,
                chainId,
                chainId,
                false,
                address(this),
                srcSender,
                singleVaultData_.liqData.token
            );

            dispatchTokens(
                superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                singleVaultData_.liqData.txData,
                singleVaultData_.liqData.token,
                singleVaultData_.liqData.amount,
                address(this),
                singleVaultData_.liqData.nativeAmount,
                "",
                superRegistry.PERMIT2()
            );
        }
    }

    function _processXChainDeposit(
        InitSingleVaultData memory singleVaultData_,
        uint64 srcChainId
    ) internal returns (uint256 dstAmount) {
        (, , uint64 dstChainId) = singleVaultData_.superformId.getSuperform();
        address vaultLoc = vault;

        IERC4626 v = IERC4626(vaultLoc);

        /// @dev pulling from sender, to auto-send tokens back in case of failed deposits / reverts
        IERC20(v.asset()).transferFrom(msg.sender, address(this), singleVaultData_.amount);

        /// @dev allowance is modified inside of the IERC20.transferFrom() call
        IERC20(v.asset()).approve(vaultLoc, singleVaultData_.amount);

        /// @dev This makes ERC4626Form (address(this)) owner of v.shares
        dstAmount = v.deposit(singleVaultData_.amount, address(this));

        emit Processed(srcChainId, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vaultLoc);
    }

    struct xChainWithdrawLocalVars {
        uint64 dstChainId;
        address receiver;
        address collateral;
        uint256 balanceBefore;
        uint256 balanceAfter;
    }

    function _processXChainWithdraw(
        InitSingleVaultData memory singleVaultData_,
        address srcSender,
        uint64 srcChainId
    ) internal returns (uint256 dstAmount) {
        uint256 len = singleVaultData_.liqData.txData.length;

        /// @dev a case where the withdraw req liqData has a valid token and tx data is not updated by the keeper
        if (singleVaultData_.liqData.token != address(0) && len == 0) {
            revert Error.WITHDRAW_TX_DATA_NOT_UPDATED();
        }

        xChainWithdrawLocalVars memory vars;
        (, , vars.dstChainId) = singleVaultData_.superformId.getSuperform();

        /// @dev if there is no txData, on withdraws the receiver is the original beneficiary (srcSender), otherwise it is this contract (before swap)
        vars.receiver = len == 0 ? srcSender : address(this);

        IERC4626 v = IERC4626(vault);
        vars.collateral = v.asset();

        /// @dev the token we are swapping from to our desired output token (if there is txData), must be the same as the vault asset
        if (vars.collateral != singleVaultData_.liqData.token) revert Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();

        /// @dev redeem vault positions (we operate only on positions, not assets)
        dstAmount = v.redeem(singleVaultData_.amount, vars.receiver, address(this));

        if (len != 0) {
            /// @dev the amount inscribed in liqData must be less or equal than the amount redeemed from the vault
            if (singleVaultData_.liqData.amount > dstAmount) revert Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();

            /// @dev validate and perform the swap to desired output token and send to beneficiary
            IBridgeValidator(superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId)).validateTxData(
                singleVaultData_.liqData.txData,
                vars.dstChainId,
                srcChainId,
                false,
                address(this),
                srcSender,
                singleVaultData_.liqData.token
            );

            dispatchTokens(
                superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                singleVaultData_.liqData.txData,
                singleVaultData_.liqData.token,
                dstAmount,
                address(this),
                singleVaultData_.liqData.nativeAmount,
                "",
                superRegistry.PERMIT2()
            );
        }

        emit Processed(srcChainId, vars.dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vault);
    }

    /*///////////////////////////////////////////////////////////////
                EXTERNAL VIEW VIRTUAL FUNCTIONS OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function superformYieldTokenName() external view virtual override returns (string memory) {
        return string(abi.encodePacked("Superform ", IERC20Metadata(vault).name()));
    }

    /// @inheritdoc BaseForm
    function superformYieldTokenSymbol() external view virtual override returns (string memory) {
        return string(abi.encodePacked("SUP-", IERC20Metadata(vault).symbol()));
    }

    /// @inheritdoc BaseForm
    function getStateRegistryId() external view override returns (uint256) {
        return STATE_REGISTRY_ID;
    }

    /*///////////////////////////////////////////////////////////////
                INTERNAL VIEW VIRTUAL FUNCTIONS OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function _vaultSharesAmountToUnderlyingAmount(
        uint256 vaultSharesAmount_,
        uint256 /*pricePerVaultShare*/
    ) internal view virtual override returns (uint256) {
        return IERC4626(vault).convertToAssets(vaultSharesAmount_);
    }

    /// @inheritdoc BaseForm
    function _vaultSharesAmountToUnderlyingAmountRoundingUp(
        uint256 vaultSharesAmount_,
        uint256 /*pricePerVaultShare*/
    ) internal view virtual override returns (uint256) {
        return IERC4626(vault).previewMint(vaultSharesAmount_);
    }

    /// @inheritdoc BaseForm
    function _underlyingAmountToVaultSharesAmount(
        uint256 underlyingAmount_,
        uint256 /*pricePerVaultShare*/
    ) internal view virtual override returns (uint256) {
        return IERC4626(vault).convertToShares(underlyingAmount_);
    }
}

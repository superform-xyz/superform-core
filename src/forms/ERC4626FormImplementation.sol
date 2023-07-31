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

/// @title ERC4626FormImplementation
/// @notice Has common internal functions that can be re-used by actual form implementations
abstract contract ERC4626FormImplementation is BaseForm, LiquidityHandler {
    using SafeERC20 for IERC20;
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    constructor(address superRegistry_) BaseForm(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                            VIEW/PURE OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    /// @dev asset() or some similar function should return all possible tokens that can be deposited into the vault so that BE can grab that properly
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
    function getConvertPricePerVaultShare() public view virtual override returns (uint256) {
        uint256 vaultDecimals = IERC4626(vault).decimals();
        return IERC4626(vault).convertToAssets(10 ** vaultDecimals);
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

    struct directDepositLocalVars {
        uint64 chainId;
        address vaultLoc;
        address collateral;
        uint256 dstAmount;
        uint256 balanceBefore;
        uint256 balanceAfter;
        IERC20 collateralToken;
    }

    function _processDirectDeposit(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    ) internal returns (uint256 dstAmount) {
        directDepositLocalVars memory vars;

        vars.vaultLoc = vault;

        /// note: checking balance
        IERC4626 v = IERC4626(vars.vaultLoc);

        vars.collateral = address(v.asset());
        vars.collateralToken = IERC20(vars.collateral);
        vars.balanceBefore = vars.collateralToken.balanceOf(address(this));

        /// note: handle the collateral token transfers.
        if (singleVaultData_.liqData.txData.length == 0) {
            if (
                IERC20(singleVaultData_.liqData.token).allowance(srcSender_, address(this)) <
                singleVaultData_.liqData.amount
            ) revert Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();

            IERC20(singleVaultData_.liqData.token).safeTransferFrom(
                srcSender_,
                address(this),
                singleVaultData_.liqData.amount
            );
        } else {
            vars.chainId = superRegistry.chainId();
            IBridgeValidator(superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId)).validateTxData(
                singleVaultData_.liqData.txData,
                vars.chainId,
                vars.chainId,
                true,
                address(this),
                srcSender_,
                singleVaultData_.liqData.token
            );

            dispatchTokens(
                superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                singleVaultData_.liqData.txData,
                singleVaultData_.liqData.token,
                singleVaultData_.liqData.amount,
                srcSender_,
                singleVaultData_.liqData.nativeAmount,
                singleVaultData_.liqData.permit2data,
                superRegistry.PERMIT2()
            );
        }

        vars.balanceAfter = vars.collateralToken.balanceOf(address(this));

        if (vars.balanceAfter - vars.balanceBefore < singleVaultData_.amount)
            revert Error.DIRECT_DEPOSIT_INVALID_DATA();

        if (address(v.asset()) != vars.collateral) revert Error.DIRECT_DEPOSIT_INVALID_COLLATERAL();

        /// @dev FIXME - should approve be reset after deposit? maybe use increase/decrease
        vars.collateralToken.approve(vars.vaultLoc, singleVaultData_.amount);
        dstAmount = v.deposit(singleVaultData_.amount, address(this));
    }

    function _processDirectWithdraw(
        InitSingleVaultData memory singleVaultData_,
        address srcSender
    ) internal returns (uint256 dstAmount) {
        uint256 len1 = singleVaultData_.liqData.txData.length;
        address receiver = len1 == 0 ? srcSender : address(this);

        IERC4626 v = IERC4626(vault);
        address collateral = address(v.asset());

        if (address(v.asset()) != collateral) revert Error.DIRECT_WITHDRAW_INVALID_COLLATERAL();

        dstAmount = v.redeem(singleVaultData_.amount, receiver, address(this));

        if (len1 != 0) {
            /// @dev this check here might be too much already, but can't hurt
            if (singleVaultData_.liqData.amount > singleVaultData_.amount)
                revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

            uint64 chainId = superRegistry.chainId();

            /// @dev NOTE: only allows withdraws to same chain
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
        (, , uint64 dstChainId) = singleVaultData_.superFormId.getSuperForm();
        address vaultLoc = vault;

        IERC4626 v = IERC4626(vaultLoc);

        /// @dev FIXME - should approve be reset after deposit? maybe use increase/decrease
        /// DEVNOTE: allowance is modified inside of the IERC20.transferFrom() call
        IERC20(v.asset()).approve(vaultLoc, singleVaultData_.amount);

        /// DEVNOTE: This makes ERC4626Form (address(this)) owner of v.shares
        dstAmount = v.deposit(singleVaultData_.amount, address(this));

        /// @dev FIXME: check subgraph if this should emit amount or dstAmount
        emit Processed(srcChainId, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vaultLoc);
    }

    struct xChainWithdrawLocalVars {
        uint64 dstChainId;
        address vaultLoc;
        uint256 dstAmount;
        uint256 balanceBefore;
        uint256 balanceAfter;
    }

    function _processXChainWithdraw(
        InitSingleVaultData memory singleVaultData_,
        address srcSender,
        uint64 srcChainId
    ) internal returns (uint256 dstAmount) {
        xChainWithdrawLocalVars memory vars;
        (, , vars.dstChainId) = singleVaultData_.superFormId.getSuperForm();
        vars.vaultLoc = vault;

        IERC4626 v = IERC4626(vars.vaultLoc);

        if (singleVaultData_.liqData.txData.length != 0) {
            /// Note Redeem Vault positions (we operate only on positions, not assets)
            vars.dstAmount = v.redeem(singleVaultData_.amount, address(this), address(this));

            vars.balanceBefore = IERC20(v.asset()).balanceOf(address(this));

            /// @dev NOTE: only allows withdraws back to source
            IBridgeValidator(superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId)).validateTxData(
                singleVaultData_.liqData.txData,
                vars.dstChainId,
                srcChainId,
                false,
                address(this),
                srcSender,
                singleVaultData_.liqData.token
            );

            /// Note Send Tokens to Source Chain
            /// FEAT Note: We could also allow to pass additional chainId arg here
            /// FEAT Note: Requires multiple ILayerZeroEndpoints to be mapped
            /// FIXME: bridge address should be validated at router level
            dispatchTokens(
                superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                singleVaultData_.liqData.txData,
                singleVaultData_.liqData.token,
                vars.dstAmount,
                address(this),
                singleVaultData_.liqData.nativeAmount,
                "",
                superRegistry.PERMIT2()
            );

            vars.balanceAfter = IERC20(v.asset()).balanceOf(address(this));

            /// note: balance validation to prevent draining contract.
            if (vars.balanceAfter < vars.balanceBefore - vars.dstAmount)
                revert Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();
        } else {
            /// Note Redeem Vault positions (we operate only on positions, not assets)
            vars.dstAmount = v.redeem(singleVaultData_.amount, srcSender, address(this));
        }

        /// @dev FIXME: check subgraph if this should emit amount or dstAmount
        emit Processed(srcChainId, vars.dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vars.vaultLoc);

        /// Here we either fully succeed of Callback.FAIL.
        return 0;
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
    function superformYieldTokenDecimals() external view virtual override returns (uint256 underlyingDecimals) {
        return IERC20Metadata(vault).decimals();
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
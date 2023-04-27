// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IBaseStateRegistry} from "../interfaces/IBaseStateRegistry.sol";
import {LiquidityHandler} from "../crosschain-liquidity/LiquidityHandler.sol";
import {InitSingleVaultData, LiqRequest} from "../types/DataTypes.sol";
import {BaseForm} from "../BaseForm.sol";
import {ERC20Form} from "./ERC20Form.sol";
import {ITokenBank} from "../interfaces/ITokenBank.sol";
import {IBridgeValidator} from "../interfaces/IBridgeValidator.sol";
import {Error} from "../utils/Error.sol";
import "../utils/DataPacking.sol";

/// @title ERC4626Form
/// @notice The Form implementation for ERC4626 vaults
contract ERC4626Form is ERC20Form, LiquidityHandler {
    using SafeTransferLib for ERC20;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev error thrown when the bridge tokens haven't arrived to destination
    error BRIDGE_TOKENS_PENDING();

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) ERC20Form(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                            VIEW/PURE OVERRIDES
    //////////////////////////////////////////////////////////////*/

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
        return true;
    }

    /// @inheritdoc BaseForm
    /// @dev asset() or some similar function should return all possible tokens that can be deposited into the vault so that BE can grab that properly
    function getUnderlyingOfVault()
        public
        view
        virtual
        override
        returns (ERC20)
    {
        return ERC4626(vault).asset();
    }

    /// @inheritdoc BaseForm
    function getPricePerVaultShare()
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 vaultDecimals = ERC4626(vault).decimals();
        return ERC4626(vault).convertToAssets(10 ** vaultDecimals);
    }

    /// @inheritdoc BaseForm
    function getVaultShareBalance()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return ERC4626(vault).balanceOf(address(this));
    }

    /// @inheritdoc BaseForm
    function getTotalAssets() public view virtual override returns (uint256) {
        return ERC4626(vault).totalAssets();
    }

    /// @inheritdoc BaseForm
    function getConvertPricePerVaultShare()
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 vaultDecimals = ERC4626(vault).decimals();
        return ERC4626(vault).convertToAssets(10 ** vaultDecimals);
    }

    /// @inheritdoc BaseForm
    function getPreviewPricePerVaultShare()
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 vaultDecimals = ERC4626(vault).decimals();
        return ERC4626(vault).previewRedeem(10 ** vaultDecimals);
    }

    /// @inheritdoc BaseForm
    function previewDepositTo(
        uint256 assets_
    ) public view virtual override returns (uint256) {
        return ERC4626(vault).convertToShares(assets_);
    }

    /// @inheritdoc BaseForm
    function previewWithdrawFrom(
        uint256 assets_
    ) public view virtual override returns (uint256) {
        return ERC4626(vault).previewWithdraw(assets_);
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    struct directDepositLocalVars {
        uint16 chainId;
        address vaultLoc;
        address collateral;
        address srcSender;
        uint256 dstAmount;
        uint256 balanceBefore;
        uint256 balanceAfter;
        ERC20 collateralToken;
    }

    /// @inheritdoc BaseForm
    function _directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual override returns (uint256 dstAmount) {
        directDepositLocalVars memory vars;

        vars.vaultLoc = vault;

        /// note: checking balance
        ERC4626 v = ERC4626(vars.vaultLoc);

        vars.collateral = address(v.asset());
        ERC20 collateralToken = ERC20(vars.collateral);
        vars.balanceBefore = vars.collateralToken.balanceOf(address(this));

        (vars.srcSender, , ) = _decodeTxData(singleVaultData_.txData);

        /// note: handle the collateral token transfers.
        if (singleVaultData_.liqData.txData.length == 0) {
            if (
                ERC20(singleVaultData_.liqData.token).allowance(
                    vars.srcSender,
                    address(this)
                ) < singleVaultData_.liqData.amount
            ) revert Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();

            ERC20(singleVaultData_.liqData.token).safeTransferFrom(
                vars.srcSender,
                address(this),
                singleVaultData_.liqData.amount
            );
        } else {
            vars.chainId = superRegistry.chainId();
            IBridgeValidator(
                superRegistry.getBridgeValidator(
                    singleVaultData_.liqData.bridgeId
                )
            ).validateTxData(
                    singleVaultData_.liqData.txData,
                    vars.chainId,
                    vars.chainId,
                    true,
                    address(this),
                    vars.srcSender,
                    singleVaultData_.liqData.token
                );

            dispatchTokens(
                superRegistry.getBridgeAddress(
                    singleVaultData_.liqData.bridgeId
                ),
                singleVaultData_.liqData.txData,
                singleVaultData_.liqData.token,
                singleVaultData_.liqData.amount,
                vars.srcSender,
                singleVaultData_.liqData.nativeAmount,
                singleVaultData_.liqData.permit2data,
                superRegistry.PERMIT2()
            );
        }

        vars.balanceAfter = vars.collateralToken.balanceOf(address(this));
        if (vars.balanceAfter - vars.balanceBefore < singleVaultData_.amount)
            revert Error.DIRECT_DEPOSIT_INVALID_DATA();

        if (address(v.asset()) != vars.collateral)
            revert Error.DIRECT_DEPOSIT_INVALID_COLLATERAL();

        /// @dev FIXME - should approve be reset after deposit? maybe use increase/decrease
        vars.collateralToken.approve(vars.vaultLoc, singleVaultData_.amount);
        dstAmount = v.deposit(singleVaultData_.amount, address(this));
    }

    /// @inheritdoc BaseForm
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual override returns (uint256 dstAmount) {
        (address srcSender, , ) = _decodeTxData(singleVaultData_.txData);

        uint256 len1 = singleVaultData_.liqData.txData.length;
        address receiver = len1 == 0 ? srcSender : address(this);

        ERC4626 v = ERC4626(vault);
        address collateral = address(v.asset());

        if (address(v.asset()) != collateral)
            revert Error.DIRECT_WITHDRAW_INVALID_COLLATERAL();

        dstAmount = v.redeem(singleVaultData_.amount, receiver, address(this));

        if (len1 != 0) {
            /// @dev this check here might be too much already, but can't hurt
            if (singleVaultData_.liqData.amount > singleVaultData_.amount)
                revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

            uint16 chainId = superRegistry.chainId();

            /// @dev NOTE: only allows withdraws to same chain
            IBridgeValidator(
                superRegistry.getBridgeValidator(
                    singleVaultData_.liqData.bridgeId
                )
            ).validateTxData(
                    singleVaultData_.liqData.txData,
                    chainId,
                    chainId,
                    false,
                    address(this),
                    srcSender,
                    singleVaultData_.liqData.token
                );

            dispatchTokens(
                superRegistry.getBridgeAddress(
                    singleVaultData_.liqData.bridgeId
                ),
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

    struct LocalVars {
        uint256 len;
        uint256[] dstAmounts;
        address[] vaults;
        uint8[] secAmb;
    }

    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual override returns (uint256 dstAmount) {
        (, , uint16 dstChainId) = _getSuperForm(singleVaultData_.superFormId);
        address vaultLoc = vault;

        ERC4626 v = ERC4626(vaultLoc);

        /// @dev FIXME - should approve be reset after deposit? maybe use increase/decrease
        /// DEVNOTE: allowance is modified inside of the ERC20.transferFrom() call
        ERC20(v.asset()).approve(vaultLoc, singleVaultData_.amount);

        /// DEVNOTE: This makes ERC4626Form (address(this)) owner of v.shares
        dstAmount = v.deposit(singleVaultData_.amount, address(this));
        (, uint16 srcChainId, uint80 txId) = _decodeTxData(
            singleVaultData_.txData
        );

        /// @dev FIXME: check subgraph if this should emit amount or dstAmount
        emit Processed(
            srcChainId,
            dstChainId,
            txId,
            singleVaultData_.amount,
            vaultLoc
        );
    }

    struct xChainWithdrawLocalVars {
        uint16 dstChainId;
        uint16 srcChainId;
        uint80 txId;
        address vaultLoc;
        address srcSender;
        uint256 dstAmount;
        uint256 balanceBefore;
        uint256 balanceAfter;
    }

    /// @inheritdoc BaseForm
    function _xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual override returns (uint16 status) {
        xChainWithdrawLocalVars memory vars;
        (, , vars.dstChainId) = _getSuperForm(singleVaultData_.superFormId);
        vars.vaultLoc = vault;

        ERC4626 v = ERC4626(vars.vaultLoc);

        (vars.srcSender, vars.srcChainId, vars.txId) = _decodeTxData(
            singleVaultData_.txData
        );

        if (singleVaultData_.liqData.txData.length != 0) {
            /// Note Redeem Vault positions (we operate only on positions, not assets)
            vars.dstAmount = v.redeem(
                singleVaultData_.amount,
                address(this),
                address(this)
            );

            vars.balanceBefore = ERC20(v.asset()).balanceOf(address(this));

            /// @dev NOTE: only allows withdraws back to source
            IBridgeValidator(
                superRegistry.getBridgeValidator(
                    singleVaultData_.liqData.bridgeId
                )
            ).validateTxData(
                    singleVaultData_.liqData.txData,
                    vars.dstChainId,
                    vars.srcChainId,
                    false,
                    address(this),
                    vars.srcSender,
                    singleVaultData_.liqData.token
                );

            /// Note Send Tokens to Source Chain
            /// FEAT Note: We could also allow to pass additional chainId arg here
            /// FEAT Note: Requires multiple ILayerZeroEndpoints to be mapped
            /// FIXME: bridge address should be validated at router level
            dispatchTokens(
                superRegistry.getBridgeAddress(
                    singleVaultData_.liqData.bridgeId
                ),
                singleVaultData_.liqData.txData,
                singleVaultData_.liqData.token,
                vars.dstAmount,
                address(this),
                singleVaultData_.liqData.nativeAmount,
                "",
                superRegistry.PERMIT2()
            );

            vars.balanceAfter = ERC20(v.asset()).balanceOf(address(this));

            /// note: balance validation to prevent draining contract.
            if (vars.balanceAfter < vars.balanceBefore - vars.dstAmount)
                revert Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();
        } else {
            /// Note Redeem Vault positions (we operate only on positions, not assets)
            vars.dstAmount = v.redeem(
                singleVaultData_.amount,
                vars.srcSender,
                address(this)
            );
        }

        /// @dev FIXME: check subgraph if this should emit amount or dstAmount
        emit Processed(
            vars.srcChainId,
            vars.dstChainId,
            vars.txId,
            singleVaultData_.amount,
            vars.vaultLoc
        );

        /// Here we either fully succeed of Callback.FAIL.
        return 0;
    }

    /*///////////////////////////////////////////////////////////////
                INTERNAL VIEW VIRTUAL FUNCTIONS OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function _vaultSharesAmountToUnderlyingAmount(
        uint256 vaultSharesAmount_,
        uint256 /*pricePerVaultShare*/
    ) internal view virtual override returns (uint256) {
        return ERC4626(vault).convertToAssets(vaultSharesAmount_);
    }

    /// @inheritdoc BaseForm
    function _vaultSharesAmountToUnderlyingAmountRoundingUp(
        uint256 vaultSharesAmount_,
        uint256 /*pricePerVaultShare*/
    ) internal view virtual override returns (uint256) {
        return ERC4626(vault).previewMint(vaultSharesAmount_);
    }

    /// @inheritdoc BaseForm
    function _underlyingAmountToVaultSharesAmount(
        uint256 underlyingAmount_,
        uint256 /*pricePerVaultShare*/
    ) internal view virtual override returns (uint256) {
        return ERC4626(vault).convertToShares(underlyingAmount_);
    }
}

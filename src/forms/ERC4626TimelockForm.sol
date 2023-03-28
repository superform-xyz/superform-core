// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {IERC4626Timelock} from "./interfaces/IERC4626Timelock.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {LiquidityHandler} from "../crosschain-liquidity/LiquidityHandler.sol";
import {InitSingleVaultData, LiqRequest} from "../types/DataTypes.sol";
import {BaseForm} from "../BaseForm.sol";
import {ISuperFormFactory} from "../interfaces/ISuperFormFactory.sol";
import {ERC20Form} from "./ERC20Form.sol";
import {ITokenBank} from "../interfaces/ITokenBank.sol";
import "../utils/DataPacking.sol";

/// @title ERC4626TimelockedForm
/// @notice The Form implementation with timelock extension for IERC4626Timelock vaults
contract ERC4626TimelockedForm is ERC20Form, LiquidityHandler {
    using SafeTransferLib for ERC20;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev error thrown when the bridge tokens haven't arrived to destination
    error BRIDGE_TOKENS_PENDING();

    /// @dev unlock already requested, cooldown period didn't pass yet
    error WITHDRAW_COOLDOWN_PERIOD();

    /// @dev error thrown when the unlock reques
    error NOT_ENOUGH_UNLOCKED();

    constructor(
        uint16 chainId_,
        ISuperFormFactory superformfactory_
    ) ERC20Form(chainId_, superformfactory_) {}

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
    function getUnderlyingOfVault(
        address vault_
    ) public view virtual override returns (ERC20) {
        return ERC20(IERC4626Timelock(vault_).asset());
    }

    /// @inheritdoc BaseForm
    function getPricePerVaultShare(
        address vault_
    ) public view virtual override returns (uint256) {
        uint256 vaultDecimals = ERC20(vault_).decimals();
        return IERC4626Timelock(vault_).convertToAssets(10 ** vaultDecimals);
    }

    /// @inheritdoc BaseForm
    function getVaultShareBalance(
        address vault_
    ) public view virtual override returns (uint256) {
        return IERC4626Timelock(vault_).balanceOf(address(this));
    }

    /// @inheritdoc BaseForm
    function getTotalAssets(
        address vault_
    ) public view virtual override returns (uint256) {
        return IERC4626Timelock(vault_).totalAssets();
    }

    /// @inheritdoc BaseForm
    function getConvertPricePerVaultShare(
        address vault_
    ) public view virtual override returns (uint256) {
        uint256 vaultDecimals = ERC20(vault_).decimals();
        return IERC4626Timelock(vault_).convertToAssets(10 ** vaultDecimals);
    }

    /// @inheritdoc BaseForm
    function getPreviewPricePerVaultShare(
        address vault_
    ) public view virtual override returns (uint256) {
        uint256 vaultDecimals = ERC20(vault_).decimals();
        return IERC4626Timelock(vault_).previewRedeem(10 ** vaultDecimals);
    }

    /// @inheritdoc BaseForm
    function previewDepositTo(
        address vault_,
        uint256 assets_
    ) public view virtual override returns (uint256) {
        return IERC4626Timelock(vault_).convertToShares(assets_);
    }

    /// @inheritdoc BaseForm
    function previewWithdrawFrom(
        address vault_,
        uint256 assets_
    ) public view virtual override returns (uint256) {
        return IERC4626Timelock(vault_).previewWithdraw(assets_);
    }

    /// @dev ERC4626TimelockFork getter
    /// NOTE: We have control over Forms, checkUnlock is designed to act like standardized function to return true/false for withdraw action
    function checkUnlock(
        address vault_,
        uint256 shares_,
        address owner_
    ) public view returns (uint16) {
        IERC4626Timelock.UnlockRequest memory request = IERC4626Timelock(vault_)
            .userUnlockRequests(owner_);

        if (request.startedAt == 0) {
            /// unlock not initiated. requestUnlock in return
            return 2;
        }

        if (
            request.startedAt + IERC4626Timelock(vault_).lockPeriod() >=
            block.timestamp
        ) {
            if (request.shareAmount >= shares_) {
                /// all clear. unlock after cooldown and enough of the shares. execute redeem
                return 0;
            } else {
                /// not enough shares to unlock. revert NOT_ENOUGH_UNLOCKED
                return 1;
            }
        }

        /// check if unlock is initiated already passed and should return before reaching here
        if (
            request.startedAt + IERC4626Timelock(vault_).lockPeriod() <
            block.timestamp
        ) {
            /// unlock cooldown period not passed. revert WITHDRAW_COOLDOWN_PERIOD
            return 3;
        }
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function _directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual override returns (uint256 dstAmount) {
        /// note: checking balance
        (address vault, , ) = _getSuperForm(singleVaultData_.superFormId);

        IERC4626Timelock v = IERC4626Timelock(vault);

        address collateral = address(v.asset());
        ERC20 collateralToken = ERC20(collateral);
        uint256 balanceBefore = collateralToken.balanceOf(address(this));

        (address srcSender, , ) = _decodeTxData(singleVaultData_.txData);

        LiqRequest memory liqData = abi.decode(
            singleVaultData_.liqData,
            (LiqRequest)
        );

        /// note: handle the collateral token transfers.
        if (liqData.txData.length == 0) {
            if (
                ERC20(liqData.token).allowance(srcSender, address(this)) <
                liqData.amount
            ) revert DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();

            ERC20(liqData.token).safeTransferFrom(
                srcSender,
                address(this),
                liqData.amount
            );
        } else {
            dispatchTokens(
                bridgeAddress[liqData.bridgeId],
                liqData.txData,
                liqData.token,
                liqData.allowanceTarget,
                liqData.amount,
                srcSender,
                liqData.nativeAmount
            );
        }

        uint256 balanceAfter = collateralToken.balanceOf(address(this));
        if (balanceAfter - balanceBefore < singleVaultData_.amount)
            revert DIRECT_DEPOSIT_INVALID_DATA();

        if (address(v.asset()) != collateral)
            revert DIRECT_DEPOSIT_INVALID_COLLATERAL();

        /// @dev FIXME - should approve be reset after deposit? maybe use increase/decrease
        /// DEVNOTE: allowance is modified inside of the ERC20.transferFrom() call
        collateralToken.approve(vault, singleVaultData_.amount);
        dstAmount = v.deposit(singleVaultData_.amount, address(this));
    }

    /// @inheritdoc BaseForm
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual override returns (uint256 dstAmount) {
        (address srcSender, , ) = _decodeTxData(singleVaultData_.txData);

        LiqRequest memory liqData = abi.decode(
            singleVaultData_.liqData,
            (LiqRequest)
        );

        uint256 len1 = liqData.txData.length;
        address receiver = len1 == 0 ? srcSender : address(this);

        (address vault, , ) = _getSuperForm(singleVaultData_.superFormId);
        IERC4626Timelock v = IERC4626Timelock(vault);
        address collateral = address(v.asset());

        if (address(v.asset()) != collateral)
            revert DIRECT_WITHDRAW_INVALID_COLLATERAL();

        /// NOTE: This assumes that first transaction to this vault may just trigger the unlock with cooldown
        /// NOTE: Only next withdraw transaction would trigger the actual withdraw.
        /// TODO: Besides API making informed choice how else we can revert this better?
        /// TODO: extraData could be used to first make check at the begining of this func and revert earlier
        uint16 unlock = checkUnlock(vault, singleVaultData_.amount, srcSender);
        if (unlock == 0) {
            dstAmount = v.redeem(
                singleVaultData_.amount,
                receiver,
                address(this)
            );

            if (len1 != 0) {
                /// @dev this check here might be too much already, but can't hurt
                if (liqData.amount > singleVaultData_.amount)
                    revert DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

                dispatchTokens(
                    bridgeAddress[liqData.bridgeId],
                    liqData.txData,
                    liqData.token,
                    liqData.allowanceTarget,
                    liqData.amount,
                    address(this),
                    liqData.nativeAmount
                );
            }
        } else if (unlock == 1) {
            revert NOT_ENOUGH_UNLOCKED();
        } else if (unlock == 2) {
            v.requestUnlock(singleVaultData_.amount);
        } else if (unlock == 3) {
            revert WITHDRAW_COOLDOWN_PERIOD();
        }
    }

    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual override returns (uint256 dstAmount) {
        (address vault, , uint16 dstChainId) = _getSuperForm(
            singleVaultData_.superFormId
        );

        IERC4626Timelock v = IERC4626Timelock(vault);

        /// @dev FIXME - should approve be reset after deposit? maybe use increase/decrease
        /// DEVNOTE: allowance is modified inside of the ERC20.transferFrom() call
        ERC20(v.asset()).approve(vault, singleVaultData_.amount);

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
            vault
        );
    }

    /// @inheritdoc BaseForm
    function _xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual override {
        (address vault, , uint16 dstChainId) = _getSuperForm(
            singleVaultData_.superFormId
        );

        uint256 dstAmount;

        IERC4626Timelock v = IERC4626Timelock(vault);

        (address srcSender, uint16 srcChainId, uint80 txId) = _decodeTxData(
            singleVaultData_.txData
        );
        LiqRequest memory liqData = abi.decode(
            singleVaultData_.liqData,
            (LiqRequest)
        );

        uint16 unlock = checkUnlock(vault, singleVaultData_.amount, srcSender);
        if (unlock == 0) {
            if (liqData.txData.length != 0) {
                /// Note Redeem Vault positions (we operate only on positions, not assets)
                dstAmount = v.redeem(
                    singleVaultData_.amount,
                    address(this),
                    address(this)
                );

                uint256 balanceBefore = ERC20(v.asset()).balanceOf(
                    address(this)
                );
                /// Note Send Tokens to Source Chain
                /// FEAT Note: We could also allow to pass additional chainId arg here
                /// FEAT Note: Requires multiple ILayerZeroEndpoints to be mapped
                dispatchTokens(
                    bridgeAddress[liqData.bridgeId],
                    liqData.txData,
                    liqData.token,
                    liqData.allowanceTarget,
                    dstAmount,
                    address(this),
                    liqData.nativeAmount
                );
                uint256 balanceAfter = ERC20(v.asset()).balanceOf(
                    address(this)
                );

                /// note: balance validation to prevent draining contract.
                if (balanceAfter < balanceBefore - dstAmount)
                    revert XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();
            } else {
                /// Note Redeem Vault positions (we operate only on positions, not assets)
                v.redeem(singleVaultData_.amount, srcSender, address(this));
            }
        } else if (unlock == 1) {
            revert NOT_ENOUGH_UNLOCKED();
        } else if (unlock == 2) {
            v.requestUnlock(singleVaultData_.amount);
        } else if (unlock == 3) {
            revert WITHDRAW_COOLDOWN_PERIOD();
        }

        /// @dev FIXME: check subgraph if this should emit amount or dstAmount
        emit Processed(
            srcChainId,
            dstChainId,
            txId,
            singleVaultData_.amount,
            vault
        );
    }

    /*///////////////////////////////////////////////////////////////
                INTERNAL VIEW VIRTUAL FUNCTIONS OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function _vaultSharesAmountToUnderlyingAmount(
        address vault_,
        uint256 vaultSharesAmount_,
        uint256 /*pricePerVaultShare*/
    ) internal view virtual override returns (uint256) {
        return IERC4626Timelock(vault_).convertToAssets(vaultSharesAmount_);
    }

    /// @inheritdoc BaseForm
    function _vaultSharesAmountToUnderlyingAmountRoundingUp(
        address vault_,
        uint256 vaultSharesAmount_,
        uint256 /*pricePerVaultShare*/
    ) internal view virtual override returns (uint256) {
        return IERC4626Timelock(vault_).previewMint(vaultSharesAmount_);
    }

    /// @inheritdoc BaseForm
    function _underlyingAmountToVaultSharesAmount(
        address vault_,
        uint256 underlyingAmount_,
        uint256 /*pricePerVaultShare*/
    ) internal view virtual override returns (uint256) {
        return IERC4626Timelock(vault_).convertToShares(underlyingAmount_);
    }
}

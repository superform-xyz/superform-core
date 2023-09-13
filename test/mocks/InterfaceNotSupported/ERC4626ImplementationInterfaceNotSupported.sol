// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { IERC20Metadata } from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import { LiquidityHandler } from "src/crosschain-liquidity/LiquidityHandler.sol";
import { InitSingleVaultData } from "src/types/DataTypes.sol";
import { BaseForm } from "./BaseFormInterfaceNotSupported.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { Error } from "src/utils/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { IPermit2 } from "src/vendor/dragonfly-xyz/IPermit2.sol";

/// @title ERC4626FormImplementation
/// @notice Has common internal functions that can be re-used by actual form implementations
abstract contract ERC4626FormImplementationInterfaceNotSupported is BaseForm, LiquidityHandler {
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
        address bridgeValidator;
        uint256 dstAmount;
        uint256 balanceBefore;
        uint256 balanceAfter;
        uint256 nonce;
        uint256 deadline;
        bytes signature;
    }

    function _processDirectDeposit(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        internal
        returns (uint256 dstAmount)
    {
        directDepositLocalVars memory vars;

        IERC4626 v = IERC4626(vault);
        vars.collateral = address(v.asset());
        vars.balanceBefore = IERC20(vars.collateral).balanceOf(address(this));

        IERC20 token = IERC20(singleVaultData_.liqData.token);

        if (address(token) != NATIVE) {
            /// @dev handles the collateral token transfers.
            if (token.allowance(msg.sender, address(this)) < singleVaultData_.amount) {
                revert Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();
            }

            /// @dev transfers input token, which is the same as vault asset, to the form
            token.safeTransferFrom(msg.sender, address(this), singleVaultData_.amount);
        }

        /// @dev if we don't have txData (no swap) then the full amount in the stateReq is used
        /// @dev non empty txData means there is a swap needed before depositing (input asset not the same as vault
        /// asset)
        if (singleVaultData_.liqData.txData.length > 0) {
            vars.bridgeValidator = superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId);

            /// @dev in this case, a swap is needed, first the txData is validated and then the final asset is obtained
            vars.chainId = superRegistry.chainId();

            IBridgeValidator(vars.bridgeValidator).validateTxData(
                singleVaultData_.liqData.txData,
                vars.chainId,
                vars.chainId,
                singleVaultData_.liqData.liqDstChainId,
                true,
                address(this),
                msg.sender,
                address(token)
            );

            dispatchTokens(
                superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                singleVaultData_.liqData.txData,
                address(token),
                IBridgeValidator(vars.bridgeValidator).decodeAmountIn(singleVaultData_.liqData.txData, false),
                address(this),
                singleVaultData_.liqData.nativeAmount
            );
        }

        vars.balanceAfter = IERC20(vars.collateral).balanceOf(address(this));

        /// @dev the balance of vault tokens, ready to be deposited is compared with the previous balance
        if (vars.balanceAfter - vars.balanceBefore < singleVaultData_.amount) {
            revert Error.DIRECT_DEPOSIT_INVALID_DATA();
        }

        /// @dev the vault asset (collateral) is approved and deposited to the vault
        IERC20(vars.collateral).safeIncreaseAllowance(vault, singleVaultData_.amount);

        dstAmount = v.deposit(singleVaultData_.amount, address(this));
    }

    struct ProcessDirectWithdawLocalVars {
        uint64 chainId;
        address collateral;
        address receiver;
        address bridgeValidator;
        uint256 len1;
        uint256 amount;
        IERC4626 v;
    }

    function _processDirectWithdraw(
        InitSingleVaultData memory singleVaultData_,
        address srcSender
    )
        internal
        returns (uint256 dstAmount)
    {
        ProcessDirectWithdawLocalVars memory v;
        v.len1 = singleVaultData_.liqData.txData.length;
        /// @dev if there is no txData, on withdraws the receiver is the original beneficiary (srcSender), otherwise it
        /// is this contract (before swap)
        v.receiver = v.len1 == 0 ? srcSender : address(this);

        v.v = IERC4626(vault);
        v.collateral = address(v.v.asset());

        /// @dev the token we are swapping from to our desired output token (if there is txData), must be the same as
        /// the vault asset
        if (singleVaultData_.liqData.token != v.collateral) revert Error.DIRECT_WITHDRAW_INVALID_COLLATERAL();

        /// @dev redeem the underlying
        dstAmount = v.v.redeem(singleVaultData_.amount, v.receiver, address(this));

        if (v.len1 != 0) {
            v.bridgeValidator = superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId);
            v.amount = IBridgeValidator(v.bridgeValidator).decodeAmountIn(singleVaultData_.liqData.txData, false);

            /// @dev this check here might be too much already, but can't hurt
            if (v.amount > dstAmount) revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

            v.chainId = superRegistry.chainId();

            /// @dev validate and perform the swap to desired output token and send to beneficiary
            IBridgeValidator(v.bridgeValidator).validateTxData(
                singleVaultData_.liqData.txData,
                v.chainId,
                v.chainId,
                singleVaultData_.liqData.liqDstChainId,
                false,
                address(this),
                srcSender,
                singleVaultData_.liqData.token
            );

            /// @dev FIXME: notice that in direct withdraws we withdraw v.amount (coming from txData), but not what was
            /// actually redeemed? Why? xChainWithdraw operates differently here

            dispatchTokens(
                superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                singleVaultData_.liqData.txData,
                singleVaultData_.liqData.token,
                v.amount,
                address(this),
                singleVaultData_.liqData.nativeAmount
            );
        }
    }

    function _processXChainDeposit(
        InitSingleVaultData memory singleVaultData_,
        uint64 srcChainId
    )
        internal
        returns (uint256 dstAmount)
    {
        (,, uint64 dstChainId) = singleVaultData_.superformId.getSuperform();
        address vaultLoc = vault;

        IERC4626 v = IERC4626(vaultLoc);

        /// @dev pulling from sender, to auto-send tokens back in case of failed deposits / reverts
        IERC20(v.asset()).transferFrom(msg.sender, address(this), singleVaultData_.amount);

        /// @dev allowance is modified inside of the IERC20.transferFrom() call
        IERC20(v.asset()).safeIncreaseAllowance(vaultLoc, singleVaultData_.amount);

        /// @dev This makes ERC4626Form (address(this)) owner of v.shares
        dstAmount = v.deposit(singleVaultData_.amount, address(this));

        emit Processed(srcChainId, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vaultLoc);
    }

    struct xChainWithdrawLocalVars {
        uint64 dstChainId;
        address receiver;
        address collateral;
        address bridgeValidator;
        uint256 balanceBefore;
        uint256 balanceAfter;
        uint256 amount;
    }

    function _processXChainWithdraw(
        InitSingleVaultData memory singleVaultData_,
        address srcSender,
        uint64 srcChainId
    )
        internal
        returns (uint256 dstAmount)
    {
        uint256 len = singleVaultData_.liqData.txData.length;

        /// @dev a case where the withdraw req liqData has a valid token and tx data is not updated by the keeper
        if (singleVaultData_.liqData.token != address(0) && len == 0) {
            revert Error.WITHDRAW_TX_DATA_NOT_UPDATED();
        }

        xChainWithdrawLocalVars memory vars;
        (,, vars.dstChainId) = singleVaultData_.superformId.getSuperform();

        /// @dev if there is no txData, on withdraws the receiver is the original beneficiary (srcSender), otherwise it
        /// is this contract (before swap)
        vars.receiver = len == 0 ? srcSender : address(this);

        IERC4626 v = IERC4626(vault);
        vars.collateral = v.asset();

        /// @dev the token we are swapping from to our desired output token (if there is txData), must be the same as
        /// the vault asset
        if (vars.collateral != singleVaultData_.liqData.token) revert Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();

        /// @dev redeem vault positions (we operate only on positions, not assets)
        dstAmount = v.redeem(singleVaultData_.amount, vars.receiver, address(this));

        if (len != 0) {
            vars.bridgeValidator = superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId);
            vars.amount = IBridgeValidator(vars.bridgeValidator).decodeAmountIn(singleVaultData_.liqData.txData, false);

            /// @dev the amount inscribed in liqData must be less or equal than the amount redeemed from the vault
            if (vars.amount > dstAmount) revert Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();

            /// @dev validate and perform the swap to desired output token and send to beneficiary
            IBridgeValidator(vars.bridgeValidator).validateTxData(
                singleVaultData_.liqData.txData,
                vars.dstChainId,
                srcChainId,
                singleVaultData_.liqData.liqDstChainId,
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
                singleVaultData_.liqData.nativeAmount
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
    )
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return IERC4626(vault).convertToAssets(vaultSharesAmount_);
    }

    /// @inheritdoc BaseForm
    function _vaultSharesAmountToUnderlyingAmountRoundingUp(
        uint256 vaultSharesAmount_,
        uint256 /*pricePerVaultShare*/
    )
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return IERC4626(vault).previewMint(vaultSharesAmount_);
    }

    /// @inheritdoc BaseForm
    function _underlyingAmountToVaultSharesAmount(
        uint256 underlyingAmount_,
        uint256 /*pricePerVaultShare*/
    )
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return IERC4626(vault).convertToShares(underlyingAmount_);
    }
}

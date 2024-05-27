// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BaseForm } from "src/BaseForm.sol";
import { LiquidityHandler } from "src/crosschain-liquidity/LiquidityHandler.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { Error } from "src/libraries/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { InitSingleVaultData } from "src/types/DataTypes.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { IERC20Metadata } from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IStandardizedYield } from "src/vendor/pendle/IStandardizedYield.sol";

/// @title ERC5115Form
/// @dev The Form implementation for ERC5115 vaults
/// @notice Reference implementation of a vault:
/// https://github.com/pendle-finance/pendle-core-v2-public/blob/main/contracts/core/StandardizedYield/SYBase.sol
/// @author Zeropoint Labs
contract ERC5115Form is BaseForm, LiquidityHandler {
    using SafeERC20 for IERC20;
    using SafeERC20 for IStandardizedYield;
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                           Errors                        //
    //////////////////////////////////////////////////////////////

    error INVALID_TOKEN_IN();

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                         //
    //////////////////////////////////////////////////////////////

    uint8 internal immutable STATE_REGISTRY_ID;
    uint256 internal constant ENTIRE_SLIPPAGE = 10_000;

    //////////////////////////////////////////////////////////////
    //                           STRUCTS                        //
    //////////////////////////////////////////////////////////////

    struct DirectDepositLocalVars {
        uint64 chainId;
        address asset;
        address bridgeValidator;
        uint256 shares;
        uint256 balanceBefore;
        uint256 assetDifference;
        uint256 nonce;
        uint256 deadline;
        uint256 inputAmount;
        bytes signature;
    }

    struct DirectWithdrawLocalVars {
        uint64 chainId;
        address asset;
        address bridgeValidator;
        uint256 amount;
    }

    struct XChainWithdrawLocalVars {
        uint64 dstChainId;
        address asset;
        address bridgeValidator;
        uint256 balanceBefore;
        uint256 balanceAfter;
        uint256 amount;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_, uint8 stateRegistryId_) BaseForm(superRegistry_) {
        /// @dev check if state registry id is valid
        superRegistry.getStateRegistry(stateRegistryId_);

        STATE_REGISTRY_ID = stateRegistryId_;
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc BaseForm
    function getVaultName() public view virtual override returns (string memory) {
        return IStandardizedYield(vault).name();
    }

    /// @inheritdoc BaseForm
    function getVaultSymbol() public view virtual override returns (string memory) {
        return IStandardizedYield(vault).symbol();
    }

    /// @inheritdoc BaseForm
    function getVaultDecimals() public view virtual override returns (uint256) {
        return uint256(IStandardizedYield(vault).decimals());
    }

    /// @inheritdoc BaseForm
    function getPricePerVaultShare() public view virtual override returns (uint256) {
        return price = IStandardizedYield(vault).exchangeRate();
    }

    /// @inheritdoc BaseForm
    function getVaultShareBalance() public view virtual override returns (uint256) {
        return IStandardizedYield(vault).balanceOf(address(this));
    }

    /// @inheritdoc BaseForm
    function getTotalAssets() public view virtual override returns (uint256) {
        return 0;
    }

    /// @inheritdoc BaseForm
    function getTotalSupply() public view virtual override returns (uint256) {
        return IERC20Metadata(vault).totalSupply();
    }

    /// @inheritdoc BaseForm
    function getPreviewPricePerVaultShare() public view virtual override returns (uint256) {
        return 0;
    }

    /// @inheritdoc BaseForm
    function previewDepositTo(uint256 assets_) public view virtual override returns (uint256) {
        return 0;
    }

    /// @inheritdoc BaseForm
    function previewWithdrawFrom(uint256 assets_) public view virtual override returns (uint256) {
        return 0;
    }

    /// @inheritdoc BaseForm
    function previewRedeemFrom(uint256 shares_) public view virtual override returns (uint256) {
        return 0;
    }

    /// @inheritdoc BaseForm
    function superformYieldTokenName() external view virtual override returns (string memory) {
        return string(abi.encodePacked(IERC20Metadata(vault).name(), " SuperPosition"));
    }

    /// @inheritdoc BaseForm
    function superformYieldTokenSymbol() external view virtual override returns (string memory) {
        return string(abi.encodePacked("sp-", IERC20Metadata(vault).symbol()));
    }

    /// @inheritdoc BaseForm
    function getStateRegistryId() external view override returns (uint8) {
        return STATE_REGISTRY_ID;
    }

    function getAccruedRewards(address user) public view virtual returns (uint256[] memory rewards) {
        rewards = IStandardizedYield(vault).accruedRewards(user);
    }

    function getRewardIndexesStored() public view virtual returns (uint256[] memory indexes) {
        indexes = IStandardizedYield(vault).rewardIndexesStored();
    }

    function getRewardTokens() public view virtual returns (address[] memory rewardTokens) {
        rewardTokens = IStandardizedYield(vault).getRewardTokens();
    }

    function getYieldToken() public view virtual returns (address yieldToken) {
        yieldToken = IStandardizedYield(vault).yieldToken();
    }

    function getTokensIn() public view virtual returns (address[] memory tokensIn) {
        tokensIn = IStandardizedYield(vault).getTokensIn();
    }

    function getTokensOut() public view virtual returns (address[] memory tokensOut) {
        tokensOut = IStandardizedYield(vault).getTokensOut();
    }

    function isValidTokenIn(address token) public view virtual returns (bool) {
        return IStandardizedYield(vault).isValidTokenIn(token);
    }

    function isValidTokenOut(address token) public view virtual returns (bool) {
        return IStandardizedYield(vault).isValidTokenOut(token);
    }

    function previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    )
        public
        view
        virtual
        returns (uint256 amountSharesOut)
    {
        amountSharesOut = IStandardizedYield(vault).previewDeposit(tokenIn, amountTokenToDeposit);
    }

    function previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    )
        public
        view
        virtual
        returns (uint256 amountTokenOut)
    {
        amountTokenOut = IStandardizedYield(vault).previewRedeem(tokenOut, amountSharesToRedeem);
    }

    function getAssetInfo()
        public
        view
        virtual
        returns (IStandardizedYield.AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        (assetType, assetAddress, assetDecimals) = IStandardizedYield(vault).assetInfo();
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc BaseForm
    function _directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address /*srcSender_*/
    )
        internal
        virtual
        override
        returns (uint256 shares)
    {
        shares = _processDirectDeposit(singleVaultData_);
    }

    /// @inheritdoc BaseForm
    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address, /*srcSender_*/
        uint64 srcChainId_
    )
        internal
        virtual
        override
        returns (uint256 shares)
    {
        shares = _processXChainDeposit(singleVaultData_, srcChainId_);
    }

    /// @inheritdoc BaseForm
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address /*srcSender_*/
    )
        internal
        virtual
        override
        returns (uint256 assets)
    {
        assets = _processDirectWithdraw(singleVaultData_);
    }

    /// @inheritdoc BaseForm
    function _xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address, /*srcSender_*/
        uint64 srcChainId_
    )
        internal
        virtual
        override
        returns (uint256 assets)
    {
        assets = _processXChainWithdraw(singleVaultData_, srcChainId_);
    }

    /// @inheritdoc BaseForm
    function _emergencyWithdraw(address receiverAddress_, uint256 amount_) internal virtual override {
        _processEmergencyWithdraw(receiverAddress_, amount_);
    }

    /// @inheritdoc BaseForm
    function _forwardDustToPaymaster(address token_) internal virtual override {
        _processForwardDustToPaymaster(token_);
    }

    function _processDirectDeposit(InitSingleVaultData memory singleVaultData_)
        internal
        virtual
        returns (uint256 shares)
    {
        DirectDepositLocalVars memory vars;

        vars.asset = address(asset);
        vars.balanceBefore = IERC20(vars.asset).balanceOf(address(this));
        IERC20 token = IERC20(singleVaultData_.liqData.token);

        if (address(token) != NATIVE && singleVaultData_.liqData.txData.length == 0) {
            /// @dev this is only valid if token == asset (no txData)
            if (singleVaultData_.liqData.token != vars.asset) revert Error.DIFFERENT_TOKENS();

            /// @dev handles the asset token transfers.
            if (token.allowance(msg.sender, address(this)) < singleVaultData_.amount) {
                revert Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();
            }

            /// @dev transfers input token, which is the same as vault asset, to the form
            token.safeTransferFrom(msg.sender, address(this), singleVaultData_.amount);
        }

        /// @dev non empty txData means there is a swap needed before depositing (input asset not the same as vault
        /// asset)
        if (singleVaultData_.liqData.txData.length != 0) {
            vars.bridgeValidator = superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId);

            vars.chainId = CHAIN_ID;

            vars.inputAmount =
                IBridgeValidator(vars.bridgeValidator).decodeAmountIn(singleVaultData_.liqData.txData, false);

            if (address(token) != NATIVE) {
                /// @dev checks the allowance before transfer from router
                if (token.allowance(msg.sender, address(this)) < vars.inputAmount) {
                    revert Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();
                }

                /// @dev transfers input token, which is different from the vault asset, to the form
                token.safeTransferFrom(msg.sender, address(this), vars.inputAmount);
            }

            IBridgeValidator(vars.bridgeValidator).validateTxData(
                IBridgeValidator.ValidateTxDataArgs(
                    singleVaultData_.liqData.txData,
                    vars.chainId,
                    vars.chainId,
                    vars.chainId,
                    true,
                    address(this),
                    msg.sender,
                    address(token),
                    address(0)
                )
            );

            _dispatchTokens(
                superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                singleVaultData_.liqData.txData,
                address(token),
                vars.inputAmount,
                singleVaultData_.liqData.nativeAmount
            );

            if (
                IBridgeValidator(vars.bridgeValidator).decodeSwapOutputToken(singleVaultData_.liqData.txData)
                    != vars.asset
            ) {
                revert Error.DIFFERENT_TOKENS();
            }
        }

        vars.assetDifference = IERC20(vars.asset).balanceOf(address(this)) - vars.balanceBefore;

        /// @dev the difference in vault tokens, ready to be deposited, is compared with the amount inscribed in the
        /// superform data
        if (
            vars.assetDifference * ENTIRE_SLIPPAGE
                < singleVaultData_.amount * (ENTIRE_SLIPPAGE - singleVaultData_.maxSlippage)
        ) {
            revert Error.DIRECT_DEPOSIT_SWAP_FAILED();
        }

        /// @dev notice that vars.assetDifference is deposited regardless if txData exists or not
        /// @dev this presumes no dust is left in the superform
        IERC20(vars.asset).safeIncreaseAllowance(vault, vars.assetDifference);

        /// @dev deposit assets for shares and add extra validation check to ensure intended ERC4626 behavior
        shares = _depositAndValidate(singleVaultData_, vars.assetDifference);
    }

    function _processXChainDeposit(
        InitSingleVaultData memory singleVaultData_,
        uint64 srcChainId_
    )
        internal
        virtual
        returns (uint256 shares)
    {
        (,, uint64 dstChainId) = singleVaultData_.superformId.getSuperform();
        address vaultLoc = vault;

        if (IERC20(asset).allowance(msg.sender, address(this)) < singleVaultData_.amount) {
            revert Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();
        }

        /// @dev pulling from sender, to auto-send tokens back in case of failed deposits / reverts
        IERC20(asset).safeTransferFrom(msg.sender, address(this), singleVaultData_.amount);

        /// @dev allowance is modified inside of the IERC20.transferFrom() call
        IERC20(asset).safeIncreaseAllowance(vaultLoc, singleVaultData_.amount);

        /// @dev deposit assets for shares and add extra validation check to ensure intended ERC4626 behavior
        shares = _depositAndValidate(singleVaultData_, singleVaultData_.amount);

        emit Processed(srcChainId_, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vaultLoc);
    }

    function _processDirectWithdraw(InitSingleVaultData memory singleVaultData_)
        internal
        virtual
        returns (uint256 assets)
    {
        DirectWithdrawLocalVars memory vars;

        /// @dev if there is no txData, on withdraws the receiver is receiverAddress, otherwise it
        /// is this contract (before swap)

        IStandardizedYield v = IStandardizedYield(vault);
        IERC20 a = IERC20(asset);

        if (!singleVaultData_.retain4626) {
            vars.asset = address(asset);

            /// @dev redeem shares for assets and add extra validation check to ensure intended ERC4626 behavior
            assets = _withdrawAndValidate(singleVaultData_, v, a);

            if (singleVaultData_.liqData.txData.length != 0) {
                vars.bridgeValidator = superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId);
                vars.amount =
                    IBridgeValidator(vars.bridgeValidator).decodeAmountIn(singleVaultData_.liqData.txData, false);

                /// @dev the amount inscribed in liqData must be less or equal than the amount redeemed from the vault
                /// @dev if less it should be within the slippage limit specified by the user
                /// @dev important to maintain so that the keeper cannot update with malicious data after successful
                /// withdraw
                if (_isWithdrawTxDataAmountInvalid(vars.amount, assets, singleVaultData_.maxSlippage)) {
                    revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();
                }

                vars.chainId = CHAIN_ID;

                /// @dev validate and perform the swap to desired output token and send to beneficiary
                IBridgeValidator(vars.bridgeValidator).validateTxData(
                    IBridgeValidator.ValidateTxDataArgs(
                        singleVaultData_.liqData.txData,
                        vars.chainId,
                        vars.chainId,
                        singleVaultData_.liqData.liqDstChainId,
                        false,
                        address(this),
                        singleVaultData_.receiverAddress,
                        vars.asset,
                        address(0)
                    )
                );

                _dispatchTokens(
                    superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                    singleVaultData_.liqData.txData,
                    vars.asset,
                    vars.amount,
                    singleVaultData_.liqData.nativeAmount
                );
            }
        } else {
            /// @dev transfer shares to user and do not redeem shares for assets
            v.safeTransfer(singleVaultData_.receiverAddress, singleVaultData_.amount);
            return 0;
        }
    }

    function _processXChainWithdraw(
        InitSingleVaultData memory singleVaultData_,
        uint64 srcChainId_
    )
        internal
        virtual
        returns (uint256 assets)
    {
        XChainWithdrawLocalVars memory vars;

        uint256 len = singleVaultData_.liqData.txData.length;
        /// @dev a case where the withdraw req liqData has a valid token and tx data is not updated by the keeper
        if (singleVaultData_.liqData.token != address(0) && len == 0) {
            revert Error.WITHDRAW_TX_DATA_NOT_UPDATED();
        } else if (singleVaultData_.liqData.token == address(0) && len != 0) {
            revert Error.WITHDRAW_TOKEN_NOT_UPDATED();
        }

        (,, vars.dstChainId) = singleVaultData_.superformId.getSuperform();

        IStandardizedYield v = IStandardizedYield(vault);
        IERC20 a = IERC20(asset);
        if (!singleVaultData_.retain4626) {
            vars.asset = address(asset);

            /// @dev redeem shares for assets and add extra validation check to ensure intended ERC4626 behavior
            assets = _withdrawAndValidate(singleVaultData_, v, a);

            if (len != 0) {
                vars.bridgeValidator = superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId);
                vars.amount =
                    IBridgeValidator(vars.bridgeValidator).decodeAmountIn(singleVaultData_.liqData.txData, false);

                /// @dev the amount inscribed in liqData must be less or equal than the amount redeemed from the vault
                /// @dev if less it should be within the slippage limit specified by the user
                /// @dev important to maintain so that the keeper cannot update with malicious data after successful
                /// withdraw
                if (_isWithdrawTxDataAmountInvalid(vars.amount, assets, singleVaultData_.maxSlippage)) {
                    revert Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();
                }

                /// @dev validate and perform the swap to desired output token and send to beneficiary
                IBridgeValidator(vars.bridgeValidator).validateTxData(
                    IBridgeValidator.ValidateTxDataArgs(
                        singleVaultData_.liqData.txData,
                        vars.dstChainId,
                        srcChainId_,
                        singleVaultData_.liqData.liqDstChainId,
                        false,
                        address(this),
                        singleVaultData_.receiverAddress,
                        vars.asset,
                        address(0)
                    )
                );

                _dispatchTokens(
                    superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                    singleVaultData_.liqData.txData,
                    vars.asset,
                    vars.amount,
                    singleVaultData_.liqData.nativeAmount
                );
            }
        } else {
            /// @dev transfer shares to user and do not redeem shares for assets
            v.safeTransfer(singleVaultData_.receiverAddress, singleVaultData_.amount);
            return 0;
        }

        emit Processed(srcChainId_, vars.dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vault);
    }

    function _depositAndValidate(
        InitSingleVaultData memory singleVaultData_,
        uint256 assetDifference
    )
        internal
        returns (uint256 shares)
    {
        IStandardizedYield v = IStandardizedYield(vault);

        address sharesReceiver = singleVaultData_.retain4626 ? singleVaultData_.receiverAddress : address(this);

        uint256 sharesBalanceBefore = v.balanceOf(sharesReceiver);

        uint256 minSharesOut = singleVaultData_.outputAmount * (ENTIRE_SLIPPAGE - singleVaultData_.maxSlippage);

        if (!isValidTokenIn(asset)) {
            revert INVALID_TOKEN_IN();
        }

        shares = v.deposit(sharesReceiver, singleVaultData_.liqData.token, assetDifference, minSharesOut);

        uint256 sharesBalanceAfter = v.balanceOf(sharesReceiver);

        if ((sharesBalanceAfter - sharesBalanceBefore != shares) || (ENTIRE_SLIPPAGE * shares < minSharesOut)) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }
    }

    function _withdrawAndValidate(
        InitSingleVaultData memory singleVaultData_,
        IStandardizedYield v,
        IERC20 a
    )
        internal
        returns (uint256 assets)
    {
        address assetsReceiver =
            singleVaultData_.liqData.txData.length == 0 ? singleVaultData_.receiverAddress : address(this);

        uint256 assetsBalanceBefore = a.balanceOf(assetsReceiver);

        uint256 minTokenOut = singleVaultData_.outputAmount * (ENTIRE_SLIPPAGE - singleVaultData_.maxSlippage);

        if (!isValidTokenOut(asset)) {
            revert INVALID_TOKEN_IN();
        }

        assets = v.redeem(assetsReceiver, singleVaultData_.amount, asset, minTokenOut, false);

        uint256 assetsBalanceAfter = a.balanceOf(assetsReceiver);

        if ((assetsBalanceAfter - assetsBalanceBefore != assets) || (ENTIRE_SLIPPAGE * assets < minTokenOut)) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }

        if (assets == 0) revert Error.WITHDRAW_ZERO_COLLATERAL();
    }

    function _isWithdrawTxDataAmountInvalid(
        uint256 bridgeDecodedAmount_,
        uint256 redeemedAmount_,
        uint256 slippage_
    )
        internal
        pure
        returns (bool isInvalid)
    {
        if (
            bridgeDecodedAmount_ > redeemedAmount_
                || ((bridgeDecodedAmount_ * ENTIRE_SLIPPAGE) < (redeemedAmount_ * (ENTIRE_SLIPPAGE - slippage_)))
        ) return true;
    }

    function _processEmergencyWithdraw(address receiverAddress_, uint256 amount_) internal {
        IStandardizedYield v = IStandardizedYield(vault);
        if (receiverAddress_ == address(0)) revert Error.ZERO_ADDRESS();

        if (v.balanceOf(address(this)) < amount_) {
            revert Error.INSUFFICIENT_BALANCE();
        }

        v.safeTransfer(receiverAddress_, amount_);

        emit EmergencyWithdrawalProcessed(receiverAddress_, amount_);
    }

    function _processForwardDustToPaymaster(address token_) internal {
        if (token_ == address(0)) revert Error.ZERO_ADDRESS();

        address paymaster = superRegistry.getAddress(keccak256("PAYMASTER"));
        IERC20 token = IERC20(token_);

        uint256 dust = token.balanceOf(address(this));
        if (dust != 0) {
            token.safeTransfer(paymaster, dust);
            emit FormDustForwardedToPaymaster(token_, dust);
        }
    }
}

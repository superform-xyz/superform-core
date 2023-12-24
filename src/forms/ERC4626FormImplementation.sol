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
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

/// @title ERC4626FormImplementation
/// @dev Has common internal functions that can be re-used by actual form implementations
/// @author Zeropoint Labs
abstract contract ERC4626FormImplementation is BaseForm, LiquidityHandler {

    using SafeERC20 for IERC20;
    using SafeERC20 for IERC4626;
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                         //
    //////////////////////////////////////////////////////////////

    uint8 internal immutable STATE_REGISTRY_ID;
    uint256 private constant ENTIRE_SLIPPAGE = 10_000;

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
        address receiver;
        address bridgeValidator;
        uint256 len1;
        uint256 amount;
    }

    struct XChainWithdrawLocalVars {
        uint64 dstChainId;
        address receiver;
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
    function getTotalSupply() public view virtual override returns (uint256) {
        return IERC4626(vault).totalSupply();
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

    /// @inheritdoc BaseForm
    function previewRedeemFrom(uint256 shares_) public view virtual override returns (uint256) {
        return IERC4626(vault).previewRedeem(shares_);
    }

    /// @inheritdoc BaseForm
    function superformYieldTokenName() external view virtual override returns (string memory) {
        return string(abi.encodePacked("Superform ", IERC20Metadata(vault).name()));
    }

    /// @inheritdoc BaseForm
    function superformYieldTokenSymbol() external view virtual override returns (string memory) {
        return string(abi.encodePacked("SUP-", IERC20Metadata(vault).symbol()));
    }

    /// @inheritdoc BaseForm
    function getStateRegistryId() external view override returns (uint8) {
        return STATE_REGISTRY_ID;
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    function _processDirectDeposit(InitSingleVaultData memory singleVaultData_) internal returns (uint256 shares) {
        DirectDepositLocalVars memory vars;

        IERC4626 v = IERC4626(vault);
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
        address sharesReceiver = singleVaultData_.retain4626 ? singleVaultData_.receiverAddress : address(this);
        uint256 sharesBalanceBefore = v.balanceOf(sharesReceiver);
        shares = v.deposit(vars.assetDifference, sharesReceiver);
        uint256 sharesBalanceAfter = v.balanceOf(sharesReceiver);
        if (sharesBalanceAfter - sharesBalanceBefore != shares) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }
    }

    function _processXChainDeposit(
        InitSingleVaultData memory singleVaultData_,
        uint64 srcChainId_
    )
        internal
        returns (uint256 shares)
    {
        (,, uint64 dstChainId) = singleVaultData_.superformId.getSuperform();
        address vaultLoc = vault;

        IERC4626 v = IERC4626(vaultLoc);

        if (IERC20(asset).allowance(msg.sender, address(this)) < singleVaultData_.amount) {
            revert Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();
        }

        /// @dev pulling from sender, to auto-send tokens back in case of failed deposits / reverts
        IERC20(asset).safeTransferFrom(msg.sender, address(this), singleVaultData_.amount);

        /// @dev allowance is modified inside of the IERC20.transferFrom() call
        IERC20(asset).safeIncreaseAllowance(vaultLoc, singleVaultData_.amount);

        /// @dev deposit assets for shares and add extra validation check to ensure intended ERC4626 behavior
        address sharesReceiver = singleVaultData_.retain4626 ? singleVaultData_.receiverAddress : address(this);
        uint256 sharesBalanceBefore = v.balanceOf(sharesReceiver);
        shares = v.deposit(singleVaultData_.amount, sharesReceiver);
        uint256 sharesBalanceAfter = v.balanceOf(sharesReceiver);
        if (sharesBalanceAfter - sharesBalanceBefore != shares) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }

        emit Processed(srcChainId_, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vaultLoc);
    }

    function _processDirectWithdraw(InitSingleVaultData memory singleVaultData_) internal returns (uint256 assets) {
        DirectWithdrawLocalVars memory vars;
        vars.len1 = singleVaultData_.liqData.txData.length;

        /// @dev if there is no txData, on withdraws the receiver is receiverAddress, otherwise it
        /// is this contract (before swap)
        vars.receiver = vars.len1 == 0 ? singleVaultData_.receiverAddress : address(this);

        IERC4626 v = IERC4626(vault);
        IERC20 a = IERC20(asset);

        if (!singleVaultData_.retain4626) {
            vars.asset = address(asset);

            /// @dev redeem shares for assets and add extra validation check to ensure intended ERC4626 behavior
            uint256 assetsBalanceBefore = a.balanceOf(vars.receiver);
            assets = v.redeem(singleVaultData_.amount, vars.receiver, address(this));
            uint256 assetsBalanceAfter = a.balanceOf(vars.receiver);
            if (assetsBalanceAfter - assetsBalanceBefore != assets) {
                revert Error.VAULT_IMPLEMENTATION_FAILED();
            }

            if (assets == 0) revert Error.WITHDRAW_ZERO_COLLATERAL();

            if (vars.len1 != 0) {
                vars.bridgeValidator = superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId);
                vars.amount =
                    IBridgeValidator(vars.bridgeValidator).decodeAmountIn(singleVaultData_.liqData.txData, false);

                /// @dev the amount inscribed in liqData must be less or equal than the amount redeemed from the vault
                if (vars.amount > assets) revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

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

        /// @dev receiverAddress is checked for existence on source
        /// @dev user will either provide an address equal to msg.sender (if EOA)
        /// @dev or user will specify an address on the target chain for the collateral extraction (if Smart Contract
        /// Wallet)
        vars.receiver = len == 0 ? singleVaultData_.receiverAddress : address(this);

        IERC4626 v = IERC4626(vault);
        IERC20 a = IERC20(asset);
        if (!singleVaultData_.retain4626) {
            vars.asset = address(asset);

            /// @dev redeem shares for assets and add extra validation check to ensure intended ERC4626 behavior
            uint256 assetsBalanceBefore = a.balanceOf(vars.receiver);
            assets = v.redeem(singleVaultData_.amount, vars.receiver, address(this));
            uint256 assetsBalanceAfter = a.balanceOf(vars.receiver);
            if (assetsBalanceAfter - assetsBalanceBefore != assets) {
                revert Error.VAULT_IMPLEMENTATION_FAILED();
            }

            if (assets == 0) revert Error.WITHDRAW_ZERO_COLLATERAL();

            if (len != 0) {
                vars.bridgeValidator = superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId);
                vars.amount =
                    IBridgeValidator(vars.bridgeValidator).decodeAmountIn(singleVaultData_.liqData.txData, false);

                /// @dev the amount inscribed in liqData must be less or equal than the amount redeemed from the vault
                if (vars.amount > assets) revert Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();

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

    function _processEmergencyWithdraw(address receiverAddress_, uint256 amount_) internal {
        IERC4626 v = IERC4626(vault);
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

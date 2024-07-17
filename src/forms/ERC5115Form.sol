// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BaseForm } from "src/BaseForm.sol";
import { LiquidityHandler } from "src/crosschain-liquidity/LiquidityHandler.sol";
import { IERC5115Form, IStandardizedYield, IBridgeValidator, IERC20 } from "src/forms/interfaces/IERC5115Form.sol";
import { Error } from "src/libraries/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { InitSingleVaultData } from "src/types/DataTypes.sol";
import { IERC20Metadata } from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC5115To4626Wrapper } from "src/forms/interfaces/IERC5115To4626Wrapper.sol";

/// @title ERC5115Form
/// @dev Implementation of the Form contract for ERC5115 vaults
/// @notice The vault variable refers to the wrapper address, not the underlying 5115
/// @author Zeropoint Labs
contract ERC5115Form is IERC5115Form, BaseForm, LiquidityHandler {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC5115To4626Wrapper;
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                         //
    //////////////////////////////////////////////////////////////

    /// @dev Identifier for the CoreStateRegistry
    uint8 constant stateRegistryId = 1;

    /// @dev Tolerance constant to account for tokens with rounding issues on transfer
    uint256 constant TOLERANCE_CONSTANT = 10 wei;

    /// @dev Represents 100% in basis points
    uint256 internal constant ENTIRE_SLIPPAGE = 10_000;

    /// @dev Represents zero address
    address internal constant ZERO_ADDRESS = address(0);

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    /// @param superRegistry_ The address of the super registry contract
    constructor(address superRegistry_) BaseForm(superRegistry_) { }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IERC5115Form
    function claimRewardTokens(bool avoidRevert) public virtual override {
        address[] memory rewardTokens = getRewardTokens();

        try IERC5115To4626Wrapper(vault).claimRewards(address(this)) returns (uint256[] memory rewardAmounts) {
            if (rewardAmounts.length != rewardTokens.length) {
                if (!avoidRevert) {
                    revert Error.ARRAY_LENGTH_MISMATCH();
                }
            } else {
                address rewardsDistributor = superRegistry.getAddress(keccak256("REWARDS_DISTRIBUTOR"));

                for (uint256 i = 0; i < rewardTokens.length; ++i) {
                    IERC20 rewardToken = IERC20(rewardTokens[i]);
                    if (address(rewardToken) == vault) {
                        if (!avoidRevert) {
                            revert Error.CANNOT_FORWARD_4646_TOKEN();
                        }
                    } else {
                        rewardToken.safeTransfer(rewardsDistributor, rewardToken.balanceOf(address(this)));
                    }
                }
            }
        } catch {
            if (!avoidRevert) {
                revert FUNCTION_NOT_IMPLEMENTED();
            }
        }
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc BaseForm
    function getVaultName() public view virtual override returns (string memory) {
        return IERC5115To4626Wrapper(vault).name();
    }

    /// @inheritdoc BaseForm
    function getVaultSymbol() public view virtual override returns (string memory) {
        return IERC5115To4626Wrapper(vault).symbol();
    }

    /// @inheritdoc BaseForm
    function getVaultDecimals() public view virtual override returns (uint256) {
        return uint256(IERC5115To4626Wrapper(vault).decimals());
    }

    /// @inheritdoc BaseForm
    function getPricePerVaultShare() public view virtual override returns (uint256) {
        return IERC5115To4626Wrapper(vault).exchangeRate();
    }

    /// @inheritdoc BaseForm
    function getVaultShareBalance() public view virtual override returns (uint256) {
        return IERC5115To4626Wrapper(IERC5115To4626Wrapper(vault).getUnderlying5115Vault()).balanceOf(address(this));
    }

    /// @inheritdoc BaseForm
    function getTotalAssets() public view virtual override returns (uint256) {
        return IERC20Metadata(asset).balanceOf(IERC5115To4626Wrapper(vault).getUnderlying5115Vault());
    }

    /// @inheritdoc BaseForm
    function getTotalSupply() public view virtual override returns (uint256) {
        return IERC20Metadata(IERC5115To4626Wrapper(vault).getUnderlying5115Vault()).totalSupply();
    }

    /// @inheritdoc BaseForm
    function getPreviewPricePerVaultShare() public view virtual override returns (uint256) {
        return IERC5115To4626Wrapper(vault).exchangeRate();
    }

    /// @inheritdoc BaseForm
    function previewDepositTo(uint256 assets_) public view virtual override returns (uint256) {
        return IERC5115To4626Wrapper(vault).previewDeposit(asset, assets_);
    }

    /// @inheritdoc BaseForm
    function previewWithdrawFrom(uint256 /*assets_*/ ) public view virtual override returns (uint256) {
        return 0;
    }

    /// @inheritdoc BaseForm
    function previewRedeemFrom(uint256 shares_) public view virtual override returns (uint256) {
        return IERC5115To4626Wrapper(vault).previewRedeem(asset, shares_);
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
    function getStateRegistryId() external pure override returns (uint8) {
        return stateRegistryId;
    }

    /// @inheritdoc IERC5115Form
    function getAccruedRewards(address user) public view virtual override returns (uint256[] memory) {
        try IERC5115To4626Wrapper(vault).accruedRewards(user) returns (uint256[] memory rewards) {
            return rewards;
        } catch {
            revert FUNCTION_NOT_IMPLEMENTED();
        }
    }

    /// @inheritdoc IERC5115Form
    function getRewardIndexesStored() public view virtual override returns (uint256[] memory) {
        try IERC5115To4626Wrapper(vault).rewardIndexesStored() returns (uint256[] memory indexes) {
            return indexes;
        } catch {
            revert FUNCTION_NOT_IMPLEMENTED();
        }
    }

    /// @inheritdoc IERC5115Form
    function getRewardTokens() public view virtual override returns (address[] memory) {
        try IERC5115To4626Wrapper(vault).getRewardTokens() returns (address[] memory rewardTokens) {
            return rewardTokens;
        } catch {
            revert FUNCTION_NOT_IMPLEMENTED();
        }
    }

    /// @inheritdoc IERC5115Form
    function getYieldToken() public view virtual override returns (address yieldToken) {
        yieldToken = IERC5115To4626Wrapper(vault).yieldToken();
    }

    /// @inheritdoc IERC5115Form
    function getTokensIn() public view virtual override returns (address[] memory tokensIn) {
        tokensIn = IERC5115To4626Wrapper(vault).getTokensIn();
    }

    /// @inheritdoc IERC5115Form
    function getTokensOut() public view virtual override returns (address[] memory tokensOut) {
        tokensOut = IERC5115To4626Wrapper(vault).getTokensOut();
    }

    /// @inheritdoc IERC5115Form
    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return IERC5115To4626Wrapper(vault).isValidTokenIn(token);
    }

    /// @inheritdoc IERC5115Form
    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return IERC5115To4626Wrapper(vault).isValidTokenOut(token);
    }

    /// @inheritdoc IERC5115Form
    function getAssetInfo()
        public
        view
        virtual
        returns (IStandardizedYield.AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        (assetType, assetAddress, assetDecimals) = IERC5115To4626Wrapper(vault).assetInfo();
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
        /// @dev we try to claim rewards - for vaults where one of the token in is the reward tokens, this prevents
        /// attack behaviours that would steal
        /// @dev those tokens from the superform

        claimRewardTokens(true);

        DirectDepositLocalVars memory vars;

        /// @dev gets a snapshot of vault token in
        vars.vaultTokenIn =
            IERC20(_decode5115ExtraFormData(singleVaultData_.superformId, singleVaultData_.extraFormData));

        vars.balanceBefore = vars.vaultTokenIn.balanceOf(address(this));
        vars.sendingToken = IERC20(singleVaultData_.liqData.token);

        /// @dev swaps the input token to vaultTokenIn (where tx data is present)
        if (singleVaultData_.liqData.txData.length != 0) {
            vars.bridgeValidator = IBridgeValidator(superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId));

            if (
                vars.bridgeValidator.decodeSwapOutputToken(singleVaultData_.liqData.txData)
                    != address(vars.vaultTokenIn)
            ) {
                revert Error.DIFFERENT_TOKENS();
            }

            vars.inputAmount = vars.bridgeValidator.decodeAmountIn(singleVaultData_.liqData.txData, false);

            if (address(vars.sendingToken) != NATIVE) {
                _checkAllowanceAndTransferIn(vars.sendingToken, vars.inputAmount);
            }

            vars.chainId = CHAIN_ID;

            vars.bridgeValidator.validateTxData(
                IBridgeValidator.ValidateTxDataArgs(
                    singleVaultData_.liqData.txData,
                    vars.chainId,
                    vars.chainId,
                    vars.chainId,
                    true,
                    address(this),
                    msg.sender,
                    address(vars.sendingToken),
                    ZERO_ADDRESS
                )
            );

            _dispatchTokens(
                superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                singleVaultData_.liqData.txData,
                address(vars.sendingToken),
                vars.inputAmount,
                singleVaultData_.liqData.nativeAmount
            );
        } else {
            /// @dev transfers in token if no swap is needed
            if (address(vars.sendingToken) != NATIVE) {
                /// @notice if no swap is present, then the vaultTokenIn should be transferred in by the user
                if (address(vars.sendingToken) != address(vars.vaultTokenIn)) revert Error.DIFFERENT_TOKENS();
                _checkAllowanceAndTransferIn(vars.sendingToken, singleVaultData_.amount);
            }
        }

        /// @dev validates the swap
        vars.assetDifference = vars.vaultTokenIn.balanceOf(address(this)) - vars.balanceBefore;

        /// @dev validates slippage post swap
        if (
            vars.assetDifference * ENTIRE_SLIPPAGE
                < singleVaultData_.amount * (ENTIRE_SLIPPAGE - singleVaultData_.maxSlippage)
        ) {
            revert Error.DIRECT_DEPOSIT_SWAP_FAILED();
        }

        /// @notice vars.assetDifference is deposited regardless if txData exists
        /// @dev no dust is left in the superform
        vars.vaultTokenIn.safeIncreaseAllowance(vault, vars.assetDifference);

        /// @dev deposit assets for shares and add extra validation check to ensure intended ERC5115 behavior
        shares = _depositAndValidate(singleVaultData_, vars.assetDifference);
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
        address vaultLoc = vault;
        address vaultTokenIn = _decode5115ExtraFormData(singleVaultData_.superformId, singleVaultData_.extraFormData);

        if (IERC20(vaultTokenIn).allowance(msg.sender, address(this)) < singleVaultData_.amount) {
            revert Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();
        }

        uint256 balanceBefore = IERC20(vaultTokenIn).balanceOf(address(this));
        /// @dev pulling from sender, to auto-send tokens back in case of failed deposits / reverts
        IERC20(vaultTokenIn).safeTransferFrom(msg.sender, address(this), singleVaultData_.amount);

        /// @dev allowance is modified inside of the IERC20.transferFrom() call
        IERC20(vaultTokenIn).safeIncreaseAllowance(vaultLoc, singleVaultData_.amount);

        /// @dev to account for tokens with rounding issues during transfer like stETH
        /// @dev please refer: https://github.com/lidofinance/lido-dao/issues/442
        singleVaultData_.amount = IERC20(vaultTokenIn).balanceOf(address(this)) - balanceBefore;

        /// @dev deposit vaultTokenIn for shares and add extra validation check to ensure intended ERC5115 behavior
        shares = _depositAndValidate(singleVaultData_, singleVaultData_.amount);

        (,, uint64 dstChainId) = singleVaultData_.superformId.getSuperform();
        emit Processed(srcChainId_, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vaultLoc);
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
        /// @dev for withdraws interimToken is used as tokenOut (as extraFormData is overriden in CSR, so cannot be used
        /// to send this intent)
        IERC20 vaultTokenOut = IERC20(singleVaultData_.liqData.interimToken);

        /// @dev notice that by validating it like this, it will deny any tokenOut that is native (sometimes addressed
        /// as address 0)
        if (address(vaultTokenOut) == ZERO_ADDRESS) revert ERC5115FORM_TOKEN_OUT_NOT_SET();

        if (!singleVaultData_.retain4626) {
            /// @dev redeem shares for assets and add extra validation check to ensure intended ERC5115 behavior
            assets = _withdrawAndValidate(singleVaultData_, IERC5115To4626Wrapper(vault), address(vaultTokenOut));

            if (singleVaultData_.liqData.txData.length != 0) {
                IBridgeValidator bridgeValidator =
                    IBridgeValidator(superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId));

                uint256 amount = bridgeValidator.decodeAmountIn(singleVaultData_.liqData.txData, false);

                /// @dev the amount inscribed in liqData must be less or equal than the amount redeemed from the vault
                /// @dev if less it should be within the slippage limit specified by the user
                /// @dev important to maintain so that the keeper cannot update with malicious data after successful
                /// withdraw
                if (_isWithdrawTxDataAmountInvalid(amount, assets, singleVaultData_.maxSlippage)) {
                    revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();
                }

                uint64 chainId = CHAIN_ID;

                /// @dev validate and perform the swap to desired output token and send to beneficiary
                bridgeValidator.validateTxData(
                    IBridgeValidator.ValidateTxDataArgs(
                        singleVaultData_.liqData.txData,
                        chainId,
                        chainId,
                        singleVaultData_.liqData.liqDstChainId,
                        false,
                        address(this),
                        singleVaultData_.receiverAddress,
                        address(vaultTokenOut),
                        ZERO_ADDRESS
                    )
                );

                _dispatchTokens(
                    superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                    singleVaultData_.liqData.txData,
                    address(vaultTokenOut),
                    amount,
                    singleVaultData_.liqData.nativeAmount
                );
            }
        } else {
            /// @dev transfer shares to user and do not redeem shares for assets
            IERC20(IERC5115To4626Wrapper(vault).getUnderlying5115Vault()).safeTransfer(
                singleVaultData_.receiverAddress, singleVaultData_.amount
            );

            emit Retain4626();
        }
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
        /// @dev for withdraws interimToken is used as tokenOut (as extraFormData is overriden in CSR, so cannot be used
        /// to send this intent)
        IERC20 vaultTokenOut = IERC20(singleVaultData_.liqData.interimToken);

        /// @dev notice that by validating it like this, it will deny any tokenOut that is native (sometimes addressed
        /// as address 0)
        if (address(vaultTokenOut) == ZERO_ADDRESS) revert ERC5115FORM_TOKEN_OUT_NOT_SET();

        uint256 len = singleVaultData_.liqData.txData.length;

        /// @dev a case where the withdraw req liqData has a valid token and tx data is not updated by the keeper
        if (singleVaultData_.liqData.token != ZERO_ADDRESS && len == 0) {
            revert Error.WITHDRAW_TX_DATA_NOT_UPDATED();
        } else if (singleVaultData_.liqData.token == ZERO_ADDRESS && len != 0) {
            revert Error.WITHDRAW_TOKEN_NOT_UPDATED();
        }

        (,, uint64 dstChainId) = singleVaultData_.superformId.getSuperform();

        if (!singleVaultData_.retain4626) {
            /// @dev redeem shares for assets and add extra validation check to ensure intended ERC5115 behavior
            assets = _withdrawAndValidate(singleVaultData_, IERC5115To4626Wrapper(vault), address(vaultTokenOut));

            if (len != 0) {
                IBridgeValidator bridgeValidator =
                    IBridgeValidator(superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId));
                uint256 amount = bridgeValidator.decodeAmountIn(singleVaultData_.liqData.txData, false);

                /// @dev the amount inscribed in liqData must be less or equal than the amount redeemed from the vault
                /// @dev if less it should be within the slippage limit specified by the user
                /// @dev important to maintain so that the keeper cannot update with malicious data after successful
                /// withdraw
                if (_isWithdrawTxDataAmountInvalid(amount, assets, singleVaultData_.maxSlippage)) {
                    revert Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();
                }

                /// @dev validate and perform the swap to desired output token and send to beneficiary
                bridgeValidator.validateTxData(
                    IBridgeValidator.ValidateTxDataArgs(
                        singleVaultData_.liqData.txData,
                        dstChainId,
                        srcChainId_,
                        singleVaultData_.liqData.liqDstChainId,
                        false,
                        address(this),
                        singleVaultData_.receiverAddress,
                        address(vaultTokenOut),
                        ZERO_ADDRESS
                    )
                );

                _dispatchTokens(
                    superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                    singleVaultData_.liqData.txData,
                    address(vaultTokenOut),
                    amount,
                    singleVaultData_.liqData.nativeAmount
                );
            }
        } else {
            /// @dev transfer shares to user and do not redeem shares for assets
            IERC20(IERC5115To4626Wrapper(vault).getUnderlying5115Vault()).safeTransfer(
                singleVaultData_.receiverAddress, singleVaultData_.amount
            );

            emit Retain4626();
        }

        emit Processed(srcChainId_, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vault);
    }

    /// @inheritdoc BaseForm
    function _emergencyWithdraw(address receiverAddress_, uint256 amount_) internal virtual override {
        IERC5115To4626Wrapper v = IERC5115To4626Wrapper(IERC5115To4626Wrapper(vault).getUnderlying5115Vault());
        if (receiverAddress_ == ZERO_ADDRESS) revert Error.ZERO_ADDRESS();

        if (v.balanceOf(address(this)) < amount_) {
            revert Error.INSUFFICIENT_BALANCE();
        }

        v.safeTransfer(receiverAddress_, amount_);

        emit EmergencyWithdrawalProcessed(receiverAddress_, amount_);
    }

    /// @inheritdoc BaseForm
    function _forwardDustToPaymaster(address token_) internal virtual override {
        if (token_ == ZERO_ADDRESS) revert Error.ZERO_ADDRESS();

        address paymaster = superRegistry.getAddress(keccak256("PAYMASTER"));
        IERC20 token = IERC20(token_);

        uint256 dust = token.balanceOf(address(this));
        if (dust != 0) {
            token.safeTransfer(paymaster, dust);
            emit FormDustForwardedToPaymaster(token_, dust);
        }
    }

    /// @dev helper to deposit to a 5115 vault
    function _depositAndValidate(
        InitSingleVaultData memory singleVaultData_,
        uint256 assetDifference_
    )
        internal
        returns (uint256 shares)
    {
        IERC5115To4626Wrapper v = IERC5115To4626Wrapper(vault);
        address sharesReceiver = singleVaultData_.retain4626 ? singleVaultData_.receiverAddress : address(this);

        uint256 sharesBalanceBefore = v.balanceOf(sharesReceiver);
        uint256 outputAmountMin =
            (singleVaultData_.outputAmount * (ENTIRE_SLIPPAGE - singleVaultData_.maxSlippage)) / ENTIRE_SLIPPAGE;

        /// @dev WARNING: validate if minSharesOut can be outputAmount (the result of previewDeposit)
        shares = v.deposit(sharesReceiver, assetDifference_, outputAmountMin);
        uint256 sharesBalanceAfter = v.balanceOf(sharesReceiver);

        if ((sharesBalanceAfter - sharesBalanceBefore != shares) || shares < outputAmountMin) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }

        if (singleVaultData_.retain4626) {
            emit Retain4626();
        }
    }

    /// @dev helper to withdraw from a 5115 vault
    function _withdrawAndValidate(
        InitSingleVaultData memory singleVaultData_,
        IERC5115To4626Wrapper v_,
        address vaultTokenOut_
    )
        internal
        returns (uint256 assets)
    {
        /// @dev if there is no txData, on withdraws the receiver is receiverAddress, otherwise it
        /// is this contract (before swap)
        address assetsReceiver =
            singleVaultData_.liqData.txData.length == 0 ? singleVaultData_.receiverAddress : address(this);

        uint256 assetsBalanceBefore = IERC20(vaultTokenOut_).balanceOf(assetsReceiver);

        IERC20 underlyingVault = IERC20(IERC5115To4626Wrapper(vault).getUnderlying5115Vault());

        /// @dev have to increase allowance as shares are moved to wrapper first
        underlyingVault.safeIncreaseAllowance(vault, singleVaultData_.amount);

        assets = v_.redeem(assetsReceiver, singleVaultData_.amount, singleVaultData_.outputAmount);

        uint256 assetsBalanceAfter = IERC20(vaultTokenOut_).balanceOf(assetsReceiver);

        if (assets < TOLERANCE_CONSTANT) revert Error.WITHDRAW_ZERO_COLLATERAL();

        if (
            (assetsBalanceAfter - assetsBalanceBefore < assets - TOLERANCE_CONSTANT)
                || (
                    ENTIRE_SLIPPAGE * assets
                        < singleVaultData_.outputAmount * (ENTIRE_SLIPPAGE - singleVaultData_.maxSlippage)
                )
        ) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }

        /// @dev reset allowance to wrapper
        if (underlyingVault.allowance(address(this), vault) > 0) underlyingVault.forceApprove(vault, 0);
    }

    /// @dev helper to validate the withdrawal amount
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

    /// @dev helper to decode extra form data
    function _decode5115ExtraFormData(
        uint256 superformId_,
        bytes memory extraFormData_
    )
        internal
        pure
        returns (address vaultTokenIn)
    {
        bool found5115;
        /// @dev for deposits tokenIn must be decoded from extraFormData as interimToken may be in use
        /// @dev Warning: This must be validated by a keeper to be the token received in CSR for the given payload, as
        /// this can be forged by the user
        /// @dev and it's not possible to validate on chain the final token post bridging/swapping
        (uint256 nVaults, bytes[] memory encodedDatas) = abi.decode(extraFormData_, (uint256, bytes[]));

        for (uint256 i = 0; i < nVaults; ++i) {
            (uint256 decodedSuperformId, bytes memory encodedSfData) = abi.decode(encodedDatas[i], (uint256, bytes));

            /// @dev notice that by validating it like this, it will deny any tokenIn that is native (sometimes
            /// addressed as address 0)
            if (decodedSuperformId == superformId_) {
                (vaultTokenIn) = abi.decode(encodedSfData, (address));
                if (vaultTokenIn != ZERO_ADDRESS) {
                    found5115 = true;
                    break;
                }
            }
        }

        if (!found5115) revert ERC5115FORM_TOKEN_IN_NOT_ENCODED();
    }

    /// @dev helper to transfer tokens from sender to address(this)
    function _checkAllowanceAndTransferIn(IERC20 token_, uint256 amount_) internal {
        /// @dev checks the allowance to process the transfer in
        if (token_.allowance(msg.sender, address(this)) < amount_) {
            revert Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();
        }

        /// @dev transfers token_ to this address
        token_.safeTransferFrom(msg.sender, address(this), amount_);
    }
}

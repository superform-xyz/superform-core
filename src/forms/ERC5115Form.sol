// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BaseForm } from "src/BaseForm.sol";
import { LiquidityHandler } from "src/crosschain-liquidity/LiquidityHandler.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { IERC5115Form } from "src/forms/interfaces/IERC5115Form.sol";
import { Error } from "src/libraries/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { InitSingleVaultData } from "src/types/DataTypes.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { IERC20Metadata } from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IStandardizedYield } from "src/vendor/pendle/IStandardizedYield.sol";
import { IERC5115To4626Wrapper } from "src/forms/interfaces/IERC5115To4626Wrapper.sol";

/// @title ERC5115Form
/// @dev The Form implementation for ERC5115 vaults
/// @notice vault variable refers to the wrapper address, not to the underlying 5115
/// @notice Reference implementation of a vault:
/// https://github.com/pendle-finance/pendle-core-v2-public/blob/main/contracts/core/StandardizedYield/SYBase.sol
/// @author Zeropoint Labs
contract ERC5115Form is IERC5115Form, BaseForm, LiquidityHandler {
    using SafeERC20 for IERC20;
    using SafeERC20 for IStandardizedYield;
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                           Errors                        //
    //////////////////////////////////////////////////////////////
    /// @dev opinionated function not part of the 5115 eip
    error FUNCTION_NOT_IMPLEMENTED();

    /// @dev Error emitted when the tokenIn is not encoded in the extraFormData
    error ERC5115FORM_TOKEN_IN_NOT_ENCODED();

    /// @dev Error emitted when the tokenOut is not set as the interimToken
    error ERC5115FORM_TOKEN_OUT_NOT_SET();

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                         //
    //////////////////////////////////////////////////////////////

    uint8 constant stateRegistryId = 1; // CoreStateRegistry
    uint256 internal constant ENTIRE_SLIPPAGE = 10_000;

    //////////////////////////////////////////////////////////////
    //                           STRUCTS                        //
    //////////////////////////////////////////////////////////////

    struct DirectDepositLocalVars {
        uint64 chainId;
        address vaultTokenIn;
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
        address vaultTokenOut;
        address bridgeValidator;
        uint256 amount;
    }

    struct XChainWithdrawLocalVars {
        uint64 dstChainId;
        address vaultTokenOut;
        address bridgeValidator;
        uint256 balanceBefore;
        uint256 balanceAfter;
        uint256 amount;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) BaseForm(superRegistry_) { }

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
        return IStandardizedYield(vault).exchangeRate();
    }

    /// @inheritdoc BaseForm
    function getVaultShareBalance() public view virtual override returns (uint256) {
        return IStandardizedYield(IERC5115To4626Wrapper(vault).getUnderlying5115Vault()).balanceOf(address(this));
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
        return IStandardizedYield(vault).exchangeRate();
    }

    /// @inheritdoc BaseForm
    function previewDepositTo(uint256 assets_) public view virtual override returns (uint256) {
        return IStandardizedYield(vault).previewDeposit(asset, assets_);
    }

    /// @inheritdoc BaseForm
    function previewWithdrawFrom(uint256 /*assets_*/ ) public view virtual override returns (uint256) {
        return 0;
    }

    /// @inheritdoc BaseForm
    function previewRedeemFrom(uint256 shares_) public view virtual override returns (uint256) {
        return IStandardizedYield(vault).previewRedeem(asset, shares_);
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
        try IStandardizedYield(vault).accruedRewards(user) returns (uint256[] memory rewards) {
            return rewards;
        } catch {
            revert FUNCTION_NOT_IMPLEMENTED();
        }
    }

    /// @inheritdoc IERC5115Form
    function getRewardIndexesStored() public view virtual override returns (uint256[] memory) {
        try IStandardizedYield(vault).rewardIndexesStored() returns (uint256[] memory indexes) {
            return indexes;
        } catch {
            revert FUNCTION_NOT_IMPLEMENTED();
        }
    }

    /// @inheritdoc IERC5115Form
    function getRewardTokens() public view virtual override returns (address[] memory) {
        try IStandardizedYield(vault).getRewardTokens() returns (address[] memory rewardTokens) {
            return rewardTokens;
        } catch {
            revert FUNCTION_NOT_IMPLEMENTED();
        }
    }

    /// @inheritdoc IERC5115Form
    function claimRewardTokens() external virtual override {
        address[] memory rewardTokens = getRewardTokens();

        /// @dev claim all reward tokens
        try IStandardizedYield(vault).claimRewards(address(this)) returns (uint256[] memory rewardAmounts) {
            if (rewardAmounts.length != rewardTokens.length) {
                revert Error.ARRAY_LENGTH_MISMATCH();
            }
        } catch {
            revert FUNCTION_NOT_IMPLEMENTED();
        }

        address rewardsDistributor = superRegistry.getAddress(keccak256("REWARDS_DISTIBUTOR"));
        if (rewardsDistributor == address(0)) revert Error.ZERO_ADDRESS();

        /// @dev forwards token to rewards distributor
        IERC20 rewardToken;
        for (uint256 i; i < rewardTokens.length; ++i) {
            rewardToken = IERC20(rewardTokens[i]);
            rewardToken.safeTransfer(rewardsDistributor, rewardToken.balanceOf(address(this)));
        }
    }

    /// @inheritdoc IERC5115Form
    function getYieldToken() public view virtual override returns (address yieldToken) {
        yieldToken = IStandardizedYield(vault).yieldToken();
    }

    /// @inheritdoc IERC5115Form
    function getTokensIn() public view virtual override returns (address[] memory tokensIn) {
        tokensIn = IStandardizedYield(vault).getTokensIn();
    }

    /// @inheritdoc IERC5115Form
    function getTokensOut() public view virtual override returns (address[] memory tokensOut) {
        tokensOut = IStandardizedYield(vault).getTokensOut();
    }

    /// @inheritdoc IERC5115Form
    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return IStandardizedYield(vault).isValidTokenIn(token);
    }

    /// @inheritdoc IERC5115Form
    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return IStandardizedYield(vault).isValidTokenOut(token);
    }

    /// @inheritdoc IERC5115Form
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

        /// @dev for deposits tokenIn must be decoded from extraFormData as interimToken may be in use
        /// @dev Warning: This must be validated by a keeper to be the token received in CSR for the given payload, as
        /// this can be forged by the user
        /// @dev and it's not possible to validate on chain the final token post bridging/swapping
        vars.vaultTokenIn = abi.decode(singleVaultData_.extraFormData, (address));

        /// @dev notice that by validating it like this, it will deny any tokenIn that is native (sometimes addressed as
        /// address 0)
        if (vars.vaultTokenIn == address(0)) revert ERC5115FORM_TOKEN_IN_NOT_ENCODED();

        vars.balanceBefore = IERC20(vars.vaultTokenIn).balanceOf(address(this));
        address sendingTokenAddress = singleVaultData_.liqData.token;
        IERC20 sendingToken = IERC20(sendingTokenAddress);

        if (sendingTokenAddress != NATIVE && singleVaultData_.liqData.txData.length == 0) {
            /// @dev this is only valid if sendingTokenAddress == vaultTokenIn (no txData)
            if (sendingTokenAddress != vars.vaultTokenIn) revert Error.DIFFERENT_TOKENS();

            /// @dev handles the vaultTokenIn token transfers.
            if (sendingToken.allowance(msg.sender, address(this)) < singleVaultData_.amount) {
                revert Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();
            }

            /// @dev transfers sendingToken to the form
            sendingToken.safeTransferFrom(msg.sender, address(this), singleVaultData_.amount);
        }

        /// @dev non empty txData means there is a swap needed before depositing (input asset not the same as vault
        /// asset)
        if (singleVaultData_.liqData.txData.length != 0) {
            vars.bridgeValidator = superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId);

            vars.chainId = CHAIN_ID;

            vars.inputAmount =
                IBridgeValidator(vars.bridgeValidator).decodeAmountIn(singleVaultData_.liqData.txData, false);

            if (sendingTokenAddress != NATIVE) {
                /// @dev checks the allowance before transfer from router
                if (sendingToken.allowance(msg.sender, address(this)) < vars.inputAmount) {
                    revert Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();
                }

                /// @dev transfers sendingToken, which is different from the vault asset, to the form
                sendingToken.safeTransferFrom(msg.sender, address(this), vars.inputAmount);
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
                    sendingTokenAddress,
                    address(0)
                )
            );

            _dispatchTokens(
                superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                singleVaultData_.liqData.txData,
                sendingTokenAddress,
                vars.inputAmount,
                singleVaultData_.liqData.nativeAmount
            );

            if (
                IBridgeValidator(vars.bridgeValidator).decodeSwapOutputToken(singleVaultData_.liqData.txData)
                    != vars.vaultTokenIn
            ) {
                revert Error.DIFFERENT_TOKENS();
            }
        }

        vars.assetDifference = IERC20(vars.vaultTokenIn).balanceOf(address(this)) - vars.balanceBefore;

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
        IERC20(vars.vaultTokenIn).safeIncreaseAllowance(vault, vars.assetDifference);

        /// @dev deposit assets for shares and add extra validation check to ensure intended ERC5115 behavior
        shares = _depositAndValidate(singleVaultData_, vars.assetDifference, vars.vaultTokenIn);
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

        /// @dev for deposits tokenIn must be decoded from extraFormData as interimToken may be in use
        /// @dev Warning: This must be validated by a keeper to be the token received in CSR for the given payload, as
        /// this can be forged by the user
        /// @dev and it's not possible to validate on chain the final token post bridging/swapping
        (uint256 nVaults, bytes memory extra5115Data) = abi.decode(singleVaultData_.extraFormData, (uint256, bytes));

        bytes memory recursion5115Data;
        address vaultTokenIn;
        uint256 superformId;
        bool found5115;

        for (uint256 i = 0; i < nVaults; ++i) {
            (recursion5115Data, superformId, vaultTokenIn) =
                abi.decode(i == 0 ? extra5115Data : recursion5115Data, (bytes, uint256, address));

            /// @dev notice that by validating it like this, it will deny any tokenIn that is native (sometimes
            /// addressed as
            /// address 0)
            if (superformId == singleVaultData_.superformId && vaultTokenIn != address(0)) {
                found5115 = true;
                break;
            }
        }
        if (!found5115) revert ERC5115FORM_TOKEN_IN_NOT_ENCODED();

        if (IERC20(vaultTokenIn).allowance(msg.sender, address(this)) < singleVaultData_.amount) {
            revert Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();
        }

        /// @dev pulling from sender, to auto-send tokens back in case of failed deposits / reverts
        IERC20(vaultTokenIn).safeTransferFrom(msg.sender, address(this), singleVaultData_.amount);

        /// @dev allowance is modified inside of the IERC20.transferFrom() call
        IERC20(vaultTokenIn).safeIncreaseAllowance(vaultLoc, singleVaultData_.amount);

        /// @dev deposit vaultTokenIn for shares and add extra validation check to ensure intended ERC5115 behavior
        shares = _depositAndValidate(singleVaultData_, singleVaultData_.amount, vaultTokenIn);

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

        /// @dev for withdraws interimToken is used as tokenOut (as extraFormData is overriden in CSR, so cannot be used
        /// to send this intent)

        vars.vaultTokenOut = singleVaultData_.liqData.interimToken;

        /// @dev notice that by validating it like this, it will deny any tokenOut that is native (sometimes addressed
        /// as address 0)
        if (vars.vaultTokenOut == address(0)) revert ERC5115FORM_TOKEN_OUT_NOT_SET();

        if (!singleVaultData_.retain4626) {
            /// @dev redeem shares for assets and add extra validation check to ensure intended ERC5115 behavior
            assets = _withdrawAndValidate(singleVaultData_, v, vars.vaultTokenOut);

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
                        vars.vaultTokenOut,
                        address(0)
                    )
                );

                _dispatchTokens(
                    superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                    singleVaultData_.liqData.txData,
                    vars.vaultTokenOut,
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

        /// @dev for withdraws interimToken is used as tokenOut (as extraFormData is overriden in CSR, so cannot be used
        /// to send this intent)

        vars.vaultTokenOut = singleVaultData_.liqData.interimToken;

        /// @dev notice that by validating it like this, it will deny any tokenOut that is native (sometimes addressed
        /// as address 0)
        if (vars.vaultTokenOut == address(0)) revert ERC5115FORM_TOKEN_OUT_NOT_SET();

        uint256 len = singleVaultData_.liqData.txData.length;
        /// @dev a case where the withdraw req liqData has a valid token and tx data is not updated by the keeper
        if (singleVaultData_.liqData.token != address(0) && len == 0) {
            revert Error.WITHDRAW_TX_DATA_NOT_UPDATED();
        } else if (singleVaultData_.liqData.token == address(0) && len != 0) {
            revert Error.WITHDRAW_TOKEN_NOT_UPDATED();
        }

        (,, vars.dstChainId) = singleVaultData_.superformId.getSuperform();

        IStandardizedYield v = IStandardizedYield(vault);

        if (!singleVaultData_.retain4626) {
            /// @dev redeem shares for assets and add extra validation check to ensure intended ERC5115 behavior
            assets = _withdrawAndValidate(singleVaultData_, v, vars.vaultTokenOut);

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
                        vars.vaultTokenOut,
                        address(0)
                    )
                );

                _dispatchTokens(
                    superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                    singleVaultData_.liqData.txData,
                    vars.vaultTokenOut,
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
        uint256 assetDifference_,
        address vaultTokenIn_
    )
        internal
        returns (uint256 shares)
    {
        IStandardizedYield v = IStandardizedYield(vault);

        address sharesReceiver = singleVaultData_.retain4626 ? singleVaultData_.receiverAddress : address(this);

        uint256 sharesBalanceBefore = v.balanceOf(sharesReceiver);

        /// @dev WARNING: validate if minSharesOut can be outputAmount (the result of previewDeposit)
        shares = v.deposit(sharesReceiver, vaultTokenIn_, assetDifference_, singleVaultData_.outputAmount);

        uint256 sharesBalanceAfter = v.balanceOf(sharesReceiver);

        if (
            (sharesBalanceAfter - sharesBalanceBefore != shares)
                || (
                    ENTIRE_SLIPPAGE * shares
                        < singleVaultData_.outputAmount * (ENTIRE_SLIPPAGE - singleVaultData_.maxSlippage)
                )
        ) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }
    }

    function _withdrawAndValidate(
        InitSingleVaultData memory singleVaultData_,
        IStandardizedYield v_,
        address vaultTokenOut_
    )
        internal
        returns (uint256 assets)
    {
        address assetsReceiver =
            singleVaultData_.liqData.txData.length == 0 ? singleVaultData_.receiverAddress : address(this);

        uint256 assetsBalanceBefore = IERC20(vaultTokenOut_).balanceOf(assetsReceiver);
        IERC20 underlyingVault = IERC20(IERC5115To4626Wrapper(vault).getUnderlying5115Vault());

        /// @dev have to increase allowance as shares are moved to wrapper first
        underlyingVault.safeIncreaseAllowance(vault, singleVaultData_.amount);

        assets =
            v_.redeem(assetsReceiver, singleVaultData_.amount, vaultTokenOut_, singleVaultData_.outputAmount, false);

        uint256 assetsBalanceAfter = IERC20(vaultTokenOut_).balanceOf(assetsReceiver);

        /// @dev reset allowance to wrapper
        if (underlyingVault.allowance(address(this), vault) > 0) underlyingVault.forceApprove(vault, 0);

        if (
            (assetsBalanceAfter - assetsBalanceBefore != assets)
                || (
                    ENTIRE_SLIPPAGE * assets
                        < singleVaultData_.outputAmount * (ENTIRE_SLIPPAGE - singleVaultData_.maxSlippage)
                )
        ) {
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
        IStandardizedYield v = IStandardizedYield(IERC5115To4626Wrapper(vault).getUnderlying5115Vault());
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

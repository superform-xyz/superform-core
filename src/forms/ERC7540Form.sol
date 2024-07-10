// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BaseForm } from "src/BaseForm.sol";
import { LiquidityHandler } from "src/crosschain-liquidity/LiquidityHandler.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { IBaseAsyncStateRegistry, SyncWithdrawTxDataPayload } from "src/interfaces/IBaseAsyncStateRegistry.sol";
import { IAsyncStateRegistry } from "src/interfaces/IAsyncStateRegistry.sol";

import { IEmergencyQueue } from "src/interfaces/IEmergencyQueue.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { Error } from "src/libraries/Error.sol";
import { InitSingleVaultData, LiqRequest } from "src/types/DataTypes.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {
    IERC7540Vault as IERC7540, IERC7540Deposit, IERC7540Redeem, IERC7575
} from "src/vendor/centrifuge/IERC7540.sol";
import { IERC7540FormBase } from "./interfaces/IERC7540Form.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

/// @title ERC7540Form
/// @dev Form implementation to handle async 7540 vaults
/// @author Zeropoint Labs
contract ERC7540Form is IERC7540FormBase, BaseForm, LiquidityHandler {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC7540;
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                          EVENTS                           //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when a payload is processed by the destination contract.
    event RequestProcessed(
        uint64 indexed srcChainID,
        uint64 indexed dstChainId,
        uint256 indexed srcPayloadId,
        uint256 amount,
        address vault,
        uint256 requestId
    );

    //////////////////////////////////////////////////////////////
    //                         ERRORS                         //
    //////////////////////////////////////////////////////////////
    /// @dev Vault must be set by calling forward dust to paymaster once
    error VAULT_KIND_NOT_SET();

    /// @dev Only async state registry can perform this operation
    error NOT_ASYNC_STATE_REGISTRY();

    /// @dev Error thrown if the check to erc165 async deposit interface failed
    error ERC_165_INTERFACE_DEPOSIT_CALL_FAILED();

    /// @dev Error thrown if the check to erc165 async redeem interface failed
    error ERC_165_INTERFACE_REDEEM_CALL_FAILED();

    /// @dev Error thrown if the vault does not support async deposit nor redeem
    error VAULT_NOT_SUPPORTED();

    /// @dev Error thrown if the vault kind is invalid for the operation
    error INVALID_VAULT_KIND();

    /// @dev Error thrown if trying to forward share token
    error CANNOT_FORWARD_SHARES();

    /// @dev If functions not implemented within the ERC7540 Standard
    error NOT_IMPLEMENTED();

    /// @dev If redeemed assets fell off slippage in redeem 2nd step
    error REDEEM_INVALID_LIQ_REQUEST();

    //////////////////////////////////////////////////////////////
    //                         STORAGE                         //
    //////////////////////////////////////////////////////////////
    /// @dev The id of the state registry
    /// TODO TEMPORARY AS THIS SHOULD BECOME ID 2
    uint8 internal immutable STATE_REGISTRY_ID;
    uint256 internal constant ENTIRE_SLIPPAGE = 10_000;

    VaultKind public vaultKind;

    //////////////////////////////////////////////////////////////
    //                  STRUCTS  and ENUMS                      //
    //////////////////////////////////////////////////////////////

    struct ClaimWithdrawLocalVars {
        uint256 len1;
        address bridgeValidator;
        uint64 chainId;
        address asset;
        uint256 amount;
        uint256 assetsBalanceBefore;
        uint256 assetsBalanceAfter;
        LiqRequest liqData;
    }

    struct DirectDepositLocalVars {
        uint64 chainId;
        address asset;
        uint256 balanceBefore;
    }

    struct DirectWithdrawLocalVars {
        uint64 chainId;
        address asset;
        uint256 amount;
    }

    struct XChainWithdrawLocalVars {
        uint64 dstChainId;
        address asset;
    }

    enum VaultKind {
        UNSET,
        DEPOSIT_ASYNC,
        REDEEM_ASYNC,
        FULLY_ASYNC
    }
    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyAsyncStateRegistry() {
        if (msg.sender != superRegistry.getAddress(keccak256("ASYNC_STATE_REGISTRY"))) {
            revert NOT_ASYNC_STATE_REGISTRY();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_, uint8 stateRegistryId_) BaseForm(superRegistry_) {
        superRegistry.getStateRegistry(stateRegistryId_);

        STATE_REGISTRY_ID = stateRegistryId_;
    }
    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IERC7540FormBase
    function getPendingDepositRequest(
        uint256 requestId,
        address owner
    )
        public
        view
        virtual
        override
        returns (uint256 pendingAssets)
    {
        return IERC7540(vault).pendingDepositRequest(requestId, owner);
    }

    /// @inheritdoc IERC7540FormBase
    function getClaimableDepositRequest(
        uint256 requestId,
        address owner
    )
        public
        view
        virtual
        override
        returns (uint256 claimableAssets)
    {
        return IERC7540(vault).claimableDepositRequest(requestId, owner);
    }

    /// @inheritdoc IERC7540FormBase
    function getPendingRedeemRequest(
        uint256 requestId,
        address owner
    )
        public
        view
        virtual
        override
        returns (uint256 pendingShares)
    {
        return IERC7540(vault).pendingRedeemRequest(requestId, owner);
    }

    /// @inheritdoc IERC7540FormBase
    function getClaimableRedeemRequest(
        uint256 requestId,
        address owner
    )
        public
        view
        virtual
        override
        returns (uint256 claimableShares)
    {
        return IERC7540(vault).claimableRedeemRequest(requestId, owner);
    }

    /// @inheritdoc BaseForm
    function getVaultName() public view virtual override returns (string memory) {
        return IERC20Metadata(_share()).name();
    }

    /// @inheritdoc BaseForm
    function getVaultSymbol() public view virtual override returns (string memory) {
        return IERC20Metadata(_share()).symbol();
    }

    /// @inheritdoc BaseForm
    function getVaultDecimals() public view virtual override returns (uint256) {
        return IERC20Metadata(_share()).decimals();
    }

    /// @inheritdoc BaseForm
    function getPricePerVaultShare() public view virtual override returns (uint256) {
        uint256 shareDecimals = IERC20Metadata(_share()).decimals();
        return IERC7540(vault).convertToAssets(10 ** shareDecimals);
    }

    /// @inheritdoc BaseForm
    function getVaultShareBalance() public view virtual override returns (uint256) {
        return IERC20Metadata(_share()).balanceOf(address(this));
    }

    /// @inheritdoc BaseForm
    function getTotalAssets() public view virtual override returns (uint256) {
        return IERC7575(vault).totalAssets();
    }

    /// @inheritdoc BaseForm
    function getTotalSupply() public view virtual override returns (uint256) {
        return IERC20Metadata(_share()).totalSupply();
    }

    /// @inheritdoc BaseForm
    function getPreviewPricePerVaultShare() public view virtual override returns (uint256) {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc BaseForm
    function previewDepositTo(uint256 assets_) public view virtual override returns (uint256) {
        return IERC7540(vault).convertToShares(assets_);
    }

    /// @inheritdoc BaseForm
    function previewWithdrawFrom(uint256) public view virtual override returns (uint256) {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc BaseForm
    function previewRedeemFrom(uint256) public view virtual override returns (uint256) {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc BaseForm
    function superformYieldTokenName() external view virtual override returns (string memory) {
        return string(abi.encodePacked(IERC20Metadata(_share()).name(), " SuperPosition"));
    }

    /// @inheritdoc BaseForm
    function superformYieldTokenSymbol() external view virtual override returns (string memory) {
        return string(abi.encodePacked("sp-", IERC20Metadata(_share()).symbol()));
    }

    /// @inheritdoc BaseForm
    function getStateRegistryId() external view override returns (uint8) {
        return STATE_REGISTRY_ID;
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IERC7540FormBase
    function claimDeposit(
        address user_,
        uint256 superformId_,
        uint256 amountToClaim_,
        bool retain4626_
    )
        external
        onlyAsyncStateRegistry
        returns (uint256 shares)
    {
        if (vaultKind == VaultKind.UNSET) revert VAULT_KIND_NOT_SET();

        if (vaultKind == VaultKind.REDEEM_ASYNC) revert INVALID_VAULT_KIND();

        if (user_ == address(0)) revert Error.RECEIVER_ADDRESS_NOT_SET();

        if (_isPaused(superformId_)) {
            /// @dev in case of a deposit claim and the form is paused, nothing can be sent to the emergency queue as
            /// there
            /// @dev are no shares belonging to this payload in the superform at this moment. return 0 to stop
            /// processing
            return 0;
        }

        uint256 sharesBalanceBefore;
        uint256 sharesBalanceAfter;

        (sharesBalanceBefore, sharesBalanceAfter, shares) =
            _claim(_share(), amountToClaim_, retain4626_ ? user_ : address(this), user_, true);
    }

    /// @inheritdoc IERC7540FormBase
    function claimWithdraw(
        address user_,
        uint256 superformId_,
        uint256 amountToClaim_,
        uint256 maxSlippage_,
        uint8 isXChain_,
        uint64 srcChainId_,
        LiqRequest memory liqData_
    )
        external
        onlyAsyncStateRegistry
        returns (uint256 assets)
    {
        if (vaultKind == VaultKind.UNSET) revert VAULT_KIND_NOT_SET();

        if (vaultKind == VaultKind.DEPOSIT_ASYNC) revert INVALID_VAULT_KIND();

        if (user_ == address(0)) revert Error.RECEIVER_ADDRESS_NOT_SET();

        if (_isPaused(superformId_)) {
            /// @dev in case of a withdraw claim and the form is paused, nothing can be sent to the emergency queue as
            /// the shares
            /// @dev have already been sent via requestRedeem to the vault. return 0 to stop processing

            return 0;
        }
        ClaimWithdrawLocalVars memory vars;

        vars.len1 = liqData_.txData.length;

        /// @dev a case where the withdraw req liqData has a valid token and tx data is not updated by the keeper
        if (liqData_.token != address(0) && vars.len1 == 0) {
            revert Error.WITHDRAW_TX_DATA_NOT_UPDATED();
        } else if (liqData_.token == address(0) && vars.len1 != 0) {
            revert Error.WITHDRAW_TOKEN_NOT_UPDATED();
        }

        /// @dev redeem from vault
        vars.asset = asset;

        (vars.assetsBalanceBefore, vars.assetsBalanceAfter, assets) = _claim(
            vars.asset,
            amountToClaim_,
            /// @dev if the txData is empty, the tokens are sent directly to the sender, otherwise sent first to this
            /// form
            vars.len1 == 0 ? user_ : address(this),
            user_,
            false
        );

        if (assets == 0) revert Error.WITHDRAW_ZERO_COLLATERAL();

        /// @dev validate and dispatches the tokens
        if (vars.len1 != 0) {
            vars.chainId = CHAIN_ID;

            /// @dev the amount inscribed in liqData must be less or equal than the amount redeemed from the vault
            /// @dev if less it should be within the slippage limit specified by the user
            /// @dev important to maintain so that the keeper cannot update with malicious data after successful
            /// withdraw
            if (
                _isWithdrawTxDataAmountInvalid(
                    _decodeAmountIn(_getBridgeValidator(liqData_.bridgeId), liqData_.txData), assets, maxSlippage_
                )
            ) {
                revert REDEEM_INVALID_LIQ_REQUEST();
            }

            /// @dev validate and perform the swap to desired output token and send to beneficiary
            _swapAssetsInOrOut(
                liqData_.bridgeId,
                liqData_.txData,
                IBridgeValidator.ValidateTxDataArgs(
                    liqData_.txData,
                    vars.chainId,
                    isXChain_ == 1 ? srcChainId_ : vars.chainId,
                    liqData_.liqDstChainId,
                    false,
                    address(this),
                    user_,
                    vars.asset,
                    address(0)
                ),
                liqData_.nativeAmount,
                vars.asset,
                false
            );
        }
    }

    /// @inheritdoc IERC7540FormBase
    function syncWithdrawTxData(SyncWithdrawTxDataPayload memory p_)
        external
        onlyAsyncStateRegistry
        returns (uint256 assets)
    {
        /// @dev txData must be updated at this point, otherwise it will revert and go into catch mode to remint
        /// superPositions
        assets = _processXChainWithdraw(p_.data, p_.srcChainId);
    }

    //////////////////////////////////////////////////////////////
    //              DIRECT DEPOSIT INTERNAL FUNCTIONS           //
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
        if (vaultKind == VaultKind.UNSET) revert VAULT_KIND_NOT_SET();

        if (vaultKind == VaultKind.DEPOSIT_ASYNC || vaultKind == VaultKind.FULLY_ASYNC) {
            /// @dev state registry for re-processing at a later date
            _updateAccount(0, CHAIN_ID, true, _requestDirectDeposit(singleVaultData_), singleVaultData_);
            shares = 0;
        } else {
            shares = _processDirectDeposit(singleVaultData_);
        }

        return shares;
    }

    /// @dev calls the vault to request direct async deposit
    function _requestDirectDeposit(InitSingleVaultData memory singleVaultData_) internal returns (uint256 requestId) {
        uint256 assetsToDeposit = _directMoveTokensIn(singleVaultData_);

        requestId = _requestDeposit(assetsToDeposit, singleVaultData_.receiverAddress);

        emit RequestProcessed(CHAIN_ID, CHAIN_ID, singleVaultData_.payloadId, assetsToDeposit, vault, requestId);
    }

    /// @dev calls the vault to process direct sync deposit
    function _processDirectDeposit(InitSingleVaultData memory singleVaultData_) internal returns (uint256 shares) {
        uint256 assetsToDeposit = _directMoveTokensIn(singleVaultData_);

        /// @dev deposit assets for shares and add extra validation check to ensure intended ERC4626 behavior
        shares = _depositAndValidate(singleVaultData_, assetsToDeposit);
    }

    function _directMoveTokensIn(InitSingleVaultData memory singleVaultData_)
        internal
        returns (uint256 assetsToDeposit)
    {
        DirectDepositLocalVars memory vars;

        vars.asset = asset;
        vars.balanceBefore = _balanceOf(vars.asset, address(this));
        IERC20 token = IERC20(singleVaultData_.liqData.token);

        if (address(token) != NATIVE && singleVaultData_.liqData.txData.length == 0) {
            /// @dev this is only valid if token == asset (no txData)
            if (singleVaultData_.liqData.token != vars.asset) revert Error.DIFFERENT_TOKENS();

            _assetTransferIn(address(token), singleVaultData_.amount);
        }

        /// @dev non empty txData means there is a swap needed before depositing (input asset not the same as vault
        /// asset)
        if (singleVaultData_.liqData.txData.length != 0) {
            vars.chainId = CHAIN_ID;

            /// @dev validate and perform the swap of input token to send to this form
            _swapAssetsInOrOut(
                singleVaultData_.liqData.bridgeId,
                singleVaultData_.liqData.txData,
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
                ),
                singleVaultData_.liqData.nativeAmount,
                address(token),
                true
            );

            if (
                IBridgeValidator(_getBridgeValidator(singleVaultData_.liqData.bridgeId)).decodeSwapOutputToken(
                    singleVaultData_.liqData.txData
                ) != vars.asset
            ) {
                revert Error.DIFFERENT_TOKENS();
            }
        }

        assetsToDeposit = IERC20(vars.asset).balanceOf(address(this)) - vars.balanceBefore;

        /// @dev the difference in vault tokens, ready to be deposited, is compared with the amount inscribed in the
        /// superform data
        if (
            assetsToDeposit * ENTIRE_SLIPPAGE
                < singleVaultData_.amount * (ENTIRE_SLIPPAGE - singleVaultData_.maxSlippage)
        ) {
            revert Error.DIRECT_DEPOSIT_SWAP_FAILED();
        }
    }

    //////////////////////////////////////////////////////////////
    //              XCHAIN DEPOSIT INTERNAL FUNCTIONS           //
    //////////////////////////////////////////////////////////////

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
        if (vaultKind == VaultKind.UNSET) revert VAULT_KIND_NOT_SET();

        if (vaultKind == VaultKind.DEPOSIT_ASYNC || vaultKind == VaultKind.FULLY_ASYNC) {
            /// @dev state registry for re-processing at a later date
            _updateAccount(1, srcChainId_, true, _requestXChainDeposit(singleVaultData_, srcChainId_), singleVaultData_);
            shares = 0;
        } else {
            shares = _processXChainDeposit(singleVaultData_, srcChainId_);
        }

        return shares;
    }

    /// @dev calls the vault to request xchain async deposit
    function _requestXChainDeposit(
        InitSingleVaultData memory singleVaultData_,
        uint64 srcChainId_
    )
        internal
        returns (uint256 requestId)
    {
        (,, uint64 dstChainId) = singleVaultData_.superformId.getSuperform();

        _assetTransferIn(asset, singleVaultData_.amount);

        requestId = _requestDeposit(singleVaultData_.amount, singleVaultData_.receiverAddress);

        emit RequestProcessed(
            srcChainId_, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vault, requestId
        );
    }

    /// @dev calls the vault to process xchain direct deposit
    function _processXChainDeposit(
        InitSingleVaultData memory singleVaultData_,
        uint64 srcChainId_
    )
        internal
        returns (uint256 shares)
    {
        (,, uint64 dstChainId) = singleVaultData_.superformId.getSuperform();

        _assetTransferIn(asset, singleVaultData_.amount);

        /// @dev deposit assets for shares and add extra validation check to ensure intended ERC4626 behavior
        shares = _depositAndValidate(singleVaultData_, singleVaultData_.amount);

        emit Processed(srcChainId_, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vault);
    }

    //////////////////////////////////////////////////////////////
    //              DIRECT WITHDRAW INTERNAL FUNCTIONS           //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc BaseForm
    /// @dev this is the step-1 for async form withdraw, direct case
    /// @dev will mandatorily process unlock unless the retain4626 flag is set
    /// @return assets
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address /*srcSender_*/
    )
        internal
        virtual
        override
        returns (uint256 assets)
    {
        if (vaultKind == VaultKind.UNSET) revert VAULT_KIND_NOT_SET();

        if (vaultKind == VaultKind.REDEEM_ASYNC || vaultKind == VaultKind.FULLY_ASYNC) {
            if (!singleVaultData_.retain4626) {
                /// @dev state registry for re-processing at a later date
                _updateAccount(0, CHAIN_ID, false, _requestRedeem(singleVaultData_, CHAIN_ID), singleVaultData_);
            } else {
                /// @dev transfer shares to user and do not redeem shares for assets
                _shareTransferOut(singleVaultData_.receiverAddress, singleVaultData_.amount);
            }

            assets = 0;
        } else {
            assets = _processDirectWithdraw(singleVaultData_);
        }
        return assets;
    }

    /// @dev calls the vault to request direct sync redeem
    function _processDirectWithdraw(InitSingleVaultData memory singleVaultData_) internal returns (uint256 assets) {
        DirectWithdrawLocalVars memory vars;

        if (!singleVaultData_.retain4626) {
            vars.asset = asset;

            /// @dev redeem shares for assets and add extra validation check to ensure intended ERC4626 behavior
            assets = _withdrawAndValidate(singleVaultData_);

            if (singleVaultData_.liqData.txData.length != 0) {
                vars.chainId = CHAIN_ID;

                /// @dev the amount inscribed in liqData must be less or equal than the amount redeemed from the vault
                if (
                    _isWithdrawTxDataAmountInvalid(
                        _decodeAmountIn(
                            _getBridgeValidator(singleVaultData_.liqData.bridgeId), singleVaultData_.liqData.txData
                        ),
                        assets,
                        singleVaultData_.maxSlippage
                    )
                ) {
                    revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();
                }

                /// @dev validate and perform the swap to desired output token and send to beneficiary
                _swapAssetsInOrOut(
                    singleVaultData_.liqData.bridgeId,
                    singleVaultData_.liqData.txData,
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
                    ),
                    singleVaultData_.liqData.nativeAmount,
                    vars.asset,
                    false
                );
            }
        } else {
            /// @dev transfer shares to user and do not redeem shares for assets
            _shareTransferOut(singleVaultData_.receiverAddress, singleVaultData_.amount);
            return 0;
        }
    }

    //////////////////////////////////////////////////////////////
    //              XCHAIN WITHDRAW INTERNAL FUNCTIONS           //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc BaseForm
    /// @dev this is the step-1 for async form withdraw, xchain case
    /// @dev will mandatorily process unlock unless the retain4626 flag is set
    /// @return assets
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
        if (vaultKind == VaultKind.UNSET) revert VAULT_KIND_NOT_SET();

        if (vaultKind == VaultKind.REDEEM_ASYNC || vaultKind == VaultKind.FULLY_ASYNC) {
            if (!singleVaultData_.retain4626) {
                /// @dev state registry for re-processing at a later date
                _updateAccount(1, srcChainId_, false, _requestRedeem(singleVaultData_, srcChainId_), singleVaultData_);
            } else {
                /// @dev transfer shares to user and do not redeem shares for assets
                _shareTransferOut(singleVaultData_.receiverAddress, singleVaultData_.amount);
            }
            assets = 0;
        } else {
            /// @dev if txData is meant to be updated
            if (singleVaultData_.liqData.token != address(0) && singleVaultData_.liqData.txData.length == 0) {
                _storeSyncWithdrawPayload(srcChainId_, singleVaultData_);

                assets = 0;
            } else {
                // assume update not needed, process imediately
                assets = _processXChainWithdraw(singleVaultData_, srcChainId_);
            }
        }

        return assets;
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

        if (!singleVaultData_.retain4626) {
            vars.asset = asset;

            /// @dev redeem shares for assets and add extra validation check to ensure intended ERC4626 behavior
            assets = _withdrawAndValidate(singleVaultData_);

            if (len != 0) {
                /// @dev the amount inscribed in liqData must be less or equal than the amount redeemed from the vault
                /// @dev if less it should be within the slippage limit specified by the user
                /// @dev important to maintain so that the keeper cannot update with malicious data after successful
                /// withdraw
                if (
                    _isWithdrawTxDataAmountInvalid(
                        _decodeAmountIn(
                            _getBridgeValidator(singleVaultData_.liqData.bridgeId), singleVaultData_.liqData.txData
                        ),
                        assets,
                        singleVaultData_.maxSlippage
                    )
                ) {
                    revert REDEEM_INVALID_LIQ_REQUEST();
                }

                /// @dev validate and perform the swap to desired output token and send to beneficiary
                _swapAssetsInOrOut(
                    singleVaultData_.liqData.bridgeId,
                    singleVaultData_.liqData.txData,
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
                    ),
                    singleVaultData_.liqData.nativeAmount,
                    vars.asset,
                    false
                );
            }
        } else {
            /// @dev transfer shares to user and do not redeem shares for assets
            _shareTransferOut(singleVaultData_.receiverAddress, singleVaultData_.amount);
            return 0;
        }

        emit Processed(srcChainId_, vars.dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vault);
    }

    //////////////////////////////////////////////////////////////
    //  DIRECT/ XCHAIN DEPOSIT  COMMON INTERNAL FUNCTIONS       //
    //////////////////////////////////////////////////////////////

    function _requestDeposit(uint256 amount, address receiverAddress) internal returns (uint256 requestId) {
        address vaultLoc = vault;

        /// @dev allowance is modified inside of the IERC20.transferFrom() call
        IERC20(asset).safeIncreaseAllowance(vaultLoc, amount);

        /// ERC7540 logic
        requestId = IERC7540(vaultLoc).requestDeposit(amount, receiverAddress, address(this));

        if (IERC20(asset).allowance(address(this), vaultLoc) > 0) IERC20(asset).forceApprove(vaultLoc, 0);

        /// @notice RequestProcessed emited in the upper internal functions due to difference between direct and xchain
        /// deposit
    }

    //////////////////////////////////////////////////////////////
    //  DIRECT/ XCHAIN WITHDRAW  COMMON INTERNAL FUNCTIONS       //
    //////////////////////////////////////////////////////////////
    /// @dev calls the vault to request direct/xchain async redeem
    /// @notice superPositions are already burned at this point
    function _requestRedeem(
        InitSingleVaultData memory singleVaultData_,
        uint64 srcChainId_
    )
        internal
        returns (uint256 requestId)
    {
        (,, uint64 dstChainId) = singleVaultData_.superformId.getSuperform();

        address share = _share();

        IERC20(share).safeIncreaseAllowance(vault, singleVaultData_.amount);

        requestId =
            IERC7540(vault).requestRedeem(singleVaultData_.amount, singleVaultData_.receiverAddress, address(this));

        if (IERC20(share).allowance(address(this), vault) > 0) IERC20(share).forceApprove(vault, 0);

        emit RequestProcessed(
            srcChainId_, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vault, requestId
        );
    }

    //////////////////////////////////////////////////////////////
    //                   HELPER INTERNAL FUNCTIONS              //
    //////////////////////////////////////////////////////////////

    function _depositAndValidate(
        InitSingleVaultData memory singleVaultData_,
        uint256 assetDifference
    )
        internal
        returns (uint256 shares)
    {
        address sharesReceiver = singleVaultData_.retain4626 ? singleVaultData_.receiverAddress : address(this);

        address share = _share();

        address vaultLoc = vault;

        address assetLoc = asset;

        /// @dev allowance is modified inside of the IERC20.transferFrom() call
        IERC20(assetLoc).safeIncreaseAllowance(vaultLoc, singleVaultData_.amount);

        uint256 sharesBalanceBefore = _balanceOf(share, sharesReceiver);

        shares = IERC7540(vault).deposit(assetDifference, sharesReceiver);

        uint256 sharesBalanceAfter = _balanceOf(share, sharesReceiver);

        if (IERC20(assetLoc).allowance(address(this), vaultLoc) > 0) IERC20(assetLoc).forceApprove(vaultLoc, 0);

        if (
            (sharesBalanceAfter - sharesBalanceBefore != shares)
                || (
                    ENTIRE_SLIPPAGE * shares
                        < ((singleVaultData_.outputAmount * (ENTIRE_SLIPPAGE - singleVaultData_.maxSlippage)))
                )
        ) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }
    }

    function _withdrawAndValidate(InitSingleVaultData memory singleVaultData_) internal returns (uint256 assets) {
        address assetsReceiver =
            singleVaultData_.liqData.txData.length == 0 ? singleVaultData_.receiverAddress : address(this);

        address share = _share();

        address vaultLoc = vault;

        IERC20(share).safeIncreaseAllowance(vaultLoc, singleVaultData_.amount);

        uint256 assetsBalanceBefore = _balanceOf(asset, assetsReceiver);

        assets = IERC7540(vaultLoc).redeem(singleVaultData_.amount, assetsReceiver, address(this));

        uint256 assetsBalanceAfter = _balanceOf(asset, assetsReceiver);

        if (IERC20(share).allowance(address(this), vaultLoc) > 0) IERC20(share).forceApprove(vaultLoc, 0);

        if (
            (assetsBalanceAfter - assetsBalanceBefore != assets)
                || (
                    ENTIRE_SLIPPAGE * assets
                        < ((singleVaultData_.outputAmount * (ENTIRE_SLIPPAGE - singleVaultData_.maxSlippage)))
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

    /// @dev stores the deposit payload
    function _updateAccount(
        uint8 type_,
        uint64 srcChainId_,
        bool isDeposit_,
        uint256 requestId_,
        InitSingleVaultData memory data_
    )
        internal
    {
        IAsyncStateRegistry(superRegistry.getAddress(keccak256("ASYNC_STATE_REGISTRY"))).updateRequestConfig(
            type_, srcChainId_, isDeposit_, requestId_, data_
        );
    }

    /// @dev stores the sync withdraw payload
    function _storeSyncWithdrawPayload(uint64 srcChainId_, InitSingleVaultData memory data_) internal {
        // send info to async state registry for txData update
        IBaseAsyncStateRegistry(superRegistry.getAddress(keccak256("ASYNC_STATE_REGISTRY")))
            .receiveSyncWithdrawTxDataPayload(srcChainId_, data_);
    }

    function _claim(
        address tokenOut,
        uint256 amountToClaim,
        address receiver,
        address controller,
        bool deposit
    )
        internal
        returns (uint256 balanceBefore, uint256 balanceAfter, uint256 tokensReceived)
    {
        IERC7540 v = IERC7540(vault);

        balanceBefore = _balanceOf(tokenOut, receiver);

        tokensReceived =
            deposit ? v.deposit(amountToClaim, receiver, controller) : v.redeem(amountToClaim, receiver, controller);

        balanceAfter = _balanceOf(tokenOut, receiver);
    }

    function _vaultKindCheck() internal view returns (VaultKind kind) {
        bool depositSupported;
        bool redeemSupported;

        /// @dev ideally the check is made at the selector level
        try IERC165(vault).supportsInterface(type(IERC7540Deposit).interfaceId) returns (bool depositSupported_) {
            depositSupported = depositSupported_;
        } catch {
            revert ERC_165_INTERFACE_DEPOSIT_CALL_FAILED();
        }

        try IERC165(vault).supportsInterface(type(IERC7540Redeem).interfaceId) returns (bool redeemSupported_) {
            redeemSupported = redeemSupported_;
        } catch {
            revert ERC_165_INTERFACE_REDEEM_CALL_FAILED();
        }

        if (depositSupported && redeemSupported) {
            return VaultKind.FULLY_ASYNC;
        }
        if (depositSupported) {
            return VaultKind.DEPOSIT_ASYNC;
        }
        if (redeemSupported) {
            return VaultKind.REDEEM_ASYNC;
        }

        revert VAULT_NOT_SUPPORTED();
    }

    function _slippageValidation(
        uint256 amountBefore,
        uint256 amountAfter,
        uint256 actualOutputAmount,
        uint256 expectedOutputAmount,
        uint256 maxSlippage
    )
        internal
        pure
    {
        if (
            (amountAfter - amountBefore != actualOutputAmount)
                || (actualOutputAmount * ENTIRE_SLIPPAGE < expectedOutputAmount * (ENTIRE_SLIPPAGE - maxSlippage))
        ) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }
    }

    /// @inheritdoc BaseForm
    function _emergencyWithdraw(address receiverAddress_, uint256 amount_) internal virtual override {
        if (receiverAddress_ == address(0)) revert Error.ZERO_ADDRESS();

        if (_balanceOf(_share(), address(this)) < amount_) {
            revert Error.INSUFFICIENT_BALANCE();
        }
        _shareTransferOut(receiverAddress_, amount_);

        emit EmergencyWithdrawalProcessed(receiverAddress_, amount_);
    }

    /// @inheritdoc BaseForm
    function _forwardDustToPaymaster(address token_) internal override {
        /// @dev call made here to avoid polluting other functions with this setter
        if (vaultKind == VaultKind.UNSET) {
            vaultKind = _vaultKindCheck();
        }
        if (token_ == _share()) revert CANNOT_FORWARD_SHARES();
        if (token_ == address(0)) revert Error.ZERO_ADDRESS();

        address paymaster = superRegistry.getAddress(keccak256("PAYMASTER"));
        IERC20 token = IERC20(token_);

        uint256 dust = token.balanceOf(address(this));
        if (dust != 0) {
            token.safeTransfer(paymaster, dust);
            emit FormDustForwardedToPaymaster(token_, dust);
        }
    }

    function _getBridgeValidator(uint8 bridgeId) internal view returns (address) {
        return superRegistry.getBridgeValidator(bridgeId);
    }

    function _decodeAmountIn(address bridgeValidator, bytes memory txData) internal view returns (uint256 amount) {
        return IBridgeValidator(bridgeValidator).decodeAmountIn(txData, false);
    }

    function _validateTxData(address bridgeValidator, IBridgeValidator.ValidateTxDataArgs memory args) internal view {
        IBridgeValidator(bridgeValidator).validateTxData(args);
    }

    function _shareTransferOut(address receiver, uint256 amount) internal {
        IERC20(_share()).safeTransfer(receiver, amount);
    }

    function _assetTransferIn(address token, uint256 amount) internal {
        if (IERC20(token).allowance(msg.sender, address(this)) < amount) {
            revert Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();
        }

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function _swapAssetsInOrOut(
        uint8 bridgeId_,
        bytes memory txData_,
        IBridgeValidator.ValidateTxDataArgs memory args_,
        uint256 nativeAmount_,
        address asset_,
        bool deposit_
    )
        internal
    {
        address bridgeValidator = _getBridgeValidator(bridgeId_);

        uint256 amountIn = _decodeAmountIn(bridgeValidator, txData_);

        if (deposit_ && asset_ != NATIVE) {
            _assetTransferIn(asset_, amountIn);
        }

        _validateTxData(bridgeValidator, args_);

        _dispatchTokens(superRegistry.getBridgeAddress(bridgeId_), txData_, asset_, amountIn, nativeAmount_);
    }

    function _balanceOf(address token, address account) internal view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }

    function _share() internal view returns (address) {
        return IERC7540(vault).share();
    }
}

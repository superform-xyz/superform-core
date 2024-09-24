// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BaseForm } from "src/BaseForm.sol";
import { LiquidityHandler } from "src/crosschain-liquidity/LiquidityHandler.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { IAsyncStateRegistry, SyncWithdrawTxDataPayload } from "src/interfaces/IAsyncStateRegistry.sol";

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
    //                      CONSTANTS                           //
    //////////////////////////////////////////////////////////////

    /// @dev The id of the state registry
    /// TODO TEMPORARY AS THIS SHOULD BECOME ID 2
    uint8 internal immutable STATE_REGISTRY_ID;
    uint256 internal constant ENTIRE_SLIPPAGE = 10_000;
    address internal constant ZERO_ADDRESS = address(0);

    //////////////////////////////////////////////////////////////
    //                  STATE VARIABLES                         //
    //////////////////////////////////////////////////////////////

    VaultKind public vaultKind;

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
        if (user_ == ZERO_ADDRESS) revert Error.RECEIVER_ADDRESS_NOT_SET();

        if (vaultKind == VaultKind.UNSET) revert VAULT_KIND_NOT_SET();
        if (vaultKind == VaultKind.REDEEM_ASYNC) revert INVALID_VAULT_KIND();

        if (_isPaused(superformId_)) {
            /// @dev in case of a deposit claim and the form is paused, nothing can be sent to the emergency queue as
            /// there are no shares belonging to this payload in the superform at this moment.

            /// @dev return 0 to stop processing
            return 0;
        }

        (,, shares) = _claim(_share(), amountToClaim_, retain4626_ ? user_ : address(this), user_, true);
    }

    /// @inheritdoc IERC7540FormBase
    function claimRedeem(
        address user_,
        uint256 superformId_,
        uint256 amountToClaim_,
        uint256 maxSlippage_,
        uint8 isXChain_,
        uint64 srcChainId_,
        LiqRequest calldata liqData_
    )
        external
        onlyAsyncStateRegistry
        returns (uint256 assets)
    {
        if (user_ == ZERO_ADDRESS) revert Error.RECEIVER_ADDRESS_NOT_SET();

        if (vaultKind == VaultKind.UNSET) revert VAULT_KIND_NOT_SET();
        if (vaultKind == VaultKind.DEPOSIT_ASYNC) revert INVALID_VAULT_KIND();

        if (_isPaused(superformId_)) {
            /// @dev in case of a withdraw claim and the form is paused, nothing can be sent to the emergency queue as
            /// the shares have already been sent via requestRedeem to the vault.

            /// @dev return 0 to stop processing
            return 0;
        }

        /// @dev cache length
        uint256 txDataLen = liqData_.txData.length;
        _checkTxData(liqData_.token, txDataLen);

        /// @dev cache asset to reduce SLOAD
        address assetCache = asset;

        /// @dev redeem from vault
        (,, assets) = _claim(
            assetCache,
            amountToClaim_,
            /// @dev send tokens to user_ if txData is empty (else) to the form
            txDataLen == 0 ? user_ : address(this),
            user_,
            false
        );

        if (assets == 0) revert Error.WITHDRAW_ZERO_COLLATERAL();

        /// @dev validate and dispatches the tokens
        if (txDataLen != 0) {
            uint64 chainId = CHAIN_ID;

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
                    chainId,
                    isXChain_ == 1 ? srcChainId_ : chainId,
                    liqData_.liqDstChainId,
                    false,
                    address(this),
                    user_,
                    assetCache,
                    ZERO_ADDRESS
                ),
                liqData_.nativeAmount,
                assetCache,
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
        /// @dev txData must be updated at this point, otherwise it will revert and
        /// go into catch mode to remint superPositions
        assets = _processXChainWithdraw(p_.data, p_.srcChainId);
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
    //              DEPOSIT HELPER FUNCTIONS                    //
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

        /// @dev moves token in regardless of the type of vault
        uint256 assetsToDeposit = _directMoveTokensIn(singleVaultData_);

        if (vaultKind == VaultKind.DEPOSIT_ASYNC || vaultKind == VaultKind.FULLY_ASYNC) {
            uint256 requestId = _requestDeposit(assetsToDeposit, singleVaultData_.receiverAddress);

            emit RequestProcessed(CHAIN_ID, CHAIN_ID, singleVaultData_.payloadId, assetsToDeposit, vault, requestId);

            /// @dev stores the payload for further processing by async state registry
            _updateAccount(0, CHAIN_ID, true, requestId, singleVaultData_);
        } else {
            shares = _depositAndValidate(singleVaultData_, assetsToDeposit);
        }
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
        if (vaultKind == VaultKind.UNSET) revert VAULT_KIND_NOT_SET();

        /// @dev transfers asset to the form regardless of the form types
        (,, uint64 dstChainId) = singleVaultData_.superformId.getSuperform();
        _assetTransferIn(asset, singleVaultData_.amount);

        if (vaultKind == VaultKind.DEPOSIT_ASYNC || vaultKind == VaultKind.FULLY_ASYNC) {
            uint256 requestId = _requestDeposit(singleVaultData_.amount, singleVaultData_.receiverAddress);

            emit RequestProcessed(
                srcChainId_, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vault, requestId
            );
            /// @dev stores the payload for further processing by async state registry
            _updateAccount(1, srcChainId_, true, requestId, singleVaultData_);
        } else {
            shares = _depositAndValidate(singleVaultData_, singleVaultData_.amount);

            emit Processed(srcChainId_, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vault);
        }
    }

    /// @notice helper functions to request deposit from a vault
    /// @notice RequestProcessed event is emitted by inheriting functions
    function _requestDeposit(uint256 amount, address receiverAddress) internal returns (uint256 requestId) {
        address vaultLoc = vault;

        /// @dev allowance is modified inside of the IERC20.transferFrom() call
        IERC20(asset).safeIncreaseAllowance(vaultLoc, amount);

        /// ERC7540 logic
        requestId = IERC7540(vaultLoc).requestDeposit(amount, receiverAddress, address(this));

        if (IERC20(asset).allowance(address(this), vaultLoc) > 0) IERC20(asset).forceApprove(vaultLoc, 0);
    }

    /// @dev helps move tokens into the form address based on the InitSingleVaultData
    /// @param singleVaultData_ is the calldata to process
    function _directMoveTokensIn(InitSingleVaultData memory singleVaultData_)
        internal
        returns (uint256 assetsToDeposit)
    {
        address assetCache = asset;
        uint256 balanceBefore = _balanceOf(assetCache, address(this));

        IERC20 token = IERC20(singleVaultData_.liqData.token);

        if (address(token) != NATIVE && singleVaultData_.liqData.txData.length == 0) {
            /// @dev vault asset should be the token in
            if (singleVaultData_.liqData.token != assetCache) revert Error.DIFFERENT_TOKENS();

            _assetTransferIn(address(token), singleVaultData_.amount);
        }

        /// @dev process swaps if the txData is non empty
        if (singleVaultData_.liqData.txData.length != 0) {
            uint64 chainId = CHAIN_ID;

            _swapAssetsInOrOut(
                singleVaultData_.liqData.bridgeId,
                singleVaultData_.liqData.txData,
                IBridgeValidator.ValidateTxDataArgs(
                    singleVaultData_.liqData.txData,
                    chainId,
                    chainId,
                    chainId,
                    true,
                    address(this),
                    msg.sender,
                    address(token),
                    ZERO_ADDRESS
                ),
                singleVaultData_.liqData.nativeAmount,
                address(token),
                true
            );

            if (
                IBridgeValidator(_getBridgeValidator(singleVaultData_.liqData.bridgeId)).decodeSwapOutputToken(
                    singleVaultData_.liqData.txData
                ) != assetCache
            ) {
                revert Error.DIFFERENT_TOKENS();
            }
        }

        assetsToDeposit = IERC20(assetCache).balanceOf(address(this)) - balanceBefore;

        console.log("assetsToDeposit", assetsToDeposit);
        console.log("singleVaultData_.amount", singleVaultData_.amount);

        /// @dev validates slippage
        if (
            assetsToDeposit * ENTIRE_SLIPPAGE
                < singleVaultData_.amount * (ENTIRE_SLIPPAGE - singleVaultData_.maxSlippage)
        ) {
            revert Error.DIRECT_DEPOSIT_SWAP_FAILED();
        }
    }

    //////////////////////////////////////////////////////////////
    //              DIRECT WITHDRAW HELPER FUNCTIONS            //
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
        } else {
            assets = _processDirectWithdraw(singleVaultData_);
        }
    }

    /// @notice helper to process same chain withdraw
    /// @dev redeems from the vault and sends tokens to the user (or)
    /// @dev transfers the vault shares out if the retain4626 flag is set
    function _processDirectWithdraw(InitSingleVaultData memory singleVaultData_) internal returns (uint256 assets) {
        if (!singleVaultData_.retain4626) {
            address assetCache = asset;

            /// @dev redeem vault shares to asset
            assets = _withdrawAndValidate(singleVaultData_);

            if (singleVaultData_.liqData.txData.length != 0) {
                uint64 chainId = CHAIN_ID;

                /// @dev validates the bridge/swap amount encoded in the txData_
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
                        chainId,
                        chainId,
                        singleVaultData_.liqData.liqDstChainId,
                        false,
                        address(this),
                        singleVaultData_.receiverAddress,
                        assetCache,
                        ZERO_ADDRESS
                    ),
                    singleVaultData_.liqData.nativeAmount,
                    assetCache,
                    false
                );
            }
        } else {
            /// @dev distributes vault shares to the user without redeeming
            _shareTransferOut(singleVaultData_.receiverAddress, singleVaultData_.amount);
        }
    }

    /// @inheritdoc BaseForm
    /// @dev this is the step-1 for async cross-chain withdraw
    /// @dev will process unlock unless the retain4626 flag is set
    /// @return assets the total underlying assets redeemded from the form
    /// @notice return 0 if further processing is required
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
        } else {
            /// @dev if txData is meant to be updated
            if (singleVaultData_.liqData.token != ZERO_ADDRESS && singleVaultData_.liqData.txData.length == 0) {
                _storeSyncWithdrawPayload(srcChainId_, singleVaultData_);
            } else {
                // assume update not needed, process immediately
                assets = _processXChainWithdraw(singleVaultData_, srcChainId_);
            }
        }
    }

    /// @dev helper to process cross-chain withdrawal
    /// @dev transfers vault share out if the retain4626 flag is set
    /// @dev else will redeem from the vault
    function _processXChainWithdraw(
        InitSingleVaultData memory singleVaultData_,
        uint64 srcChainId_
    )
        internal
        returns (uint256 assets)
    {
        uint256 len = singleVaultData_.liqData.txData.length;
        _checkTxData(singleVaultData_.liqData.token, len);

        (,, uint64 dstChainId) = singleVaultData_.superformId.getSuperform();

        if (!singleVaultData_.retain4626) {
            address assetCache = asset;

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
                        dstChainId,
                        srcChainId_,
                        singleVaultData_.liqData.liqDstChainId,
                        false,
                        address(this),
                        singleVaultData_.receiverAddress,
                        assetCache,
                        ZERO_ADDRESS
                    ),
                    singleVaultData_.liqData.nativeAmount,
                    assetCache,
                    false
                );
            }
        } else {
            /// @dev transfer shares to user and do not redeem shares for assets
            _shareTransferOut(singleVaultData_.receiverAddress, singleVaultData_.amount);
        }

        emit Processed(srcChainId_, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vault);
    }

    /// @notice helper to request redeem from the vault
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
    //                   HELPER FUNCTIONS                       //
    //////////////////////////////////////////////////////////////

    function _checkTxData(address token_, uint256 len_) internal pure {
        /// @dev a case where the withdraw req liqData has a valid token and tx data is not updated by the keeper
        if (token_ != ZERO_ADDRESS && len_ == 0) {
            revert Error.WITHDRAW_TX_DATA_NOT_UPDATED();
        } else if (token_ == ZERO_ADDRESS && len_ != 0) {
            revert Error.WITHDRAW_TOKEN_NOT_UPDATED();
        }
    }

    /// @notice helper to deposit to the underlying vault
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

    /// @notice helper to redeem from the underlying vault
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

    /// @notice helper to validate txData amount
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

    /// @notice helper to store the deposit payload
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

    /// @notice helper to store the sync withdraw payload
    function _storeSyncWithdrawPayload(uint64 srcChainId_, InitSingleVaultData memory data_) internal {
        // send info to async state registry for txData update
        IAsyncStateRegistry(superRegistry.getAddress(keccak256("ASYNC_STATE_REGISTRY")))
            .receiveSyncWithdrawTxDataPayload(srcChainId_, data_);
    }

    /// @notice helper to claim the vault shares in async deposit vault
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
        balanceBefore = _balanceOf(tokenOut, receiver);
        tokensReceived = deposit
            ? IERC7540(vault).deposit(amountToClaim, receiver, controller)
            : IERC7540(vault).redeem(amountToClaim, receiver, controller);
        balanceAfter = _balanceOf(tokenOut, receiver);
    }

    /// @notice helper to validate vault kind
    function _validateVaultKind() internal view returns (VaultKind kind) {
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

    /// @notice helper to validate slippage
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
        if (receiverAddress_ == ZERO_ADDRESS) revert Error.ZERO_ADDRESS();

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
            vaultKind = _validateVaultKind();
        }
        if (token_ == _share()) revert CANNOT_FORWARD_SHARES();
        if (token_ == ZERO_ADDRESS) revert Error.ZERO_ADDRESS();

        address paymaster = superRegistry.getAddress(keccak256("PAYMASTER"));
        IERC20 token = IERC20(token_);

        uint256 dust = token.balanceOf(address(this));
        if (dust != 0) {
            token.safeTransfer(paymaster, dust);
            emit FormDustForwardedToPaymaster(token_, dust);
        }
    }

    /// @notice helper to get bridge validator address from super registry
    function _getBridgeValidator(uint8 bridgeId) internal view returns (address) {
        return superRegistry.getBridgeValidator(bridgeId);
    }

    /// @notice helper to decode amount from the txData_ using bridge validator
    function _decodeAmountIn(address bridgeValidator, bytes memory txData) internal view returns (uint256 amount) {
        return IBridgeValidator(bridgeValidator).decodeAmountIn(txData, false);
    }

    /// @notice helper to transfer vault shares to the receiver
    function _shareTransferOut(address receiver, uint256 amount) internal {
        IERC20(_share()).safeTransfer(receiver, amount);
    }

    /// @notice helper to move tokens to this contract using safeTransferFrom
    function _assetTransferIn(address token, uint256 amount) internal {
        if (IERC20(token).allowance(msg.sender, address(this)) < amount) {
            revert Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();
        }

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice helper to swap / move tokens into the form
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

        IBridgeValidator(bridgeValidator).validateTxData(args_);
        _dispatchTokens(superRegistry.getBridgeAddress(bridgeId_), txData_, asset_, amountIn, nativeAmount_);
    }

    /// @notice helper to query token balance of an account
    function _balanceOf(address token, address account) internal view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }

    /// @notice helper to read the vault share address
    function _share() internal view returns (address) {
        return IERC7540(vault).share();
    }
}

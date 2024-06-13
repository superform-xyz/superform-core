// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { ERC4626FormImplementation } from "src/forms/ERC4626FormImplementation.sol";
import { BaseForm } from "src/BaseForm.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { IAsyncStateRegistry, AsyncWithdrawPayload, AsyncDepositPayload } from "src/interfaces/IAsyncStateRegistry.sol";
import { IEmergencyQueue } from "src/interfaces/IEmergencyQueue.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { Error } from "src/libraries/Error.sol";
import { InitSingleVaultData, LiqRequest } from "src/types/DataTypes.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC7540, IERC7540Deposit, IERC7540Redeem } from "src/vendor/centrifuge/IERC7540.sol";
import { IERC7540FormBase } from "./interfaces/IERC7540Form.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

/// @title ERC7540Form
/// @dev Form implementation to handle async 7540 vaults
/// @author Zeropoint Labs
contract ERC7540Form is IERC7540FormBase, ERC4626FormImplementation {
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
    error NOT_ASYNC_STATE_REGISTRY();

    error ERC_165_INTERFACE_DEPOSIT_CALL_FAILED();

    error ERC_165_INTERFACE_REDEEM_CALL_FAILED();

    //////////////////////////////////////////////////////////////
    //                         STORAGE                         //
    //////////////////////////////////////////////////////////////

    uint8 constant stateRegistryId = 2; // AsyncStateRegistry

    VaultKind private _vaultKind;

    //////////////////////////////////////////////////////////////
    //                  STRUCTS  and ENUMS                      //
    //////////////////////////////////////////////////////////////

    struct ClaimWithdrawLocalVars {
        uint256 len1;
        address bridgeValidator;
        uint64 chainId;
        address receiver;
        address asset;
        uint256 amount;
        LiqRequest liqData;
    }

    enum VaultKind {
        UNSET,
        DEPOSIT_ASYNC,
        REDEEM_ASYNC,
        FULLY_ASYNC,
        SYNC
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

    constructor(address superRegistry_) ERC4626FormImplementation(superRegistry_, stateRegistryId) { }
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

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IERC7540FormBase
    function claimDeposit(AsyncDepositPayload memory p_) external onlyAsyncStateRegistry returns (uint256 shares) {
        if (p_.data.receiverAddress == address(0)) revert Error.RECEIVER_ADDRESS_NOT_SET();

        if (_isPaused(p_.data.superformId)) {
            /// @dev in case of a deposit claim and the form is paused, nothing can be sent to the emergency queue as
            /// there
            /// @dev are no shares belonging to this payload in the superform at this moment. return 0 to stop
            /// processing
            return 0;
        }

        IERC7540 v = IERC7540(vault);
        IERC20 share = IERC20(v.share());

        address sharesReceiver = p_.data.retain4626 ? p_.data.receiverAddress : address(this);

        uint256 sharesBalanceBefore = share.balanceOf(sharesReceiver);
        shares = v.deposit(p_.assetsToDeposit, sharesReceiver, p_.data.receiverAddress);
        uint256 sharesBalanceAfter = share.balanceOf(sharesReceiver);
        if (
            (sharesBalanceAfter - sharesBalanceBefore != shares)
                || (ENTIRE_SLIPPAGE * shares < ((p_.data.outputAmount * (ENTIRE_SLIPPAGE - p_.data.maxSlippage))))
        ) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }
    }

    /// @inheritdoc IERC7540FormBase
    function claimWithdraw(AsyncWithdrawPayload memory p_) external onlyAsyncStateRegistry returns (uint256 assets) {
        if (p_.data.receiverAddress == address(0)) revert Error.RECEIVER_ADDRESS_NOT_SET();

        if (_isPaused(p_.data.superformId)) {
            /// @dev in case of a withdraw claim and the form is paused, nothing can be sent to the emergency queue as
            /// the shares
            /// @dev have already been sent via requestRedeem to the vault. return 0 to stop processing

            return 0;
        }
        ClaimWithdrawLocalVars memory vars;

        IERC7540 v = IERC7540(vault);

        vars.liqData = p_.data.liqData;
        vars.len1 = vars.liqData.txData.length;

        /// @dev a case where the withdraw req liqData has a valid token and tx data is not updated by the keeper
        if (vars.liqData.token != address(0) && vars.len1 == 0) {
            revert Error.WITHDRAW_TX_DATA_NOT_UPDATED();
        } else if (vars.liqData.token == address(0) && vars.len1 != 0) {
            revert Error.WITHDRAW_TOKEN_NOT_UPDATED();
        }

        /// @dev if the txData is empty, the tokens are sent directly to the sender, otherwise sent first to this form
        vars.receiver = vars.len1 == 0 ? p_.data.receiverAddress : address(this);

        /// @dev redeem from vault
        vars.asset = asset;
        IERC20 assetERC = IERC20(vars.asset);

        uint256 assetsBalanceBefore = assetERC.balanceOf(vars.receiver);

        assets = v.redeem(p_.data.amount, vars.receiver, p_.data.receiverAddress);
        uint256 assetsBalanceAfter = assetERC.balanceOf(vars.receiver);

        if (
            (assetsBalanceAfter - assetsBalanceBefore != assets)
                || (assets * ENTIRE_SLIPPAGE < p_.data.outputAmount * (ENTIRE_SLIPPAGE - p_.data.maxSlippage))
        ) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }

        if (assets == 0) revert Error.WITHDRAW_ZERO_COLLATERAL();

        /// @dev validate and dispatches the tokens
        if (vars.len1 != 0) {
            vars.bridgeValidator = superRegistry.getBridgeValidator(vars.liqData.bridgeId);
            vars.amount = IBridgeValidator(vars.bridgeValidator).decodeAmountIn(vars.liqData.txData, false);

            /// @dev the amount inscribed in liqData must be less or equal than the amount redeemed from the vault
            if (_isWithdrawTxDataAmountInvalid(vars.amount, assets, p_.data.maxSlippage)) {
                if (p_.isXChain == 1) revert Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();
                revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();
            }

            vars.chainId = CHAIN_ID;

            /// @dev validate and perform the swap to desired output token and send to beneficiary
            IBridgeValidator(superRegistry.getBridgeValidator(vars.liqData.bridgeId)).validateTxData(
                IBridgeValidator.ValidateTxDataArgs(
                    vars.liqData.txData,
                    vars.chainId,
                    p_.isXChain == 1 ? p_.srcChainId : vars.chainId,
                    vars.liqData.liqDstChainId,
                    false,
                    address(this),
                    p_.data.receiverAddress,
                    vars.asset,
                    address(0)
                )
            );

            _dispatchTokens(
                superRegistry.getBridgeAddress(vars.liqData.bridgeId),
                vars.liqData.txData,
                vars.asset,
                vars.amount,
                vars.liqData.nativeAmount
            );
        }
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
        if (_vaultKind == VaultKind.UNSET) {
            _vaultKind = _vaultKindCheck();
        }
        if (_vaultKind == VaultKind.DEPOSIT_ASYNC || _vaultKind == VaultKind.FULLY_ASYNC) {
            (uint256 assetsToDeposit, uint256 requestId) = _requestDirectDeposit(singleVaultData_);

            /// @dev state registry for re-processing at a later date
            _storeDepositPayload(0, CHAIN_ID, assetsToDeposit, requestId, singleVaultData_);
            shares = 0;
        } else {
            shares = _processDirectDeposit(singleVaultData_);
        }

        return shares;
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
        if (_vaultKind == VaultKind.UNSET) {
            _vaultKind = _vaultKindCheck();
        }
        if (_vaultKind == VaultKind.DEPOSIT_ASYNC || _vaultKind == VaultKind.FULLY_ASYNC) {
            /// @dev state registry for re-processing at a later date
            _storeDepositPayload(
                1,
                srcChainId_,
                singleVaultData_.amount,
                _requestXChainDeposit(singleVaultData_, srcChainId_),
                singleVaultData_
            );
            shares = 0;
        } else {
            shares = _processXChainDeposit(singleVaultData_, srcChainId_);
        }

        return shares;
    }

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
        if (_vaultKind == VaultKind.UNSET) {
            _vaultKind = _vaultKindCheck();
        }
        if (_vaultKind == VaultKind.REDEEM_ASYNC || _vaultKind == VaultKind.FULLY_ASYNC) {
            if (!singleVaultData_.retain4626) {
                /// @dev state registry for re-processing at a later date
                _storeWithdrawPayload(0, CHAIN_ID, _requestRedeem(singleVaultData_, CHAIN_ID), singleVaultData_);
            } else {
                /// @dev transfer shares to user and do not redeem shares for assets
                IERC20(IERC7540(vault).share()).safeTransfer(singleVaultData_.receiverAddress, singleVaultData_.amount);
            }

            assets = 0;
        } else {
            assets = _processDirectWithdraw(singleVaultData_);
        }
        return assets;
    }

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
        if (_vaultKind == VaultKind.UNSET) {
            _vaultKind = _vaultKindCheck();
        }
        if (_vaultKind == VaultKind.REDEEM_ASYNC || _vaultKind == VaultKind.FULLY_ASYNC) {
            if (!singleVaultData_.retain4626) {
                /// @dev state registry for re-processing at a later date
                _storeWithdrawPayload(1, srcChainId_, _requestRedeem(singleVaultData_, srcChainId_), singleVaultData_);
            } else {
                /// @dev transfer shares to user and do not redeem shares for assets
                IERC20(IERC7540(vault).share()).safeTransfer(singleVaultData_.receiverAddress, singleVaultData_.amount);
            }
            assets = 0;
        } else {
            assets = _processXChainWithdraw(singleVaultData_, srcChainId_);
        }

        return assets;
    }

    /// @inheritdoc BaseForm
    function _emergencyWithdraw(address receiverAddress_, uint256 amount_) internal virtual override {
        IERC7540 v = IERC7540(vault);
        IERC20 share = IERC20(v.share());

        if (receiverAddress_ == address(0)) revert Error.ZERO_ADDRESS();

        if (share.balanceOf(address(this)) < amount_) {
            revert Error.INSUFFICIENT_BALANCE();
        }

        share.safeTransfer(receiverAddress_, amount_);

        emit EmergencyWithdrawalProcessed(receiverAddress_, amount_);
    }

    /// @inheritdoc BaseForm
    function _forwardDustToPaymaster(address token_) internal override {
        _processForwardDustToPaymaster(token_);
    }

    /// @dev calls the vault to request deposit
    function _requestDirectDeposit(InitSingleVaultData memory singleVaultData_)
        internal
        returns (uint256 assetsToDeposit, uint256 requestId)
    {
        DirectDepositLocalVars memory vars;

        address vaultLoc = vault;
        IERC7540 v = IERC7540(vaultLoc);
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

        assetsToDeposit = IERC20(vars.asset).balanceOf(address(this)) - vars.balanceBefore;

        /// @dev the difference in vault tokens, ready to be deposited, is compared with the amount inscribed in the
        /// superform data
        if (
            assetsToDeposit * ENTIRE_SLIPPAGE
                < singleVaultData_.amount * (ENTIRE_SLIPPAGE - singleVaultData_.maxSlippage)
        ) {
            revert Error.DIRECT_DEPOSIT_SWAP_FAILED();
        }

        /// @dev notice that assetsToDeposit is deposited regardless if txData exists or not
        /// @dev this presumes no dust is left in the superform
        IERC20(vars.asset).safeIncreaseAllowance(vaultLoc, assetsToDeposit);

        /// ERC7540 logic
        /// @dev if receiver address is a contract it needs to have a onERC7540DepositReceived() function
        requestId = v.requestDeposit(assetsToDeposit, singleVaultData_.receiverAddress, address(this));

        emit RequestProcessed(
            CHAIN_ID, CHAIN_ID, singleVaultData_.payloadId, singleVaultData_.amount, vaultLoc, requestId
        );

        return (assetsToDeposit, requestId);
    }

    /// @dev calls the vault to request deposit
    function _requestXChainDeposit(
        InitSingleVaultData memory singleVaultData_,
        uint64 srcChainId_
    )
        internal
        returns (uint256 requestId)
    {
        (,, uint64 dstChainId) = singleVaultData_.superformId.getSuperform();
        address vaultLoc = vault;

        IERC7540 v = IERC7540(vaultLoc);

        if (IERC20(asset).allowance(msg.sender, address(this)) < singleVaultData_.amount) {
            revert Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();
        }

        /// @dev pulling from sender (CSR), to auto-send tokens back in case of failed deposits / reverts
        IERC20(asset).safeTransferFrom(msg.sender, address(this), singleVaultData_.amount);

        /// @dev allowance is modified inside of the IERC20.transferFrom() call
        IERC20(asset).safeIncreaseAllowance(vaultLoc, singleVaultData_.amount);

        /// ERC7540 logic
        requestId = v.requestDeposit(singleVaultData_.amount, singleVaultData_.receiverAddress, address(this));

        emit RequestProcessed(
            srcChainId_, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vaultLoc, requestId
        );

        return requestId;
    }

    /// @dev calls the vault to request unlock
    /// @notice superPositions are already burned at this point
    function _requestRedeem(
        InitSingleVaultData memory singleVaultData_,
        uint64 srcChainId_
    )
        internal
        returns (uint256 requestId_)
    {
        (,, uint64 dstChainId) = singleVaultData_.superformId.getSuperform();

        IERC7540 v = IERC7540(vault);

        uint256 requestId = v.requestRedeem(singleVaultData_.amount, singleVaultData_.receiverAddress, address(this));

        emit RequestProcessed(
            srcChainId_, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vault, requestId
        );

        return requestId;
    }

    /// @dev stores the deposit payload
    function _storeDepositPayload(
        uint8 type_,
        uint64 srcChainId_,
        uint256 assetsToDeposit_,
        uint256 requestId_,
        InitSingleVaultData memory data_
    )
        internal
    {
        IAsyncStateRegistry(superRegistry.getAddress(keccak256("ASYNC_STATE_REGISTRY"))).receiveDepositPayload(
            type_, srcChainId_, assetsToDeposit_, requestId_, data_
        );
    }

    /// @dev stores the withdraw payload
    function _storeWithdrawPayload(
        uint8 type_,
        uint64 srcChainId_,
        uint256 requestId_,
        InitSingleVaultData memory data_
    )
        internal
    {
        IAsyncStateRegistry(superRegistry.getAddress(keccak256("ASYNC_STATE_REGISTRY"))).receiveWithdrawPayload(
            type_, srcChainId_, requestId_, data_
        );
    }

    function _vaultKindCheck() public view returns (VaultKind kind) {
        bool depositSupported;
        bool redeemSupported;

        /// @dev ideally the check is made at the selector level
        try IERC165(vault).supportsInterface(type(IERC7540Deposit).interfaceId) returns (bool depositSupported_) {
            depositSupported = depositSupported_;
            try IERC165(vault).supportsInterface(type(IERC7540Redeem).interfaceId) returns (bool redeemSupported_) {
                redeemSupported = redeemSupported_;
            } catch {
                revert ERC_165_INTERFACE_REDEEM_CALL_FAILED();
            }
        } catch {
            revert ERC_165_INTERFACE_DEPOSIT_CALL_FAILED();
        }

        if (depositSupported && redeemSupported) {
            return VaultKind.FULLY_ASYNC;
        } else if (depositSupported) {
            return VaultKind.DEPOSIT_ASYNC;
        } else if (redeemSupported) {
            return VaultKind.REDEEM_ASYNC;
        } else {
            return VaultKind.SYNC;
        }
    }
}

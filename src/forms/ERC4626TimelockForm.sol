// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IERC4626Timelock} from "./interfaces/IERC4626Timelock.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {LiquidityHandler} from "../crosschain-liquidity/LiquidityHandler.sol";
import {InitSingleVaultData, LiqRequest} from "../types/DataTypes.sol";
import {BaseForm} from "../BaseForm.sol";
import {ERC20Form} from "./ERC20Form.sol";
import {IBridgeValidator} from "../interfaces/IBridgeValidator.sol";
import {IFormStateRegistry} from "../interfaces/IFormStateRegistry.sol";
import {Error} from "../utils/Error.sol";
import "../utils/DataPacking.sol";

/// @title ERC4626TimelockForm
/// @notice The Form implementation with timelock extension for IERC4626Timelock vaults
contract ERC4626TimelockForm is ERC20Form, LiquidityHandler {
    using SafeTransferLib for ERC20;

    uint256 unlockCounter;

    struct OwnerRequest {
        uint8 status; /// is requestUnlock already initiated?
        uint256 requestTimestamp; /// when requestUnlock was initiated
        InitSingleVaultData singleVaultData_; /// withdraw data to re-execute
    }

    mapping(address owner => OwnerRequest) public unlockId;

    // mapping (address owner => mapping(uint256 unlockId => InitSingleVaultData)) public unlockId;
    // mapping(uint256 => InitSingleVaultData) public unlockId;

    IFormStateRegistry public immutable formStateRegistry;

    modifier onlyFormStateRegistry() {
        if (msg.sender != address(formStateRegistry))
            revert Error.NOT_FORM_STATE_REGISTRY();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) ERC20Form(superRegistry_) {
        address formStateRegistry_ = superRegistry.formStateRegistry();
        formStateRegistry = IFormStateRegistry(formStateRegistry_);
    }

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
        return ERC20(IERC4626Timelock(vault).asset());
    }

    /// @inheritdoc BaseForm
    function getPricePerVaultShare()
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 vaultDecimals = ERC20(vault).decimals();
        return IERC4626Timelock(vault).convertToAssets(10 ** vaultDecimals);
    }

    /// @inheritdoc BaseForm
    function getVaultShareBalance()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return IERC4626Timelock(vault).balanceOf(address(this));
    }

    /// @inheritdoc BaseForm
    function getTotalAssets() public view virtual override returns (uint256) {
        return IERC4626Timelock(vault).totalAssets();
    }

    /// @inheritdoc BaseForm
    function getConvertPricePerVaultShare()
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 vaultDecimals = ERC20(vault).decimals();
        return IERC4626Timelock(vault).convertToAssets(10 ** vaultDecimals);
    }

    /// @inheritdoc BaseForm
    function getPreviewPricePerVaultShare()
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 vaultDecimals = ERC20(vault).decimals();
        return IERC4626Timelock(vault).previewRedeem(10 ** vaultDecimals);
    }

    /// @inheritdoc BaseForm
    function previewDepositTo(
        uint256 assets_
    ) public view virtual override returns (uint256) {
        return IERC4626Timelock(vault).convertToShares(assets_);
    }

    /// @inheritdoc BaseForm
    function previewWithdrawFrom(
        uint256 assets_
    ) public view virtual override returns (uint256) {
        return IERC4626Timelock(vault).previewWithdraw(assets_);
    }

    /// @dev ERC4626TimelockFork getter
    /// NOTE: Designed to act like a standardized function to return true/false for withdraw action on underlying Timelock Vault
    function checkUnlock(
        address vault_,
        uint256 shares_,
        address owner_
    ) public view returns (uint16) {
        OwnerRequest memory ownerRequest = unlockId[owner_];

        if (ownerRequest.requestTimestamp == 0) {
            /// unlock not initiated. requestUnlock in return
            return 2;
        }

        uint256 unlockTime = ownerRequest.requestTimestamp +
            IERC4626Timelock(vault_).getLockPeirod();

        if (block.timestamp < unlockTime) {
            /// unlock cooldown period not passed. revert Error.WITHDRAW_COOLDOWN_PERIOD
            return 3;
        } else {
            if (ownerRequest.singleVaultData_.amount >= shares_) {
                /// all clear. unlock after cooldown and enough of the shares. execute redeem
                return 0;
            } else {
                /// not enough shares to unlock. revert Error.NOT_ENOUGH_UNLOCKED
                return 1;
            }
        }
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
        IERC4626Timelock v = IERC4626Timelock(vars.vaultLoc);

        vars.collateral = address(v.asset());
        vars.collateralToken = ERC20(vars.collateral);
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
        /// DEVNOTE: allowance is modified inside of the ERC20.transferFrom() call
        vars.collateralToken.approve(vars.vaultLoc, singleVaultData_.amount);
        dstAmount = v.deposit(singleVaultData_.amount, address(this));
    }

    struct directWithdrawLocalVars {
        uint16 unlock;
        uint16 chainId;
        address collateral;
        address srcSender;
        address receiver;
        uint256 len1;
    }

    /// @inheritdoc BaseForm
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual override returns (uint256 dstAmount) {
        directWithdrawLocalVars memory vars;

        (vars.srcSender, , ) = _decodeTxData(singleVaultData_.txData);

        vars.len1 = singleVaultData_.liqData.txData.length;
        vars.receiver = vars.len1 == 0 ? vars.srcSender : address(this);

        IERC4626Timelock v = IERC4626Timelock(vault);
        vars.collateral = address(v.asset());

        if (address(v.asset()) != vars.collateral)
            revert Error.DIRECT_WITHDRAW_INVALID_COLLATERAL();

        vars.unlock = checkUnlock(
            vault,
            singleVaultData_.amount,
            vars.srcSender
        );
        if (vars.unlock == 0) {
            dstAmount = v.redeem(
                singleVaultData_.amount,
                vars.receiver,
                address(this)
            );

            if (vars.len1 != 0) {
                /// @dev this check here might be too much already, but can't hurt
                if (singleVaultData_.liqData.amount > singleVaultData_.amount)
                    revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

                vars.chainId = superRegistry.chainId();

                /// @dev NOTE: only allows withdraws to same chain
                IBridgeValidator(
                    superRegistry.getBridgeValidator(
                        singleVaultData_.liqData.bridgeId
                    )
                ).validateTxData(
                        singleVaultData_.liqData.txData,
                        vars.chainId,
                        vars.chainId,
                        false,
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
                    address(this),
                    singleVaultData_.liqData.nativeAmount,
                    "",
                    superRegistry.PERMIT2()
                );
            }
        } else if (vars.unlock == 1) {
            revert Error.LOCKED();
        } else if (vars.unlock == 2) {
            v.requestUnlock(singleVaultData_.amount, address(this));

            /// NOTE: This already burned SPs optimistically on SuperRouter
            /// NOTE: All Timelocked Forms need to go through the FORM_KEEPER, including same chain
            /// @dev Store for FORM_KEEPER
            ++unlockCounter;
            unlockId[vars.srcSender] = OwnerRequest({
                status: 1,
                requestTimestamp: block.timestamp,
                singleVaultData_: singleVaultData_
            });

            /// @dev Sent unlockCounter (id) to the FORM_KEEPER (contract on this chain)
            formStateRegistry.receivePayload(
                unlockCounter,
                singleVaultData_.superFormId,
                vars.srcSender
            );
        } else if (vars.unlock == 3) {
            revert Error.WITHDRAW_COOLDOWN_PERIOD();
        }
    }

    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual override returns (uint256 dstAmount) {
        (, , uint16 dstChainId) = _getSuperForm(singleVaultData_.superFormId);
        address vaultLoc = vault;
        IERC4626Timelock v = IERC4626Timelock(vaultLoc);

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
        uint16 unlock;
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

        IERC4626Timelock v = IERC4626Timelock(vars.vaultLoc);

        (vars.srcSender, vars.srcChainId, vars.txId) = _decodeTxData(
            singleVaultData_.txData
        );

        /// NOTE: This needs to match on 1st-step against srcSender
        /// NOTE: This needs to match on 2nd-step against payloadId
        /// NOTE: We have no payloadId (for formStateRegistry) at 1st step
        vars.unlock = checkUnlock(
            vault,
            singleVaultData_.amount,
            vars.srcSender
        );

        if (vars.unlock == 0) {
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
                v.redeem(
                    singleVaultData_.amount,
                    vars.srcSender,
                    address(this)
                );
            }
        } else if (vars.unlock == 1) {
            revert Error.LOCKED();
        } else if (vars.unlock == 2) {
            /// @dev Can vary per Timelock Vault implementation of initiating unlock
            /// @dev on ERC4626Timelock (wrappers) controlled by SuperForm we can use this function
            v.requestUnlock(singleVaultData_.amount, address(this));

            /// @dev Store for FORM_KEEPER
            ++unlockCounter;
            unlockId[vars.srcSender] = OwnerRequest({
                status: 1,
                requestTimestamp: block.timestamp,
                singleVaultData_: singleVaultData_
            });

            /// @dev Sent unlockCounter (id) to the FORM_KEEPER (contract on this chain)
            formStateRegistry.receivePayload(
                unlockCounter,
                singleVaultData_.superFormId,
                vars.srcSender
            );
        } else if (vars.unlock == 3) {
            revert Error.WITHDRAW_COOLDOWN_PERIOD();
        }

        /// @dev FIXME: check subgraph if this should emit amount or dstAmount
        emit Processed(
            vars.srcChainId,
            vars.dstChainId,
            vars.txId,
            singleVaultData_.amount,
            vars.vaultLoc
        );
    }

    /*///////////////////////////////////////////////////////////////
                RE-PROCESSING REDEEM AFTER COOLDOWN
    //////////////////////////////////////////////////////////////*/

    function processUnlock(
        address owner_
    )
        external
        onlyFormStateRegistry
        returns (OwnerRequest memory ownerRequest)
    {
        ownerRequest = unlockId[owner_];
        _xChainWithdrawFromVault(ownerRequest.singleVaultData_);
        delete unlockId[owner_];
    }

    /*///////////////////////////////////////////////////////////////
                INTERNAL VIEW VIRTUAL FUNCTIONS OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function _vaultSharesAmountToUnderlyingAmount(
        uint256 vaultSharesAmount_,
        uint256 /*pricePerVaultShare*/
    ) internal view virtual override returns (uint256) {
        return IERC4626Timelock(vault).convertToAssets(vaultSharesAmount_);
    }

    /// @inheritdoc BaseForm
    function _vaultSharesAmountToUnderlyingAmountRoundingUp(
        uint256 vaultSharesAmount_,
        uint256 /*pricePerVaultShare*/
    ) internal view virtual override returns (uint256) {
        return IERC4626Timelock(vault).previewMint(vaultSharesAmount_);
    }

    /// @inheritdoc BaseForm
    function _underlyingAmountToVaultSharesAmount(
        uint256 underlyingAmount_,
        uint256 /*pricePerVaultShare*/
    ) internal view virtual override returns (uint256) {
        return IERC4626Timelock(vault).convertToShares(underlyingAmount_);
    }
}

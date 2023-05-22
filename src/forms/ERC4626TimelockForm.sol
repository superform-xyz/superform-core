// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IERC4626TimelockVault} from "./interfaces/IERC4626TimelockVault.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {InitSingleVaultData} from "../types/DataTypes.sol";
import {ERC4626FormImplementation} from "./ERC4626FormImplementation.sol";
import {BaseForm} from "../BaseForm.sol";
import {IBridgeValidator} from "../interfaces/IBridgeValidator.sol";
import {IFormStateRegistry} from "../interfaces/IFormStateRegistry.sol";
import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {Error} from "../utils/Error.sol";
import "../utils/DataPacking.sol";

/// @title ERC4626TimelockForm
/// @notice The Form implementation with timelock extension for ERC4626 vaults
contract ERC4626TimelockForm is ERC4626FormImplementation {
    using SafeTransferLib for ERC20;

    /// @dev Internal counter of all unlock requests to be processed
    uint256 unlockCounter;

    /// @dev Internal struct to store individual user's request to unlock
    struct OwnerRequest {
        uint256 requestTimestamp; /// when requestUnlock was initiated
        InitSingleVaultData singleVaultData_; /// withdraw data to re-execute
    }

    mapping(address owner => OwnerRequest) public unlockId;

    /// @dev TwoStepsFormStateRegistry implementation, calls processUnlock()
    IFormStateRegistry public immutable twoStepsFormStateRegistry;

    /// @dev TwoStepsFormStateRegistry modifier for calling processUnlock()
    modifier onlyTwoStepsFormStateRegistry() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasTwoStepsFormStateRegistryRole(msg.sender))
            revert Error.NOT_FORM_STATE_REGISTRY();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) ERC4626FormImplementation(superRegistry_) {
        address formStateRegistry_ = superRegistry.twoStepsFormStateRegistry();
        twoStepsFormStateRegistry = IFormStateRegistry(formStateRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                            SPECIFIC TIMELOCKED FORM FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice ERC4626TimelockFork getter
    /// @dev Standardized function returning what step of a timelock withdraw process are we to execute
    function checkUnlock(address vault_, uint256 shares_, address owner_) public view returns (uint16) {
        OwnerRequest memory ownerRequest = unlockId[owner_];

        if (ownerRequest.requestTimestamp == 0) {
            /// unlock not initiated. requestUnlock in return
            return 2;
        }

        uint256 unlockTime = ownerRequest.requestTimestamp + IERC4626TimelockVault(vault_).getLockPeirod();

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

    /// @notice Called by TwoStepsFormStateRegistry to process 2nd step of redeem after cooldown period passes
    function processUnlock(
        address owner_
    ) external onlyTwoStepsFormStateRegistry returns (OwnerRequest memory ownerRequest) {
        ownerRequest = unlockId[owner_];
        _xChainWithdrawFromVault(ownerRequest.singleVaultData_);
        delete unlockId[owner_];
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function _directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual override returns (uint256 dstAmount) {
        (address srcSender, , ) = _decodeTxData(singleVaultData_.txData);

        dstAmount = _processDirectDeposit(singleVaultData_, srcSender);
    }

    struct directWithdrawTimelockedLocalVars {
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
        directWithdrawTimelockedLocalVars memory vars;

        (vars.srcSender, , ) = _decodeTxData(singleVaultData_.txData);

        vars.len1 = singleVaultData_.liqData.txData.length;
        vars.receiver = vars.len1 == 0 ? vars.srcSender : address(this);

        IERC4626TimelockVault v = IERC4626TimelockVault(vault);
        vars.collateral = address(v.asset());

        if (address(v.asset()) != vars.collateral) revert Error.DIRECT_WITHDRAW_INVALID_COLLATERAL();

        vars.unlock = checkUnlock(vault, singleVaultData_.amount, vars.srcSender);
        if (vars.unlock == 0) {
            dstAmount = v.redeem(singleVaultData_.amount, vars.receiver, address(this));

            if (vars.len1 != 0) {
                /// @dev this check here might be too much already, but can't hurt
                if (singleVaultData_.liqData.amount > singleVaultData_.amount)
                    revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

                vars.chainId = superRegistry.chainId();

                /// @dev NOTE: only allows withdraws to same chain
                IBridgeValidator(superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId)).validateTxData(
                    singleVaultData_.liqData.txData,
                    vars.chainId,
                    vars.chainId,
                    false,
                    address(this),
                    vars.srcSender,
                    singleVaultData_.liqData.token
                );

                dispatchTokens(
                    superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
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

            /// NOTE: We already burned SPs optimistically on SuperRouter
            /// NOTE: All Timelocked Forms need to go through the TwoStepsFormStateRegistry, including same chain
            /// @dev Store for TwoStepsFormStateRegistry
            ++unlockCounter;
            unlockId[vars.srcSender] = OwnerRequest({
                requestTimestamp: block.timestamp,
                singleVaultData_: singleVaultData_
            });

            /// @dev Sent unlockCounter (id) to the FORM_KEEPER (contract on this chain)
            twoStepsFormStateRegistry.receivePayload(unlockCounter, singleVaultData_.superFormId, vars.srcSender);
        } else if (vars.unlock == 3) {
            revert Error.WITHDRAW_COOLDOWN_PERIOD();
        }
    }

    /// @inheritdoc BaseForm
    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual override returns (uint256 dstAmount) {
        (, uint16 srcChainId, uint80 txId) = _decodeTxData(singleVaultData_.txData);

        dstAmount = _processXChainDeposit(singleVaultData_, srcChainId, txId);
    }

    struct xChainWithdrawTimelockecLocalVars {
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
    ) internal virtual override returns (uint256 dstAmount) {
        xChainWithdrawTimelockecLocalVars memory vars;
        (, , vars.dstChainId) = _getSuperForm(singleVaultData_.superFormId);
        vars.vaultLoc = vault;

        IERC4626TimelockVault v = IERC4626TimelockVault(vars.vaultLoc);

        (vars.srcSender, vars.srcChainId, vars.txId) = _decodeTxData(singleVaultData_.txData);

        /// NOTE: This needs to match on 1st-step against srcSender
        /// NOTE: This needs to match on 2nd-step against payloadId
        /// NOTE: We have no payloadId (for twoStepsFormStateRegistry) at 1st step
        vars.unlock = checkUnlock(vault, singleVaultData_.amount, vars.srcSender);

        if (vars.unlock == 0) {
            if (singleVaultData_.liqData.txData.length != 0) {
                /// Note Redeem Vault positions (we operate only on positions, not assets)
                vars.dstAmount = v.redeem(singleVaultData_.amount, address(this), address(this));

                vars.balanceBefore = ERC20(v.asset()).balanceOf(address(this));

                /// @dev NOTE: only allows withdraws back to source
                IBridgeValidator(superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId)).validateTxData(
                    singleVaultData_.liqData.txData,
                    vars.dstChainId,
                    vars.srcChainId,
                    false,
                    address(this),
                    vars.srcSender,
                    singleVaultData_.liqData.token
                );

                /// Note Send Tokens to Source Chain
                dispatchTokens(
                    superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
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
                v.redeem(singleVaultData_.amount, vars.srcSender, address(this));
            }
        } else if (vars.unlock == 1) {
            revert Error.LOCKED();
        } else if (vars.unlock == 2) {
            /// @dev Can vary per Timelock Vault implementation of initiating unlock
            /// @dev on ERC4626Timelock (wrappers) controlled by SuperForm we can use this function
            v.requestUnlock(singleVaultData_.amount, address(this));

            /// @dev Store for TwoStepsFormStateRegistry
            ++unlockCounter;
            unlockId[vars.srcSender] = OwnerRequest({
                requestTimestamp: block.timestamp,
                singleVaultData_: singleVaultData_
            });

            /// @dev Sent unlockCounter (id) to the FORM_KEEPER (contract on this chain)
            twoStepsFormStateRegistry.receivePayload(unlockCounter, singleVaultData_.superFormId, vars.srcSender);
        } else if (vars.unlock == 3) {
            revert Error.WITHDRAW_COOLDOWN_PERIOD();
        }

        /// @dev FIXME: check subgraph if this should emit amount or dstAmount
        emit Processed(vars.srcChainId, vars.dstChainId, vars.txId, singleVaultData_.amount, vars.vaultLoc);
    }
}

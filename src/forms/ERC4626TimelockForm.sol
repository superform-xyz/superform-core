// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626TimelockVault} from "./interfaces/IERC4626TimelockVault.sol";
import {InitSingleVaultData, AMBMessage, InitMultiVaultData} from "../types/DataTypes.sol";
import {ERC4626FormImplementation} from "./ERC4626FormImplementation.sol";
import {BaseForm} from "../BaseForm.sol";
import {IBaseStateRegistry} from "../interfaces/IBaseStateRegistry.sol";
import {IBridgeValidator} from "../interfaces/IBridgeValidator.sol";
import {ITwoStepsFormStateRegistry} from "../interfaces/ITwoStepsFormStateRegistry.sol";
import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {Error} from "../utils/Error.sol";
import "../utils/DataPacking.sol";

/// @title ERC4626TimelockForm
/// @notice The Form implementation with timelock extension for ERC4626 vaults
contract ERC4626TimelockForm is ERC4626FormImplementation {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// FIXME: Move it later to registry (improper pattern)
    /// @dev TwoStepsFormStateRegistry implementation, calls processUnlock()
    ITwoStepsFormStateRegistry public immutable twoStepsFormStateRegistry;

    mapping(uint256 dstPayloadId => mapping(uint256 index => uint256 requestTimestamp)) public xUnlockTime;
    mapping(address => uint256) public unlockAmount;
    mapping(address => uint256) public unlockTime;

    /// @dev TwoStepsFormStateRegistry modifier for calling processUnlock()
    modifier onlyTwoStepsFormStateRegistry() {
        if (superRegistry.twoStepsFormStateRegistry() != msg.sender) revert Error.NOT_FORM_STATE_REGISTRY();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) ERC4626FormImplementation(superRegistry_) {
        address formStateRegistry_ = superRegistry.twoStepsFormStateRegistry();
        twoStepsFormStateRegistry = ITwoStepsFormStateRegistry(formStateRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                    SPECIFIC TIMELOCKED FORM FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice ERC4626TimelockFork getter
    /// @dev Standardized function returning what step of a timelock withdraw process are we to execute

    /// @notice Called by TwoStepsFormStateRegistry to process 2nd step of redeem after cooldown period passes
    function processUnlock(
        uint256 payloadId_,
        uint256 index_
    ) external onlyTwoStepsFormStateRegistry returns (uint256 dstAmount) {
        (InitSingleVaultData memory data, address srcSender, uint64 srcChainId) = getSingleVaultDataAtIndex(
            payloadId_,
            index_
        );
        _xChainWithdrawFromVault(data, srcSender, srcChainId);
        delete xUnlockTime[payloadId_][index_];
    }

    function xcheckUnlock(address vault_, uint256 dstPayloadId_, uint256 index_) public view returns (uint16) {
        uint256 requestTimestamp = xUnlockTime[dstPayloadId_][index_];

        if (requestTimestamp == 0) return 2;

        /// @dev FIXME: this works for vaults that return lock period in terms of block.timestamp
        uint256 lockPeriod = IERC4626TimelockVault(vault_).getLockPeriod();
        if (requestTimestamp + lockPeriod < block.timestamp) return 3;

        /// @dev NOTE: feels like amount based validation is redundant (remove this later)
        return 0;
    }

    /// FIXME: for now the same chain is sequential & blocking
    function checkUnlock(address srcSender_, uint256 shares_) public view returns (uint16) {
        uint256 requestTimestamp = unlockTime[srcSender_];

        /// unlock not initiated. requestUnlock in return
        if (requestTimestamp == 0) return 2;

        /// @dev FIXME: this works for vaults that return lock period in terms of block.timestamp
        uint256 lockPeriod = IERC4626TimelockVault(vault).getLockPeriod();
        if (requestTimestamp + lockPeriod < block.timestamp) return 3;

        uint256 requestedAmount = unlockAmount[srcSender_];
        if (requestedAmount < shares_) return 1;

        /// all clear. unlock after cooldown and enough of the shares. execute redeem
        return 0;
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function _directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    ) internal virtual override returns (uint256 dstAmount) {
        dstAmount = _processDirectDeposit(singleVaultData_, srcSender_);
    }

    struct directWithdrawTimelockedLocalVars {
        uint16 unlock;
        uint64 chainId;
        address collateral;
        address receiver;
        uint256 isValidLiqReq;
    }

    /// @inheritdoc BaseForm
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    ) internal virtual override returns (uint256 dstAmount) {
        directWithdrawTimelockedLocalVars memory vars;

        vars.isValidLiqReq = singleVaultData_.liqData.txData.length;
        vars.receiver = vars.isValidLiqReq == 0 ? srcSender_ : address(this);

        IERC4626TimelockVault v = IERC4626TimelockVault(vault);
        vars.collateral = address(v.asset());

        uint256 amount = singleVaultData_.amount;

        if (address(v.asset()) != vars.collateral) revert Error.DIRECT_WITHDRAW_INVALID_COLLATERAL();

        vars.unlock = checkUnlock(srcSender_, amount);

        if (vars.unlock == 1) revert Error.LOCKED();
        if (vars.unlock == 3) revert Error.WITHDRAW_COOLDOWN_PERIOD();

        if (vars.unlock == 0) {
            /// FIXME: reset state here
            dstAmount = v.redeem(amount, vars.receiver, address(this));

            if (vars.isValidLiqReq != 0) {
                /// @dev this check here might be too much already, but can't hurt
                if (singleVaultData_.liqData.amount > amount) revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

                vars.chainId = superRegistry.chainId();

                /// @dev NOTE: only allows withdraws to same chain
                IBridgeValidator(superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId)).validateTxData(
                    singleVaultData_.liqData.txData,
                    vars.chainId,
                    vars.chainId,
                    false,
                    address(this),
                    srcSender_,
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
        }

        if (vars.unlock == 2) {
            v.requestUnlock(singleVaultData_.amount, address(this));

            /// NOTE: We already burned SPs optimistically on SuperFormRouter
            /// NOTE: All Timelocked Forms need to go through the TwoStepsFormStateRegistry, including same chain
            /// @dev Store for TwoStepsFormStateRegistry
            unlockTime[srcSender_] = block.timestamp;

            /// @dev this is now blocking & sequential; Work on this later
            unlockAmount[srcSender_] = singleVaultData_.amount;

            /// @dev Sent unlockCounter (id) to the FORM_KEEPER (contract on this chain)
            /// FIXME: not sure why this is here for same chain
            // twoStepsFormStateRegistry.receivePayload(
            //     unlockCounter,
            //     singleVaultData_.superFormId,
            //     srcSender_,
            //     superRegistry.chainId()
            // );
        }
    }

    /// @inheritdoc BaseForm
    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address,
        uint64 srcChainId_
    ) internal virtual override returns (uint256 dstAmount) {
        dstAmount = _processXChainDeposit(singleVaultData_, srcChainId_);
    }

    struct xChainWithdrawTimelockecLocalVars {
        uint16 unlock;
        uint64 dstChainId;
        address vault;
        uint256 balanceBefore;
        uint256 balanceAfter;
        uint256 payloadId;
        uint256 index;
    }

    /// @inheritdoc BaseForm
    function _xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    ) internal virtual override returns (uint256 dstAmount) {
        xChainWithdrawTimelockecLocalVars memory vars;

        (, , vars.dstChainId) = _getSuperForm(singleVaultData_.superFormId);
        (vars.payloadId, vars.index) = abi.decode(singleVaultData_.extraFormData, (uint256, uint256));

        vars.vault = vault;

        IERC4626TimelockVault v = IERC4626TimelockVault(vars.vault);

        /// NOTE: This needs to match on 1st-step against srcSender
        /// NOTE: This needs to match on 2nd-step against payloadId
        /// NOTE: We have no payloadId (for twoStepsFormStateRegistry) at 1st step
        vars.unlock = xcheckUnlock(vars.vault, vars.payloadId, vars.index);

        if (vars.unlock == 1) revert Error.LOCKED();
        if (vars.unlock == 3) revert Error.WITHDRAW_COOLDOWN_PERIOD();

        uint256 isValidLiqReq = singleVaultData_.liqData.txData.length;
        address receiver = isValidLiqReq == 0 ? srcSender_ : address(this);

        if (vars.unlock == 0) {
            dstAmount = v.redeem(singleVaultData_.amount, receiver, address(this));

            if (isValidLiqReq != 0) {
                /// Note Redeem Vault positions (we operate only on positions, not assets)
                vars.balanceBefore = IERC20(v.asset()).balanceOf(address(this));

                /// @dev NOTE: only allows withdraws back to source
                IBridgeValidator(superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId)).validateTxData(
                    singleVaultData_.liqData.txData,
                    vars.dstChainId,
                    srcChainId_,
                    false,
                    address(this),
                    srcSender_,
                    singleVaultData_.liqData.token
                );

                /// Note Send Tokens to Source Chain
                dispatchTokens(
                    superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                    singleVaultData_.liqData.txData,
                    singleVaultData_.liqData.token,
                    dstAmount,
                    address(this),
                    singleVaultData_.liqData.nativeAmount,
                    "",
                    superRegistry.PERMIT2()
                );
                vars.balanceAfter = IERC20(v.asset()).balanceOf(address(this));

                /// note: balance validation to prevent draining contract.
                if (vars.balanceAfter < vars.balanceBefore - dstAmount)
                    revert Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();
            }
        }

        if (vars.unlock == 2) {
            /// @dev Can vary per Timelock Vault implementation of initiating unlock
            /// @dev on ERC4626Timelock (wrappers) controlled by SuperForm we can use this function
            v.requestUnlock(singleVaultData_.amount, address(this));

            /// @dev Store for TwoStepsFormStateRegistry
            /// @dev NOTE aggregate based on payload id
            xUnlockTime[vars.payloadId][vars.index] = block.timestamp;

            /// @dev send job to twoStepsFormStateRegistry
            twoStepsFormStateRegistry.receivePayload(vars.payloadId, vars.index, singleVaultData_.superFormId);
        }

        /// @dev FIXME: check subgraph if this should emit amount or dstAmount
        emit Processed(srcChainId_, vars.dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vars.vault);
    }

    function getSingleVaultDataAtIndex(
        uint256 payloadId_,
        uint256 index_
    ) public view returns (InitSingleVaultData memory data, address, uint64) {
        bytes memory payload = IBaseStateRegistry(superRegistry.coreStateRegistry()).payload(payloadId_);
        AMBMessage memory payloadInfo = abi.decode(payload, (AMBMessage));

        (, , , , address srcSender, uint64 srcChainId) = _decodeTxInfo(payloadInfo.txInfo);

        InitMultiVaultData memory multiVaultData = abi.decode(payloadInfo.params, (InitMultiVaultData));

        data = InitSingleVaultData({
            payloadId: multiVaultData.payloadId,
            superFormId: multiVaultData.superFormIds[index_],
            amount: multiVaultData.amounts[index_],
            maxSlippage: multiVaultData.maxSlippage[index_],
            liqData: multiVaultData.liqData[index_],
            extraFormData: abi.encode(payloadId_, index_)
        });
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { BaseStateRegistry } from "../BaseStateRegistry.sol";
import { ISuperRBAC } from "../../interfaces/ISuperRBAC.sol";
import { ISuperPositions } from "../../interfaces/ISuperPositions.sol";
import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";
import { IPaymentHelper } from "../../interfaces/IPaymentHelper.sol";
import { IBaseForm } from "../../interfaces/IBaseForm.sol";
import { IDstSwapper } from "../../interfaces/IDstSwapper.sol";
import { ISuperformFactory } from "../../interfaces/ISuperformFactory.sol";
import { ICoreStateRegistry } from "../../interfaces/ICoreStateRegistry.sol";
import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";
import { DataLib } from "../../libraries/DataLib.sol";
import { ProofLib } from "../../libraries/ProofLib.sol";
import { ArrayCastLib } from "../../libraries/ArrayCastLib.sol";
import { PayloadUpdaterLib } from "../../libraries/PayloadUpdaterLib.sol";
import { Error } from "../../libraries/Error.sol";
import {
    PayloadState,
    AMBMessage,
    InitMultiVaultData,
    TransactionType,
    CallbackType,
    ReturnMultiData,
    ReturnSingleData,
    InitSingleVaultData,
    LiqRequest
} from "../../types/DataTypes.sol";
/// @title CoreStateRegistry
/// @author Zeropoint Labs
/// @dev enables communication between Superform Core Contracts deployed on all supported networks

contract CoreStateRegistry is BaseStateRegistry, ICoreStateRegistry {
    using SafeERC20 for IERC20;
    using DataLib for uint256;
    using ProofLib for AMBMessage;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    /// @dev just stores the superformIds that failed in a specific payload id
    mapping(uint256 payloadId => FailedDeposit) failedDeposits;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlySender() override {
        if (msg.sender != superRegistry.getAddress(keccak256("SUPERFORM_ROUTER"))) revert Error.NOT_SUPERFORM_ROUTER();
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(ISuperRegistry superRegistry_) BaseStateRegistry(superRegistry_) { }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ICoreStateRegistry
    function getFailedDeposits(uint256 payloadId_)
        external
        view
        override
        returns (uint256[] memory superformIds, uint256[] memory amounts, uint256 lastProposedTime)
    {
        FailedDeposit storage failedDeposit = failedDeposits[payloadId_];
        superformIds = failedDeposit.superformIds;
        amounts = failedDeposit.amounts;
        lastProposedTime = failedDeposit.lastProposedTimestamp;
    }

    /// @inheritdoc ICoreStateRegistry
    function validateSlippage(uint256 finalAmount_, uint256 amount_, uint256 maxSlippage_) public view returns (bool) {
        // only internal transaction
        if (msg.sender != address(this)) {
            revert Error.INVALID_INTERNAL_CALL();
        }

        return PayloadUpdaterLib.validateSlippage(finalAmount_, amount_, maxSlippage_);
    }
    
    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ICoreStateRegistry
    function updateDepositPayload(uint256 payloadId_, uint256[] calldata finalAmounts_) external virtual override {
        /// @dev validates the caller
        _onlyAllowedCaller(keccak256("CORE_STATE_REGISTRY_UPDATER_ROLE"));

        /// @dev validates the payload id
        _validatePayloadId(payloadId_);

        (uint256 prevPayloadHeader, bytes memory prevPayloadBody, bytes32 prevPayloadProof,,, uint8 isMulti,,,) =
            _getPayload(payloadId_);

        PayloadUpdaterLib.validatePayloadUpdate(
            prevPayloadHeader, uint8(TransactionType.DEPOSIT), payloadTracking[payloadId_], isMulti
        );

        PayloadState finalState;
        if (isMulti != 0) {
            (prevPayloadBody, finalState) = _updateMultiDeposit(payloadId_, prevPayloadBody, finalAmounts_);
        } else {
            (prevPayloadBody, finalState) = _updateSingleDeposit(payloadId_, prevPayloadBody, finalAmounts_[0]);
        }

        /// @dev updates the payload proof
        _updatePayload(payloadId_, prevPayloadProof, prevPayloadBody, prevPayloadHeader, finalState);

        /// @dev if payload is processed at this stage then it is failing
        if (finalState == PayloadState.PROCESSED) {
            emit PayloadProcessed(payloadId_);
            emit FailedXChainDeposits(payloadId_);
        }
    }

    /// @inheritdoc ICoreStateRegistry
    function updateWithdrawPayload(uint256 payloadId_, bytes[] calldata txData_) external virtual override {
        /// @dev validates the caller
        _onlyAllowedCaller(keccak256("CORE_STATE_REGISTRY_UPDATER_ROLE"));

        /// @dev validates the payload id
        _validatePayloadId(payloadId_);

        (
            uint256 prevPayloadHeader,
            bytes memory prevPayloadBody,
            bytes32 prevPayloadProof,
            ,
            ,
            uint8 isMulti,
            ,
            ,
            uint64 srcChainId
        ) = _getPayload(payloadId_);

        /// @dev validate payload update
        PayloadUpdaterLib.validatePayloadUpdate(
            prevPayloadHeader, uint8(TransactionType.WITHDRAW), payloadTracking[payloadId_], isMulti
        );
        prevPayloadBody = _updateWithdrawPayload(prevPayloadBody, srcChainId, txData_, isMulti);

        /// @dev updates the payload proof
        _updatePayload(payloadId_, prevPayloadProof, prevPayloadBody, prevPayloadHeader, PayloadState.UPDATED);

        emit PayloadUpdated(payloadId_);
    }

    /// @inheritdoc BaseStateRegistry
    function processPayload(uint256 payloadId_) external payable virtual override {
        /// @dev validates the caller
        _onlyAllowedCaller(keccak256("CORE_STATE_REGISTRY_PROCESSOR_ROLE"));

        /// @dev validates the payload id
        _validatePayloadId(payloadId_);

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.PAYLOAD_ALREADY_PROCESSED();
        }

        PayloadState initialState = payloadTracking[payloadId_];
        /// @dev sets status as processed to prevent re-entrancy
        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        (
            uint256 payloadHeader_,
            bytes memory payloadBody_,
            ,
            uint8 txType,
            uint8 callbackType,
            uint8 isMulti,
            ,
            address srcSender,
            uint64 srcChainId
        ) = _getPayload(payloadId_);

        AMBMessage memory message_ = AMBMessage(payloadHeader_, payloadBody_);

        /// @dev mint superPositions for successful deposits or remint for failed withdraws
        if (callbackType == uint256(CallbackType.RETURN) || callbackType == uint256(CallbackType.FAIL)) {
            isMulti == 1
                ? ISuperPositions(_getAddress(keccak256("SUPER_POSITIONS"))).stateMultiSync(message_)
                : ISuperPositions(_getAddress(keccak256("SUPER_POSITIONS"))).stateSync(message_);
        } else if (callbackType == uint8(CallbackType.INIT)) {
            /// @dev for initial payload processing
            bytes memory returnMessage;

            if (txType == uint8(TransactionType.WITHDRAW)) {
                returnMessage = isMulti == 1
                    ? _multiWithdrawal(payloadId_, payloadBody_, srcSender, srcChainId)
                    : _singleWithdrawal(payloadId_, payloadBody_, srcSender, srcChainId);
            } else if (txType == uint8(TransactionType.DEPOSIT)) {
                if (initialState != PayloadState.UPDATED) {
                    revert Error.PAYLOAD_NOT_UPDATED();
                }

                returnMessage = isMulti == 1
                    ? _multiDeposit(payloadId_, payloadBody_, srcSender, srcChainId)
                    : _singleDeposit(payloadId_, payloadBody_, srcSender, srcChainId);
            }

            _processAck(payloadId_, srcChainId, returnMessage);
        } else {
            revert Error.INVALID_PAYLOAD_TYPE();
        }

        emit PayloadProcessed(payloadId_);
    }

    /// @inheritdoc ICoreStateRegistry
    function proposeRescueFailedDeposits(uint256 payloadId_, uint256[] calldata proposedAmounts_) external override {
        /// @dev validates the caller
        _onlyAllowedCaller(keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE"));

        /// @dev validates the payload id
        _validatePayloadId(payloadId_);

        FailedDeposit storage failedDeposits_ = failedDeposits[payloadId_];

        if (failedDeposits_.superformIds.length == 0 || failedDeposits_.superformIds.length != proposedAmounts_.length)
        {
            revert Error.INVALID_RESCUE_DATA();
        }

        if (failedDeposits_.lastProposedTimestamp != 0) {
            revert Error.RESCUE_ALREADY_PROPOSED();
        }

        /// @dev note: should set this value to dstSwapper.failedSwap().amount for interim rescue
        failedDeposits[payloadId_].amounts = proposedAmounts_;
        failedDeposits[payloadId_].lastProposedTimestamp = block.timestamp;

        (,, uint8 multi,,,) = DataLib.decodeTxInfo(payloadHeader[payloadId_]);

        address receiverAddress;
        if (multi == 1) {
            receiverAddress = abi.decode(payloadBody[payloadId_], (InitMultiVaultData)).receiverAddress;
        } else {
            receiverAddress = abi.decode(payloadBody[payloadId_], (InitSingleVaultData)).receiverAddress;
        }

        failedDeposits[payloadId_].receiverAddress = receiverAddress;
        emit RescueProposed(payloadId_, failedDeposits_.superformIds, proposedAmounts_, block.timestamp);
    }

    /// @inheritdoc ICoreStateRegistry
    function disputeRescueFailedDeposits(uint256 payloadId_) external override {
        /// @dev validates the payload id
        _validatePayloadId(payloadId_);

        FailedDeposit storage failedDeposits_ = failedDeposits[payloadId_];

        /// @dev the msg sender should be the refund address (or) the disputer
        if (
            !(
                msg.sender == failedDeposits_.receiverAddress
                    || _hasRole(keccak256("CORE_STATE_REGISTRY_DISPUTER_ROLE"), msg.sender)
            )
        ) {
            revert Error.NOT_VALID_DISPUTER();
        }

        /// @dev the timelock is already elapsed to dispute
        if (
            failedDeposits_.lastProposedTimestamp == 0
                || block.timestamp > failedDeposits_.lastProposedTimestamp + _getDelay()
        ) {
            revert Error.DISPUTE_TIME_ELAPSED();
        }

        /// @dev just can reset last proposed time here, since amounts should be updated again to
        /// pass the lastProposedTimestamp zero check in finalize
        failedDeposits[payloadId_].lastProposedTimestamp = 0;

        emit RescueDisputed(payloadId_);
    }

    /// @inheritdoc ICoreStateRegistry
    /// @notice is an open function & can be executed by anyone
    function finalizeRescueFailedDeposits(uint256 payloadId_) external override {
        /// @dev validates the payload id
        _validatePayloadId(payloadId_);

        FailedDeposit storage failedDeposits_ = failedDeposits[payloadId_];

        /// @dev the timelock is elapsed
        if (
            failedDeposits_.lastProposedTimestamp == 0
                || block.timestamp <= failedDeposits_.lastProposedTimestamp + _getDelay()
        ) {
            revert Error.RESCUE_LOCKED();
        }

        /// @dev set to zero to prevent re-entrancy
        failedDeposits_.lastProposedTimestamp = 0;
        IDstSwapper dstSwapper = IDstSwapper(_getAddress(keccak256("DST_SWAPPER")));

        uint256 len = failedDeposits_.amounts.length;
        for (uint256 i; i < len; ++i) {
            /// @dev refunds the amount to user specified refund address
            if (failedDeposits_.settleFromDstSwapper[i]) {
                dstSwapper.processFailedTx(
                    failedDeposits_.receiverAddress, failedDeposits_.settlementToken[i], failedDeposits_.amounts[i]
                );
            } else {
                IERC20(failedDeposits_.settlementToken[i]).safeTransfer(
                    failedDeposits_.receiverAddress, failedDeposits_.amounts[i]
                );
            }
        }

        delete failedDeposits[payloadId_];
        emit RescueFinalized(payloadId_);
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev returns vault asset from superform
    function _getVaultAsset(address superform_) internal view returns (address) {
        return IBaseForm(superform_).getVaultAsset();
    }

    /// @dev returns if superform is valid
    function _isSuperform(uint256 superformId_) internal view returns (bool) {
        return ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY"))).isSuperform(superformId_);
    }

    /// @dev returns a superformAddress
    function _getSuperform(uint256 superformId_) internal pure returns (address superform) {
        (superform,,) = superformId_.getSuperform();
    }

    /// @dev returns if an address has a specific role
    function _hasRole(bytes32 id_, address addressToCheck_) internal view returns (bool) {
        return ISuperRBAC(_getAddress(keccak256("SUPER_RBAC"))).hasRole(id_, addressToCheck_);
    }

    /// @dev returns the registry address for id
    function _getStateRegistryId(address registryAddress_) internal view returns (uint8 id) {
        return superRegistry.getStateRegistryId(registryAddress_);
    }

    /// @dev returns the address from super registry
    function _getAddress(bytes32 id_) internal view returns (address) {
        return superRegistry.getAddress(id_);
    }

    /// @dev returns the current timelock delay
    function _getDelay() internal view returns (uint256) {
        uint256 delay = superRegistry.delay();
        if (delay == 0) {
            revert Error.DELAY_NOT_SET();
        }
        return delay;
    }

    function _validatePayloadId(uint256 payloadId_) internal view {
        if (payloadId_ > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }
    }

    function _onlyAllowedCaller(bytes32 role_) internal view {
        if (!_hasRole(role_, msg.sender)) revert Error.NOT_PRIVILEGED_CALLER(role_);
    }

    /// @dev retrieves information associated with the payload and validates quorum
    function _getPayload(uint256 payloadId_)
        internal
        view
        returns (
            uint256 payloadHeader_,
            bytes memory payloadBody_,
            bytes32 payloadProof,
            uint8 txType,
            uint8 callbackType,
            uint8 isMulti,
            uint8 registryId,
            address srcSender,
            uint64 srcChainId
        )
    {
        payloadHeader_ = payloadHeader[payloadId_];
        payloadBody_ = payloadBody[payloadId_];
        payloadProof = AMBMessage(payloadHeader_, payloadBody_).computeProof();
        (txType, callbackType, isMulti, registryId, srcSender, srcChainId) = payloadHeader_.decodeTxInfo();

        /// @dev the number of valid proofs (quorum) must be equal or larger to the required messaging quorum
        if (messageQuorum[payloadProof] < _getQuorum(srcChainId)) {
            revert Error.INSUFFICIENT_QUORUM();
        }
    }

    /// @dev helper function to update multi vault deposit payload
    function _updateMultiDeposit(
        uint256 payloadId_,
        bytes memory prevPayloadBody_,
        uint256[] calldata finalAmounts_
    )
        internal
        returns (bytes memory newPayloadBody_, PayloadState finalState_)
    {
        InitMultiVaultData memory multiVaultData = abi.decode(prevPayloadBody_, (InitMultiVaultData));
        IDstSwapper dstSwapper = IDstSwapper(_getAddress(keccak256("DST_SWAPPER")));

        uint256 arrLen = finalAmounts_.length;

        /// @dev compare number of vaults to update with provided finalAmounts length
        if (multiVaultData.amounts.length != arrLen) {
            revert Error.DIFFERENT_PAYLOAD_UPDATE_AMOUNTS_LENGTH();
        }

        uint256 validLen;
        for (uint256 i; i < arrLen; ++i) {
            if (finalAmounts_[i] == 0) {
                revert Error.ZERO_AMOUNT();
            }

            /// @dev observe not consuming the second return value
            (multiVaultData.amounts[i],, validLen) = _updateAmount(
                dstSwapper,
                multiVaultData.hasDstSwaps[i],
                payloadId_,
                i,
                finalAmounts_[i],
                multiVaultData.superformIds[i],
                multiVaultData.amounts[i],
                multiVaultData.maxSlippages[i],
                finalState_,
                validLen
            );
        }

        /// @dev validLen > 0 for the cases where there was at least one deposit update that had valid slippage
        /// @dev (v1: passedSlippage, v2: failedSlippage, v3: passedSlippage)
        /// @dev final vaults: (v1, v3) / PayloadState.UPDATED
        /// @dev if validLen is 0 then Payload is marked as processed and can be extracted via rescue
        if (validLen != 0) {
            uint256[] memory finalSuperformIds = new uint256[](validLen);
            uint256[] memory finalAmounts = new uint256[](validLen);
            uint256[] memory maxSlippage = new uint256[](validLen);
            bool[] memory hasDstSwaps = new bool[](validLen);
            bool[] memory finalRetain4626s = new bool[](validLen);

            uint256 currLen;
            for (uint256 i; i < arrLen; ++i) {
                if (multiVaultData.amounts[i] != 0) {
                    finalSuperformIds[currLen] = multiVaultData.superformIds[i];
                    finalAmounts[currLen] = multiVaultData.amounts[i];
                    maxSlippage[currLen] = multiVaultData.maxSlippages[i];
                    hasDstSwaps[currLen] = multiVaultData.hasDstSwaps[i];
                    finalRetain4626s[currLen] = multiVaultData.retain4626s[i];

                    ++currLen;
                }
            }

            multiVaultData.amounts = finalAmounts;
            multiVaultData.superformIds = finalSuperformIds;
            multiVaultData.maxSlippages = maxSlippage;
            multiVaultData.hasDstSwaps = hasDstSwaps;
            multiVaultData.retain4626s = finalRetain4626s;
            finalState_ = PayloadState.UPDATED;
        } else {
            finalState_ = PayloadState.PROCESSED;
        }
        newPayloadBody_ = abi.encode(multiVaultData);
    }

    /// @dev helper function to update single vault deposit payload
    function _updateSingleDeposit(
        uint256 payloadId_,
        bytes memory prevPayloadBody_,
        uint256 finalAmount_
    )
        internal
        returns (bytes memory newPayloadBody_, PayloadState finalState_)
    {
        InitSingleVaultData memory singleVaultData = abi.decode(prevPayloadBody_, (InitSingleVaultData));
        IDstSwapper dstSwapper = IDstSwapper(_getAddress(keccak256("DST_SWAPPER")));

        if (finalAmount_ == 0) {
            revert Error.ZERO_AMOUNT();
        }

        /// @dev observe not consuming the third return value
        (singleVaultData.amount, finalState_,) = _updateAmount(
            dstSwapper,
            singleVaultData.hasDstSwap,
            payloadId_,
            0,
            finalAmount_,
            singleVaultData.superformId,
            singleVaultData.amount,
            singleVaultData.maxSlippage,
            finalState_,
            0
        );

        newPayloadBody_ = abi.encode(singleVaultData);
    }

    function _updateAmount(
        IDstSwapper dstSwapper,
        bool hasDstSwap_,
        uint256 payloadId_,
        uint256 index_,
        uint256 finalAmount_,
        uint256 superformId_,
        uint256 amount_,
        uint256 maxSlippage_,
        PayloadState finalState_,
        uint256 validLen_
    )
        internal
        returns (uint256, PayloadState, uint256)
    {
        bool failedSwapQueued;
        if (hasDstSwap_) {
            if (dstSwapper.swappedAmount(payloadId_, index_) != finalAmount_) {
                (address interimToken, uint256 amount) =
                    dstSwapper.getPostDstSwapFailureUpdatedTokenAmount(payloadId_, index_);

                if (amount != finalAmount_) {
                    revert Error.INVALID_DST_SWAP_AMOUNT();
                } else {
                    failedSwapQueued = true;
                    failedDeposits[payloadId_].superformIds.push(superformId_);
                    failedDeposits[payloadId_].settlementToken.push(interimToken);
                    failedDeposits[payloadId_].settleFromDstSwapper.push(true);

                    /// @dev sets amount to zero and will mark the payload as PROCESSED
                    amount_ = 0;
                    finalState_ = PayloadState.PROCESSED;
                }
            }
        }

        /// @dev validate payload update
        /// @dev validLen may only be increased here in the case where slippage for the update is valid
        /// @notice we enter this if condition only if there is a valid dstSwap OR if there is just bridging to this
        /// contract
        if (!failedSwapQueued) {
            /// if the slippage is within allowed amount && the superform id also exists
            try this.validateSlippage(finalAmount_, amount_, maxSlippage_) returns (bool valid) {
                /// @dev in case of a valid slippage check we update the amount to finalAmount_
                if (valid) {
                    amount_ = finalAmount_;
                    /// @dev Mark the payload as UPDATED
                    finalState_ = PayloadState.UPDATED;
                }
            } catch {
                /// @dev in case of negative slippage we don't update the amount in the user request to the amount
                /// provided by the keeper
                /// @notice it remains as the original amount supplied by the user in the original state request
                /// @notice This means than any difference from the amount provided by the keepeer to the user supplied
                /// amount will be collected in this contract and remain here
                /// @notice we consider this to also be validSlippage = true
                /// @dev Mark the payload as UPDATED
                finalState_ = PayloadState.UPDATED;
            }

            if (!(_isSuperform(superformId_) && finalState_ == PayloadState.UPDATED)) {
                failedDeposits[payloadId_].superformIds.push(superformId_);

                address asset;
                try IBaseForm(_getSuperform(superformId_)).getVaultAsset() returns (address asset_) {
                    asset = asset_;
                } catch {
                    /// @dev if its error, we just consider asset as zero address
                }
                /// @dev if superform is invalid, try catch will fail and asset pushed is address (0)
                /// @notice this means that if a user tries to game the protocol with an invalid superformId, the funds
                /// bridged over that failed will be stuck here
                failedDeposits[payloadId_].settlementToken.push(asset);
                failedDeposits[payloadId_].settleFromDstSwapper.push(false);

                /// @dev sets amount to zero and will mark the payload as PROCESSED (overriding the previous memory
                /// settings)
                amount_ = 0;
                finalState_ = PayloadState.PROCESSED;
            } else {
                ++validLen_;
            }
        }

        return (amount_, finalState_, validLen_);
    }

    /// @dev helper function to update multi vault withdraw payload
    function _updateWithdrawPayload(
        bytes memory prevPayloadBody_,
        uint64 srcChainId_,
        bytes[] calldata txData_,
        uint8 multi
    )
        internal
        view
        returns (bytes memory)
    {
        InitMultiVaultData memory multiVaultData;
        InitSingleVaultData memory singleVaultData;
        if (multi == 1) {
            multiVaultData = abi.decode(prevPayloadBody_, (InitMultiVaultData));
        } else {
            singleVaultData = abi.decode(prevPayloadBody_, (InitSingleVaultData));
            multiVaultData = ArrayCastLib.castToMultiVaultData(singleVaultData);
        }

        if (multiVaultData.liqData.length != txData_.length) {
            revert Error.DIFFERENT_PAYLOAD_UPDATE_TX_DATA_LENGTH();
        }

        multiVaultData = _updateTxData(txData_, multiVaultData, srcChainId_, CHAIN_ID);

        if (multi == 0) {
            singleVaultData.liqData.txData = multiVaultData.liqData[0].txData;
            return abi.encode(singleVaultData);
        }

        return abi.encode(multiVaultData);
    }

    /// @dev validates the incoming update data
    function _updateTxData(
        bytes[] calldata txData_,
        InitMultiVaultData memory multiVaultData_,
        uint64 srcChainId_,
        uint64 dstChainId_
    )
        internal
        view
        returns (InitMultiVaultData memory)
    {
        uint256 len = multiVaultData_.liqData.length;
        IBaseForm superform;

        for (uint256 i; i < len; ++i) {
            if (txData_[i].length != 0 && multiVaultData_.liqData[i].txData.length == 0) {
                (address superformAddress,,) = multiVaultData_.superformIds[i].getSuperform();
                superform = IBaseForm(superformAddress);

                /// @dev for withdrawals the payload update can happen on core state registry (for normal forms)
                /// and also can happen in timelock state registry (for timelock form)

                /// @notice this check validates if the state registry is eligible to update tx data for the
                /// corresponding superform
                if (superform.getStateRegistryId() == _getStateRegistryId(address(this))) {
                    PayloadUpdaterLib.validateLiqReq(multiVaultData_.liqData[i]);

                    IBridgeValidator bridgeValidator =
                        IBridgeValidator(superRegistry.getBridgeValidator(multiVaultData_.liqData[i].bridgeId));

                    bridgeValidator.validateTxData(
                        IBridgeValidator.ValidateTxDataArgs(
                            txData_[i],
                            dstChainId_,
                            srcChainId_,
                            multiVaultData_.liqData[i].liqDstChainId,
                            false,
                            superformAddress,
                            multiVaultData_.receiverAddress,
                            superform.getVaultAsset(),
                            address(0)
                        )
                    );

                    if (
                        !PayloadUpdaterLib.validateSlippage(
                            bridgeValidator.decodeAmountIn(txData_[i], false),
                            superform.previewRedeemFrom(multiVaultData_.amounts[i]),
                            multiVaultData_.maxSlippages[i]
                        )
                    ) {
                        revert Error.SLIPPAGE_OUT_OF_BOUNDS();
                    }

                    multiVaultData_.liqData[i].txData = txData_[i];
                }
            }
        }

        return multiVaultData_;
    }

    function _multiWithdrawal(
        uint256 payloadId_,
        bytes memory payload_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        returns (bytes memory)
    {
        InitMultiVaultData memory multiVaultData = abi.decode(payload_, (InitMultiVaultData));

        bool errors;
        uint256 len = multiVaultData.superformIds.length;
        address superformFactory = superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"));

        for (uint256 i; i < len; ++i) {
            // @dev validates if superformId exists on factory
            if (!ISuperformFactory(superformFactory).isSuperform(multiVaultData.superformIds[i])) {
                revert Error.SUPERFORM_ID_NONEXISTENT();
            }

            /// @dev Store destination payloadId_ & index in extraFormData (tbd: 1-step flow doesnt need this)
            (address superform_,,) = multiVaultData.superformIds[i].getSuperform();

            try IBaseForm(superform_).xChainWithdrawFromVault(
                InitSingleVaultData({
                    payloadId: multiVaultData.payloadId,
                    superformId: multiVaultData.superformIds[i],
                    amount: multiVaultData.amounts[i],
                    maxSlippage: multiVaultData.maxSlippages[i],
                    liqData: multiVaultData.liqData[i],
                    hasDstSwap: false,
                    retain4626: false,
                    receiverAddress: multiVaultData.receiverAddress,
                    extraFormData: abi.encode(payloadId_, i)
                }),
                srcSender_,
                srcChainId_
            ) {
                /// @dev marks the indexes that don't require a callback re-mint of shares (successful
                /// withdraws)
                multiVaultData.amounts[i] = 0;
            } catch {
                /// @dev detect if there is at least one failed withdraw
                errors = true;
            }
        }

        /// @dev if at least one error happens, the shares will be re-minted for the affected superformIds
        if (errors) {
            return _multiReturnData(
                srcSender_,
                multiVaultData.payloadId,
                TransactionType.WITHDRAW,
                CallbackType.FAIL,
                multiVaultData.superformIds,
                multiVaultData.amounts
            );
        }

        return "";
    }

    function _multiDeposit(
        uint256 payloadId_,
        bytes memory payload_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        returns (bytes memory)
    {
        InitMultiVaultData memory multiVaultData = abi.decode(payload_, (InitMultiVaultData));

        address[] memory superforms = DataLib.getSuperforms(multiVaultData.superformIds);

        IERC20 underlying;
        uint256 numberOfVaults = multiVaultData.superformIds.length;
        bool fulfilment;
        bool errors;
        for (uint256 i; i < numberOfVaults; ++i) {
            /// @dev if updating the deposit payload fails because of slippage, multiVaultData.amounts[i] is set to 0
            /// @dev this means that this amount was already added to the failedDeposits state variable and should not
            /// be re-added (or processed here)
            if (multiVaultData.amounts[i] != 0) {
                underlying = IERC20(_getVaultAsset(superforms[i]));

                if (underlying.balanceOf(address(this)) >= multiVaultData.amounts[i]) {
                    underlying.safeIncreaseAllowance(superforms[i], multiVaultData.amounts[i]);
                    LiqRequest memory emptyRequest;

                    /// @notice  If a given deposit fails, we are minting 0 SPs back on source (slight gas waste)
                    try IBaseForm(superforms[i]).xChainDepositIntoVault(
                        InitSingleVaultData({
                            payloadId: multiVaultData.payloadId,
                            superformId: multiVaultData.superformIds[i],
                            amount: multiVaultData.amounts[i],
                            maxSlippage: multiVaultData.maxSlippages[i],
                            liqData: emptyRequest,
                            hasDstSwap: false,
                            retain4626: multiVaultData.retain4626s[i],
                            receiverAddress: multiVaultData.receiverAddress,
                            extraFormData: multiVaultData.extraFormData
                        }),
                        srcSender_,
                        srcChainId_
                    ) returns (uint256 shares) {
                        if (shares != 0 && !multiVaultData.retain4626s[i]) {
                            fulfilment = true;
                            /// @dev marks the indexes that require a callback mint of shares (successful)
                            multiVaultData.amounts[i] = shares;
                        } else {
                            multiVaultData.amounts[i] = 0;
                        }
                    } catch {
                        /// @dev cleaning unused approval
                        underlying.safeDecreaseAllowance(superforms[i], multiVaultData.amounts[i]);

                        /// @dev if any deposit fails, we mark errors as true and add it to failedDepositSuperformIds
                        /// mapping for future rescuing
                        errors = true;

                        failedDeposits[payloadId_].superformIds.push(multiVaultData.superformIds[i]);

                        /// @dev clearing multiVaultData.amounts so that in case that fulfillment is true these amounts
                        /// are not minted
                        multiVaultData.amounts[i] = 0;
                        failedDeposits[payloadId_].settlementToken.push(IBaseForm(superforms[i]).getVaultAsset());
                        failedDeposits[payloadId_].settleFromDstSwapper.push(false);
                    }
                } else {
                    revert Error.BRIDGE_TOKENS_PENDING();
                }
            }
        }

        if (errors) {
            emit FailedXChainDeposits(payloadId_);
        }

        /// @dev issue superPositions if at least one vault deposit passed
        if (fulfilment) {
            return _multiReturnData(
                srcSender_,
                multiVaultData.payloadId,
                TransactionType.DEPOSIT,
                CallbackType.RETURN,
                multiVaultData.superformIds,
                multiVaultData.amounts
            );
        }

        return "";
    }

    function _singleWithdrawal(
        uint256 payloadId_,
        bytes memory payload_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        returns (bytes memory)
    {
        InitSingleVaultData memory singleVaultData = abi.decode(payload_, (InitSingleVaultData));
        singleVaultData.extraFormData = abi.encode(payloadId_, 0);

        if (!_isSuperform(singleVaultData.superformId)) {
            revert Error.SUPERFORM_ID_NONEXISTENT();
        }

        (address superform_,,) = singleVaultData.superformId.getSuperform();
        /// @dev Withdraw from superform
        try IBaseForm(superform_).xChainWithdrawFromVault(singleVaultData, srcSender_, srcChainId_) {
            // Handle the case when the external call succeeds
        } catch {
            // Handle the case when the external call reverts for whatever reason
            /// https://solidity-by-example.org/try-catch/
            return _singleReturnData(
                srcSender_,
                singleVaultData.payloadId,
                TransactionType.WITHDRAW,
                CallbackType.FAIL,
                singleVaultData.superformId,
                singleVaultData.amount
            );
        }

        return "";
    }

    function _singleDeposit(
        uint256 payloadId_,
        bytes memory payload_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        returns (bytes memory)
    {
        InitSingleVaultData memory singleVaultData = abi.decode(payload_, (InitSingleVaultData));

        address superform_ = _getSuperform(singleVaultData.superformId);
        address vaultAsset = _getVaultAsset(superform_);
        IERC20 underlying = IERC20(vaultAsset);

        if (underlying.balanceOf(address(this)) >= singleVaultData.amount) {
            underlying.safeIncreaseAllowance(superform_, singleVaultData.amount);

            /// @dev deposit to superform
            try IBaseForm(superform_).xChainDepositIntoVault(singleVaultData, srcSender_, srcChainId_) returns (
                uint256 shares
            ) {
                if (shares != 0 && !singleVaultData.retain4626) {
                    return _singleReturnData(
                        srcSender_,
                        singleVaultData.payloadId,
                        TransactionType.DEPOSIT,
                        CallbackType.RETURN,
                        singleVaultData.superformId,
                        shares
                    );
                }
            } catch {
                /// @dev cleaning unused approval
                underlying.safeDecreaseAllowance(superform_, singleVaultData.amount);

                /// @dev if any deposit fails, add it to failedDepositSuperformIds mapping for future rescuing
                failedDeposits[payloadId_].superformIds.push(singleVaultData.superformId);
                failedDeposits[payloadId_].settlementToken.push(vaultAsset);
                failedDeposits[payloadId_].settleFromDstSwapper.push(false);

                emit FailedXChainDeposits(payloadId_);
            }
        } else {
            revert Error.BRIDGE_TOKENS_PENDING();
        }

        return "";
    }

    function _processAck(uint256 payloadId_, uint64 srcChainId_, bytes memory returnMessage_) internal {
        /// @dev if deposits succeeded or some withdrawal failed, dispatch a callback
        if (returnMessage_.length != 0) {
            uint8[] memory ambIds = msgAMBs[payloadId_];

            (, bytes memory extraData) = IPaymentHelper(_getAddress(keccak256("PAYMENT_HELPER"))).calculateAMBData(
                srcChainId_, ambIds, returnMessage_
            );

            _dispatchPayload(msg.sender, ambIds, srcChainId_, returnMessage_, extraData);
        }
    }

    /// @notice depositSync and withdrawSync internal method for sending message back to the source chain
    function _multiReturnData(
        address srcSender_,
        uint256 payloadId_,
        TransactionType txType,
        CallbackType returnType_,
        uint256[] memory superformIds_,
        uint256[] memory amounts_
    )
        internal
        view
        returns (bytes memory)
    {
        /// @dev Send Data to Source to issue superform positions (failed withdraws and successful deposits)
        return abi.encode(
            AMBMessage(
                DataLib.packTxInfo(
                    uint8(txType), uint8(returnType_), 1, _getStateRegistryId(address(this)), srcSender_, CHAIN_ID
                ),
                abi.encode(ReturnMultiData(payloadId_, superformIds_, amounts_))
            )
        );
    }

    /// @notice depositSync and withdrawSync internal method for sending message back to the source chain
    function _singleReturnData(
        address srcSender_,
        uint256 payloadId_,
        TransactionType txType,
        CallbackType returnType_,
        uint256 superformId_,
        uint256 amount_
    )
        internal
        view
        returns (bytes memory)
    {
        /// @dev Send Data to Source to issue superform positions (failed withdraws and successful deposits)
        return abi.encode(
            AMBMessage(
                DataLib.packTxInfo(
                    uint8(txType), uint8(returnType_), 0, _getStateRegistryId(address(this)), srcSender_, CHAIN_ID
                ),
                abi.encode(ReturnSingleData(payloadId_, superformId_, amount_))
            )
        );
    }

    /// @dev calls the function to update the proof during payload update
    function _updatePayload(
        uint256 payloadId_,
        bytes32 prevPayloadProof,
        bytes memory newPayloadBody,
        uint256 prevPayloadHeader,
        PayloadState finalState
    )
        internal
    {
        bytes32 newPayloadProof = AMBMessage(prevPayloadHeader, newPayloadBody).computeProof();
        if (newPayloadProof != prevPayloadProof) {
            messageQuorum[newPayloadProof] = messageQuorum[prevPayloadProof];

            delete messageQuorum[prevPayloadProof];
        }

        payloadBody[payloadId_] = newPayloadBody;
        payloadTracking[payloadId_] = finalState;

        emit PayloadUpdated(payloadId_);
    }
}

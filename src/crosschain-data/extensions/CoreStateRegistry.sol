// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { BaseStateRegistry } from "../BaseStateRegistry.sol";
import { ISuperRBAC } from "../../interfaces/ISuperRBAC.sol";
import { IStateSyncer } from "../../interfaces/IStateSyncer.sol";
import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";
import { IQuorumManager } from "../../interfaces/IQuorumManager.sol";
import { IPaymentHelper } from "../../interfaces/IPaymentHelper.sol";
import { IBaseForm } from "../../interfaces/IBaseForm.sol";
import { IDstSwapper } from "../../interfaces/IDstSwapper.sol";
import { DataLib } from "../../libraries/DataLib.sol";
import { ProofLib } from "../../libraries/ProofLib.sol";
import { ArrayCastLib } from "../../libraries/ArrayCastLib.sol";
import { IERC4626Form } from "../../forms/interfaces/IERC4626Form.sol";
import { PayloadUpdaterLib } from "../../libraries/PayloadUpdaterLib.sol";
import { Error } from "../../utils/Error.sol";
import "../../interfaces/ICoreStateRegistry.sol";

/// @title CoreStateRegistry
/// @author Zeropoint Labs
/// @dev enables communication between Superform Core Contracts deployed on all supported networks
contract CoreStateRegistry is BaseStateRegistry, ICoreStateRegistry {
    using SafeERC20 for IERC20;
    using DataLib for uint256;
    using ProofLib for AMBMessage;

    /*///////////////////////////////////////////////////////////////
                    Constants
    //////////////////////////////////////////////////////////////*/
    bytes32 constant SUPER_RBAC = keccak256("SUPER_RBAC");
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev just stores the superformIds that failed in a specific payload id
    mapping(uint256 payloadId => FailedDeposit) internal failedDeposits;

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAllowedCaller(bytes32 role_) {
        if (!_hasRole(role_, msg.sender)) revert Error.NOT_PREVILAGED_CALLER(role_);
        _;
    }

    modifier isValidPayloadId(uint256 payloadId_) {
        if (payloadId_ > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }
        _;
    }

    modifier onlySender() override {
        if (superRegistry.getSuperformRouterId(msg.sender) == 0) revert Error.NOT_SUPER_ROUTER();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(ISuperRegistry superRegistry_) BaseStateRegistry(superRegistry_) { }

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICoreStateRegistry
    function updateDepositPayload(
        uint256 payloadId_,
        uint256[] calldata finalAmounts_
    )
        external
        virtual
        override
        onlyAllowedCaller(keccak256("CORE_STATE_REGISTRY_UPDATER_ROLE"))
        isValidPayloadId(payloadId_)
    {
        (uint256 prevPayloadHeader, bytes memory prevPayloadBody,, bytes32 prevPayloadProof,,, uint8 isMulti,,,) =
            _retrievePayloadHeaderAndBody(payloadId_);

        PayloadUpdaterLib.validateDepositPayloadUpdate(prevPayloadHeader, payloadTracking[payloadId_], isMulti);

        PayloadState finalState;
        if (isMulti != 0) {
            (prevPayloadBody, finalState) = _updateMultiVaultDepositPayload(payloadId_, prevPayloadBody, finalAmounts_);
        } else {
            (prevPayloadBody, finalState) =
                _updateSingleVaultDepositPayload(payloadId_, prevPayloadBody, finalAmounts_[0]);
        }

        payloadBody[payloadId_] = prevPayloadBody;

        /// @dev updates the payload proof
        _handlePayloadProofUpdate(prevPayloadProof, prevPayloadBody, prevPayloadHeader);

        payloadTracking[payloadId_] = finalState;
        emit PayloadUpdated(payloadId_);

        /// @dev if payload is processed at this stage then it is failing
        if (finalState == PayloadState.PROCESSED) {
            emit PayloadProcessed(payloadId_);
            emit FailedXChainDeposits(payloadId_);
        }
    }

    /// @inheritdoc ICoreStateRegistry
    function updateWithdrawPayload(
        uint256 payloadId_,
        bytes[] calldata txData_
    )
        external
        virtual
        override
        onlyAllowedCaller(keccak256("CORE_STATE_REGISTRY_UPDATER_ROLE"))
        isValidPayloadId(payloadId_)
    {
        (
            uint256 prevPayloadHeader,
            bytes memory prevPayloadBody,
            ,
            bytes32 prevPayloadProof,
            ,
            ,
            uint8 isMulti,
            ,
            address srcSender,
            uint64 srcChainId
        ) = _retrievePayloadHeaderAndBody(payloadId_);

        /// @dev validate payload update
        PayloadUpdaterLib.validateWithdrawPayloadUpdate(prevPayloadHeader, payloadTracking[payloadId_], isMulti);

        prevPayloadBody = _updateWithdrawPayload(prevPayloadBody, srcSender, srcChainId, txData_, isMulti);
        payloadBody[payloadId_] = prevPayloadBody;

        /// @dev updates the payload proof
        _handlePayloadProofUpdate(prevPayloadProof, prevPayloadBody, prevPayloadHeader);

        /// @dev define the payload status as updated
        payloadTracking[payloadId_] = PayloadState.UPDATED;

        emit PayloadUpdated(payloadId_);
    }

    /// @inheritdoc BaseStateRegistry
    function processPayload(uint256 payloadId_)
        external
        payable
        virtual
        override
        onlyAllowedCaller(keccak256("CORE_STATE_REGISTRY_PROCESSOR_ROLE"))
        isValidPayloadId(payloadId_)
    {
        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.PAYLOAD_ALREADY_PROCESSED();
        }

        PayloadState initialState = payloadTracking[payloadId_];
        /// @dev sets status as processed to prevent re-entrancy
        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        (
            uint256 payloadHeader_,
            bytes memory payloadBody_,
            AMBMessage memory message_,
            ,
            uint8 txType,
            uint8 callbackType,
            uint8 isMulti,
            ,
            address srcSender,
            uint64 srcChainId
        ) = _retrievePayloadHeaderAndBody(payloadId_);

        /// @dev mint superPositions for successful deposits or remint for failed withdraws
        if (callbackType == uint256(CallbackType.RETURN) || callbackType == uint256(CallbackType.FAIL)) {
            isMulti == 1
                ? IStateSyncer(_getStateSyncer(abi.decode(payloadBody_, (ReturnMultiData)).superformRouterId))
                    .stateMultiSync(message_)
                : IStateSyncer(_getStateSyncer(abi.decode(payloadBody_, (ReturnSingleData)).superformRouterId)).stateSync(
                    message_
                );
        } else if (callbackType == uint8(CallbackType.INIT)) {
            /// @dev for initial payload processing
            bytes memory returnMessage;

            if (txType == uint8(TransactionType.WITHDRAW)) {
                returnMessage = isMulti == 1
                    ? _processMultiWithdrawal(payloadId_, payloadBody_, srcSender, srcChainId)
                    : _processSingleWithdrawal(payloadId_, payloadBody_, srcSender, srcChainId);
            }

            if (txType == uint8(TransactionType.DEPOSIT)) {
                if (initialState != PayloadState.UPDATED) {
                    revert Error.PAYLOAD_NOT_UPDATED();
                }

                returnMessage = isMulti == 1
                    ? _processMultiDeposit(payloadId_, payloadBody_, srcSender, srcChainId)
                    : _processSingleDeposit(payloadId_, payloadBody_, srcSender, srcChainId);
            }

            _processAcknowledgement(payloadId_, message_.computeProof(), srcChainId, returnMessage);
        }

        emit PayloadProcessed(payloadId_);
    }

    /// @inheritdoc ICoreStateRegistry
    function proposeRescueFailedDeposits(
        uint256 payloadId_,
        uint256[] calldata proposedAmounts_
    )
        external
        override
        onlyAllowedCaller(keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE"))
        isValidPayloadId(payloadId_)
    {
        FailedDeposit storage failedDeposits_ = failedDeposits[payloadId_];

        if (
            failedDeposits_.superformIds.length == 0 || proposedAmounts_.length == 0
                || failedDeposits_.superformIds.length != proposedAmounts_.length
        ) {
            revert Error.INVALID_RESCUE_DATA();
        }

        if (failedDeposits_.lastProposedTimestamp != 0) {
            revert Error.RESCUE_ALREADY_PROPOSED();
        }

        /// @dev note: should set this value to dstSwapper.failedSwap().amount for interim rescue
        failedDeposits[payloadId_].amounts = proposedAmounts_;
        failedDeposits[payloadId_].lastProposedTimestamp = block.timestamp;

        (,, uint8 multi,,,) = DataLib.decodeTxInfo(payloadHeader[payloadId_]);

        if (multi == 1) {
            failedDeposits[payloadId_].refundAddress =
                abi.decode(payloadBody[payloadId_], (InitMultiVaultData)).dstRefundAddress;
        } else {
            failedDeposits[payloadId_].refundAddress =
                abi.decode(payloadBody[payloadId_], (InitSingleVaultData)).dstRefundAddress;
        }

        emit RescueProposed(payloadId_, failedDeposits_.superformIds, proposedAmounts_, block.timestamp);
    }

    /// @inheritdoc ICoreStateRegistry
    function disputeRescueFailedDeposits(uint256 payloadId_) external override isValidPayloadId(payloadId_) {
        FailedDeposit storage failedDeposits_ = failedDeposits[payloadId_];

        /// @dev the msg sender should be the refund address (or) the disputer
        if (
            !(
                msg.sender == failedDeposits_.refundAddress
                    || _hasRole(keccak256("CORE_STATE_REGISTRY_DISPUTER_ROLE"), msg.sender)
            )
        ) {
            revert Error.INVALID_DISUPTER();
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
        uint256 lastProposedTimestamp = failedDeposits[payloadId_].lastProposedTimestamp;

        /// @dev the timelock is elapsed
        if (lastProposedTimestamp == 0 || block.timestamp < lastProposedTimestamp + _getDelay()) {
            revert Error.RESCUE_LOCKED();
        }

        uint256[] memory amounts = failedDeposits[payloadId_].amounts;
        address[] memory settlementToken = failedDeposits[payloadId_].settlementToken;
        bool[] memory rescueInterim = failedDeposits[payloadId_].settleFromDstSwapper;
        address refundAddress = failedDeposits[payloadId_].refundAddress;

        /// @dev deleted to prevent re-entrancy
        delete failedDeposits[payloadId_];

        for (uint256 i; i < amounts.length;) {
            /// @dev refunds the amount to user specified refund address
            if (rescueInterim[i]) {
                IDstSwapper dstSwapper = IDstSwapper(_getAddress(keccak256("DST_SWAPPER")));
                dstSwapper.processFailedTx(refundAddress, settlementToken[i], amounts[i]);
            } else {
                IERC20(settlementToken[i]).safeTransfer(refundAddress, amounts[i]);
            }
            unchecked {
                ++i;
            }
        }

        emit RescueFinalized(payloadId_);
    }

    /// @inheritdoc ICoreStateRegistry
    function getFailedDeposits(uint256 payloadId_)
        external
        view
        override
        returns (uint256[] memory superformIds, uint256[] memory amounts)
    {
        superformIds = failedDeposits[payloadId_].superformIds;
        amounts = failedDeposits[payloadId_].amounts;
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev returns if an address has a specific role
    function _hasRole(bytes32 id_, address addressToCheck_) internal view returns (bool) {
        return ISuperRBAC(_getSuperRBAC()).hasRole(id_, addressToCheck_);
    }

    /// @dev returns the state syncer address for id
    function _getStateSyncer(uint8 id_) internal view returns (address stateSyncer) {
        return superRegistry.getStateSyncer(id_);
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
        return superRegistry.delay();
    }

    /// @dev returns the superRBAC address
    function _getSuperRBAC() internal view returns (address) {
        return _getAddress(SUPER_RBAC);
    }

    /// @dev returns the required quorum for the src chain id from super registry
    /// @param chainId_ is the src chain id
    /// @return the quorum configured for the chain id
    function _getRequiredMessagingQuorum(uint64 chainId_) internal view returns (uint256) {
        return IQuorumManager(address(superRegistry)).getRequiredMessagingQuorum(chainId_);
    }

    /// @dev returns the required quorum for the src chain id from super registry
    /// @param bridgeId_ is the bridge id
    /// @return validator is the address of the validator contract
    function _getBridgeValidator(uint8 bridgeId_) internal view returns (IBridgeValidator validator) {
        return IBridgeValidator(superRegistry.getBridgeValidator(bridgeId_));
    }

    /// @dev retrieves information associated with the payload and validates quorum
    /// @param payloadId_ is the payload id
    /// @return payloadHeader_ is the payload header
    /// @return payloadBody_ is the payload body
    /// @return message is the AMBMessage struct
    /// @return payloadProof is the payload proof
    /// @return txType is the transaction type
    /// @return callbackType is the callback type
    /// @return isMulti is the multi flag
    /// @return registryId is the registry id
    /// @return srcSender is the source sender
    /// @return srcChainId is the source chain id
    function _retrievePayloadHeaderAndBody(uint256 payloadId_)
        internal
        view
        returns (
            uint256 payloadHeader_,
            bytes memory payloadBody_,
            AMBMessage memory message,
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
        message = AMBMessage(payloadHeader_, payloadBody_);
        payloadProof = message.computeProof();
        (txType, callbackType, isMulti, registryId, srcSender, srcChainId) = payloadHeader_.decodeTxInfo();

        if (messageQuorum[payloadProof] < _getRequiredMessagingQuorum(srcChainId)) {
            revert Error.QUORUM_NOT_REACHED();
        }
    }

    /// @dev helper function to update multi vault deposit payload
    function _updateMultiVaultDepositPayload(
        uint256 payloadId_,
        bytes memory prevPayloadBody_,
        uint256[] calldata finalAmounts_
    )
        internal
        returns (bytes memory newPayloadBody_, PayloadState finalState_)
    {
        InitMultiVaultData memory multiVaultData = abi.decode(prevPayloadBody_, (InitMultiVaultData));
        IDstSwapper dstSwapper = IDstSwapper(_getAddress(keccak256("DST_SWAPPER")));

        /// @dev compare number of vaults to update with provided finalAmounts length
        if (multiVaultData.amounts.length != finalAmounts_.length) {
            revert Error.DIFFERENT_PAYLOAD_UPDATE_AMOUNTS_LENGTH();
        }

        uint256 validLen;
        uint256 arrLen = finalAmounts_.length;

        for (uint256 i; i < arrLen;) {
            if (finalAmounts_[i] == 0) {
                revert Error.ZERO_AMOUNT();
            }

            /// @dev observe not consuming the second return value
            (multiVaultData.amounts[i],, validLen) = _updateAmountOrQueueFailedDeposit(
                dstSwapper,
                multiVaultData.hasDstSwaps[i],
                payloadId_,
                i,
                finalAmounts_[i],
                multiVaultData.superformIds[i],
                multiVaultData.amounts[i],
                multiVaultData.maxSlippage[i],
                finalState_,
                validLen
            );

            unchecked {
                ++i;
            }
        }

        if (validLen > 0) {
            uint256[] memory finalSuperformIds = new uint256[](validLen);
            uint256[] memory finalAmounts = new uint256[](validLen);
            uint256[] memory maxSlippage = new uint256[](validLen);
            bool[] memory hasDstSwaps = new bool[](validLen);

            uint256 currLen;
            for (uint256 i; i < arrLen;) {
                if (multiVaultData.amounts[i] != 0) {
                    finalSuperformIds[currLen] = multiVaultData.superformIds[i];
                    finalAmounts[currLen] = multiVaultData.amounts[i];
                    maxSlippage[currLen] = multiVaultData.maxSlippage[i];
                    hasDstSwaps[currLen] = multiVaultData.hasDstSwaps[i];
                    ++currLen;
                }
                unchecked {
                    ++i;
                }
            }

            multiVaultData.amounts = finalAmounts;
            multiVaultData.superformIds = finalSuperformIds;
            multiVaultData.maxSlippage = maxSlippage;
            multiVaultData.hasDstSwaps = hasDstSwaps;
            finalState_ = PayloadState.UPDATED;
        } else {
            finalState_ = PayloadState.PROCESSED;
        }

        newPayloadBody_ = abi.encode(multiVaultData);
    }

    /// @dev helper function to update single vault deposit payload
    function _updateSingleVaultDepositPayload(
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
        (singleVaultData.amount, finalState_,) = _updateAmountOrQueueFailedDeposit(
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

    function _updateAmountOrQueueFailedDeposit(
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
                (address interimToken, uint256 amount) = dstSwapper.getFailedSwap(payloadId_, index_);

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
        if (!failedSwapQueued) {
            if (PayloadUpdaterLib.validateSlippage(finalAmount_, amount_, maxSlippage_)) {
                /// @dev sets amount to zero and will mark the payload as UPDATED
                amount_ = finalAmount_;
                finalState_ = PayloadState.UPDATED;
                ++validLen_;
            } else {
                (address superform,,) = superformId_.getSuperform();
                failedDeposits[payloadId_].superformIds.push(superformId_);
                failedDeposits[payloadId_].settlementToken.push(IBaseForm(superform).getVaultAsset());
                failedDeposits[payloadId_].settleFromDstSwapper.push(false);

                /// @dev sets amount to zero and will mark the payload as PROCESSED
                amount_ = 0;
                finalState_ = PayloadState.PROCESSED;
            }
        }

        return (amount_, finalState_, validLen_);
    }

    /// @dev helper function to update multi vault withdraw payload
    function _updateWithdrawPayload(
        bytes memory prevPayloadBody_,
        address srcSender_,
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

        multiVaultData = _validateAndUpdateTxData(txData_, multiVaultData, srcSender_, srcChainId_, CHAIN_ID);

        if (multi == 0) {
            singleVaultData.liqData.txData = txData_[0];
            return abi.encode(singleVaultData);
        }

        return abi.encode(multiVaultData);
    }

    /// @dev validates the incoming update data
    function _validateAndUpdateTxData(
        bytes[] calldata txData_,
        InitMultiVaultData memory multiVaultData_,
        address srcSender_,
        uint64 srcChainId_,
        uint64 dstChainId_
    )
        internal
        view
        returns (InitMultiVaultData memory)
    {
        for (uint256 i; i < multiVaultData_.liqData.length;) {
            if (txData_[i].length != 0 && multiVaultData_.liqData[i].txData.length == 0) {
                (address superform,,) = multiVaultData_.superformIds[i].getSuperform();

                if (IBaseForm(superform).getStateRegistryId() == _getStateRegistryId(address(this))) {
                    PayloadUpdaterLib.validateLiqReq(multiVaultData_.liqData[i]);

                    IBridgeValidator bridgeValidator = _getBridgeValidator(multiVaultData_.liqData[i].bridgeId);

                    bridgeValidator.validateTxData(
                        IBridgeValidator.ValidateTxDataArgs(
                            txData_[i],
                            dstChainId_,
                            srcChainId_,
                            multiVaultData_.liqData[i].liqDstChainId,
                            false,
                            superform,
                            srcSender_,
                            multiVaultData_.liqData[i].token
                        )
                    );

                    uint256 finalAmount = bridgeValidator.decodeAmountIn(txData_[i], false);
                    PayloadUpdaterLib.strictValidateSlippage(
                        finalAmount,
                        IBaseForm(superform).previewRedeemFrom(multiVaultData_.amounts[i]),
                        multiVaultData_.maxSlippage[i]
                    );

                    multiVaultData_.liqData[i].txData = txData_[i];
                }
            }

            unchecked {
                ++i;
            }
        }

        return multiVaultData_;
    }

    function _processMultiWithdrawal(
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

        for (uint256 i; i < len;) {
            /// @dev it is critical to validate that the action is being performed to the correct chainId coming from
            /// the superform
            DataLib.validateSuperformChainId(multiVaultData.superformIds[i], CHAIN_ID);

            /// @dev Store destination payloadId_ & index in extraFormData (tbd: 1-step flow doesnt need this)
            (address superform_,,) = multiVaultData.superformIds[i].getSuperform();

            try IBaseForm(superform_).xChainWithdrawFromVault(
                InitSingleVaultData({
                    superformRouterId: multiVaultData.superformRouterId,
                    payloadId: multiVaultData.payloadId,
                    superformId: multiVaultData.superformIds[i],
                    amount: multiVaultData.amounts[i],
                    maxSlippage: multiVaultData.maxSlippage[i],
                    hasDstSwap: false,
                    liqData: multiVaultData.liqData[i],
                    dstRefundAddress: multiVaultData.dstRefundAddress,
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
                if (!errors) errors = true;
            }

            unchecked {
                ++i;
            }
        }

        /// @dev if at least one error happens, the shares will be re-minted for the affected superformIds
        if (errors) {
            return _constructMultiReturnData(
                srcSender_,
                multiVaultData.payloadId,
                multiVaultData.superformRouterId,
                TransactionType.WITHDRAW,
                CallbackType.FAIL,
                multiVaultData.superformIds,
                multiVaultData.amounts
            );
        }

        return "";
    }

    function _processMultiDeposit(
        uint256 payloadId_,
        bytes memory payload_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        returns (bytes memory)
    {
        InitMultiVaultData memory multiVaultData = abi.decode(payload_, (InitMultiVaultData));

        (address[] memory superforms,,) = DataLib.getSuperforms(multiVaultData.superformIds);

        IERC20 underlying;
        uint256 numberOfVaults = multiVaultData.superformIds.length;
        uint256[] memory dstAmounts = new uint256[](numberOfVaults);

        bool fulfilment;
        bool errors;

        for (uint256 i; i < numberOfVaults;) {
            /// @dev if updating the deposit payload fails because of slippage, multiVaultData.amounts[i] is set to 0
            /// @dev this means that this amount was already added to the failedDeposits state variable and should not
            /// be re-added (or processed here)
            if (multiVaultData.amounts[i] > 0) {
                underlying = IERC20(IBaseForm(superforms[i]).getVaultAsset());

                if (underlying.balanceOf(address(this)) >= multiVaultData.amounts[i]) {
                    underlying.safeIncreaseAllowance(superforms[i], multiVaultData.amounts[i]);
                    LiqRequest memory emptyRequest;

                    /// @dev it is critical to validate that the action is being performed to the correct chainId coming
                    /// from the superform
                    DataLib.validateSuperformChainId(multiVaultData.superformIds[i], CHAIN_ID);

                    /// @notice dstAmounts has same size of the number of vaults. If a given deposit fails, we are
                    /// minting 0
                    /// SPs back on source (slight gas waste)
                    try IBaseForm(superforms[i]).xChainDepositIntoVault(
                        InitSingleVaultData({
                            superformRouterId: multiVaultData.superformRouterId,
                            payloadId: multiVaultData.payloadId,
                            superformId: multiVaultData.superformIds[i],
                            amount: multiVaultData.amounts[i],
                            maxSlippage: multiVaultData.maxSlippage[i],
                            liqData: emptyRequest,
                            hasDstSwap: false,
                            dstRefundAddress: multiVaultData.dstRefundAddress,
                            extraFormData: multiVaultData.extraFormData
                        }),
                        srcSender_,
                        srcChainId_
                    ) returns (uint256 dstAmount) {
                        if (dstAmount > 0) {
                            if (!fulfilment) fulfilment = true;
                            /// @dev marks the indexes that require a callback mint of shares (successful)
                            dstAmounts[i] = dstAmount;
                        }
                    } catch {
                        /// @dev cleaning unused approval
                        underlying.safeDecreaseAllowance(superforms[i], multiVaultData.amounts[i]);

                        /// @dev if any deposit fails, we mark errors as true and add it to failedDepositSuperformIds
                        /// mapping for future rescuing
                        if (!errors) errors = true;

                        failedDeposits[payloadId_].superformIds.push(multiVaultData.superformIds[i]);
                        failedDeposits[payloadId_].settlementToken.push(IBaseForm(superforms[i]).getVaultAsset());
                        failedDeposits[payloadId_].settleFromDstSwapper.push(false);
                    }
                } else {
                    revert Error.BRIDGE_TOKENS_PENDING();
                }
                unchecked {
                    ++i;
                }
            }
        }

        /// @dev issue superPositions if at least one vault deposit passed
        if (fulfilment) {
            return _constructMultiReturnData(
                srcSender_,
                multiVaultData.payloadId,
                multiVaultData.superformRouterId,
                TransactionType.DEPOSIT,
                CallbackType.RETURN,
                multiVaultData.superformIds,
                dstAmounts
            );
        }

        if (errors) {
            emit FailedXChainDeposits(payloadId_);
        }

        return "";
    }

    function _processSingleWithdrawal(
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

        DataLib.validateSuperformChainId(singleVaultData.superformId, CHAIN_ID);

        (address superform_,,) = singleVaultData.superformId.getSuperform();
        /// @dev Withdraw from superform
        try IBaseForm(superform_).xChainWithdrawFromVault(singleVaultData, srcSender_, srcChainId_) {
            // Handle the case when the external call succeeds
        } catch {
            // Handle the case when the external call reverts for whatever reason
            /// https://solidity-by-example.org/try-catch/
            return _constructSingleReturnData(
                srcSender_,
                singleVaultData.payloadId,
                singleVaultData.superformRouterId,
                TransactionType.WITHDRAW,
                CallbackType.FAIL,
                singleVaultData.superformId,
                singleVaultData.amount
            );
        }

        return "";
    }

    function _processSingleDeposit(
        uint256 payloadId_,
        bytes memory payload_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        returns (bytes memory)
    {
        InitSingleVaultData memory singleVaultData = abi.decode(payload_, (InitSingleVaultData));

        DataLib.validateSuperformChainId(singleVaultData.superformId, CHAIN_ID);

        (address superform_,,) = singleVaultData.superformId.getSuperform();

        IERC20 underlying = IERC20(IBaseForm(superform_).getVaultAsset());

        if (underlying.balanceOf(address(this)) >= singleVaultData.amount) {
            underlying.safeIncreaseAllowance(superform_, singleVaultData.amount);

            /// @dev deposit to superform
            try IBaseForm(superform_).xChainDepositIntoVault(singleVaultData, srcSender_, srcChainId_) returns (
                uint256 dstAmount
            ) {
                if (dstAmount > 0) {
                    return _constructSingleReturnData(
                        srcSender_,
                        singleVaultData.payloadId,
                        singleVaultData.superformRouterId,
                        TransactionType.DEPOSIT,
                        CallbackType.RETURN,
                        singleVaultData.superformId,
                        dstAmount
                    );
                }
            } catch {
                /// @dev cleaning unused approval
                underlying.safeDecreaseAllowance(superform_, singleVaultData.amount);

                /// @dev if any deposit fails, add it to failedDepositSuperformIds mapping for future rescuing
                failedDeposits[payloadId_].superformIds.push(singleVaultData.superformId);
                failedDeposits[payloadId_].settlementToken.push(IBaseForm(superform_).getVaultAsset());
                failedDeposits[payloadId_].settleFromDstSwapper.push(false);

                emit FailedXChainDeposits(payloadId_);
            }
        } else {
            revert Error.BRIDGE_TOKENS_PENDING();
        }

        return "";
    }

    function _processAcknowledgement(
        uint256 payloadId_,
        bytes32 proof_,
        uint64 srcChainId_,
        bytes memory returnMessage_
    )
        internal
    {
        uint8[] memory proofIds = proofAMB[proof_];

        /// @dev if deposits succeeded or some withdrawal failed, dispatch a callback
        if (returnMessage_.length > 0) {
            uint8[] memory ambIds = new uint8[](proofIds.length + 1);

            ambIds[0] = msgAMB[payloadId_];

            uint256 len = proofIds.length;
            for (uint256 i; i < len;) {
                ambIds[i + 1] = proofIds[i];

                unchecked {
                    ++i;
                }
            }

            _dispatchAcknowledgement(srcChainId_, ambIds, returnMessage_);
        }
    }

    /// @notice depositSync and withdrawSync internal method for sending message back to the source chain
    function _constructMultiReturnData(
        address srcSender_,
        uint256 payloadId_,
        uint8 superformRouterId_,
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
                abi.encode(ReturnMultiData(superformRouterId_, payloadId_, superformIds_, amounts_))
            )
        );
    }

    /// @notice depositSync and withdrawSync internal method for sending message back to the source chain
    function _constructSingleReturnData(
        address srcSender_,
        uint256 payloadId_,
        uint8 superformRouterId_,
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
                abi.encode(ReturnSingleData(superformRouterId_, payloadId_, superformId_, amount_))
            )
        );
    }

    /// @dev calls the appropriate dispatch function according to the ackExtraData the keeper fed initially
    function _dispatchAcknowledgement(uint64 dstChainId_, uint8[] memory ambIds_, bytes memory message_) internal {
        (, bytes memory extraData) =
            IPaymentHelper(_getAddress(keccak256("PAYMENT_HELPER"))).calculateAMBData(dstChainId_, ambIds_, message_);

        AMBExtraData memory d = abi.decode(extraData, (AMBExtraData));

        _dispatchPayload(msg.sender, ambIds_[0], dstChainId_, d.gasPerAMB[0], message_, d.extraDataPerAMB[0]);

        if (ambIds_.length > 1) {
            _dispatchProof(msg.sender, ambIds_, dstChainId_, d.gasPerAMB, message_, d.extraDataPerAMB);
        }
    }

    /// @dev calls the function to update the proof during payload update
    function _handlePayloadProofUpdate(
        bytes32 prevPayloadProof,
        bytes memory newPayloadBody,
        uint256 prevPayloadHeader
    )
        internal
    {
        bytes32 newPayloadProof = AMBMessage(prevPayloadHeader, newPayloadBody).computeProof();
        if (newPayloadProof != prevPayloadProof) {
            messageQuorum[newPayloadProof] = messageQuorum[prevPayloadProof];
            proofAMB[newPayloadProof] = proofAMB[prevPayloadProof];

            delete messageQuorum[prevPayloadProof];
            delete proofAMB[prevPayloadProof];
        }
    }
}

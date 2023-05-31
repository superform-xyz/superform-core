// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {BaseStateRegistry} from "./BaseStateRegistry.sol";
import {QuorumManager} from "./utils/QuorumManager.sol";
import {LiquidityHandler} from "../crosschain-liquidity/LiquidityHandler.sol";
import {ISuperPositions} from "../interfaces/ISuperPositions.sol";
import {ICoreStateRegistry} from "../interfaces/ICoreStateRegistry.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {IBaseForm} from "../interfaces/IBaseForm.sol";
import {IBridgeValidator} from "../interfaces/IBridgeValidator.sol";
import {PayloadState, TransactionType, CallbackType, AMBMessage, InitSingleVaultData, InitMultiVaultData, AckAMBData, AMBExtraData, ReturnMultiData, ReturnSingleData} from "../types/DataTypes.sol";
import {LiqRequest} from "../types/DataTypes.sol";
import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {Error} from "../utils/Error.sol";
import "../utils/DataPacking.sol";

/// @title CoreStateRegistry
/// @author Zeropoint Labs
/// @dev enables communication between SuperForm Core Contracts deployed on all supported networks
contract CoreStateRegistry is LiquidityHandler, BaseStateRegistry, QuorumManager, ICoreStateRegistry {
    /// FIXME: are we using safe transfers?
    using SafeTransferLib for ERC20;
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    mapping(uint256 payloadId => bytes failedDepositRequests) internal failedDepositPayloads;

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlySender() override {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasCoreContractsRole(msg.sender)) revert Error.NOT_CORE_CONTRACTS();
        _;
    }

    modifier isValidPayloadId(uint256 payloadId_) {
        if (payloadId_ > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    ///@dev set up admin during deployment.
    constructor(ISuperRegistry superRegistry_, uint8 registryType_) BaseStateRegistry(superRegistry_, registryType_) {}

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc QuorumManager
    function setRequiredMessagingQuorum(uint64 srcChainId_, uint256 quorum_) external override onlyProtocolAdmin {
        requiredQuorum[srcChainId_] = quorum_;
    }

    /// @inheritdoc ICoreStateRegistry
    function updateMultiVaultPayload(
        uint256 payloadId_,
        uint256[] calldata finalAmounts_
    ) external virtual override onlyUpdater isValidPayloadId(payloadId_) {
        AMBMessage memory payloadInfo = abi.decode(payload[payloadId_], (AMBMessage));
        InitMultiVaultData memory multiVaultData = abi.decode(payloadInfo.params, (InitMultiVaultData));

        _validatePayloadUpdate(payloadInfo.txInfo, payloadId_, 1);

        uint256 l1 = multiVaultData.amounts.length;
        uint256 l2 = finalAmounts_.length;

        if (l1 != l2) {
            revert Error.DIFFERENT_PAYLOAD_UPDATE_AMOUNTS_LENGTH();
        }

        for (uint256 i = 0; i < l1; i++) {
            _validateSlippage(finalAmounts_[i], multiVaultData.amounts[i], multiVaultData.maxSlippage[i]);
        }

        multiVaultData.amounts = finalAmounts_;

        payloadInfo.params = abi.encode(multiVaultData);

        payload[payloadId_] = abi.encode(payloadInfo);
        payloadTracking[payloadId_] = PayloadState.UPDATED;

        emit PayloadUpdated(payloadId_);
    }

    /// @inheritdoc ICoreStateRegistry
    function updateSingleVaultPayload(
        uint256 payloadId_,
        uint256 finalAmount_
    ) external virtual override onlyUpdater isValidPayloadId(payloadId_) {
        AMBMessage memory payloadInfo = abi.decode(payload[payloadId_], (AMBMessage));
        InitSingleVaultData memory singleVaultData = abi.decode(payloadInfo.params, (InitSingleVaultData));

        _validatePayloadUpdate(payloadInfo.txInfo, payloadId_, 0);
        _validateSlippage(finalAmount_, singleVaultData.amount, singleVaultData.maxSlippage);

        singleVaultData.amount = finalAmount_;
        payloadInfo.params = abi.encode(singleVaultData);

        payload[payloadId_] = abi.encode(payloadInfo);

        payloadTracking[payloadId_] = PayloadState.UPDATED;
        emit PayloadUpdated(payloadId_);
    }

    /// @inheritdoc BaseStateRegistry
    function processPayload(
        uint256 payloadId_,
        bytes memory ackExtraData_
    ) external payable virtual override onlyProcessor isValidPayloadId(payloadId_) {
        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.INVALID_PAYLOAD_STATE();
        }

        bytes memory _payload = payload[payloadId_];
        AMBMessage memory payloadInfo = abi.decode(_payload, (AMBMessage));

        (uint8 txType, uint8 callbackType, uint8 multi, , address srcSender, uint64 srcChainId) = _decodeTxInfo(
            payloadInfo.txInfo
        );
        bytes memory returnMessage;

        if (callbackType == uint256(CallbackType.RETURN)) {
            multi == 1
                ? ISuperPositions(superRegistry.superPositions()).stateMultiSync(payloadInfo)
                : ISuperPositions(superRegistry.superPositions()).stateSync(payloadInfo);
        }

        if (callbackType == uint8(CallbackType.INIT)) {
            if (txType == uint8(TransactionType.WITHDRAW)) {
                returnMessage = multi == 1
                    ? _processMultiWithdrawal(payloadId_, payloadInfo.params, srcSender, srcChainId)
                    : _processSingleWithdrawal(payloadId_, payloadInfo.params, srcSender, srcChainId);
            }

            if (txType == uint8(TransactionType.DEPOSIT)) {
                returnMessage = multi == 1
                    ? _processMultiDeposit(payloadId_, payloadInfo.params, srcSender, srcChainId)
                    : _processSingleDeposit(payloadId_, payloadInfo.params, srcSender, srcChainId);
            }
        }

        /// @dev validates quorum
        bytes memory _proof = abi.encode(keccak256(_payload));
        if (messageQuorum[_proof] < getRequiredMessagingQuorum(srcChainId)) {
            revert Error.QUORUM_NOT_REACHED();
        }

        if (returnMessage.length > 0) {
            _dispatchAcknowledgement(srcChainId, returnMessage, ackExtraData_);
        }

        /// @dev sets status as processed
        /// @dev check for re-entrancy & relocate if needed
        payloadTracking[payloadId_] = PayloadState.PROCESSED;
    }

    /// @inheritdoc BaseStateRegistry
    function revertPayload(
        uint256 payloadId_,
        uint256,
        bytes memory
    ) external payable virtual override onlyProcessor isValidPayloadId(payloadId_) {
        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.INVALID_PAYLOAD_STATE();
        }

        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        AMBMessage memory payloadInfo = abi.decode(payload[payloadId_], (AMBMessage));

        (, , uint8 multi, , , ) = _decodeTxInfo(payloadInfo.txInfo);

        if (multi == 1) {
            InitMultiVaultData memory multiVaultData = abi.decode(payloadInfo.params, (InitMultiVaultData));

            if (superRegistry.chainId() != _getDestinationChain(multiVaultData.superFormIds[0]))
                revert Error.INVALID_PAYLOAD_STATE();
        } else if (multi == 0) {
            InitSingleVaultData memory singleVaultData = abi.decode(payloadInfo.params, (InitSingleVaultData));

            if (superRegistry.chainId() != _getDestinationChain(singleVaultData.superFormId))
                revert Error.INVALID_PAYLOAD_STATE();
        }

        /// FIXME: Send `data` back to source based on AmbID to revert Error.the state.
        /// FIXME: chain_ids conflict should be addresses here.
        // amb[ambId_].dispatchPayload(formData.dstChainId_, message_, extraData_);
    }

    struct RescueFaileDepositsLocalVars {
        uint8 multi;
        bool rescued;
        uint64 dstChainId;
        uint64 srcChainId;
        address srcSender;
        address superForm;
        bytes failedData;
        bytes payload;
        uint256[] failedSuperFormIds;
        AMBMessage payloadInfo;
        InitMultiVaultData multiVaultData;
    }

    /// @inheritdoc ICoreStateRegistry
    function rescueFailedMultiDeposits(
        uint256 payloadId_,
        LiqRequest[] memory liqDatas_
    ) external payable override onlyProcessor {
        RescueFaileDepositsLocalVars memory v;
        (v.multi, v.rescued, v.failedData, v.srcSender, v.srcChainId) = abi.decode(
            failedDepositPayloads[payloadId_],
            (uint8, bool, bytes, address, uint64)
        );
        if (v.multi == 0) revert Error.NOT_MULTI_FAILURE();
        if (v.rescued) revert Error.ALREADY_RESCUED();

        failedDepositPayloads[payloadId_] = abi.encode(v.multi, true, v.failedData, v.srcSender, v.srcChainId);

        v.failedSuperFormIds = abi.decode(v.failedData, (uint256[]));

        v.payload = payload[payloadId_];
        v.payloadInfo = abi.decode(v.payload, (AMBMessage));

        v.multiVaultData = abi.decode(v.payloadInfo.params, (InitMultiVaultData));

        if (
            !((liqDatas_.length == v.failedSuperFormIds.length) &&
                (v.failedSuperFormIds.length == v.multiVaultData.liqData.length))
        ) revert Error.INVALID_RESCUE_DATA();

        v.dstChainId = superRegistry.chainId();

        v.superForm;
        for (uint256 i = 0; i < v.multiVaultData.liqData.length; i++) {
            if (v.multiVaultData.superFormIds[i] == v.failedSuperFormIds[i]) {
                (v.superForm, , ) = _getSuperForm(v.failedSuperFormIds[i]);

                IBridgeValidator(superRegistry.getBridgeValidator(liqDatas_[i].bridgeId)).validateTxData(
                    liqDatas_[i].txData,
                    v.dstChainId,
                    v.srcChainId,
                    false, /// @dev - this acts like a withdraw where funds are bridged back to user
                    v.superForm,
                    v.srcSender,
                    liqDatas_[i].token
                );

                dispatchTokens(
                    superRegistry.getBridgeAddress(liqDatas_[i].bridgeId),
                    liqDatas_[i].txData,
                    liqDatas_[i].token,
                    liqDatas_[i].amount,
                    v.srcSender,
                    liqDatas_[i].nativeAmount,
                    liqDatas_[i].permit2data,
                    superRegistry.PERMIT2()
                );
            }
        }
    }

    struct RescueFailedDepositLocalVars {
        uint8 multi;
        bool rescued;
        uint64 dstChainId;
        uint64 srcChainId;
        address srcSender;
        address superForm;
        bytes failedData;
        bytes payload;
        uint256 failedSuperFormId;
        AMBMessage payloadInfo;
        InitSingleVaultData singleVaultData;
    }

    /// @inheritdoc ICoreStateRegistry
    function rescueFailedDeposit(
        uint256 payloadId_,
        LiqRequest memory liqData_
    ) external payable override onlyProcessor {
        RescueFailedDepositLocalVars memory v;
        (v.multi, v.rescued, v.failedData, v.srcSender, v.srcChainId) = abi.decode(
            failedDepositPayloads[payloadId_],
            (uint8, bool, bytes, address, uint64)
        );
        if (v.multi == 1) revert Error.NOT_SINGLE_FAILURE();
        if (v.rescued) revert Error.ALREADY_RESCUED();

        failedDepositPayloads[payloadId_] = abi.encode(v.multi, true, v.failedData, v.srcSender, v.srcChainId);

        v.failedSuperFormId = abi.decode(v.failedData, (uint256));

        v.payload = payload[payloadId_];
        v.payloadInfo = abi.decode(v.payload, (AMBMessage));

        v.singleVaultData = abi.decode(v.payloadInfo.params, (InitSingleVaultData));

        v.dstChainId = superRegistry.chainId();

        if (v.singleVaultData.superFormId == v.failedSuperFormId) {
            (v.superForm, , ) = _getSuperForm(v.failedSuperFormId);

            IBridgeValidator(superRegistry.getBridgeValidator(liqData_.bridgeId)).validateTxData(
                liqData_.txData,
                v.dstChainId,
                v.srcChainId,
                false, /// @dev - this acts like a withdraw where funds are bridged back to user
                v.superForm,
                v.srcSender,
                liqData_.token
            );

            dispatchTokens(
                superRegistry.getBridgeAddress(liqData_.bridgeId),
                liqData_.txData,
                liqData_.token,
                liqData_.amount,
                v.srcSender,
                liqData_.nativeAmount,
                liqData_.permit2data,
                superRegistry.PERMIT2()
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _processMultiWithdrawal(
        uint256 payloadId_,
        bytes memory payload_,
        address srcSender_,
        uint64 srcChainId_
    ) internal returns (bytes memory) {
        InitMultiVaultData memory multiVaultData = abi.decode(payload_, (InitMultiVaultData));

        InitSingleVaultData memory singleVaultData;
        bool errors;

        /// @dev This will revert ALL of the transactions if one of them fails.
        for (uint256 i; i < multiVaultData.superFormIds.length; i++) {
            singleVaultData = InitSingleVaultData({
                payloadId: multiVaultData.payloadId,
                superFormId: multiVaultData.superFormIds[i],
                amount: multiVaultData.amounts[i],
                maxSlippage: multiVaultData.maxSlippage[i],
                liqData: multiVaultData.liqData[i],
                extraFormData: multiVaultData.extraFormData
            });

            /// @dev Store destination payloadId_ & index in extraFormData (tbd: 1-step flow doesnt need this)
            /// FIXME: Decide and move this logic inside the above initialization of the struct
            singleVaultData.extraFormData = abi.encode(payloadId_, i);

            (address superForm_, , ) = _getSuperForm(singleVaultData.superFormId);

            try IBaseForm(superForm_).xChainWithdrawFromVault(singleVaultData, srcSender_, srcChainId_) {
                /// @dev marks the indexes that don't require a callback re-mint of SuperPositions
                multiVaultData.amounts[i] = 0;
            } catch {
                if (!errors) errors = true;
                continue;
            }
        }

        /// @dev if at least one error happens, the shares will be re-minted for the affected superFormIds
        if (errors) {
            return
                _constructMultiReturnData(
                    srcChainId_,
                    srcSender_,
                    multiVaultData.payloadId,
                    TransactionType.WITHDRAW,
                    CallbackType.FAIL,
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
    ) internal returns (bytes memory) {
        if (payloadTracking[payloadId_] != PayloadState.UPDATED) {
            revert Error.PAYLOAD_NOT_UPDATED();
        }

        InitMultiVaultData memory multiVaultData = abi.decode(payload_, (InitMultiVaultData));

        (address[] memory superForms, , ) = _getSuperForms(multiVaultData.superFormIds);
        ERC20 underlying;
        uint256 numberOfVaults = multiVaultData.superFormIds.length;
        uint256[] memory dstAmounts = new uint256[](numberOfVaults);
        uint256[] memory failedSuperFormIds = new uint256[](numberOfVaults);
        bool fulfilment;
        bool errors;

        for (uint256 i = 0; i < numberOfVaults; i++) {
            /// @dev FIXME: whole msg.value is transferred here, in multi sync this needs to be split

            underlying = IBaseForm(superForms[i]).getUnderlyingOfVault();

            /// @dev This will revert ALL of the transactions if one of them fails.
            if (underlying.balanceOf(address(this)) >= multiVaultData.amounts[i]) {
                underlying.transfer(superForms[i], multiVaultData.amounts[i]);
                LiqRequest memory emptyRequest;

                /// Note / FIXME ?: dstAmounts has same size of the number of vaults. If a given deposit fails, we are minting 0 SPs back on source (slight gas waste)
                try
                    IBaseForm(superForms[i]).xChainDepositIntoVault(
                        InitSingleVaultData({
                            payloadId: multiVaultData.payloadId,
                            superFormId: multiVaultData.superFormIds[i],
                            amount: multiVaultData.amounts[i],
                            maxSlippage: multiVaultData.maxSlippage[i],
                            liqData: emptyRequest,
                            extraFormData: multiVaultData.extraFormData
                        }),
                        srcSender_,
                        srcChainId_
                    )
                returns (uint256 dstAmount) {
                    if (!fulfilment) fulfilment = true;
                    /// @dev marks the indexes that require a callback mint of SuperPositions
                    dstAmounts[i] = dstAmount;
                    continue;
                } catch {
                    if (!errors) errors = true;
                    failedSuperFormIds[i] = multiVaultData.superFormIds[i];
                    /// @dev mark here the superFormIds and amounts to be bridged back
                    /// FIXME do we bridge back tokens that failed? we need to save the failed vaults and bridge back the tokens... (in a different tx?)
                    continue;
                }
            } else {
                revert Error.BRIDGE_TOKENS_PENDING();
            }
        }

        /// @dev issue superPositions if at least one vault deposit passed
        if (fulfilment) {
            return
                _constructMultiReturnData(
                    srcChainId_,
                    srcSender_,
                    multiVaultData.payloadId,
                    TransactionType.DEPOSIT,
                    CallbackType.RETURN,
                    dstAmounts
                );
        }

        if (errors) {
            failedDepositPayloads[payloadId_] = abi.encode(
                1,
                false,
                abi.encode(failedSuperFormIds),
                srcSender_,
                srcChainId_
            );
            emit FailedXChainDeposits(payloadId_);
        }

        return "";
    }

    function _processSingleWithdrawal(
        uint256 payloadId_,
        bytes memory payload_,
        address srcSender_,
        uint64 srcChainId_
    ) internal returns (bytes memory) {
        InitSingleVaultData memory singleVaultData = abi.decode(payload_, (InitSingleVaultData));

        /// @dev Store PayloadId in extraFormData (tbd: 1-step flow doesnt need this)
        singleVaultData.extraFormData = abi.encode(payloadId_);

        (address superForm_, , ) = _getSuperForm(singleVaultData.superFormId);

        /// @dev Withdraw from Form
        /// TODO: we can do returns(ErrorCode errorCode) and have those also returned here from each individual try/catch (droping revert is risky)
        /// that's also the only way to get error type out of the try/catch
        /// NOTE: opted for just returning CallbackType.FAIL as we always end up with superPositions.returnPosition() anyways
        /// FIXME: try/catch may introduce some security concerns as reverting is final, while try/catch proceeds with the call further
        try IBaseForm(superForm_).xChainWithdrawFromVault(singleVaultData, srcSender_, srcChainId_) {
            // Handle the case when the external call succeeds
        } catch {
            // Handle the case when the external call reverts for whatever reason
            /// https://solidity-by-example.org/try-catch/
            return
                _constructSingleReturnData(
                    srcChainId_,
                    srcSender_,
                    singleVaultData.payloadId,
                    TransactionType.WITHDRAW,
                    CallbackType.FAIL,
                    singleVaultData.amount
                );
        }

        /// TODO: else if for FAIL callbackType could save some gas for users if we process it in stateSyncError() function
        return "";
    }

    function _processSingleDeposit(
        uint256 payloadId_,
        bytes memory payload_,
        address srcSender_,
        uint64 srcChainId_
    ) internal returns (bytes memory) {
        InitSingleVaultData memory singleVaultData = abi.decode(payload_, (InitSingleVaultData));
        if (payloadTracking[payloadId_] != PayloadState.UPDATED) {
            revert Error.PAYLOAD_NOT_UPDATED();
        }

        (address superForm_, , ) = _getSuperForm(singleVaultData.superFormId);

        ERC20 underlying = IBaseForm(superForm_).getUnderlyingOfVault();

        /// @dev NOTE: This will revert with an error only descriptive of the first possible revert out of many
        /// 1. Not enough tokens on this contract == BRIDGE_TOKENS_PENDING
        /// 2. Fail to .transfer() == BRIDGE_TOKENS_PENDING
        /// 3. xChainDepositIntoVault() reverting on anything == BRIDGE_TOKENS_PENDING
        /// FIXME: Add reverts at the Form level
        if (underlying.balanceOf(address(this)) >= singleVaultData.amount) {
            underlying.transfer(superForm_, singleVaultData.amount);

            try IBaseForm(superForm_).xChainDepositIntoVault(singleVaultData, srcSender_, srcChainId_) returns (
                uint256 dstAmount
            ) {
                return
                    _constructSingleReturnData(
                        srcChainId_,
                        srcSender_,
                        singleVaultData.payloadId,
                        TransactionType.DEPOSIT,
                        CallbackType.RETURN,
                        dstAmount
                    );
            } catch {
                failedDepositPayloads[payloadId_] = abi.encode(
                    0,
                    false,
                    abi.encode(singleVaultData.superFormId),
                    srcSender_,
                    srcChainId_
                );
                emit FailedXChainDeposits(payloadId_);
            }
        } else {
            revert Error.BRIDGE_TOKENS_PENDING();
        }

        return "";
    }

    /// @notice depositSync and withdrawSync internal method for sending message back to the source chain
    function _constructMultiReturnData(
        uint64 srcChainId_,
        address srcSender_,
        uint256 payloadId_,
        TransactionType txType,
        CallbackType returnType,
        uint256[] memory amounts
    ) internal view returns (bytes memory) {
        /// @notice Send Data to Source to issue superform positions.
        return
            abi.encode(
                AMBMessage(
                    _packTxInfo(uint8(txType), uint8(returnType), 1, STATE_REGISTRY_TYPE, srcSender_, srcChainId_),
                    abi.encode(ReturnMultiData(payloadId_, amounts))
                )
            );
    }

    /// @notice depositSync and withdrawSync internal method for sending message back to the source chain
    function _constructSingleReturnData(
        uint64 srcChainId_,
        address srcSender_,
        uint256 payloadId_,
        TransactionType txType,
        CallbackType returnType,
        uint256 amount
    ) internal view returns (bytes memory) {
        /// @notice Send Data to Source to issue superform positions.
        return
            abi.encode(
                AMBMessage(
                    _packTxInfo(uint8(txType), uint8(returnType), 0, STATE_REGISTRY_TYPE, srcSender_, srcChainId_),
                    abi.encode(ReturnSingleData(payloadId_, amount))
                )
            );
    }

    function _dispatchAcknowledgement(
        uint64 dstChainId_, /// TODO: here it's dstChainId but when it's called it's srcChainId
        bytes memory message_,
        bytes memory ackExtraData_
    ) internal {
        AckAMBData memory ackData = abi.decode(ackExtraData_, (AckAMBData));
        uint8[] memory ambIds_ = ackData.ambIds;

        AMBExtraData memory d = abi.decode(ackData.extraData, (AMBExtraData));

        _dispatchPayload(msg.sender, ambIds_[0], dstChainId_, d.gasPerAMB[0], message_, d.extraDataPerAMB[0]);

        if (ambIds_.length > 1) {
            _dispatchProof(msg.sender, ambIds_, dstChainId_, d.gasPerAMB, message_, d.extraDataPerAMB);
        }
    }

    function _validatePayloadUpdate(uint256 txInfo_, uint256 payloadId_, uint8 isMulti) internal view {
        (uint256 txType, uint256 callbackType, uint8 multi, , , ) = _decodeTxInfo(txInfo_);

        if (txType != uint256(TransactionType.DEPOSIT) && callbackType != uint256(CallbackType.INIT)) {
            revert Error.INVALID_PAYLOAD_UPDATE_REQUEST();
        }

        if (payloadTracking[payloadId_] != PayloadState.STORED) {
            revert Error.INVALID_PAYLOAD_STATE();
        }

        if (multi != isMulti) {
            revert Error.INVALID_PAYLOAD_UPDATE_REQUEST();
        }
    }

    function _validateSlippage(uint256 newAmount, uint256 maxAmount, uint256 slippage) internal pure {
        if (newAmount > maxAmount) {
            revert Error.NEGATIVE_SLIPPAGE();
        }

        uint256 minAmount = (maxAmount * (10000 - slippage)) / 10000;

        if (newAmount < minAmount) {
            revert Error.SLIPPAGE_OUT_OF_BOUNDS();
        }
    }
}

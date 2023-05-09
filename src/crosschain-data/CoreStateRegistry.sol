// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import {BaseStateRegistry} from "./BaseStateRegistry.sol";
import {ITokenBank} from "../interfaces/ITokenBank.sol";
import {ISuperRouter} from "../interfaces/ISuperRouter.sol";
import {ICoreStateRegistry} from "../interfaces/ICoreStateRegistry.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {PayloadState, TransactionType, CallbackType, AMBMessage, InitSingleVaultData, InitMultiVaultData, AckAMBData, AMBExtraData} from "../types/DataTypes.sol";
import {Error} from "../utils/Error.sol";
import "../utils/DataPacking.sol";

/// @title Cross-Chain AMB Aggregator
/// @author Zeropoint Labs
/// @notice stores, sends & process message sent via various messaging ambs.
contract CoreStateRegistry is BaseStateRegistry, ICoreStateRegistry {
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 public constant REQUIRED_QUORUM = 1;

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlySender() override {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasCoreContractsRole(
                msg.sender
            )
        ) revert Error.NOT_CORE_CONTRACTS();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    ///@dev set up admin during deployment.
    constructor(
        ISuperRegistry superRegistry_
    ) BaseStateRegistry(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev allows accounts with {DEFAULT_ADMIN_ROLE} to update the core contracts
    /// @param routerContract_ is the address of the router
    /// @param tokenBankContract_ is the address of the token bank

    /// @dev allows accounts with {UPDATER_ROLE} to modify a received cross-chain payload.
    /// @param payloadId_ is the identifier of the cross-chain payload to be updated.
    /// @param finalAmounts_ is the amount to be updated.
    /// NOTE: amounts cannot be updated beyond user specified safe slippage limit.
    function updateMultiVaultPayload(
        uint256 payloadId_,
        uint256[] calldata finalAmounts_
    ) external virtual override onlyUpdater {
        if (payloadId_ > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        AMBMessage memory payloadInfo = abi.decode(
            payload[payloadId_],
            (AMBMessage)
        );
        (uint256 txType, uint256 callbackType, bool multi, ) = _decodeTxInfo(
            payloadInfo.txInfo
        );

        if (
            txType != uint256(TransactionType.DEPOSIT) &&
            callbackType != uint256(CallbackType.INIT)
        ) {
            revert Error.INVALID_PAYLOAD_UPDATE_REQUEST();
        }

        if (payloadTracking[payloadId_] != PayloadState.STORED) {
            revert Error.INVALID_PAYLOAD_STATE();
        }

        if (!multi) {
            revert Error.INVALID_PAYLOAD_UPDATE_REQUEST();
        }

        InitMultiVaultData memory multiVaultData = abi.decode(
            payloadInfo.params,
            (InitMultiVaultData)
        );

        uint256 l1 = multiVaultData.amounts.length;
        uint256 l2 = finalAmounts_.length;

        if (l1 != l2) {
            revert Error.DIFFERENT_PAYLOAD_UPDATE_AMOUNTS_LENGTH();
        }

        for (uint256 i = 0; i < l1; i++) {
            uint256 newAmount = finalAmounts_[i]; /// backend fed amounts of socket tokens expected
            uint256 maxAmount = multiVaultData.amounts[i];

            if (newAmount > maxAmount) {
                revert Error.NEGATIVE_SLIPPAGE();
            }

            uint256 minAmount = (maxAmount *
                (10000 - multiVaultData.maxSlippage[i])) / 10000;

            if (newAmount < minAmount) {
                revert Error.SLIPPAGE_OUT_OF_BOUNDS();
            }
        }

        multiVaultData.amounts = finalAmounts_;

        payloadInfo.params = abi.encode(multiVaultData);

        payload[payloadId_] = abi.encode(payloadInfo);
        payloadTracking[payloadId_] = PayloadState.UPDATED;

        emit PayloadUpdated(payloadId_);
    }

    /// @dev allows accounts with {UPDATER_ROLE} to modify a received cross-chain payload.
    /// @param payloadId_ is the identifier of the cross-chain payload to be updated.
    /// @param finalAmount_ is the amount to be updated.
    /// NOTE: amounts cannot be updated beyond user specified safe slippage limit.
    function updateSingleVaultPayload(
        uint256 payloadId_,
        uint256 finalAmount_
    ) external virtual override onlyUpdater {
        if (payloadId_ > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        AMBMessage memory payloadInfo = abi.decode(
            payload[payloadId_],
            (AMBMessage)
        );
        (uint256 txType, uint256 callbackType, bool multi, ) = _decodeTxInfo(
            payloadInfo.txInfo
        );

        if (
            txType != uint256(TransactionType.DEPOSIT) &&
            callbackType != uint256(CallbackType.INIT)
        ) {
            revert Error.INVALID_PAYLOAD_UPDATE_REQUEST();
        }

        if (payloadTracking[payloadId_] != PayloadState.STORED) {
            revert Error.INVALID_PAYLOAD_STATE();
        }

        if (multi) {
            revert Error.INVALID_PAYLOAD_UPDATE_REQUEST();
        }

        InitSingleVaultData memory singleVaultData = abi.decode(
            payloadInfo.params,
            (InitSingleVaultData)
        );

        uint256 newAmount = finalAmount_; /// backend fed amounts of socket tokens expected
        uint256 maxAmount = singleVaultData.amount;

        if (newAmount > maxAmount) {
            revert Error.NEGATIVE_SLIPPAGE();
        }

        uint256 minAmount = (maxAmount *
            (10000 - singleVaultData.maxSlippage)) / 10000;

        if (newAmount < minAmount) {
            revert Error.SLIPPAGE_OUT_OF_BOUNDS();
        }

        singleVaultData.amount = finalAmount_;

        payloadInfo.params = abi.encode(singleVaultData);

        payload[payloadId_] = abi.encode(payloadInfo);
        payloadTracking[payloadId_] = PayloadState.UPDATED;

        emit PayloadUpdated(payloadId_);
    }

    /// @dev allows accounts with {PROCESSOR_ROLE} to process any successful cross-chain payload.
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @param ackExtraData_ is the extra data to be passed to AMB to send acknowledgement.
    /// NOTE: function can only process successful payloads.
    function processPayload(
        uint256 payloadId_,
        bytes memory ackExtraData_
    ) external payable virtual override onlyProcessor {
        if (payloadId_ > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.INVALID_PAYLOAD_STATE();
        }

        bytes memory _payload = payload[payloadId_];
        bytes memory _proof = abi.encode(keccak256(_payload));

        if (messageQuorum[_proof] < REQUIRED_QUORUM) {
            revert Error.QUORUM_NOT_REACHED();
        }

        AMBMessage memory payloadInfo = abi.decode(_payload, (AMBMessage));

        (uint256 txType, uint256 callbackType, bool multi, ) = _decodeTxInfo(
            payloadInfo.txInfo
        );

        uint16 srcChainId;
        bytes memory returnMessage;
        if (multi) {
            if (txType == uint256(TransactionType.WITHDRAW)) {
                (srcChainId, returnMessage) = _processMultiWithdrawal(
                    payloadId_,
                    callbackType,
                    payloadInfo
                );
            } else if (txType == uint256(TransactionType.DEPOSIT)) {
                (srcChainId, returnMessage) = _processMultiDeposit(
                    payloadId_,
                    callbackType,
                    payloadInfo
                );
            }
        } else {
            if (txType == uint256(TransactionType.WITHDRAW)) {
                (srcChainId, returnMessage) = _processSingleWithdrawal(
                    payloadId_,
                    callbackType,
                    payloadInfo
                );
            } else if (txType == uint256(TransactionType.DEPOSIT)) {
                (srcChainId, returnMessage) = _processSingleDeposit(
                    payloadId_,
                    callbackType,
                    payloadInfo
                );
            }
        }

        if (srcChainId != 0 && returnMessage.length > 0) {
            _dispatchAcknowledgement(srcChainId, returnMessage, ackExtraData_);
        }
    }

    /// @dev allows accounts with {PROCESSOR_ROLE} to revert Error.payload that fail to revert Error.state changes on source chain.
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// NOTE: function can only process failing payloads.
    function revertPayload(
        uint256 payloadId_,
        uint256,
        bytes memory
    ) external payable virtual override onlyProcessor {
        if (payloadId_ > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.INVALID_PAYLOAD_STATE();
        }

        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        AMBMessage memory payloadInfo = abi.decode(
            payload[payloadId_],
            (AMBMessage)
        );

        (, , bool multi, ) = _decodeTxInfo(payloadInfo.txInfo);

        if (multi) {
            InitMultiVaultData memory multiVaultData = abi.decode(
                payloadInfo.params,
                (InitMultiVaultData)
            );

            if (
                superRegistry.chainId() !=
                _getDestinationChain(multiVaultData.superFormIds[0])
            ) revert Error.INVALID_PAYLOAD_STATE();
        } else {
            InitSingleVaultData memory singleVaultData = abi.decode(
                payloadInfo.params,
                (InitSingleVaultData)
            );

            if (
                superRegistry.chainId() !=
                _getDestinationChain(singleVaultData.superFormId)
            ) revert Error.INVALID_PAYLOAD_STATE();
        }

        /// NOTE: Send `data` back to source based on AmbID to revert Error.the state.
        /// NOTE: chain_ids conflict should be addresses here.
        // amb[ambId_].dispatchPayload(formData.dstChainId_, message_, extraData_);
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _processMultiWithdrawal(
        uint256 payloadId_,
        uint256 callbackType_,
        AMBMessage memory payloadInfo_
    ) internal returns (uint16, bytes memory) {
        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        if (callbackType_ == uint256(CallbackType.INIT)) {
            InitMultiVaultData memory multiVaultData = abi.decode(
                payloadInfo_.params,
                (InitMultiVaultData)
            );
            return
                ITokenBank(superRegistry.tokenBank()).withdrawMultiSync{
                    value: msg.value
                }(multiVaultData);
        } else {
            ISuperRouter(superRegistry.superRouter()).stateMultiSync{
                value: msg.value
            }(payloadInfo_);
        }

        return (0, "");
    }

    function _processMultiDeposit(
        uint256 payloadId_,
        uint256 callbackType_,
        AMBMessage memory payloadInfo_
    ) internal returns (uint16, bytes memory) {
        if (callbackType_ == uint256(CallbackType.INIT)) {
            if (payloadTracking[payloadId_] != PayloadState.UPDATED) {
                revert Error.PAYLOAD_NOT_UPDATED();
            }
            payloadTracking[payloadId_] = PayloadState.PROCESSED;

            InitMultiVaultData memory multiVaultData = abi.decode(
                payloadInfo_.params,
                (InitMultiVaultData)
            );

            return
                ITokenBank(superRegistry.tokenBank()).depositMultiSync(
                    multiVaultData
                );
        } else {
            if (payloadTracking[payloadId_] != PayloadState.STORED) {
                revert Error.INVALID_PAYLOAD_STATE();
            }
            payloadTracking[payloadId_] = PayloadState.PROCESSED;

            ISuperRouter(superRegistry.superRouter()).stateMultiSync(
                payloadInfo_
            );
        }

        return (0, "");
    }

    function _processSingleWithdrawal(
        uint256 payloadId_,
        uint256 callbackType_,
        AMBMessage memory payloadInfo_
    ) internal returns (uint16, bytes memory) {
        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        if (callbackType_ == uint256(CallbackType.INIT)) {
            InitSingleVaultData memory singleVaultData = abi.decode(
                payloadInfo_.params,
                (InitSingleVaultData)
            );
            return
                ITokenBank(superRegistry.tokenBank()).withdrawSync{
                    value: msg.value
                }(singleVaultData);
            /// TODO: else if for FAIL callbackType could save some gas for users if we process it in stateSyncError() function
        } else {
            /// @dev Withdraw SyncBack here, callbackType.return
            ISuperRouter(superRegistry.superRouter()).stateSync{
                value: msg.value
            }(payloadInfo_);
        }

        return (0, "");
    }

    function _processSingleDeposit(
        uint256 payloadId_,
        uint256 callbackType_,
        AMBMessage memory payloadInfo_
    ) internal returns (uint16, bytes memory) {
        if (callbackType_ == uint256(CallbackType.INIT)) {
            InitSingleVaultData memory singleVaultData = abi.decode(
                payloadInfo_.params,
                (InitSingleVaultData)
            );
            if (payloadTracking[payloadId_] != PayloadState.UPDATED) {
                revert Error.PAYLOAD_NOT_UPDATED();
            }
            payloadTracking[payloadId_] = PayloadState.PROCESSED;

            return
                ITokenBank(superRegistry.tokenBank()).depositSync(
                    singleVaultData
                );
        } else {
            if (payloadTracking[payloadId_] != PayloadState.STORED) {
                revert Error.INVALID_PAYLOAD_STATE();
            }
            payloadTracking[payloadId_] = PayloadState.PROCESSED;

            ISuperRouter(superRegistry.superRouter()).stateSync(payloadInfo_);
        }

        return (0, "");
    }

    function _dispatchAcknowledgement(
        uint16 dstChainId_,
        bytes memory message_,
        bytes memory ackExtraData_
    ) internal {
        AckAMBData memory ackData = abi.decode(ackExtraData_, (AckAMBData));
        uint8[] memory ambIds_ = ackData.ambIds;

        /// @dev atleast 2 AMBs are required
        if (ambIds_.length < 2) {
            revert Error.INVALID_AMB_IDS_LENGTH();
        }

        AMBExtraData memory d = abi.decode(ackData.extraData, (AMBExtraData));

        _dispatchPayload(
            ambIds_[0],
            dstChainId_,
            d.gasPerAMB[0],
            message_,
            d.extraDataPerAMB[0]
        );

        _dispatchProof(
            ambIds_,
            dstChainId_,
            d.gasPerAMB,
            message_,
            d.extraDataPerAMB
        );
    }
}

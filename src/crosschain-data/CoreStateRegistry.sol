// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {BaseStateRegistry} from "./BaseStateRegistry.sol";
import {ISuperPositions} from "../interfaces/ISuperPositions.sol";
import {ICoreStateRegistry} from "../interfaces/ICoreStateRegistry.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {IBaseForm} from "../interfaces/IBaseForm.sol";
import {PayloadState, TransactionType, CallbackType, AMBMessage, InitSingleVaultData, InitMultiVaultData, AckAMBData, AMBExtraData, ReturnMultiData, ReturnSingleData} from "../types/DataTypes.sol";
import {LiqRequest} from "../types/DataTypes.sol";
import {Error} from "../utils/Error.sol";
import "../utils/DataPacking.sol";

/// @title Cross-Chain AMB Aggregator
/// @author Zeropoint Labs
/// @notice stores, sends & process message sent via various messaging ambs.
contract CoreStateRegistry is BaseStateRegistry, ICoreStateRegistry {
    /// @dev FIXME: are we using safe transfers?
    using SafeTransferLib for ERC20;
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public constant REQUIRED_QUORUM = 1;

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

            (, uint16 srcChainId, uint80 currentTotalTxs) = _decodeTxData(
                multiVaultData.txData
            );
            InitSingleVaultData memory singleVaultData;

            uint256 errorCounter;

            /// @dev This will revert ALL of the transactions if one of them fails.
            for (uint256 i; i < multiVaultData.superFormIds.length; i++) {
                singleVaultData = InitSingleVaultData({
                    txData: multiVaultData.txData,
                    superFormId: multiVaultData.superFormIds[i],
                    amount: multiVaultData.amounts[i],
                    maxSlippage: multiVaultData.maxSlippage[i],
                    liqData: multiVaultData.liqData[i],
                    extraFormData: multiVaultData.extraFormData
                });

                (address superForm_, , ) = _getSuperForm(
                    singleVaultData.superFormId
                );

                ///FIXME: handling failure cases
                try
                    IBaseForm(superForm_).xChainWithdrawFromVault(
                        singleVaultData
                    )
                {} catch {
                    errorCounter++;
                    continue;
                }
            }

            /// @dev mint back the superPositions on source if any of the transactions fail.
            if (errorCounter > 0) {
                return
                    _constructMultiReturnData(
                        multiVaultData,
                        TransactionType.WITHDRAW,
                        CallbackType.FAIL,
                        multiVaultData.amounts,
                        0 /// <=== FIXME: status always 0 for withdraw fail
                    );
            }
        } else {
            ISuperPositions(superRegistry.superPositions()).stateMultiSync(
                payloadInfo_
            );
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

            (address[] memory superForms, , ) = _getSuperForms(
                multiVaultData.superFormIds
            );
            ERC20 underlying;
            uint256 numberOfVaults = multiVaultData.superFormIds.length;
            uint256[] memory dstAmounts = new uint256[](numberOfVaults);

            uint256 numberPassed;

            for (uint256 i = 0; i < numberOfVaults; i++) {
                /// @dev FIXME: whole msg.value is transferred here, in multi sync this needs to be split

                underlying = IBaseForm(superForms[i]).getUnderlyingOfVault();

                /// @dev This will revert ALL of the transactions if one of them fails.
                if (
                    underlying.balanceOf(address(this)) >=
                    multiVaultData.amounts[i]
                ) {
                    underlying.transfer(
                        superForms[i],
                        multiVaultData.amounts[i]
                    );
                    LiqRequest memory emptyRequest;

                    ///FIXME: handling failure cases
                    try
                        IBaseForm(superForms[i]).xChainDepositIntoVault(
                            InitSingleVaultData({
                                txData: multiVaultData.txData,
                                superFormId: multiVaultData.superFormIds[i],
                                amount: multiVaultData.amounts[i],
                                maxSlippage: multiVaultData.maxSlippage[i],
                                liqData: emptyRequest,
                                extraFormData: multiVaultData.extraFormData
                            })
                        )
                    returns (uint256 dstAmount) {
                        dstAmounts[i] = dstAmount;
                        numberPassed++;
                        continue;
                    } catch {
                        continue;
                    }
                } else {
                    revert Error.BRIDGE_TOKENS_PENDING();
                }
            }

            /// @dev only issue super positions if all vaults passed
            if (numberPassed == numberOfVaults) {
                return (
                    _constructMultiReturnData(
                        multiVaultData,
                        TransactionType.DEPOSIT,
                        CallbackType.RETURN,
                        dstAmounts,
                        1 /// <=== FIXME: status always 1 for deposit success
                    )
                );
            }
        } else {
            if (payloadTracking[payloadId_] != PayloadState.STORED) {
                revert Error.INVALID_PAYLOAD_STATE();
            }
            payloadTracking[payloadId_] = PayloadState.PROCESSED;

            ISuperPositions(superRegistry.superPositions()).stateMultiSync(
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

            (address superForm_, , ) = _getSuperForm(
                singleVaultData.superFormId
            );

            /// @dev Withdraw from Form
            /// TODO: we can do returns(ErrorCode errorCode) and have those also returned here from each individual try/catch (droping revert is risky)
            /// that's also the only way to get error type out of the try/catch
            /// NOTE: opted for just returning CallbackType.FAIL as we always end up with superPositions.returnPosition() anyways
            /// FIXME: try/catch may introduce some security concerns as reverting is final, while try/catch proceeds with the call further
            try
                IBaseForm(superForm_).xChainWithdrawFromVault(singleVaultData)
            returns (uint16 status) {
                // Handle the case when the external call succeeds
                return (status, "");
            } catch {
                // Handle the case when the external call reverts for whatever reason
                /// https://solidity-by-example.org/try-catch/
                return (
                    _constructSingleReturnData(
                        singleVaultData,
                        TransactionType.WITHDRAW,
                        CallbackType.FAIL,
                        singleVaultData.amount,
                        0 /// <=== FIXME: status always 0 for withdraw fail
                    )
                );

                /*
                /// @dev we could match on individual reasons, but it's hard with strings
                emit ErrorLog("FORM_REVERT");
                */
            }

            /// TODO: else if for FAIL callbackType could save some gas for users if we process it in stateSyncError() function
        } else {
            /// @dev Withdraw SyncBack here, callbackType.return
            ISuperPositions(superRegistry.superPositions()).stateSync(
                payloadInfo_
            );
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

            (address superForm_, , ) = _getSuperForm(
                singleVaultData.superFormId
            );

            ERC20 underlying = IBaseForm(superForm_).getUnderlyingOfVault();

            /// DEVNOTE: This will revert with an error only descriptive of the first possible revert out of many
            /// 1. Not enough tokens on this contract == BRIDGE_TOKENS_PENDING
            /// 2. Fail to .transfer() == BRIDGE_TOKENS_PENDING
            /// 3. xChainDepositIntoVault() reverting on anything == BRIDGE_TOKENS_PENDING
            /// FIXME: Add reverts at the Form level
            if (underlying.balanceOf(address(this)) >= singleVaultData.amount) {
                underlying.transfer(superForm_, singleVaultData.amount);

                try
                    IBaseForm(superForm_).xChainDepositIntoVault(
                        singleVaultData
                    )
                returns (uint256 dstAmount) {
                    return (
                        _constructSingleReturnData(
                            singleVaultData,
                            TransactionType.DEPOSIT,
                            CallbackType.RETURN,
                            dstAmount,
                            0 /// <=== FIXME: status always 0 for withdraw fail
                        )
                    );
                } catch {
                    return (0, "");
                }
            } else {
                revert Error.BRIDGE_TOKENS_PENDING();
            }
        } else {
            if (payloadTracking[payloadId_] != PayloadState.STORED) {
                revert Error.INVALID_PAYLOAD_STATE();
            }
            payloadTracking[payloadId_] = PayloadState.PROCESSED;

            ISuperPositions(superRegistry.superPositions()).stateSync(
                payloadInfo_
            );
        }

        return (0, "");
    }

    /// @notice depositSync and withdrawSync internal method for sending message back to the source chain
    function _constructMultiReturnData(
        InitMultiVaultData memory multiVaultData_,
        TransactionType txType,
        CallbackType returnType,
        uint256[] memory amounts,
        uint16 status
    ) internal view returns (uint16, bytes memory) {
        (, uint16 srcChainId, uint80 currentTotalTxs) = _decodeTxData(
            multiVaultData_.txData
        );

        /// @notice Send Data to Source to issue superform positions.
        return (
            srcChainId,
            abi.encode(
                AMBMessage(
                    _packTxInfo(uint120(txType), uint120(returnType), true, 0),
                    abi.encode(
                        ReturnMultiData(
                            _packReturnTxInfo(
                                status,
                                srcChainId,
                                superRegistry.chainId(),
                                currentTotalTxs
                            ),
                            amounts /// @dev TODO: return this from Form, not InitSingleVaultData. Q: assets amount from shares or shares only?
                        )
                    )
                )
            )
        );
    }

    /// @notice depositSync and withdrawSync internal method for sending message back to the source chain
    function _constructSingleReturnData(
        InitSingleVaultData memory singleVaultData_,
        TransactionType txType,
        CallbackType returnType,
        uint256 amount,
        uint16 status
    ) internal view returns (uint16, bytes memory) {
        (, uint16 srcChainId, uint80 currentTotalTxs) = _decodeTxData(
            singleVaultData_.txData
        );

        /// @notice Send Data to Source to issue superform positions.
        return (
            srcChainId,
            abi.encode(
                AMBMessage(
                    _packTxInfo(uint120(txType), uint120(returnType), false, 0),
                    abi.encode(
                        ReturnSingleData(
                            _packReturnTxInfo(
                                status,
                                srcChainId,
                                superRegistry.chainId(),
                                currentTotalTxs
                            ),
                            amount /// @dev TODO: return this from Form, not InitSingleVaultData. Q: assets amount from shares or shares only?
                        )
                    )
                )
            )
        );
    }

    function _dispatchAcknowledgement(
        uint16 dstChainId_, /// TODO: here it's dstChainId but when it's called it's srcChainId
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ISuperRBAC} from "../../interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IERC4626Timelock} from ".././interfaces/IERC4626Timelock.sol";
import {IFormStateRegistry} from "./IFormStateRegistry.sol";
import {Error} from "../../utils/Error.sol";
import "../../utils/DataPacking.sol";

import {BaseStateRegistry} from "../../crosschain-data/BaseStateRegistry.sol";
import {ITokenBank} from "../../interfaces/ITokenBank.sol";
import {ISuperRouter} from "../../interfaces/ISuperRouter.sol";
import {PayloadState, TransactionType, CallbackType, AMBMessage, InitSingleVaultData, InitMultiVaultData} from "../../types/DataTypes.sol";
import "forge-std/console.sol";

/// @title Cross-Chain AMB Aggregator
/// @author Zeropoint Labs
/// @notice stores, sends & process message sent via various messaging ambs.
contract CoreStateRegistry is BaseStateRegistry, IFormStateRegistry {
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public constant REQUIRED_QUORUM = 1;
    mapping(uint256 payloadId => uint256 superFormId) public payloadStore;

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

    function receivePayload(uint256 payloadId, uint256 superFormId) external onlyUpdater {
        payloadStore[payloadId] = superFormId;
    }

    function initPayload(uint256 payloadId) external onlyUpdater {
        (address form_, , ) = _getSuperForm(payloadStore[payloadId]);
        IERC4626Timelock(form_).processUnlock(payloadId);
        delete payloadStore[payloadId];
        /// dispatchPayload();
    }

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
    /// NOTE: function can only process successful payloads.
    function processPayload(
        uint256 payloadId_
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

        if (multi) {
            if (txType == uint256(TransactionType.WITHDRAW)) {
                _processMultiWithdrawal(payloadId_, callbackType, payloadInfo);
            } else if (txType == uint256(TransactionType.DEPOSIT)) {
                _processMultiDeposit(payloadId_, callbackType, payloadInfo);
            }
        } else {
            if (txType == uint256(TransactionType.WITHDRAW)) {
                _processSingleWithdrawal(payloadId_, callbackType, payloadInfo);
            } else if (txType == uint256(TransactionType.DEPOSIT)) {
                _processSingleDeposit(payloadId_, callbackType, payloadInfo);
            }
        }
    }

    /// @dev allows accounts with {PROCESSOR_ROLE} to revert Error.payload that fail to revert Error.state changes on source chain.
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @param ambId_ is the identifier of the cross-chain amb to be used to send the acknowledgement.
    /// @param extraData_ is any message amb specific override information.
    /// NOTE: function can only process failing payloads.
    function revertPayload(
        uint256 payloadId_,
        uint256 ambId_,
        bytes memory extraData_
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

        uint16 chainId = superRegistry.chainId();
        if (multi) {
            InitMultiVaultData memory multiVaultData = abi.decode(
                payloadInfo.params,
                (InitMultiVaultData)
            );

            if (chainId != _getDestinationChain(multiVaultData.superFormIds[0]))
                revert Error.INVALID_PAYLOAD_STATE();
        } else {
            InitSingleVaultData memory singleVaultData = abi.decode(
                payloadInfo.params,
                (InitSingleVaultData)
            );

            if (chainId != _getDestinationChain(singleVaultData.superFormId))
                revert Error.INVALID_PAYLOAD_STATE();
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
    ) internal {
        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        if (callbackType_ == uint256(CallbackType.INIT)) {
            InitMultiVaultData memory multiVaultData = abi.decode(
                payloadInfo_.params,
                (InitMultiVaultData)
            );
            ITokenBank(superRegistry.tokenBank()).withdrawMultiSync{
                value: msg.value
            }(multiVaultData);
        } else {
            ISuperRouter(superRegistry.superRouter()).stateMultiSync{
                value: msg.value
            }(payloadInfo_);
        }
    }

    function _processMultiDeposit(
        uint256 payloadId_,
        uint256 callbackType_,
        AMBMessage memory payloadInfo_
    ) internal {
        if (callbackType_ == uint256(CallbackType.INIT)) {
            if (payloadTracking[payloadId_] != PayloadState.UPDATED) {
                revert Error.PAYLOAD_NOT_UPDATED();
            }
            payloadTracking[payloadId_] = PayloadState.PROCESSED;

            InitMultiVaultData memory multiVaultData = abi.decode(
                payloadInfo_.params,
                (InitMultiVaultData)
            );

            ITokenBank(superRegistry.tokenBank()).depositMultiSync{
                value: msg.value
            }(multiVaultData);
        } else {
            if (payloadTracking[payloadId_] != PayloadState.STORED) {
                revert Error.INVALID_PAYLOAD_STATE();
            }
            payloadTracking[payloadId_] = PayloadState.PROCESSED;

            ISuperRouter(superRegistry.superRouter()).stateMultiSync{
                value: msg.value
            }(payloadInfo_);
        }
    }

    function _processSingleWithdrawal(
        uint256 payloadId_,
        uint256 callbackType_,
        AMBMessage memory payloadInfo_ /// NOTE: var is used to track current state of action (callback, flag, multivault)
    ) internal {
        /// NOTE: For Keeper processing, don't we need additional PayloadState?
        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        if (callbackType_ == uint256(CallbackType.INIT)) {
            InitSingleVaultData memory singleVaultData = abi.decode(
                payloadInfo_.params,
                (InitSingleVaultData)
            );
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
    }

    function _processSingleDeposit(
        uint256 payloadId_,
        uint256 callbackType_,
        AMBMessage memory payloadInfo_
    ) internal {
        if (callbackType_ == uint256(CallbackType.INIT)) {
            InitSingleVaultData memory singleVaultData = abi.decode(
                payloadInfo_.params,
                (InitSingleVaultData)
            );
            if (payloadTracking[payloadId_] != PayloadState.UPDATED) {
                revert Error.PAYLOAD_NOT_UPDATED();
            }
            payloadTracking[payloadId_] = PayloadState.PROCESSED;

            ITokenBank(superRegistry.tokenBank()).depositSync{value: msg.value}(
                singleVaultData
            );
        } else {
            if (payloadTracking[payloadId_] != PayloadState.STORED) {
                revert Error.INVALID_PAYLOAD_STATE();
            }
            payloadTracking[payloadId_] = PayloadState.PROCESSED;

            ISuperRouter(superRegistry.superRouter()).stateSync{
                value: msg.value
            }(payloadInfo_);
        }
    }
}


contract FormStateRegistry {

    mapping(uint256 payloadId => uint256 superFormId) public payloadStore;

    bytes32 public constant TOKEN_BANK_ROLE = keccak256("FORM_KEEPER_ROLE");

    ISuperRegistry public superRegistry;

    modifier onlyFormKeeper() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasFormStateRegistryRole(msg.sender)
        ) revert Error.NOT_FORM_KEEPER();
        _;
    }

    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    function receivePayload(uint256 payloadId, uint256 superFormId) external onlyFormKeeper {
        payloadStore[payloadId] = superFormId;
    }

    function initPayload(uint256 payloadId) external onlyFormKeeper {
        (address form_, , ) = _getSuperForm(payloadStore[payloadId]);
        IERC4626Timelock(form_).processUnlock(payloadId);
        delete payloadStore[payloadId];
        /// dispatchPayload();
    }

}

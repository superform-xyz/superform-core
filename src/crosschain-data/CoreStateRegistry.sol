// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ITokenBank} from "../interfaces/ITokenBank.sol";
import {BaseStateRegistry} from "./BaseStateRegistry.sol";
import {ISuperRouter} from "../interfaces/ISuperRouter.sol";
import {ICoreStateRegistry} from "../interfaces/ICoreStateRegistry.sol";
import {StateData, PayloadState, TransactionType, CallbackType, ReturnData, FormData, FormCommonData, FormXChainData} from "../types/DataTypes.sol";

/// @title State Registry To Process CORE MESSAGING CALLS (DEPOSIT & WITHDRAWALS)
/// @author Zeropoint Labs
/// @notice stores, sends & process message sent via various messaging ambs.
contract CoreStateRegistry is BaseStateRegistry, ICoreStateRegistry {
    uint256 public constant REQUIRED_QUORUM = 1;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    address public routerContract;
    address public tokenBankContract;

    /*///////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    ///@dev set up admin during deployment.
    constructor(uint80 chainId_) BaseStateRegistry(chainId_) {}

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev allows accounts with {DEFAULT_ADMIN_ROLE} to update the core contracts
    /// @param routerContract_ is the address of the router
    /// @param tokenBankContract_ is the address of the token bank
    function setCoreContracts(
        address routerContract_,
        address tokenBankContract_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        routerContract = routerContract_;
        tokenBankContract = tokenBankContract_;

        emit CoreContractsUpdated(routerContract_, tokenBankContract_);
    }

    /// @dev allows accounts with {UPDATER_ROLE} to modify a received cross-chain payload.
    /// @param payloadId_ is the identifier of the cross-chain payload to be updated.
    /// @param finalAmounts_ is the amount to be updated.
    /// NOTE: amounts cannot be updated beyond user specified safe slippage limit.
    function updatePayload(uint256 payloadId_, uint256[] calldata finalAmounts_)
        external
        virtual
        override
        onlyRole(UPDATER_ROLE)
    {
        if (payloadId_ > payloadsCount) {
            revert INVALID_PAYLOAD_ID();
        }

        StateData memory payloadInfo = abi.decode(
            payload[payloadId_],
            (StateData)
        );

        if (
            payloadInfo.txType != TransactionType.DEPOSIT &&
            payloadInfo.flag != CallbackType.INIT
        ) {
            revert INVALID_PAYLOAD_UPDATE_REQUEST();
        }

        if (payloadTracking[payloadId_] != PayloadState.STORED) {
            revert INVALID_PAYLOAD_STATE();
        }

        FormData memory formData = abi.decode(payloadInfo.params, (FormData));
        FormCommonData memory formCommonData = abi.decode(
            formData.commonData,
            (FormCommonData)
        );
        FormXChainData memory formXChainData = abi.decode(
            formData.xChainData,
            (FormXChainData)
        );

        uint256 l1 = formCommonData.amounts.length;
        uint256 l2 = finalAmounts_.length;

        if (l1 != l2) {
            revert INVALID_ARR_LENGTH();
        }

        for (uint256 i = 0; i < l1; i++) {
            uint256 newAmount = finalAmounts_[i];
            uint256 maxAmount = formCommonData.amounts[i];

            if (newAmount > maxAmount) {
                revert NEGATIVE_SLIPPAGE();
            }

            uint256 minAmount = (maxAmount *
                (10000 - formXChainData.maxSlippage[i])) / 10000;

            if (newAmount < minAmount) {
                revert SLIPPAGE_OUT_OF_BOUNDS();
            }
        }

        formCommonData.amounts = finalAmounts_;

        FormData memory updatedFormData = FormData(
            formData.srcChainId,
            formData.dstChainId,
            abi.encode(formCommonData),
            formData.xChainData,
            formData.extraFormData
        );

        payloadInfo.params = abi.encode(updatedFormData);

        payload[payloadId_] = abi.encode(payloadInfo);
        payloadTracking[payloadId_] = PayloadState.UPDATED;

        emit PayloadUpdated(payloadId_);
    }

    /// @dev allows accounts with {PROCESSOR_ROLE} to process any successful cross-chain payload.
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// NOTE: function can only process successful payloads.
    function processPayload(uint256 payloadId_)
        external
        payable
        virtual
        override
        onlyRole(PROCESSOR_ROLE)
    {
        if (payloadId_ > payloadsCount) {
            revert INVALID_PAYLOAD_ID();
        }

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert INVALID_PAYLOAD_STATE();
        }

        bytes memory _payload = payload[payloadId_];
        bytes memory _proof = abi.encode(keccak256(_payload));

        if(messageQuorum[_proof] < REQUIRED_QUORUM) {
            revert QUORUM_NOT_REACHED(); 
        }

        StateData memory payloadInfo = abi.decode(_payload, (StateData));

        if (payloadInfo.txType == TransactionType.WITHDRAW) {
            _processWithdrawal(payloadId_, payloadInfo);
        } else {
            _processDeposit(payloadId_, payloadInfo);
        }
    }

    /// @dev allows accounts with {PROCESSOR_ROLE} to revert payload that fail to revert state changes on source chain.
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @param ambId_ is the identifier of the cross-chain amb to be used to send the acknowledgement.
    /// @param extraData_ is any message amb specific override information.
    /// NOTE: function can only process failing payloads.
    function revertPayload(
        uint256 payloadId_,
        uint256 ambId_,
        bytes memory extraData_
    ) external payable virtual override onlyRole(PROCESSOR_ROLE) {
        if (payloadId_ > payloadsCount) {
            revert INVALID_PAYLOAD_ID();
        }

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert INVALID_PAYLOAD_STATE();
        }

        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        StateData memory payloadInfo = abi.decode(
            payload[payloadId_],
            (StateData)
        );
        FormData memory formData = abi.decode(payloadInfo.params, (FormData));

        if (formData.dstChainId != chainId) {
            revert INVALID_PAYLOAD_STATE();
        }

        /// NOTE: Send `data` back to source based on AmbID to revert the state.
        /// NOTE: chain_ids conflict should be addresses here.
        // amb[ambId_].dipatchPayload(formData.dstChainId_, message_, extraData_);
    }
    

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _processWithdrawal(
        uint256 payloadId_,
        StateData memory payloadInfo_
    ) internal {
        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        if (payloadInfo_.flag == CallbackType.INIT) {
            ITokenBank(tokenBankContract).stateSync{value: msg.value}(
                abi.encode(payloadInfo_)
            );
        } else {
            ISuperRouter(routerContract).stateSync{value: msg.value}(
                abi.encode(payloadInfo_)
            );
        }
    }

    function _processDeposit(uint256 payloadId_, StateData memory payloadInfo_)
        internal
    {
        if (payloadInfo_.flag == CallbackType.INIT) {
            if (payloadTracking[payloadId_] != PayloadState.UPDATED) {
                revert PAYLOAD_NOT_UPDATED();
            }
            payloadTracking[payloadId_] = PayloadState.PROCESSED;

            ITokenBank(tokenBankContract).stateSync{value: msg.value}(
                abi.encode(payloadInfo_)
            );
        } else {
            if (payloadTracking[payloadId_] != PayloadState.STORED) {
                revert INVALID_PAYLOAD_STATE();
            }
            payloadTracking[payloadId_] = PayloadState.PROCESSED;

            ISuperRouter(routerContract).stateSync{value: msg.value}(
                abi.encode(payloadInfo_)
            );
        }
    }
}

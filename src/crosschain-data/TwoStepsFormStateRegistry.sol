// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {IERC4626TimelockForm} from "../forms/interfaces/IERC4626TimelockForm.sol";
import {ITwoStepsFormStateRegistry} from "../interfaces/ITwoStepsFormStateRegistry.sol";
import {Error} from "../utils/Error.sol";
import {BaseStateRegistry} from "../crosschain-data/BaseStateRegistry.sol";
import {AckAMBData, AMBExtraData, TransactionType, CallbackType, InitSingleVaultData, AMBMessage, ReturnSingleData} from "../types/DataTypes.sol";
import "../utils/DataPacking.sol";

/// @title TwoStepsFormStateRegistry
/// @author Zeropoint Labs
/// @notice handles communication in two stepped forms
contract TwoStepsFormStateRegistry is BaseStateRegistry, ITwoStepsFormStateRegistry {
    bytes32 immutable WITHDRAW_COOLDOWN_PERIOD = keccak256(abi.encodeWithSignature("WITHDRAW_COOLDOWN_PERIOD()"));

    enum TimeLockStatus {
        UNAVAILABLE,
        PENDING,
        PROCESSED
    }

    struct TimeLockPayload {
        uint256 superFormId;
        TimeLockStatus status;
    }

    mapping(uint256 payloadId => mapping(uint256 index => TimeLockPayload)) public timeLockPayload;

    /// @notice Checks if the caller is form allowed to send payload to this contract (only Forms are allowed)
    /// TODO: Test this modifier
    modifier onlyForm(uint256 superFormId) {
        (address superForm, , ) = _getSuperForm(superFormId);
        if (msg.sender != superForm) revert Error.NOT_SUPERFORM();
        _;
    }

    /// @notice Checks if the caller is the two steps processor
    modifier onlyTwoStepsProcessor() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasTwoStepsProcessorRole(msg.sender))
            revert Error.NOT_TWO_STEPS_PROCESSOR();
        _;
    }

    constructor(ISuperRegistry superRegistry_, uint8 registryType_) BaseStateRegistry(superRegistry_, registryType_) {}

    /// @inheritdoc ITwoStepsFormStateRegistry
    function receivePayload(uint256 payloadId_, uint256 index_, uint256 superFormId_) external onlyForm(superFormId_) {
        timeLockPayload[payloadId_][index_] = TimeLockPayload(superFormId_, TimeLockStatus.PENDING);
    }

    /// @inheritdoc ITwoStepsFormStateRegistry
    function finalizePayload(
        uint256 payloadId_,
        uint256 index_,
        bytes memory ackExtraData
    ) external payable onlyTwoStepsProcessor {
        TimeLockPayload storage payload = timeLockPayload[payloadId_][index_];

        if (payload.status != TimeLockStatus.PENDING) revert Error.INVALID_PAYLOAD_STATE();
        payload.status = TimeLockStatus.PROCESSED;

        (address superForm, , ) = _getSuperForm(payload.superFormId);

        /// NOTE: ERC4626TimelockForm is the only form that uses processUnlock function
        IERC4626TimelockForm form = IERC4626TimelockForm(superForm);

        /// @dev try to processUnlock for this srcSender
        try form.processUnlock(payloadId_, index_) {} catch (bytes memory err) {
            /// NOTE: in every other instance it's better to re-init withdraw
            /// NOTE: this catch will ALWAYS send a message back to source with exception of WITHDRAW_COOLDOWN_PERIOD error on Timelock
            /// TODO: Test this case (test messaging back to src)

            if (WITHDRAW_COOLDOWN_PERIOD != keccak256(err)) {
                /// catch doesnt have an access to singleVaultData, we use mirrored mapping on form (to test)
                (InitSingleVaultData memory singleVaultData, address srcSender, uint64 srcChainId) = form
                    .getSingleVaultDataAtIndex(payloadId_, index_);

                bytes memory returnMessage = _constructSingleReturnData(
                    srcSender,
                    srcChainId,
                    payloadId_,
                    singleVaultData
                );
                _dispatchAcknowledgement(srcChainId, returnMessage, ackExtraData); /// NOTE: ackExtraData needs to be always specified 'just in case' we fail
            }

            /// TODO: Emit something in case of WITHDRAW_COOLDOWN_PERIOD. We don't want to delete payload then
            // emit()
        }
    }

    /// @notice CoreStateRegistry-like function for build message back to the source. In regular flow called after xChainWithdraw succeds.
    /// @dev Constructs return message in case of a FAILURE to perform redemption of already unlocked assets
    function _constructSingleReturnData(
        address srcSender_,
        uint64 srcChainId_,
        uint256 payloadId_,
        InitSingleVaultData memory singleVaultData_
    ) internal view returns (bytes memory returnMessage) {
        /// @notice Send Data to Source to issue superform positions.
        return
            abi.encode(
                AMBMessage(
                    _packTxInfo(
                        uint8(TransactionType.WITHDRAW),
                        uint8(CallbackType.FAIL),
                        0,
                        STATE_REGISTRY_TYPE,
                        srcSender_,
                        srcChainId_
                    ),
                    abi.encode(ReturnSingleData(payloadId_, singleVaultData_.amount))
                )
            );
    }

    /// @notice In regular flow, BaseStateRegistry function for messaging back to the source
    /// @notice Use constructed earlier return message to send acknowledgment (msg) back to the source
    function _dispatchAcknowledgement(uint64 dstChainId_, bytes memory message_, bytes memory ackExtraData_) internal {
        AckAMBData memory ackData = abi.decode(ackExtraData_, (AckAMBData));
        uint8[] memory ambIds_ = ackData.ambIds;
        AMBExtraData memory d = abi.decode(ackData.extraData, (AMBExtraData));

        _dispatchPayload(msg.sender, ambIds_[0], dstChainId_, d.gasPerAMB[0], message_, d.extraDataPerAMB[0]);

        if (ambIds_.length > 1) {
            _dispatchProof(msg.sender, ambIds_, dstChainId_, d.gasPerAMB, message_, d.extraDataPerAMB);
        }
    }
}

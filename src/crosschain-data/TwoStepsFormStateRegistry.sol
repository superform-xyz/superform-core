// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {IERC4626TimelockForm} from "../forms/interfaces/IERC4626TimelockForm.sol";
import {ITwoStepsFormStateRegistry} from "../interfaces/ITwoStepsFormStateRegistry.sol";
import {Error} from "../utils/Error.sol";
import {BaseStateRegistry} from "../crosschain-data/BaseStateRegistry.sol";
import {ISuperRouter} from "../interfaces/ISuperRouter.sol";
import {AckAMBData, AMBExtraData, TransactionType, CallbackType, InitSingleVaultData, AMBMessage, ReturnSingleData} from "../types/DataTypes.sol";
import "../utils/DataPacking.sol";
import "forge-std/console.sol";

/// @title TwoStepsFormStateRegistry
/// @author Zeropoint Labs
/// @notice handles communication in two stepped forms
contract TwoStepsFormStateRegistry is BaseStateRegistry, ITwoStepsFormStateRegistry {
    /// @notice Pre-compute keccak256 hash of WITHDRAW_COOLDOWN_PERIOD()
    bytes32 immutable WITHDRAW_COOLDOWN_PERIOD = keccak256(abi.encodeWithSignature("WITHDRAW_COOLDOWN_PERIOD()"));

    /// @dev Stores individual user request to process unlock
    struct OwnerRequest {
        address owner;
        uint64 srcChainId;
        uint256 superFormId;
    }

    /// @notice Stores 1:1 mapping with Form.unlockId(srcSender) without copying the whole data structure
    mapping(uint256 payloadId => OwnerRequest) public payloadStore;

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
    function receivePayload(
        uint256 payloadId,
        uint256 superFormId,
        address owner,
        uint64 srcChainId
    ) external onlyForm(superFormId) {
        payloadStore[payloadId] = OwnerRequest({owner: owner, srcChainId: srcChainId, superFormId: superFormId});
    }

    /// @inheritdoc ITwoStepsFormStateRegistry
    function finalizePayload(uint256 payloadId, bytes memory ackExtraData) external payable onlyTwoStepsProcessor {
        (address superForm, , ) = _getSuperForm(payloadStore[payloadId].superFormId);

        /// NOTE: ERC4626TimelockForm is the only form that uses processUnlock function
        IERC4626TimelockForm form = IERC4626TimelockForm(superForm);

        address srcSender = payloadStore[payloadId].owner;
        uint64 srcChainId = payloadStore[payloadId].srcChainId;

        /// @dev try to processUnlock for this srcSender
        try form.processUnlock(srcSender, srcChainId) {
            delete payloadStore[payloadId];
        } catch (bytes memory err) {
            /// NOTE: in every other instance it's better to re-init withdraw
            /// NOTE: this catch will ALWAYS send a message back to source with exception of WITHDRAW_COOLDOWN_PERIOD error on Timelock
            /// TODO: Test this case (test messaging back to src)

            if (WITHDRAW_COOLDOWN_PERIOD != keccak256(err)) {
                /// catch doesnt have an access to singleVaultData, we use mirrored mapping on form (to test)
                (, InitSingleVaultData memory singleVaultData) = form.unlockId(srcSender);

                // it registryId == 1
                delete payloadStore[payloadId];

                bytes memory returnMessage = _constructSingleReturnData(srcChainId, payloadId, singleVaultData);
                _dispatchAcknowledgement(srcChainId, returnMessage, ackExtraData); /// NOTE: ackExtraData needs to be always specified 'just in case' we fail
            }

            /// TODO: Emit something in case of WITHDRAW_COOLDOWN_PERIOD. We don't want to delete payload then
            // emit()
        }
    }

    /// @notice CoreStateRegistry-like function for build message back to the source. In regular flow called after xChainWithdraw succeds.
    /// @dev Constructs return message in case of a FAILURE to perform redemption of already unlocked assets
    function _constructSingleReturnData(
        uint64 srcChainId_,
        uint256 payloadId_,
        InitSingleVaultData memory singleVaultData_
    ) internal view returns (uint16, bytes memory returnMessage) {
        /// @notice Send Data to Source to issue superform positions.
        return
            abi.encode(
                AMBMessage(
                    _packTxInfo(
                        uint120(TransactionType.WITHDRAW),
                        uint120(CallbackType.FAIL),
                        false,
                        STATE_REGISTRY_TYPE
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {IERC4626TimelockForm} from "../forms/interfaces/IERC4626TimelockForm.sol";
import {IFormStateRegistry} from "../interfaces/IFormStateRegistry.sol";
import {Error} from "../utils/Error.sol";
import {BaseStateRegistry} from "../crosschain-data/BaseStateRegistry.sol";
import {ISuperRouter} from "../interfaces/ISuperRouter.sol";
import {AckAMBData, AMBExtraData, TransactionType, CallbackType, InitSingleVaultData, AMBMessage, ReturnSingleData} from "../types/DataTypes.sol";
import "../utils/DataPacking.sol";

/// @title TwoStepsFormStateRegistry
/// @author Zeropoint Labs
/// @notice handles communication in two stepped forms
contract TwoStepsFormStateRegistry is BaseStateRegistry, IFormStateRegistry {
    /// @notice Pre-compute keccak256 hash of WITHDRAW_COOLDOWN_PERIOD()
    bytes32 immutable WITHDRAW_COOLDOWN_PERIOD =
        keccak256(abi.encodeWithSignature("WITHDRAW_COOLDOWN_PERIOD()"));

    /// @dev Stores individual user request to process unlock
    struct OwnerRequest {
        address owner;
        uint256 superFormId;
    }

    /// @notice Stores 1:1 mapping with Form.unlockId(srcSender) without copying the whole data structure
    mapping(uint256 payloadId => OwnerRequest) public payloadStore;

    /// @notice Checks if the caller is form allowed to send payload to this contract (only Forms are allowed)
    /// TODO: Test this modifier
    modifier onlyForm(uint256 superFormId) {
        (address form_, , ) = _getSuperForm(superFormId);
        if (msg.sender != form_) revert Error.NOT_FORM();
        _;
    }

    /// @notice Checks if the caller is the form keeper
    /// NOTE: Uses PROCESSOR_ROLE from SuperRBAC, who should be a form keeper?
    modifier onlyFormKeeper() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasProcessorRole(
                msg.sender
            )
        ) revert Error.NOT_FORM_KEEPER();
        _;
    }

    constructor(
        ISuperRegistry superRegistry_,
        uint8 registryType_
    ) BaseStateRegistry(superRegistry_, registryType_) {}

    /// @inheritdoc IFormStateRegistry
    function receivePayload(
        uint256 payloadId,
        uint256 superFormId,
        address owner
    ) external onlyForm(superFormId) {
        payloadStore[payloadId] = OwnerRequest({
            owner: owner,
            superFormId: superFormId
        });
    }

    /// @inheritdoc IFormStateRegistry
     function finalizePayload(
        uint256 payloadId,
        bytes memory ackExtraData
    ) external onlyFormKeeper {
        (address form_, , ) = _getSuperForm(
            payloadStore[payloadId].superFormId
        );

        /// NOTE: ERC4626TimelockForm is the only form that uses processUnlock function
        IERC4626TimelockForm form = IERC4626TimelockForm(form_);

        /// @dev try to processUnlock for this srcSender
        try form.processUnlock(payloadStore[payloadId].owner) {
            delete payloadStore[payloadId];
        } catch (bytes memory err) {
            /// NOTE: in every other instance it's better to re-init withdraw
            /// NOTE: this catch will ALWAYS send a message back to source with exception of WITHDRAW_COOLDOWN_PERIOD error on Timelock
            /// TODO: Test this case (test messaging back to src)
            if (WITHDRAW_COOLDOWN_PERIOD != keccak256(err)) {
                /// catch doesnt have an access to singleVaultData, we use mirrored mapping on form (to test)
                InitSingleVaultData memory singleVaultData = form.unlockId(
                    payloadStore[payloadId].owner
                );

                delete payloadStore[payloadId];

                (
                    uint16 srcChainId,
                    bytes memory returnMessage
                ) = _constructSingleReturnData(singleVaultData);
                _dispatchAcknowledgement(
                    srcChainId,
                    returnMessage,
                    ackExtraData
                ); /// NOTE: ackExtraData needs to be always specified 'just in case' we fail
            }

            /// TODO: Emit something in case of WITHDRAW_COOLDOWN_PERIOD. We don't want to delete payload then
            // emit()
        }
    }

    /// @notice CoreStateRegistry-like function for build message back to the source. In regular flow called after xChainWithdraw succeds.
    /// @dev Constructs return message in case of a FAILURE to perform redemption of already unlocked assets
    function _constructSingleReturnData(
        InitSingleVaultData memory singleVaultData_
    ) internal view returns (uint16 srcChainId, bytes memory returnMessage) {
        (, , uint80 currentTotalTxs) = _decodeTxData(singleVaultData_.txData);

        /// @notice Send Data to Source to issue superform positions.
        return (
            srcChainId,
            abi.encode(
                AMBMessage(
                    _packTxInfo(
                        uint120(TransactionType.WITHDRAW),
                        uint120(CallbackType.FAIL),
                        false,
                        0
                    ),
                    abi.encode(
                        ReturnSingleData(
                            _packReturnTxInfo(
                                srcChainId,
                                superRegistry.chainId(),
                                currentTotalTxs /// @dev TODO: How to sync that with source now?
                            ),
                            singleVaultData_.amount
                        )
                    )
                )
            )
        );
    }

    /// @notice In regular flow, BaseStateRegistry function for messaging back to the source
    /// @notice Use constructed earlier return message to send acknowledgment (msg) back to the source
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IBaseForm} from "../../interfaces/IBaseForm.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IBridgeValidator} from "../../interfaces/IBridgeValidator.sol";
import {IQuorumManager} from "../../interfaces/IQuorumManager.sol";
import {ISuperPositions} from "../../interfaces/ISuperPositions.sol";
import {IERC4626TimelockForm} from "../../forms/interfaces/IERC4626TimelockForm.sol";
import {ITwoStepsFormStateRegistry} from "../../interfaces/ITwoStepsFormStateRegistry.sol";
import {Error} from "../../utils/Error.sol";
import {BaseStateRegistry} from "../BaseStateRegistry.sol";
import {AckAMBData, AMBExtraData, TransactionType, CallbackType, InitSingleVaultData, AMBMessage, ReturnSingleData, PayloadState, TimeLockStatus, TimeLockPayload} from "../../types/DataTypes.sol";
import {DataLib} from "../../libraries/DataLib.sol";
import {PayloadUpdaterLib} from "../../libraries/PayloadUpdaterLib.sol";

/// @title TwoStepsFormStateRegistry
/// @author Zeropoint Labs
/// @notice handles communication in two stepped forms
contract TwoStepsFormStateRegistry is BaseStateRegistry, ITwoStepsFormStateRegistry {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/
    bytes32 immutable WITHDRAW_COOLDOWN_PERIOD = keccak256(abi.encodeWithSignature("WITHDRAW_COOLDOWN_PERIOD()"));

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev tracks the total time lock payloads
    uint256 public timeLockPayloadCounter;

    /// @dev stores the timelock payloads
    mapping(uint256 timeLockPayloadId => TimeLockPayload) public timeLockPayload;

    /// @dev allows only form to write to the receive paylod
    modifier onlyForm(uint256 superformId) {
        (address superform, , ) = superformId.getSuperform();
        if (msg.sender != superform) revert Error.NOT_SUPERFORM();
        if (IBaseForm(superform).getStateRegistryId() != superRegistry.getStateRegistryId(address(this)))
            revert Error.NOT_TWO_STEP_SUPERFORM();
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
    constructor(ISuperRegistry superRegistry_) BaseStateRegistry(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ITwoStepsFormStateRegistry
    function receivePayload(
        uint8 type_,
        address srcSender_,
        uint64 srcChainId_,
        uint256 lockedTill_,
        InitSingleVaultData memory data_
    ) external override onlyForm(data_.superformId) {
        ++timeLockPayloadCounter;

        timeLockPayload[timeLockPayloadCounter] = TimeLockPayload(
            type_,
            srcSender_,
            srcChainId_,
            lockedTill_,
            data_,
            TimeLockStatus.PENDING
        );
    }

    /// @inheritdoc ITwoStepsFormStateRegistry
    function finalizePayload(
        uint256 timeLockPayloadId_,
        bytes memory txData_,
        bytes memory ambOverride_
    ) external payable override onlyProcessor returns (bytes memory returnMessage) {
        TimeLockPayload memory p = timeLockPayload[timeLockPayloadId_];

        if (p.status != TimeLockStatus.PENDING) {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        if (p.lockedTill > block.timestamp) {
            revert Error.LOCKED();
        }

        /// @dev set status here to prevent re-entrancy
        p.status = TimeLockStatus.PROCESSED;
        (address superform, , ) = p.data.superformId.getSuperform();

        /// @dev this step is used to re-feed txData to avoid using old txData that would have expired by now
        if (txData_.length > 0) {
            PayloadUpdaterLib.validateLiqReq(p.data.liqData);

            /// @dev validate the incoming tx data
            IBridgeValidator(superRegistry.getBridgeValidator(p.data.liqData.bridgeId)).validateTxData(
                txData_,
                superRegistry.chainId(),
                p.srcChainId,
                false,
                superform,
                p.srcSender,
                p.data.liqData.token
            );

            p.data.liqData.txData = txData_;
        }

        IERC4626TimelockForm form = IERC4626TimelockForm(superform);
        try form.withdrawAfterCoolDown(p.data.amount, p) {} catch {
            /// @dev dispatch acknowledgement to mint superPositions back because of failure
            if (p.isXChain == 1) {
                returnMessage = _constructSingleReturnData(p.srcSender, p.data);

                _dispatchAcknowledgement(p.srcChainId, returnMessage, ambOverride_);
            }
            /// @dev for direct chain, superPositions are minted directly
            if (p.isXChain == 0) {
                returnMessage = _constructSingleReturnData(p.srcSender, p.data);

                ISuperPositions(superRegistry.superPositions()).mintSingleSP(
                    p.srcSender,
                    p.data.superformId,
                    p.data.amount
                );
            }
        }

        /// @dev restoring state for gas saving
        delete timeLockPayload[timeLockPayloadId_];
    }

    /// @inheritdoc BaseStateRegistry
    function processPayload(
        uint256 payloadId_,
        bytes memory
    )
        external
        payable
        virtual
        override
        onlyProcessor
        isValidPayloadId(payloadId_)
        returns (bytes memory, bytes memory)
    {
        uint256 _payloadHeader = payloadHeader[payloadId_];
        bytes memory _payloadBody = payloadBody[payloadId_];

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.PAYLOAD_ALREADY_PROCESSED();
        }

        (, uint256 callbackType, , , , uint64 srcChainId) = _payloadHeader.decodeTxInfo();

        AMBMessage memory _message = AMBMessage(_payloadHeader, _payloadBody);

        if (callbackType == uint256(CallbackType.FAIL)) {
            ISuperPositions(superRegistry.superPositions()).stateSync(_message);
        }

        /// @dev validates quorum
        bytes32 _proof = keccak256(abi.encode(_message));

        if (messageQuorum[_proof] < getRequiredMessagingQuorum(srcChainId)) {
            revert Error.QUORUM_NOT_REACHED();
        }

        /// @dev sets status as processed
        /// @dev check for re-entrancy & relocate if needed
        payloadTracking[payloadId_] = PayloadState.PROCESSED;
    }

    /// @dev returns the required quorum for the src chain id from super registry
    /// @param chainId is the src chain id
    /// @return the quorum configured for the chain id
    function getRequiredMessagingQuorum(uint64 chainId) public view returns (uint256) {
        return IQuorumManager(address(superRegistry)).getRequiredMessagingQuorum(chainId);
    }

    /// @inheritdoc ITwoStepsFormStateRegistry
    function getTimeLockPayload(uint256 payloadId_) external view returns (TimeLockPayload memory timeLockPayload_) {
        return timeLockPayload[payloadId_];
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice CoreStateRegistry-like function for build message back to the source. In regular flow called after xChainWithdraw succeds.
    /// @dev Constructs return message in case of a FAILURE to perform redemption of already unlocked assets
    function _constructSingleReturnData(
        address srcSender_,
        InitSingleVaultData memory singleVaultData_
    ) internal view returns (bytes memory returnMessage) {
        /// @notice Send Data to Source to issue superform positions.
        return
            abi.encode(
                AMBMessage(
                    DataLib.packTxInfo(
                        uint8(TransactionType.WITHDRAW),
                        uint8(CallbackType.FAIL),
                        0,
                        superRegistry.getStateRegistryId(address(this)),
                        srcSender_,
                        superRegistry.chainId()
                    ),
                    abi.encode(
                        ReturnSingleData(
                            singleVaultData_.payloadId,
                            singleVaultData_.superformId,
                            singleVaultData_.amount
                        )
                    )
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

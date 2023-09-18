// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import { IBaseForm } from "../../interfaces/IBaseForm.sol";
import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";
import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";
import { IQuorumManager } from "../../interfaces/IQuorumManager.sol";
import { IStateSyncer } from "../../interfaces/IStateSyncer.sol";
import { IERC4626TimelockForm } from "../../forms/interfaces/IERC4626TimelockForm.sol";
import { ITimelockStateRegistry } from "../../interfaces/ITimelockStateRegistry.sol";
import { IBaseStateRegistry } from "../../interfaces/IBaseStateRegistry.sol";
import { ISuperRBAC } from "../../interfaces/ISuperRBAC.sol";
import { IPaymentHelper } from "../../interfaces/IPaymentHelper.sol";
import { Error } from "../../utils/Error.sol";
import { BaseStateRegistry } from "../BaseStateRegistry.sol";
import { ProofLib } from "../../libraries/ProofLib.sol";
import { DataLib } from "../../libraries/DataLib.sol";
import { PayloadUpdaterLib } from "../../libraries/PayloadUpdaterLib.sol";
import "../../types/DataTypes.sol";

/// @title TimelockStateRegistry
/// @author Zeropoint Labs
/// @notice handles communication in two stepped forms

contract TimelockStateRegistry is BaseStateRegistry, ITimelockStateRegistry {
    using DataLib for uint256;
    using ProofLib for AMBMessage;

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyTimelockStateRegistryProcessor() {
        if (
            !ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasTimelockStateRegistryProcessorRole(
                msg.sender
            )
        ) revert Error.NOT_PROCESSOR();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/
    bytes32 immutable WITHDRAW_COOLDOWN_PERIOD = keccak256(abi.encodeWithSignature("WITHDRAW_COOLDOWN_PERIOD()"));

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev tracks the total time lock payloads
    uint256 public timelockPayloadCounter;

    /// @dev stores the timelock payloads
    mapping(uint256 timeLockPayloadId => TimelockPayload) public timelockPayload;

    /// @dev allows only form to write to the receive paylod
    modifier onlyForm(uint256 superformId) {
        (address superform,,) = superformId.getSuperform();
        if (msg.sender != superform) revert Error.NOT_SUPERFORM();
        if (IBaseForm(superform).getStateRegistryId() != superRegistry.getStateRegistryId(address(this))) {
            revert Error.NOT_TWO_STEP_SUPERFORM();
        }
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
    constructor(ISuperRegistry superRegistry_) BaseStateRegistry(superRegistry_) { }

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ITimelockStateRegistry
    function receivePayload(
        uint8 type_,
        address srcSender_,
        uint64 srcChainId_,
        uint256 lockedTill_,
        InitSingleVaultData memory data_
    )
        external
        override
        onlyForm(data_.superformId)
    {
        ++timelockPayloadCounter;

        timelockPayload[timelockPayloadCounter] =
            TimelockPayload(type_, srcSender_, srcChainId_, lockedTill_, data_, TwoStepsStatus.PENDING);
    }

    /// @inheritdoc ITimelockStateRegistry
    function finalizePayload(
        uint256 timeLockPayloadId_,
        bytes memory txData_
    )
        external
        payable
        override
        onlyTimelockStateRegistryProcessor
    {
        TimelockPayload memory p = timelockPayload[timeLockPayloadId_];
        IBridgeValidator bridgeValidator = IBridgeValidator(superRegistry.getBridgeValidator(p.data.liqData.bridgeId));
        uint256 finalAmount;

        if (p.status != TwoStepsStatus.PENDING) {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        if (p.lockedTill > block.timestamp) {
            revert Error.LOCKED();
        }

        /// @dev set status here to prevent re-entrancy
        p.status = TwoStepsStatus.PROCESSED;
        (address superform,,) = p.data.superformId.getSuperform();

        IERC4626TimelockForm form = IERC4626TimelockForm(superform);

        /// @dev this step is used to re-feed txData to avoid using old txData that would have expired by now
        if (txData_.length > 0) {
            PayloadUpdaterLib.validateLiqReq(p.data.liqData);

            /// @dev validate the incoming tx data
            bridgeValidator.validateTxData(
                IBridgeValidator.ValidateTxDataArgs(
                    txData_,
                    uint64(block.chainid),
                    p.srcChainId,
                    p.data.liqData.liqDstChainId,
                    false,
                    superform,
                    p.srcSender,
                    p.data.liqData.token
                )
            );

            finalAmount = bridgeValidator.decodeAmountIn(txData_, false);
            PayloadUpdaterLib.strictValidateSlippage(
                finalAmount, form.previewWithdrawFrom(p.data.amount), p.data.maxSlippage
            );

            p.data.liqData.txData = txData_;
        }

        try form.withdrawAfterCoolDown(p.data.amount, p) { }
        catch {
            /// @dev dispatch acknowledgement to mint superPositions back because of failure
            if (p.isXChain == 1) {
                (uint256 payloadId,) = abi.decode(p.data.extraFormData, (uint256, uint256));

                _dispatchAcknowledgement(
                    p.srcChainId, _getDeliveryAMB(payloadId), _constructSingleReturnData(p.srcSender, p.data)
                );
            }
            /// @dev for direct chain, superPositions are minted directly
            if (p.isXChain == 0) {
                IStateSyncer(superRegistry.getStateSyncer(p.data.superformRouterId)).mintSingle(
                    p.srcSender, p.data.superformId, p.data.amount
                );
            }
        }

        /// @dev restoring state for gas saving
        delete timelockPayload[timeLockPayloadId_];
    }

    /// @inheritdoc BaseStateRegistry
    function processPayload(uint256 payloadId_)
        external
        payable
        virtual
        override
        onlyTimelockStateRegistryProcessor
        isValidPayloadId(payloadId_)
    {
        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.PAYLOAD_ALREADY_PROCESSED();
        }

        /// @dev sets status as processed to prevent re-entrancy
        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        uint256 _payloadHeader = payloadHeader[payloadId_];
        bytes memory _payloadBody = payloadBody[payloadId_];

        (, uint256 callbackType,,,, uint64 srcChainId) = _payloadHeader.decodeTxInfo();
        AMBMessage memory _message = AMBMessage(_payloadHeader, _payloadBody);

        ReturnSingleData memory singleVaultData = abi.decode(_payloadBody, (ReturnSingleData));
        if (callbackType == uint256(CallbackType.FAIL)) {
            IStateSyncer(superRegistry.getStateSyncer(singleVaultData.superformRouterId)).stateSync(_message);
        }

        /// @dev validates quorum
        bytes32 _proof = _message.computeProof();

        if (messageQuorum[_proof] < getRequiredMessagingQuorum(srcChainId)) {
            revert Error.QUORUM_NOT_REACHED();
        }
    }

    /// @dev returns the required quorum for the src chain id from super registry
    /// @param chainId is the src chain id
    /// @return the quorum configured for the chain id
    function getRequiredMessagingQuorum(uint64 chainId) internal view returns (uint256) {
        return IQuorumManager(address(superRegistry)).getRequiredMessagingQuorum(chainId);
    }

    /// @inheritdoc ITimelockStateRegistry
    function getTimelockPayload(uint256 payloadId_) external view returns (TimelockPayload memory timelockPayload_) {
        return timelockPayload[payloadId_];
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev allows users to read the ids of ambs that delivered a payload
    function _getDeliveryAMB(uint256 payloadId_) internal view returns (uint8[] memory ambIds_) {
        IBaseStateRegistry coreStateRegistry =
            IBaseStateRegistry(superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY")));

        uint256 payloadHeader = coreStateRegistry.payloadHeader(payloadId_);
        bytes memory payloadBody = coreStateRegistry.payloadBody(payloadId_);

        bytes32 proof = AMBMessage(payloadHeader, payloadBody).computeProof();
        uint8[] memory proofIds = coreStateRegistry.getProofAMB(proof);

        uint256 len = proofIds.length;
        ambIds_ = new uint8[](len + 1);
        ambIds_[0] = coreStateRegistry.msgAMB(payloadId_);

        for (uint256 i; i < len;) {
            ambIds_[i + 1] = proofIds[i];

            unchecked {
                ++i;
            }
        }
    }

    /// @notice CoreStateRegistry-like function for build message back to the source. In regular flow called after
    /// xChainWithdraw succeds.
    /// @dev Constructs return message in case of a FAILURE to perform redemption of already unlocked assets
    function _constructSingleReturnData(
        address srcSender_,
        InitSingleVaultData memory singleVaultData_
    )
        internal
        view
        returns (bytes memory returnMessage)
    {
        /// @notice Send Data to Source to issue superform positions.
        return abi.encode(
            AMBMessage(
                DataLib.packTxInfo(
                    uint8(TransactionType.WITHDRAW),
                    uint8(CallbackType.FAIL),
                    0,
                    superRegistry.getStateRegistryId(address(this)),
                    srcSender_,
                    uint64(block.chainid)
                ),
                abi.encode(
                    ReturnSingleData(
                        singleVaultData_.superformRouterId,
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
    function _dispatchAcknowledgement(uint64 dstChainId_, uint8[] memory ambIds_, bytes memory message_) internal {
        (, bytes memory extraData) = IPaymentHelper(superRegistry.getAddress(keccak256("PAYMENT_HELPER")))
            .calculateAMBData(dstChainId_, ambIds_, message_);

        AMBExtraData memory d = abi.decode(extraData, (AMBExtraData));
        _dispatchPayload(msg.sender, ambIds_[0], dstChainId_, d.gasPerAMB[0], message_, d.extraDataPerAMB[0]);

        if (ambIds_.length > 1) {
            _dispatchProof(msg.sender, ambIds_, dstChainId_, d.gasPerAMB, message_, d.extraDataPerAMB);
        }
    }
}

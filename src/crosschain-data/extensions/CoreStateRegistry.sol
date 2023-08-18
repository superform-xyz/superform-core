// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {BaseStateRegistry} from "../BaseStateRegistry.sol";
import {LiquidityHandler} from "../../crosschain-liquidity/LiquidityHandler.sol";
import {ISuperPositions} from "../../interfaces/ISuperPositions.sol";
import {ICoreStateRegistry} from "../../interfaces/ICoreStateRegistry.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IQuorumManager} from "../../interfaces/IQuorumManager.sol";
import {IBaseForm} from "../../interfaces/IBaseForm.sol";
import {IBridgeValidator} from "../../interfaces/IBridgeValidator.sol";
import {LiqRequest} from "../../types/DataTypes.sol";
import {ISuperRBAC} from "../../interfaces/ISuperRBAC.sol";
import {DataLib} from "../../libraries/DataLib.sol";
import {PayloadUpdaterLib} from "../../libraries/PayloadUpdaterLib.sol";
import {Error} from "../../utils/Error.sol";
import "../../types/DataTypes.sol";

/// @title CoreStateRegistry
/// @author Zeropoint Labs
/// @dev enables communication between Superform Core Contracts deployed on all supported networks
contract CoreStateRegistry is LiquidityHandler, BaseStateRegistry, ICoreStateRegistry {
    using SafeERC20 for IERC20;
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyCoreStateRegistryProcessor() {
        if (
            !ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasCoreStateRegistryProcessorRole(msg.sender)
        ) revert Error.NOT_PROCESSOR();
        _;
    }

    modifier onlyCoreStateRegistryUpdater() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasCoreStateRegistryUpdaterRole(msg.sender))
            revert Error.NOT_UPDATER();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev just stores the superformIds that failed in a specific payload id
    mapping(uint256 payloadId => uint256[] superformIds) internal failedDeposits;

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlySender() override {
        if (superRegistry.getAddress(keccak256("SUPERFORM_ROUTER")) != msg.sender) revert Error.NOT_SUPER_ROUTER();
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

    /// @inheritdoc ICoreStateRegistry
    function updateDepositPayload(
        uint256 payloadId_,
        uint256[] calldata finalAmounts_
    ) external virtual override onlyCoreStateRegistryUpdater isValidPayloadId(payloadId_) {
        UpdateDepositPayloadVars memory v;

        v.prevPayloadHeader = payloadHeader[payloadId_];
        v.prevPayloadBody = payloadBody[payloadId_];

        v.prevPayloadProof = keccak256(abi.encode(AMBMessage(v.prevPayloadHeader, v.prevPayloadBody)));

        (, , v.isMulti, , , v.srcChainId) = v.prevPayloadHeader.decodeTxInfo();

        if (messageQuorum[v.prevPayloadProof] < getRequiredMessagingQuorum(v.srcChainId)) {
            revert Error.QUORUM_NOT_REACHED();
        }

        PayloadUpdaterLib.validateDepositPayloadUpdate(v.prevPayloadHeader, payloadTracking[payloadId_], v.isMulti);

        bytes memory newPayloadBody;
        if (v.isMulti != 0) {
            newPayloadBody = _updateMultiVaultDepositPayload(v.prevPayloadBody, finalAmounts_);
        } else {
            newPayloadBody = _updateSingleVaultDepositPayload(v.prevPayloadBody, finalAmounts_[0]);
        }

        /// @dev set the new payload body
        payloadBody[payloadId_] = newPayloadBody;

        /// @dev re-set previous message quorum to 0
        delete messageQuorum[v.prevPayloadProof];

        /// @dev set new message quorum
        messageQuorum[
            keccak256(abi.encode(AMBMessage(v.prevPayloadHeader, newPayloadBody)))
        ] = getRequiredMessagingQuorum(v.srcChainId);

        /// @dev define the payload status as updated
        payloadTracking[payloadId_] = PayloadState.UPDATED;

        emit PayloadUpdated(payloadId_);
    }

    /// @inheritdoc ICoreStateRegistry
    function updateWithdrawPayload(
        uint256 payloadId_,
        bytes[] calldata txData_
    ) external virtual override onlyCoreStateRegistryUpdater isValidPayloadId(payloadId_) {
        UpdateWithdrawPayloadVars memory v;

        /// @dev load header and body of payload
        v.prevPayloadHeader = payloadHeader[payloadId_];
        v.prevPayloadBody = payloadBody[payloadId_];

        v.prevPayloadProof = keccak256(abi.encode(AMBMessage(v.prevPayloadHeader, v.prevPayloadBody)));
        (, , v.isMulti, , v.srcSender, v.srcChainId) = v.prevPayloadHeader.decodeTxInfo();

        if (messageQuorum[v.prevPayloadProof] < getRequiredMessagingQuorum(v.srcChainId)) {
            revert Error.QUORUM_NOT_REACHED();
        }

        /// @dev validate payload update
        PayloadUpdaterLib.validateWithdrawPayloadUpdate(v.prevPayloadHeader, payloadTracking[payloadId_], v.isMulti);
        v.dstChainId = superRegistry.chainId();

        bytes memory newPayloadBody;
        if (v.isMulti != 0) {
            newPayloadBody = _updateMultiVaultWithdrawPayload(v, txData_);
        } else {
            newPayloadBody = _updateSingleVaultWithdrawPayload(v, txData_[0]);
        }

        /// @dev set the new payload body
        payloadBody[payloadId_] = newPayloadBody;

        /// @dev re-set previous message quorum to 0
        delete messageQuorum[v.prevPayloadProof];

        /// @dev set new message quorum
        messageQuorum[
            keccak256(abi.encode(AMBMessage(v.prevPayloadHeader, newPayloadBody)))
        ] = getRequiredMessagingQuorum(v.srcChainId);

        /// @dev define the payload status as updated
        payloadTracking[payloadId_] = PayloadState.UPDATED;

        emit PayloadUpdated(payloadId_);
    }

    /// @inheritdoc BaseStateRegistry
    function processPayload(
        uint256 payloadId_,
        bytes memory ackExtraData_
    )
        external
        payable
        virtual
        override
        onlyCoreStateRegistryProcessor
        isValidPayloadId(payloadId_)
        returns (bytes memory savedMessage, bytes memory returnMessage)
    {
        CoreProcessPayloadLocalVars memory v;

        v._payloadBody = payloadBody[payloadId_];
        v._payloadHeader = payloadHeader[payloadId_];

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.PAYLOAD_ALREADY_PROCESSED();
        }

        (v.txType, v.callbackType, v.multi, , v.srcSender, v.srcChainId) = v._payloadHeader.decodeTxInfo();

        v._message = AMBMessage(v._payloadHeader, v._payloadBody);

        savedMessage = abi.encode(v._message);

        /// @dev validates quorum
        v._proof = keccak256(savedMessage);

        /// @dev The number of valid proofs (quorum) must be equal to the required messaging quorum
        if (messageQuorum[v._proof] < getRequiredMessagingQuorum(v.srcChainId)) {
            revert Error.QUORUM_NOT_REACHED();
        }

        /// @dev mint superPositions for successful deposits or remint for failed withdraws
        if (v.callbackType == uint256(CallbackType.RETURN) || v.callbackType == uint256(CallbackType.FAIL)) {
            v.multi == 1
                ? ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).stateMultiSync(v._message)
                : ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).stateSync(v._message);
        }

        /// @dev for initial payload processing
        if (v.callbackType == uint8(CallbackType.INIT)) {
            if (v.txType == uint8(TransactionType.WITHDRAW)) {
                returnMessage = v.multi == 1
                    ? _processMultiWithdrawal(payloadId_, v._payloadBody, v.srcSender, v.srcChainId)
                    : _processSingleWithdrawal(v._payloadBody, v.srcSender, v.srcChainId);
            }

            if (v.txType == uint8(TransactionType.DEPOSIT)) {
                returnMessage = v.multi == 1
                    ? _processMultiDeposit(payloadId_, v._payloadBody, v.srcSender, v.srcChainId)
                    : _processSingleDeposit(payloadId_, v._payloadBody, v.srcSender, v.srcChainId);
            }
        }

        /// @dev if deposits succeeded or some withdrawal failed, dispatch a callback
        if (returnMessage.length > 0) {
            _dispatchAcknowledgement(v.srcChainId, returnMessage, ackExtraData_);
        }

        /// @dev sets status as processed
        /// @dev check for re-entrancy & relocate if needed
        payloadTracking[payloadId_] = PayloadState.PROCESSED;
    }

    /// @dev local struct to avoid stack too deep errors
    struct RescueFailedDepositsLocalVars {
        uint64 dstChainId;
        uint64 srcChainId;
        address srcSender;
        address superform;
    }

    /// @inheritdoc ICoreStateRegistry
    function rescueFailedDeposits(
        uint256 payloadId_,
        LiqRequest[] memory liqData_
    ) external payable override onlyCoreStateRegistryProcessor {
        RescueFailedDepositsLocalVars memory v;

        uint256[] memory superformIds = failedDeposits[payloadId_];

        uint256 l1 = superformIds.length;
        uint256 l2 = liqData_.length;

        if (l1 == 0 || l2 == 0 || l1 != l2) {
            revert Error.INVALID_RESCUE_DATA();
        }
        uint256 _payloadHeader = payloadHeader[payloadId_];

        (, , , , v.srcSender, v.srcChainId) = _payloadHeader.decodeTxInfo();

        delete failedDeposits[payloadId_];

        v.dstChainId = superRegistry.chainId();

        for (uint256 i; i < l1; ) {
            (v.superform, , ) = superformIds[i].getSuperform();

            IBridgeValidator(superRegistry.getBridgeValidator(liqData_[i].bridgeId)).validateTxData(
                liqData_[i].txData,
                v.dstChainId,
                v.srcChainId,
                false, /// @dev - this acts like a withdraw where funds are bridged back to user
                v.superform,
                v.srcSender,
                liqData_[i].token
            );

            dispatchTokens(
                superRegistry.getBridgeAddress(liqData_[i].bridgeId),
                liqData_[i].txData,
                liqData_[i].token,
                liqData_[i].amount,
                address(this),
                liqData_[i].nativeAmount,
                liqData_[i].permit2data,
                superRegistry.PERMIT2()
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @dev returns the required quorum for the src chain id from super registry
    /// @param chainId is the src chain id
    /// @return the quorum configured for the chain id
    function getRequiredMessagingQuorum(uint64 chainId) public view returns (uint256) {
        return IQuorumManager(address(superRegistry)).getRequiredMessagingQuorum(chainId);
    }

    /// @dev returns array of superformIds whose deposits need to be rescued, for a given payloadId
    function getFailedDeposits(uint256 payloadId) external view returns (uint256[] memory) {
        return failedDeposits[payloadId];
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev helper function to update multi vault deposit payload
    function _updateMultiVaultDepositPayload(
        bytes memory prevPayloadBody_,
        uint256[] calldata finalAmounts_
    ) internal pure returns (bytes memory newPayloadBody_) {
        InitMultiVaultData memory multiVaultData = abi.decode(prevPayloadBody_, (InitMultiVaultData));

        /// @dev compare number of vaults to update with provided finalAmounts length
        if (multiVaultData.amounts.length != finalAmounts_.length) {
            revert Error.DIFFERENT_PAYLOAD_UPDATE_AMOUNTS_LENGTH();
        }

        /// @dev validate payload update
        PayloadUpdaterLib.validateSlippageArray(finalAmounts_, multiVaultData.amounts, multiVaultData.maxSlippage);
        multiVaultData.amounts = finalAmounts_;

        newPayloadBody_ = abi.encode(multiVaultData);
    }

    /// @dev helper function to update single vault deposit payload
    function _updateSingleVaultDepositPayload(
        bytes memory prevPayloadBody_,
        uint256 finalAmount_
    ) internal pure returns (bytes memory newPayloadBody_) {
        InitSingleVaultData memory singleVaultData = abi.decode(prevPayloadBody_, (InitSingleVaultData));

        /// @dev validate payload update
        PayloadUpdaterLib.validateSlippage(finalAmount_, singleVaultData.amount, singleVaultData.maxSlippage);
        singleVaultData.amount = finalAmount_;

        newPayloadBody_ = abi.encode(singleVaultData);
    }

    /// @dev helper function to update multi vault withdraw payload
    function _updateMultiVaultWithdrawPayload(
        UpdateWithdrawPayloadVars memory v_,
        bytes[] calldata txData_
    ) internal view returns (bytes memory) {
        InitMultiVaultData memory multiVaultData = abi.decode(v_.prevPayloadBody, (InitMultiVaultData));

        uint256 len = multiVaultData.liqData.length;

        if (len != txData_.length) {
            revert Error.DIFFERENT_PAYLOAD_UPDATE_TX_DATA_LENGTH();
        }

        /// @dev validates if the incoming update is valid
        for (uint256 i; i < len; ) {
            if (txData_[i].length != 0 && multiVaultData.liqData[i].txData.length == 0) {
                (address superform, , ) = multiVaultData.superformIds[i].getSuperform();

                if (IBaseForm(superform).getStateRegistryId() == superRegistry.getStateRegistryId(address(this))) {
                    PayloadUpdaterLib.validateLiqReq(multiVaultData.liqData[i]);

                    IBridgeValidator(superRegistry.getBridgeValidator(multiVaultData.liqData[i].bridgeId))
                        .validateTxData(
                            txData_[i],
                            v_.dstChainId,
                            v_.srcChainId,
                            false,
                            superform,
                            v_.srcSender,
                            multiVaultData.liqData[i].token
                        );

                    multiVaultData.liqData[i].txData = txData_[i];
                }
            }

            unchecked {
                ++i;
            }
        }

        return abi.encode(multiVaultData);
    }

    /// @dev helper function to update single vault withdraw payload
    function _updateSingleVaultWithdrawPayload(
        UpdateWithdrawPayloadVars memory v_,
        bytes calldata txData_
    ) internal view returns (bytes memory newPayloadBody_) {
        InitSingleVaultData memory singleVaultData = abi.decode(v_.prevPayloadBody, (InitSingleVaultData));

        (address superform, , ) = singleVaultData.superformId.getSuperform();

        if (IBaseForm(superform).getStateRegistryId() != superRegistry.getStateRegistryId(address(this))) {
            revert Error.INVALID_PAYLOAD_UPDATE_REQUEST();
        }

        /// @dev validate payload update
        PayloadUpdaterLib.validateLiqReq(singleVaultData.liqData);

        IBridgeValidator(superRegistry.getBridgeValidator(singleVaultData.liqData.bridgeId)).validateTxData(
            txData_,
            v_.dstChainId,
            v_.srcChainId,
            false,
            superform,
            v_.srcSender,
            singleVaultData.liqData.token
        );

        singleVaultData.liqData.txData = txData_;

        newPayloadBody_ = abi.encode(singleVaultData);
    }

    function _processMultiWithdrawal(
        uint256 payloadId_,
        bytes memory payload_,
        address srcSender_,
        uint64 srcChainId_
    ) internal returns (bytes memory) {
        InitMultiVaultData memory multiVaultData = abi.decode(payload_, (InitMultiVaultData));

        InitSingleVaultData memory singleVaultData;
        bool errors;

        for (uint256 i; i < multiVaultData.superformIds.length; ) {
            /// @dev it is critical to validate that the action is being performed to the correct chainId coming from the superform
            DataLib.validateSuperformChainId(multiVaultData.superformIds[i], superRegistry.chainId());

            singleVaultData = InitSingleVaultData({
                payloadId: multiVaultData.payloadId,
                superformId: multiVaultData.superformIds[i],
                amount: multiVaultData.amounts[i],
                maxSlippage: multiVaultData.maxSlippage[i],
                liqData: multiVaultData.liqData[i],
                extraFormData: abi.encode(payloadId_, i) /// @dev Store destination payloadId_ & index in extraFormData (tbd: 1-step flow doesnt need this)
            });

            (address superform_, , ) = singleVaultData.superformId.getSuperform();

            try IBaseForm(superform_).xChainWithdrawFromVault(singleVaultData, srcSender_, srcChainId_) {
                /// @dev marks the indexes that don't require a callback re-mint of SuperPositions (successful withdraws)
                multiVaultData.amounts[i] = 0;
            } catch {
                /// @dev detect if there is at least one failed withdraw
                if (!errors) errors = true;
            }

            unchecked {
                ++i;
            }
        }

        /// @dev if at least one error happens, the shares will be re-minted for the affected superformIds
        if (errors) {
            return
                _constructMultiReturnData(
                    srcSender_,
                    multiVaultData.payloadId,
                    TransactionType.WITHDRAW,
                    CallbackType.FAIL,
                    multiVaultData.superformIds,
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

        (address[] memory superforms, , ) = DataLib.getSuperforms(multiVaultData.superformIds);

        IERC20 underlying;
        uint256 numberOfVaults = multiVaultData.superformIds.length;
        uint256[] memory dstAmounts = new uint256[](numberOfVaults);

        bool fulfilment;
        bool errors;

        for (uint256 i; i < numberOfVaults; ) {
            underlying = IERC20(IBaseForm(superforms[i]).getVaultAsset());

            if (underlying.balanceOf(address(this)) >= multiVaultData.amounts[i]) {
                underlying.transfer(superforms[i], multiVaultData.amounts[i]);
                LiqRequest memory emptyRequest;

                /// @dev it is critical to validate that the action is being performed to the correct chainId coming from the superform
                DataLib.validateSuperformChainId(multiVaultData.superformIds[i], superRegistry.chainId());

                /// @notice dstAmounts has same size of the number of vaults. If a given deposit fails, we are minting 0 SPs back on source (slight gas waste)
                try
                    IBaseForm(superforms[i]).xChainDepositIntoVault(
                        InitSingleVaultData({
                            payloadId: multiVaultData.payloadId,
                            superformId: multiVaultData.superformIds[i],
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
                    /// @dev marks the indexes that require a callback mint of SuperPositions (successful)
                    dstAmounts[i] = dstAmount;
                } catch {
                    /// @dev if any deposit fails, we mark errors as true and add it to failedDeposits mapping for future rescuing
                    if (!errors) errors = true;

                    failedDeposits[payloadId_].push(multiVaultData.superformIds[i]);
                }
            } else {
                revert Error.BRIDGE_TOKENS_PENDING();
            }
            unchecked {
                ++i;
            }
        }

        /// @dev issue superPositions if at least one vault deposit passed
        if (fulfilment) {
            return
                _constructMultiReturnData(
                    srcSender_,
                    multiVaultData.payloadId,
                    TransactionType.DEPOSIT,
                    CallbackType.RETURN,
                    multiVaultData.superformIds,
                    dstAmounts
                );
        }

        if (errors) {
            emit FailedXChainDeposits(payloadId_);
        }

        return "";
    }

    function _processSingleWithdrawal(
        bytes memory payload_,
        address srcSender_,
        uint64 srcChainId_
    ) internal returns (bytes memory) {
        InitSingleVaultData memory singleVaultData = abi.decode(payload_, (InitSingleVaultData));

        DataLib.validateSuperformChainId(singleVaultData.superformId, superRegistry.chainId());

        (address superform_, , ) = singleVaultData.superformId.getSuperform();

        /// @dev Withdraw from superform
        try IBaseForm(superform_).xChainWithdrawFromVault(singleVaultData, srcSender_, srcChainId_) {
            // Handle the case when the external call succeeds
        } catch {
            // Handle the case when the external call reverts for whatever reason
            /// https://solidity-by-example.org/try-catch/
            return
                _constructSingleReturnData(
                    srcSender_,
                    singleVaultData.payloadId,
                    TransactionType.WITHDRAW,
                    CallbackType.FAIL,
                    singleVaultData.superformId,
                    singleVaultData.amount
                );
        }

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

        DataLib.validateSuperformChainId(singleVaultData.superformId, superRegistry.chainId());

        (address superform_, , ) = singleVaultData.superformId.getSuperform();

        IERC20 underlying = IERC20(IBaseForm(superform_).getVaultAsset());

        if (underlying.balanceOf(address(this)) >= singleVaultData.amount) {
            underlying.transfer(superform_, singleVaultData.amount);

            /// @dev deposit to superform
            try IBaseForm(superform_).xChainDepositIntoVault(singleVaultData, srcSender_, srcChainId_) returns (
                uint256 dstAmount
            ) {
                return
                    _constructSingleReturnData(
                        srcSender_,
                        singleVaultData.payloadId,
                        TransactionType.DEPOSIT,
                        CallbackType.RETURN,
                        singleVaultData.superformId,
                        dstAmount
                    );
            } catch {
                /// @dev if any deposit fails, add it to failedDeposits mapping for future rescuing
                failedDeposits[payloadId_].push(singleVaultData.superformId);

                emit FailedXChainDeposits(payloadId_);
            }
        } else {
            revert Error.BRIDGE_TOKENS_PENDING();
        }

        return "";
    }

    /// @notice depositSync and withdrawSync internal method for sending message back to the source chain
    function _constructMultiReturnData(
        address srcSender_,
        uint256 payloadId_,
        TransactionType txType,
        CallbackType returnType,
        uint256[] memory superformIds_,
        uint256[] memory amounts
    ) internal view returns (bytes memory) {
        /// @dev Send Data to Source to issue superform positions (failed withdraws and successful deposits)
        return
            abi.encode(
                AMBMessage(
                    DataLib.packTxInfo(
                        uint8(txType),
                        uint8(returnType),
                        1,
                        superRegistry.getStateRegistryId(address(this)),
                        srcSender_,
                        superRegistry.chainId()
                    ),
                    abi.encode(ReturnMultiData(payloadId_, superformIds_, amounts))
                )
            );
    }

    /// @notice depositSync and withdrawSync internal method for sending message back to the source chain
    function _constructSingleReturnData(
        address srcSender_,
        uint256 payloadId_,
        TransactionType txType,
        CallbackType returnType,
        uint256 superformId_,
        uint256 amount
    ) internal view returns (bytes memory) {
        /// @dev Send Data to Source to issue superform positions (failed withdraws and successful deposits)
        return
            abi.encode(
                AMBMessage(
                    DataLib.packTxInfo(
                        uint8(txType),
                        uint8(returnType),
                        0,
                        superRegistry.getStateRegistryId(address(this)),
                        srcSender_,
                        superRegistry.chainId()
                    ),
                    abi.encode(ReturnSingleData(payloadId_, superformId_, amount))
                )
            );
    }

    /// @dev calls the appropriate dispatch function according to the ackExtraData the keeper fed initially
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

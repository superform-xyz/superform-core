// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BaseStateRegistry } from "src/crosschain-data/BaseStateRegistry.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { IQuorumManager } from "src/interfaces/IQuorumManager.sol";
import { ISuperPositions } from "src/interfaces/ISuperPositions.sol";
import {
    AsyncStatus,
    IAsyncStateRegistry,
    AsyncDepositPayload,
    AsyncWithdrawPayload,
    SyncWithdrawTxDataPayload,
    NOT_ASYNC_SUPERFORM,
    NOT_READY_TO_CLAIM,
    ERC7540_AMBIDS_NOT_ENCODED
} from "src/interfaces/IAsyncStateRegistry.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { IPaymentHelperV2 as IPaymentHelper } from "src/interfaces/IPaymentHelperV2.sol";
import { IERC7540Form } from "src/forms/interfaces/IERC7540Form.sol";
import { Error } from "src/libraries/Error.sol";
import { ProofLib } from "src/libraries/ProofLib.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { PayloadUpdaterLib } from "src/libraries/PayloadUpdaterLib.sol";
import {
    InitSingleVaultData,
    AMBMessage,
    CallbackType,
    TransactionType,
    PayloadState,
    ReturnSingleData
} from "src/types/DataTypes.sol";
import { IERC7575 } from "src/vendor/centrifuge/IERC7540.sol";

/// @title AsyncStateRegistry
/// @dev Handles communication in 7540 forms
/// @author Zeropoint Labs
contract AsyncStateRegistry is BaseStateRegistry, IAsyncStateRegistry {
    using DataLib for uint256;
    using ProofLib for AMBMessage;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    /// @dev tracks the total async deposit payloads
    uint256 public asyncDepositPayloadCounter;

    /// @dev tracks the total async withdraw payloads
    uint256 public asyncWithdrawPayloadCounter;

    /// @dev tracks the total sync withdraw txData payloads
    uint256 public syncWithdrawTxDataPayloadCounter;

    /// @dev stores the async  payloads
    mapping(uint256 asyncPayloadId => AsyncDepositPayload) public asyncDepositPayload;
    mapping(uint256 asyncPayloadId => AsyncWithdrawPayload) public asyncWithdrawPayload;
    mapping(uint256 syncPayloadId => SyncWithdrawTxDataPayload) public syncWithdrawTxDataPayload;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyAsyncStateRegistryProcessor() {
        bytes32 role = keccak256("ASYNC_STATE_REGISTRY_PROCESSOR_ROLE");
        if (!ISuperRBAC(_getSuperRegistryAddress(keccak256("SUPER_RBAC"))).hasRole(role, msg.sender)) {
            revert Error.NOT_PRIVILEGED_CALLER(role);
        }
        _;
    }

    /// @dev dispatchPayload() should be disabled by default
    modifier onlySender() override {
        revert Error.DISABLED();
        _;
    }

    /// @dev ensures only an async superform can write to this state registry
    /// @param superformId_ is the superformId of the superform to check
    modifier onlyAsyncSuperform(uint256 superformId_) {
        if (!ISuperformFactory(_getSuperRegistryAddress(keccak256("SUPERFORM_FACTORY"))).isSuperform(superformId_)) {
            revert Error.SUPERFORM_ID_NONEXISTENT();
        }
        (address superform,,) = superformId_.getSuperform();
        if (msg.sender != superform) revert Error.NOT_SUPERFORM();

        if (IBaseForm(superform).getStateRegistryId() != _getStateRegistryId()) {
            revert NOT_ASYNC_SUPERFORM();
        }

        _;
    }

    /// @dev ensures only valid payloads are processed
    /// @param payloadId_ is the payloadId to check
    modifier isValidPayloadId(uint256 payloadId_) {
        if (payloadId_ > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(ISuperRegistry superRegistry_) BaseStateRegistry(superRegistry_) { }
    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IAsyncStateRegistry
    function getAsyncDepositPayload(uint256 payloadId_)
        external
        view
        returns (AsyncDepositPayload memory asyncDepositPayload_)
    {
        return asyncDepositPayload[payloadId_];
    }

    /// @inheritdoc IAsyncStateRegistry
    function getAsyncWithdrawPayload(uint256 payloadId_)
        external
        view
        returns (AsyncWithdrawPayload memory asyncWithdrawPayload_)
    {
        return asyncWithdrawPayload[payloadId_];
    }

    /// @inheritdoc IAsyncStateRegistry
    function getSyncWithdrawTxDataPayload(uint256 payloadId_)
        external
        view
        returns (SyncWithdrawTxDataPayload memory syncWithdrawTxDataPayload_)
    {
        return syncWithdrawTxDataPayload[payloadId_];
    }
    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IAsyncStateRegistry
    function receiveDepositPayload(
        uint8 type_,
        uint64 srcChainId_,
        uint256 assetsToDeposit_,
        uint256 requestId_,
        InitSingleVaultData memory data_
    )
        external
        override
        onlyAsyncSuperform(data_.superformId)
    {
        if (data_.receiverAddress == address(0)) revert Error.RECEIVER_ADDRESS_NOT_SET();

        ++asyncDepositPayloadCounter;
        uint256 payloadId = asyncDepositPayloadCounter;

        asyncDepositPayload[payloadId] =
            AsyncDepositPayload(type_, srcChainId_, assetsToDeposit_, requestId_, data_, AsyncStatus.PENDING);

        emit ReceivedAsyncDepositPayload(payloadId);
    }

    /// @inheritdoc IAsyncStateRegistry
    function receiveWithdrawPayload(
        uint8 type_,
        uint64 srcChainId_,
        uint256 requestId_,
        InitSingleVaultData memory data_
    )
        external
        override
        onlyAsyncSuperform(data_.superformId)
    {
        if (data_.receiverAddress == address(0)) revert Error.RECEIVER_ADDRESS_NOT_SET();

        ++asyncWithdrawPayloadCounter;
        uint256 payloadId = asyncWithdrawPayloadCounter;

        asyncWithdrawPayload[payloadId] =
            AsyncWithdrawPayload(type_, srcChainId_, requestId_, data_, AsyncStatus.PENDING);

        emit ReceivedAsyncWithdrawPayload(payloadId);
    }

    /// @inheritdoc IAsyncStateRegistry
    function receiveSyncWithdrawTxDataPayload(
        uint64 srcChainId_,
        InitSingleVaultData memory data_
    )
        external
        override
        onlyAsyncSuperform(data_.superformId)
    {
        if (data_.receiverAddress == address(0)) revert Error.RECEIVER_ADDRESS_NOT_SET();

        ++syncWithdrawTxDataPayloadCounter;
        uint256 payloadId = syncWithdrawTxDataPayloadCounter;

        syncWithdrawTxDataPayload[payloadId] = SyncWithdrawTxDataPayload(srcChainId_, data_, AsyncStatus.PENDING);

        emit ReceivedSyncWithdrawTxDataPayload(payloadId);
    }

    struct FinalizeDepositPayloadLocalVars {
        bool is7540;
        address superformAddress;
        uint256 claimableDeposit;
        uint8[] ambIds;
    }
    /// @inheritdoc IAsyncStateRegistry

    function finalizeDepositPayload(uint256 asyncPayloadId_)
        external
        payable
        override
        onlyAsyncStateRegistryProcessor
    {
        FinalizeDepositPayloadLocalVars memory v;
        AsyncDepositPayload storage p = asyncDepositPayload[asyncPayloadId_];
        if (p.status != AsyncStatus.PENDING) {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        (v.superformAddress,,) = p.data.superformId.getSuperform();

        IERC7540Form superform = IERC7540Form(v.superformAddress);

        v.claimableDeposit = superform.getClaimableDepositRequest(p.requestId, p.data.receiverAddress);
        if (
            (p.requestId == 0 && v.claimableDeposit < p.assetsToDeposit)
                || (p.requestId != 0 && v.claimableDeposit != p.assetsToDeposit)
        ) {
            revert NOT_READY_TO_CLAIM();
        }

        /// @dev set status here to prevent re-entrancy
        p.status = AsyncStatus.PROCESSED;

        try superform.claimDeposit(p) returns (uint256 shares) {
            if (shares != 0 && !p.data.retain4626) {
                /// @dev dispatch acknowledgement to mint superPositions
                if (p.isXChain == 1) {
                    (v.is7540, v.ambIds) = _decode7540ExtraFormData(p.data.superformId, p.data.extraFormData);

                    if (!v.is7540) revert ERC7540_AMBIDS_NOT_ENCODED();

                    if (v.ambIds.length == 0) revert ERC7540_AMBIDS_NOT_ENCODED();

                    _dispatchAcknowledgement(
                        p.srcChainId,
                        v.ambIds,
                        abi.encode(
                            AMBMessage(
                                DataLib.packTxInfo(
                                    uint8(TransactionType.DEPOSIT),
                                    uint8(CallbackType.RETURN),
                                    0,
                                    _getStateRegistryId(),
                                    p.data.receiverAddress,
                                    CHAIN_ID
                                ),
                                abi.encode(ReturnSingleData(p.data.payloadId, p.data.superformId, shares))
                            )
                        )
                    );
                }

                /// @dev for direct chain, superPositions are minted directly
                if (p.isXChain == 0) {
                    ISuperPositions(_getSuperRegistryAddress(keccak256("SUPER_POSITIONS"))).mintSingle(
                        p.data.receiverAddress, p.data.superformId, shares
                    );
                }
            } else if (shares == 0) {
                emit FailedAsyncDepositZeroShares(asyncPayloadId_);
            }
        } catch {
            /// @dev In case of a deposit actual failure (at the vault level, or returned shares level in the form),
            /// @dev the course of action for a user to claim the deposit would be to directly call claim deposit at the
            /// vault contract level.
            /// @dev This must happen like this because superform does not have the shares nor the assets to act upon
            /// them.

            emit FailedDeposit(asyncPayloadId_);
        }

        /// @dev restoring state for gas saving
        delete asyncDepositPayload[asyncPayloadId_];

        emit FinalizedAsyncDepositPayload(asyncPayloadId_);
    }

    /// @inheritdoc IAsyncStateRegistry
    function finalizeWithdrawPayload(
        uint256 asyncPayloadId_,
        bytes memory txData_
    )
        external
        override
        onlyAsyncStateRegistryProcessor
    {
        AsyncWithdrawPayload storage p = asyncWithdrawPayload[asyncPayloadId_];
        if (p.status != AsyncStatus.PENDING) {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        (address superformAddress,,) = p.data.superformId.getSuperform();

        IERC7540Form superform = IERC7540Form(superformAddress);

        uint256 claimableRedeem = superform.getClaimableRedeemRequest(p.requestId, p.data.receiverAddress);

        if (
            (p.requestId == 0 && claimableRedeem < p.data.amount)
                || (p.requestId != 0 && claimableRedeem != p.data.amount)
        ) {
            revert NOT_READY_TO_CLAIM();
        }

        /// @dev set status here to prevent re-entrancy
        p.status = AsyncStatus.PROCESSED;

        /// @dev this step is used to feed txData in case user wants to receive assets in a different way
        if (txData_.length != 0) {
            _validateTxData(true, p.srcChainId, txData_, p.data, superformAddress);

            p.data.liqData.txData = txData_;
        }

        /// @dev if redeeming failed superPositions are not reminted
        /// @dev this is different than the normal 4626 flow because if a redeem is claimable
        /// @dev a user could simply go to the vault and claim the assets directly
        superform.claimWithdraw(p);

        /// @dev restoring state for gas saving
        delete asyncWithdrawPayload[asyncPayloadId_];

        emit FinalizedAsyncWithdrawPayload(asyncPayloadId_);
    }

    /// @inheritdoc IAsyncStateRegistry
    function finalizeSyncWithdrawTxDataPayload(
        uint256 payloadId_,
        bytes memory txData_
    )
        external
        payable
        override
        onlyAsyncStateRegistryProcessor
    {
        SyncWithdrawTxDataPayload storage p = syncWithdrawTxDataPayload[payloadId_];
        if (p.status != AsyncStatus.PENDING) {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        /// @dev set status here to prevent re-entrancy
        p.status = AsyncStatus.PROCESSED;

        (address superformAddress,,) = p.data.superformId.getSuperform();

        /// @dev this step is used to feed txData in case user wants to receive assets in a different way
        if (txData_.length != 0) {
            _validateTxData(false, p.srcChainId, txData_, p.data, superformAddress);

            p.data.liqData.txData = txData_;
        }
        try IERC7540Form(superformAddress).syncWithdrawTxData(p) { }
        catch {
            /// @dev dispatch acknowledgement to mint superPositions back because of failure
            /// @dev this case is only for xchain withdraws as sync direct withdraws don't pass through this contract
            (uint256 payloadId,) = abi.decode(p.data.extraFormData, (uint256, uint256));

            _dispatchAcknowledgement(
                p.srcChainId,
                _getDeliveryAMB(payloadId),
                abi.encode(
                    AMBMessage(
                        DataLib.packTxInfo(
                            uint8(TransactionType.WITHDRAW),
                            uint8(CallbackType.FAIL),
                            0,
                            _getStateRegistryId(),
                            p.data.receiverAddress,
                            CHAIN_ID
                        ),
                        abi.encode(ReturnSingleData(p.data.payloadId, p.data.superformId, p.data.amount))
                    )
                )
            );
        }

        /// @dev restoring state for gas saving
        delete syncWithdrawTxDataPayload[payloadId_];

        emit FinalizedSyncWithdrawTxDataPayload(payloadId_);
    }

    /// @inheritdoc BaseStateRegistry
    function processPayload(uint256 payloadId_)
        external
        payable
        virtual
        override
        onlyAsyncStateRegistryProcessor
        isValidPayloadId(payloadId_)
    {
        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.PAYLOAD_ALREADY_PROCESSED();
        }

        /// @dev sets status as processed to prevent re-entrancy
        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        uint256 _payloadHeader = payloadHeader[payloadId_];

        (, uint256 callbackType,,,, uint64 srcChainId) = _payloadHeader.decodeTxInfo();
        AMBMessage memory _message = AMBMessage(_payloadHeader, payloadBody[payloadId_]);

        /// @dev validates quorum
        if (messageQuorum[_message.computeProof()] < _getRequiredMessagingQuorum(srcChainId)) {
            revert Error.INSUFFICIENT_QUORUM();
        }

        if (callbackType == uint256(CallbackType.FAIL) || callbackType == uint256(CallbackType.RETURN)) {
            ISuperPositions(_getSuperRegistryAddress(keccak256("SUPER_POSITIONS"))).stateSync(_message);
        }
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    function _validateTxData(
        bool async_,
        uint64 srcChainId_,
        bytes memory txData_,
        InitSingleVaultData memory data_,
        address superformAddress_
    )
        internal
        view
    {
        IBaseForm superform = IBaseForm(superformAddress_);
        PayloadUpdaterLib.validateLiqReq(data_.liqData);

        IBridgeValidator bridgeValidator = IBridgeValidator(superRegistry.getBridgeValidator(data_.liqData.bridgeId));

        bridgeValidator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txData_,
                CHAIN_ID,
                srcChainId_,
                data_.liqData.liqDstChainId,
                false,
                superformAddress_,
                data_.receiverAddress,
                superform.getVaultAsset(),
                address(0)
            )
        );
        address vault = superform.getVaultAddress();
        /// @dev Validate if it is safe to use convertToAssets in full async or async redeem given previewRedeem is not
        /// available
        if (
            !PayloadUpdaterLib.validateSlippage(
                bridgeValidator.decodeAmountIn(txData_, false),
                async_ ? IERC7575(vault).convertToAssets(data_.amount) : IERC7575(vault).previewRedeem(data_.amount),
                data_.maxSlippage
            )
        ) {
            revert Error.SLIPPAGE_OUT_OF_BOUNDS();
        }
    }

    /// @dev returns the required quorum for the src chain id from super registry
    /// @param chainId is the src chain id
    /// @return the quorum configured for the chain id
    function _getRequiredMessagingQuorum(uint64 chainId) internal view returns (uint256) {
        return IQuorumManager(address(superRegistry)).getRequiredMessagingQuorum(chainId);
    }

    /// @dev allows users to read the ids of ambs that delivered a payload
    function _getDeliveryAMB(uint256 payloadId_) internal view returns (uint8[] memory ambIds_) {
        IBaseStateRegistry coreStateRegistry =
            IBaseStateRegistry(_getSuperRegistryAddress(keccak256("CORE_STATE_REGISTRY")));

        ambIds_ = coreStateRegistry.getMessageAMB(payloadId_);
    }

    /// @notice In regular flow, BaseStateRegistry function for messaging back to the source
    /// @notice Use constructed earlier return message to send acknowledgment (msg) back to the source
    function _dispatchAcknowledgement(uint64 dstChainId_, uint8[] memory ambIds_, bytes memory message_) internal {
        (, bytes memory extraData) = IPaymentHelper(_getSuperRegistryAddress(keccak256("PAYMENT_HELPER")))
            .calculateAMBData(dstChainId_, ambIds_, message_);

        _dispatchPayload(msg.sender, ambIds_, dstChainId_, message_, extraData);
    }

    function _getStateRegistryId() internal view returns (uint8) {
        return superRegistry.getStateRegistryId(address(this));
    }

    function _getSuperRegistryAddress(bytes32 id) internal view returns (address) {
        return superRegistry.getAddress(id);
    }

    function _decode7540ExtraFormData(
        uint256 superformId_,
        bytes memory extraFormData_
    )
        internal
        pure
        returns (bool found7540, uint8[] memory ambIds)
    {
        (uint256 nVaults, bytes[] memory encodedDatas) = abi.decode(extraFormData_, (uint256, bytes[]));

        for (uint256 i = 0; i < nVaults; ++i) {
            (uint256 decodedSuperformId, bytes memory encodedSfData) = abi.decode(encodedDatas[i], (uint256, bytes));

            if (decodedSuperformId == superformId_) {
                (ambIds) = abi.decode(encodedSfData, (uint8[]));
                if (ambIds.length > 0) {
                    found7540 = true;
                    break;
                }
            }
        }
    }
}

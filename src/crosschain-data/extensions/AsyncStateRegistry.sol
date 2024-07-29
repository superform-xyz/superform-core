// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";
import { ISuperPositions } from "src/interfaces/ISuperPositions.sol";
import { IERC7540Form } from "src/forms/interfaces/IERC7540Form.sol";
import { IERC7575 } from "src/vendor/centrifuge/IERC7540.sol";
import { IQuorumManager } from "src/interfaces/IQuorumManager.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { IPaymentHelperV2 as IPaymentHelper } from "src/interfaces/IPaymentHelperV2.sol";

import { Error } from "src/libraries/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { PayloadUpdaterLib } from "src/libraries/PayloadUpdaterLib.sol";

import "src/crosschain-data/BaseStateRegistry.sol";
import "src/interfaces/IAsyncStateRegistry.sol";
import "src/types/DataTypes.sol";

/// @title AsyncStateRegistry
/// @dev Handles communication in 7540 forms with constant zero request ids
/// @author Zeropoint Labs
contract AsyncStateRegistry is BaseStateRegistry, IAsyncStateRegistry {
    using DataLib for uint256;
    using ProofLib for AMBMessage;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    /// @dev tracks the total sync withdraw txData payloads
    uint256 public syncWithdrawTxDataPayloadCounter;

    /// @dev request configurations for each user and superform
    mapping(address user => mapping(uint256 superformId => RequestConfig requestConfig)) public requestConfigs;

    /// @dev sync withdraw txData payloads
    mapping(uint256 syncPayloadId => SyncWithdrawTxDataPayload) public syncWithdrawTxDataPayload;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    /// @dev dispatchPayload() should be disabled by default
    modifier onlySender() override {
        revert Error.DISABLED();
        _;
    }

    /// @dev ensures only the async state registry processor can a valid caller
    modifier onlyAsyncStateRegistryProcessor() {
        bytes32 role = keccak256("ASYNC_STATE_REGISTRY_PROCESSOR_ROLE");
        if (!ISuperRBAC(_getSuperRegistryAddress(keccak256("SUPER_RBAC"))).hasRole(role, msg.sender)) {
            revert Error.NOT_PRIVILEGED_CALLER(role);
        }
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
    function getRequestConfig(address user_, uint256 superformId_) external view returns (RequestConfig memory) {
        return requestConfigs[user_][superformId_];
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
    function receiveSyncWithdrawTxDataPayload(
        uint64 srcChainId_,
        InitSingleVaultData calldata data_
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

    /// @inheritdoc IAsyncStateRegistry
    function processSyncWithdrawWithUpdatedTxData(
        uint256 payloadId_,
        bytes calldata txData_
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

    /// @inheritdoc IAsyncStateRegistry
    function updateRequestConfig(
        uint8 type_,
        uint64 srcChainId_,
        bool isDeposit_,
        uint256 requestId_,
        InitSingleVaultData calldata data_
    )
        external
        override
        onlyAsyncSuperform(data_.superformId)
    {
        if (data_.receiverAddress == address(0)) revert Error.RECEIVER_ADDRESS_NOT_SET();

        /// @dev note that as per the standard, if requestId_ is returned as 0, it means it will always be zero
        RequestConfig storage config = requestConfigs[data_.receiverAddress][data_.superformId];

        config.isXChain = type_;
        config.retain4626 = data_.retain4626;
        config.currentSrcChainId = srcChainId_;

        if (requestId_ != 0) config.requestId = requestId_;

        /// TODO
        /// @dev decode payloadId with txHistory and check if multi == 1 if so, do not update
        config.currentReturnDataPayloadId = data_.payloadId;
        config.maxSlippageSetting = data_.maxSlippage;

        if (!isDeposit_) config.currentLiqRequest = data_.liqData;

        if (type_ == 1 && isDeposit_) {
            config.ambIds = _decode7540ExtraFormData(data_.superformId, data_.extraFormData);
            if (config.ambIds.length < _getQuorum(srcChainId_)) revert ERC7540_AMBIDS_NOT_ENCODED();
        }

        emit UpdatedRequestsConfig(data_.receiverAddress, data_.superformId, requestId_);
    }

    /// @inheritdoc IAsyncStateRegistry
    function claimAvailableDeposits(ClaimAvailableDepositsArgs calldata args_)
        external
        payable
        override
        onlyAsyncStateRegistryProcessor
    {
        RequestConfig memory config = requestConfigs[args_.user][args_.superformId];

        if (config.currentSrcChainId == 0) revert REQUEST_CONFIG_NON_EXISTENT();

        (address superformAddress,,) = args_.superformId.getSuperform();

        uint256 claimableDeposit =
            IERC7540Form(superformAddress).getClaimableDepositRequest(config.requestId, args_.user);
        if (claimableDeposit == 0) revert NOT_READY_TO_CLAIM();

        try IERC7540Form(superformAddress).claimDeposit(
            args_.user, args_.superformId, claimableDeposit, config.retain4626
        ) returns (uint256 shares) {
            if (shares > 0 && !config.retain4626) {
                /// @dev dispatch acknowledgement to mint superPositions
                if (config.isXChain == 1) {
                    _dispatchAcknowledgement(
                        config.currentSrcChainId,
                        config.ambIds,
                        abi.encode(
                            AMBMessage(
                                DataLib.packTxInfo(
                                    uint8(TransactionType.DEPOSIT),
                                    uint8(CallbackType.RETURN),
                                    0,
                                    _getStateRegistryId(),
                                    args_.user,
                                    CHAIN_ID
                                ),
                                abi.encode(
                                    ReturnSingleData(config.currentReturnDataPayloadId, args_.superformId, shares)
                                )
                            )
                        )
                    );
                }
                /// @dev for direct chain, superPositions are minted directly
                else {
                    ISuperPositions(_getSuperRegistryAddress(keccak256("SUPER_POSITIONS"))).mintSingle(
                        args_.user, args_.superformId, shares
                    );
                }
            } else if (shares == 0) {
                emit FailedDepositClaim(args_.user, args_.superformId, config.requestId);
            }
        } catch {
            /// @dev In case of a deposit actual failure (at the vault level, or returned shares level in the form),
            /// @dev the course of action for a user to claim the deposit would be to directly call claim deposit at the
            /// vault contract level.
            /// @dev This must happen like this because superform does not have the shares nor the assets to act upon
            /// them.

            emit FailedDepositClaim(args_.user, args_.superformId, config.requestId);
        }

        emit ClaimedAvailableDeposits(args_.user, args_.superformId, config.requestId);
    }

    /// @inheritdoc IAsyncStateRegistry
    function claimAvailableRedeems(
        address user_,
        uint256 superformId_,
        bytes calldata updatedTxData_
    )
        external
        override
        onlyAsyncStateRegistryProcessor
    {
        RequestConfig storage config = requestConfigs[user_][superformId_];

        if (config.currentSrcChainId == 0) {
            revert REQUEST_CONFIG_NON_EXISTENT();
        }

        (address superformAddress,,) = superformId_.getSuperform();

        /// @dev validate that account exists (aka User must do at least one deposit to initiate this procedure)

        IERC7540Form superform = IERC7540Form(superformAddress);

        uint256 claimableRedeem = superform.getClaimableRedeemRequest(config.requestId, user_);

        if (claimableRedeem == 0) {
            revert NOT_READY_TO_CLAIM();
        }

        /// @dev this step is used to feed txData in case user wants to receive assets in a different way
        if (updatedTxData_.length != 0) {
            _validateTxDataAsync(
                config.currentSrcChainId,
                claimableRedeem,
                updatedTxData_,
                config.currentLiqRequest,
                user_,
                superformAddress
            );

            config.currentLiqRequest.txData = updatedTxData_;
        }

        /// @dev if redeeming failed superPositions are not reminted
        /// @dev this is different than the normal 4626 flow because if a redeem is claimable
        /// @dev a user could simply go to the vault and claim the assets directly
        superform.claimWithdraw(
            user_,
            superformId_,
            claimableRedeem,
            config.maxSlippageSetting,
            config.isXChain,
            config.currentSrcChainId,
            config.currentLiqRequest
        );

        emit ClaimedAvailableRedeems(user_, superformId_, config.requestId);
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev validates the transaction data for async operations
    function _validateTxDataAsync(
        uint64 srcChainId_,
        uint256 claimableRedeem_,
        bytes calldata txData_,
        LiqRequest memory liqData_,
        address user_,
        address superformAddress_
    )
        internal
        view
    {
        IBaseForm superform = IBaseForm(superformAddress_);
        PayloadUpdaterLib.validateLiqReq(liqData_);

        IBridgeValidator bridgeValidator = IBridgeValidator(superRegistry.getBridgeValidator(liqData_.bridgeId));

        bridgeValidator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txData_,
                CHAIN_ID,
                srcChainId_,
                liqData_.liqDstChainId,
                false,
                superformAddress_,
                user_,
                superform.getVaultAsset(),
                address(0)
            )
        );

        if (bridgeValidator.decodeAmountIn(txData_, false) != claimableRedeem_) {
            revert INVALID_AMOUNT_IN_TXDATA();
        }
    }

    /// @dev validates the transaction data using a bridge validator
    function _validateTxData(
        bool async_,
        uint64 srcChainId_,
        bytes calldata txData_,
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

    /// @dev returns the required quorum for the source chain ID
    function _getRequiredMessagingQuorum(uint64 chainId) internal view returns (uint256) {
        return IQuorumManager(address(superRegistry)).getRequiredMessagingQuorum(chainId);
    }

    /// @dev retrieves the AMB IDs that delivered a payload
    function _getDeliveryAMB(uint256 payloadId_) internal view returns (uint8[] memory ambIds_) {
        IBaseStateRegistry coreStateRegistry =
            IBaseStateRegistry(_getSuperRegistryAddress(keccak256("CORE_STATE_REGISTRY")));

        ambIds_ = coreStateRegistry.getMessageAMB(payloadId_);
    }

    /// @notice In regular flow, BaseStateRegistry function for messaging back to the source
    /// @notice Use constructed earlier return message to send acknowledgment (msg) back to the source
    /// @dev dispatches an acknowledgment message back to the source chain
    function _dispatchAcknowledgement(uint64 dstChainId_, uint8[] memory ambIds_, bytes memory message_) internal {
        (, bytes memory extraData) = IPaymentHelper(_getSuperRegistryAddress(keccak256("PAYMENT_HELPER")))
            .calculateAMBData(dstChainId_, ambIds_, message_);

        _dispatchPayload(msg.sender, ambIds_, dstChainId_, message_, extraData);
    }

    /// @dev retrieves the state registry ID
    function _getStateRegistryId() internal view returns (uint8) {
        return superRegistry.getStateRegistryId(address(this));
    }

    /// @dev retrieves an address from the SuperRegistry
    function _getSuperRegistryAddress(bytes32 id) internal view returns (address) {
        return superRegistry.getAddress(id);
    }

    /// @dev decodes the 7540 extra form data
    function _decode7540ExtraFormData(
        uint256 superformId_,
        bytes calldata extraFormData_
    )
        internal
        pure
        returns (uint8[] memory ambIds)
    {
        (uint256 nVaults, bytes[] memory encodedDatas) = abi.decode(extraFormData_, (uint256, bytes[]));

        uint256 decodedSuperformId;
        bytes memory encodedSfData;

        for (uint256 i; i < nVaults; ++i) {
            (decodedSuperformId, encodedSfData) = abi.decode(encodedDatas[i], (uint256, bytes));

            if (decodedSuperformId == superformId_) {
                (ambIds) = abi.decode(encodedSfData, (uint8[]));
                if (ambIds.length > 0) break;
            }
        }
    }
}

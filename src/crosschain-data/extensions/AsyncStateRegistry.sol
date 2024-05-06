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
    IAsyncStateRegistry,
    AsyncDepositPayload,
    AsyncWithdrawPayload,
    FailedAsyncDeposit,
    NOT_ASYNC_SUPERFORM
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
    TimelockStatus,
    ReturnSingleData
} from "src/types/DataTypes.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

/// @title AsyncStateRegistry
/// @dev Handles communication in 7540 forms
/// @author Zeropoint Labs
contract AsyncStateRegistry is BaseStateRegistry, IAsyncStateRegistry, ReentrancyGuard {
    using DataLib for uint256;
    using ProofLib for AMBMessage;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    /// @dev tracks the total async deposit ayloads
    uint256 public asyncDepositPayloadCounter;

    /// @dev tracks the total async withdraw payloads
    uint256 public asyncWithdrawPayloadCounter;

    /// @dev stores the async  payloads
    mapping(uint256 asyncPayloadId => AsyncDepositPayload) public asyncDepositPayload;
    mapping(uint256 asyncPayloadId => AsyncWithdrawPayload) public asyncWithdrawPayload;

    /// @dev stores the information about a specific payload id that failed
    mapping(uint256 asyncPayloadId => FailedAsyncDeposit) failedDeposits;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyAsyncStateRegistry() {
        bytes32 role = keccak256("ASYNC_STATE_REGISTRY_PROCESSOR_ROLE");
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasRole(role, msg.sender)) {
            revert Error.NOT_PRIVILEGED_CALLER(role);
        }
        _;
    }

    /// @dev dispatchPayload() should be disabled by default
    modifier onlySender() override {
        revert Error.DISABLED();
        _;
    }

    /// @dev ensures only a async superform can write to this state registry
    /// @param superformId_ is the superformId of the superform to check
    modifier onlyAsyncSuperform(uint256 superformId_) {
        if (!ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).isSuperform(superformId_)) {
            revert Error.SUPERFORM_ID_NONEXISTENT();
        }
        (address superform,,) = superformId_.getSuperform();
        if (msg.sender != superform) revert Error.NOT_SUPERFORM();

        if (IBaseForm(superform).getStateRegistryId() != superRegistry.getStateRegistryId(address(this))) {
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

        asyncDepositPayload[asyncDepositPayloadCounter] =
            AsyncDepositPayload(type_, srcChainId_, assetsToDeposit_, requestId_, data_, TimelockStatus.PENDING);
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

        asyncWithdrawPayload[asyncWithdrawPayloadCounter] =
            AsyncDepositPayload(type_, srcChainId_, requestId_, data_, TimelockStatus.PENDING);
    }

    /// @inheritdoc IAsyncStateRegistry
    function finalizeDepositPayload(uint256 asyncPayloadId_) external payable override onlyAsyncStateRegistry {
        AsyncDepositPayload storage p = asyncDepositPayload[asyncPayloadId_];
        if (p.status != TimelockStatus.PENDING) {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        /// @dev set status here to prevent re-entrancy
        p.status = TimelockStatus.PROCESSED;

        (address superformAddress,,) = p.data.superformId.getSuperform();

        IERC7540Form superform = IERC7540Form(superformAddress);

        /// @dev MISSES LOGIC TO CHECK IF THERE ARE CLAIMABLE SHARES

        /// @dev Should we have keeper amount re-update logic here?

        try superform.claimDeposit(p) returns (uint256 shares) {
            if (shares != 0 && !p.data.retain4626) {
                /// @dev dispatch acknowledgement to mint superPositions
                if (p.isXChain == 1) {
                    (uint256 payloadId,) = abi.decode(p.data.extraFormData, (uint256, uint256));

                    _dispatchAcknowledgement(
                        p.srcChainId,
                        _getDeliveryAMB(payloadId),
                        _constructSingleDepositReturnData(p.data.receiverAddress, p.data, shares)
                    );
                }

                /// @dev for direct chain, superPositions are minted directly
                if (p.isXChain == 0) {
                    ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).mintSingle(
                        p.data.receiverAddress, p.data.superformId, shares
                    );
                }
            }
        } catch {
            /// @dev if any deposit fails, add it to failedDepositSuperformIds mapping for future rescuing
            failedDeposits[asyncPayloadId_].superformIds.push(p.data.superformId);
            failedDeposits[asyncPayloadId_].settlementToken.push(superform.getVaultAsset());

            emit FailedDeposit(asyncPayloadId_);
        }

        /// @dev restoring state for gas saving
        delete asyncDepositPayload[asyncPayloadId_];
    }

    /// @inheritdoc IAsyncStateRegistry
    function finalizeWithdrawPayload(
        uint256 asyncPayloadId_,
        bytes memory txData_
    )
        external
        payable
        override
        onlyAsyncStateRegistry
    {
        AsyncWithdrawPayload storage p = asyncWithdrawPayload[asyncPayloadId_];
        if (p.status != TimelockStatus.PENDING) {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        if (p.lockedTill > block.timestamp) {
            revert Error.LOCKED();
        }

        IBridgeValidator bridgeValidator = IBridgeValidator(superRegistry.getBridgeValidator(p.data.liqData.bridgeId));

        /// @dev set status here to prevent re-entrancy
        p.status = TimelockStatus.PROCESSED;

        (address superformAddress,,) = p.data.superformId.getSuperform();

        IERC7540Form superform = IERC7540Form(superformAddress);

        /// @dev this step is used to re-feed txData to avoid using old txData that would have expired by now
        if (txData_.length != 0) {
            uint256 finalAmount;

            PayloadUpdaterLib.validateLiqReq(p.data.liqData);
            /// @dev validate the incoming tx data
            bridgeValidator.validateTxData(
                IBridgeValidator.ValidateTxDataArgs(
                    txData_,
                    CHAIN_ID,
                    p.srcChainId,
                    p.data.liqData.liqDstChainId,
                    false,
                    superformAddress,
                    p.data.receiverAddress,
                    superform.getVaultAsset(),
                    address(0)
                )
            );

            finalAmount = bridgeValidator.decodeAmountIn(txData_, false);
            if (
                !PayloadUpdaterLib.validateSlippage(
                    finalAmount, superform.previewRedeemFrom(p.data.amount), p.data.maxSlippage
                )
            ) {
                revert Error.SLIPPAGE_OUT_OF_BOUNDS();
            }

            p.data.liqData.txData = txData_;
        }

        try superform.claimWithdraw(p) { }
        catch {
            /// @dev dispatch acknowledgement to mint superPositions back because of failure
            if (p.isXChain == 1) {
                (uint256 payloadId,) = abi.decode(p.data.extraFormData, (uint256, uint256));

                _dispatchAcknowledgement(
                    p.srcChainId,
                    _getDeliveryAMB(payloadId),
                    _constructSingleWithdrawReturnData(p.data.receiverAddress, p.data)
                );
            }

            /// @dev for direct chain, superPositions are minted directly
            if (p.isXChain == 0) {
                ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).mintSingle(
                    p.data.receiverAddress, p.data.superformId, p.data.amount
                );
            }
        }

        /// @dev restoring state for gas saving
        delete asyncWithdrawPayload[asyncPayloadId_];
    }

    /// @inheritdoc BaseStateRegistry
    function processPayload(uint256 payloadId_)
        external
        payable
        virtual
        override
        onlyAsyncStateRegistry
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

        /// @dev validates quorum
        bytes32 _proof = _message.computeProof();

        if (messageQuorum[_proof] < _getRequiredMessagingQuorum(srcChainId)) {
            revert Error.INSUFFICIENT_QUORUM();
        }

        if (callbackType == uint256(CallbackType.FAIL)) {
            ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).stateSync(_message);
        }
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev returns the required quorum for the src chain id from super registry
    /// @param chainId is the src chain id
    /// @return the quorum configured for the chain id
    function _getRequiredMessagingQuorum(uint64 chainId) internal view returns (uint256) {
        return IQuorumManager(address(superRegistry)).getRequiredMessagingQuorum(chainId);
    }

    /// @dev allows users to read the ids of ambs that delivered a payload
    function _getDeliveryAMB(uint256 payloadId_) internal view returns (uint8[] memory ambIds_) {
        IBaseStateRegistry coreStateRegistry =
            IBaseStateRegistry(superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY")));

        ambIds_ = coreStateRegistry.getMessageAMB(payloadId_);
    }

    /// @notice CoreStateRegistry-like function for build message back to the source. In regular flow called after
    /// xChainDeposit succeeds.
    /// @dev Constructs return message in case of a FAILURE to perform redemption of already unlocked assets
    function _constructSingleDepositReturnData(
        address receiverAddress_,
        InitSingleVaultData memory singleVaultData_,
        uint256 shares_
    )
        internal
        view
        returns (bytes memory returnMessage)
    {
        /// @notice Send Data to Source to issue superform positions.
        return abi.encode(
            AMBMessage(
                DataLib.packTxInfo(
                    uint8(TransactionType.DEPOSIT),
                    uint8(CallbackType.RETURN),
                    0,
                    superRegistry.getStateRegistryId(address(this)),
                    receiverAddress_,
                    CHAIN_ID
                ),
                abi.encode(ReturnSingleData(singleVaultData_.payloadId, singleVaultData_.superformId, shares_))
            )
        );
    }

    /// @notice CoreStateRegistry-like function for build message back to the source. In regular flow called after
    /// xChainWithdraw succeeds.
    /// @dev Constructs return message in case of a FAILURE to perform redemption of already unlocked assets
    function _constructSingleWithdrawReturnData(
        address receiverAddress_,
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
                    receiverAddress_,
                    CHAIN_ID
                ),
                abi.encode(
                    ReturnSingleData(singleVaultData_.payloadId, singleVaultData_.superformId, singleVaultData_.amount)
                )
            )
        );
    }

    /// @notice In regular flow, BaseStateRegistry function for messaging back to the source
    /// @notice Use constructed earlier return message to send acknowledgment (msg) back to the source
    function _dispatchAcknowledgement(uint64 dstChainId_, uint8[] memory ambIds_, bytes memory message_) internal {
        (, bytes memory extraData) = IPaymentHelper(superRegistry.getAddress(keccak256("PAYMENT_HELPER")))
            .calculateAMBData(dstChainId_, ambIds_, message_);

        _dispatchPayload(msg.sender, ambIds_, dstChainId_, message_, extraData);
    }
}

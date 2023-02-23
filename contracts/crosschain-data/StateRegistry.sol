// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {IStateRegistry} from "../interfaces/IStateRegistry.sol";
import {IBridgeImpl} from "../interfaces/IBridgeImpl.sol";
import {ISuperRouter} from "../interfaces/ISuperRouter.sol";
import {ISuperDestination} from "../interfaces/ISuperDestination.sol";
import {StateData, PayloadState, TransactionType, CallbackType, InitData, ReturnData} from "../types/DataTypes.sol";

/// @title Cross-Chain Messaging Bridge Aggregator
/// @author Zeropoint Labs
/// @notice stores, sends & process message sent via various messaging bridges.
contract StateRegistry is IStateRegistry, AccessControl {
    /*///////////////////////////////////////////////////////////////
                    Access Control Role Constants
    //////////////////////////////////////////////////////////////*/
    bytes32 public constant CORE_CONTRACTS_ROLE =
        keccak256("CORE_CONTRACTS_ROLE");
    bytes32 public constant IMPLEMENTATION_CONTRACTS_ROLE =
        keccak256("IMPLEMENTATION_CONTRACTS_ROLE");
    bytes32 public constant PROCESSOR_ROLE = keccak256("PROCESSOR_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    /*///////////////////////////////////////////////////////////////
                    State Variables
    //////////////////////////////////////////////////////////////*/
    uint256 public immutable chainId;
    uint256 public payloadsCount;

    address public routerContract;
    address public destinationContract;

    mapping(uint8 => IBridgeImpl) public bridge;

    /// @dev stores all received payloads after assigning them an unique identifier upon receiving.
    mapping(uint256 => bytes) public payload;

    /// @dev maps payloads to their status
    mapping(uint256 => PayloadState) public payloadTracking;

    /*///////////////////////////////////////////////////////////////
                    Constructor
    //////////////////////////////////////////////////////////////*/

    ///@dev set up admin during deployment.
    constructor(uint256 chainId_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        chainId = chainId_;
    }

    /*///////////////////////////////////////////////////////////////
                    External Functions
    //////////////////////////////////////////////////////////////*/
    receive() external payable {}

    /// @dev allows admin to update bridge implementations.
    /// @param bridgeId_ is the propreitory bridge id.
    /// @param bridgeImpl_ is the implementation address.
    function configureBridge(
        uint8 bridgeId_,
        address bridgeImpl_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (bridgeId_ == 0) {
            revert INVALID_BRIDGE_ID();
        }

        if (bridgeImpl_ == address(0)) {
            revert INVALID_BRIDGE_ADDRESS();
        }

        bridge[bridgeId_] = IBridgeImpl(bridgeImpl_);
        emit BridgeConfigured(bridgeId_, bridgeImpl_);
    }

    /// @dev allows core contracts to send data to a destination chain.
    /// @param bridgeId_ is the identifier of the message bridge to be used.
    /// @param dstChainId_ is the internal chainId used throughtout the protocol.
    /// @param message_ is the crosschain data to be sent.
    /// @param extraData_ defines all the message bridge specific information.
    /// NOTE: dstChainId maps with the message bridge's propreitory chain Id.
    function dispatchPayload(
        uint8 bridgeId_,
        uint256 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable virtual override onlyRole(CORE_CONTRACTS_ROLE) {
        IBridgeImpl bridgeImpl = bridge[bridgeId_];

        if (address(bridgeImpl) == address(0)) {
            revert INVALID_BRIDGE_ID();
        }

        bridgeImpl.dipatchPayload(dstChainId_, message_, extraData_);
    }

    /// @dev allows state registry to receive messages from bridge implementations.
    /// @param srcChainId_ is the internal chainId from which the data is sent.
    /// @param message_ is the crosschain data received.
    /// NOTE: Only {IMPLEMENTATION_CONTRACT} role can call this function.
    function receivePayload(
        uint256 srcChainId_,
        bytes memory message_
    ) external virtual override onlyRole(IMPLEMENTATION_CONTRACTS_ROLE) {
        ++payloadsCount;
        payload[payloadsCount] = message_;

        emit PayloadReceived(srcChainId_, chainId, payloadsCount);
    }

    /// @dev allows accounts with {UPDATER_ROLE} to modify a received cross-chain payload.
    /// @param payloadId_ is the identifier of the cross-chain payload to be updated.
    /// @param finalAmounts_ is the amount to be updated.
    /// NOTE: amounts cannot be updated beyond user specified safe slippage limit.
    function updatePayload(
        uint256 payloadId_,
        uint256[] calldata finalAmounts_
    ) external virtual override onlyRole(UPDATER_ROLE) {
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

        InitData memory data = abi.decode(payloadInfo.params, (InitData));

        uint256 l1 = data.amounts.length;
        uint256 l2 = finalAmounts_.length;

        if (l1 != l2) {
            revert INVALID_ARR_LENGTH();
        }

        for (uint256 i = 0; i < l1; i++) {
            uint256 newAmount = finalAmounts_[i];
            uint256 maxAmount = data.amounts[i];

            if (newAmount > maxAmount) {
                revert NEGATIVE_SLIPPAGE();
            }

            uint256 minAmount = (maxAmount * (10000 - data.maxSlippage[i])) /
                10000;

            if (newAmount < minAmount) {
                revert SLIPPAGE_OUT_OF_BOUNDS();
            }
        }

        data.amounts = finalAmounts_;
        payloadInfo.params = abi.encode(data);

        payload[payloadId_] = abi.encode(payloadInfo);
        payloadTracking[payloadId_] = PayloadState.UPDATED;

        emit PayloadUpdated(payloadId_);
    }

    /// @dev allows accounts with {PROCESSOR_ROLE} to process any successful cross-chain payload.
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// NOTE: function can only process successful payloads.
    function processPayload(
        uint256 payloadId_
    ) external payable virtual override onlyRole(PROCESSOR_ROLE) {
        if (payloadId_ > payloadsCount) {
            revert INVALID_PAYLOAD_ID();
        }

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert INVALID_PAYLOAD_STATE();
        }

        bytes memory _payload = payload[payloadId_];
        StateData memory payloadInfo = abi.decode(_payload, (StateData));

        if (payloadInfo.txType == TransactionType.WITHDRAW) {
            processWithdrawal(payloadId_, payloadInfo);
        } else {
            processDeposit(payloadId_, payloadInfo);
        }
    }

    /// @dev allows accounts with {PROCESSOR_ROLE} to revert payload that fail to revert state changes on source chain.
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @param bridgeId_ is the identifier of the cross-chain bridge to be used to send the acknowledgement.
    /// @param extraData_ is any message bridge specific override information.
    /// NOTE: function can only process failing payloads.
    function revertPayload(
        uint256 payloadId_,
        uint256 bridgeId_,
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
        InitData memory initData = abi.decode(payloadInfo.params, (InitData));

        if (initData.dstChainId != chainId) {
            revert INVALID_PAYLOAD_STATE();
        }

        /// NOTE: Send `data` back to source based on BridgeID to revert the state.
        /// NOTE: chain_ids conflict should be addresses here.
        // bridge[bridgeId_].dipatchPayload(initData.dstChainId_, message_, extraData_);
    }

    /*///////////////////////////////////////////////////////////////
                    Internal Functions
    //////////////////////////////////////////////////////////////*/
    function processWithdrawal(
        uint256 payloadId_,
        StateData memory payloadInfo_
    ) internal {
        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        if (payloadInfo_.flag == CallbackType.INIT) {
            ISuperDestination(destinationContract).stateSync{value: msg.value}(
                abi.encode(payloadInfo_)
            );
        } else {
            ISuperRouter(routerContract).stateSync{value: msg.value}(
                abi.encode(payloadInfo_)
            );
        }
    }

    function processDeposit(
        uint256 payloadId_,
        StateData memory payloadInfo_
    ) internal {
        if (payloadInfo_.flag == CallbackType.INIT) {
            if (payloadTracking[payloadId_] != PayloadState.UPDATED) {
                revert PAYLOAD_NOT_UPDATED();
            }
            payloadTracking[payloadId_] = PayloadState.PROCESSED;

            ISuperDestination(destinationContract).stateSync{value: msg.value}(
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

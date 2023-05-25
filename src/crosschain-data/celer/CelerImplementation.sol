// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;
import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {ISuperRBAC} from "../../interfaces/ISuperRBAC.sol";
import {IMessageBus} from "../../vendor/celer/IMessageBus.sol";
import {IMessageReceiver} from "../../vendor/celer/IMessageReceiver.sol";
import {Error} from "../../utils/Error.sol";
import {AMBMessage, BroadCastAMBExtraData} from "../../types/DataTypes.sol";
import "../../utils/DataPacking.sol";

/// @title CelerImplementation
/// @author Zeropoint Labs
/// @dev allows state registries to use celer for crosschain communication
contract CelerImplementation is IAmbImplementation, IMessageReceiver {
    /*///////////////////////////////////////////////////////////////
                    State Variables
    //////////////////////////////////////////////////////////////*/
    IMessageBus public immutable messageBus;
    ISuperRegistry public immutable superRegistry;

    uint64[] public broadcastChains;

    mapping(uint64 => uint64) public ambChainId;
    mapping(uint64 => uint64) public superChainId;
    mapping(uint64 => address) public authorizedImpl;

    mapping(bytes32 => bool) public processedMessages;

    /*///////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/
    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(msg.sender)) revert Error.NOT_PROTOCOL_ADMIN();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                    Constructor
    //////////////////////////////////////////////////////////////*/
    /// @param messageBus_ is the celer message bus contract for respective chain.
    constructor(IMessageBus messageBus_, ISuperRegistry superRegistry_) {
        messageBus = messageBus_;
        superRegistry = superRegistry_;
    }

    /*///////////////////////////////////////////////////////////////
                    External Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice receive enables refund processing for gas payments
    /// @dev FIXME: check for re-entrancy in all gas refunds
    receive() external payable {}

    /// @inheritdoc IAmbImplementation
    function dispatchPayload(
        address srcSender_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory /// extraData_
    ) external payable virtual override {
        if (!superRegistry.isValidStateRegistry(msg.sender)) {
            revert Error.INVALID_CALLER();
        }

        uint64 chainId = ambChainId[dstChainId_];

        /// calculate the exact fee needed
        uint256 feesReq = messageBus.calcFee(message_);
        /// FIXME: works only on EVM-networks & contracts using CREATE2/CREATE3
        messageBus.sendMessage{value: feesReq}(authorizedImpl[chainId], chainId, message_);

        /// Refund unused fees
        /// NOTE: check security implications here
        (bool success, ) = payable(srcSender_).call{value: msg.value - feesReq}("");

        if (!success) {
            revert Error.GAS_REFUND_FAILED();
        }
    }

    /// @inheritdoc IAmbImplementation
    function broadcastPayload(
        address srcSender_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable virtual {
        if (!superRegistry.isValidStateRegistry(msg.sender)) {
            revert Error.INVALID_CALLER();
        }

        BroadCastAMBExtraData memory d = abi.decode(extraData_, (BroadCastAMBExtraData));
        /// FIXME:should we check the length ?? anyway out of index will fail if the length
        /// mistmatches
        uint256 totalChains = broadcastChains.length;

        /// calculate the exact fee needed
        uint256 feesReq = messageBus.calcFee(message_);
        feesReq = feesReq * totalChains;

        for (uint64 i = 0; i < totalChains; i++) {
            uint64 chainId = broadcastChains[i];

            messageBus.sendMessage{value: d.gasPerDst[i]}(authorizedImpl[chainId], chainId, message_);
        }

        /// Refund unused fees
        /// NOTE: check security implications here
        (bool success, ) = payable(srcSender_).call{value: msg.value - feesReq}("");

        if (!success) {
            revert Error.GAS_REFUND_FAILED();
        }
    }

    /// @dev allows protocol admin to configure new chain id
    /// @param superChainId_ is the identifier of the chain within superform protocol
    /// @param ambChainId_ is the identifier of the chain given by the AMB
    /// NOTE: cannot be defined in an interface as types vary for each message bridge (amb)
    function setChainId(uint64 superChainId_, uint64 ambChainId_) external onlyProtocolAdmin {
        if (superChainId_ == 0 || ambChainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        ambChainId[superChainId_] = ambChainId_;
        superChainId[ambChainId_] = superChainId_;

        /// FIXME: @dev should handle a way to pop
        broadcastChains.push(ambChainId_);

        emit ChainAdded(superChainId_);
    }

    /// @dev allows protocol admin to set receiver implmentation on a new chain id
    /// @param dstChainId_ is the identifier of the destination chain in celer
    /// @param authorizedImpl_ is the implementation of the celer message bridge on the specified destination
    /// NOTE: cannot be defined in an interface as types vary for each message bridge (amb)
    function setReceiver(uint64 dstChainId_, address authorizedImpl_) external onlyProtocolAdmin {
        if (dstChainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        if (authorizedImpl_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        authorizedImpl[dstChainId_] = authorizedImpl_;
    }

    /// @inheritdoc IMessageReceiver
    function executeMessage(
        address, /// srcContract_
        uint64 srcChainId_,
        bytes calldata message_,
        address // executor
    ) external payable override returns (ExecutionStatus) {
        /// @dev 1. validate caller
        /// @dev 2. validate src chain sender
        /// @dev 3. validate message uniqueness
        if (msg.sender != address(messageBus)) {
            revert Error.INVALID_CALLER();
        }

        /// FIXME: check why this fails
        // if (sender_ != castAddr(authorizedImpl[origin_])) {
        //     revert INVALID_CALLER();
        // }

        bytes32 hash = keccak256(message_);

        if (processedMessages[hash]) {
            revert Error.DUPLICATE_PAYLOAD();
        }

        processedMessages[hash] = true;

        /// @dev decoding payload
        AMBMessage memory decoded = abi.decode(message_, (AMBMessage));

        /// NOTE: experimental split of registry contracts
        (, , , uint8 registryId, , ) = _decodeTxInfo(decoded.txInfo);
        address registryAddress = superRegistry.getStateRegistry(registryId);
        IBaseStateRegistry targetRegistry = IBaseStateRegistry(registryAddress);

        targetRegistry.receivePayload(superChainId[srcChainId_], message_);
        return ExecutionStatus.Success;
    }
}

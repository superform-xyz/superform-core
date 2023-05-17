// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IMessageBus} from "./interface/IMessageBus.sol";
import {IMessageReceiver} from "./interface/IMessageReceiver.sol";
import {Error} from "../../utils/Error.sol";
import {AMBMessage, BroadCastAMBExtraData} from "../../types/DataTypes.sol";
import "../../utils/DataPacking.sol";

/// @title Celer Implementation Contract
/// @author Zeropoint Labs
///
/// @dev interacts with the Celer AMB
contract CelerImplementation is IAmbImplementation, IMessageReceiver, Ownable {
    error INVALID_RECEIVER();

    /*///////////////////////////////////////////////////////////////
                    State Variables
    //////////////////////////////////////////////////////////////*/
    IMessageBus public immutable messageBus;
    ISuperRegistry public immutable superRegistry;

    uint64[] public broadcastChains;

    mapping(uint16 => uint64) public ambChainId;
    mapping(uint64 => uint16) public superChainId;
    mapping(uint64 => address) public authorizedImpl;

    mapping(bytes32 => bool) public processedMessages;

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
    receive() external payable {}

    /// @dev allows state registry to send message via implementation.
    /// @param dstChainId_ is the identifier of the destination chain
    /// @param message_ is the cross-chain message to be sent
    /// @param extraData_ is message amb specific override information
    function dispatchPayload(
        uint16 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable virtual override {
        if (!superRegistry.isValidStateRegistry(msg.sender)) {
            revert Error.INVALID_CALLER();
        }

        uint64 chainId = ambChainId[dstChainId_];
        /// FIXME: works only on EVM-networks & contracts using CREATE2/CREATE3
        messageBus.sendMessage{value: msg.value}(
            authorizedImpl[chainId],
            chainId,
            message_
        );
    }

    /// @dev allows state registry to send multiple messages via implementation
    /// @param message_ is the cross-chain message to be sent
    /// @param extraData_ is the message amb specific override information
    function broadcastPayload(
        bytes memory message_,
        bytes memory extraData_
    ) external payable virtual {
        if (!superRegistry.isValidStateRegistry(msg.sender)) {
            revert Error.INVALID_CALLER();
        }

        BroadCastAMBExtraData memory d = abi.decode(
            extraData_,
            (BroadCastAMBExtraData)
        );
        /// FIXME:should we check the length ?? anyway out of index will fail if the length
        /// mistmatches

        uint256 totalChains = broadcastChains.length;
        for (uint16 i = 0; i < totalChains; i++) {
            uint64 chainId = broadcastChains[i];

            messageBus.sendMessage{value: d.gasPerDst[i]}(
                authorizedImpl[chainId],
                chainId,
                message_
            );
        }
    }

    /// @notice to add access based controls over here
    /// @dev allows admin to add new chain ids in future
    /// @param superChainId_ is the identifier of the chain within superform protocol
    /// @param ambChainId_ is the identifier of the chain given by the AMB
    function setChainId(
        uint16 superChainId_,
        uint64 ambChainId_
    ) external onlyOwner {
        if (superChainId_ == 0 || ambChainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        ambChainId[superChainId_] = ambChainId_;
        superChainId[ambChainId_] = superChainId_;

        /// NOTE: @dev should handle a way to pop
        broadcastChains.push(ambChainId_);

        emit ChainAdded(superChainId_);
    }

    function setReceiver(
        uint64 dstChainId_,
        address authorizedImpl_
    ) external onlyOwner {
        if (dstChainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        if (authorizedImpl_ == address(0)) {
            revert INVALID_RECEIVER();
        }

        authorizedImpl[dstChainId_] = authorizedImpl_;
    }

    /// @notice Handle an interchain message
    /// @notice Only called by mailbox
    ///
    /// @param srcChainId_ ChainId ID of the chain from which the message came
    /// @param srcContract_ Address of the message sender on the origin chain
    /// @param message_ Raw bytes content of message body
    function executeMessage(
        address srcContract_,
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
        (, , , uint8 registryId) = _decodeTxInfo(decoded.txInfo);
        address registryAddress = superRegistry.getStateRegistry(registryId);
        IBaseStateRegistry targetRegistry = IBaseStateRegistry(registryAddress);

        targetRegistry.receivePayload(superChainId[srcChainId_], message_);
        return ExecutionStatus.Success;
    }

    /*///////////////////////////////////////////////////////////////
                    Internal Functions
    //////////////////////////////////////////////////////////////*/
}

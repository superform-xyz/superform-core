// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IBaseStateRegistry} from "../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../interfaces/IAmbImplementation.sol";
import {PayloadState, AMBMessage, AMBFactoryMessage} from "../types/DataTypes.sol";
import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {Error} from "../utils/Error.sol";
import "../utils/DataPacking.sol";

import "forge-std/console.sol";

/// @title Cross-Chain AMB (Arbitrary Message Bridge) Aggregator Base
/// @author Zeropoint Labs
/// @notice stores, sends & process message sent via various messaging ambs.
abstract contract BaseStateRegistry is IBaseStateRegistry {
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public payloadsCount;

    mapping(bytes => uint256) public messageQuorum;
    /// @dev stores all received payloads after assigning them an unique identifier upon receiving.
    mapping(uint256 => bytes) public payload;
    /// @dev maps payloads to their status
    mapping(uint256 => PayloadState) public payloadTracking;

    ISuperRegistry public immutable superRegistry;

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyProtocolAdmin() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(
                msg.sender
            )
        ) revert Error.NOT_PROTOCOL_ADMIN();
        _;
    }

    modifier onlyProcessor() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasProcessorRole(msg.sender))
            revert Error.NOT_PROCESSOR();
        _;
    }

    modifier onlyUpdater() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasUpdaterRole(msg.sender))
            revert Error.NOT_UPDATER();
        _;
    }

    modifier onlyCoreContracts() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasCoreContractsRole(
                msg.sender
            )
        ) revert Error.NOT_CORE_CONTRACTS();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    ///@dev set up admin during deployment.
    constructor(ISuperRegistry superRegistry_) {
        superRegistry = superRegistry_;
    }

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    receive() external payable {}

    /// @dev allows core contracts to send data to a destination chain.
    /// @param ambId_ is the identifier of the message amb to be used.
    /// @param dstChainId_ is the internal chainId used throughtout the protocol.
    /// @param message_ is the crosschain data to be sent.
    /// @param extraData_ defines all the message amb specific information.
    /// NOTE: dstChainId maps with the message amb's propreitory chain Id.
    function dispatchPayload(
        uint8 ambId_,
        uint8[] memory secAmbId_,
        uint16 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable virtual override onlyCoreContracts {
        _dispatchPayload(ambId_, dstChainId_, message_, extraData_);
        _dispatchProof(ambId_, secAmbId_, dstChainId_, message_, extraData_);
    }

    /// @dev allows core contracts to send data to all available destination chains
    function broadcastPayload(
        uint8 ambId_,
        uint8[] memory secAmbId_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable virtual override onlyCoreContracts {
        _broadcastPayload(ambId_, message_, extraData_);
        _broadcastProof(ambId_, secAmbId_, message_, extraData_);
    }

    /// @dev allows state registry to receive messages from amb implementations.
    /// @param srcChainId_ is the internal chainId from which the data is sent.
    /// @param message_ is the crosschain data received.
    /// NOTE: Only {IMPLEMENTATION_CONTRACT} role can call this function.
    function receivePayload(
        uint16 srcChainId_,
        bytes memory message_
    ) external virtual override {
        AMBMessage memory data = abi.decode(message_, (AMBMessage));

        if (data.params.length == 32) {
            /// assuming 32 bytes length is always proof
            /// @dev should validate this later
            messageQuorum[data.params] += 1;

            emit ProofReceived(data.params);
        } else {
            ++payloadsCount;
            payload[payloadsCount] = message_;

            emit PayloadReceived(
                srcChainId_,
                superRegistry.chainId(),
                payloadsCount
            );
        }
    }

    /// @dev allows accounts with {PROCESSOR_ROLE} to process any successful cross-chain payload.
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// NOTE: function can only process successful payloads.
    function processPayload(
        uint256 payloadId_
    ) external payable virtual override onlyProcessor {}

    /// @dev allows accounts with {PROCESSOR_ROLE} to revert Error.payload that fail to revert Error.state changes on source chain.
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @param ambId_ is the identifier of the cross-chain amb to be used to send the acknowledgement.
    /// @param extraData_ is any message amb specific override information.
    /// NOTE: function can only process failing payloads.
    function revertPayload(
        uint256 payloadId_,
        uint256 ambId_,
        bytes memory extraData_
    ) external payable virtual override onlyProcessor {}

    function _dispatchPayload(
        uint8 ambId_,
        uint16 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) internal {
        IAmbImplementation ambImplementation = IAmbImplementation(
            superRegistry.getAmbAddress(ambId_)
        );

        if (address(ambImplementation) == address(0)) {
            revert Error.INVALID_BRIDGE_ID();
        }
        console.log("sending to dst", dstChainId_);
        ambImplementation.dispatchPayload{value: msg.value / 2}(
            dstChainId_,
            message_,
            extraData_
        );
    }

    function _dispatchProof(
        uint8 ambId_,
        uint8[] memory secAmbId_,
        uint16 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) internal {
        /// @dev generates the proof
        bytes memory proof = abi.encode(keccak256(message_));

        AMBMessage memory data = abi.decode(message_, (AMBMessage));
        data.params = proof;

        for (uint8 i = 0; i < secAmbId_.length; i++) {
            uint8 tempAmbId = secAmbId_[i];

            if (tempAmbId == ambId_) {
                revert Error.INVALID_PROOF_BRIDGE_ID();
            }

            IAmbImplementation tempImpl = IAmbImplementation(
                superRegistry.getAmbAddress(ambId_)
            );

            if (address(tempImpl) == address(0)) {
                revert Error.INVALID_BRIDGE_ID();
            }

            /// @dev should figure out how to split message costs
            /// @notice for now works if the secAmbId loop lenght == 1
            tempImpl.dispatchPayload{value: msg.value / 2}(
                dstChainId_,
                abi.encode(data),
                extraData_
            );
        }
    }

    function _broadcastPayload(
        uint8 ambId_,
        bytes memory message_,
        bytes memory extraData_
    ) internal {
        AMBMessage memory newData = AMBMessage(
            _packTxInfo(0, 0, false, 1),
            message_
        );

        IAmbImplementation ambImplementation = IAmbImplementation(
            superRegistry.getAmbAddress(ambId_)
        );

        if (address(ambImplementation) == address(0)) {
            revert Error.INVALID_BRIDGE_ID();
        }

        ambImplementation.broadcastPayload{value: msg.value / 2}(
            abi.encode(newData),
            extraData_
        );
    }

    function _broadcastProof(
        uint8 ambId_,
        uint8[] memory secAmbId_,
        bytes memory message_,
        bytes memory extraData_
    ) internal {
        /// @dev generates the proof
        bytes memory proof = abi.encode(keccak256(message_));
        AMBMessage memory newData = AMBMessage(
            _packTxInfo(0, 0, false, 1),
            proof
        );

        for (uint8 i = 0; i < secAmbId_.length; i++) {
            uint8 tempAmbId = secAmbId_[i];

            if (tempAmbId == ambId_) {
                revert Error.INVALID_PROOF_BRIDGE_ID();
            }

            IAmbImplementation tempImpl = IAmbImplementation(
                superRegistry.getAmbAddress(ambId_)
            );

            if (address(tempImpl) == address(0)) {
                revert Error.INVALID_BRIDGE_ID();
            }

            /// @dev should figure out how to split message costs
            /// @notice for now works if the secAmbId loop lenght == 1
            tempImpl.broadcastPayload{value: msg.value / 2}(
                abi.encode(newData),
                extraData_
            );
        }
    }
}

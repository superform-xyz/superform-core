// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "forge-std/console.sol";
import {IBaseStateRegistry} from "../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../interfaces/IAmbImplementation.sol";
import {PayloadState, AMBMessage, AMBFactoryMessage, AMBExtraData} from "../types/DataTypes.sol";
import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {Error} from "../utils/Error.sol";
import "../utils/DataPacking.sol";

/// @title Cross-Chain AMB (Arbitrary Message Bridge) Aggregator Base
/// @author Zeropoint Labs
/// @notice stores, sends & process message sent via various messaging ambs.
abstract contract BaseStateRegistry is IBaseStateRegistry {
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev superformChainid
    uint16 public immutable chainId;
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
    constructor(uint16 chainId_, ISuperRegistry superRegistry_) {
        if (chainId_ == 0) revert Error.INVALID_INPUT_CHAIN_ID();

        chainId = chainId_;
        superRegistry = superRegistry_;
    }

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    receive() external payable {}

    /// @dev allows core contracts to send data to a destination chain.
    /// @param ambIds_ is the identifier of the message amb to be used.
    /// @param dstChainId_ is the internal chainId used throughtout the protocol.
    /// @param message_ is the crosschain data to be sent.
    /// @param extraData_ defines all the message amb specific information.
    /// NOTE: dstChainId maps with the message amb's propreitory chain Id.
    function dispatchPayload(
        uint8[] memory ambIds_,
        uint16 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable virtual override onlyCoreContracts {
        _dispatchPayload(ambIds_[0], dstChainId_, message_, extraData_);
        _dispatchProof(ambIds_, dstChainId_, message_, extraData_);
    }

    /// @dev allows core contracts to send data to all available destination chains
    function broadcastPayload(
        uint8[] memory ambIds_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable virtual override onlyCoreContracts {
        _broadcastPayload(ambIds_[0], message_, extraData_);
        _broadcastProof(ambIds_, message_, extraData_);
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

            emit PayloadReceived(srcChainId_, chainId, payloadsCount);
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

        AMBExtraData memory d = abi.decode(extraData_, (AMBExtraData));

        ambImplementation.dispatchPayload{value: d.ambGas[0]}(
            dstChainId_,
            message_,
            d.ambExtraData[0]
        );
    }

    function _dispatchProof(
        uint8[] memory ambIds_,
        uint16 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) internal {
        /// @dev generates the proof
        bytes memory proof = abi.encode(keccak256(message_));

        AMBMessage memory data = abi.decode(message_, (AMBMessage));
        AMBExtraData memory ambData = abi.decode(extraData_, (AMBExtraData));

        data.params = proof;

        for (uint8 i = 1; i < ambIds_.length; i++) {
            uint8 tempAmbId = ambIds_[i];

            if (tempAmbId == ambIds_[0]) {
                revert Error.INVALID_PROOF_BRIDGE_ID();
            }

            IAmbImplementation tempImpl = IAmbImplementation(
                superRegistry.getAmbAddress(tempAmbId)
            );

            if (address(tempImpl) == address(0)) {
                revert Error.INVALID_BRIDGE_ID();
            }

            /// @dev should figure out how to split message costs
            /// @notice for now works if the secAmbId loop lenght == 1
            tempImpl.dispatchPayload{value: ambData.ambGas[i]}(
                dstChainId_,
                abi.encode(data),
                ambData.ambExtraData[i]
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
        AMBExtraData memory ambData = abi.decode(extraData_, (AMBExtraData));

        ambImplementation.broadcastPayload{value: ambData.ambGas[0]}(
            abi.encode(newData),
            ambData.ambExtraData[0]
        );
    }

    function _broadcastProof(
        uint8[] memory ambIds_,
        bytes memory message_,
        bytes memory extraData_
    ) internal {
        /// @dev generates the proof
        bytes memory proof = abi.encode(keccak256(message_));
        AMBMessage memory newData = AMBMessage(
            _packTxInfo(0, 0, false, 1),
            proof
        );
        AMBExtraData memory ambData = abi.decode(extraData_, (AMBExtraData));

        for (uint8 i = 1; i < ambIds_.length; i++) {
            uint8 tempAmbId = ambIds_[i];

            if (tempAmbId == ambIds_[0]) {
                revert Error.INVALID_PROOF_BRIDGE_ID();
            }

            IAmbImplementation tempImpl = IAmbImplementation(
                superRegistry.getAmbAddress(tempAmbId)
            );

            if (address(tempImpl) == address(0)) {
                revert Error.INVALID_BRIDGE_ID();
            }

            /// @dev should figure out how to split message costs
            /// @notice for now works if the secAmbId loop lenght == 1
            tempImpl.broadcastPayload{value: ambData.ambGas[i]}(
                abi.encode(newData),
                ambData.ambExtraData[i]
            );
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IBaseStateRegistry} from "../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../interfaces/IAmbImplementation.sol";
import {PayloadState, AMBMessage, AMBFactoryMessage, AMBExtraData} from "../types/DataTypes.sol";
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
        /// @dev atleast 2 AMBs are required
        if (ambIds_.length < 2) {
            revert Error.INVALID_AMB_IDS_LENGTH();
        }

        AMBExtraData memory d = abi.decode(extraData_, (AMBExtraData));

        _dispatchPayload(
            ambIds_[0],
            dstChainId_,
            d.gasPerAMB[0],
            message_,
            d.extraDataPerAMB[0]
        );

        _dispatchProof(
            ambIds_,
            dstChainId_,
            d.gasPerAMB,
            message_,
            d.extraDataPerAMB
        );
    }

    /// @dev allows core contracts to send data to all available destination chains
    function broadcastPayload(
        uint8[] memory ambIds_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable virtual override onlyCoreContracts {
        /// @dev atleast 2 AMBs are required
        if (ambIds_.length < 2) {
            revert Error.INVALID_AMB_IDS_LENGTH();
        }

        AMBExtraData memory d = abi.decode(extraData_, (AMBExtraData));

        _broadcastPayload(
            ambIds_[0],
            d.gasPerAMB[0],
            message_,
            d.extraDataPerAMB[0]
        );
        _broadcastProof(ambIds_, d.gasPerAMB, message_, d.extraDataPerAMB);
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
    /// @param ambOverride_ override data for AMBs to process acknowledgements.
    /// NOTE: function can only process successful payloads.
    function processPayload(
        uint256 payloadId_,
        bytes memory ambOverride_
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
        uint256 gasToPay_,
        bytes memory message_,
        bytes memory overrideData_
    ) internal {
        IAmbImplementation ambImplementation = IAmbImplementation(
            superRegistry.getAmbAddress(ambId_)
        );

        if (address(ambImplementation) == address(0)) {
            revert Error.INVALID_BRIDGE_ID();
        }

        ambImplementation.dispatchPayload{value: gasToPay_}(
            dstChainId_,
            message_,
            overrideData_
        );
    }

    function _dispatchProof(
        uint8[] memory ambIds_,
        uint16 dstChainId_,
        uint256[] memory gasToPay_,
        bytes memory message_,
        bytes[] memory overrideData_
    ) internal {
        bytes memory proof = abi.encode(keccak256(message_));

        AMBMessage memory data = abi.decode(message_, (AMBMessage));
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

            tempImpl.dispatchPayload{value: gasToPay_[i]}(
                dstChainId_,
                abi.encode(data),
                overrideData_[i]
            );
        }
    }

    function _broadcastPayload(
        uint8 ambId_,
        uint256 gasToPay_,
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

        ambImplementation.broadcastPayload{value: gasToPay_}(
            abi.encode(newData),
            extraData_
        );
    }

    function _broadcastProof(
        uint8[] memory ambIds_,
        uint256[] memory gasToPay_,
        bytes memory message_,
        bytes[] memory extraData_
    ) internal {
        /// @dev generates the proof
        bytes memory proof = abi.encode(keccak256(message_));
        AMBMessage memory newData = AMBMessage(
            _packTxInfo(0, 0, false, 1),
            proof
        );

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

            tempImpl.broadcastPayload{value: gasToPay_[i]}(
                abi.encode(newData),
                extraData_[i]
            );
        }
    }
}

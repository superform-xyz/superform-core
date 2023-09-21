// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import { Error } from "../utils/Error.sol";
import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";
import { IBaseStateRegistry } from "../interfaces/IBaseStateRegistry.sol";
import { IAmbImplementation } from "../interfaces/IAmbImplementation.sol";
import { PayloadState, AMBMessage, AMBExtraData } from "../types/DataTypes.sol";
import { ProofLib } from "../libraries/ProofLib.sol";

/// @title BaseStateRegistry
/// @author Zeropoint Labs
/// @dev contract module that allows inheriting contracts to implement crosschain messaging & processing mechanisms.
/// @dev This is a lightweight version that allows only dispatching and receiving crosschain
/// @dev payloads (messages). Inheriting children contracts have the flexibility to define their own processing
/// mechanisms.
abstract contract BaseStateRegistry is IBaseStateRegistry {
    using ProofLib for AMBMessage;
    using ProofLib for bytes;

    /*///////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public immutable superRegistry;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 public payloadsCount;

    /// @dev stores received payload after assigning them an unique identifier upon receiving
    mapping(uint256 => bytes) public payloadBody;

    /// @dev stores received payload's header (txInfo)
    mapping(uint256 => uint256) public payloadHeader;

    /// @dev stores a proof's quorum
    mapping(bytes32 => uint256) public messageQuorum;

    /// @dev maps payloads to their current status
    mapping(uint256 => PayloadState) public payloadTracking;

    /// @dev maps payloads to the amb ids that delivered them
    mapping(uint256 => uint8) public msgAMB;

    /// @dev maps payloads to the amb ids that delivered them
    mapping(bytes32 => uint8[]) internal proofAMB;

    /// @dev sender varies based on functionality
    /// @notice inheriting contracts should override this function (else not safe)
    modifier onlySender() virtual {
        _;
    }

    /*///////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(ISuperRegistry superRegistry_) {
        superRegistry = superRegistry_;
    }

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    receive() external payable { }

    /// @inheritdoc IBaseStateRegistry
    function dispatchPayload(
        address srcSender_,
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        payable
        override
        onlySender
    {
        AMBExtraData memory d = abi.decode(extraData_, (AMBExtraData));

        _dispatchPayload(srcSender_, ambIds_[0], dstChainId_, d.gasPerAMB[0], message_, d.extraDataPerAMB[0]);

        if (ambIds_.length > 1) {
            _dispatchProof(srcSender_, ambIds_, dstChainId_, d.gasPerAMB, message_, d.extraDataPerAMB);
        }
    }

    /// @inheritdoc IBaseStateRegistry
    function receivePayload(uint64 srcChainId_, bytes memory message_) external override {
        if (!superRegistry.isValidAmbImpl(msg.sender)) {
            revert Error.NOT_AMB_IMPLEMENTATION();
        }

        AMBMessage memory data = abi.decode(message_, (AMBMessage));

        /// @dev proofHash will always be 32 bytes length due to keccak256
        if (data.params.length == 32) {
            bytes32 proofHash = abi.decode(data.params, (bytes32));
            ++messageQuorum[proofHash];

            proofAMB[proofHash].push(_getAmbId(msg.sender));

            emit ProofReceived(data.params);
        } else {
            /// @dev if message, store header and body of it
            ++payloadsCount;

            payloadBody[payloadsCount] = data.params;
            payloadHeader[payloadsCount] = data.txInfo;

            msgAMB[payloadsCount] = _getAmbId(msg.sender);

            emit PayloadReceived(srcChainId_, uint64(block.chainid), payloadsCount);
        }
    }

    /// @inheritdoc IBaseStateRegistry
    function processPayload(uint256 payloadId_) external payable virtual override;

    /// @inheritdoc IBaseStateRegistry
    function getProofAMB(bytes32 proof_) external view override returns (uint8[] memory) {
        return proofAMB[proof_];
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the amb id for address
    function _getAmbId(address amb_) internal view returns (uint8 ambId) {
        return superRegistry.getAmbId(amb_);
    }

    /// @dev returns the amb id for address
    function _getAmbAddress(uint8 id_) internal view returns (address amb) {
        return superRegistry.getAmbAddress(id_);
    }

    /// @dev dispatches the payload(message_) through individual message bridge implementations
    function _dispatchPayload(
        address srcSender_,
        uint8 ambId_,
        uint64 dstChainId_,
        uint256 gasToPay_,
        bytes memory message_,
        bytes memory overrideData_
    )
        internal
    {
        IAmbImplementation ambImplementation = IAmbImplementation(_getAmbAddress(ambId_));

        /// @dev revert if an unknown amb id is used
        if (address(ambImplementation) == address(0)) {
            revert Error.INVALID_BRIDGE_ID();
        }

        ambImplementation.dispatchPayload{ value: gasToPay_ }(srcSender_, dstChainId_, message_, overrideData_);
    }

    /// @dev dispatches the proof(hash of the message_) through individual message bridge implementations
    function _dispatchProof(
        address srcSender_,
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        uint256[] memory gasToPay_,
        bytes memory message_,
        bytes[] memory overrideData_
    )
        internal
    {
        AMBMessage memory data = abi.decode(message_, (AMBMessage));
        data.params = message_.computeProofBytes();

        uint256 len = ambIds_.length;
        /// @dev i starts from 1 since 0 is primary amb id which dispatches the message itself
        for (uint8 i = 1; i < len;) {
            uint8 tempAmbId = ambIds_[i];

            if (tempAmbId == ambIds_[0]) {
                revert Error.INVALID_PROOF_BRIDGE_ID();
            }

            if (i - 1 > 0 && tempAmbId <= ambIds_[i - 1]) {
                revert Error.DUPLICATE_PROOF_BRIDGE_ID();
            }

            IAmbImplementation tempImpl = IAmbImplementation(_getAmbAddress(tempAmbId));

            if (address(tempImpl) == address(0)) {
                revert Error.INVALID_BRIDGE_ID();
            }

            /// @dev proof is dispatched in the form of a payload
            tempImpl.dispatchPayload{ value: gasToPay_[i] }(srcSender_, dstChainId_, abi.encode(data), overrideData_[i]);

            unchecked {
                ++i;
            }
        }
    }
}

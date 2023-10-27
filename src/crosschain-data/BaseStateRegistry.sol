// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { Error } from "../utils/Error.sol";
import { IQuorumManager } from "../interfaces/IQuorumManager.sol";
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
    uint64 public immutable CHAIN_ID;

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
    mapping(uint256 => uint8[]) internal msgAMBs;

    /// @dev sender varies based on functionality
    /// @notice inheriting contracts should override this function (else not safe)
    modifier onlySender() virtual {
        _;
    }

    /*///////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(ISuperRegistry superRegistry_) {
        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }

        CHAIN_ID = uint64(block.chainid);
        superRegistry = superRegistry_;
    }

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

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
        _dispatchPayload(srcSender_, ambIds_, dstChainId_, message_, extraData_);
    }

    function _dispatchPayload(
        address srcSender_,
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    )
        internal
    {
        /// @dev revert here if quorum requirements might fail on the remote chain
        if (ambIds_.length - 1 < _getQuorum(dstChainId_)) {
            revert Error.INSUFFICIENT_QUORUM();
        }

        AMBExtraData memory d = abi.decode(extraData_, (AMBExtraData));

        AMBMessage memory ambEncodedMessage = abi.decode(message_, (AMBMessage));
        ambEncodedMessage.params = abi.encode(ambIds_, ambEncodedMessage.params);

        _getAMBImpl(ambIds_[0]).dispatchPayload{ value: d.gasPerAMB[0] }(
            srcSender_, dstChainId_, abi.encode(ambEncodedMessage), d.extraDataPerAMB[0]
        );

        uint256 len = ambIds_.length;

        if (len > 1) {
            AMBMessage memory data = abi.decode(message_, (AMBMessage));
            data.params = message_.computeProofBytes();

            /// @dev i starts from 1 since 0 is primary amb id which dispatches the message itself
            for (uint8 i = 1; i < len;) {
                if (ambIds_[i] == ambIds_[0]) {
                    revert Error.INVALID_PROOF_BRIDGE_ID();
                }

                if (i - 1 > 0 && ambIds_[i] <= ambIds_[i - 1]) {
                    revert Error.DUPLICATE_PROOF_BRIDGE_ID();
                }

                /// @dev proof is dispatched in the form of a payload
                _getAMBImpl(ambIds_[i]).dispatchPayload{ value: d.gasPerAMB[i] }(
                    srcSender_, dstChainId_, abi.encode(data), d.extraDataPerAMB[i]
                );

                unchecked {
                    ++i;
                }
            }
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

            emit ProofReceived(data.params);
        } else {
            /// @dev if message, store header and body of it
            ++payloadsCount;

            payloadHeader[payloadsCount] = data.txInfo;
            (msgAMBs[payloadsCount], payloadBody[payloadsCount]) = abi.decode(data.params, (uint8[], bytes));

            emit PayloadReceived(srcChainId_, CHAIN_ID, payloadsCount);
        }
    }

    /// @inheritdoc IBaseStateRegistry
    function processPayload(uint256 payloadId_) external payable virtual override;

    /// @inheritdoc IBaseStateRegistry
    function getMessageAMB(uint256 payloadId_) external view override returns (uint8[] memory) {
        return msgAMBs[payloadId_];
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the required quorum for the src chain id from super registry
    /// @param chainId_ is the src chain id
    /// @return the quorum configured for the chain id
    function _getQuorum(uint64 chainId_) internal view returns (uint256) {
        return IQuorumManager(address(superRegistry)).getRequiredMessagingQuorum(chainId_);
    }

    /// @dev returns the amb id for address
    function _getAmbAddress(uint8 id_) internal view returns (address amb) {
        return superRegistry.getAmbAddress(id_);
    }

    function _getAMBImpl(uint8 id_) internal view returns (IAmbImplementation ambImplementation) {
        ambImplementation = IAmbImplementation(_getAmbAddress(id_));

        /// @dev revert if an unknown amb id is used
        if (address(ambImplementation) == address(0)) {
            revert Error.INVALID_BRIDGE_ID();
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { IBroadcastRegistry } from "src/interfaces/IBroadcastRegistry.sol";
import { IBroadcastAmbImplementation } from "src/interfaces/IBroadcastAmbImplementation.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { Error } from "src/utils/Error.sol";
import { IWormhole } from "src/vendor/wormhole/IWormhole.sol";
import { DataLib } from "src/libraries/DataLib.sol";

/// @title WormholeImplementation
/// @author Zeropoint Labs
/// @notice allows broadcast state registry contracts to send messages to multiple chains
/// @dev uses multicast of wormhole for broadcasting
contract WormholeSRImplementation is IBroadcastAmbImplementation {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public immutable superRegistry;
    IWormhole public wormhole;
    address public relayer;

    uint8 public broadcastFinality;

    mapping(uint64 => uint16) public ambChainId;
    mapping(uint16 => uint64) public superChainId;
    mapping(uint16 => address) public authorizedImpl;
    mapping(bytes32 => bool) public processedMessages;

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param superRegistry_ is super registry address for respective chain
    constructor(ISuperRegistry superRegistry_) {
        superRegistry = superRegistry_;
    }

    /*///////////////////////////////////////////////////////////////
                            WORMHOLE APPLICATION CONFIG
    //////////////////////////////////////////////////////////////*/

    /// @dev allows protocol admin to configure wormhole core contract
    /// @param wormhole_ is wormhole address for respective chain
    function setWormholeCore(address wormhole_) external onlyProtocolAdmin {
        if (wormhole_ == address(0)) revert Error.ZERO_ADDRESS();
        if (address(wormhole) == address(0)) {
            wormhole = IWormhole(wormhole_);
        }
    }

    /// @dev allows protocol admin to configure relayer (superform owned)
    /// @param relayer_ is superform deployed relayer address
    function setRelayer(address relayer_) external onlyProtocolAdmin {
        if (relayer_ == address(0)) revert Error.ZERO_ADDRESS();
        relayer = relayer_;
    }

    /// @dev allows protocol admin to set broadcast finality
    /// @param finality_ is the required finality on src chain
    function setFinality(uint8 finality_) external onlyProtocolAdmin {
        if (finality_ == 0) {
            revert Error.INVALID_BROADCAST_FINALITY();
        }

        broadcastFinality = finality_;
    }

    /*///////////////////////////////////////////////////////////////
                                EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBroadcastAmbImplementation
    function broadcastPayload(
        address, /*srcSender_*/
        bytes memory message_,
        bytes memory /*extraData_*/
    )
        external
        payable
        virtual
    {
        if (!superRegistry.isValidStateRegistry(msg.sender)) {
            revert Error.NOT_STATE_REGISTRY();
        }

        /// @dev is wormhole's inherent fee for sending a message
        uint256 msgFee = wormhole.messageFee();

        if (msg.value < msgFee) {
            revert Error.CROSS_CHAIN_TX_UNDERPAID();
        }

        wormhole.publishMessage{ value: msgFee }(
            0,
            /// batch id
            message_,
            broadcastFinality
        );

        if (relayer == address(0)) {
            revert Error.RELAYER_NOT_SET();
        }

        /// @dev forwards the rest to superform relayer
        (bool success,) = payable(relayer).call{ value: msg.value - msgFee }("");

        if (!success) {
            revert Error.NATIVE_TOKEN_TRANSFER_FAILURE();
        }
    }

    function receiveMessage(bytes memory encodedMessage_) public {
        /// @dev 1. validate caller
        /// @dev 2. validate not broadcasted to emitter chain
        /// @dev 3. validate src chain sender
        /// @dev 4. validate message uniqueness
        if (
            !ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasRole(
                keccak256("WORMHOLE_VAA_RELAYER_ROLE"), msg.sender
            )
        ) {
            revert Error.CALLER_NOT_RELAYER();
        }

        (IWormhole.VM memory wormholeMessage, bool valid,) = wormhole.parseAndVerifyVM(encodedMessage_);

        if (!valid) {
            revert Error.INVALID_BROADCAST_PAYLOAD();
        }

        if (wormholeMessage.emitterChainId == wormhole.chainId()) {
            revert Error.INVALID_SRC_CHAIN_ID();
        }

        if (_bytes32ToAddress(wormholeMessage.emitterAddress) != authorizedImpl[wormholeMessage.emitterChainId]) {
            revert Error.INVALID_SRC_SENDER();
        }

        if (processedMessages[wormholeMessage.hash]) {
            revert Error.DUPLICATE_PAYLOAD();
        }

        processedMessages[wormholeMessage.hash] = true;

        /// @dev decoding payload
        IBroadcastRegistry targetRegistry = IBroadcastRegistry(superRegistry.getStateRegistry(3));
        targetRegistry.receiveBroadcastPayload(superChainId[wormholeMessage.emitterChainId], wormholeMessage.payload);
    }

    /// @dev allows protocol admin to add new chain ids in future
    /// @param superChainId_ is the identifier of the chain within superform protocol
    /// @param ambChainId_ is the identifier of the chain given by the AMB
    /// NOTE: cannot be defined in an interface as types vary for each message bridge (amb)
    function setChainId(uint64 superChainId_, uint16 ambChainId_) external onlyProtocolAdmin {
        if (superChainId_ == 0 || ambChainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        /// @dev  reset old mappings
        uint64 oldSuperChainId = superChainId[ambChainId_];
        uint16 oldAmbChainId = ambChainId[superChainId_];

        if (oldSuperChainId != 0) {
            delete ambChainId[oldSuperChainId];
        }

        if (oldAmbChainId != 0) {
            delete superChainId[oldAmbChainId];
        }

        ambChainId[superChainId_] = ambChainId_;
        superChainId[ambChainId_] = superChainId_;

        emit ChainAdded(superChainId_);
    }

    /// @dev allows protocol admin to set receiver implmentation on a new chain id
    /// @param chainId_ is the identifier of the destination chain within wormhole
    /// @param authorizedImpl_ is the implementation of the wormhole message bridge on the specified destination
    /// NOTE: cannot be defined in an interface as types vary for each message bridge (amb)
    function setReceiver(uint16 chainId_, address authorizedImpl_) external onlyProtocolAdmin {
        if (chainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        if (authorizedImpl_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        authorizedImpl[chainId_] = authorizedImpl_;
        emit AuthorizedImplAdded(chainId_, authorizedImpl_);
    }

    /*///////////////////////////////////////////////////////////////
                    READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBroadcastAmbImplementation
    function estimateFees(
        bytes memory, /*message_*/
        bytes memory /*extraData_*/
    )
        external
        view
        override
        returns (uint256 fees)
    {
        return wormhole.messageFee();
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev casts a bytes32 string to address
    /// @param buf_ is the bytes32 string to be casted
    /// @return a address variable of the address passed in params
    function _bytes32ToAddress(bytes32 buf_) internal pure returns (address) {
        return address(uint160(uint256(buf_)));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { AMBMessage } from "src/types/DataTypes.sol";
import { Error } from "src/libraries/Error.sol";
import { ILayerZeroReceiver } from "src/vendor/layerzero/ILayerZeroReceiver.sol";
import { ILayerZeroUserApplicationConfig } from "src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol";
import { ILayerZeroEndpoint } from "src/vendor/layerzero/ILayerZeroEndpoint.sol";
import { DataLib } from "src/libraries/DataLib.sol";

/// @title LayerzeroImplementation
/// @author Zeropoint Labs
/// @dev allows state registries to use Layerzero for crosschain communication
contract LayerzeroImplementation is IAmbImplementation, ILayerZeroUserApplicationConfig, ILayerZeroReceiver {
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                         //
    //////////////////////////////////////////////////////////////

    ISuperRegistry public immutable superRegistry;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    ILayerZeroEndpoint public lzEndpoint;

    /// @dev prevents layerzero relayer from replaying payload
    mapping(uint16 => mapping(uint64 => bool)) public isValid;
    mapping(uint64 => uint16) public ambChainId;
    mapping(uint16 => uint64) public superChainId;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    event EndpointUpdated(address oldEndpoint_, address newEndpoint_);
    event MessageFailed(uint16 srcChainId_, bytes srcAddress_, uint64 nonce_, bytes payload_);
    event SetTrustedRemote(uint16 srcChainId_, bytes srcAddress_);

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    modifier onlyEmergencyAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasEmergencyAdminRole(msg.sender)) {
            revert Error.NOT_EMERGENCY_ADMIN();
        }
        _;
    }

    modifier onlyValidStateRegistry() {
        if (!superRegistry.isValidStateRegistry(msg.sender)) {
            revert Error.NOT_STATE_REGISTRY();
        }
        _;
    }

    modifier onlyLzEndpoint() {
        // lzReceive must be called by the endpoint for security
        if (msg.sender != address(lzEndpoint)) {
            revert Error.CALLER_NOT_ENDPOINT();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    /// @param superRegistry_ is the super registry address
    constructor(ISuperRegistry superRegistry_) {
        superRegistry = superRegistry_;
    }

    //////////////////////////////////////////////////////////////
    //                         CONFIG                           //
    //////////////////////////////////////////////////////////////

    /// @dev allows protocol admin to configure layerzero endpoint
    /// @param endpoint_ is the layerzero endpoint on the deployed network
    function setLzEndpoint(address endpoint_) external onlyProtocolAdmin {
        if (endpoint_ == address(0)) revert Error.ZERO_ADDRESS();

        if (address(lzEndpoint) == address(0)) {
            lzEndpoint = ILayerZeroEndpoint(endpoint_);
            emit EndpointUpdated(address(0), endpoint_);
        }
    }

    /// @dev returns the configuration of this contract
    function getConfig(
        uint16 version_,
        uint16 chainId_,
        address,
        uint256 configType_
    )
        external
        view
        returns (bytes memory)
    {
        return lzEndpoint.getConfig(version_, chainId_, address(this), configType_);
    }

    /// @dev allows protocol admin to configure UA on layerzero
    function setConfig(
        uint16 version_,
        uint16 chainId_,
        uint256 configType_,
        bytes calldata config_
    )
        external
        override
        onlyProtocolAdmin
    {
        lzEndpoint.setConfig(version_, chainId_, configType_, config_);
    }

    /// @dev allows protocol admin to configure send version on layerzero
    function setSendVersion(uint16 version_) external override onlyProtocolAdmin {
        lzEndpoint.setSendVersion(version_);
    }

    /// @dev allows protocol admin to configure receive version on layerzero
    function setReceiveVersion(uint16 version_) external override onlyProtocolAdmin {
        lzEndpoint.setReceiveVersion(version_);
    }

    /// @dev allows protocol admin to unblock queue of messages if needed
    function forceResumeReceive(uint16 srcChainId_, bytes calldata srcAddress_) external override onlyEmergencyAdmin {
        lzEndpoint.forceResumeReceive(srcChainId_, srcAddress_);
    }

    /// @dev allows protocol admin to set contract which can receive messages
    function setTrustedRemote(uint16 srcChainId_, bytes calldata srcAddress_) external onlyProtocolAdmin {
        trustedRemoteLookup[srcChainId_] = srcAddress_;
        emit SetTrustedRemote(srcChainId_, srcAddress_);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    function isTrustedRemote(uint16 srcChainId_, bytes calldata srcAddress_) external view returns (bool) {
        if (srcChainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }
        return keccak256(trustedRemoteLookup[srcChainId_]) == keccak256(srcAddress_);
    }

    /// @inheritdoc IAmbImplementation
    function estimateFees(
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        view
        override
        returns (uint256 fees)
    {
        uint16 chainId = ambChainId[dstChainId_];

        if (chainId == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        (fees,) = lzEndpoint.estimateFees(chainId, address(this), message_, false, extraData_);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IAmbImplementation
    function dispatchPayload(
        address srcSender_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        payable
        override
        onlyValidStateRegistry
    {
        _lzSend(ambChainId[dstChainId_], message_, payable(srcSender_), address(0x0), extraData_, msg.value);
    }

    /// @inheritdoc IAmbImplementation
    function retryPayload(bytes memory data_) external payable override {
        (uint16 srcChainId, bytes memory srcAddress, bytes memory payload) = abi.decode(data_, (uint16, bytes, bytes));
        lzEndpoint.retryPayload(srcChainId, srcAddress, payload);
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

    /// @inheritdoc ILayerZeroReceiver
    function lzReceive(
        uint16 srcChainId_,
        bytes memory srcAddress_,
        uint64 nonce_,
        bytes memory payload_
    )
        public
        override
        onlyLzEndpoint
    {
        if (isValid[srcChainId_][nonce_]) {
            revert Error.DUPLICATE_PAYLOAD();
        }

        isValid[srcChainId_][nonce_] = true;

        bytes memory trustedRemote = trustedRemoteLookup[srcChainId_];

        if (
            !(
                srcAddress_.length == trustedRemote.length && keccak256(srcAddress_) == keccak256(trustedRemote)
                    && trustedRemote.length != 0
            )
        ) {
            revert Error.INVALID_SRC_SENDER();
        }

        _blockingLzReceive(srcChainId_, srcAddress_, nonce_, payload_);
    }

    function nonblockingLzReceive(uint16 srcChainId_, bytes memory srcAddress_, bytes memory payload_) public {
        // only internal transaction
        if (msg.sender != address(this)) {
            revert Error.INVALID_INTERNAL_CALL();
        }

        _nonblockingLzReceive(srcChainId_, srcAddress_, payload_);
    }

    function retryMessage(
        uint16 srcChainId_,
        bytes memory srcAddress_,
        uint64 nonce_,
        bytes memory payload_
    )
        public
        payable
    {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[srcChainId_][srcAddress_][nonce_];

        if (payloadHash == bytes32(0)) {
            revert Error.ZERO_PAYLOAD_HASH();
        }

        if (keccak256(payload_) != payloadHash) {
            revert Error.INVALID_PAYLOAD_HASH();
        }

        // clear the stored message
        failedMessages[srcChainId_][srcAddress_][nonce_] = bytes32(0);

        // execute the message. revert if it fails again
        _nonblockingLzReceive(srcChainId_, srcAddress_, payload_);
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory, bytes memory _payload) internal {
        /// @dev decodes payload received
        AMBMessage memory decoded = abi.decode(_payload, (AMBMessage));

        /// NOTE: experimental split of registry contracts
        (,,, uint8 registryId,,) = decoded.txInfo.decodeTxInfo();

        IBaseStateRegistry targetRegistry = IBaseStateRegistry(superRegistry.getStateRegistry(registryId));

        targetRegistry.receivePayload(superChainId[_srcChainId], _payload);
    }

    function _lzSend(
        uint16 dstChainId_,
        bytes memory payload_,
        address payable refundAddress_,
        address zroPaymentAddress_,
        bytes memory adapterParams_,
        uint256 msgValue_
    )
        internal
    {
        bytes memory trustedRemote = trustedRemoteLookup[dstChainId_];
        if (trustedRemote.length == 0) {
            revert Error.INVALID_SRC_CHAIN_ID();
        }

        lzEndpoint.send{ value: msgValue_ }(
            dstChainId_, trustedRemote, payload_, refundAddress_, zroPaymentAddress_, adapterParams_
        );
    }

    function _blockingLzReceive(
        uint16 srcChainId_,
        bytes memory srcAddress_,
        uint64 nonce_,
        bytes memory payload_
    )
        internal
    {
        // try-catch all errors/exceptions
        try this.nonblockingLzReceive(srcChainId_, srcAddress_, payload_) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[srcChainId_][srcAddress_][nonce_] = keccak256(payload_);
            emit MessageFailed(srcChainId_, srcAddress_, nonce_, payload_);
        }
    }
}

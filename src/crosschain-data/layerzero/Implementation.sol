// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {ISuperRBAC} from "../../interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {AMBMessage, BroadCastAMBExtraData} from "../../types/DataTypes.sol";
import {Error} from "../../utils/Error.sol";
import {ILayerZeroReceiver} from "./interface/ILayerZeroReceiver.sol";
import {ILayerZeroUserApplicationConfig} from "./interface/ILayerZeroUserApplicationConfig.sol";
import {ILayerZeroEndpoint} from "./interface/ILayerZeroEndpoint.sol";
import "../../utils/DataPacking.sol";

/// @dev FIXME: this contract could use better overrides from interfaces
/// @title Layerzero implementation contract
/// @author Zeropoint Labs.
/// @dev interacts with Layerzero AMB.
contract LayerzeroImplementation is
    IAmbImplementation,
    ILayerZeroUserApplicationConfig,
    ILayerZeroReceiver
{
    uint256 private constant RECEIVER_OFFSET = 1;

    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/
    uint16[] public broadcastChains;
    ISuperRegistry public immutable superRegistry;
    ILayerZeroEndpoint public lzEndpoint;

    /// @dev prevents layerzero relayer from replaying payload
    mapping(uint16 => mapping(uint64 => bool)) public isValid;

    mapping(uint16 => uint16) public ambChainId;
    mapping(uint16 => uint16) public superChainId;

    /*///////////////////////////////////////////////////////////////
                            LZ Variables & events
    //////////////////////////////////////////////////////////////*/

    mapping(uint16 => bytes) public trustedRemoteLookup;

    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32)))
        public failedMessages;

    event MessageFailed(
        uint16 _srcChainId,
        bytes _srcAddress,
        uint64 _nonce,
        bytes _payload
    );

    /*///////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyProtocolAdmin() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(
                msg.sender
            )
        ) revert Error.NOT_PROTOCOL_ADMIN();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    /// @param superRegistry_ is the super registry address
    constructor(ISuperRegistry superRegistry_) {
        superRegistry = superRegistry_;
    }

    /*///////////////////////////////////////////////////////////////
                        Core External Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice receive enables processing native token transfers into the smart contract.
    /// @dev layerzero gas payments/refund fails without a native receive function.
    receive() external payable {}

    /// @dev allows state registry to send message via implementation.
    /// @param dstChainId_ is the identifier of the destination chain
    /// @param message_ is the cross-chain message to be sent
    /// @param extraData_ is message amb specific override information
    function dispatchPayload(
        uint16 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable override {
        if (!superRegistry.isValidStateRegistry(msg.sender)) {
            revert Error.INVALID_CALLER();
        }

        _lzSend(
            ambChainId[dstChainId_],
            message_,
            payable(msg.sender),
            address(0x0),
            extraData_,
            msg.value
        );
    }

    /// @dev allows state registry to send multiple messages via implementation
    /// @param message_ is the cross-chain message to be sent
    /// @param extraData_ is the message amb specific override information
    function broadcastPayload(
        bytes memory message_,
        bytes memory extraData_
    ) external payable {
        if (!superRegistry.isValidStateRegistry(msg.sender)) {
            revert Error.INVALID_CALLER();
        }

        BroadCastAMBExtraData memory d = abi.decode(
            extraData_,
            (BroadCastAMBExtraData)
        );
        /// NOTE:should we check the length ?? anyway out of index will fail if the length
        /// mistmatches

        for (uint16 i = 0; i < broadcastChains.length; i++) {
            uint16 dstChainId = broadcastChains[i];
            _lzSend(
                dstChainId,
                message_,
                payable(msg.sender),
                address(0x0),
                d.extraDataPerDst[i],
                d.gasPerDst[i]
            );
        }
    }

    /// @notice to add access based controls over here
    /// @dev allows admin to add new chain ids in future
    /// @param superChainId_ is the identifier of the chain within superform protocol
    /// @param ambChainId_ is the identifier of the chain given by the AMB
    function setChainId(
        uint16 superChainId_,
        uint16 ambChainId_
    ) external onlyProtocolAdmin {
        ambChainId[superChainId_] = ambChainId_;
        superChainId[ambChainId_] = superChainId_;

        /// NOTE: @dev should handle a way to pop
        broadcastChains.push(ambChainId_);
    }

    /*///////////////////////////////////////////////////////////////
                       Core Internal Functions
    //////////////////////////////////////////////////////////////*/
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory,
        uint64 _nonce,
        bytes memory _payload
    ) internal {
        if (isValid[_srcChainId][_nonce] == true) {
            revert Error.DUPLICATE_PAYLOAD();
        }

        /// NOTE: changing state earlier to prevent re-entrancy.
        isValid[_srcChainId][_nonce] = true;

        /// @dev decodes payload received
        AMBMessage memory decoded = abi.decode(_payload, (AMBMessage));

        /// NOTE: experimental split of registry contracts
        (, , , uint8 registryId) = _decodeTxInfo(decoded.txInfo);

        address registryAddress = superRegistry.getStateRegistry(registryId);
        IBaseStateRegistry targetRegistry = IBaseStateRegistry(registryAddress);

        targetRegistry.receivePayload(superChainId[_srcChainId], _payload);
    }

    /*///////////////////////////////////////////////////////////////
                        LZ External Functions
    //////////////////////////////////////////////////////////////*/

    function lzReceive(
        uint16 srcChainId_,
        bytes memory srcAddress_,
        uint64 nonce_,
        bytes memory payload_
    ) public override {
        // lzReceive must be called by the endpoint for security
        require(
            msg.sender == address(lzEndpoint),
            "LzApp: invalid endpoint caller"
        );

        bytes memory trustedRemote = trustedRemoteLookup[srcChainId_];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(
            srcAddress_.length == trustedRemote.length &&
                keccak256(srcAddress_) == keccak256(trustedRemote),
            "LzApp: invalid source sending contract"
        );

        _blockingLzReceive(srcChainId_, srcAddress_, nonce_, payload_);
    }

    function nonblockingLzReceive(
        uint16 srcChainId_,
        bytes memory srcAddress_,
        uint64 nonce_,
        bytes memory payload_
    ) public {
        // only internal transaction
        require(
            msg.sender == address(this),
            "NonblockingLzApp: caller must be LzApp"
        );
        _nonblockingLzReceive(srcChainId_, srcAddress_, nonce_, payload_);
    }

    function retryMessage(
        uint16 srcChainId_,
        bytes memory srcAddress_,
        uint64 nonce_,
        bytes memory payload_
    ) public payable {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[srcChainId_][srcAddress_][nonce_];
        require(
            payloadHash != bytes32(0),
            "NonblockingLzApp: no stored message"
        );
        require(
            keccak256(payload_) == payloadHash,
            "NonblockingLzApp: invalid payload"
        );
        // clear the stored message
        failedMessages[srcChainId_][srcAddress_][nonce_] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(srcChainId_, srcAddress_, nonce_, payload_);
    }

    /*///////////////////////////////////////////////////////////////
                        LZ Internal Functions
    //////////////////////////////////////////////////////////////*/

    function _lzSend(
        uint16 dstChainId_,
        bytes memory payload_,
        address payable refundAddress_,
        address zroPaymentAddress_,
        bytes memory adapterParams_,
        uint256 msgValue_
    ) internal {
        bytes memory trustedRemote = trustedRemoteLookup[dstChainId_];
        require(
            trustedRemote.length != 0,
            "LzApp: destination chain is not a trusted source"
        );

        lzEndpoint.send{value: msgValue_}(
            dstChainId_,
            trustedRemote,
            payload_,
            refundAddress_,
            zroPaymentAddress_,
            adapterParams_
        );
    }

    function _blockingLzReceive(
        uint16 srcChainId_,
        bytes memory srcAddress_,
        uint64 nonce_,
        bytes memory payload_
    ) internal {
        // try-catch all errors/exceptions
        try
            this.nonblockingLzReceive(
                srcChainId_,
                srcAddress_,
                nonce_,
                payload_
            )
        {
            // do nothing
        } catch {
            // error / exception
            failedMessages[srcChainId_][srcAddress_][nonce_] = keccak256(
                payload_
            );
            emit MessageFailed(srcChainId_, srcAddress_, nonce_, payload_);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            LZ Application config
    //////////////////////////////////////////////////////////////*/

    function setLzEndpoint(address endpoint_) external onlyProtocolAdmin {
        if (address(lzEndpoint) == address(0)) {
            lzEndpoint = ILayerZeroEndpoint(endpoint_);
        }
    }

    function getConfig(
        uint16 version_,
        uint16 chainId_,
        address,
        uint256 configType_
    ) external view returns (bytes memory) {
        return
            lzEndpoint.getConfig(
                version_,
                chainId_,
                address(this),
                configType_
            );
    }

    // generic config for LayerZero user Application
    function setConfig(
        uint16 version_,
        uint16 chainId_,
        uint256 configType_,
        bytes calldata config_
    ) external override onlyProtocolAdmin {
        lzEndpoint.setConfig(version_, chainId_, configType_, config_);
    }

    function setSendVersion(
        uint16 version_
    ) external override onlyProtocolAdmin {
        lzEndpoint.setSendVersion(version_);
    }

    function setReceiveVersion(
        uint16 version_
    ) external override onlyProtocolAdmin {
        lzEndpoint.setReceiveVersion(version_);
    }

    function forceResumeReceive(
        uint16 srcChainId_,
        bytes calldata srcAddress_
    ) external override onlyProtocolAdmin {
        lzEndpoint.forceResumeReceive(srcChainId_, srcAddress_);
    }

    // allow owner to set it multiple times.
    function setTrustedRemote(
        uint16 srcChainId_,
        bytes calldata srcAddress_
    ) external onlyProtocolAdmin {
        trustedRemoteLookup[srcChainId_] = srcAddress_;
        emit SetTrustedRemote(srcChainId_, srcAddress_);
    }

    function isTrustedRemote(
        uint16 srcChainId_,
        bytes calldata srcAddress_
    ) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[srcChainId_];
        return keccak256(trustedSource) == keccak256(srcAddress_);
    }
}

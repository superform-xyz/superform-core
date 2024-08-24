// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "src/vendor/layerzero/v2/ILayerZeroReceiver.sol";
import "src/vendor/layerzero/v2/ILayerZeroEndpointV2.sol";

import { Error } from "src/libraries/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { AMBMessage } from "src/types/DataTypes.sol";
import { ProofLib } from "src/libraries/ProofLib.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";

/// @title LayerzeroV2Implementation
/// @dev Allows state registries to use Layerzero v2 for crosschain communication
/// @author Zeropoint Labs
contract LayerzeroV2Implementation is IAmbImplementation, ILayerZeroReceiver {
    using DataLib for uint256;
    using ProofLib for AMBMessage;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////
    uint64 internal constant SENDER_VERSION = 1;
    /// identifier for oapp sender version
    uint64 internal constant RECEIVER_VERSION = 2;
    /// identifier for oapp receiver

    uint16 private constant OPTIONS_TYPE = 1;

    /// legacy options is fine for superform
    ISuperRegistry public immutable superRegistry;

    //////////////////////////////////////////////////////////////
    //                         STATE VARIABLES                  //
    //////////////////////////////////////////////////////////////
    ILayerZeroEndpointV2 public endpoint;

    mapping(bytes32 => bool) public ambProtect;

    mapping(uint64 => uint32) public ambChainId;
    mapping(uint32 => uint64) public superChainId;

    mapping(bytes32 => bool) public processedMessages;
    mapping(uint32 eid => bytes32 peer) public peers;

    /////////////////////////////////////////////////////////////
    //                      CUSTOM  ERRORS                     //
    //////////////////////////////////////////////////////////////

    /// @dev thrown if endpoint is already set
    error ENDPOINT_EXISTS();

    /// @dev thrown if endpoint is not set
    error ENDPOINT_NOT_SET();

    /// @dev thrown if msg.value is not expected msg fees
    error INVALID_MSG_FEE();

    /// @dev thrown if peer is not set
    error PEER_NOT_SET();

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    event EndpointUpdated(address indexed oldEndpoint_, address indexed newEndpoint_);
    event DelegateUpdated(address indexed newDelegate_);
    event PeerSet(uint32 indexed eid_, bytes32 peer_);

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    modifier onlyValidStateRegistry() {
        if (!superRegistry.isValidStateRegistry(msg.sender)) {
            revert Error.NOT_STATE_REGISTRY();
        }
        _;
    }

    /// @param superRegistry_ is the super registry address
    constructor(ISuperRegistry superRegistry_) {
        superRegistry = superRegistry_;
    }

    //////////////////////////////////////////////////////////////
    //                         CONFIG                           //
    //////////////////////////////////////////////////////////////

    /// @notice Sets the peer address (OApp instance) for a corresponding endpoint.
    /// @param eid_ The endpoint ID.
    /// @param peer_ The address of the peer to be associated with the corresponding endpoint.
    function setPeer(uint32 eid_, bytes32 peer_) external onlyProtocolAdmin {
        peers[eid_] = peer_;
        emit PeerSet(eid_, peer_);
    }

    /// @dev allows protocol admin to configure layerzero endpoint
    /// @param endpoint_ is the layerzero endpoint on the deployed network
    function setLzEndpoint(address endpoint_) external onlyProtocolAdmin {
        if (address(endpoint) != address(0)) revert ENDPOINT_EXISTS();
        if (endpoint_ == address(0)) revert Error.ZERO_ADDRESS();

        endpoint = ILayerZeroEndpointV2(endpoint_);
        emit EndpointUpdated(address(0), endpoint_);
    }

    /// @dev allows protocol admin to configure layerzero delegate
    /// @param delegate_ is the layerzero delegate to be configured
    function setDelegate(address delegate_) external onlyProtocolAdmin {
        if (address(endpoint) == address(0)) revert ENDPOINT_NOT_SET();
        if (delegate_ == address(0)) revert Error.ZERO_ADDRESS();

        endpoint.setDelegate(delegate_);
        emit DelegateUpdated(delegate_);
    }

    /// @dev allows protocol admin to add new chain ids in future
    /// @param superChainId_ is the identifier of the chain within superform protocol
    /// @param ambChainId_ is the identifier of the chain given by the AMB
    /// NOTE: cannot be defined in an interface as types vary for each message bridge (amb)
    function setChainId(uint64 superChainId_, uint32 ambChainId_) external onlyProtocolAdmin {
        if (superChainId_ == 0 || ambChainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        /// @dev  reset old mappings
        uint64 oldSuperChainId = superChainId[ambChainId_];
        uint32 oldAmbChainId = ambChainId[superChainId_];

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
        uint32 eid = ambChainId[dstChainId_];
        if (eid == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        MessagingFee memory fee_ = _quote(eid, message_, extraData_);

        _lzSend(eid, message_, extraData_, fee_, srcSender_);
    }

    /// @inheritdoc ILayerZeroReceiver
    function lzReceive(
        Origin calldata origin_,
        bytes32 guid_,
        bytes calldata message_,
        address executor_,
        bytes calldata extraData_
    )
        external
        payable
        override
    {
        /// @dev validates if caller is lz endpoint
        if (address(endpoint) != msg.sender) revert Error.CALLER_NOT_ENDPOINT();

        /// @dev validates is source sender is valid
        if (_getPeerOrRevert(origin_.srcEid) != origin_.sender) revert Error.INVALID_SRC_SENDER();

        _lzReceive(origin_, guid_, message_, executor_, extraData_);
    }

    /// @inheritdoc IAmbImplementation
    function retryPayload(bytes calldata data_) external payable override {
        /// @dev this is just a helper function. this can be direct made to the layerzero endpoint as well
        (Origin memory origin, address receiver, bytes32 guid, bytes memory message, bytes memory extraData) =
            abi.decode(data_, (Origin, address, bytes32, bytes, bytes));

        endpoint.lzReceive{ value: msg.value }(origin, receiver, guid, message, extraData);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

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
        uint32 tempAmbChainId = ambChainId[dstChainId_];

        if (tempAmbChainId == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        /// @dev superform core cannot support _payInLzToken at this moment
        /// extraData_ here is the layerzero options
        fees = _quote(tempAmbChainId, message_, extraData_).nativeFee;
    }

    /// @inheritdoc IAmbImplementation
    function generateExtraData(uint256 gasLimit) external pure override returns (bytes memory extraData) {
        /// generate the executor options here, since we don't use msg.value just returning encoded args
        /// refer: https://docs.layerzero.network/v2/developers/evm/gas-settings/options#lzreceive-option

        /// @dev uses the legacy extra data option
        /// refer:
        /// https://github.com/LayerZero-Labs/LayerZero-v2/blob/1fde89479fdc68b1a54cda7f19efa84483fcacc4/oapp/contracts/oapp/libs/OptionsBuilder.sol#L178
        return abi.encodePacked(OPTIONS_TYPE, gasLimit);
    }

    /// @notice returns the oapp version information
    function oAppVersion() external pure returns (uint64 senderVersion, uint64 receiverVersion) {
        return (SENDER_VERSION, RECEIVER_VERSION);
    }

    /// @notice checks if the path initialization is allowed based on the provided origin.
    function allowInitializePath(Origin calldata origin) external view override returns (bool) {
        return peers[origin.srcEid] == origin.sender;
    }

    /// @dev the path nonce starts from 1. If 0 is returned it means that there is NO nonce ordered enforcement.
    /// @dev is required by the off-chain executor to determine the OApp expects msg execution is ordered.
    function nextNonce(uint32, /*_srcEid*/ bytes32 /*_sender*/ ) external pure override returns (uint64 nonce) {
        return 0;
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @notice internal function to get the peer address associated with a specific endpoint; reverts if NOT set.
    function _getPeerOrRevert(uint32 _eid) internal view virtual returns (bytes32) {
        bytes32 peer = peers[_eid];
        if (peer == bytes32(0)) revert PEER_NOT_SET();
        return peer;
    }

    /// @dev interacts with EndpointV2.quote() for fee calculation
    function _quote(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options
    )
        internal
        view
        virtual
        returns (MessagingFee memory fee)
    {
        /// payInLzToken is hardcoded to false
        return endpoint.quote(
            MessagingParams(_dstEid, _getPeerOrRevert(_dstEid), _message, _options, false), address(this)
        );
    }

    /// @dev interacts with the LayerZero EndpointV2.send() for sending a message
    function _lzSend(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options,
        MessagingFee memory _fee,
        address _refundAddress
    )
        internal
        virtual
        returns (MessagingReceipt memory receipt)
    {
        // @dev push corresponding fees to the endpoint
        if (msg.value < _fee.nativeFee || _fee.lzTokenFee != 0) revert INVALID_MSG_FEE();

        return endpoint.send{ value: msg.value }(
            MessagingParams(_dstEid, _getPeerOrRevert(_dstEid), _message, _options, false), _refundAddress
        );
    }

    /// @dev processes a received payload
    function _lzReceive(
        Origin calldata origin_,
        bytes32 guid_,
        bytes calldata message_,
        address,
        /// executor_
        bytes calldata
    )
        /// extraData_
        internal
    {
        if (processedMessages[guid_]) {
            revert Error.DUPLICATE_PAYLOAD();
        }

        processedMessages[guid_] = true;

        /// @dev decodes payload received
        AMBMessage memory decoded = abi.decode(message_, (AMBMessage));

        /// NOTE: experimental split of registry contracts
        (,,, uint8 registryId,,) = decoded.txInfo.decodeTxInfo();

        IBaseStateRegistry targetRegistry = IBaseStateRegistry(superRegistry.getStateRegistry(registryId));

        uint64 srcChainId = superChainId[origin_.srcEid];

        if (srcChainId == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        _ambProtect(decoded);
        targetRegistry.receivePayload(srcChainId, message_);
    }

    /// @dev prevents the same AMB from delivery a payload and its proof
    /// @dev is an additional protection against malicious ambs
    function _ambProtect(AMBMessage memory _message) internal {
        bytes32 proof;

        /// @dev amb protect
        if (_message.params.length != 32) {
            (, bytes memory payloadBody) = abi.decode(_message.params, (uint8[], bytes));
            proof = AMBMessage(_message.txInfo, payloadBody).computeProof();
        } else {
            proof = abi.decode(_message.params, (bytes32));
        }

        if (ambProtect[proof]) revert ();
        ambProtect[proof] = true;
    }
}

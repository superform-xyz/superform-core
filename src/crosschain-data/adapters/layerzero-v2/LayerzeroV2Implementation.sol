// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "src/vendor/layerzero/v2/OApp.sol";
import "src/vendor/layerzero/v2/interfaces/ILayerZeroEndpointV2.sol";

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
contract LayerzeroV2Implementation is IAmbImplementation, OApp {
    using DataLib for uint256;
    using ProofLib for AMBMessage;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////
    uint16 constant private OPTIONS_TYPE = 1;  /// legacy options is fine for superform
    ISuperRegistry public immutable superRegistry;

    //////////////////////////////////////////////////////////////
    //                         STATE VARIABLES                  //
    //////////////////////////////////////////////////////////////

    mapping(bytes32 => bool) public ambProtect;

    mapping(uint64 => uint32) public ambChainId;
    mapping(uint32 => uint64) public superChainId;

    mapping(bytes32 => bool) public processedMessages;

    /////////////////////////////////////////////////////////////
    //                      CUSTOM  ERRORS                     //
    //////////////////////////////////////////////////////////////

    /// @dev thrown if endpoint is already set
    error ENDPOINT_EXISTS();

    /// @dev thrown if endpoint is not set
    error ENDPOINT_NOT_SET();

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    event EndpointUpdated(address indexed oldEndpoint_, address indexed newEndpoint_);
    event DelegateUpdated(address indexed newDelegate_);

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
    function setPeer(uint32 eid_, bytes32 peer_) external override onlyProtocolAdmin {
        _setPeer(eid_, peer_);
    }


    /// @dev allows protocol admin to configure layerzero endpoint
    /// @param endpoint_ is the layerzero endpoint on the deployed network
    function setLzEndpoint(address endpoint_) external onlyProtocolAdmin {
        if(address(endpoint) != address(0)) revert ENDPOINT_EXISTS();
        if (endpoint_ == address(0)) revert Error.ZERO_ADDRESS();

        endpoint = ILayerZeroEndpointV2(endpoint_);
        emit EndpointUpdated(address(0), endpoint_);
    }

    /// @dev allows protocol admin to configure layerzero delegate
    /// @param delegate_ is the layerzero delegate to be configured
    function setDelegate(address delegate_) external override onlyProtocolAdmin {
        if (address(endpoint) == address(0)) revert ENDPOINT_NOT_SET();
        if(delegate_ == address(0)) revert Error.ZERO_ADDRESS();
        
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

        MessagingFee memory fee_ = _quote(eid, message_, extraData_, false);

        _lzSend(eid, message_, extraData_, fee_, srcSender_);
    }

    /// @inheritdoc IAmbImplementation
    function retryPayload(bytes memory data_) external payable override {}

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

        if(tempAmbChainId == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        /// @dev superform core cannot support _payInLzToken at this moment
        /// extraData_ here is the layerzero options
        fees = _quote(tempAmbChainId, message_, extraData_, false).nativeFee;
    }

    /// @inheritdoc IAmbImplementation
    function generateExtraData(uint256 gasLimit) external override pure returns (bytes memory extraData) {
        /// generate the executor options here, since we don't use msg.value just returning encoded args
        /// refer: https://docs.layerzero.network/v2/developers/evm/gas-settings/options#lzreceive-option
        return abi.encodePacked(OPTIONS_TYPE, gasLimit);
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    function _lzReceive(
        Origin calldata origin_,
        bytes32 guid_,
        bytes calldata message_,
        address , /// executor_
        bytes calldata /// extraData_
    ) internal override {
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

        if (ambProtect[proof]) revert MALICIOUS_DELIVERY();
        ambProtect[proof] = true;
    }
}
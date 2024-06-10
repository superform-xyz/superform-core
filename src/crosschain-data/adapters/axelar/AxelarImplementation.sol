// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { ProofLib } from "src/libraries/ProofLib.sol";
import { AMBMessage } from "src/types/DataTypes.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IAxelarGasService } from "src/vendor/axelar/IAxelarGasService.sol";
import { IAxelarGateway } from "src/vendor/axelar/IAxelarGateway.sol";
import { IInterchainGasEstimation } from "src/vendor/axelar/IInterchainGasEstimation.sol";
import { IAxelarExecutable } from "src/vendor/axelar/IAxelarExecutable.sol";
import { StringToAddress, AddressToString } from "src/vendor/axelar/StringAddressConversion.sol";

contract AxelarImplementation is IAmbImplementation, IAxelarExecutable {
    using DataLib for uint256;
    using ProofLib for AMBMessage;
    using AddressToString for address;
    using StringToAddress for string;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    ISuperRegistry public immutable superRegistry;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////
    IAxelarGateway public gateway;

    /// @dev gas service is the gas estimator
    IAxelarGasService public gasService;
    IInterchainGasEstimation public gasEstimator;

    mapping(uint64 => string) public ambChainId;
    mapping(string => uint64) public superChainId;
    mapping(string => address) public authorizedImpl;
    mapping(bytes32 => bool) public processedMessages;

    mapping(bytes32 => bool) public ambProtect;

    //////////////////////////////////////////////////////////////
    //                      CUSTOM  ERRORS                      //
    //////////////////////////////////////////////////////////////

    /// @dev when gateway is already configured.
    error GATEWAY_EXISTS();

    /// @dev thrown if the incoming request is an invalid contract call
    error INVALID_CONTRACT_CALL();

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    event GatewayAdded(address indexed _newGateway);
    event GasServiceAdded(address indexed _newGasService);
    event GasEstimatorAdded(address indexed _newGasEstimator);

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

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(ISuperRegistry superRegistry_) {
        superRegistry = superRegistry_;
    }

    //////////////////////////////////////////////////////////////
    //                         CONFIG                            //
    //////////////////////////////////////////////////////////////

    /// @dev allows protocol admin to configure axelar gateway
    /// @dev this allows only one-time configuration for immutability
    /// @param gateway_ is the address of axelar gateway
    function setAxelarConfig(IAxelarGateway gateway_) external onlyProtocolAdmin {
        if (address(gateway_) == address(0)) revert Error.ZERO_ADDRESS();
        if (address(gateway) != address(0)) revert GATEWAY_EXISTS();

        gateway = gateway_;
        emit GatewayAdded(address(gateway_));
    }

    /// @dev allows protocol admin to configure axelar gas service and gas estimator
    /// @param gasService_ is the address of axelar gas service
    /// @param gasEstimator_ is the address of axelar gas estimator
    function setAxelarGasService(
        IAxelarGasService gasService_,
        IInterchainGasEstimation gasEstimator_
    )
        external
        onlyProtocolAdmin
    {
        if (address(gasService_) == address(0) || address(gasEstimator_) == address(0)) revert Error.ZERO_ADDRESS();

        gasService = gasService_;
        gasEstimator = gasEstimator_;

        emit GasServiceAdded(address(gasService_));
        emit GasEstimatorAdded(address(gasEstimator_));
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
        string memory axelarChainId = ambChainId[dstChainId_];
        bytes memory axelarChainIdBytes = bytes(axelarChainId);

        if (keccak256(axelarChainIdBytes) == keccak256(bytes("")) || axelarChainIdBytes.length == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        /// @dev the destinationAddress is not used in the upstream axelar contract; hence passing in zero address
        /// @dev the params is also not used; hence passing in bytes(0)
        return gasEstimator.estimateGasFee(
            axelarChainId, address(0).toString(), message_, abi.decode(extraData_, (uint256)), bytes("")
        );
    }

    /// @inheritdoc IAmbImplementation
    function generateExtraData(uint256 gasLimit) external pure override returns (bytes memory extraData) {
        /// @notice encoded dst gas limit
        extraData = abi.encode(gasLimit);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IAmbImplementation
    function dispatchPayload(
        address srcSender_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory /*extraData_ */
    )
        external
        payable
        virtual
        override
        onlyValidStateRegistry
    {
        string memory axelarChainId = ambChainId[dstChainId_];
        if (bytes(axelarChainId).length == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        string memory axelerDstImpl = authorizedImpl[axelarChainId].toString();

        gateway.callContract(axelarChainId, axelerDstImpl, message_);
        gasService.payNativeGasForContractCall{ value: msg.value }(
            msg.sender, axelarChainId, axelerDstImpl, message_, srcSender_
        );
    }

    /// @inheritdoc IAmbImplementation
    function retryPayload(bytes memory data_) external payable override {
        (bytes32 txHash, uint256 logIndex) = abi.decode(data_, (bytes32, uint256));
        /// @dev refunds are sent to the msg.sender
        gasService.addNativeGas{ value: msg.value }(txHash, logIndex, msg.sender);
    }

    /// @inheritdoc IAxelarExecutable
    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    )
        external
        override
    {
        /// @dev 1. validate caller
        /// @dev 2. validate src chain sender
        /// @dev 3. validate message uniqueness
        if (sourceAddress.toAddress() != authorizedImpl[sourceChain]) {
            revert Error.INVALID_SRC_SENDER();
        }

        /// @dev axelar has native replay protection, still adding our own internal replay protections
        /// using msgId
        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, keccak256(payload))) {
            revert INVALID_CONTRACT_CALL();
        }

        /// @dev validateContractCall has native replay protection, this is additional
        bytes32 msgId = keccak256(abi.encode(commandId, payload));

        if (processedMessages[msgId]) {
            revert Error.DUPLICATE_PAYLOAD();
        }

        processedMessages[msgId] = true;

        /// @dev decoding payload
        AMBMessage memory decoded = abi.decode(payload, (AMBMessage));

        /// @dev routes message to respective state registry
        (,,, uint8 registryId,,) = decoded.txInfo.decodeTxInfo();
        IBaseStateRegistry targetRegistry = IBaseStateRegistry(superRegistry.getStateRegistry(registryId));

        uint64 origin = superChainId[sourceChain];

        /// @dev unreacheable code, added for defensive checks
        if (origin == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        _ambProtect(decoded);
        targetRegistry.receivePayload(origin, payload);
    }

    /// @dev allows protocol admin to add new chain ids in future
    /// @param superChainId_ is the identifier of the chain within superform protocol
    /// @param ambChainId_ is the identifier of the chain given by the AMB
    /// NOTE: cannot be defined in an interface as types vary for each message bridge (amb)
    function setChainId(uint64 superChainId_, string memory ambChainId_) external onlyProtocolAdmin {
        if (superChainId_ == 0 || bytes(ambChainId_).length == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        // @dev  reset old mappings
        uint64 oldSuperChainId = superChainId[ambChainId_];
        string memory oldAmbChainId = ambChainId[superChainId_];

        if (oldSuperChainId != 0) {
            delete ambChainId[oldSuperChainId];
        }

        if (bytes(oldAmbChainId).length != 0) {
            delete superChainId[oldAmbChainId];
        }

        ambChainId[superChainId_] = ambChainId_;
        superChainId[ambChainId_] = superChainId_;

        emit ChainAdded(superChainId_);
    }

    /// @dev allows protocol admin to set receiver implementation on a new chain id
    /// @param ambChainId_ is the identifier of the destination chain within axelar
    /// @param authorizedImpl_ is the implementation of the axelar message bridge on the specified destination
    /// NOTE: cannot be defined in an interface as types vary for each message bridge (amb)
    function setReceiver(string memory ambChainId_, address authorizedImpl_) external onlyProtocolAdmin {
        if (superChainId[ambChainId_] == 0 || bytes(ambChainId_).length == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        if (authorizedImpl_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        authorizedImpl[ambChainId_] = authorizedImpl_;

        emit AuthorizedImplAdded(superChainId[ambChainId_], authorizedImpl_);
    }

    //////////////////////////////////////////////////////////////
    //              INTERNAL HELPER FUNCTIONS                   //
    //////////////////////////////////////////////////////////////

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

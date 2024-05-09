// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { ProofLib } from "src/libraries/ProofLib.sol";
import { Error } from "src/libraries/Error.sol";
import { AMBMessage } from "src/types/DataTypes.sol";
import { IWormholeRelayer, VaaKey } from "src/vendor/wormhole/IWormholeRelayer.sol";
import { IWormholeReceiver } from "src/vendor/wormhole/IWormholeReceiver.sol";
import "src/vendor/wormhole/Utils.sol";

/// @title WormholeImplementation
/// @dev Allows state registries to use Wormhole AR's for crosschain communication
/// @author Zeropoint Labs
contract WormholeARImplementation is IAmbImplementation, IWormholeReceiver {
    using DataLib for uint256;
    using ProofLib for AMBMessage;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////
    ISuperRegistry public immutable superRegistry;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    IWormholeRelayer public relayer;
    uint16 public refundChainId;

    mapping(uint64 => uint16) public ambChainId;
    mapping(uint16 => uint64) public superChainId;
    mapping(uint16 => address) public authorizedImpl;
    mapping(bytes32 => bool) public processedMessages;
    mapping(bytes32 => bool) public ambProtect;

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev emitted when wormhole relayer is set
    event WormholeRelayerSet(address indexed wormholeRelayer);

    /// @dev emitted when refund chain id is set
    event WormholeRefundChainIdSet(uint16 indexed refundChainId);

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

    modifier onlyRelayer() {
        if (msg.sender != address(relayer)) {
            revert Error.CALLER_NOT_RELAYER();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    /// @param superRegistry_ is super registry address for respective chain
    constructor(ISuperRegistry superRegistry_) {
        superRegistry = superRegistry_;
    }

    //////////////////////////////////////////////////////////////
    //                         CONFIG                           //
    //////////////////////////////////////////////////////////////

    /// @dev allows protocol admin to configure wormhole relayer contract
    /// @param relayer_ is the automatic relayer address for respective chain
    function setWormholeRelayer(address relayer_) external onlyProtocolAdmin {
        if (relayer_ == address(0)) revert Error.ZERO_ADDRESS();
        if (address(relayer) == address(0)) {
            relayer = IWormholeRelayer(relayer_);
            emit WormholeRelayerSet(address(relayer));
        }
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IAmbImplementation
    function estimateFees(
        uint64 dstChainId_,
        bytes memory,
        bytes memory extraData_
    )
        external
        view
        override
        returns (uint256 fees)
    {
        uint256 dstNativeAirdrop;
        uint256 dstGasLimit;

        if (extraData_.length != 0) {
            (dstNativeAirdrop, dstGasLimit) = abi.decode(extraData_, (uint256, uint256));
        }

        uint16 dstChainId = ambChainId[dstChainId_];

        if (dstChainId == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        (fees,) = relayer.quoteEVMDeliveryPrice(dstChainId, dstNativeAirdrop, dstGasLimit);
    }

    /// @inheritdoc IAmbImplementation
    function generateExtraData(uint256 gasLimit) external pure override returns (bytes memory extraData) {
        /// @notice encoded dst gas limit
        extraData = abi.encode(0, gasLimit);
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
        virtual
        override
        onlyValidStateRegistry
    {
        if (refundChainId == 0) {
            revert Error.REFUND_CHAIN_ID_NOT_SET();
        }

        uint16 dstChainId = ambChainId[dstChainId_];
        (uint256 dstNativeAirdrop, uint256 dstGasLimit) = abi.decode(extraData_, (uint256, uint256));

        /// @dev refunds any excess on this chain back to srcSender_
        relayer.sendPayloadToEvm{ value: msg.value }(
            dstChainId, authorizedImpl[dstChainId], message_, dstNativeAirdrop, dstGasLimit, refundChainId, srcSender_
        );
    }

    /// @inheritdoc IAmbImplementation
    function retryPayload(bytes memory data_) external payable override {
        (
            VaaKey memory deliveryVaaKey,
            uint16 targetChain,
            uint256 newReceiverValue,
            uint256 newGasLimit,
            address newDeliveryProviderAddress
        ) = abi.decode(data_, (VaaKey, uint16, uint256, uint256, address));

        (uint256 fees,) = relayer.quoteEVMDeliveryPrice(targetChain, 0, newGasLimit);

        if (msg.value < fees) {
            revert Error.INVALID_RETRY_FEE();
        }

        if (newDeliveryProviderAddress == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        relayer.resendToEvm{ value: fees }(
            deliveryVaaKey, targetChain, newReceiverValue, newGasLimit, newDeliveryProviderAddress
        );

        /// refunds excess msg.value to msg.sender
        uint256 excessPaid = msg.value - fees;
        if (excessPaid > 0) {
            (bool success,) = payable(msg.sender).call{ value: excessPaid }("");

            if (!success) {
                revert Error.FAILED_TO_SEND_NATIVE();
            }
        }
    }

    /// @inheritdoc IWormholeReceiver
    function receiveWormholeMessages(
        bytes memory payload_,
        bytes[] memory,
        bytes32 sourceAddress_,
        uint16 sourceChain_,
        bytes32 deliveryHash_
    )
        public
        payable
        override
        onlyRelayer
    {
        /// @dev 1. validate caller
        /// @dev 2. validate src chain sender
        /// @dev 3. validate message uniqueness
        if (fromWormholeFormat(sourceAddress_) != authorizedImpl[sourceChain_]) {
            revert Error.INVALID_SRC_SENDER();
        }

        if (processedMessages[deliveryHash_]) {
            revert Error.DUPLICATE_PAYLOAD();
        }

        processedMessages[deliveryHash_] = true;

        /// @dev decoding payload
        AMBMessage memory decoded = abi.decode(payload_, (AMBMessage));
        (,,, uint8 registryId,,) = decoded.txInfo.decodeTxInfo();
        IBaseStateRegistry targetRegistry = IBaseStateRegistry(superRegistry.getStateRegistry(registryId));

        uint64 sourceChain = superChainId[sourceChain_];

        if (sourceChain == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        _ambProtect(decoded);
        targetRegistry.receivePayload(sourceChain, payload_);
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

    /// @dev allows protocol admin to set wormhole chain id for refunds
    /// @param refundChainId_ is the wormhole chain id of current chain
    function setRefundChainId(uint16 refundChainId_) external onlyProtocolAdmin {
        if (refundChainId_ == 0) revert Error.INVALID_CHAIN_ID();
        refundChainId = refundChainId_;

        emit WormholeRefundChainIdSet(refundChainId_);
    }

    /// @dev allows protocol admin to set receiver implementation on a new chain id
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

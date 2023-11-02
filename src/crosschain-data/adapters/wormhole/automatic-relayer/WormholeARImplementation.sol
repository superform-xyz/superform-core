// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { AMBMessage } from "src/types/DataTypes.sol";
import { Error } from "src/utils/Error.sol";
import { IWormholeRelayer, VaaKey } from "src/vendor/wormhole/IWormholeRelayer.sol";
import { IWormholeReceiver } from "src/vendor/wormhole/IWormholeReceiver.sol";
import { DataLib } from "src/libraries/DataLib.sol";

/// @title WormholeImplementation
/// @author Zeropoint Labs
/// @notice allows state registries to use wormhole for crosschain communication
/// @dev uses automatic relayers of wormhole for 1:1 messaging
contract WormholeARImplementation is IAmbImplementation, IWormholeReceiver {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public immutable superRegistry;
    IWormholeRelayer public relayer;

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
    /// @dev allows protocol admin to configure wormhole relayer contract
    /// @param relayer_ is the automatic relayer address for respective chain
    function setWormholeRelayer(address relayer_) external onlyProtocolAdmin {
        if (relayer_ == address(0)) revert Error.ZERO_ADDRESS();
        if (address(relayer) == address(0)) {
            relayer = IWormholeRelayer(relayer_);
        }
    }
    /*///////////////////////////////////////////////////////////////
                                EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAmbImplementation
    function dispatchPayload(
        address, /*srcSender_*/
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
        uint16 dstChainId = ambChainId[dstChainId_];

        (uint256 dstNativeAirdrop, uint256 dstGasLimit) = abi.decode(extraData_, (uint256, uint256));

        relayer.sendPayloadToEvm{ value: msg.value }(
            dstChainId, authorizedImpl[dstChainId], message_, dstNativeAirdrop, dstGasLimit
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
        relayer.resendToEvm{ value: msg.value }(
            deliveryVaaKey, targetChain, newReceiverValue, newGasLimit, newDeliveryProviderAddress
        );
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

        if (_bytes32ToAddress(sourceAddress_) != authorizedImpl[sourceChain_]) {
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

        targetRegistry.receivePayload(superChainId[sourceChain_], payload_);
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
                    View Functions
    //////////////////////////////////////////////////////////////*/

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

        if (extraData_.length > 0) {
            (dstNativeAirdrop, dstGasLimit) = abi.decode(extraData_, (uint256, uint256));
        }

        uint16 dstChainId = ambChainId[dstChainId_];

        if (dstChainId == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        (fees,) = relayer.quoteEVMDeliveryPrice(dstChainId, dstNativeAirdrop, dstGasLimit);
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

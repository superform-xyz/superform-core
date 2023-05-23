// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IWormhole} from "../../vendor/wormhole/IWormhole.sol";
import {IWormholeReceiver} from "../../vendor/wormhole/IWormholeReceiver.sol";
import {IWormholeRelayer} from "../../vendor/wormhole/IWormholeRelayer.sol";
import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {AMBMessage} from "../../types/DataTypes.sol";
import {ISuperRBAC} from "../../interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {Error} from "../../utils/Error.sol";
import "../../utils/DataPacking.sol";

/// @dev FIXME: this contract is WIP; not completed yet
/// @title WormholeImplementation
/// @author Zeropoint Labs
/// @dev allows state registries to use wormhole for crosschain communication
contract WormholeImplementation is IAmbImplementation, IWormholeReceiver {
    struct ExtraData {
        uint256 messageFee;
        uint256 relayerFee;
        uint256 airdrop;
    }

    /*///////////////////////////////////////////////////////////////
                    State Variables
    //////////////////////////////////////////////////////////////*/
    uint8 public constant CONSISTENCY_LEVEL = 1;

    IWormhole public immutable bridge;
    ISuperRegistry public immutable superRegistry;

    /// @dev relayer will forward published wormhole messages
    IWormholeRelayer public relayer;

    /// @dev FIXME: refactor
    mapping(uint16 => uint16) public ambChainId;
    mapping(uint16 => uint16) public superChainId;
    mapping(bytes32 => bool) public processedMessages;

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(msg.sender)) revert Error.NOT_PROTOCOL_ADMIN();
        _;
    }

    modifier onlyRelayer() {
        if (address(relayer) != msg.sender) revert Error.NOT_WORMHOLE_RELAYER();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                    Constructor
    //////////////////////////////////////////////////////////////*/

    /// @param bridge_ is the wormhole implementation for respective chain.
    /// @param relayer_ is the wormhole relayer for respective chain.
    /// @param superRegistry_ is the superform registry.
    constructor(IWormhole bridge_, IWormholeRelayer relayer_, ISuperRegistry superRegistry_) {
        bridge = bridge_;
        relayer = relayer_;
        superRegistry = superRegistry_;
    }

    /*///////////////////////////////////////////////////////////////
                    External Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice receive enables processing native token transfers into the smart contract.
    /// @dev socket.tech fails without a native receive function.
    receive() external payable {}

    /// @inheritdoc IAmbImplementation
    function dispatchPayload(
        uint16 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable virtual override {
        if (!superRegistry.isValidStateRegistry(msg.sender)) {
            revert Error.INVALID_CALLER();
        }

        bytes memory payload = abi.encode(msg.sender, dstChainId_, message_);
        ExtraData memory eData = abi.decode(extraData_, (ExtraData));

        /// FIXME: nonce is externally generated. can also be moved inside our contracts
        uint32 nonce = abi.decode(extraData_, (uint32));

        bridge.publishMessage{value: eData.messageFee}(nonce, payload, CONSISTENCY_LEVEL);

        /// @dev call relayers to publish the message
        /// @note refund and delivery always fail if CREATE3 / CREATE2 is not used

        relayer.send{value: eData.relayerFee}(
            ambChainId[dstChainId_],
            castAddr(address(this)),
            castAddr(address(this)),
            eData.relayerFee,
            eData.airdrop,
            nonce
        );
    }

    /// @inheritdoc IAmbImplementation
    function broadcastPayload(bytes memory message_, bytes memory extraData_) external payable override {}

    /// @inheritdoc IWormholeReceiver
    function receiveWormholeMessages(bytes[] memory whMessages, bytes[] memory) public payable override onlyRelayer {
        (IWormhole.VM memory vm, bool valid, string memory reason) = bridge.parseAndVerifyVM(whMessages[0]);

        if (!valid) {
            revert Error.INVALID_WORMHOLE_PAYLOAD(reason);
        }

        /// @dev 1.should validate sender
        /// @dev 2.should validate message uniqueness

        /// @notice sender validation
        /// @note validation always fail if CREATE3 / CREATE2 is not used
        if (vm.emitterAddress != castAddr(address(this))) {
            revert Error.INVALID_CALLER();
        }

        /// @notice uniqueness validation
        if (processedMessages[vm.hash]) {
            revert Error.DUPLICATE_PAYLOAD();
        }

        processedMessages[vm.hash] = true;

        /// @dev decoding payload
        AMBMessage memory decoded = abi.decode(vm.payload, (AMBMessage));

        /// NOTE: experimental split of registry contracts
        (, , , uint8 registryId) = _decodeTxInfo(decoded.txInfo);
        /// FIXME: should migrate to support more state registry types
        address registryAddress = superRegistry.getStateRegistry(registryId);
        IBaseStateRegistry targetRegistry = IBaseStateRegistry(registryAddress);

        targetRegistry.receivePayload(superChainId[vm.emitterChainId], vm.payload);
    }

    /// @dev allows admin to add new chain ids in future
    /// @param superChainId_ is the identifier of the chain within superform protocol
    /// @param ambChainId_ is the identifier of the chain given by the AMB
    /// NOTE: cannot be defined in an interface as types vary for each message bridge (amb)
    function setChainId(uint16 superChainId_, uint16 ambChainId_) external onlyProtocolAdmin {
        if (superChainId_ == 0 || ambChainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        ambChainId[superChainId_] = ambChainId_;
        superChainId[ambChainId_] = superChainId_;

        emit ChainAdded(superChainId_);
    }

    /// @notice relayer contracts are used to forward messages
    /// @dev allows protocol admin to set the core relayer
    /// @param relayer_ is the identifier of the relayer address
    function setRelayer(IWormholeRelayer relayer_) external onlyProtocolAdmin {
        if (address(relayer_) == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        relayer = relayer_;
    }

    /*///////////////////////////////////////////////////////////////
                    Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev FIXME: should go into utils
    /// @dev casts an address to bytes32
    /// @param addr_ is the address to be casted
    /// @return a bytes32 casted variable of the address passed in params
    function castAddr(address addr_) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr_)) << 96);
    }
}

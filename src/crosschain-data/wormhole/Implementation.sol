// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IWormhole} from "./interface/IWormhole.sol";
import {IWormholeReceiver} from "./interface/IWormholeReceiver.sol";
import {IWormholeRelayer} from "./interface/IWormholeRelayer.sol";
import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {AccessControl} from "@openzeppelin-contracts/access/AccessControl.sol";
import {AMBMessage} from "../../types/DataTypes.sol";
import "../../utils/DataPacking.sol";

/// @title Wormhole implementation contract
/// @author Zeropoint Labs.
/// @dev interacts with Wormhole AMB.
///
/// @notice https://book.wormhole.com/wormhole/3_coreLayerContracts.html#multicasting
/// this contract uses multi-casting feature from wormhole
contract WormholeImplementation is
    IAmbImplementation,
    IWormholeReceiver,
    AccessControl
{
    struct ExtraData {
        uint256 messageFee;
        uint256 relayerFee;
        uint256 airdrop;
    }

    /// @dev users with WORMHOLE_RELAYER_ROLE can only deliver messages
    bytes32 public constant WORMHOLE_RELAYER_ROLE =
        bytes32("WORMHOLE_RELAYER_ROLE");

    /*///////////////////////////////////////////////////////////////
                    State Variables
    //////////////////////////////////////////////////////////////*/
    uint8 public constant CONSISTENCY_LEVEL = 1;

    IWormhole public immutable bridge;

    IBaseStateRegistry public immutable coreRegistry;
    IBaseStateRegistry public immutable factoryRegistry;

    /// @dev relayer will forward published wormhole messages
    IWormholeRelayer public relayer;

    mapping(uint16 => uint16) public ambChainId;
    mapping(uint16 => uint16) public superChainId;
    mapping(bytes32 => bool) public processedMessages;

    /*///////////////////////////////////////////////////////////////
                    Constructor
    //////////////////////////////////////////////////////////////*/

    /// @param bridge_ is the wormhole implementation for respective chain.
    constructor(
        IWormhole bridge_,
        IBaseStateRegistry coreRegistry_,
        IBaseStateRegistry factoryRegistry_,
        address relayer_
    ) {
        bridge = bridge_;
        coreRegistry = coreRegistry_;
        factoryRegistry = factoryRegistry_;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        /// @dev receiving relayer
        _setupRole(WORMHOLE_RELAYER_ROLE, relayer_);
    }

    /*///////////////////////////////////////////////////////////////
                    External Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice receive enables processing native token transfers into the smart contract.
    /// @dev socket.tech fails without a native receive function.
    receive() external payable {}

    /// @dev allows state registry to send message via implementation.
    /// @param dstChainId_ is the identifier of the destination chain
    /// @param message_ is the cross-chain message to be sent
    /// @param extraData_ is message amb specific override information
    function dispatchPayload(
        uint16 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable virtual override {
        if (msg.sender != address(coreRegistry)) {
            revert INVALID_CALLER();
        }
        bytes memory payload = abi.encode(msg.sender, dstChainId_, message_);
        ExtraData memory eData = abi.decode(extraData_, (ExtraData));

        /// FIXME: nonce is externally generated. can also be moved inside our contracts
        uint32 nonce = abi.decode(extraData_, (uint32));

        bridge.publishMessage{value: eData.messageFee}(
            nonce,
            payload,
            CONSISTENCY_LEVEL
        );

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

    function broadcastPayload(
        bytes memory message_,
        bytes memory extraData_
    ) external payable override {}

    function receiveWormholeMessages(
        bytes[] memory whMessages,
        bytes[] memory
    ) public payable override onlyRole(WORMHOLE_RELAYER_ROLE) {
        (IWormhole.VM memory vm, bool valid, string memory reason) = bridge
            .parseAndVerifyVM(whMessages[0]);

        require(valid, reason);

        /// @dev 1.should validate sender
        /// @dev 2.should validate message uniqueness

        /// @notice sender validation
        /// @note validation always fail if CREATE3 / CREATE2 is not used
        if (vm.emitterAddress != castAddr(address(this))) {
            revert INVALID_CALLER();
        }

        /// @notice uniqueness validation
        if (processedMessages[vm.hash]) {
            revert DUPLICATE_PAYLOAD();
        }

        processedMessages[vm.hash] = true;

        /// @dev decoding payload
        AMBMessage memory decoded = abi.decode(vm.payload, (AMBMessage));

        /// NOTE: experimental split of registry contracts
        (, , , uint8 registryId) = _decodeTxInfo(decoded.txInfo);
        /// FIXME: should migrate to support more state registry types
        if (registryId == 0) {
            coreRegistry.receivePayload(
                superChainId[vm.emitterChainId],
                vm.payload
            );
        } else {
            factoryRegistry.receivePayload(
                superChainId[vm.emitterChainId],
                vm.payload
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
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (superChainId_ == 0 || ambChainId_ == 0) {
            revert INVALID_CHAIN_ID();
        }

        ambChainId[superChainId_] = ambChainId_;
        superChainId[ambChainId_] = superChainId_;

        emit ChainAdded(superChainId_);
    }

    /// @notice relayer contracts are used to forward messages
    /// @dev allows admin to set the core relayer
    /// @param relayer_ is the identifier of the relayer address
    function setRelayer(
        IWormholeRelayer relayer_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(relayer_) == address(0)) {
            revert ZERO_ADDRESS();
        }

        relayer = relayer_;
    }

    /*///////////////////////////////////////////////////////////////
                    Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev converts address to bytes32
    function castAddr(address addr_) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr_)) << 96);
    }
}

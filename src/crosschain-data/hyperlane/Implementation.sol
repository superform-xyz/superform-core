// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {IMailbox} from "./interface/IMailbox.sol";
import {IMessageRecipient} from "./interface/IMessageRecipient.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IInterchainGasPaymaster} from "./interface/IInterchainGasPaymaster.sol";
import {AMBMessage} from "../../types/DataTypes.sol";
import {Error} from "../../utils/Error.sol";
import "../../utils/DataPacking.sol";

/// @title Hyperlane implementation contract
/// @author Zeropoint Labs
///
/// @dev interacts with hyperlane AMB
contract HyperlaneImplementation is
    IAmbImplementation,
    IMessageRecipient,
    Ownable
{
    /*///////////////////////////////////////////////////////////////
                    State Variables
    //////////////////////////////////////////////////////////////*/
    IMailbox public immutable mailbox;
    IInterchainGasPaymaster public immutable igp;
    ISuperRegistry public immutable superRegistry;

    uint32[] public broadcastChains;

    mapping(uint16 => uint32) public ambChainId;
    mapping(uint32 => uint16) public superChainId;
    mapping(uint32 => address) public authorizedImpl;

    mapping(bytes32 => bool) public processedMessages;

    /*///////////////////////////////////////////////////////////////
                    Constructor
    //////////////////////////////////////////////////////////////*/

    /// @param mailbox_ is the hyperlane mailbox for respective chain.
    constructor(
        IMailbox mailbox_,
        IInterchainGasPaymaster igp_,
        ISuperRegistry superRegistry_
    ) {
        mailbox = mailbox_;
        igp = igp_;
        superRegistry = superRegistry_;
    }

    /*///////////////////////////////////////////////////////////////
                    External Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice receive enables processing native token transfers into the smart contract.
    /// @dev hyperlane gas payments/refund fails without a native receive function.
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
        IBaseStateRegistry coreRegistry = IBaseStateRegistry(
            superRegistry.coreStateRegistry()
        );
        IBaseStateRegistry factoryRegistry = IBaseStateRegistry(
            superRegistry.factoryStateRegistry()
        );

        if (
            msg.sender != address(coreRegistry) &&
            msg.sender != address(factoryRegistry)
        ) {
            revert Error.INVALID_CALLER();
        }

        uint32 domain = ambChainId[dstChainId_];
        /// FIXME: works only on EVM-networks & contracts using CREATE2/CREATE3
        bytes32 messageId = mailbox.dispatch(
            domain,
            castAddr(authorizedImpl[domain]),
            message_
        );

        igp.payForGas{value: msg.value}(
            messageId,
            domain,
            500000, // @dev FIXME hardcoded to 500k abi.decode(extraData_, (uint256)),
            msg.sender /// @dev should refund to the user, now refunds to core state registry
        );
    }

    /// @dev allows state registry to send multiple messages via implementation
    /// @param message_ is the cross-chain message to be sent
    /// @param extraData_ is the message amb specific override information
    function broadcastPayload(
        bytes memory message_,
        bytes memory extraData_
    ) external payable virtual {
        IBaseStateRegistry coreRegistry = IBaseStateRegistry(
            superRegistry.coreStateRegistry()
        );
        IBaseStateRegistry factoryRegistry = IBaseStateRegistry(
            superRegistry.factoryStateRegistry()
        );

        if (
            msg.sender != address(coreRegistry) &&
            msg.sender != address(factoryRegistry)
        ) {
            revert Error.INVALID_CALLER();
        }

        uint256 totalChains = broadcastChains.length;
        for (uint16 i = 0; i < totalChains; i++) {
            uint32 domain = broadcastChains[i];

            bytes32 messageId = mailbox.dispatch(
                domain,
                castAddr(authorizedImpl[domain]),
                message_
            );

            igp.payForGas{value: msg.value / totalChains}(
                messageId,
                domain,
                500000, // @dev FIXME hardcoded to 500k abi.decode(extraData_, (uint256)),
                msg.sender /// @dev should refund to the user, now refunds to core state registry
            );
        }
    }

    /// @notice to add access based controls over here
    /// @dev allows admin to add new chain ids in future
    /// @param superChainId_ is the identifier of the chain within superform protocol
    /// @param ambChainId_ is the identifier of the chain given by the AMB
    function setChainId(
        uint16 superChainId_,
        uint32 ambChainId_
    ) external onlyOwner {
        if (superChainId_ == 0 || ambChainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        ambChainId[superChainId_] = ambChainId_;
        superChainId[ambChainId_] = superChainId_;

        /// NOTE: @dev should handle a way to pop
        broadcastChains.push(ambChainId_);

        emit ChainAdded(superChainId_);
    }

    function setReceiver(
        uint32 domain_,
        address authorizedImpl_
    ) external onlyOwner {
        if (domain_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        if (authorizedImpl_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        authorizedImpl[domain_] = authorizedImpl_;
    }

    /// @notice Handle an interchain message
    /// @notice Only called by mailbox
    ///
    /// @param origin_ Domain ID of the chain from which the message came
    /// @param sender_ Address of the message sender on the origin chain as bytes32
    /// @param body_ Raw bytes content of message body
    function handle(
        uint32 origin_,
        bytes32 sender_,
        bytes calldata body_
    ) external override {
        /// @dev 1. validate caller
        /// @dev 2. validate src chain sender
        /// @dev 3. validate message uniqueness
        if (msg.sender != address(mailbox)) {
            revert Error.INVALID_CALLER();
        }

        // if (sender_ != castAddr(authorizedImpl[origin_])) {
        //     revert Error.INVALID_CALLER();
        // }

        bytes32 hash = keccak256(body_);

        if (processedMessages[hash]) {
            revert Error.DUPLICATE_PAYLOAD();
        }

        processedMessages[hash] = true;

        /// @dev decoding payload
        AMBMessage memory decoded = abi.decode(body_, (AMBMessage));

        /// NOTE: experimental split of registry contracts
        (, , , uint8 registryId) = _decodeTxInfo(decoded.txInfo);
        /// FIXME: should migrate to support more state registry types
        if (registryId == 0) {
            IBaseStateRegistry coreRegistry = IBaseStateRegistry(
                superRegistry.coreStateRegistry()
            );

            coreRegistry.receivePayload(superChainId[origin_], body_);
        } else {
            IBaseStateRegistry factoryRegistry = IBaseStateRegistry(
                superRegistry.factoryStateRegistry()
            );
            factoryRegistry.receivePayload(superChainId[origin_], body_);
        }
    }

    /*///////////////////////////////////////////////////////////////
                    Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev converts address to bytes32
    function castAddr(address addr_) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr_)));
    }
}

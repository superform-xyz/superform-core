// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {IMailbox} from "./interface/IMailbox.sol";
import {IMessageRecipient} from "./interface/IMessageRecipient.sol";
import {IInterchainGasPaymaster} from "./interface/IInterchainGasPaymaster.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Hyperlane implementation contract
/// @author Zeropoint Labs
///
/// @dev interacts with hyperlane AMB
contract HyperlaneImplementation is
    IAmbImplementation,
    IMessageRecipient,
    Ownable
{
    error INVALID_RECEIVER();
    event HeyHey();
    /*///////////////////////////////////////////////////////////////
                    State Variables
    //////////////////////////////////////////////////////////////*/
    IBaseStateRegistry public immutable registry;
    IMailbox public immutable mailbox;
    IInterchainGasPaymaster public immutable igp;

    mapping(uint80 => uint32) public ambChainId;
    mapping(uint32 => uint80) public superChainId;
    mapping(uint32 => address) public authorizedImpl;

    mapping(bytes32 => bool) public processedMessages;

    /*///////////////////////////////////////////////////////////////
                    Constructor
    //////////////////////////////////////////////////////////////*/

    /// @param mailbox_ is the hyperlane mailbox for respective chain.
    constructor(
        IMailbox mailbox_,
        IBaseStateRegistry registry_,
        IInterchainGasPaymaster igp_
    ) {
        registry = registry_;
        mailbox = mailbox_;
        igp = igp_;
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
    function dipatchPayload(
        uint80 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable virtual override {
        if (msg.sender != address(registry)) {
            revert INVALID_CALLER();
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
            ambChainId[dstChainId_],
            500000, // @dev FIXME hardcoded to 500k abi.decode(extraData_, (uint256)),
            msg.sender /// @dev should refund to the user, now refunds to core state registry
        );
    }

    /// @notice to add access based controls over here
    /// @dev allows admin to add new chain ids in future
    /// @param superChainId_ is the identifier of the chain within superform protocol
    /// @param ambChainId_ is the identifier of the chain given by the AMB
    function setChainId(
        uint80 superChainId_,
        uint32 ambChainId_
    ) external onlyOwner {
        if (superChainId_ == 0 || ambChainId_ == 0) {
            revert INVALID_CHAIN_ID();
        }

        ambChainId[superChainId_] = ambChainId_;
        superChainId[ambChainId_] = superChainId_;

        emit ChainAdded(superChainId_);
    }

    function setReceiver(
        uint32 domain_,
        address authorizedImpl_
    ) external onlyOwner {
        if (domain_ == 0) {
            revert INVALID_CHAIN_ID();
        }

        if (authorizedImpl_ == address(0)) {
            revert INVALID_RECEIVER();
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
            revert INVALID_CALLER();
        }

        if (sender_ != castAddr(authorizedImpl[origin_])) {
            revert INVALID_CALLER();
        }

        bytes32 hash = keccak256(body_);

        if (processedMessages[hash]) {
            revert DUPLICATE_PAYLOAD();
        }

        processedMessages[hash] = true;
        registry.receivePayload(superChainId[origin_], body_);

        emit HeyHey();
    }

    /*///////////////////////////////////////////////////////////////
                    Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev converts address to bytes32
    function castAddr(address addr_) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr_)) << 96);
    }
}

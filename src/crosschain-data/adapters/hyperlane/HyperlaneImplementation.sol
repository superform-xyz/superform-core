// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";
import { IMailbox } from "src/vendor/hyperlane/IMailbox.sol";
import { IMessageRecipient } from "src/vendor/hyperlane/IMessageRecipient.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IInterchainGasPaymaster } from "src/vendor/hyperlane/IInterchainGasPaymaster.sol";
import { AMBMessage } from "src/types/DataTypes.sol";
import { Error } from "src/utils/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";

/// @title HyperlaneImplementation
/// @author Zeropoint Labs
/// @dev allows state registries to use hyperlane for crosschain communication
contract HyperlaneImplementation is IAmbImplementation, IMessageRecipient {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/
    IMailbox public immutable mailbox;
    IInterchainGasPaymaster public immutable igp;
    ISuperRegistry public immutable superRegistry;

    mapping(uint64 => uint32) public ambChainId;
    mapping(uint32 => uint64) public superChainId;
    mapping(uint32 => address) public authorizedImpl;

    mapping(bytes32 => bool) public processedMessages;

    /*///////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/
    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/
    /// @param mailbox_ is the hyperlane mailbox for respective chain.
    constructor(IMailbox mailbox_, IInterchainGasPaymaster igp_, ISuperRegistry superRegistry_) {
        mailbox = mailbox_;
        igp = igp_;
        superRegistry = superRegistry_;
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice receive enables processing native token transfers into the smart contract.
    /// @dev hyperlane gas payments/refund fails without a native receive function.
    receive() external payable { }

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
    {
        if (!superRegistry.isValidStateRegistry(msg.sender)) {
            revert Error.NOT_STATE_REGISTRY();
        }

        uint32 domain = ambChainId[dstChainId_];
        bytes32 messageId = mailbox.dispatch(domain, _castAddr(authorizedImpl[domain]), message_);

        igp.payForGas{ value: msg.value }(
            messageId, domain, extraData_.length > 0 ? abi.decode(extraData_, (uint256)) : 0, srcSender_
        );
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

        if (oldSuperChainId > 0) {
            ambChainId[oldSuperChainId] = 0;
        }

        if (oldAmbChainId > 0) {
            superChainId[oldAmbChainId] = 0;
        }

        ambChainId[superChainId_] = ambChainId_;
        superChainId[ambChainId_] = superChainId_;

        emit ChainAdded(superChainId_);
    }

    /// @dev allows protocol admin to set receiver implmentation on a new chain id
    /// @param domain_ is the identifier of the destination chain within hyperlane
    /// @param authorizedImpl_ is the implementation of the hyperlane message bridge on the specified destination
    /// NOTE: cannot be defined in an interface as types vary for each message bridge (amb)
    function setReceiver(uint32 domain_, address authorizedImpl_) external onlyProtocolAdmin {
        if (domain_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        if (authorizedImpl_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        authorizedImpl[domain_] = authorizedImpl_;
    }

    /// @inheritdoc IMessageRecipient
    function handle(uint32 origin_, bytes32 sender_, bytes calldata body_) external override {
        /// @dev 1. validate caller
        /// @dev 2. validate src chain sender
        /// @dev 3. validate message uniqueness
        if (msg.sender != address(mailbox)) {
            revert Error.CALLER_NOT_MAILBOX();
        }

        if (sender_ != _castAddr(authorizedImpl[origin_])) {
            revert Error.INVALID_SRC_SENDER();
        }

        bytes32 hash = keccak256(body_);

        if (processedMessages[hash]) {
            revert Error.DUPLICATE_PAYLOAD();
        }

        processedMessages[hash] = true;

        /// @dev decoding payload
        AMBMessage memory decoded = abi.decode(body_, (AMBMessage));

        /// NOTE: experimental split of registry contracts
        (,,, uint8 registryId,,) = decoded.txInfo.decodeTxInfo();
        address registryAddress = superRegistry.getStateRegistry(registryId);
        IBaseStateRegistry targetRegistry = IBaseStateRegistry(registryAddress);

        targetRegistry.receivePayload(superChainId[origin_], body_);
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
        uint32 domain = ambChainId[dstChainId_];

        if (domain != 0) {
            fees = igp.quoteGasPayment(domain, abi.decode(extraData_, (uint256)));
        }
    }

    /*///////////////////////////////////////////////////////////////
                    Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev casts an address to bytes32
    /// @param addr_ is the address to be casted
    /// @return a bytes32 casted variable of the address passed in params
    function _castAddr(address addr_) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr_)));
    }
}

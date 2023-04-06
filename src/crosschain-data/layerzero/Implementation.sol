// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "./NonblockingLzApp.sol";
import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {AMBMessage} from "../../types/DataTypes.sol";
import "../../utils/DataPacking.sol";

/// @title Layerzero implementation contract
/// @author Zeropoint Labs.
/// @dev interacts with Layerzero AMB.
contract LayerzeroImplementation is NonblockingLzApp, IAmbImplementation {
    uint256 private constant RECEIVER_OFFSET = 1;

    /*///////////////////////////////////////////////////////////////
                    State Variables
    //////////////////////////////////////////////////////////////*/
    uint16[] public broadcastChains;
    ISuperRegistry public superRegistry;

    /// @dev prevents layerzero relayer from replaying payload
    mapping(uint16 => mapping(uint64 => bool)) public isValid;

    mapping(uint16 => uint16) public ambChainId;
    mapping(uint16 => uint16) public superChainId;

    /*///////////////////////////////////////////////////////////////
                    Constructor
    //////////////////////////////////////////////////////////////*/

    /// @param endpoint_ is the layer zero endpoint for respective chain.
    constructor(
        address endpoint_,
        ISuperRegistry superRegistry_
    ) NonblockingLzApp(endpoint_) {
        superRegistry = superRegistry_;
    }

    /*///////////////////////////////////////////////////////////////
                    External Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice receive enables processing native token transfers into the smart contract.
    /// @dev layerzero gas payments/refund fails without a native receive function.
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
            revert INVALID_CALLER();
        }

        _lzSend(
            ambChainId[dstChainId_],
            message_,
            payable(msg.sender),
            address(0x0),
            extraData_,
            msg.value
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
            revert INVALID_CALLER();
        }

        for (uint16 i = 0; i < broadcastChains.length; i++) {
            uint16 dstChainId = broadcastChains[i];
            _lzSend(
                dstChainId,
                message_,
                payable(msg.sender),
                address(0x0),
                extraData_,
                msg.value / broadcastChains.length
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
    ) external onlyOwner {
        ambChainId[superChainId_] = ambChainId_;
        superChainId[ambChainId_] = superChainId_;

        /// NOTE: @dev should handle a way to pop
        broadcastChains.push(ambChainId_);
    }

    /*///////////////////////////////////////////////////////////////
                    Internal Functions
    //////////////////////////////////////////////////////////////*/
    /// @dev override function to process messages received via L0
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        if (isValid[_srcChainId][_nonce] == true) {
            revert DUPLICATE_PAYLOAD();
        }

        /// NOTE: changing state earlier to prevent re-entrancy.
        isValid[_srcChainId][_nonce] = true;

        /// @dev decodes payload received
        AMBMessage memory decoded = abi.decode(_payload, (AMBMessage));

        /// NOTE: experimental split of registry contracts
        (, , , uint8 registryId) = _decodeTxInfo(decoded.txInfo);

        /// FIXME: should migrate to support more state registry types
        if (registryId == 0) {
            IBaseStateRegistry coreRegistry = IBaseStateRegistry(
                superRegistry.coreStateRegistry()
            );
            coreRegistry.receivePayload(superChainId[_srcChainId], _payload);
        } else {
            IBaseStateRegistry factoryRegistry = IBaseStateRegistry(
                superRegistry.factoryStateRegistry()
            );
            factoryRegistry.receivePayload(superChainId[_srcChainId], _payload);
        }
    }
}

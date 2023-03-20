// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "./NonblockingLzApp.sol";
import {IStateRegistry} from "../../interfaces/IStateRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {StateData, CallbackType} from "../../types/DataTypes.sol";

/// @title Layerzero implementation contract
/// @author Zeropoint Labs.
/// @dev interacts with Layerzero AMB.
contract LayerzeroImplementation is NonblockingLzApp, IAmbImplementation {
    /*///////////////////////////////////////////////////////////////
                    State Variables
    //////////////////////////////////////////////////////////////*/
    IStateRegistry public immutable registry;

    /// @dev prevents layerzero relayer from replaying payload
    mapping(uint16 => mapping(uint64 => bool)) public isValid;

    mapping(uint80 => uint16) public ambChainId;
    mapping(uint16 => uint80) public superChainId;

    /*///////////////////////////////////////////////////////////////
                    Constructor
    //////////////////////////////////////////////////////////////*/

    /// @param endpoint_ is the layer zero endpoint for respective chain.
    constructor(
        address endpoint_,
        IStateRegistry registry_
    ) NonblockingLzApp(endpoint_) {
        registry = registry_;
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
    function dipatchPayload(
        uint80 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable virtual override {
        if (msg.sender != address(registry)) {
            revert INVALID_CALLER();
        }

        _lzSend(
            ambChainId[dstChainId_],
            message_,
            payable(msg.sender),
            address(0x0),
            extraData_
        );
    }

    /// @notice to add access based controls over here
    /// @dev allows admin to add new chain ids in future
    /// @param superChainId_ is the identifier of the chain within superform protocol
    /// @param ambChainId_ is the identifier of the chain given by the AMB
    function setChainId(
        uint80 superChainId_,
        uint16 ambChainId_
    ) external override onlyOwner {
        ambChainId[superChainId_] = ambChainId_;
        superChainId[ambChainId_] = superChainId_;
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

        /// NOTE: add _srcAddress validation
        registry.receivePayload(superChainId[_srcChainId], _payload);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

import {IWormhole} from "./interface/IWormhole.sol";
import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {StateData, CallbackType} from "../../types/DataTypes.sol";

/// @title Wormhole implementation contract
/// @author Zeropoint Labs.
/// @dev interacts with Wormhole AMB.
///
/// @notice https://book.wormhole.com/wormhole/3_coreLayerContracts.html#multicasting
/// this contract uses multi-casting feature from wormhole
contract WormholeImplementation is IAmbImplementation, Ownable {
    /*///////////////////////////////////////////////////////////////
                    State Variables
    //////////////////////////////////////////////////////////////*/
    uint8 public constant CONSISTENCY_LEVEL = 1;

    IWormhole public immutable bridge;
    IBaseStateRegistry public immutable registry;

    mapping(uint80 => uint16) public ambChainId;
    mapping(uint16 => uint80) public superChainId;

    /*///////////////////////////////////////////////////////////////
                    Constructor
    //////////////////////////////////////////////////////////////*/

    /// @param bridge_ is the wormhole implementation for respective chain.
    constructor(IWormhole bridge_, IBaseStateRegistry registry_) {
        bridge = bridge_;
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

        bytes memory payload = abi.encode(msg.sender, dstChainId_, message_);

        /// FIXME: nonce is externally generated. can also be moved inside our contracts
        uint32 nonce = abi.decode(extraData_, (uint32));

        bridge.publishMessage{value: msg.value}(
            nonce,
            payload,
            CONSISTENCY_LEVEL
        );
    }

    /// @notice to add access based controls over here
    /// @dev allows admin to add new chain ids in future
    /// @param superChainId_ is the identifier of the chain within superform protocol
    /// @param ambChainId_ is the identifier of the chain given by the AMB
    function setChainId(uint80 superChainId_, uint16 ambChainId_)
        external
        override
        onlyOwner
    {
        ambChainId[superChainId_] = ambChainId_;
        superChainId[ambChainId_] = superChainId_;
    }

    /*///////////////////////////////////////////////////////////////
                    Internal Functions
    //////////////////////////////////////////////////////////////*/
}

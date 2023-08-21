// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {Error} from "../../utils/Error.sol";
import {BaseStateRegistry} from "../BaseStateRegistry.sol";
import {IBroadcaster} from "../../interfaces/IBroadcaster.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {AMBMessage, AMBExtraData} from "../../types/DataTypes.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {DataLib} from "../../libraries/DataLib.sol";

/// @title Broadcaster
/// @author ZeroPoint Labs
/// @dev separates brodcasting concerns into an abstract implementation
abstract contract Broadcaster is IBroadcaster, BaseStateRegistry {
    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    ///@dev set up admin during deployment.
    constructor(ISuperRegistry superRegistry_) BaseStateRegistry(superRegistry_) {}

    /// @inheritdoc IBroadcaster
    function broadcastPayload(
        address srcSender_,
        uint8[] memory ambIds_,
        uint64[] memory dstChainIds_,
        bytes memory message_,
        bytes memory extraData_
    ) external payable override onlySender {
        AMBExtraData memory d = abi.decode(extraData_, (AMBExtraData));

        _broadcastPayload(srcSender_, ambIds_[0], dstChainIds_, d.gasPerAMB[0], message_, d.extraDataPerAMB[0]);

        if (ambIds_.length > 1) {
            _broadcastProof(srcSender_, ambIds_, dstChainIds_, d.gasPerAMB, message_, d.extraDataPerAMB);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev broadcasts the payload(message_) through individual message bridge implementations
    function _broadcastPayload(
        address srcSender_,
        uint8 ambId_,
        uint64[] memory dstChainIds_,
        uint256 gasToPay_,
        bytes memory message_,
        bytes memory extraData_
    ) internal {
        /// @dev when broadcasting, txType, callbackType and multi are set to their default values as they are unused
        AMBMessage memory newData = AMBMessage(
            DataLib.packTxInfo(
                0,
                0,
                0,
                superRegistry.getStateRegistryId(address(this)),
                srcSender_,
                superRegistry.chainId()
            ),
            message_
        );

        IAmbImplementation ambImplementation = IAmbImplementation(superRegistry.getAmbAddress(ambId_));

        /// @dev reverts if an unknown amb id is used
        if (address(ambImplementation) == address(0)) {
            revert Error.INVALID_BRIDGE_ID();
        }

        ambImplementation.broadcastPayload{value: gasToPay_}(srcSender_, dstChainIds_, abi.encode(newData), extraData_);
    }

    /// @dev broadcasts the proof(hash of the message_) through individual message bridge implementations
    function _broadcastProof(
        address srcSender_,
        uint8[] memory ambIds_,
        uint64[] memory dstChainIds_,
        uint256[] memory gasToPay_,
        bytes memory message_,
        bytes[] memory extraData_
    ) internal {
        bytes memory proof = abi.encode(keccak256(message_));

        /// @dev when broadcasting, txType, callbackType and multi are set to their default values as they are unused
        AMBMessage memory newData = AMBMessage(
            DataLib.packTxInfo(
                0,
                0,
                0,
                superRegistry.getStateRegistryId(address(this)),
                srcSender_,
                superRegistry.chainId()
            ),
            proof
        );

        for (uint8 i = 1; i < ambIds_.length; ) {
            uint8 tempAmbId = ambIds_[i];

            /// @dev the loaded ambId cannot be the same as the ambId used for messaging
            if (tempAmbId == ambIds_[0]) {
                revert Error.INVALID_PROOF_BRIDGE_ID();
            }

            IAmbImplementation tempImpl = IAmbImplementation(superRegistry.getAmbAddress(tempAmbId));

            if (address(tempImpl) == address(0)) {
                revert Error.INVALID_BRIDGE_ID();
            }

            tempImpl.broadcastPayload{value: gasToPay_[i]}(
                srcSender_,
                dstChainIds_,
                abi.encode(newData),
                extraData_[i]
            );

            unchecked {
                ++i;
            }
        }
    }
}

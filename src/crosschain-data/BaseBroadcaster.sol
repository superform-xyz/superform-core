// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { Error } from "src/utils/Error.sol";
import { IBaseBroadcaster } from "src/interfaces/IBaseBroadcaster.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { AMBMessage, AMBExtraData } from "src/types/DataTypes.sol";
import { IBroadcastAmbImplementation } from "src/interfaces/IBroadcastAmbImplementation.sol";
import { DataLib } from "src/libraries/DataLib.sol";

/// @title BaseBroadcaster
/// @author ZeroPoint Labs
/// @notice helps core contract communicate with multiple dst chains through supported AMBs
abstract contract BaseBroadcaster is IBaseBroadcaster {
    /*///////////////////////////////////////////////////////////////
                              STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public superRegistry;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    ///@dev set up admin during deployment.
    constructor(ISuperRegistry superRegistry_) {
        superRegistry = superRegistry_;
    }

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev sender varies based on functionality
    /// @notice inheriting contracts should override this function (else not safe)
    /// @dev with general revert to protect dispatchPaylod in case of non override
    modifier onlySender() virtual {
        revert Error.DISABLED();
        _;
    }

    /// @inheritdoc IBaseBroadcaster
    function broadcastPayload(
        address srcSender_,
        uint8[] memory ambIds_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        payable
        override
        onlySender
    {
        AMBExtraData memory d = abi.decode(extraData_, (AMBExtraData));

        _broadcastPayload(srcSender_, ambIds_[0], d.gasPerAMB[0], message_, d.extraDataPerAMB[0]);

        if (ambIds_.length > 1) {
            _broadcastProof(srcSender_, ambIds_, d.gasPerAMB, message_, d.extraDataPerAMB);
        }
    }

    /// @inheritdoc IBaseBroadcaster
    function receivePayload(uint64 srcChainId_, bytes memory message_) external override { }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev broadcasts the payload(message_) through individual message bridge implementations
    function _broadcastPayload(
        address srcSender_,
        uint8 ambId_,
        uint256 gasToPay_,
        bytes memory message_,
        bytes memory extraData_
    )
        internal
    {
        /// @dev when broadcasting, txType, callbackType and multi are set to their default values as they are unused
        AMBMessage memory newData = AMBMessage(
            DataLib.packTxInfo(
                0, 0, 0, superRegistry.getStateRegistryId(address(this)), srcSender_, superRegistry.chainId()
            ),
            message_
        );

        IBroadcastAmbImplementation ambImplementation = IBroadcastAmbImplementation(superRegistry.getAmbAddress(ambId_));

        /// @dev reverts if an unknown amb id is used
        if (address(ambImplementation) == address(0)) {
            revert Error.INVALID_BRIDGE_ID();
        }

        ambImplementation.broadcastPayload{ value: gasToPay_ }(srcSender_, abi.encode(newData), extraData_);
    }

    /// @dev broadcasts the proof(hash of the message_) through individual message bridge implementations
    function _broadcastProof(
        address srcSender_,
        uint8[] memory ambIds_,
        uint256[] memory gasToPay_,
        bytes memory message_,
        bytes[] memory extraData_
    )
        internal
    {
        bytes memory proof = abi.encode(keccak256(message_));

        /// @dev when broadcasting, txType, callbackType and multi are set to their default values as they are unused
        AMBMessage memory newData = AMBMessage(
            DataLib.packTxInfo(
                0, 0, 0, superRegistry.getStateRegistryId(address(this)), srcSender_, superRegistry.chainId()
            ),
            proof
        );

        for (uint8 i = 1; i < ambIds_.length;) {
            uint8 tempAmbId = ambIds_[i];

            /// @dev the loaded ambId cannot be the same as the ambId used for messaging
            if (tempAmbId == ambIds_[0]) {
                revert Error.INVALID_PROOF_BRIDGE_ID();
            }

            IBroadcastAmbImplementation tempImpl = IBroadcastAmbImplementation(superRegistry.getAmbAddress(tempAmbId));

            if (address(tempImpl) == address(0)) {
                revert Error.INVALID_BRIDGE_ID();
            }

            tempImpl.broadcastPayload{ value: gasToPay_[i] }(srcSender_, abi.encode(newData), extraData_[i]);

            unchecked {
                ++i;
            }
        }
    }
}

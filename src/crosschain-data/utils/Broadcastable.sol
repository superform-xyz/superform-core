// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IBroadcastRegistry } from "src/interfaces/IBroadcastRegistry.sol";
import { Error } from "src/libraries/Error.sol";

/// @title Broadcastable
/// @dev Can be inherited in contracts that wish to support broadcasting
/// @author ZeroPoint Labs
abstract contract Broadcastable {
    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev interacts with role state registry to broadcasting state changes to all connected remote chains
    /// @param broadcastRegistry_ is the address of the broadcast registry contract.
    /// @param payMaster_ is the address of the paymaster contract.
    /// @param message_ is the crosschain message to be sent.
    /// @param extraData_ is the amb override information.
    function _broadcast(
        address broadcastRegistry_,
        address payMaster_,
        bytes memory message_,
        bytes memory extraData_
    )
        internal
    {
        (uint8 ambId, bytes memory broadcastParams) = abi.decode(extraData_, (uint8, bytes));

        /// @dev if the broadcastParams are wrong this will revert
        (uint256 gasFee, bytes memory extraData) = abi.decode(broadcastParams, (uint256, bytes));

        if (msg.value < gasFee) {
            revert Error.INVALID_BROADCAST_FEE();
        }

        /// @dev ambIds are validated inside the broadcast state registry
        IBroadcastRegistry(broadcastRegistry_).broadcastPayload{ value: gasFee }(
            msg.sender, ambId, gasFee, message_, extraData
        );

        if (msg.value > gasFee) {
            /// @dev forwards the rest to paymaster
            (bool success,) = payable(payMaster_).call{ value: msg.value - gasFee }("");

            if (!success) {
                revert Error.FAILED_TO_SEND_NATIVE();
            }
        }
    }
}

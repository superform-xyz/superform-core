/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import { InitSingleVaultData } from "../types/DataTypes.sol";

interface IEmergencyQueue {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event WithdrawalQueued(
        address indexed srcAddress,
        address indexed refundAddress,
        uint256 indexed id,
        uint256 superformId,
        uint256 amount,
        uint256 srcPayloadId
    );

    event WithdrawalProcessed(address indexed refundAddress, uint256 indexed id, uint256 superformId, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev called by paused forms to queue up withdrawals for exit
    /// @param data_ is the single vault data passed by the user
    function queueWithdrawal(InitSingleVaultData memory data_, address srcSender_) external;

    /// @dev alled by emergency admin to processed queued withdrawal
    /// @param id_ is the identifier of the queued action
    function executeQueuedWithdrawal(uint256 id_) external;
}

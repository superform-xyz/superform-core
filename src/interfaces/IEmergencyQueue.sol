/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { InitSingleVaultData } from "../types/DataTypes.sol";

interface IEmergencyQueue {

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    event WithdrawalQueued(
        address indexed srcAddress,
        address indexed refundAddress,
        uint256 indexed id,
        uint256 superformId,
        uint256 amount,
        uint256 srcPayloadId
    );

    event WithdrawalProcessed(address indexed refundAddress, uint256 indexed id, uint256 superformId, uint256 amount);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev returns the execution status of an id in the emergency queue
    /// @param id is the identifier of the queued action
    /// @return boolean representing the execution status
    function queuedWithdrawalStatus(uint256 id) external view returns (bool);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev called by paused forms to queue up withdrawals for exit
    /// @param data_ is the single vault data passed by the user
    function queueWithdrawal(InitSingleVaultData memory data_, address srcSender_) external;

    /// @dev called by emergency admin to processed queued withdrawal
    /// @param id_ is the identifier of the queued action
    function executeQueuedWithdrawal(uint256 id_) external;

    /// @dev called by emergency admin to batch process queued withdrawals
    /// @param ids_ is the array of identifiers of the queued actions
    function batchExecuteQueuedWithdrawal(uint256[] memory ids_) external;
}
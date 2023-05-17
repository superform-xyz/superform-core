// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

/// @dev is imported from (https://github.com/celer-network/sgn-v2-contracts/blob/main/contracts/message/interfaces/IMessageReceiverApp.sol)
interface IMessageReceiver {
    enum ExecutionStatus {
        Fail, // execution failed, finalized
        Success, // execution succeeded, finalized
        Retry // execution rejected, can retry later
    }

    /// @notice Called by MessageBus to execute a message
    /// @param _sender The address of the source app contract
    /// @param _srcChainId The source chain ID where the transfer is originated from
    /// @param _message Arbitrary message bytes originated from and encoded by the source app contract
    /// @param _executor Address who called the MessageBus execution function
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);
}

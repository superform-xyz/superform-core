// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title IPaymentHelperExtn
/// @dev Interface for PaymentHelperExtn, which estimates costs for various operations
/// @author ZeroPoint Labs
interface IPaymentHelperExtn {
    /// @notice Estimates the cost for rebalancing a single position
    /// @param callData_ The encoded data for the withdrawal
    /// @param rebalanceCallData_ The encoded data for the deposit after rebalance
    /// @return msgValue The estimated cost of the operation
    function estimateRebalanceSinglePosition(
        bytes calldata callData_,
        bytes calldata rebalanceCallData_
    )
        external
        view
        returns (uint256 msgValue);

    /// @notice Estimates the cost for rebalancing multiple positions
    /// @param callData_ The encoded data for the withdrawals
    /// @param rebalanceCallData_ The encoded data for the deposits after rebalance
    /// @return msgValue The estimated cost of the operation
    function estimateRebalanceMultiPositions(
        bytes calldata callData_,
        bytes calldata rebalanceCallData_
    )
        external
        view
        returns (uint256 msgValue);

    /// @notice Estimates the cost for a cross-chain rebalance of a single position
    /// @param callData_ The encoded data for the withdrawal
    /// @param rebalanceCallData_ The encoded data for the deposit after rebalance
    /// @return msgValue The estimated cost of the operation
    function estimateCrossChainRebalance(
        bytes calldata callData_,
        bytes calldata rebalanceCallData_
    )
        external
        view
        returns (uint256 msgValue);

    /// @notice Estimates the cost for a cross-chain rebalance of multiple positions
    /// @param callData_ The encoded data for the withdrawals
    /// @param rebalanceCallData_ The encoded data for the deposits after rebalance
    /// @return msgValue The estimated cost of the operation
    function estimateCrossChainRebalanceMulti(
        bytes calldata callData_,
        bytes calldata rebalanceCallData_
    )
        external
        view
        returns (uint256 msgValue);

    /// @notice Estimates the cost for depositing into a 4626 vault
    /// @param callData_ The encoded data for the deposit
    /// @return msgValue The estimated cost of the operation
    function estimateDeposit4626(bytes calldata callData_) external view returns (uint256 msgValue);

    /// @notice Estimates the cost for a deposit
    /// @param callData_ The encoded data for the deposit
    /// @return msgValue The estimated cost of the operation
    function estimateDeposit(bytes calldata callData_) external view returns (uint256 msgValue);

    /// @notice Estimates the cost for batch deposits
    /// @param callData_ An array of encoded data for the deposits
    /// @return msgValue The estimated total cost of the operations
    function estimateBatchDeposit(bytes[] calldata callData_) external view returns (uint256 msgValue);
}

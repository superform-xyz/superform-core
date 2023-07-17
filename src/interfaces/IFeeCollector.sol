// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "../types/LiquidityTypes.sol";

/// @title IFeeCollector
/// @author ZeroPoint Labs
/// @dev contract for cross-chain transaction fee management
interface IFeeCollector {
    /*///////////////////////////////////////////////////////////////
                        EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when a new fee payment is made
    event FeesPaid(address indexed user, uint256 amount);

    /// @dev is emitted when fees are moved out of fee collector
    event FeesWithdrawn(address indexed receiver, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                    PREVILAGED ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev withdraws funds from fee collector to multi tx processor on same chain
    /// @param nativeAmount_ is the amount to withdraw from fee collector
    function withdrawToMultiTxProcessor(uint256 nativeAmount_) external;

    /// @dev withdraws funds from fee collector to tx processor on same chain
    /// @param nativeAmount_ is the amount to withdraw from fee collector
    function withdrawToTxProcessor(uint256 nativeAmount_) external;

    /// @dev withdraws funds from fee collector to tx updater on same chain
    /// @param nativeAmount_ is the amount to withdraw from fee collector
    function withdrawToTxUpdater(uint256 nativeAmount_) external;

    /// @dev withdraws fund from fee collector to multi-tx processor on different chain
    /// @param req_ is the off-chain generated liquidity request to move funds
    function rebalanceToMultiTxProcessor(LiqRequest memory req_) external;

    /// @dev withdraws fund from fee collector to tx processor on different chain
    /// @param req_ is the off-chain generated liquidity request to move funds
    function rebalanceToTxProcessor(LiqRequest memory req_) external;

    /// @dev withdraws fund from fee collector to tx updater on different chain
    /// @param req_ is the off-chain generated liquidity request to move funds
    function rebalanceToTxUpdater(LiqRequest memory req_) external;

    /*///////////////////////////////////////////////////////////////
                    EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev accepts fee payment from user
    /// @param user_ is the wallet address of the paying user
    function makePayment(address user_) external payable;
}

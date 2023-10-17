// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "../types/LiquidityTypes.sol";

/// @title IPayMaster
/// @author ZeroPoint Labs
/// @dev contract for destination transaction costs payment
interface IPayMaster {
    /*///////////////////////////////////////////////////////////////
                        EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when a new payment is made
    event Payment(address indexed user, uint256 amount);

    /// @dev is emitted when payments are moved out of collector
    event PaymentWithdrawn(address indexed receiver, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                    PRIVILEGED ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev withdraws funds from pay master to target id from superRegistry
    /// @param superRegistryId_ is the id of the target address in superRegistry
    /// @param nativeAmount_ is the amount to withdraw from pay master
    function withdrawTo(bytes32 superRegistryId_, uint256 nativeAmount_) external;

    /// @dev withdraws fund from pay master to target id from superRegistry
    /// @param superRegistryId_ is the id of the target address in superRegistry
    /// @param req_ is the off-chain generated liquidity request to move funds
    /// @param dstChainId_ is the destination chain id
    function rebalanceTo(bytes32 superRegistryId_, LiqRequest memory req_, uint64 dstChainId_) external;

    /*///////////////////////////////////////////////////////////////
                    EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev accepts payment from user
    /// @param user_ is the wallet address of the paying user
    function makePayment(address user_) external payable;
}

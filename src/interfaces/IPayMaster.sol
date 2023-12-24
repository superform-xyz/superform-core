// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { LiqRequest } from "src/types/DataTypes.sol";

/// @title IPayMaster
/// @dev contract for destination transaction costs payment
/// @author ZeroPoint Labs
interface IPayMaster {
    
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when a new payment is made
    event Payment(address indexed user, uint256 indexed amount);

    /// @dev is emitted when  tokens are moved out of paymaster
    event TokenWithdrawn(address indexed receiver, address indexed token, uint256 indexed amount);

    /// @dev is emitted when native tokens are moved out of paymaster
    event NativeWithdrawn(address indexed receiver, uint256 indexed amount);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev withdraws token funds from pay master to target id from superRegistry
    /// @param superRegistryId_ is the id of the target address in superRegistry
    /// @param token_ is the token to withdraw from pay master
    /// @param amount_ is the amount to withdraw from pay master
    function withdrawTo(bytes32 superRegistryId_, address token_, uint256 amount_) external;

    /// @dev withdraws native funds from pay master to target id from superRegistry
    /// @param superRegistryId_ is the id of the target address in superRegistry
    /// @param nativeAmount_ is the amount to withdraw from pay master
    function withdrawNativeTo(bytes32 superRegistryId_, uint256 nativeAmount_) external;

    /// @dev withdraws fund from pay master to target id from superRegistry
    /// @param superRegistryId_ is the id of the target address in superRegistry
    /// @param req_ is the off-chain generated liquidity request to move funds
    /// @param dstChainId_ is the destination chain id
    function rebalanceTo(bytes32 superRegistryId_, LiqRequest memory req_, uint64 dstChainId_) external;

    /// @dev retries a stuck payload on any supported amb using funds from paymaster
    /// @param ambId_ is the identifier of the AMB
    /// @param nativeValue_ is the native fees to be sent along the transaction
    /// @param data_ is the amb specific encoded retry data [check individual AMB implementations]
    function treatAMB(uint8 ambId_, uint256 nativeValue_, bytes memory data_) external;

    /// @dev accepts payment from user
    /// @param user_ is the wallet address of the paying user
    function makePayment(address user_) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IBaseRouter } from "src/interfaces/IBaseRouter.sol";
import "src/types/DataTypes.sol";

/// @title IBaseRouterImplementation
/// @author Zeropoint Labs.
/// @dev interface for BaseRouterImplementation
interface IBaseRouterImplementation is IBaseRouter {
    //////////////////////////////////////////////////////////////
    //                           STRUCTS                        //
    //////////////////////////////////////////////////////////////

    /// @dev For local memory variable loading and avoiding stack too deep errors
    struct ActionLocalVars {
        AMBMessage ambMessage;
        LiqRequest liqRequest;
        uint64 srcChainId;
        uint256 currentPayloadId;
        uint256 liqRequestsLen;
    }

    struct DispatchAMBMessageVars {
        TransactionType txType;
        bytes ambData;
        uint256[] superformIds;
        address srcSender;
        uint8[] ambIds;
        uint8 multiVaults;
        uint64 srcChainId;
        uint64 dstChainId;
        uint256 currentPayloadId;
    }

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when a cross-chain deposit multi vault transaction is initiated.
    event CrossChainInitiatedDepositMulti(
        uint256 indexed payloadId,
        uint64 indexed dstChainId,
        uint256[] superformIds,
        uint256[] amountsIn,
        uint8[] bridgeIds,
        uint8[] ambIds
    );

    /// @dev is emitted when a cross-chain deposit single vault transaction is initiated.
    event CrossChainInitiatedDepositSingle(
        uint256 indexed payloadId,
        uint64 indexed dstChainId,
        uint256 superformIds,
        uint256 amountIn,
        uint8 bridgeId,
        uint8[] ambIds
    );

    /// @dev is emitted when a cross-chain withdraw multi vault transaction is initiated.
    event CrossChainInitiatedWithdrawMulti(
        uint256 indexed payloadId, uint64 indexed dstChainId, uint256[] superformIds, uint8[] ambIds
    );

    /// @dev is emitted when a cross-chain withdraw single vault transaction is initiated.
    event CrossChainInitiatedWithdrawSingle(
        uint256 indexed payloadId, uint64 indexed dstChainId, uint256 superformIds, uint8[] ambIds
    );

    /// @dev is emitted when a direct chain action is complete
    event Completed();

    /// @dev is emitted when dust is forwarded to paymaster
    event RouterDustForwardedToPaymaster(address indexed token, uint256 indexed amount);
}

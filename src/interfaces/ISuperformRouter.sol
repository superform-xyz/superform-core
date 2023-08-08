// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "../types/DataTypes.sol";

/// @title ISuperformRouter
/// @author Zeropoint Labs.
/// @dev interface for Super Router
interface ISuperformRouter {
    /*///////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @dev For local memory variable loading and avoiding stack too deep errors
    struct ActionLocalVars {
        AMBMessage ambMessage;
        LiqRequest liqRequest;
        uint64 srcChainId;
        uint256 currentPayloadId;
        uint256 liqRequestsLen;
    }

    /// @dev ºacks the necessary data for a cross-chain transaction
    struct DispatchAMBMessageVars {
        TransactionType txType;
        bytes ambData;
        uint256[] superFormIds;
        address srcSender;
        uint8[] ambIds;
        uint8 multiVaults;
        uint64 srcChainId;
        uint64 dstChainId;
        uint256 currentPayloadId;
    }

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when a cross-chain transaction is initiated.
    event CrossChainInitiated(uint256 indexed payloadId);

    /// @dev is emitted when the super registry is updated.
    event SuperRegistryUpdated(address indexed superRegistry);

    /// @dev is emitted when a cross-chain transaction is completed.
    event Completed(uint256 payloadId);

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL DEPOSIT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Performs multi destination x single vault deposits
    /// @param req is the request object containing all the necessary data for the action
    function multiDstSingleVaultDeposit(MultiDstSingleVaultStateReq calldata req) external payable;

    /// @dev Performs multi destination x multi vault deposits
    /// @param req is the request object containing all the necessary data for the action
    function multiDstMultiVaultDeposit(MultiDstMultiVaultStateReq calldata req) external payable;

    /// @dev Performs single xchain destination x single vault deposits
    /// @param req is the request object containing all the necessary data for the action
    function singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq memory req) external payable;

    /// @dev Performs single destination x multi vault deposits
    /// @param req is the request object containing all the necessary data for the action
    function singleXChainMultiVaultDeposit(SingleXChainMultiVaultStateReq memory req) external payable;

    /// @dev Performs single direct x single vault deposits
    /// @param req is the request object containing all the necessary data for the action
    function singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq memory req) external payable;

    /// @dev Performs single direct x multi vault deposits
    /// @param req is the request object containing all the necessary data for the action
    function singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq memory req) external payable;

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL WITHDRAW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Performs multi destination x single vault withdraws
    /// @param req is the request object containing all the necessary data for the action
    function multiDstSingleVaultWithdraw(MultiDstSingleVaultStateReq calldata req) external payable;

    /// @dev Performs multi destination x multi vault withdraws
    /// @param req is the request object containing all the necessary data for the action
    function multiDstMultiVaultWithdraw(MultiDstMultiVaultStateReq calldata req) external payable;

    /// @dev Performs single xchain destination x single vault withdraws
    /// @param req is the request object containing all the necessary data for the action
    function singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq memory req) external payable;

    /// @dev Performs single destination x multi vault withdraws
    /// @param req is the request object containing all the necessary data for the action
    function singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq memory req) external payable;

    /// @dev Performs single direct x single vault withdraws
    /// @param req is the request object containing all the necessary data for the action
    function singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq memory req) external payable;

    /// @dev Performs single direct x multi vault withdraws
    /// @param req is the request object containing all the necessary data for the action
    function singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq memory req) external payable;

    /*///////////////////////////////////////////////////////////////
                        External View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the total individual vault transactions made through the router.
    function payloadIds() external view returns (uint256);
}

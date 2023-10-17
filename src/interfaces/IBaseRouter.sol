// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "../types/DataTypes.sol";

/// @title IBaseRouter
/// @author Zeropoint Labs.
/// @dev interface for abstract Router
interface IBaseRouter {
    /*///////////////////////////////////////////////////////////////
                        EXTERNAL DEPOSIT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Performs multi destination x single vault deposits
    /// @param req_ is the request object containing all the necessary data for the action
    function multiDstSingleVaultDeposit(MultiDstSingleVaultStateReq calldata req_) external payable;

    /// @dev Performs multi destination x multi vault deposits
    /// @param req_ is the request object containing all the necessary data for the action
    function multiDstMultiVaultDeposit(MultiDstMultiVaultStateReq calldata req_) external payable;

    /// @dev Performs single xchain destination x single vault deposits
    /// @param req_ is the request object containing all the necessary data for the action
    function singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq memory req_) external payable;

    /// @dev Performs single destination x multi vault deposits
    /// @param req_ is the request object containing all the necessary data for the action
    function singleXChainMultiVaultDeposit(SingleXChainMultiVaultStateReq memory req_) external payable;

    /// @dev Performs single direct x single vault deposits
    /// @param req_ is the request object containing all the necessary data for the action
    function singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq memory req_) external payable;

    /// @dev Performs single direct x multi vault deposits
    /// @param req_ is the request object containing all the necessary data for the action
    function singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq memory req_) external payable;

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL WITHDRAW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Performs multi destination x single vault withdraws
    /// @param req_ is the request object containing all the necessary data for the action
    function multiDstSingleVaultWithdraw(MultiDstSingleVaultStateReq calldata req_) external payable;

    /// @dev Performs multi destination x multi vault withdraws
    /// @param req_ is the request object containing all the necessary data for the action
    function multiDstMultiVaultWithdraw(MultiDstMultiVaultStateReq calldata req_) external payable;

    /// @dev Performs single xchain destination x single vault withdraws
    /// @param req_ is the request object containing all the necessary data for the action
    function singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq memory req_) external payable;

    /// @dev Performs single destination x multi vault withdraws
    /// @param req_ is the request object containing all the necessary data for the action
    function singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq memory req_) external payable;

    /// @dev Performs single direct x single vault withdraws
    /// @param req_ is the request object containing all the necessary data for the action
    function singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq memory req_) external payable;

    /// @dev Performs single direct x multi vault withdraws
    /// @param req_ is the request object containing all the necessary data for the action
    function singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq memory req_) external payable;
}

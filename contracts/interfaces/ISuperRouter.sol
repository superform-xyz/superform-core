// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import {LiqRequest} from "../types/LiquidityTypes.sol";
import {StateReq} from "../types/DataTypes.sol";

/// @title ISuperRouter
/// @author Zeropoint Labs.
interface ISuperRouter {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    
    /// @dev is emitted when a cross-chain transaction is initiated.
    event Initiated(uint256 txId, address fromToken, uint256 fromAmount);
    
    /// @dev is emitted when a cross-chain transaction is completed.
    event Completed(uint256 txId);

    /// @dev is emitted when a new cross-chain token bridge is configured.
    event SetBridgeAddress(uint256 bridgeId, address bridgeAddress);

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev allows users to mint vault tokens and receive vault positions in return.
    /// @param liqData_      represents the data required to move tokens from user wallet to destination contract.
    /// @param stateData_    represents the state information including destination vault ids and amounts to be deposited to such vaults.
    /// note: Just use single type not arr and delegate to SuperFormRouter?
    function deposit(
        LiqRequest[] calldata liqData_,
        StateReq[] calldata stateData_
    ) external;

    /// @dev burns users superpositions and dispatch a withdrawal request to the destination chain.
    /// @param liqData_         represents the bridge data for underlying to be moved from destination chain.
    /// @param stateData_       represents the state data required for withdrawal of funds from the vaults.
    /// @dev API NOTE: This function can be called by anybody
    /// @dev ENG NOTE: Amounts is abstracted. 1:1 of positions on DESTINATION, but user can't query ie. previewWithdraw() cross-chain
    function withdraw(
        LiqRequest[] calldata liqData_, /// @dev Allow [] because user can request multiple tokens (as long as bridge has them - Needs check!)
        StateReq[] calldata stateData_
    ) external;

    function chainId() external returns (uint16);

    function totalTransactions() external returns (uint256);

    function stateSync(bytes memory _payload) external payable;
}

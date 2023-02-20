// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

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
    ) external payable;

    /// @dev burns users superpositions and dispatch a withdrawal request to the destination chain.
    /// @param liqData_         represents the bridge data for underlying to be moved from destination chain.
    /// @param stateData_       represents the state data required for withdrawal of funds from the vaults.
    /// @dev API NOTE: This function can be called by anybody
    /// @dev ENG NOTE: Amounts is abstracted. 1:1 of positions on DESTINATION, but user can't query ie. previewWithdraw() cross-chain
    function withdraw(
        LiqRequest[] calldata liqData_, /// @dev Allow [] because user can request multiple tokens (as long as bridge has them - Needs check!)
        StateReq[] calldata stateData_
    ) external payable;

    /// @dev PREVILAGED admin ONLY FUNCTION.
    /// @dev allows admin to set the bridge address for an bridge id.
    /// @param bridgeId_         represents the bridge unqiue identifier.
    /// @param bridgeAddress_    represents the bridge address.
    function setBridgeAddress(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_
    ) external;

    /// @dev allows registry contract to send payload for processing to the router contract.
    /// @param payload_ is the received information to be processed.
    function stateSync(bytes memory payload_) external payable;

    /*///////////////////////////////////////////////////////////////
                        External View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the chain id of the router contract
    function chainId() external view returns (uint256);

    /// @dev returns the total individual vault transactions made through the router.
    function totalTransactions() external view returns (uint256);

    /// @dev returns the off-chain metadata URI for each ERC1155 super position.
    /// @param id_ is the unique identifier of the ERC1155 super position aka the vault id.
    /// @return string pointing to the off-chain metadata of the 1155 super position.
    function tokenURI(uint256 id_) external view returns (string memory);
}

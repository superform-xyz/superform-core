/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { AMBMessage } from "../types/DataTypes.sol";

/// @title IStateSyncer
/// @author Zeropoint Labs.
/// @dev interface for State Syncer
interface IStateSyncer {
    /// @dev saves the message being sent together with the associated id formulated in a router
    /// @param payloadId_ is the id of the message being saved
    /// @param txInfo_ is the relevant information of the transaction being saved
    function updateTxHistory(uint256 payloadId_, uint256 txInfo_) external;

    /// @dev allows minter to mint shares on source
    /// @param sender_ is the beneficiary of shares
    /// @param id_ is the id of the shares
    /// @param amount_ is the amount of shares to mint
    function mintSingle(address sender_, uint256 id_, uint256 amount_) external;

    /// @dev allows minter to mint shares on source in batch
    /// @param sender_ is the beneficiary of shares
    /// @param ids_ are the ids of the shares
    /// @param amounts_ are the amounts of shares to mint
    function mintBatch(address sender_, uint256[] memory ids_, uint256[] memory amounts_) external;

    /// @dev allows burner to burn shares on source
    /// @param sender_ is the address of the sender
    /// @param id_ is the id of the shares
    /// @param amount_ is the amount of shares to burn
    function burnSingle(address sender_, uint256 id_, uint256 amount_) external;

    /// @dev allows burner to burn shares on source in batch
    /// @param sender_ is the address of the sender
    /// @param ids_ are the ids of the shares
    /// @param amounts_ are the amounts of shares to burn
    function burnBatch(address sender_, uint256[] memory ids_, uint256[] memory amounts_) external;

    /// @dev allows state registry contract to mint shares on source
    /// @param data_ is the received information to be processed.
    /// @return srcChainId_ is the decoded srcChainId.
    function stateMultiSync(AMBMessage memory data_) external returns (uint64 srcChainId_);

    /// @dev allows state registry contract to mint shares on source
    /// @param data_ is the received information to be processed.
    /// @return srcChainId_ is the decoded srcChainId.
    function stateSync(AMBMessage memory data_) external returns (uint64 srcChainId_);

    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the payload header for a tx id on the source chain
    /// @param txId_ is the identifier of the transaction issued by super router
    function txHistory(uint256 txId_) external view returns (uint256);
}

/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { AMBMessage } from "../types/DataTypes.sol";

/// @title IStateSyncer
/// @author Zeropoint Labs.
/// @dev interface for State Syncer
interface IStateSyncer {
    /// @dev allows state registry contract to mint shares on source
    /// @param data_ is the received information to be processed.
    /// @return srcChainId_ is the decoded srcChainId.
    function stateMultiSync(AMBMessage memory data_) external payable returns (uint64 srcChainId_);

    /// @dev allows state registry contract to mint shares on source
    /// @param data_ is the received information to be processed.
    /// @return srcChainId_ is the decoded srcChainId.
    function stateSync(AMBMessage memory data_) external payable returns (uint64 srcChainId_);

    /// @dev allows two steps state registry contract to re-mint shares on source
    /// @param sender_ is the address of the sender
    /// @param superformid is the id of the superform
    /// @param amount is the amount to re-mint
    function stateSyncTwoStep(address sender_, uint256 superformid, uint256 amount) external payable;

    /// @dev saves the message being sent together with the associated id formulated in a router
    /// @param payloadId_ is the id of the message being saved
    /// @param txInfo_ is the relevant information of the transaction being saved
    function updateTxHistory(uint256 payloadId_, uint256 txInfo_) external;

    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the payload header for a tx id on the source chain
    /// @param txId_ is the identifier of the transaction issued by super router
    function txHistory(uint256 txId_) external view returns (uint256);
}

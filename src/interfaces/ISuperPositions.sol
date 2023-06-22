/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {AMBMessage} from "../types/DataTypes.sol";

/// @title ISuperPositions
/// @author Zeropoint Labs.
/// @dev interface for Super Positions
interface ISuperPositions {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when a cross-chain withdraw return data is received.
    event Status(uint256 txId, uint64 status);

    /// @dev is emitted when a cross-chain transaction is completed.
    event Completed(uint256 txId);

    /*///////////////////////////////////////////////////////////////
                        PROTECTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev mints a single super position
    /// @param owner_ is the address of the owner of the super position
    /// @param superFormId_ is the id of the super position being minted
    /// @param amount_ is the amount of the super position being minted
    function mintSingleSP(address owner_, uint256 superFormId_, uint256 amount_) external;

    /// @dev mints a batch of super positions
    /// @param owner_ is the address of the owner of the super positions
    /// @param superFormIds_ are the ids of the super positions being minted
    /// @param amounts_ are the amounts of the super positions being minted
    function mintBatchSP(address owner_, uint256[] memory superFormIds_, uint256[] memory amounts_) external;

    /// @dev burns a single super position
    /// @param srcSender_ is the address of the sender of the super position
    /// @param superFormId_ is the id of the super position being burned
    /// @param amount_ is the amount of the super position being burned
    function burnSingleSP(address srcSender_, uint256 superFormId_, uint256 amount_) external;

    /// @dev burns a batch of super positions
    /// @param srcSender_ is the address of the sender of the super positions
    /// @param superFormIds_ are the ids of the super positions being burned
    /// @param amounts_ are the amounts of the super positions being burned
    function burnBatchSP(address srcSender_, uint256[] memory superFormIds_, uint256[] memory amounts_) external;

    /// @dev allows registry contract to send payload for processing to the router contract.
    /// @param data_ is the received information to be processed.
    /// @return srcChainId_ is the decoded srcChainId.
    function stateMultiSync(AMBMessage memory data_) external payable returns (uint64 srcChainId_);

    /// @dev allows registry contract to send payload for processing to the router contract.
    /// @param data_ is the received information to be processed.
    /// @return srcChainId_ is the decoded srcChainId.
    function stateSync(AMBMessage memory data_) external payable returns (uint64 srcChainId_);

    /// @dev saves the message being sent together with the associated id formulated in super router
    /// @param payloadId_ is the id of the message being saved
    /// @param txInfo_ is the relevant information of the transaction being saved
    /// @param superFormIds_ are the ids of the super positions being saved
    function updateTxHistory(uint256 payloadId_, uint256 txInfo_, uint256[] memory superFormIds_) external;

    function setDynamicURI(string memory dynamicURI_) external;

    /// FIXME: Temp extension need to make approve at superRouter, may change with arch
    function setApprovalForAll(address operator, bool approved) external;
}

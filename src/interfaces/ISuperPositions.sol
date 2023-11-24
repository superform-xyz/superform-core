/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import { AMBMessage } from "../types/DataTypes.sol";
import { IERC1155A } from "ERC1155A/interfaces/IERC1155A.sol";

/// @title ISuperPositions
/// @author Zeropoint Labs.
/// @dev interface for Super Positions
interface ISuperPositions is IERC1155A {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when a dynamic uri is updated
    event DynamicURIUpdated(string oldURI, string newURI, bool frozen);

    /// @dev is emitted when a cross-chain transaction is completed.
    event Completed(uint256 txId);

    /// @dev is emitted when a aErc20 token is registered
    event AERC20TokenRegistered(uint256 indexed tokenId, address indexed tokenAddress);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev returns the payload header for a tx id on the source chain
    /// @param txId_ is the identifier of the transaction issued by superform router
    function txHistory(uint256 txId_) external view returns (uint256);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev saves the message being sent together with the associated id formulated in a router
    /// @param payloadId_ is the id of the message being saved
    /// @param txInfo_ is the relevant information of the transaction being saved
    function updateTxHistory(uint256 payloadId_, uint256 txInfo_) external;

    /// @dev allows minter to mint shares on source
    /// @param srcSender_ is the beneficiary of shares
    /// @param id_ is the id of the shares
    /// @param amount_ is the amount of shares to mint
    function mintSingle(address srcSender_, uint256 id_, uint256 amount_) external;

    /// @dev allows minter to mint shares on source in batch
    /// @param srcSender_ is the beneficiary of shares
    /// @param ids_ are the ids of the shares
    /// @param amounts_ are the amounts of shares to mint
    function mintBatch(address srcSender_, uint256[] memory ids_, uint256[] memory amounts_) external;

    /// @dev allows superformRouter to burn shares on source
    /// @notice burn is done optimistically by the router in the beginning of the withdraw transactions
    /// @notice in case the withdraw tx fails on the destination, shares are reminted through stateSync
    /// @param srcSender_ is the address of the sender
    /// @param id_ is the id of the shares
    /// @param amount_ is the amount of shares to burn
    function burnSingle(address srcSender_, uint256 id_, uint256 amount_) external;

    /// @dev allows burner to burn shares on source in batch
    /// @param srcSender_ is the address of the sender
    /// @param ids_ are the ids of the shares
    /// @param amounts_ are the amounts of shares to burn
    function burnBatch(address srcSender_, uint256[] memory ids_, uint256[] memory amounts_) external;

    /// @dev allows state registry contract to mint shares on source
    /// @param data_ is the received information to be processed.
    /// @return srcChainId_ is the decoded srcChainId.
    function stateMultiSync(AMBMessage memory data_) external returns (uint64 srcChainId_);

    /// @dev allows state registry contract to mint shares on source
    /// @param data_ is the received information to be processed.
    /// @return srcChainId_ is the decoded srcChainId.
    function stateSync(AMBMessage memory data_) external returns (uint64 srcChainId_);

    /// @dev sets the dynamic uri for NFT
    /// @param dynamicURI_ is the dynamic uri of the NFT
    /// @param freeze_ is to prevent updating the metadata once migrated to IPFS
    function setDynamicURI(string memory dynamicURI_, bool freeze_) external;

    /// @dev allows to create sERC0 using broadcast state registry
    /// @param data_ is the crosschain payload
    function stateSyncBroadcast(bytes memory data_) external payable;
}

/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { IStateSyncer } from "./IStateSyncer.sol";

/// @title ISuperPositions
/// @author Zeropoint Labs.
/// @dev interface for Super Positions
interface ISuperPositions is IStateSyncer {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when a dynamic uri is updated
    event DynamicURIUpdated(string oldURI, string newURI, bool frozen);

    /// @dev is emitted when a cross-chain transaction is completed.
    event Completed(uint256 txId);

    /*///////////////////////////////////////////////////////////////
                        PROTECTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev mints a single super position
    /// @param owner_ is the address of the owner of the super position
    /// @param id_ is the id of the super position being minted
    /// @param amount_ is the amount of the super position being minted
    function mintSingleSP(address owner_, uint256 id_, uint256 amount_) external;

    /// @dev mints a batch of super positions
    /// @param owner_ is the address of the owner of the super positions
    /// @param ids_ are the ids of the super positions being minted
    /// @param amounts_ are the amounts of the super positions being minted
    function mintBatchSP(address owner_, uint256[] memory ids_, uint256[] memory amounts_) external;

    /// @dev burns a single super position
    /// @param srcSender_ is the address of the sender of the super position
    /// @param id_ is the id of the super position being burned
    /// @param amount_ is the amount of the super position being burned
    function burnSingleSP(address srcSender_, uint256 id_, uint256 amount_) external;

    /// @dev burns a batch of super positions
    /// @param srcSender_ is the address of the sender of the super positions
    /// @param ids_ are the ids of the super positions being burned
    /// @param amounts_ are the amounts of the super positions being burned
    function burnBatchSP(address srcSender_, uint256[] memory ids_, uint256[] memory amounts_) external;

    /// @dev sets the dynamic uri for NFT
    /// @param dynamicURI_ is the dynamic uri of the NFT
    /// @param freeze_ is to prevent updating the metadata once migrated to IPFS
    function setDynamicURI(string memory dynamicURI_, bool freeze_) external;
}

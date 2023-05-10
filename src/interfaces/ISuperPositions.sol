/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {AMBMessage} from "../types/DataTypes.sol";

/// @title Super Positions
/// @author Zeropoint Labs.
/// @dev  extends ERC1155s to create SuperPositions which track vault shares from any originating chain
interface ISuperPositions {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when a cross-chain withdraw return data is received.
    event Status(uint256 txId, uint16 status);

    /// @dev is emitted when a cross-chain transaction is completed.
    event Completed(uint256 txId);

    /*///////////////////////////////////////////////////////////////
                        PROTECTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mintSingleSP(
        address owner_,
        uint256 superFormId_,
        uint256 amount_
    ) external;

    function mintBatchSP(
        address owner_,
        uint256[] memory superFormIds_,
        uint256[] memory amounts_
    ) external;

    function burnSingleSP(
        address srcSender_,
        uint256 superFormId_,
        uint256 amount_
    ) external;

    function burnBatchSP(
        address srcSender_,
        uint256[] memory superFormIds_,
        uint256[] memory amounts_
    ) external;

    /// @dev allows registry contract to send payload for processing to the router contract.
    /// @param data_ is the received information to be processed.
    function stateMultiSync(AMBMessage memory data_) external payable;

    /// @dev allows registry contract to send payload for processing to the router contract.
    /// @param data_ is the received information to be processed.
    function stateSync(AMBMessage memory data_) external payable;

    /// @dev saves the AMB message being sent together with the associated id formulated in super router
    /// @param messageId_ is the id of the message being sent
    /// @param message_ is the message being sent
    function updateTxHistory(
        uint80 messageId_,
        AMBMessage memory message_
    ) external;

    function setDynamicURI(string memory dynamicURI_) external;

    /// FIXME: Temp extension need to make approve at superRouter, may change with arch
    function setApprovalForAll(address operator, bool approved) external;
}

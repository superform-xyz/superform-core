/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {AMBMessage} from "../types/DataTypes.sol";

interface ISuperPositionBank {
    /*///////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct PositionBatch {
        uint256[] tokenIds;
        uint256[] amounts;
    }

    struct PositionSingle {
        uint256 tokenId;
        uint256 amount;
    }

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when a cross-chain withdraw return data is received.
    event Status(uint256 txId, uint16 status);

    /// @dev is emitted when a cross-chain transaction is completed.
    event Completed(uint256 txId);

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function acceptPositionBatch(
        uint256[] memory tokenIds_,
        uint256[] memory amounts_,
        address owner_
    ) external returns (uint256 index);

    function acceptPositionSingle(
        uint256 tokenId_,
        uint256 amounts,
        address owner_
    ) external returns (uint256 index);

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
        address owner_,
        uint256 superFormId_,
        uint256 amount_
    ) external;

    function burnBatchSP(
        address owner_,
        uint256[] memory superFormIds_,
        uint256[] memory amounts_
    ) external;

    function getPositionBatch(
        address owner_,
        uint256 positionIndex_
    )
        external
        view
        returns (uint256[] memory tokenIds, uint256[] memory amounts);

    function getPositionSingle(
        address owner_,
        uint256 positionIndex_
    ) external view returns (uint256 tokenId, uint256 amount);
}

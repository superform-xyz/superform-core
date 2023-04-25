/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

/// @title Super Positions
/// @author Zeropoint Labs.
/// @dev  extends ERC1155s to create SuperPositions which track vault shares from any originating chain
interface ISuperPositions is IERC1155 {
    /*///////////////////////////////////////////////////////////////
                        PROTECTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mintSingleSP(
        address srcSender_,
        uint256 superFormId_,
        uint256 amount_,
        bytes memory data_
    ) external;

    function mintBatchSP(
        address srcSender_,
        uint256[] memory superFormIds_,
        uint256[] memory amounts_,
        bytes memory data_
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

    function setDynamicURI(string memory dynamicURI_) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) external;

    /// FIXME: Temp extension need to make approve at superRouter, may change with arch
    function setApprovalForAll(address operator, bool approved) external;

}

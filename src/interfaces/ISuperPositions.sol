/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title Super Positions
/// @author Zeropoint Labs.
/// @dev  extends ERC1155s to create SuperPositions which track vault shares from any originating chain
interface ISuperPositions {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when the chain id input is invalid.
    error INVALID_INPUT_CHAIN_ID();

    /// @dev is emitted when an address is being set to 0
    error ZERO_ADDRESS();

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
}

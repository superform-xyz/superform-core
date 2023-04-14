/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC1155s} from "ERC1155s/src/ERC1155s.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {ISuperPositions} from "./interfaces/ISuperPositions.sol";
import {ISuperRBAC} from "./interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";
import {Error} from "./utils/Error.sol";

/// @title Super Positions
/// @author Zeropoint Labs.
/// @dev  extends ERC1155s to create SuperPositions which track vault shares from any originating chain
contract SuperPositions is ISuperPositions, ERC1155s {
    /*///////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////*/

    string public dynamicURI = "https://api.superform.xyz/superposition/";

    ISuperRegistry public immutable superRegistry;

    modifier onlySuperRouter() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasSuperRouterRole(
                msg.sender
            )
        ) revert Error.NOT_SUPER_ROUTER();
        _;
    }

    modifier onlyProtocolAdmin() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(
                msg.sender
            )
        ) revert Error.NOT_PROTOCOL_ADMIN();
        _;
    }

    /// @param dynamicURI_              URL for external metadata of ERC1155 SuperPositions
    /// @param superRegistry_ the superform registry contract
    constructor(string memory dynamicURI_, address superRegistry_) {
        dynamicURI = dynamicURI_;
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                        MINT/BURN PROTECTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mintSingleSP(
        address srcSender_,
        uint256 superFormId_,
        uint256 amount_,
        bytes memory data_
    ) external override onlySuperRouter {
        _mint(srcSender_, superFormId_, amount_, data_);
    }

    function mintBatchSP(
        address srcSender_,
        uint256[] memory superFormIds_,
        uint256[] memory amounts_,
        bytes memory data_
    ) external override onlySuperRouter {
        _batchMint(srcSender_, superFormIds_, amounts_, data_);
    }

    function burnSingleSP(
        address srcSender_,
        uint256 superFormId_,
        uint256 amount_
    ) external override onlySuperRouter {
        _burn(srcSender_, superFormId_, amount_);
    }

    function burnBatchSP(
        address srcSender_,
        uint256[] memory superFormIds_,
        uint256[] memory amounts_
    ) external override onlySuperRouter {
        _batchBurn(srcSender_, superFormIds_, amounts_);
    }

    /*///////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev PREVILEGED admin ONLY FUNCTION.
    /// @param dynamicURI_    represents the dynamicURI for the ERC1155 super positions
    function setDynamicURI(
        string memory dynamicURI_
    ) external override onlyProtocolAdmin {
        dynamicURI = dynamicURI_;
    }

    /*///////////////////////////////////////////////////////////////
                            Read Only Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Used to construct return url
    function _baseURI() internal view override returns (string memory) {
        return dynamicURI;
    }

    /**
     * @dev See {ERC1155s-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

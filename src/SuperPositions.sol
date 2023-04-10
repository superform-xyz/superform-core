/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {ERC1155s} from "ERC1155s/src/ERC1155s.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {ISuperPositions} from "./interfaces/ISuperPositions.sol";

/// @title Super Positions
/// @author Zeropoint Labs.
/// @dev  extends ERC1155s to create SuperPositions which track vault shares from any originating chain
contract SuperPositions is ISuperPositions, ERC1155s, AccessControl {
    /*///////////////////////////////////////////////////////////////
                    Access Control Role Constants
    //////////////////////////////////////////////////////////////*/
    bytes32 public constant SUPER_ROUTER_ROLE = keccak256("SUPER_ROUTER_ROLE");

    /*///////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////*/

    string public dynamicURI = "https://api.superform.xyz/superposition/";

    /// @notice chainId represents unique chain id for each chains.
    uint16 public immutable chainId;

    /// @param chainId_              SuperForm chain id
    /// @param dynamicURI_              URL for external metadata of ERC1155 SuperPositions
    constructor(uint16 chainId_, string memory dynamicURI_) {
        if (chainId_ == 0) revert INVALID_INPUT_CHAIN_ID();

        chainId = chainId_;
        dynamicURI = dynamicURI_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        MINT/BURN PROTECTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mintSingleSP(
        address srcSender_,
        uint256 superFormId_,
        uint256 amount_,
        bytes memory data_
    ) external override onlyRole(SUPER_ROUTER_ROLE) {
        _mint(srcSender_, superFormId_, amount_, data_);
    }

    function mintBatchSP(
        address srcSender_,
        uint256[] memory superFormIds_,
        uint256[] memory amounts_,
        bytes memory data_
    ) external override onlyRole(SUPER_ROUTER_ROLE) {
        _batchMint(srcSender_, superFormIds_, amounts_, data_);
    }

    function burnSingleSP(
        address srcSender_,
        uint256 superFormId_,
        uint256 amount_
    ) external override onlyRole(SUPER_ROUTER_ROLE) {
        _burn(srcSender_, superFormId_, amount_);
    }

    function burnBatchSP(
        address srcSender_,
        uint256[] memory superFormIds_,
        uint256[] memory amounts_
    ) external override onlyRole(SUPER_ROUTER_ROLE) {
        _batchBurn(srcSender_, superFormIds_, amounts_);
    }

    /*///////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev PREVILEGED admin ONLY FUNCTION.
    /// @param dynamicURI_    represents the dynamicURI for the ERC1155 super positions
    function setDynamicURI(
        string memory dynamicURI_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
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
    ) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

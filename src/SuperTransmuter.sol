///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {Transmuter} from "ERC1155A/transmuter/Transmuter.sol";
import {IERC1155A} from "ERC1155A/interfaces/IERC1155A.sol";
import {sERC20} from "ERC1155A/transmuter/sERC20.sol";
import {DataLib} from "./libraries/DataLib.sol";
import {ISuperTransmuter} from "./interfaces/ISuperTransmuter.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";
import {IBaseForm} from "./interfaces/IBaseForm.sol";
import {Error} from "./utils/Error.sol";

/// @title SuperTransmuter
/// @author Zeropoint Labs.
/// @notice This contract inherits from ERC1155A transmuter, changing the way transmuters are registered to only require a superformId. Metadata is fetched from underlying vault
contract SuperTransmuter is ISuperTransmuter, Transmuter {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public immutable superRegistry;

    /// @param superPositions_ the super positions contract
    /// @param superRegistry_ the superform registry contract
    constructor(IERC1155A superPositions_, address superRegistry_) Transmuter(superPositions_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /// @inheritdoc ISuperTransmuter
    function registerTransmuter(uint256 superformId) external override returns (address) {
        (address superform, uint32 formBeaconId, uint64 chainId) = DataLib.getSuperform(superformId);

        if (superform == address(0)) revert Error.NOT_SUPERFORM();
        if (formBeaconId == 0) revert Error.FORM_DOES_NOT_EXIST();
        if (synthethicTokenId[superformId] != address(0)) revert TRANSMUTER_ALREADY_REGISTERED();

        address syntheticToken = address(
            new sERC20(
                string(abi.encodePacked("Synthetic ERC20 ", IBaseForm(superform).superformYieldTokenName())),
                string(abi.encodePacked("sERC20-", IBaseForm(superform).superformYieldTokenSymbol())),
                uint8(IBaseForm(superform).getVaultDecimals())
            )
        );
        synthethicTokenId[superformId] = syntheticToken;

        return synthethicTokenId[superformId];
    }
}

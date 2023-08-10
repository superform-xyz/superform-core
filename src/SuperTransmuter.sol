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
    function registerTransmuter(uint256 superFormId) external override returns (address) {
        (address superForm, uint32 formBeaconId, uint64 chainId) = DataLib.getSuperform(superFormId);

        if (superForm == address(0)) revert Error.NOT_SUPERFORM();
        if (formBeaconId == 0) revert Error.FORM_DOES_NOT_EXIST();
        if (chainId != superRegistry.chainId()) revert Error.INVALID_CHAIN_ID();
        if (synthethicTokenId[superFormId] != address(0)) revert TRANSMUTER_ALREADY_REGISTERED();

        address syntheticToken = address(
            new sERC20(
                string(abi.encodePacked("Synthetic ERC20 ", IBaseForm(superForm).superformYieldTokenName())),
                string(abi.encodePacked("sERC20-", IBaseForm(superForm).superformYieldTokenSymbol())),
                uint8(IBaseForm(superForm).getVaultDecimals())
            )
        );
        synthethicTokenId[superFormId] = syntheticToken;

        return synthethicTokenId[superFormId];
    }
}

///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { Transmuter } from "ERC1155A/transmuter/Transmuter.sol";
import { IERC1155A } from "ERC1155A/interfaces/IERC1155A.sol";
import { sERC20 } from "ERC1155A/transmuter/sERC20.sol";
import { DataLib } from "./libraries/DataLib.sol";
import { ISuperTransmuter } from "./interfaces/ISuperTransmuter.sol";
import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";
import { IBaseForm } from "./interfaces/IBaseForm.sol";
import { IBroadcastRegistry } from "./interfaces/IBroadcastRegistry.sol";
import { Error } from "./utils/Error.sol";
import { BroadcastMessage } from "./types/DataTypes.sol";

/// @title SuperTransmuter
/// @author Zeropoint Labs.
/// @notice This contract inherits from ERC1155A transmuter, changing the way transmuters are registered to only require
/// a superformId. Metadata is fetched from underlying vault
contract SuperTransmuter is ISuperTransmuter, Transmuter {
    using DataLib for uint256;

    bytes32 constant DEPLOY_NEW_TRANSMUTER = keccak256("DEPLOY_NEW_TRANSMUTER");

    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public immutable superRegistry;

    uint256 public xChainPayloadCounter;

    /// @param superPositions_ the super positions contract
    /// @param superRegistry_ the superform registry contract
    constructor(IERC1155A superPositions_, address superRegistry_) Transmuter(superPositions_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /// @inheritdoc Transmuter
    /// @notice explicity revert on register transmuter
    function registerTransmuter(
        uint256 id,
        string memory name,
        string memory symbol,
        uint8 decimals
    )
        external
        override
        returns (address)
    {
        revert Error.DISABLED();
    }

    /// @inheritdoc ISuperTransmuter
    function registerTransmuter(uint256 superformId, bytes memory extraData_) external override returns (address) {
        (address superform, uint32 formBeaconId, uint64 chainId) = DataLib.getSuperform(superformId);
        if (superRegistry.chainId() != chainId) revert Error.INVALID_CHAIN_ID();
        if (superform == address(0)) revert Error.NOT_SUPERFORM();
        if (formBeaconId == 0) revert Error.FORM_DOES_NOT_EXIST();
        if (synthethicTokenId[superformId] != address(0)) revert TRANSMUTER_ALREADY_REGISTERED();

        string memory name =
            string(abi.encodePacked("Synthetic ERC20 ", IBaseForm(superform).superformYieldTokenName()));
        string memory symbol = string(abi.encodePacked("sERC20-", IBaseForm(superform).superformYieldTokenSymbol()));
        uint8 decimal = uint8(IBaseForm(superform).getVaultDecimals());

        /// @dev if we call this on the chain where the superform is, it works
        /// @dev however we need this to be called on certain chains where the superform is not deployed
        /// @dev with broadcasting this could be forwarded to all the other chains
        address syntheticToken = address(
            new sERC20(
                name,
                symbol,
                decimal
            )
        );

        synthethicTokenId[superformId] = syntheticToken;

        /// @dev broadcast and deploy to the other destination chains
        if (extraData_.length > 0) {
            BroadcastMessage memory transmuterPayload = BroadcastMessage(
                "SUPER_TRANSMUTER",
                DEPLOY_NEW_TRANSMUTER,
                abi.encode(superRegistry.chainId(), ++xChainPayloadCounter, superformId, name, symbol, decimal)
            );

            _broadcast(abi.encode(transmuterPayload), extraData_);
        }

        return synthethicTokenId[superformId];
    }

    /// @inheritdoc ISuperTransmuter
    function stateSyncBroadcast(bytes memory data_) external payable override {
        /// @dev this function is only accessible through broadcast registry
        if (msg.sender != superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))) {
            revert Error.NOT_BROADCAST_REGISTRY();
        }

        BroadcastMessage memory transmuterPayload = abi.decode(data_, (BroadcastMessage));

        if (transmuterPayload.messageType == DEPLOY_NEW_TRANSMUTER) {
            _deployTransmuter(transmuterPayload.message);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev interacts with broadcast state registry to broadcasting state changes to all connected remote chains
    /// @param message_ is the crosschain message to be sent.
    /// @param extraData_ is the amb override information.
    function _broadcast(bytes memory message_, bytes memory extraData_) internal {
        (uint8[] memory ambIds, bytes memory broadcastParams) = abi.decode(extraData_, (uint8[], bytes));

        /// @dev ambIds are validated inside the broadcast state registry
        /// @dev broadcastParams if wrong will revert in the amb implementation
        IBroadcastRegistry(superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))).broadcastPayload{
            value: msg.value
        }(msg.sender, ambIds, message_, broadcastParams);
    }

    /// @dev deploys new transmuter on broadcasting
    function _deployTransmuter(bytes memory message_) internal {
        (,, uint256 superformId, string memory name, string memory symbol, uint8 decimal) =
            abi.decode(message_, (uint64, uint256, uint256, string, string, uint8));

        address syntheticToken = address(
            new sERC20(
                name,
                symbol,
                decimal
            )
        );

        synthethicTokenId[superformId] = syntheticToken;
    }
}

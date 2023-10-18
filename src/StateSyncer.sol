///SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { AMBMessage } from "./types/DataTypes.sol";
import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";
import { IStateSyncer } from "./interfaces/IStateSyncer.sol";
import { ISuperRBAC } from "./interfaces/ISuperRBAC.sol";
import { Error } from "./utils/Error.sol";
import { DataLib } from "./libraries/DataLib.sol";

/// @title StateSyncer
/// @author Zeropoint Labs.
/// @dev base contract for stateSync functions
abstract contract StateSyncer is IStateSyncer {
    /*///////////////////////////////////////////////////////////////
                        STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev is the super registry address
    ISuperRegistry public immutable superRegistry;
    uint8 public immutable ROUTER_TYPE;
    uint64 public immutable CHAIN_ID;
    /// @dev maps all transaction data routed through the smart contract.
    mapping(uint256 transactionId => uint256 txInfo) public override txHistory;

    /*///////////////////////////////////////////////////////////////
                            MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier onlyRouter() {
        if (superRegistry.getSuperformRouterId(msg.sender) == 0) revert Error.NOT_SUPER_ROUTER();
        _;
    }

    modifier onlyMinter(uint256 id) virtual;

    modifier onlyBatchMinter(uint256[] memory ids) virtual;

    modifier onlyBurner() virtual;

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param superRegistry_ the superform registry contract
    /// @param routerType_ the router type
    constructor(address superRegistry_, uint8 routerType_) {
        CHAIN_ID = uint64(block.chainid);

        superRegistry = ISuperRegistry(superRegistry_);
        ROUTER_TYPE = routerType_;
    }

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IStateSyncer
    function updateTxHistory(uint256 payloadId_, uint256 txInfo_) external override onlyRouter {
        txHistory[payloadId_] = txInfo_;
    }

    /// @inheritdoc IStateSyncer
    function mintSingle(address srcSender_, uint256 id_, uint256 amount_) external virtual override;

    /// @inheritdoc IStateSyncer
    function mintBatch(
        address srcSender_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    )
        external
        virtual
        override;

    /// @inheritdoc IStateSyncer
    function burnSingle(address srcSender_, uint256 id_, uint256 amount_) external virtual override;

    /// @inheritdoc IStateSyncer
    function burnBatch(
        address srcSender_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    )
        external
        virtual
        override;

    /// @inheritdoc IStateSyncer
    function stateMultiSync(AMBMessage memory data_) external virtual override returns (uint64 srcChainId_);

    /// @inheritdoc IStateSyncer
    function stateSync(AMBMessage memory data_) external virtual override returns (uint64 srcChainId_);

    function validateSingleIdExists(uint256 superformId_) public view virtual override;

    function validateBatchIdsExist(uint256[] memory superformIds_) public view virtual override;
    /*///////////////////////////////////////////////////////////////
                        INTERNAL/HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev helps validate the state registry id for minting superform id
    function _validateStateSyncer(uint256 superformId_) internal view {
        uint8 registryId = superRegistry.getStateRegistryId(msg.sender);
        _isValidStateSyncer(registryId, superformId_);
    }

    /// @dev helps validate the state registry id for minting superform id
    function _validateStateSyncer(uint256[] memory superformIds_) internal view {
        uint8 registryId = superRegistry.getStateRegistryId(msg.sender);
        for (uint256 i; i < superformIds_.length;) {
            _isValidStateSyncer(registryId, superformIds_[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _isValidStateSyncer(uint8 registryId_, uint256 superformId_) internal pure {
        // Directly check if the registryId is 0 or doesn't match the allowed cases.
        if (registryId_ == 0) {
            revert Error.NOT_MINTER_STATE_REGISTRY_ROLE();
        }
        // If registryId is 1, no further checks are necessary.
        if (registryId_ == 1) {
            return;
        }

        (, uint32 formImplementationId,) = DataLib.getSuperform(superformId_);

        if (uint32(registryId_) != formImplementationId) {
            revert Error.NOT_MINTER_STATE_REGISTRY_ROLE();
        }
    }
}

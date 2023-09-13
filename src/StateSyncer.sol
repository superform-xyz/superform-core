///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import { AMBMessage } from "./types/DataTypes.sol";
import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";
import { IStateSyncer } from "./interfaces/IStateSyncer.sol";
import { ISuperRBAC } from "./interfaces/ISuperRBAC.sol";
import { Error } from "./utils/Error.sol";

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

    /// @dev maps all transaction data routed through the smart contract.
    mapping(uint256 transactionId => uint256 txInfo) public override txHistory;

    /*///////////////////////////////////////////////////////////////
                            MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier onlyRouter() {
        if (superRegistry.getSuperformRouterId(msg.sender) == 0) revert Error.NOT_SUPER_ROUTER();
        _;
    }

    modifier onlyMinter() virtual;

    modifier onlyBurner() virtual;

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    modifier onlyMinterStateRegistry() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasMinterStateRegistryRole(msg.sender)) {
            revert Error.NOT_MINTER_STATE_REGISTRY_ROLE();
        }
        _;
    }
    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param superRegistry_ the superform registry contract
    /// @param routerType_ the router type
    constructor(address superRegistry_, uint8 routerType_) {
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
}

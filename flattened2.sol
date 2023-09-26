// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

/// @title ISuperRegistry
/// @author Zeropoint Labs.
/// @dev interface for Super Registry
interface ISuperRegistry {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev emitted when permit2 is set.
    event SetPermit2(address indexed permit2);

    /// @dev is emitted when an address is set.
    event AddressUpdated(
        bytes32 indexed protocolAddressId, uint64 indexed chainId, address indexed oldAddress, address newAddress
    );

    /// @dev is emitted when a new token bridge is configured.
    event SetBridgeAddress(uint256 indexed bridgeId, address indexed bridgeAddress);

    /// @dev is emitted when a new bridge validator is configured.
    event SetBridgeValidator(uint256 indexed bridgeId, address indexed bridgeValidator);

    /// @dev is emitted when a new amb is configured.
    event SetAmbAddress(uint8 ambId_, address ambAddress_, bool isBroadcastAMB_);

    /// @dev is emitted when a new state registry is configured.
    event SetStateRegistryAddress(uint8 registryId_, address registryAddress_);

    /// @dev is emitted when a new router/state syncer is configured.
    event SetRouterInfo(uint8 superFormRouterId_, address stateSyncer_, address router_);

    /// @dev is emitted when a new delay is configured.
    event SetDelay(uint256 oldDelay_, uint256 newDelay_);

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev sets the deposit rescue delay
    /// @param delay_ the delay in seconds before the deposit rescue can be finalized
    function setDelay(uint256 delay_) external;

    /// @dev sets the permit2 address
    /// @param permit2_ the address of the permit2 contract
    function setPermit2(address permit2_) external;

    /// @dev sets a new address on a specific chain.
    /// @param id_ the identifier of the address on that chain
    /// @param newAddress_ the new address on that chain
    /// @param chainId_ the chain id of that chain
    function setAddress(bytes32 id_, address newAddress_, uint64 chainId_) external;

    /// @dev allows admin to set the bridge address for an bridge id.
    /// @param bridgeId_         represents the bridge unqiue identifier.
    /// @param bridgeAddress_    represents the bridge address.
    /// @param bridgeValidator_  represents the bridge validator address.
    function setBridgeAddresses(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_,
        address[] memory bridgeValidator_
    )
        external;

    /// @dev allows admin to set the amb address for an amb id.
    /// @param ambId_         represents the bridge unqiue identifier.
    /// @param ambAddress_    represents the bridge address.
    /// @param isBroadcastAMB_ represents whether the amb implementation supports broadcasting
    function setAmbAddress(
        uint8[] memory ambId_,
        address[] memory ambAddress_,
        bool[] memory isBroadcastAMB_
    )
        external;

    /// @dev allows admin to set the state registry address for an state registry id.
    /// @param registryId_    represents the state registry's unqiue identifier.
    /// @param registryAddress_    represents the state registry's address.
    function setStateRegistryAddress(uint8[] memory registryId_, address[] memory registryAddress_) external;

    /// @dev allows admin to set the superform routers info
    /// @param superformRouterIds_    represents the superform router's unqiue identifier.
    /// @param stateSyncers_    represents the state syncer's address.
    /// @param routers_    represents the router's address.
    function setRouterInfo(
        uint8[] memory superformRouterIds_,
        address[] memory stateSyncers_,
        address[] memory routers_
    )
        external;

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev gets the deposit rescue delay
    function delay() external view returns (uint256);

    /// @dev returns the permit2 address
    function PERMIT2() external view returns (address);

    /// @dev returns the id of the super router module
    function SUPERFORM_ROUTER() external view returns (bytes32);

    /// @dev returns the id of the superform factory module
    function SUPERFORM_FACTORY() external view returns (bytes32);

    /// @dev returns the id of the superform transmuter
    function SUPER_TRANSMUTER() external view returns (bytes32);

    /// @dev returns the id of the superform paymaster contract
    function PAYMASTER() external view returns (bytes32);

    /// @dev returns the id of the superform payload helper contract
    function PAYMENT_HELPER() external view returns (bytes32);

    /// @dev returns the id of the core state registry module
    function CORE_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the two steps form state registry module
    function TIMELOCK_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the broadcast state registry module
    function BROADCAST_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the super positions module
    function SUPER_POSITIONS() external view returns (bytes32);

    /// @dev returns the id of the super rbac module
    function SUPER_RBAC() external view returns (bytes32);

    /// @dev returns the id of the payload helper module
    function PAYLOAD_HELPER() external view returns (bytes32);

    /// @dev returns the id of the payment admin keeper
    function PAYMENT_ADMIN() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function CORE_REGISTRY_UPDATER() external view returns (bytes32);

    /// @dev returns the id of the core state registry processor keeper
    function CORE_REGISTRY_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the broadcast registry processor keeper
    function BROADCAST_REGISTRY_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the two steps form state registry processor keeper
    function TWO_STEPS_REGISTRY_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the dst swapper keeper
    function DST_SWAPPER() external view returns (bytes32);

    /// @dev gets the address of a contract on current chain
    /// @param id_ is the id of the contract
    function getAddress(bytes32 id_) external view returns (address);

    /// @dev gets the address of a contract on a target chain
    /// @param id_ is the id of the contract
    /// @param chainId_ is the chain id of that chain
    function getAddressByChainId(bytes32 id_, uint64 chainId_) external view returns (address);

    /// @dev gets the address of a bridge
    /// @param bridgeId_ is the id of a bridge
    /// @return bridgeAddress_ is the address of the form
    function getBridgeAddress(uint8 bridgeId_) external view returns (address bridgeAddress_);

    /// @dev gets the address of the registry
    /// @param registryId_ is the id of the state registry
    /// @return registryAddress_ is the address of the state registry
    function getStateRegistry(uint8 registryId_) external view returns (address registryAddress_);

    /// @dev gets the id of the amb
    /// @param ambAddress_ is the address of an amb
    /// @return ambId_ is the identifier of an amb
    function getAmbId(address ambAddress_) external view returns (uint8 ambId_);

    /// @dev gets the id of the registry
    /// @notice reverts if the id is not found
    /// @param registryAddress_ is the address of the state registry
    /// @return registryId_ is the id of the state registry
    function getStateRegistryId(address registryAddress_) external view returns (uint8 registryId_);

    /// @dev gets the address of a state syncer
    /// @param superformRouterId_ is the id of a state syncer
    /// @return stateSyncer_ is the address of a state syncer
    function getStateSyncer(uint8 superformRouterId_) external view returns (address stateSyncer_);

    /// @dev gets the address of a router
    /// @param superformRouterId_ is the id of a state syncer
    /// @return router_ is the address of a router
    function getRouter(uint8 superformRouterId_) external view returns (address router_);

    /// @dev gets the id of a router
    /// @param router_ is the address of a router
    /// @return superformRouterId_ is the id of a superform router / state syncer
    function getSuperformRouterId(address router_) external view returns (uint8 superformRouterId_);

    /// @dev helps validate if an address is a valid state registry
    /// @param registryAddress_ is the address of the state registry
    /// @return valid_ a flag indicating if its valid.
    function isValidStateRegistry(address registryAddress_) external view returns (bool valid_);

    /// @dev helps validate if an address is a valid amb implementation
    /// @param ambAddress_ is the address of the amb implementation
    /// @return valid_ a flag indicating if its valid.
    function isValidAmbImpl(address ambAddress_) external view returns (bool valid_);

    /// @dev helps validate if an address is a valid broadcast amb implementation
    /// @param ambAddress_ is the address of the broadcast amb implementation
    /// @return valid_ a flag indicating if its valid.
    function isValidBroadcastAmbImpl(address ambAddress_) external view returns (bool valid_);

    /// @dev gets the address of a bridge validator
    /// @param bridgeId_ is the id of a bridge
    /// @return bridgeValidator_ is the address of the form
    function getBridgeValidator(uint8 bridgeId_) external view returns (address bridgeValidator_);

    /// @dev gets the address of a amb
    /// @param ambId_ is the id of a bridge
    /// @return ambAddress_ is the address of the form
    function getAmbAddress(uint8 ambId_) external view returns (address ambAddress_);
}

/// @title Bridge Handler Interface
/// @author Zeropoint Labs
interface IBridgeValidator {
    /*///////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/
    struct ValidateTxDataArgs {
        bytes txData;
        uint64 srcChainId;
        uint64 dstChainId;
        uint64 liqDstChainId;
        bool deposit;
        address superform;
        address srcSender;
        address liqDataToken;
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev validates the destination chainId of the liquidity request
    /// @param txData_ the txData of the deposit
    /// @param liqDstChainId_ the chainId of the destination chain for liquidity
    function validateLiqDstChainId(bytes calldata txData_, uint64 liqDstChainId_) external pure returns (bool);

    /// @dev decoded txData and returns the receiver address
    /// @param txData_ is the txData of the cross chain deposit
    /// @param receiver_ is the address of the receiver to validate
    /// @return valid_ if the address is valid
    function validateReceiver(bytes calldata txData_, address receiver_) external pure returns (bool valid_);

    /// @dev validates the txData of a cross chain deposit
    /// @param args_ the txData arguments to validate in txData
    function validateTxData(ValidateTxDataArgs calldata args_) external view;

    /// @dev decodes the txData and returns the minimum amount expected to receive on the destination
    /// @param txData_ is the txData of the cross chain deposit
    /// @param genericSwapDisallowed_ true if generic swaps are disallowed
    /// @return amount_ the amount expected
    function decodeMinAmountOut(
        bytes calldata txData_,
        bool genericSwapDisallowed_
    )
        external
        view
        returns (uint256 amount_);

    /// @dev decodes the txData and returns the amount of external token on source
    /// @param txData_ is the txData of the cross chain deposit
    /// @param genericSwapDisallowed_ true if generic swaps are disallowed
    /// @return amount_ the amount expected
    function decodeAmountIn(
        bytes calldata txData_,
        bool genericSwapDisallowed_
    )
        external
        view
        returns (uint256 amount_);

    /// @dev decodes the amount in from the txData that just involves a swap
    /// @param txData_ is the txData to be decoded
    function decodeDstSwap(bytes calldata txData_) external pure returns (address token_, uint256 amount_);
}

/// @title BridgeValidator
/// @author Zeropoint Labs
/// @dev To be inherited by specific bridge handlers to verify the calldata being sent
abstract contract BridgeValidator is IBridgeValidator {
    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public immutable superRegistry;

    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBridgeValidator
    function validateLiqDstChainId(
        bytes calldata txData_,
        uint64 liqDstChainId_
    )
        external
        pure
        virtual
        override
        returns (bool);

    /// @inheritdoc IBridgeValidator
    function validateReceiver(
        bytes calldata txData_,
        address receiver_
    )
        external
        pure
        virtual
        override
        returns (bool valid_);

    /// @inheritdoc IBridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external view virtual override;

    /// @inheritdoc IBridgeValidator
    function decodeMinAmountOut(
        bytes calldata txData_,
        bool genericSwapDisallowed_
    )
        external
        view
        virtual
        override
        returns (uint256 amount_);

    /// @inheritdoc IBridgeValidator
    function decodeAmountIn(
        bytes calldata txData_,
        bool genericSwapDisallowed_
    )
        external
        view
        virtual
        override
        returns (uint256 amount_);

    /// @inheritdoc IBridgeValidator
    function decodeDstSwap(bytes calldata txData_)
        external
        pure
        virtual
        override
        returns (address token_, uint256 amount_);
}

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

/// @title ISuperRBAC
/// @author Zeropoint Labs.
/// @dev interface for Super RBAC
interface ISuperRBAC is IAccessControl {
    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev updates the super registry address
    function setSuperRegistry(address superRegistry_) external;

    /// @dev configures a new role in superForm
    /// @param role_ the role to set
    /// @param adminRole_ the admin role to set as admin
    function setRoleAdmin(bytes32 role_, bytes32 adminRole_) external;

    /// @dev revokes the role_ from superRegistryAddressId_ on all chains
    /// @param role_ the role to revoke
    /// @param addressToRevoke_ the address to revoke the role from
    /// @param extraData_ amb config if broadcasting is required
    /// @param superRegistryAddressId_ the super registry address id
    function revokeRoleSuperBroadcast(
        bytes32 role_,
        address addressToRevoke_,
        bytes memory extraData_,
        bytes32 superRegistryAddressId_
    )
        external
        payable;

    /// @dev allows sync of global roles from different chains using broadcast registry
    /// @notice may not work for all roles
    function stateSyncBroadcast(bytes memory data_) external;

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the id of the protocol admin role
    function PROTOCOL_ADMIN_ROLE() external view returns (bytes32);

    /// @dev returns the id of the emergency admin role
    function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

    /// @dev returns the id of the payment admin role
    function PAYMENT_ADMIN_ROLE() external view returns (bytes32);

    /// @dev returns the id of the broadcaster role
    function BROADCASTER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry processor role
    function CORE_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry rescuer role
    function CORE_STATE_REGISTRY_RESCUER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry rescue disputer role
    function CORE_STATE_REGISTRY_DISPUTER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the two steps state registry processor role
    function TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the broadcast state registry processor role
    function BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the dst swapper role
    function DST_SWAPPER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater role
    function CORE_STATE_REGISTRY_UPDATER_ROLE() external view returns (bytes32);

    /// @dev returns the id of superpositions minter role
    function SUPERPOSITIONS_MINTER_ROLE() external view returns (bytes32);

    /// @dev returns the id of superpositions burner role
    function SUPERPOSITIONS_BURNER_ROLE() external view returns (bytes32);

    /// @dev returns the id of serc20 minter role
    function SERC20_MINTER_ROLE() external view returns (bytes32);

    /// @dev returns the id of serc20 burner role
    function SERC20_BURNER_ROLE() external view returns (bytes32);

    /// @dev returns the id of minter state registry role
    function MINTER_STATE_REGISTRY_ROLE() external view returns (bytes32);

    /// @dev returns the id of wormhole vaa relayer role
    function WORMHOLE_VAA_RELAYER_ROLE() external view returns (bytes32);

    /// @dev returns whether the given address has the protocol admin role
    /// @param admin_ the address to check
    function hasProtocolAdminRole(address admin_) external view returns (bool);

    /// @dev returns whether the given address has the emergency admin role
    /// @param admin_ the address to check
    function hasEmergencyAdminRole(address admin_) external view returns (bool);
}

library Error {
    /*///////////////////////////////////////////////////////////////
                        GENERAL ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when the chain id input is invalid.
    error INVALID_INPUT_CHAIN_ID();

    /// @dev error thrown when address input is address 0
    error ZERO_ADDRESS();

    /// @dev error thrown when address input is address 0
    error ZERO_AMOUNT();

    /// @dev error thrown when beacon id already exists
    error BEACON_ID_ALREADY_EXISTS();

    /// @dev thrown when msg.sender is not core state registry
    error NOT_CORE_STATE_REGISTRY();

    /// @dev thrown when msg.sender is not form
    error NOT_SUPERFORM();

    /// @dev thrown when msg.sender is not two step form
    error NOT_TWO_STEP_SUPERFORM();

    /// @dev thrown when msg.sender is not a valid amb implementation
    error NOT_AMB_IMPLEMENTATION();

    /// @dev thrown when msg.sender is not state registry
    error NOT_STATE_REGISTRY();

    /// @dev thrown when msg.sender is not an allowed broadcaster
    error NOT_ALLOWED_BROADCASTER();

    /// @dev thrown when msg.sender is not broadcast state registry
    error NOT_BROADCAST_REGISTRY();

    /// @dev thrown when msg.sender is not broadcast amb implementation
    error NOT_BROADCAST_AMB_IMPLEMENTATION();

    /// @dev thrown if the broadcast payload is invalid
    error INVALID_BROADCAST_PAYLOAD();

    /// @dev thrown if the underlying collateral mismatches
    error INVALID_DEPOSIT_TOKEN();

    /// @dev thrown when msg.sender is not two step state registry
    error NOT_TWO_STEP_STATE_REGISTRY();

    /// @dev thrown when msg.sender is not protocol admin
    error NOT_PROTOCOL_ADMIN();

    /// @dev thrown when msg.sender is not emergency admin
    error NOT_EMERGENCY_ADMIN();

    /// @dev thrown when msg.sender is not super router
    error NOT_SUPER_ROUTER();

    /// @dev thrown when msg.sender is not minter
    error NOT_MINTER();

    /// @dev thrown when msg.sender is not burner
    error NOT_BURNER();

    /// @dev thrown when msg.sender is not minter state registry
    error NOT_MINTER_STATE_REGISTRY_ROLE();

    /// @dev if the msg-sender is not super form factory
    error NOT_SUPERFORM_FACTORY();

    /// @dev thrown if the msg-sender is not super registry
    error NOT_SUPER_REGISTRY();

    /// @dev thrown if the msg-sender does not have SWAPPER role
    error NOT_SWAPPER();

    /// @dev thrown if the msg-sender does not have PROCESSOR role
    error NOT_PROCESSOR();

    /// @dev thrown if the msg-sender does not have UPDATER role
    error NOT_UPDATER();

    /// @dev thrown if the msg-sender does not have RESCUER role
    error NOT_RESCUER();

    /// @dev thrown when the bridge tokens haven't arrived to destination
    error BRIDGE_TOKENS_PENDING();

    /// @dev thrown when trying to set again pseudo immutables in SuperRegistry
    error DISABLED();

    /// @dev thrown when the native tokens transfer has failed
    error NATIVE_TOKEN_TRANSFER_FAILURE();

    /// @dev thrown when not possible to revoke last admin
    error CANNOT_REVOKE_LAST_ADMIN();

    /// @dev thrown if the delay is invalid
    error INVALID_TIMELOCK_DELAY();

    /// @dev thrown if rescue is already proposed
    error RESCUE_ALREADY_PROPOSED();

    /*///////////////////////////////////////////////////////////////
                         LIQUIDITY BRIDGE ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when the chain id in the txdata is invalid
    error INVALID_TXDATA_CHAIN_ID();

    /// @dev thrown the when validation of bridge txData fails due to wrong receiver
    error INVALID_TXDATA_RECEIVER();

    /// @dev thrown when the validation of bridge txData fails due to wrong token
    error INVALID_TXDATA_TOKEN();

    /// @dev thrown when in deposits, the liqDstChainId doesn't match the stateReq dstChainId
    error INVALID_DEPOSIT_LIQ_DST_CHAIN_ID();

    /// @dev when a certain action of the user is not allowed given the txData provided
    error INVALID_ACTION();

    /// @dev thrown when the validation of bridge txData fails due to a destination call present
    error INVALID_TXDATA_NO_DESTINATIONCALL_ALLOWED();

    /// @dev thrown when dst swap output is less than minimum expected
    error INVALID_SWAP_OUTPUT();

    /// @dev thrown when try to process dst swap for same payload id
    error DST_SWAP_ALREADY_PROCESSED();

    /// @dev thrown if index is invalid
    error INVALID_INDEX();

    /// @dev thrown if msg.sender is not the refund address to dispute
    error INVALID_DISUPTER();

    /// @dev thrown if the rescue passed dispute deadline
    error DISPUTE_TIME_ELAPSED();

    /// @dev thrown if the rescue is still in timelocked state
    error RESCUE_TIMELOCKED();

    /*///////////////////////////////////////////////////////////////
                        STATE REGISTRY ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev hyperlane adapter specific error, when caller not hyperlane mailbox
    error CALLER_NOT_MAILBOX();

    /// @dev wormhole relayer specific error, when caller not wormhole relayer
    error CALLER_NOT_RELAYER();

    /// @dev layerzero adapter specific error, when caller not layerzero endpoint
    error CALLER_NOT_ENDPOINT();

    /// @dev thrown when src chain sender is not valid
    error INVALID_SRC_SENDER();

    /// @dev thrown when broadcast finality for wormhole is invalid
    error INVALID_BROADCAST_FINALITY();

    /// @dev thrown when src chain is blocked from messaging
    error INVALID_SRC_CHAIN_ID();

    /// @dev thrown when payload is not unique
    error DUPLICATE_PAYLOAD();

    /// @dev is emitted when the chain id brought in the cross chain message is invalid
    error INVALID_CHAIN_ID();

    /// @dev thrown if ambId is not valid leading to an address 0 of the implementation
    error INVALID_BRIDGE_ID();

    /// @dev thrown if payload id does not exist
    error INVALID_PAYLOAD_ID();

    /// @dev is thrown is payload is already updated (during xChain deposits)
    error PAYLOAD_ALREADY_UPDATED();

    /// @dev is thrown is payload is already processed
    error PAYLOAD_ALREADY_PROCESSED();

    /// @dev is thrown if the payload hash is zero during `retryMessage` on Layezero implementation
    error ZERO_PAYLOAD_HASH();

    /// @dev is thrown if the payload hash is invalid during `retryMessage` on Layezero implementation
    error INVALID_PAYLOAD_HASH();

    /// @dev thrown if update payload function was called on a wrong payload
    error INVALID_PAYLOAD_UPDATE_REQUEST();

    /// @dev thrown if payload update amount mismatch with dst swapper amount
    error INVALID_DST_SWAP_AMOUNT();

    /// @dev thrown if payload is being updated with final amounts length different than amounts length
    error DIFFERENT_PAYLOAD_UPDATE_AMOUNTS_LENGTH();

    /// @dev thrown if payload is being updated with tx data length different than liq data length
    error DIFFERENT_PAYLOAD_UPDATE_TX_DATA_LENGTH();

    /// @dev thrown if the amounts being sent in update payload mean a negative slippage
    error NEGATIVE_SLIPPAGE();

    /// @dev thrown if payload is not in UPDATED state
    error PAYLOAD_NOT_UPDATED();

    /// @dev thrown if withdrawal TX_DATA cannot be updated
    error CANNOT_UPDATE_WITHDRAW_TX_DATA();

    /// @dev thrown if withdrawal TX_DATA is not updated
    error WITHDRAW_TX_DATA_NOT_UPDATED();

    /// @dev thrown if message hasn't reached the specified level of quorum needed
    error QUORUM_NOT_REACHED();

    /// @dev thrown if message amb and proof amb are the same
    error INVALID_PROOF_BRIDGE_ID();

    /// @dev thrown if a duplicate proof amb is found
    error DUPLICATE_PROOF_BRIDGE_ID();

    /// @dev thrown if the rescue data lengths are invalid
    error INVALID_RESCUE_DATA();

    /// @dev thrown if not enough native fees is paid for amb to send the message
    error CROSS_CHAIN_TX_UNDERPAID();

    /*///////////////////////////////////////////////////////////////
                        SUPERFORM FACTORY ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev thrown when a form is not ERC165 compatible
    error ERC165_UNSUPPORTED();

    /// @dev thrown when a form is not FORM interface compatible
    error FORM_INTERFACE_UNSUPPORTED();

    /// @dev thrown when a form does not exist
    error FORM_DOES_NOT_EXIST();

    /// @dev thrown when same vault and beacon is used to create new superform
    error VAULT_BEACON_COMBNATION_EXISTS();

    /// @dev thrown when there is an array length mismatch
    error ARRAY_LENGTH_MISMATCH();

    /// @dev thrown slippage is outside of bounds
    error SLIPPAGE_OUT_OF_BOUNDS();

    /*///////////////////////////////////////////////////////////////
                        SUPERFORM ROUTER ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev thrown when form id is larger than max uint16
    error INVALID_FORM_ID();

    /// @dev thrown when the vaults data is invalid
    error INVALID_SUPERFORMS_DATA();

    /// @dev thrown when the chain ids data is invalid
    error INVALID_CHAIN_IDS();

    /// @dev thrown when the payload is invalid
    error INVALID_PAYLOAD();

    /// @dev thrown if src senders mismatch in state sync
    error SRC_SENDER_MISMATCH();

    /// @dev thrown if src tx types mismatch in state sync
    error SRC_TX_TYPE_MISMATCH();

    /// @dev thrown if the payload status is invalid
    error INVALID_PAYLOAD_STATUS();

    /*///////////////////////////////////////////////////////////////
                        LIQUIDITY HANDLER ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev thrown if liquidity bridge fails for erc20 tokens
    error FAILED_TO_EXECUTE_TXDATA();

    /// @dev thrown if liquidity bridge fails for native tokens
    error FAILED_TO_EXECUTE_TXDATA_NATIVE();

    /// @dev thrown if native amount is not at least equal to the amount in the request
    error INSUFFICIENT_NATIVE_AMOUNT();

    /*///////////////////////////////////////////////////////////////
                            FORM ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev thrown when the allowance in direct deposit is not correct
    error DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();

    /// @dev thrown when the amount in direct deposit is not correct
    error DIRECT_DEPOSIT_INVALID_DATA();

    /// @dev thrown when the collateral in direct withdraw is not correct
    error DIRECT_WITHDRAW_INVALID_COLLATERAL();

    /// @dev thrown when the amount in direct withdraw is not correct
    error DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

    /// @dev thrown when the amount in xchain withdraw is not correct
    error XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();

    /// @dev thrown when unlock has already been requested - cooldown period didn't pass yet
    error WITHDRAW_COOLDOWN_PERIOD();

    /// @dev thrown when trying to finalize the payload but the withdraw is still locked
    error LOCKED();

    /// @dev thrown when liqData token is empty but txData is not
    error EMPTY_TOKEN_NON_EMPTY_TXDATA();

    /// @dev if implementation formBeacon is PAUSED then users cannot perform any action
    error PAUSED();

    /*///////////////////////////////////////////////////////////////
                        PAYMASTER ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev - when msg.sender is not payment admin
    error NOT_PAYMENT_ADMIN();

    /// @dev thrown when user pays zero
    error ZERO_MSG_VALUE();

    /// @dev thrown when payment withdrawal fails
    error FAILED_WITHDRAW();

    /*///////////////////////////////////////////////////////////////
                        SUPER POSITIONS ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev thrown when the uri cannot be updated
    error DYNAMIC_URI_FROZEN();

    /*///////////////////////////////////////////////////////////////
                        PAYMENT HELPER ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev thrown when chainlink is reporting an improper price
    error CHAINLINK_MALFUNCTION();

    /// @dev thrown when chainlink is reporting an incomplete round
    error CHAINLINK_INCOMPLETE_ROUND();
}

/// @title ILiFi
/// @notice Interface containing useful structs when using LiFi as a bridge
/// @notice taken from LiFi contracts https://github.com/lifinance/contracts
interface ILiFi {
    struct BridgeData {
        bytes32 transactionId;
        string bridge;
        string integrator;
        address referrer;
        address sendingAssetId;
        address receiver;
        uint256 minAmount;
        uint256 destinationChainId;
        bool hasSourceSwaps;
        bool hasDestinationCall; // is there a destination call? we should disable this
    }
}

library LibSwap {
    struct SwapData {
        address callTo;
        address approveTo;
        address sendingAssetId;
        address receivingAssetId;
        uint256 fromAmount;
        bytes callData;
        bool requiresDeposit;
    }
}

/// @title LiFiTxDataExtractor
/// @author LI.FI (https://li.fi)
/// @notice Provides functionality for extracting calldata
/// @notice upgraded to solidity 0.8.19 and adapted from CalldataVerificationFacet and LibBytes without any changes to
/// used functions (just stripped down functionality and renamed contract name)
/// @notice taken from LiFi contracts https://github.com/lifinance/contracts
/// @custom:version 1.1.0

contract LiFiTxDataExtractor {
    error SliceOverflow();
    error SliceOutOfBounds();

    /// @notice Extracts the bridge data from the calldata
    /// @param data The calldata to extract the bridge data from
    /// @return bridgeData The bridge data extracted from the calldata
    function _extractBridgeData(bytes calldata data) internal pure returns (ILiFi.BridgeData memory bridgeData) {
        if (bytes4(data[:4]) == 0xd6a4bc50) {
            // StandardizedCall
            bytes memory unwrappedData = abi.decode(data[4:], (bytes));
            bridgeData = abi.decode(_slice(unwrappedData, 4, unwrappedData.length - 4), (ILiFi.BridgeData));
            return bridgeData;
        }
        // normal call
        bridgeData = abi.decode(data[4:], (ILiFi.BridgeData));
    }

    /// @notice Extracts the swap data from the calldata
    /// @param data The calldata to extract the swap data from
    /// @return swapData The swap data extracted from the calldata
    function _extractSwapData(bytes calldata data) internal pure returns (LibSwap.SwapData[] memory swapData) {
        if (bytes4(data[:4]) == 0xd6a4bc50) {
            // standardizedCall
            bytes memory unwrappedData = abi.decode(data[4:], (bytes));
            (, swapData) =
                abi.decode(_slice(unwrappedData, 4, unwrappedData.length - 4), (ILiFi.BridgeData, LibSwap.SwapData[]));
            return swapData;
        }
        // normal call
        (, swapData) = abi.decode(data[4:], (ILiFi.BridgeData, LibSwap.SwapData[]));
    }

    function _slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        if (_length + 31 < _length) revert SliceOverflow();
        if (_bytes.length < _start + _length) revert SliceOutOfBounds();

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}

/// @title LiFiValidator
/// @author Zeropoint Labs
/// @dev To assert input txData is valid
contract LiFiValidator is BridgeValidator, LiFiTxDataExtractor {
    /*///////////////////////////////////////////////////////////////
                              Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) BridgeValidator(superRegistry_) { }

    /// @inheritdoc BridgeValidator
    function validateLiqDstChainId(
        bytes calldata txData_,
        uint64 liqDstChainId_
    )
        external
        pure
        override
        returns (bool)
    {
        return (uint256(liqDstChainId_) == _extractBridgeData(txData_).destinationChainId);
    }

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver_) external pure override returns (bool valid_) {
        return _extractBridgeData(txData_).receiver == receiver_;
    }

    /// @inheritdoc BridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external view override {
        /// @dev xchain actions can have bridgeData or bridgeData + swapData
        /// @dev direct actions with deposit, cannot have bridge data - goes into catch block
        /// @dev withdraw actions may have bridge data after withdrawing - goes into try block
        /// @dev withdraw actions without bridge data (just swap) - goes into catch block

        try this.extractMainParameters(args_.txData) returns (
            string memory, /*bridge*/
            address sendingAssetId,
            address receiver,
            uint256, /*amount*/
            uint256, /*minAmount*/
            uint256 destinationChainId,
            bool, /*hasSourceSwaps*/
            bool hasDestinationCall
        ) {
            /// @dev 0. Destination call validation
            if (hasDestinationCall) revert Error.INVALID_TXDATA_NO_DESTINATIONCALL_ALLOWED();

            /// @dev 1. chainId validation
            /// @dev for deposits, liqDstChainId/toChainId will be the normal destination (where the target superform
            /// is)
            /// @dev for withdraws, liqDstChainId/toChainId will be the desired chain to where the underlying must be
            /// sent
            /// @dev to after vault redemption

            if (uint256(args_.liqDstChainId) != destinationChainId) revert Error.INVALID_TXDATA_CHAIN_ID();

            /// @dev 2. receiver address validation
            if (args_.deposit) {
                if (args_.srcChainId == args_.dstChainId) {
                    revert Error.INVALID_ACTION();
                } else {
                    /// @dev if cross chain deposits, then receiver address must be CoreStateRegistry (or) Dst Swapper
                    if (
                        !(
                            receiver
                                == superRegistry.getAddressByChainId(keccak256("CORE_STATE_REGISTRY"), args_.dstChainId)
                                || receiver == superRegistry.getAddressByChainId(keccak256("DST_SWAPPER"), args_.dstChainId)
                        )
                    ) {
                        revert Error.INVALID_TXDATA_RECEIVER();
                    }
                }
            } else {
                /// @dev if withdraws, then receiver address must be the srcSender
                if (receiver != args_.srcSender) revert Error.INVALID_TXDATA_RECEIVER();
            }

            /// @dev remap of address 0 to NATIVE because of how LiFi produces txData
            if (sendingAssetId == address(0)) {
                sendingAssetId = NATIVE;
            }
            /// @dev 3. token validations
            if (args_.liqDataToken != sendingAssetId) revert Error.INVALID_TXDATA_TOKEN();
        } catch {
            (address sendingAssetId,, address receiver,,) = extractGenericSwapParameters(args_.txData);

            /// @dev 1. chainId validation

            if (args_.srcChainId != args_.dstChainId) revert Error.INVALID_ACTION();

            /// @dev 2. receiver address validation
            if (args_.deposit) {
                if (args_.dstChainId != args_.liqDstChainId) revert Error.INVALID_DEPOSIT_LIQ_DST_CHAIN_ID();
                /// @dev If same chain deposits then receiver address must be the superform
                if (receiver != args_.superform) revert Error.INVALID_TXDATA_RECEIVER();
            } else {
                /// @dev if withdraws, then receiver address must be the srcSender
                if (receiver != args_.srcSender) revert Error.INVALID_TXDATA_RECEIVER();
            }

            /// @dev remap of address 0 to NATIVE because of how LiFi produces txData
            if (sendingAssetId == address(0)) {
                sendingAssetId = NATIVE;
            }
            /// @dev 3. token validations
            if (args_.liqDataToken != sendingAssetId) revert Error.INVALID_TXDATA_TOKEN();
        }
    }

    /// @inheritdoc BridgeValidator
    function decodeMinAmountOut(
        bytes calldata txData_,
        bool genericSwapDisallowed_
    )
        external
        view
        override
        returns (uint256 amount_)
    {
        try this.extractMainParameters(txData_) returns (
            string memory, /*bridge*/
            address, /*sendingAssetId*/
            address, /*receiver*/
            uint256, /*amount*/
            uint256 minAmount,
            uint256, /*destinationChainId*/
            bool, /*hasSourceSwaps*/
            bool /*hasDestinationCall*/
        ) {
            /// @dev try is just used here to validate the txData. We need to always extract minAmount from bridge data
            amount_ = minAmount;
        } catch {
            if (genericSwapDisallowed_) revert Error.INVALID_ACTION();
            /// @dev in the case of a generic swap, minAmountOut is considered to be the receivedAmount
            (,,,, amount_) = extractGenericSwapParameters(txData_);
        }
    }

    /// @inheritdoc BridgeValidator
    function decodeAmountIn(
        bytes calldata txData_,
        bool genericSwapDisallowed_
    )
        external
        view
        override
        returns (uint256 amount_)
    {
        try this.extractMainParameters(txData_) returns (
            string memory, /*bridge*/
            address, /*sendingAssetId*/
            address, /*receiver*/
            uint256 amount,
            uint256, /*minAmount*/
            uint256, /*destinationChainId*/
            bool, /*hasSourceSwaps*/
            bool /*hasDestinationCall*/
        ) {
            /// @dev if there isn't a source swap, amountIn is minAmountOut from bridge data?

            amount_ = amount;
        } catch {
            if (genericSwapDisallowed_) revert Error.INVALID_ACTION();
            /// @dev in the case of a generic swap, amountIn is the from amount

            (, amount_,,,) = extractGenericSwapParameters(txData_);
        }
    }

    /// @inheritdoc BridgeValidator
    function decodeDstSwap(bytes calldata txData_) external pure override returns (address token_, uint256 amount_) {
        (token_, amount_,,,) = extractGenericSwapParameters(txData_);
    }

    /// @notice Extracts the main parameters from the calldata
    /// @param data_ The calldata to extract the main parameters from
    /// @return bridge The bridge extracted from the calldata
    /// @return sendingAssetId The sending asset id extracted from the calldata
    /// @return receiver The receiver extracted from the calldata
    /// @return amount The amount the calldata (which may be equal to bridge min amount)
    /// @return minAmount The min amount extracted from the bridgeData calldata
    /// @return destinationChainId The destination chain id extracted from the calldata
    /// @return hasSourceSwaps Whether the calldata has source swaps
    /// @return hasDestinationCall Whether the calldata has a destination call
    function extractMainParameters(bytes calldata data_)
        public
        pure
        returns (
            string memory bridge,
            address sendingAssetId,
            address receiver,
            uint256 amount,
            uint256 minAmount,
            uint256 destinationChainId,
            bool hasSourceSwaps,
            bool hasDestinationCall
        )
    {
        ILiFi.BridgeData memory bridgeData = _extractBridgeData(data_);

        if (bridgeData.hasSourceSwaps) {
            LibSwap.SwapData[] memory swapData = _extractSwapData(data_);
            sendingAssetId = swapData[0].sendingAssetId;
            amount = swapData[0].fromAmount;
        } else {
            sendingAssetId = bridgeData.sendingAssetId;
            amount = bridgeData.minAmount;
        }
        minAmount = bridgeData.minAmount;
        return (
            bridgeData.bridge,
            sendingAssetId,
            bridgeData.receiver,
            amount,
            minAmount,
            bridgeData.destinationChainId,
            bridgeData.hasSourceSwaps,
            bridgeData.hasDestinationCall
        );
    }

    /// @notice Extracts the generic swap parameters from the calldata
    /// @param data_ The calldata to extract the generic swap parameters from
    /// @return sendingAssetId The sending asset id extracted from the calldata
    /// @return amount The amount extracted from the calldata
    /// @return receiver The receiver extracted from the calldata
    /// @return receivingAssetId The receiving asset id extracted from the calldata
    /// @return receivingAmount The receiving amount extracted from the calldata
    function extractGenericSwapParameters(bytes calldata data_)
        public
        pure
        returns (
            address sendingAssetId,
            uint256 amount,
            address receiver,
            address receivingAssetId,
            uint256 receivingAmount
        )
    {
        LibSwap.SwapData[] memory swapData;
        bytes memory callData = data_;

        if (bytes4(data_[:4]) == 0xd6a4bc50) {
            // standardizedCall
            callData = abi.decode(data_[4:], (bytes));
        }
        (,,, receiver, receivingAmount, swapData) = abi.decode(
            _slice(callData, 4, callData.length - 4), (bytes32, string, string, address, uint256, LibSwap.SwapData[])
        );

        sendingAssetId = swapData[0].sendingAssetId;
        amount = swapData[0].fromAmount;
        receivingAssetId = swapData[swapData.length - 1].receivingAssetId;
        return (sendingAssetId, amount, receiver, receivingAssetId, receivingAmount);
    }
}

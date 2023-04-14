// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

library Error {
    /*///////////////////////////////////////////////////////////////
                        GENERAL ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev 0- is emitted when the chain id input is invalid.
    error INVALID_INPUT_CHAIN_ID();

    /// @dev error thrown when address input is address 0
    error ZERO_ADDRESS();

    /// @dev - when msg.sender is not core state registry
    error NOT_CORE_STATE_REGISTRY();

    /// @dev - when msg.sender is not factory state registry
    error NOT_FACTORY_STATE_REGISTRY();

    /// @dev - when msg.sender is not protocol admin
    error NOT_PROTOCOL_ADMIN();

    /// @dev - when msg.sender is not super router
    error NOT_SUPER_ROUTER();

    /// @dev if the msg-sender is not token bank
    error NOT_TOKEN_BANK();

    /// @dev if the msg-sender is not super form factory
    error NOT_SUPERFORM_FACTORY();

    /// @dev if the msg-sender is not super registry
    error NOT_SUPER_REGISTRY();

    /// @dev if the msg-sender does not have SWAPPER role
    error NOT_SWAPPER();

    /// @dev if the msg-sender does not have PROCESSOR role
    error NOT_PROCESSOR();

    /// @dev if the msg-sender does not have UPDATER role
    error NOT_UPDATER();

    /// @dev if the msg-sender does not have CORE_CONTRACTS role
    error NOT_CORE_CONTRACTS();

    /// @dev error thrown when the deployer is not the protocol admin
    error INVALID_DEPLOYER();

    /// @dev error thrown when the bridge tokens haven't arrived to destination
    error BRIDGE_TOKENS_PENDING();

    /// @dev error thrown when the safe gas param is incorrectly set
    error INVALID_GAS_OVERRIDE();

    error ALREADY_SET();

    /*///////////////////////////////////////////////////////////////
                        STATE REGISTRY ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev general error when msg.sender isn't a valid caller
    /// TODO: all errors that throw this should be refactored into more specific error messages
    error INVALID_CALLER();

    /// @dev uniqueness check for paylaods
    error DUPLICATE_PAYLOAD();

    /// @dev is emitted when the chain id brought in the cross chain message is invalid
    error INVALID_CHAIN_ID();

    /// @dev if ambId is not valid leading to an address 0 of the implementation
    error INVALID_BRIDGE_ID();

    /// @dev if payload id does not exist
    error INVALID_PAYLOAD_ID();

    /// @dev if payload state is not valid
    /// TODO: all errors that throw this should be refactored into more specific error messages
    error INVALID_PAYLOAD_STATE();

    /// @dev if update payload function was called on a wrong payload
    error INVALID_PAYLOAD_UPDATE_REQUEST();

    /// @dev if payload is being updated with final amounts length different than amounts length
    error DIFFERENT_PAYLOAD_UPDATE_AMOUNTS_LENGTH();

    /// @dev if the amounts being sent in update payload mean a negative slippage
    error NEGATIVE_SLIPPAGE();

    /// @dev if Slippage is out of bounds
    error SLIPPAGE_OUT_OF_BOUNDS();

    /// @dev if payload is not in UPDATED state
    error PAYLOAD_NOT_UPDATED();

    /// @dev if message hasn't reached the specified level of quorum needed
    error QUORUM_NOT_REACHED();

    /// TODO: insert description
    error INVALID_PROOF_BRIDGE_ID();

    /// @dev if the msg.sender is not the wormhole relayer
    error NOT_WORMHOLE_RELAYER();

    /*///////////////////////////////////////////////////////////////
                        SUPERFORM FACTORY ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev emitted when a form is not ERC165 compatible
    error ERC165_UNSUPPORTED();

    /// @dev emitted when a form is not FORM interface compatible
    error FORM_INTERFACE_UNSUPPORTED();

    /// @dev emitted when a form does not exist
    error FORM_DOES_NOT_EXIST();

    /*///////////////////////////////////////////////////////////////
                        SUPER ROUTER ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev emitted when form id is larger than max uint16
    error INVALID_FORM_ID();

    /// @dev is emitted when the amb ids input is invalid.
    error INVALID_AMB_IDS();

    /// @dev is emitted when the vaults data is invalid
    error INVALID_SUPERFORMS_DATA();

    /// @dev is emitted when the chain ids data is invalid
    error INVALID_CHAIN_IDS();

    /// @dev is emitted if anything other than state Registry calls stateSync
    error REQUEST_DENIED();

    /// @dev is emitted when the payload is invalid
    error INVALID_PAYLOAD();

    /// @dev is emitted if srchain ids mismatch in state sync
    error SRC_CHAIN_IDS_MISMATCH();

    /// @dev is emitted if dsthain ids mismatch in state sync
    error DST_CHAIN_IDS_MISMATCH();

    /// @dev is emitted if the payload status is invalid
    error INVALID_PAYLOAD_STATUS();

    /*///////////////////////////////////////////////////////////////
                        LIQUIDITY HANDLER ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted if liquidity bridge fails for erc20 tokens
    error FAILED_TO_EXECUTE_TXDATA();

    /// @dev is emitted if liquidity bridge fails for native tokens
    error FAILED_TO_EXECUTE_TXDATA_NATIVE();

    /// @dev if native amount is not at least equal to the amount in the request
    error INSUFFICIENT_NATIVE_AMOUNT();

    /*///////////////////////////////////////////////////////////////
                            FORM ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when the allowance in direct deposit is not correct
    error DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();

    /// @dev is emitted when the amount in direct deposit is not correct
    error DIRECT_DEPOSIT_INVALID_DATA();

    /// @dev is emitted when the collateral in direct deposit is not correct
    error DIRECT_DEPOSIT_INVALID_COLLATERAL();

    /// @dev is emitted when the collateral in direct withdraw is not correct
    error DIRECT_WITHDRAW_INVALID_COLLATERAL();

    /// @dev is emitted when the amount in direct withdraw is not correct
    error DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

    /// @dev is emitted when the amount in xchain withdraw is not correct
    error XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();

    /// @dev unlock already requested, cooldown period didn't pass yet
    error WITHDRAW_COOLDOWN_PERIOD();

    /// @dev error thrown when the unlock reques
    error LOCKED();
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

library Error {
    /*///////////////////////////////////////////////////////////////
                        GENERAL ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when the chain id input is invalid.
    error INVALID_INPUT_CHAIN_ID();

    /// @dev error thrown when address input is address 0
    error ZERO_ADDRESS();

    /// @dev error thrown when beacon id already exists
    error BEACON_ID_ALREADY_EXISTS();

    /// @dev thrown when msg.sender is not core state registry
    error NOT_CORE_STATE_REGISTRY();

    /// @dev thrown when msg.sender is not form
    error NOT_SUPERFORM();

    /// @dev thrown when msg.sender is not factory state registry
    error NOT_FACTORY_STATE_REGISTRY();

    /// @dev thrown when msg.sender is not roles state registry
    error NOT_ROLES_STATE_REGISTRY();

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

    /// @dev thrown if the msg-sender is not super form factory
    error NOT_SUPERFORM_FACTORY();

    /// @dev thrown if the msg-sender is not super registry
    error NOT_SUPER_REGISTRY();

    /// @dev thrown if the msg-sender does not have SWAPPER role
    error NOT_SWAPPER();

    /// @dev thrown if the msg-sender does not have PROCESSOR role
    error NOT_PROCESSOR();

    /// @dev thrown if the msg-sender does not have UPDATER role
    error NOT_UPDATER();

    /// @dev thrown if the msg-sender does not have CORE_CONTRACTS role
    error NOT_CORE_CONTRACTS();

    /// @dev thrown when the bridge tokens haven't arrived to destination
    error BRIDGE_TOKENS_PENDING();

    /// @dev thrown when trying to set again pseudo immutables in SuperRegistry
    error DISABLED();

    /// @dev thrown when the native tokens transfer has failed
    error NATIVE_TOKEN_TRANSFER_FAILURE();

    /*///////////////////////////////////////////////////////////////
                         LIQUIDITY BRIDGE ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev thrown when the validation of bridge txData fails due to wrong amount
    error INVALID_TXDATA_AMOUNTS();

    /// @dev is emitted when the chain id in the txdata is invalid
    error INVALID_TXDATA_CHAIN_ID();

    /// @dev thrown the when validation of bridge txData fails due to wrong receiver
    error INVALID_TXDATA_RECEIVER();

    /// @dev thrown when the validation of bridge txData fails due to wrong token
    error INVALID_TXDATA_TOKEN();

    /*///////////////////////////////////////////////////////////////
                        STATE REGISTRY ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev thrown when msg.sender isn't a valid caller
    /// TODO: all errors that throw this should be refactored into more specific error messages - Sujith
    error INVALID_CALLER();

    /// @dev thrown when src chain sender is not valid
    error INVALID_SRC_SENDER();

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

    /// @dev thrown if payload state is not valid
    /// TODO: all errors that throw this should be refactored into more specific error messages - Sujith
    error INVALID_PAYLOAD_STATE();

    /// @dev thrown if update payload function was called on a wrong payload
    error INVALID_PAYLOAD_UPDATE_REQUEST();

    /// @dev thrown if payload is being updated with final amounts length different than amounts length
    error DIFFERENT_PAYLOAD_UPDATE_AMOUNTS_LENGTH();

    /// @dev thrown if the amounts being sent in update payload mean a negative slippage
    error NEGATIVE_SLIPPAGE();

    /// @dev thrown if Slippage is out of bounds
    error SLIPPAGE_OUT_OF_BOUNDS();

    /// @dev thrown if payload is not in UPDATED state
    error PAYLOAD_NOT_UPDATED();

    /// @dev thrown if message hasn't reached the specified level of quorum needed
    error QUORUM_NOT_REACHED();

    /// @dev thrown if gas refunds failed
    error GAS_REFUND_FAILED();

    /// @dev thrown if any of the ambs in indexes +1 are repeated  (index 0)
    error INVALID_PROOF_BRIDGE_ID();

    /// @dev thrown if the rescue data lengths are invalid
    error INVALID_RESCUE_DATA();

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

    /*///////////////////////////////////////////////////////////////
                        SUPER ROUTER ERRORS
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

    /// @dev thrown when the collateral in direct deposit is not correct
    error DIRECT_DEPOSIT_INVALID_COLLATERAL();

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

    /*///////////////////////////////////////////////////////////////
                        FEE COLLECTOR ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev thrown when user pays zero fees
    error ZERO_MSG_VALUE();

    /// @dev thrown when fees withdrawal fails
    error FAILED_WITHDRAW();

    /*///////////////////////////////////////////////////////////////
                        SUPER POSITIONS ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev thrown when the uri cannot be updated
    error DYNAMIC_URI_FROZEN();
}

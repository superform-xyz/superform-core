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

    /// @dev error thrown when beacon id already exists
    error BEACON_ID_ALREADY_EXISTS();

    /// @dev - when msg.sender is not core state registry
    error NOT_CORE_STATE_REGISTRY();

    /// @dev - when msg.sender is not two steps form processor
    error NOT_TWO_STEPS_PROCESSOR();

    /// @dev - when msg.sender is not form
    error NOT_SUPERFORM();

    /// @dev - when the address is not a state registry on super registry
    error NOT_VALID_STATE_REGISTRY();

    /// @dev - when msg.sender is not form state registry
    error NOT_FORM_STATE_REGISTRY();

    /// @dev - when msg.sender is not a valid amb implementation
    error NOT_AMB_IMPLEMENTATION();

    /// @dev - when msg.sender is not state registry
    error NOT_STATE_REGISTRY();

    /// @dev - when msg.sender is not factory state registry
    error NOT_FACTORY_STATE_REGISTRY();

    /// @dev - when msg.sender is not roles state registry
    error NOT_ROLES_STATE_REGISTRY();

    /// @dev - when msg.sender is not two step state registry
    error NOT_TWO_STEP_STATE_REGISTRY();

    /// @dev - when msg.sender is not protocol admin
    error NOT_PROTOCOL_ADMIN();

    /// @dev - when msg.sender is not emergency admin
    error NOT_EMERGENCY_ADMIN();

    /// @dev - when msg.sender is not super router
    error NOT_SUPER_ROUTER();

    /// @dev - when msg.sender is not minter
    error NOT_MINTER();

    /// @dev - when msg.sender is not burner
    error NOT_BURNER();

    /// @dev - when msg.sender is not minter state registry
    error NOT_MINTER_STATE_REGISTRY();

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

    error DISABLED();

    /// @dev when the native tokens transfer has failed
    error NATIVE_TOKEN_TRANSFER_FAILURE();

    /*///////////////////////////////////////////////////////////////
                         LIQUIDITY BRIDGE ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev when validation of bridge txData fails due to wrong amount
    error INVALID_TXDATA_AMOUNTS();

    /// @dev is emitted when the chain id in the txdata is invalid
    error INVALID_TXDATA_CHAIN_ID();

    /// @dev when validation of bridge txData fails due to wrong receiver
    error INVALID_TXDATA_RECEIVER();

    /// @dev when validation of bridge txData fails due to wrong token
    error INVALID_TXDATA_TOKEN();

    /*///////////////////////////////////////////////////////////////
                        STATE REGISTRY ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev celer adapter specific error, when caller not celer message bus
    error CALLER_NOT_MESSAGE_BUS();

    /// @dev hyperlane adapter specific error, when caller not hyperlane mailbox
    error CALLER_NOT_MAILBOX();

    /// @dev layerzero adapter specific error, when caller not layerzero endpoint
    error CALLER_NOT_ENDPOINT();

    /// @dev general error when src chain sender is not valid
    error INVALID_SRC_SENDER();

    /// @dev general error when src chain is blocked from messaging
    error INVALID_SRC_CHAIN_ID();

    /// @dev uniqueness check for paylaods
    error DUPLICATE_PAYLOAD();

    /// @dev is emitted when the chain id brought in the cross chain message is invalid
    error INVALID_CHAIN_ID();

    /// @dev if ambId is not valid leading to an address 0 of the implementation
    error INVALID_BRIDGE_ID();

    /// @dev if payload id does not exist
    error INVALID_PAYLOAD_ID();

    /// @dev is thrown is payload is already updated (during xChain deposits)
    error PAYLOAD_ALREADY_UPDATED();

    /// @dev is thrown is payload is already processed
    error PAYLOAD_ALREADY_PROCESSED();

    /// @dev is thrown if the payload hash is zero during `retryMessage` on Layezero implementation
    error ZERO_PAYLOAD_HASH();

    /// @dev is thrown if the payload hash is invalid during `retryMessage` on Layezero implementation
    error INVALID_PAYLOAD_HASH();

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

    /// @dev is gas refunds failed
    error GAS_REFUND_FAILED();

    /// @dev error thrown if any of the ambs in indexes +1 are repeated  (index 0)
    error INVALID_PROOF_BRIDGE_ID();

    /// @dev if less than 2 AMBs are passed in the state request
    error INVALID_AMB_IDS_LENGTH();

    /// @dev is thrown if the gas per dst doesn't match chain ids in broadcasting
    error INVALID_GAS_PER_DST_LENGTH();

    /// @dev if trying to rescue a non multi failed deposit data
    error NOT_MULTI_FAILURE();

    /// @dev if trying to rescue a non single failed deposit data
    error NOT_SINGLE_FAILURE();

    /// @dev if deposits were already rescued
    error ALREADY_RESCUED();

    /// @dev if the rescue data lengths are invalid
    error INVALID_RESCUE_DATA();

    /*///////////////////////////////////////////////////////////////
                        SUPERFORM FACTORY ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev emitted when a form is not ERC165 compatible
    error ERC165_UNSUPPORTED();

    /// @dev emitted when a form is not FORM interface compatible
    error FORM_INTERFACE_UNSUPPORTED();

    /// @dev emitted when a form does not exist
    error FORM_DOES_NOT_EXIST();

    /// @dev emitted when a vault has already been added to a form kind
    error VAULT_ALREADY_HAS_FORM();

    /// @dev emitted when same vault and beacon is used to create new superform
    error VAULT_BEACON_COMBNATION_EXISTS();

    /*///////////////////////////////////////////////////////////////
                        SUPER ROUTER ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev emitted when form id is larger than max uint16
    error INVALID_FORM_ID();

    /// @dev is emitted when the vaults data is invalid
    error INVALID_SUPERFORMS_DATA();

    /// @dev is emitted when the chain ids data is invalid
    error INVALID_CHAIN_IDS();

    /// @dev is emitted when the payload is invalid
    error INVALID_PAYLOAD();

    /// @dev is emitted if src senders mismatch in state sync
    error SRC_SENDER_MISMATCH();

    /// @dev is emitted if src tx types mismatch in state sync
    error SRC_TX_TYPE_MISMATCH();

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

    /*///////////////////////////////////////////////////////////////
                        FEE COLLECTOR ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @dev - when msg.sender is not fee admin
    error NOT_FEE_ADMIN();

    /// @dev error thrown when user pays zero
    error ZERO_MSG_VALUE();

    /// @dev error thrown when fees withdrawal fails
    error FAILED_WITHDRAW();

    /*///////////////////////////////////////////////////////////////
                        SUPER POSITIONS ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev error thrown when the uri cannot be updated
    error DYNAMIC_URI_FROZEN();
}

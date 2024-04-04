/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity >=0.8.0;

import "./IQuote.sol";

/// @title IHashflowRouter
/// @author Victor Ionescu
/**
 * @notice In terms of user-facing functionality, the Router is responsible for:
 * - orchestrating trades
 * - managing cross-chain permissions
 *
 * Every trade requires consent from two parties: the Trader and the Market Maker.
 * However, there are two models to establish consent:
 * - RFQ-T: in this model, the Market Maker provides an EIP-191 signature for the quote,
 *   while the Trader signs the transaction and submits it on-chain
 * - RFQ-M: in this model, the Trader provides an EIP-712 signature for the quote,
 *   the Market Maker provides an EIP-191 signature, and a 3rd party relays the trade.
 *   The 3rd party can be the Market Maker itself.
 *
 * In terms of Hashflow internals, the Router maintains a set of authorized pool
 * contracts that are allowed to be used for trading. This allowlist creates
 * guarantees against malicious behavior, as documented in specific places.
 *
 * The Router contract is not upgradeable. In order to change functionality, a new
 * Router has to be deployed, and new HashflowPool contracts have to be deployed
 * by the Market Makers.
 */
/// @dev Trade / liquidity events are emitted at the HashflowPool level, rather than the router.
interface IHashflowRouter is IQuote {
    /**
     * @notice X-Chain message received from an X-Chain Messenger. This is used by the
     * Router to communicate a fill to a HashflowPool.
     */
    struct XChainFillMessage {
        /// @notice The Hashflow Chain ID of the source chain.
        uint16 srcHashflowChainId;
        /// @notice The address of the HashflowPool on the source chain.
        bytes32 srcPool;
        /// @notice The HashflowPool to disburse funds on the destination chain.
        address dstPool;
        /**
         * @notice The external account linked to the HashflowPool on the destination chain.
         * If the HashflowPool holds funds, this should be bytes32(0).
         */
        address dstExternalAccount;
        /// @notice The recipient of the quoteToken on the destination chain.
        address dstTrader;
        /// @notice The token that the trader buys on the destination chain.
        address quoteToken;
        /// @notice The amount of quoteToken bought.
        uint256 quoteTokenAmount;
        /// @notice Unique identifier for the quote.
        /// @dev Generated off-chain via a distributed UUID generator.
        bytes32 txid;
        /// @notice The caller of the trade function on the source chain.
        bytes32 srcCaller;
        /// @notice The contract to call, if any.
        address dstContract;
        /// @notice The calldata for the contract.
        bytes dstContractCalldata;
    }

    /// @notice Emitted when the authorization status of a pool changes.
    /// @param pool The pool whose status changed.
    /// @param authorized The new auth status.
    event UpdatePoolAuthorizaton(address pool, bool authorized);

    /// @notice Emitted when a sender pool authorization changes.
    /// @param pool Pool address on this chain.
    /// @param otherHashflowChainId Hashflow Chain ID of the other chain.
    /// @param otherChainPool Pool address on the other chain.
    /// @param authorized Whether the pool is authorized.
    event UpdateXChainPoolAuthorization(
        address indexed pool, uint16 otherHashflowChainId, bytes32 otherChainPool, bool authorized
    );

    /// @notice Emitted when the authorization of an x-caller changes.
    /// @param pool Pool address on this chain.
    /// @param otherHashflowChainId Hashflow Chain ID of the other chain.
    /// @param caller Caller address on the other chain.
    /// @param authorized Whether the caller is authorized.
    event UpdateXChainCallerAuthorization(
        address indexed pool, uint16 otherHashflowChainId, bytes32 caller, bool authorized
    );

    /// @notice Emitted when the authorization status of an X-Chain Messenger changes for a pool.
    /// @param pool Pool address for which the Messenger authorization changes.
    /// @param xChainMessenger Address of the Messenger.
    /// @param authorized Whether the X-Chain Messenger is authorized.
    event UpdateXChainMessengerAuthorization(address indexed pool, address xChainMessenger, bool authorized);

    /// @notice Emitted when the authorized status of an X-Chain Messenger changes for a callee.
    /// @param callee Address of the callee.
    /// @param xChainMessenger Address of the Messenger.
    /// @param authorized Whether the X-Chain Messenger is authorized.
    event UpdateXChainMessengerCallerAuthorization(address indexed callee, address xChainMessenger, bool authorized);

    /// @notice Emitted when the Limit Order Guardian address is updated.
    /// @param guardian The new Guardian address.
    event UpdateLimitOrderGuardian(address guardian);

    /// @notice Initializes the Router. Called one time.
    /// @param factory The address of the HashflowFactory contract.
    function initialize(address factory) external;

    /// @notice Returns the address of the associated HashflowFactor contract.
    function factory() external view returns (address);

    function authorizedXChainPools(bytes32 dstPool, uint16 srcHChainId, bytes32 srcPool) external view returns (bool);

    function authorizedXChainCallers(
        address dstContract,
        uint16 srcHashflowChainId,
        bytes32 caller
    )
        external
        view
        returns (bool);

    function authorizedXChainMessengersByPool(address pool, address messenger) external view returns (bool);

    function authorizedXChainMessengersByCallee(address callee, address messenger) external view returns (bool);

    /// @notice Executes an intra-chain RFQ-T trade.
    /// @param quote The quote data to be executed.
    function tradeRFQT(RFQTQuote memory quote) external payable;

    /// @notice Executes an intra-chain RFQ-T trade, leveraging an ERC-20 permit.
    /// @param quote The quote data to be executed.
    /// @dev Does not support native tokens for the baseToken.
    function tradeRFQTWithPermit(
        RFQTQuote memory quote,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 amountToApprove
    )
        external;

    /// @notice Executes an intra-chain RFQ-T trade.
    /// @param quote The quote to be executed.
    function tradeRFQM(RFQMQuote memory quote) external;

    /// @notice Executes an intra-chain RFQ-T trade, leveraging an ERC-20 permit.
    /// @param quote The quote to be executed.
    /// @param deadline The deadline of the ERC-20 permit.
    /// @param v v-part of the signature.
    /// @param r r-part of the signature.
    /// @param s s-part of the signature.
    /// @param amountToApprove The amount being approved.
    function tradeRFQMWithPermit(
        RFQMQuote memory quote,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 amountToApprove
    )
        external;

    /// @notice Executes an intra-chain RFQ-T trade.
    /// @param quote The quote to be executed.
    /// @param guardianSignature A signature issued by the Limit Order Guardian.
    function tradeRFQMLimitOrder(RFQMQuote memory quote, bytes memory guardianSignature) external;

    /// @notice Executes an intra-chain RFQ-T trade, leveraging an ERC-20 permit.
    /// @param quote The quote to be executed.
    /// @param guardianSignature A signature issued by the Limit Order Guardian.
    /// @param deadline The deadline of the ERC-20 permit.
    /// @param v v-part of the signature.
    /// @param r r-part of the signature.
    /// @param s s-part of the signature.
    /// @param amountToApprove The amount being approved.
    function tradeRFQMLimitOrderWithPermit(
        RFQMQuote memory quote,
        bytes memory guardianSignature,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 amountToApprove
    )
        external;

    /// @notice Executes an RFQ-T cross-chain trade.
    /// @param quote The quote to be executed.
    /// @param dstContract The address of the contract to be called on the destination chain.
    /// @param dstCalldata The calldata for the smart contract call.
    function tradeXChainRFQT(
        XChainRFQTQuote memory quote,
        bytes32 dstContract,
        bytes memory dstCalldata
    )
        external
        payable;

    /// @notice Executes an RFQ-T cross-chain trade, leveraging an ERC-20 permit.
    /// @param quote The quote to be executed.
    /// @param dstContract The address of the contract to be called on the destination chain.
    /// @param dstCalldata The calldata for the smart contract call.
    /// @param deadline The deadline of the ERC-20 permit.
    /// @param v v-part of the signature.
    /// @param r r-part of the signature.
    /// @param s s-part of the signature.
    /// @param amountToApprove The amount being approved.
    function tradeXChainRFQTWithPermit(
        XChainRFQTQuote memory quote,
        bytes32 dstContract,
        bytes memory dstCalldata,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 amountToApprove
    )
        external
        payable;

    /// @notice Executes an RFQ-M cross-chain trade.
    /// @param quote The quote to be executed.
    /// @param dstContract The address of the contract to be called on the destination chain.
    /// @param dstCalldata The calldata for the smart contract call.
    function tradeXChainRFQM(
        XChainRFQMQuote memory quote,
        bytes32 dstContract,
        bytes memory dstCalldata
    )
        external
        payable;

    /// @notice Similar to tradeXChainRFQm, but includes a spend permit for the baseToken.
    /// @param quote The quote to be executed.
    /// @param dstContract The address of the contract to be called on the destination chain.
    /// @param dstCalldata The calldata for the smart contract call.
    /// @param deadline The deadline of the ERC-20 permit.
    /// @param v v-part of the signature.
    /// @param r r-part of the signature.
    /// @param s s-part of the signature.
    /// @param amountToApprove The amount to approve.
    function tradeXChainRFQMWithPermit(
        XChainRFQMQuote memory quote,
        bytes32 dstContract,
        bytes memory dstCalldata,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 amountToApprove
    )
        external
        payable;

    /// @notice Completes the second leg of a cross-chain trade.
    /// @param fillMessage Payload containing information necessary to complete the trade.
    function fillXChain(XChainFillMessage memory fillMessage) external;

    /// @notice Returns whether the pool is authorized for trading.
    /// @param pool The address of the HashflowPool.
    function authorizedPools(address pool) external view returns (bool);

    /// @notice Allows the owner to unauthorize a potentially compromised pool. Cannot be reverted.
    /// @param pool The address of the HashflowPool.
    function forceUnauthorizePool(address pool) external;

    /// @notice Authorizes a HashflowPool for trading.
    /// @dev Can only be called by the HashflowFactory or the admin.
    function updatePoolAuthorization(address pool, bool authorized) external;

    /// @notice Updates the authorization status of an X-Chain pool pair.
    /// @param otherHashflowChainId The Hashflow Chain ID of the peer chain.
    /// @param otherPool The 32-byte representation of the Pool address on the peer chain.
    /// @param authorized Whether the pool is authorized to communicate with the sender pool.
    function updateXChainPoolAuthorization(uint16 otherHashflowChainId, bytes32 otherPool, bool authorized) external;

    /// @notice Updates the authorization status of an X-Chain caller.
    /// @param otherHashflowChainId The Hashflow Chain ID of the peer chain.
    /// @param caller The caller address.
    /// @param authorized Whether the caller is authorized to send an x-call to the sender pool.
    function updateXChainCallerAuthorization(uint16 otherHashflowChainId, bytes32 caller, bool authorized) external;

    /// @notice Updates the authorization status of an X-Chain Messenger app.
    /// @param xChainMessenger The address of the Messenger App.
    /// @param authorized The new authorization status.
    function updateXChainMessengerAuthorization(address xChainMessenger, bool authorized) external;

    /// @notice Updates the authorization status of an X-Chain Messenger app.
    /// @param xChainMessenger The address of the Messenger App.
    /// @param authorized The new authorization status.
    function updateXChainMessengerCallerAuthorization(address xChainMessenger, bool authorized) external;

    /// @notice Used to stop all operations on a pool, in case of an emergency.
    /// @param pool The address of the HashflowPool.
    /// @param enabled Whether the pool is enabled.
    function killswitchPool(address pool, bool enabled) external;

    /// @notice Used to update the Limit Order Guardian.
    /// @param guardian The address of the new Guardian.
    function updateLimitOrderGuardian(address guardian) external;

    /// @notice Allows the owner to withdraw excess funds from the Router.
    /// @dev Under normal operations, the Router should not have excess funds.
    function withdrawFunds(address token) external;
}

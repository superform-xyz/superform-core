/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity >=0.8.0;

/// @title IQuote
/// @author Victor Ionescu
/**
 * @notice Interface for quote structs used for trading. There are two major types of trades:
 * - intra-chain: atomic transactions within one chain
 * - cross-chain: multi-leg transactions between two chains, which utilize interoperability protocols
 *                such as Wormhole.
 *
 * Separately, there are two trading modes:
 * - RFQ-T: the trader signs the transaction, the market maker signs the quote
 * - RFQ-M: both the trader and Market Maker sign the quote, any relayer can sign the transaction
 */
interface IQuote {
    /// @notice Used for intra-chain RFQ-T trades.
    struct RFQTQuote {
        /// @notice The address of the HashflowPool to trade against.
        address pool;
        /**
         * @notice The external account linked to the HashflowPool.
         * If the HashflowPool holds funds, this should be address(0).
         */
        address externalAccount;
        /// @notice The recipient of the quoteToken at the end of the trade.
        address trader;
        /**
         * @notice The account "effectively" making the trade (ultimately receiving the funds).
         * This is commonly used by aggregators, where a proxy contract (the 'trader')
         * receives the quoteToken, and the effective trader is the user initiating the call.
         *
         * This field DOES NOT influence movement of funds. However, it is used to check against
         * quote replay.
         */
        address effectiveTrader;
        /// @notice The token that the trader sells.
        address baseToken;
        /// @notice The token that the trader buys.
        address quoteToken;
        /**
         * @notice The amount of baseToken sold in this trade. The exchange rate
         * is going to be preserved as the quoteTokenAmount / baseTokenAmount ratio.
         *
         * Most commonly, effectiveBaseTokenAmount will == baseTokenAmount.
         */
        uint256 effectiveBaseTokenAmount;
        /// @notice The max amount of baseToken sold.
        uint256 baseTokenAmount;
        /// @notice The amount of quoteToken bought when baseTokenAmount is sold.
        uint256 quoteTokenAmount;
        /// @notice The Unix timestamp (in seconds) when the quote expires.
        /// @dev This gets checked against block.timestamp.
        uint256 quoteExpiry;
        /// @notice The nonce used by this effectiveTrader. Nonces are used to protect against replay.
        uint256 nonce;
        /// @notice Unique identifier for the quote.
        /// @dev Generated off-chain via a distributed UUID generator.
        bytes32 txid;
        /// @notice Signature provided by the market maker (EIP-191).
        bytes signature;
    }

    /// @notice Used for intra-chain RFQ-M trades.
    struct RFQMQuote {
        /// @notice The address of the HashflowPool to trade against.
        address pool;
        /**
         * @notice The external account linked to the HashflowPool.
         * If the HashflowPool holds funds, this should be address(0).
         */
        address externalAccount;
        /// @notice The account that will be debited baseToken / credited quoteToken.
        address trader;
        /// @notice The token that the trader sells.
        address baseToken;
        /// @notice The token that the trader buys.
        address quoteToken;
        /// @notice The amount of baseToken sold.
        uint256 baseTokenAmount;
        /// @notice The amount of quoteToken bought.
        uint256 quoteTokenAmount;
        /// @notice The Unix timestamp (in seconds) when the quote expires.
        /// @dev This gets checked against block.timestamp.
        uint256 quoteExpiry;
        /// @notice Unique identifier for the quote.
        /// @dev Generated off-chain via a distributed UUID generator.
        bytes32 txid;
        /// @notice Signature provided by the trader (EIP-712).
        bytes takerSignature;
        /// @notice Signature provided by the market maker (EIP-191).
        bytes makerSignature;
    }

    /// @notice Used for cross-chain RFQ-T trades.
    struct XChainRFQTQuote {
        /// @notice The Hashflow Chain ID of the source chain.
        uint16 srcChainId;
        /// @notice The Hashflow Chain ID of the destination chain.
        uint16 dstChainId;
        /// @notice The address of the HashflowPool to trade against on the source chain.
        address srcPool;
        /// @notice The HashflowPool to disburse funds on the destination chain.
        /// @dev This is bytes32 in order to anticipate non-EVM chains.
        bytes32 dstPool;
        /**
         * @notice The external account linked to the HashflowPool on the source chain.
         * If the HashflowPool holds funds, this should be address(0).
         */
        address srcExternalAccount;
        /**
         * @notice The external account linked to the HashflowPool on the destination chain.
         * If the HashflowPool holds funds, this should be bytes32(0).
         */
        bytes32 dstExternalAccount;
        /// @notice The recipient of the quoteToken on the destination chain.
        bytes32 dstTrader;
        /// @notice The token that the trader sells on the source chain.
        address baseToken;
        /// @notice The token that the trader buys on the destination chain.
        bytes32 quoteToken;
        /**
         * @notice The amount of baseToken sold in this trade. The exchange rate
         * is going to be preserved as the quoteTokenAmount / baseTokenAmount ratio.
         *
         * Most commonly, effectiveBaseTokenAmount will == baseTokenAmount.
         */
        uint256 effectiveBaseTokenAmount;
        /// @notice The amount of baseToken sold.
        uint256 baseTokenAmount;
        /// @notice The amount of quoteToken bought.
        uint256 quoteTokenAmount;
        /**
         * @notice The Unix timestamp (in seconds) when the quote expire. Only enforced
         * on the source chain.
         */
        /// @dev This gets checked against block.timestamp.
        uint256 quoteExpiry;
        /// @notice The nonce used by this trader.
        uint256 nonce;
        /// @notice Unique identifier for the quote.
        /// @dev Generated off-chain via a distributed UUID generator.
        bytes32 txid;
        /**
         * @notice The address of the IHashflowXChainMessenger contract used for
         * cross-chain communication.
         */
        address xChainMessenger;
        /// @notice Signature provided by the market maker (EIP-191).
        bytes signature;
    }

    /// @notice Used for Cross-Chain RFQ-M trades.
    struct XChainRFQMQuote {
        /// @notice The Hashflow Chain ID of the source chain.
        uint16 srcChainId;
        /// @notice The Hashflow Chain ID of the destination chain.
        uint16 dstChainId;
        /// @notice The address of the HashflowPool to trade against on the source chain.
        address srcPool;
        /// @notice The HashflowPool to disburse funds on the destination chain.
        /// @dev This is bytes32 in order to anticipate non-EVM chains.
        bytes32 dstPool;
        /**
         * @notice The external account linked to the HashflowPool on the source chain.
         * If the HashflowPool holds funds, this should be address(0).
         */
        address srcExternalAccount;
        /**
         * @notice The external account linked to the HashflowPool on the destination chain.
         * If the HashflowPool holds funds, this should be bytes32(0).
         */
        bytes32 dstExternalAccount;
        /// @notice The account that will be debited baseToken on the source chain.
        address trader;
        /// @notice The recipient of the quoteToken on the destination chain.
        bytes32 dstTrader;
        /// @notice The token that the trader sells on the source chain.
        address baseToken;
        /// @notice The token that the trader buys on the destination chain.
        bytes32 quoteToken;
        /// @notice The amount of baseToken sold.
        uint256 baseTokenAmount;
        /// @notice The amount of quoteToken bought.
        uint256 quoteTokenAmount;
        /**
         * @notice The Unix timestamp (in seconds) when the quote expire. Only enforced
         * on the source chain.
         */
        /// @dev This gets checked against block.timestamp.
        uint256 quoteExpiry;
        /// @notice Unique identifier for the quote.
        /// @dev Generated off-chain via a distributed UUID generator.
        bytes32 txid;
        /**
         * @notice The address of the IHashflowXChainMessenger contract used for
         * cross-chain communication.
         */
        address xChainMessenger;
        /// @notice Signature provided by the trader (EIP-712).
        bytes takerSignature;
        /// @notice Signature provided by the market maker (EIP-191).
        bytes makerSignature;
    }
}

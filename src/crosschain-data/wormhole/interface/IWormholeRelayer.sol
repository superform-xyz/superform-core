// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

/// @dev is imported from (https://github.com/wormhole-foundation/trustless-generic-relayer/blob/main/ethereum/contracts/interfaces/IWormholeRelayer.sol)
interface IWormholeRelayer {
    function send(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes32 refundAddress,
        uint256 maxTransactionFee,
        uint256 receiverValue,
        uint32 nonce
    ) external payable returns (uint64 sequence);

    struct Send {
        uint16 targetChain;
        bytes32 targetAddress;
        bytes32 refundAddress;
        uint256 maxTransactionFee;
        uint256 receiverValue;
        bytes relayParameters;
    }

    function send(
        Send memory request,
        uint32 nonce,
        address relayProvider
    ) external payable returns (uint64 sequence);

    function forward(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes32 refundAddress,
        uint256 maxTransactionFee,
        uint256 receiverValue,
        uint32 nonce
    ) external payable;

    function forward(
        Send memory request,
        uint32 nonce,
        address relayProvider
    ) external payable;

    struct MultichainSend {
        address relayProviderAddress;
        Send[] requests;
    }

    function multichainSend(
        MultichainSend memory sendContainer,
        uint32 nonce
    ) external payable returns (uint64 sequence);

    function multichainForward(
        MultichainSend memory requests,
        uint32 nonce
    ) external payable;

    struct ResendByTx {
        uint16 sourceChain;
        bytes32 sourceTxHash;
        uint32 sourceNonce;
        uint16 targetChain;
        uint8 deliveryIndex;
        uint8 multisendIndex;
        uint256 newMaxTransactionFee;
        uint256 newReceiverValue;
        bytes newRelayParameters;
    }

    function resend(
        ResendByTx memory request,
        address relayProvider
    ) external payable returns (uint64 sequence);

    function quoteGas(
        uint16 targetChain,
        uint32 gasLimit,
        address relayProvider
    ) external pure returns (uint256 maxTransactionFee);

    function quoteGasResend(
        uint16 targetChain,
        uint32 gasLimit,
        address relayProvider
    ) external pure returns (uint256 maxTransactionFee);

    function quoteReceiverValue(
        uint16 targetChain,
        uint256 targetAmount,
        address relayProvider
    ) external pure returns (uint256 receiverValue);

    function toWormholeFormat(
        address addr
    ) external pure returns (bytes32 whFormat);

    function fromWormholeFormat(
        bytes32 whFormatAddress
    ) external pure returns (address addr);

    function getDefaultRelayProvider()
        external
        view
        returns (address relayProvider);

    function getDefaultRelayParams()
        external
        pure
        returns (bytes memory relayParams);

    error FundsTooMuch(uint8 multisendIndex); // (maxTransactionFee, converted to target chain currency) + (receiverValue, converted to target chain currency) is greater than what your chosen relay provider allows
    error MaxTransactionFeeNotEnough(uint8 multisendIndex); // maxTransactionFee is less than the minimum needed by your chosen relay provider
    error MsgValueTooLow(); // msg.value is too low
    // Specifically, (msg.value) + (any leftover funds if this is a forward) is less than (maxTransactionFee + receiverValue), summed over all of your requests if this is a multichainSend/multichainForward
    error NonceIsZero(); // Nonce cannot be 0
    error NoDeliveryInProgress(); // Forwards can only be requested within execution of 'receiveWormholeMessages', or when a delivery is in progress
    error MultipleForwardsRequested(); // Only one forward can be requested in a transaction
    error ForwardRequestFromWrongAddress(); // A forward was requested from an address that is not the 'targetAddress' of the original delivery
    error RelayProviderDoesNotSupportTargetChain(); // Your relay provider does not support the target chain you specified
    error MultichainSendEmpty(); // Your delivery request container has size 0
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param dstChainId_ - the destination chain identifier
    // @param destination_ - the address on destination chain (in bytes). address length/format may vary by chains
    // @param payload_ - a custom bytes payload to send to the destination contract
    // @param refundAddress_ - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param zroPaymentAddress_ - the address of the ZRO token holder who would pay for the transaction
    // @param adapterParams_ - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 dstChainId_,
        bytes calldata destination_,
        bytes calldata payload_,
        address payable refundAddress_,
        address zroPaymentAddress_,
        bytes calldata adapterParams_
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param srcChainId_ - the source chain identifier
    // @param srcAddress_ - the source contract (as bytes) at the source chain
    // @param dstAddress_ - the address on destination chain
    // @param nonce_ - the unbound message ordering nonce
    // @param gasLimit_ - the gas limit for external contract execution
    // @param payload_ - verified payload to send to the destination contract
    function receivePayload(
        uint16 srcChainId_,
        bytes calldata srcAddress_,
        address dstAddress_,
        uint64 nonce_,
        uint256 gasLimit_,
        bytes calldata payload_
    ) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param srcChainId_ - the source chain identifier
    // @param srcAddress_ - the source chain contract address
    function getInboundNonce(
        uint16 srcChainId_,
        bytes calldata srcAddress_
    ) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param srcAddress_ - the source chain contract address
    function getOutboundNonce(
        uint16 dstChainId_,
        address srcAddress_
    ) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param dstChainId_ - the destination chain identifier
    // @param userApplication_ - the user app address on this EVM chain
    // @param payload_ - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 dstChainId_,
        address userApplication_,
        bytes calldata payload_,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param srcChainId_ - the source chain identifier
    // @param srcAddress_ - the source chain contract address
    // @param payload_ - the payload to be retried
    function retryPayload(
        uint16 srcChainId_,
        bytes calldata srcAddress_,
        bytes calldata payload_
    ) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param srcChainId_ - the source chain identifier
    // @param srcAddress_ - the source chain contract address
    function hasStoredPayload(
        uint16 srcChainId_,
        bytes calldata srcAddress_
    ) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param userApplication_ - the user app address on this EVM chain
    function getSendLibraryAddress(
        address userApplication_
    ) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param userApplication_ - the user app address on this EVM chain
    function getReceiveLibraryAddress(
        address userApplication_
    ) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param version_ - messaging library version
    // @param chainId_ - the chainId for the pending config change
    // @param userApplication_ - the contract address of the user application
    // @param configType_ - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 version_,
        uint16 chainId_,
        address userApplication_,
        uint256 configType_
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param userApplication_ - the contract address of the user application
    function getSendVersion(
        address userApplication_
    ) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param userApplication_ - the contract address of the user application
    function getReceiveVersion(
        address userApplication_
    ) external view returns (uint16);
}

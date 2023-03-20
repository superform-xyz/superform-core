// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param version_ - messaging library version
    // @param chainId_ - the chainId for the pending config change
    // @param configType_ - type of configuration. every messaging library has its own convention.
    // @param config_ - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 version_,
        uint16 chainId_,
        uint256 configType_,
        bytes calldata config_
    ) external;

    // @notice set the send() LayerZero messaging library version to version_
    // @param version_ - new messaging library version
    function setSendVersion(uint16 version_) external;

    // @notice set the lzReceive() LayerZero messaging library version to version_
    // @param version_ - new messaging library version
    function setReceiveVersion(uint16 version_) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param srcChainId_ - the chainId of the source chain
    // @param srcAddress_ - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 srcChainId_, bytes calldata srcAddress_)
        external;
}

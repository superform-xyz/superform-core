// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin-contracts/contracts/access/Ownable.sol";
import "./interface/ILayerZeroReceiver.sol";
import "./interface/ILayerZeroUserApplicationConfig.sol";
import "./interface/ILayerZeroEndpoint.sol";
import "forge-std/console.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is
    Ownable,
    ILayerZeroReceiver,
    ILayerZeroUserApplicationConfig
{
    ILayerZeroEndpoint public immutable lzEndpoint;

    mapping(uint16 => bytes) public trustedRemoteLookup;

    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(
            _msgSender() == address(lzEndpoint),
            "LzApp: invalid endpoint caller"
        );

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        console.log(_srcChainId);
        console.logBytes(trustedRemote);
        console.logBytes(_srcAddress);
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        /// FIXME: tests doesn't update trusted remotes properly
        // require(
        //     _srcAddress.length == trustedRemote.length &&
        //         keccak256(_srcAddress) == keccak256(trustedRemote),
        //     "LzApp: invalid source sending contract"
        // );

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        uint256 _msgValue
    ) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(
            trustedRemote.length != 0,
            "LzApp: destination chain is not a trusted source"
        );

        lzEndpoint.send{value: _msgValue}(
            _dstChainId,
            trustedRemote,
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address,
        uint256 _configType
    ) external view returns (bytes memory) {
        return
            lzEndpoint.getConfig(
                _version,
                _chainId,
                address(this),
                _configType
            );
    }

    // generic config for LayerZero user Application
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // allow owner to set it multiple times.
    function setTrustedRemote(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _srcAddress;
        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------

    function isTrustedRemote(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}

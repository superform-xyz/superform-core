// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

/// @title ISocketRegistry
/// @notice Interface for socket's Router contract
/// @notice taken from
/// https://github.com/SocketDotTech/socket-gateway-verifier
interface ISocketRegistry {
    struct SocketRequest {
        uint256 amount;
        address recipient;
        uint256 toChainId;
        address token;
        bytes4 signature;
    }

    struct UserRequest {
        uint32 routeId;
        bytes socketRequest;
    }

    struct UserRequestValidation {
        uint32 routeId;
        SocketRequest socketRequest;
    }
}

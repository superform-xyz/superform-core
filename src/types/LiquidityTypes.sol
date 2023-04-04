// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @dev contains all the common struct used for interchain token transfers.
struct LiqRequest {
    uint8 bridgeId; // socketId: 1 - cross chain bridge / 2 - inch implementation / 3 - 0x implementation
    bytes txData;
    address token; // in deposit this is the token sent by the user / withdraw this is the vault underlying
    address allowanceTarget; /// @dev should check with socket.
    uint256 amount;
    uint256 nativeAmount;
}

struct BridgeRequest {
    uint256 id;
    uint256 optionalNativeAmount;
    address inputToken;
    bytes data;
}

struct MiddlewareRequest {
    uint256 id;
    uint256 optionalNativeAmount;
    address inputToken;
    bytes data;
}

struct UserRequest {
    address receiverAddress;
    uint256 toChainId;
    uint256 amount;
    MiddlewareRequest middlewareRequest;
    BridgeRequest bridgeRequest;
}

struct LiqStruct {
    address inputToken;
    address bridge;
    UserRequest socketInfo;
}

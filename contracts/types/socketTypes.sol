// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.14;

struct LiqRequest {
    uint8 bridgeId;
    bytes txData;
    address token;
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

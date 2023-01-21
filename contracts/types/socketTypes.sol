// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.14;

struct LiqRequest {
    uint8 bridgeId; /// @dev what bridge to use to move tokens
    bytes txData; /// @dev socket generated data
    address token; /// @dev what token to move from src to dst
    bool isERC20; /// @dev changed from allowanceTarget / if native token or not
    uint256 amount; /// @dev in what amount token is bridged
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

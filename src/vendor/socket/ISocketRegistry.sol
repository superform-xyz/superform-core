// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

/// @title ISocketRegistry
/// @notice Interface for socket's Router contract
/// @notice taken from
/// https://github.com/SocketDotTech/socket-v2-verifier-contracts/blob/master/contracts/SocketV2Verifier.sol
interface ISocketRegistry {
    /// @param id route id of middleware to be used
    /// @param optionalNativeAmount is the amount of native asset that the route requires
    /// @param inputToken token address which will be swapped to BridgeRequest inputToken
    /// @param data to be used by middleware
    struct MiddlewareRequest {
        uint256 id;
        uint256 optionalNativeAmount;
        address inputToken;
        bytes data;
    }

    /// @param id route id of bridge to be used
    /// @param optionalNativeAmount optional native amount, to be used when bridge needs native token along with ERC20
    /// @param inputToken token addresss which will be bridged
    /// @param data bridgeData to be used by bridge
    struct BridgeRequest {
        uint256 id;
        uint256 optionalNativeAmount;
        address inputToken;
        bytes data;
    }

    /// @param receiverAddress Recipient address to recieve funds on destination chain
    /// @param toChainId Destination ChainId
    /// @param amount amount to be swapped if middlewareId is 0  it will be
    /// the amount to be bridged
    /// @param middlewareRequest middleware Requestdata
    /// @param bridgeRequest bridge request data
    struct UserRequest {
        address receiverAddress;
        uint256 toChainId;
        uint256 amount;
        MiddlewareRequest middlewareRequest;
        BridgeRequest bridgeRequest;
    }

    function outboundTransferTo(UserRequest calldata _userRequest) external payable;
}

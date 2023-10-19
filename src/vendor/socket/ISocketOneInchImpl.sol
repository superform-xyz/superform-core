// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

/// @title ISocketOneInchImpl
/// @notice Interface for Socket's One Inch Impl
/// @notice used for swaps without bridge
/// @notice taken from https://polygonscan.com/address/0x2ddf16BA6d0180e5357d5e170eF1917a01b41fc0
interface ISocketOneInchImpl {
    struct SwapInput {
        address fromToken;
        address toToken;
        address receiver;
        uint256 amount;
        bytes swapExtraData;
    }

    function performDirectAction(
        address fromToken,
        address toToken,
        address receiver,
        uint256 amount,
        bytes memory swapExtraData
    )
        external
        payable;
}

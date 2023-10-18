// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

interface ISocketOneInchImpl {
    struct SwapInput {
        address fromToken;
        address toToken;
        address receiver;
        uint256 amount;
        bytes swapExtraData;
    }
}

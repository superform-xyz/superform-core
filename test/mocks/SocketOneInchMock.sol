// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";

/// local imports
import "./MockERC20.sol";
import { ISocketOneInchImpl } from "src/vendor/socket/ISocketOneInchImpl.sol";

/// @title Socket OneInch Mock
/// @dev eventually replace this by using a fork of the real registry contract
contract SocketOneInchMock is ISocketOneInchImpl, Test {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    receive() external payable { }

    function performDirectAction(
        address fromToken,
        address toToken,
        address receiver,
        uint256 amount,
        bytes memory swapExtraData
    )
        external
        payable
    {
        (address from) = abi.decode(swapExtraData, (address));

        if (fromToken != NATIVE) {
            MockERC20(fromToken).transferFrom(from, address(this), amount);
        } else {
            require(msg.value == amount);
        }

        /// FIXME: account for slippage
        deal(toToken, receiver, MockERC20(toToken).balanceOf(receiver) + amount);
    }
}

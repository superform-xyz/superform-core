// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

/// local imports
import "./MockERC20.sol";
import { ISocketOneInchImpl } from "src/vendor/socket/ISocketOneInchImpl.sol";

import "forge-std/console.sol";
/// @title Socket OneInch Mock
/// @dev eventually replace this by using a fork of the real registry contract

contract SocketOneInchMock is ISocketOneInchImpl, Test {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    receive() external payable { }

    struct SwapLocalVars {
        uint256 decimal1;
        uint256 decimal2;
        uint256 finalAmount;
        address from;
        uint256 USDPerUnderlyingToken;
        uint256 USDPerUnderlyingTokenDst;
    }

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
        SwapLocalVars memory vars;
        (vars.from, vars.USDPerUnderlyingToken, vars.USDPerUnderlyingTokenDst) =
            abi.decode(swapExtraData, (address, uint256, uint256));

        if (fromToken != NATIVE) {
            MockERC20(fromToken).transferFrom(vars.from, address(this), amount);
        } else {
            require(msg.value == amount);
        }

        vars.decimal1 = fromToken == NATIVE ? 18 : MockERC20(fromToken).decimals();
        vars.decimal2 = toToken == NATIVE ? 18 : MockERC20(toToken).decimals();

        if (vars.decimal1 > vars.decimal2) {
            vars.finalAmount = (amount * vars.USDPerUnderlyingToken)
                / (10 ** (vars.decimal1 - vars.decimal2) * vars.USDPerUnderlyingTokenDst);
        } else {
            vars.finalAmount = ((amount * vars.USDPerUnderlyingToken) * 10 ** (vars.decimal2 - vars.decimal1))
                / vars.USDPerUnderlyingTokenDst;
        }

        console.log("finalAmount", vars.finalAmount);

        deal(toToken, receiver, MockERC20(toToken).balanceOf(receiver) + vars.finalAmount);
    }
}

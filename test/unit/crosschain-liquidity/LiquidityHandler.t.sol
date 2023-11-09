// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import { LiquidityHandler } from "src/crosschain-liquidity/LiquidityHandler.sol";
import { Error } from "src/utils/Error.sol";
import "test/utils/ProtocolActions.sol";

contract LiquidityHandlerUser is LiquidityHandler {
    function dispatchTokensTest(
        address bridge_,
        bytes memory txData_,
        address token_,
        uint256 amount_,
        uint256 nativeAmount_
    )
        external
        payable
    {
        _dispatchTokens(bridge_, txData_, token_, amount_, nativeAmount_);
    }
}

contract LiquidityHandlerTest is ProtocolActions {
    LiquidityHandlerUser public liquidityHandler;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        liquidityHandler = new LiquidityHandlerUser();
    }

    function test_dispatchTokensAlreadyInContract() public {
        uint256 transferAmount = 1e18;
        /// 1 token
        address payable token = payable(getContract(ETH, "DAI"));
        address tokenDst = getContract(ARBI, "DAI");

        vm.startPrank(deployer);
        MockERC20(token).transfer(address(liquidityHandler), transferAmount);

        liquidityHandler.dispatchTokensTest(
            SuperRegistry(getContract(ETH, "SuperRegistry")).getBridgeAddress(1),
            _buildDummyTxDataUnitTests(
                BuildDummyTxDataUnitTestsVars(
                    1,
                    address(token),
                    tokenDst,
                    address(liquidityHandler),
                    ETH,
                    ARBI,
                    transferAmount,
                    address(liquidityHandler),
                    false
                )
            ),
            token,
            transferAmount,
            0
        );
        vm.stopPrank();
    }

    function test_dispatchTokensUsingFailingTxData() public {
        uint256 transferAmount = 1e18; // 1 token
        address payable token = payable(getContract(ETH, "DAI"));
        address tokenDst = getContract(ARBI, "DAI");

        address bridgeAddress = address(new LiquidityHandlerUser());

        vm.prank(deployer);
        MockERC20(token).approve(address(liquidityHandler), transferAmount);

        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1,
                address(token),
                tokenDst,
                address(liquidityHandler),
                ETH,
                ARBI,
                transferAmount,
                address(liquidityHandler),
                false
            )
        );
        vm.prank(deployer);

        vm.expectRevert(abi.encodeWithSelector(Error.FAILED_TO_EXECUTE_TXDATA.selector, token));
        liquidityHandler.dispatchTokensTest(bridgeAddress, txData, token, transferAmount, 0);
    }

    function test_dispatchNativeTokensWithInsufficientNativeAmount() public {
        uint256 transferAmount = 1e18; // 1 token
        address token = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        address bridgeAddress = SuperRegistry(getContract(ETH, "SuperRegistry")).getBridgeAddress(1);

        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1, token, token, address(liquidityHandler), ETH, ARBI, transferAmount, address(liquidityHandler), false
            )
        );
        vm.prank(deployer);

        vm.expectRevert(Error.INSUFFICIENT_NATIVE_AMOUNT.selector);
        liquidityHandler.dispatchTokensTest(bridgeAddress, txData, token, transferAmount, 0);
    }

    function test_dispatchNativeTokensWithInvalidTxData() public {
        uint256 transferAmount = 1e18; // 1 token
        address token = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        address bridgeAddress = address(new LiquidityHandlerUser());
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1, token, token, address(liquidityHandler), ETH, ARBI, transferAmount, address(liquidityHandler), false
            )
        );
        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSelector(Error.FAILED_TO_EXECUTE_TXDATA.selector, token));
        liquidityHandler.dispatchTokensTest{ value: 1e18 }(bridgeAddress, txData, token, transferAmount, transferAmount);
    }

    function test_bridgeAddress0() public {
        uint256 transferAmount = 1e18; // 1 token
        address token = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1, token, token, address(liquidityHandler), ETH, ARBI, transferAmount, address(liquidityHandler), false
            )
        );
        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        liquidityHandler.dispatchTokensTest{ value: 1e18 }(address(0), txData, token, transferAmount, transferAmount);
    }
}

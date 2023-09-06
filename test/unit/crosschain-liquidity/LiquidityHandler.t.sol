// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { LiquidityHandler } from "src/crosschain-liquidity/LiquidityHandler.sol";
import { Error } from "src/utils/Error.sol";
import "test/utils/ProtocolActions.sol";

contract LiquidityHandlerUser is LiquidityHandler {
    function dispatchTokensTest(
        address bridge_,
        bytes memory txData_,
        address token_,
        uint256 amount_,
        address owner_,
        uint256 nativeAmount_,
        bytes memory permit2Data_,
        address permit2_
    )
        external
        payable
    {
        dispatchTokens(bridge_, txData_, token_, amount_, owner_, nativeAmount_, permit2Data_, permit2_);
    }
}

contract LiquidityHandlerTest is BaseSetup {
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
            _buildTxData(
                1, address(token), tokenDst, address(liquidityHandler), ARBI, transferAmount, address(liquidityHandler)
            ),
            token,
            transferAmount,
            address(liquidityHandler),
            0,
            bytes(""),
            address(0)
        );
        vm.stopPrank();
    }

    function test_dispatchTokensUsingApprovals() public {
        uint256 transferAmount = 1e18;
        /// 1 token
        address payable token = payable(getContract(ETH, "DAI"));
        address tokenDst = getContract(ARBI, "DAI");

        /// @dev giving approval
        vm.prank(deployer);
        MockERC20(token).approve(address(liquidityHandler), transferAmount);

        vm.prank(deployer);
        liquidityHandler.dispatchTokensTest(
            SuperRegistry(getContract(ETH, "SuperRegistry")).getBridgeAddress(1),
            _buildTxData(
                1, address(token), tokenDst, address(liquidityHandler), ARBI, transferAmount, address(liquidityHandler)
            ),
            token,
            transferAmount,
            deployer,
            0,
            bytes(""),
            address(0)
        );
    }

    function test_dispatchTokensWithPermit2() public {
        uint256 transferAmount = 1e18;
        /// 1 token
        address payable token = payable(getContract(ETH, "USDT"));
        address tokenDst = getContract(ARBI, "DAI");

        /// @dev giving approval
        IPermit2.PermitTransferFrom memory permit = IPermit2.PermitTransferFrom({
            permitted: IPermit2.TokenPermissions({ token: IERC20(token), amount: transferAmount }),
            nonce: _randomUint256(),
            deadline: block.timestamp
        });

        bytes memory sig = _signPermit(permit, address(liquidityHandler), 777, ETH);
        bytes memory permit2Calldata = abi.encode(permit.nonce, permit.deadline, sig);

        address permit2 = SuperRegistry(getContract(ETH, "SuperRegistry")).PERMIT2();

        vm.prank(deployer);
        MockERC20(token).approve(getContract(ETH, "CanonicalPermit2"), type(uint256).max);

        vm.prank(deployer);
        liquidityHandler.dispatchTokensTest(
            SuperRegistry(getContract(ETH, "SuperRegistry")).getBridgeAddress(1),
            _buildTxData(
                1, address(token), tokenDst, address(liquidityHandler), ARBI, transferAmount, address(liquidityHandler)
            ),
            address(token),
            transferAmount,
            deployer,
            0,
            permit2Calldata,
            permit2
        );
    }

    function test_dispatchTokensUsingFailingTxData() public {
        uint256 transferAmount = 1e18; // 1 token
        address payable token = payable(getContract(ETH, "DAI"));
        address tokenDst = getContract(ARBI, "DAI");

        address bridgeAddress = address(new LiquidityHandlerUser());

        vm.prank(deployer);
        MockERC20(token).approve(address(liquidityHandler), transferAmount);

        vm.prank(deployer);
        vm.expectRevert(Error.FAILED_TO_EXECUTE_TXDATA.selector);
        liquidityHandler.dispatchTokensTest(
            bridgeAddress,
            _buildTxData(
                1, address(token), tokenDst, address(liquidityHandler), ARBI, transferAmount, address(liquidityHandler)
            ),
            token,
            transferAmount,
            deployer,
            0,
            bytes(""),
            address(0)
        );
    }

    function test_dispatchNativeTokensWithInsufficientNativeAmount() public {
        uint256 transferAmount = 1e18; // 1 token
        address token = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        address bridgeAddress = SuperRegistry(getContract(ETH, "SuperRegistry")).getBridgeAddress(1);

        vm.prank(deployer);
        vm.expectRevert(Error.INSUFFICIENT_NATIVE_AMOUNT.selector);
        liquidityHandler.dispatchTokensTest(
            bridgeAddress,
            _buildTxData(1, token, token, address(liquidityHandler), ARBI, transferAmount, address(liquidityHandler)),
            token,
            transferAmount,
            deployer,
            0,
            bytes(""),
            address(0)
        );
    }

    function test_dispatchNativeTokensWithInvalidTxData() public {
        uint256 transferAmount = 1e18; // 1 token
        address token = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        address bridgeAddress = address(new LiquidityHandlerUser());

        vm.prank(deployer);
        vm.expectRevert(Error.FAILED_TO_EXECUTE_TXDATA_NATIVE.selector);
        liquidityHandler.dispatchTokensTest{ value: 1e18 }(
            bridgeAddress,
            _buildTxData(1, token, token, address(liquidityHandler), ARBI, transferAmount, address(liquidityHandler)),
            token,
            transferAmount,
            deployer,
            transferAmount,
            bytes(""),
            address(0)
        );
    }

    function _buildTxData(
        uint8 liqBridgeKind_,
        address underlyingToken_,
        address underlyingTokenDst_,
        address from_,
        uint64 toChainId_,
        uint256 amount_,
        address receiver_
    )
        internal
        returns (bytes memory txData)
    {
        if (liqBridgeKind_ == 1) {
            ILiFi.BridgeData memory bridgeData;
            ILiFi.SwapData[] memory swapData = new ILiFi.SwapData[](1);

            swapData[0] = ILiFi.SwapData(
                address(0),
                /// callTo (arbitrary)
                address(0),
                /// callTo (approveTo)
                underlyingToken_,
                underlyingToken_,
                amount_,
                /// @dev arbitrary totalSlippage (200)
                abi.encode(from_, FORKS[toChainId_], underlyingTokenDst_, 200, false),
                false // arbitrary
            );

            bridgeData = ILiFi.BridgeData(
                bytes32("1"),
                /// request id
                "",
                "",
                address(0),
                underlyingToken_,
                receiver_,
                amount_,
                uint256(toChainId_),
                false,
                true
            );

            txData = abi.encodeWithSelector(LiFiMock.swapAndStartBridgeTokensViaBridge.selector, bridgeData, swapData);
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {Error} from "../../utils/Error.sol";
import "../utils/ProtocolActions.sol";

contract KeeperMock {
    receive() external payable {}
}

contract KeeperMockThatWontAcceptEth {
    receive() external payable {
        revert();
    }
}

contract FeeCollectorTest is BaseSetup {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address multiTxProcessor;
    address txProcessor;
    address txUpdater;

    address multiTxProcessorFraud;

    function setUp() public override {
        super.setUp();

        for (uint256 i; i < chainIds.length; i++) {
            vm.selectFork(FORKS[chainIds[i]]);
            multiTxProcessor = address(new KeeperMock());
            multiTxProcessorFraud = address(new KeeperMockThatWontAcceptEth());

            txProcessor = address(new KeeperMock());
            txUpdater = address(new KeeperMock());
        }
    }

    function test_validationsInMakePayment() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// @dev make zero payment
        vm.expectRevert(Error.ZERO_MSG_VALUE.selector);
        FeeCollector(getContract(ETH, "FeeCollector")).makePayment(deployer);

        /// @dev try to make payment for zero address
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        FeeCollector(getContract(ETH, "FeeCollector")).makePayment{value: 1 wei}(address(0));
    }

    function test_withdrawNativeToMultiTxProcessorFraud() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address feeCollector = getContract(ETH, "FeeCollector");

        /// @dev makes payment of 1 wei
        FeeCollector(feeCollector).makePayment{value: 1 wei}(deployer);
        assertEq(feeCollector.balance, 1 wei);

        SuperRegistry(getContract(ETH, "SuperRegistry")).setMultiTxProcessor(multiTxProcessorFraud);

        /// @dev admin tries withdraw more than balance (check if handled gracefully)
        vm.expectRevert(Error.FAILED_WITHDRAW.selector);
        FeeCollector(feeCollector).withdrawToMultiTxProcessor(1 wei);
    }

    function test_withdrawNativeToMultiTxProcessor() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address feeCollector = getContract(ETH, "FeeCollector");

        /// @dev makes payment of 1 wei
        FeeCollector(feeCollector).makePayment{value: 1 wei}(deployer);
        assertEq(feeCollector.balance, 1 wei);

        /// @dev admin tries withdraw more than balance (check if handled gracefully)
        vm.expectRevert(Error.INSUFFICIENT_NATIVE_AMOUNT.selector);
        FeeCollector(feeCollector).withdrawToMultiTxProcessor(2 wei);

        /// @dev admin tries withdraw if processor address is zero (check if handled gracefully)
        SuperRegistry(getContract(ETH, "SuperRegistry")).setMultiTxProcessor(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        FeeCollector(feeCollector).withdrawToMultiTxProcessor(1 wei);

        SuperRegistry(getContract(ETH, "SuperRegistry")).setMultiTxProcessor(multiTxProcessor);

        /// @dev admin moves the payment from fee collector to multi tx processor
        FeeCollector(feeCollector).withdrawToMultiTxProcessor(1 wei);
        assertEq(feeCollector.balance, 0);
        assertEq(multiTxProcessor.balance, 1 wei);
    }

    function test_withdrawNativeToTxProcessor() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address feeCollector = getContract(ETH, "FeeCollector");

        /// @dev makes payment of 1 wei
        FeeCollector(feeCollector).makePayment{value: 1 wei}(deployer);
        assertEq(feeCollector.balance, 1 wei);

        /// @dev admin tries withdraw more than balance (check if handled gracefully)
        vm.expectRevert(Error.INSUFFICIENT_NATIVE_AMOUNT.selector);
        FeeCollector(feeCollector).withdrawToTxProcessor(2 wei);

        /// @dev admin tries withdraw if processor address is zero (check if handled gracefully)
        SuperRegistry(getContract(ETH, "SuperRegistry")).setTxProcessor(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        FeeCollector(feeCollector).withdrawToTxProcessor(1 wei);

        SuperRegistry(getContract(ETH, "SuperRegistry")).setTxProcessor(txProcessor);

        /// @dev admin moves the payment from fee collector to tx processor
        FeeCollector(feeCollector).withdrawToTxProcessor(1 wei);
        assertEq(feeCollector.balance, 0);
        assertEq(txProcessor.balance, 1 wei);
    }

    function test_withdrawNativeToTxUpdater() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address feeCollector = getContract(ETH, "FeeCollector");

        /// @dev makes payment of 1 wei
        FeeCollector(feeCollector).makePayment{value: 1 wei}(deployer);
        assertEq(feeCollector.balance, 1 wei);

        /// @dev admin tries withdraw more than balance (check if handled gracefully)
        vm.expectRevert(Error.INSUFFICIENT_NATIVE_AMOUNT.selector);
        FeeCollector(feeCollector).withdrawToTxUpdater(2 wei);

        /// @dev admin tries withdraw if updater address is zero (check if handled gracefully)
        SuperRegistry(getContract(ETH, "SuperRegistry")).setTxUpdater(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        FeeCollector(feeCollector).withdrawToTxUpdater(1 wei);

        SuperRegistry(getContract(ETH, "SuperRegistry")).setTxUpdater(txUpdater);

        /// @dev admin moves the payment from fee collector to tx updater
        FeeCollector(feeCollector).withdrawToTxUpdater(1 wei);
        assertEq(feeCollector.balance, 0);
        assertEq(txUpdater.balance, 1 wei);
    }

    function test_rebalanceToMultiTxProcessor() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address feeCollector = getContract(ETH, "FeeCollector");

        /// @dev makes payment of 1 ether
        FeeCollector(feeCollector).makePayment{value: 1 ether}(deployer);
        assertEq(feeCollector.balance, 1 ether);

        /// @dev admin tries withdraw if processor address is zero (check if handled gracefully)
        SuperRegistry(getContract(ETH, "SuperRegistry")).setMultiTxProcessor(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        FeeCollector(feeCollector).rebalanceToMultiTxProcessor(
            LiqRequest(
                1,
                _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, feeCollector),
                NATIVE,
                1 ether,
                1 ether,
                ""
            )
        );

        SuperRegistry(getContract(ETH, "SuperRegistry")).setMultiTxProcessor(multiTxProcessor);

        /// @dev admin moves the payment from fee collector to different address on another chain
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        FeeCollector(feeCollector).rebalanceToMultiTxProcessor(
            LiqRequest(
                1,
                _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, feeCollector),
                NATIVE,
                1 ether,
                1 ether,
                ""
            )
        );

        /// @dev admin moves the payment from fee collector (ideal conditions)
        FeeCollector(feeCollector).rebalanceToMultiTxProcessor(
            LiqRequest(
                1,
                _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, multiTxProcessor),
                NATIVE,
                1 ether,
                1 ether,
                ""
            )
        );

        assertEq(feeCollector.balance, 0);

        vm.selectFork(FORKS[ARBI]);
        assertEq(multiTxProcessor.balance, 1 ether);
    }

    function test_rebalanceToTxProcessor() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address feeCollector = getContract(ETH, "FeeCollector");

        /// @dev makes payment of 1 ether
        FeeCollector(feeCollector).makePayment{value: 1 ether}(deployer);
        assertEq(feeCollector.balance, 1 ether);

        /// @dev admin tries withdraw if processor address is zero (check if handled gracefully)
        SuperRegistry(getContract(ETH, "SuperRegistry")).setTxProcessor(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        FeeCollector(feeCollector).rebalanceToTxProcessor(
            LiqRequest(
                1,
                _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, feeCollector),
                NATIVE,
                1 ether,
                1 ether,
                ""
            )
        );

        SuperRegistry(getContract(ETH, "SuperRegistry")).setTxProcessor(txProcessor);

        /// @dev admin moves the payment from fee collector to different address on another chain
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        FeeCollector(feeCollector).rebalanceToTxProcessor(
            LiqRequest(
                1,
                _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, feeCollector),
                NATIVE,
                1 ether,
                1 ether,
                ""
            )
        );

        /// @dev admin moves the payment from fee collector (ideal conditions)
        FeeCollector(feeCollector).rebalanceToTxProcessor(
            LiqRequest(
                1,
                _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, txProcessor),
                NATIVE,
                1 ether,
                1 ether,
                ""
            )
        );

        assertEq(feeCollector.balance, 0);

        vm.selectFork(FORKS[ARBI]);
        assertEq(txProcessor.balance, 1 ether);
    }

    function test_rebalanceToTxUpdater() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address feeCollector = getContract(ETH, "FeeCollector");

        /// @dev makes payment of 1 ether
        FeeCollector(feeCollector).makePayment{value: 1 ether}(deployer);
        assertEq(feeCollector.balance, 1 ether);

        /// @dev admin tries withdraw if processor address is zero (check if handled gracefully)
        SuperRegistry(getContract(ETH, "SuperRegistry")).setTxUpdater(address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        FeeCollector(feeCollector).rebalanceToTxUpdater(
            LiqRequest(
                1,
                _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, feeCollector),
                NATIVE,
                1 ether,
                1 ether,
                ""
            )
        );

        SuperRegistry(getContract(ETH, "SuperRegistry")).setTxUpdater(txUpdater);

        /// @dev admin moves the payment from fee collector to different address on another chain
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        FeeCollector(feeCollector).rebalanceToTxUpdater(
            LiqRequest(
                1,
                _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, feeCollector),
                NATIVE,
                1 ether,
                1 ether,
                ""
            )
        );

        /// @dev admin moves the payment from fee collector (ideal conditions)
        FeeCollector(feeCollector).rebalanceToTxUpdater(
            LiqRequest(1, _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, txUpdater), NATIVE, 1 ether, 1 ether, "")
        );

        assertEq(feeCollector.balance, 0);

        vm.selectFork(FORKS[ARBI]);
        assertEq(txUpdater.balance, 1 ether);
    }

    function _buildTxData(
        uint8 liqBridgeKind_,
        address underlyingToken_,
        address from_,
        uint64 toChainId_,
        uint256 amount_,
        address receiver_
    ) internal returns (bytes memory txData) {
        if (liqBridgeKind_ == 1) {
            ISocketRegistry.BridgeRequest memory bridgeRequest;
            ISocketRegistry.MiddlewareRequest memory middlewareRequest;
            ISocketRegistry.UserRequest memory userRequest;
            /// @dev middlware request is used if there is a swap involved before the bridging action
            /// @dev the input token should be the token the user deposits, which will be swapped to the input token of bridging request
            middlewareRequest = ISocketRegistry.MiddlewareRequest(
                1, /// request id
                0,
                underlyingToken_,
                abi.encode(from_, FORKS[toChainId_])
            );

            /// @dev empty bridge request
            bridgeRequest = ISocketRegistry.BridgeRequest(
                0, /// id
                0,
                address(0),
                abi.encode(receiver_, FORKS[toChainId_])
            );

            userRequest = ISocketRegistry.UserRequest(
                receiver_,
                uint256(toChainId_),
                amount_,
                middlewareRequest,
                bridgeRequest
            );

            txData = abi.encodeWithSelector(SocketRouterMock.outboundTransferTo.selector, userRequest);
        } else if (liqBridgeKind_ == 2) {
            ILiFi.BridgeData memory bridgeData;
            ILiFi.SwapData[] memory swapData = new ILiFi.SwapData[](1);

            swapData[0] = ILiFi.SwapData(
                address(0), /// callTo (arbitrary)
                address(0), /// callTo (approveTo)
                underlyingToken_,
                underlyingToken_,
                amount_,
                abi.encode(from_, FORKS[toChainId_]),
                false // arbitrary
            );

            bridgeData = ILiFi.BridgeData(
                bytes32("1"), /// request id
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

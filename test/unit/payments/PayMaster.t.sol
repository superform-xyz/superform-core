// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { Error } from "src/utils/Error.sol";
import "test/utils/ProtocolActions.sol";

contract KeeperMock {
    receive() external payable { }
}

contract KeeperMockThatWontAcceptEth {
    receive() external payable {
        revert();
    }
}

contract PayMasterTest is BaseSetup {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address multiTxSwapperETH;
    address txProcessorETH;
    address txUpdaterETH;
    address multiTxSwapperARBI;
    address txProcessorARBI;
    address txUpdaterARBI;

    address multiTxProcessorFraud;

    /// out of 10000
    int256 totalSlippage = 200;

    SuperRegistry superRegistry;
    SuperRegistry superRegistryARBI;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        multiTxSwapperETH = address(new KeeperMock());
        multiTxProcessorFraud = address(new KeeperMockThatWontAcceptEth());

        txProcessorETH = address(new KeeperMock());
        txUpdaterETH = address(new KeeperMock());

        superRegistry = SuperRegistry(getContract(ETH, "SuperRegistry"));

        vm.selectFork(FORKS[ARBI]);
        multiTxSwapperARBI = address(new KeeperMock());
        txProcessorARBI = address(new KeeperMock());
        txUpdaterARBI = address(new KeeperMock());

        vm.selectFork(FORKS[ETH]);

        /// @dev setting these here as overrides just to test with receive function
        vm.startPrank(deployer);
        superRegistry.setAddress(keccak256("MULTI_TX_SWAPPER"), multiTxSwapperARBI, ARBI);
        superRegistry.setAddress(keccak256("CORE_REGISTRY_PROCESSOR"), txProcessorARBI, ARBI);
        superRegistry.setAddress(keccak256("CORE_REGISTRY_UPDATER"), txUpdaterARBI, ARBI);
        vm.stopPrank();
    }

    function test_manipuationsBySendingFeesIntoRouter() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// @dev at this point the contract has 1 ether extra
        address superformRouter = getContract(ETH, "SuperformRouter");
        payable(superformRouter).transfer(1 ether);

        /// @dev make a deposit and send in 2 ether extra for other off-chain operations
        _successfulDeposit();
        assertEq(address(superformRouter).balance, 1 ether);
        assertEq(getContract(ETH, "PayMaster").balance, 2 ether);
    }

    function test_validationsInMakePayment() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// @dev make zero payment
        vm.expectRevert(Error.ZERO_MSG_VALUE.selector);
        PayMaster(getContract(ETH, "PayMaster")).makePayment(deployer);

        /// @dev try to make payment for zero address
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        PayMaster(getContract(ETH, "PayMaster")).makePayment{ value: 1 wei }(address(0));
    }

    function test_withdrawNativeToMultiTxProcessorFraud() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address feeCollector = getContract(ETH, "PayMaster");

        /// @dev makes payment of 1 wei
        PayMaster(feeCollector).makePayment{ value: 1 wei }(deployer);
        assertEq(feeCollector.balance, 1 wei);

        superRegistry.setAddress(keccak256("MULTI_TX_SWAPPER"), multiTxProcessorFraud, ETH);

        /// @dev admin tries withdraw more than balance (check if handled gracefully)
        vm.expectRevert(Error.FAILED_WITHDRAW.selector);
        PayMaster(feeCollector).withdrawTo(keccak256("MULTI_TX_SWAPPER"), 1 wei);
    }

    function test_withdrawNativeToMultiTxProcessor() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address feeCollector = getContract(ETH, "PayMaster");

        /// @dev makes payment of 1 wei
        PayMaster(feeCollector).makePayment{ value: 1 wei }(deployer);
        assertEq(feeCollector.balance, 1 wei);

        /// @dev admin tries withdraw more than balance (check if handled gracefully)
        vm.expectRevert(Error.INSUFFICIENT_NATIVE_AMOUNT.selector);
        PayMaster(feeCollector).withdrawTo(keccak256("MULTI_TX_SWAPPER"), 2 wei);

        /// @dev admin tries withdraw if processor address is zero (check if handled gracefully)
        superRegistry.setAddress(keccak256("MULTI_TX_SWAPPER"), address(0), ETH);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        PayMaster(feeCollector).withdrawTo(keccak256("MULTI_TX_SWAPPER"), 1 wei);

        superRegistry.setAddress(keccak256("MULTI_TX_SWAPPER"), multiTxSwapperETH, ETH);

        /// @dev admin moves the payment from fee collector to multi tx processor
        PayMaster(feeCollector).withdrawTo(keccak256("MULTI_TX_SWAPPER"), 1 wei);
        assertEq(feeCollector.balance, 0);
        assertEq(multiTxSwapperETH.balance, 1 wei);
    }

    function test_withdrawNativeToTxProcessor() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address feeCollector = getContract(ETH, "PayMaster");

        /// @dev makes payment of 1 wei
        PayMaster(feeCollector).makePayment{ value: 1 wei }(deployer);
        assertEq(feeCollector.balance, 1 wei);

        /// @dev admin tries withdraw more than balance (check if handled gracefully)
        vm.expectRevert(Error.INSUFFICIENT_NATIVE_AMOUNT.selector);
        PayMaster(feeCollector).withdrawTo(keccak256("CORE_REGISTRY_PROCESSOR"), 2 wei);

        /// @dev admin tries withdraw if processor address is zero (check if handled gracefully)
        superRegistry.setAddress(keccak256("CORE_REGISTRY_PROCESSOR"), address(0), ETH);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        PayMaster(feeCollector).withdrawTo(keccak256("CORE_REGISTRY_PROCESSOR"), 1 wei);

        superRegistry.setAddress(keccak256("CORE_REGISTRY_PROCESSOR"), txProcessorETH, ETH);

        /// @dev admin moves the payment from fee collector to tx processor
        PayMaster(feeCollector).withdrawTo(keccak256("CORE_REGISTRY_PROCESSOR"), 1 wei);
        assertEq(feeCollector.balance, 0);
        assertEq(txProcessorETH.balance, 1 wei);
    }

    function test_withdrawNativeToTxUpdater() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address feeCollector = getContract(ETH, "PayMaster");

        /// @dev makes payment of 1 wei
        PayMaster(feeCollector).makePayment{ value: 1 wei }(deployer);
        assertEq(feeCollector.balance, 1 wei);

        /// @dev admin tries withdraw more than balance (check if handled gracefully)
        vm.expectRevert(Error.INSUFFICIENT_NATIVE_AMOUNT.selector);
        PayMaster(feeCollector).withdrawTo(keccak256("CORE_REGISTRY_UPDATER"), 2 wei);

        /// @dev admin tries withdraw if updater address is zero (check if handled gracefully)
        superRegistry.setAddress(keccak256("CORE_REGISTRY_UPDATER"), address(0), ETH);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        PayMaster(feeCollector).withdrawTo(keccak256("CORE_REGISTRY_UPDATER"), 1 wei);

        superRegistry.setAddress(keccak256("CORE_REGISTRY_UPDATER"), txUpdaterETH, ETH);

        /// @dev admin moves the payment from fee collector to tx updater
        PayMaster(feeCollector).withdrawTo(keccak256("CORE_REGISTRY_UPDATER"), 1 wei);
        assertEq(feeCollector.balance, 0);
        assertEq(txUpdaterETH.balance, 1 wei);
    }

    function test_rebalanceToMultiTxSwapper() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address feeCollector = getContract(ETH, "PayMaster");
        address feeCollectorDst = getContract(ARBI, "PayMaster");

        /// @dev makes payment of 1 ether
        PayMaster(feeCollector).makePayment{ value: 1 ether }(deployer);
        assertEq(feeCollector.balance, 1 ether);

        /// @dev admin tries withdraw if processor address is zero (check if handled gracefully)
        superRegistry.setAddress(keccak256("MULTI_TX_SWAPPER"), address(0), ETH);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        PayMaster(feeCollector).rebalanceTo(
            keccak256("MULTI_TX_SWAPPER"),
            LiqRequest(
                1, _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, feeCollectorDst), NATIVE, 1 ether, 1 ether, ""
            ),
            420
        );

        superRegistry.setAddress(keccak256("MULTI_TX_SWAPPER"), multiTxSwapperETH, ETH);

        /// @dev admin moves the payment from fee collector to different address on another chain
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        PayMaster(feeCollector).rebalanceTo(
            keccak256("MULTI_TX_SWAPPER"),
            LiqRequest(
                1, _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, feeCollectorDst), NATIVE, 1 ether, 1 ether, ""
            ),
            ARBI
        );

        /// @dev admin moves the payment from fee collector (ideal conditions)
        PayMaster(feeCollector).rebalanceTo(
            keccak256("MULTI_TX_SWAPPER"),
            LiqRequest(
                1,
                _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, multiTxSwapperARBI),
                NATIVE,
                1 ether,
                1 ether,
                ""
            ),
            ARBI
        );

        assertEq(feeCollector.balance, 0);

        vm.selectFork(FORKS[ARBI]);
        /// @dev amount received will be bridge-slippage-adjusted
        assertEq(multiTxSwapperARBI.balance, (1 ether * (10_000 - uint256(totalSlippage))) / 10_000);
    }

    function test_rebalanceToCoreStateRegistryTxProcessor() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address feeCollector = getContract(ETH, "PayMaster");
        address feeCollectorDst = getContract(ARBI, "PayMaster");

        /// @dev makes payment of 1 ether
        PayMaster(feeCollector).makePayment{ value: 1 ether }(deployer);
        assertEq(feeCollector.balance, 1 ether);

        /// @dev admin tries withdraw if processor address is zero (check if handled gracefully)
        superRegistry.setAddress(keccak256("CORE_REGISTRY_PROCESSOR"), address(0), ETH);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        PayMaster(feeCollector).rebalanceTo(
            keccak256("CORE_REGISTRY_PROCESSOR"),
            LiqRequest(
                1, _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, feeCollectorDst), NATIVE, 1 ether, 1 ether, ""
            ),
            420
        );

        superRegistry.setAddress(keccak256("CORE_REGISTRY_PROCESSOR"), txProcessorETH, ETH);

        /// @dev admin moves the payment from fee collector to different address on another chain
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        PayMaster(feeCollector).rebalanceTo(
            keccak256("CORE_REGISTRY_PROCESSOR"),
            LiqRequest(
                1, _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, feeCollectorDst), NATIVE, 1 ether, 1 ether, ""
            ),
            ARBI
        );

        /// @dev admin moves the payment from fee collector (ideal conditions)
        PayMaster(feeCollector).rebalanceTo(
            keccak256("CORE_REGISTRY_PROCESSOR"),
            LiqRequest(
                1, _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, txProcessorARBI), NATIVE, 1 ether, 1 ether, ""
            ),
            ARBI
        );

        assertEq(feeCollector.balance, 0);

        vm.selectFork(FORKS[ARBI]);
        /// @dev amount received will be bridge-slippage-adjusted
        assertEq(txProcessorARBI.balance, (1 ether * (10_000 - uint256(totalSlippage))) / 10_000);
    }

    function test_rebalanceToCoreStateRegistryTxUpdater() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address feeCollector = getContract(ETH, "PayMaster");
        address feeCollectorDst = getContract(ARBI, "PayMaster");

        /// @dev makes payment of 1 ether
        PayMaster(feeCollector).makePayment{ value: 1 ether }(deployer);
        assertEq(feeCollector.balance, 1 ether);

        /// @dev admin tries withdraw if processor address is zero (check if handled gracefully)
        superRegistry.setAddress(keccak256("CORE_REGISTRY_UPDATER"), address(0), ETH);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        PayMaster(feeCollector).rebalanceTo(
            keccak256("CORE_REGISTRY_UPDATER"),
            LiqRequest(
                1, _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, feeCollectorDst), NATIVE, 1 ether, 1 ether, ""
            ),
            420
        );

        superRegistry.setAddress(keccak256("CORE_REGISTRY_UPDATER"), txUpdaterARBI, ETH);

        /// @dev admin moves the payment from fee collector to different address on another chain
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        PayMaster(feeCollector).rebalanceTo(
            keccak256("CORE_REGISTRY_UPDATER"),
            LiqRequest(
                1, _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, feeCollectorDst), NATIVE, 1 ether, 1 ether, ""
            ),
            ARBI
        );

        /// @dev admin moves the payment from fee collector (ideal conditions)
        PayMaster(feeCollector).rebalanceTo(
            keccak256("CORE_REGISTRY_UPDATER"),
            LiqRequest(
                1, _buildTxData(1, NATIVE, feeCollector, ARBI, 1 ether, txUpdaterARBI), NATIVE, 1 ether, 1 ether, ""
            ),
            ARBI
        );

        assertEq(feeCollector.balance, 0);

        vm.selectFork(FORKS[ARBI]);
        /// @dev amount received will be bridge-slippage-adjusted
        assertEq(txUpdaterARBI.balance, (1 ether * (10_000 - uint256(totalSlippage))) / 10_000);
    }

    function _successfulDeposit() internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform =
            getContract(ETH, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ETH);

        SingleVaultSFData memory data =
            SingleVaultSFData(superformId, 1e18, 100, LiqRequest(1, "", getContract(ETH, "USDT"), 1e18, 0, ""), "");

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        (address formBeacon,,) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);

        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(formBeacon, 1e18);
        (,,, uint256 msgFees) =
            PaymentHelper(getContract(ETH, "PaymentHelper")).estimateSingleDirectSingleVault(req, true);
        msgFees = msgFees + 2 ether;

        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit{ value: msgFees }(
            req
        );
    }

    function _buildTxData(
        uint8 liqBridgeKind_,
        address underlyingToken_,
        address from_,
        uint64 toChainId_,
        uint256 amount_,
        address receiver_
    )
        internal
        returns (bytes memory txData)
    {
        if (liqBridgeKind_ == 1) {
            ISocketRegistry.BridgeRequest memory bridgeRequest;
            ISocketRegistry.MiddlewareRequest memory middlewareRequest;
            ISocketRegistry.UserRequest memory userRequest;
            /// @dev middlware request is used if there is a swap involved before the bridging action
            /// @dev the input token should be the token the user deposits, which will be swapped to the input token of
            /// bridging request
            middlewareRequest = ISocketRegistry.MiddlewareRequest(
                1,
                /// request id
                0,
                underlyingToken_,
                abi.encode(from_, FORKS[toChainId_], underlyingToken_, totalSlippage, false, 0, false)
            );

            /// @dev empty bridge request
            bridgeRequest = ISocketRegistry.BridgeRequest(
                0,
                /// id
                0,
                address(0),
                abi.encode(receiver_, FORKS[toChainId_], underlyingToken_)
            );

            userRequest =
                ISocketRegistry.UserRequest(receiver_, uint256(toChainId_), amount_, middlewareRequest, bridgeRequest);

            txData = abi.encodeWithSelector(SocketRouterMock.outboundTransferTo.selector, userRequest);
        } else if (liqBridgeKind_ == 2) {
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
                abi.encode(from_, FORKS[toChainId_], underlyingToken_, totalSlippage, false, 0, false),
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

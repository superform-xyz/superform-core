// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

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

contract PayMasterTest is ProtocolActions {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address txProcessorETH;
    address txUpdaterETH;
    address txProcessorARBI;
    address txUpdaterARBI;

    address dstRefundAddress = address(444);

    SuperRegistry superRegistry;
    SuperRegistry superRegistryARBI;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);

        txProcessorETH = address(new KeeperMock());
        txUpdaterETH = address(new KeeperMock());

        superRegistry = SuperRegistry(getContract(ETH, "SuperRegistry"));

        vm.selectFork(FORKS[ARBI]);
        txProcessorARBI = address(new KeeperMock());
        txUpdaterARBI = address(new KeeperMock());

        vm.selectFork(FORKS[ETH]);

        /// @dev setting these here as overrides just to test with receive function
        vm.startPrank(deployer);
        superRegistry.setAddress(keccak256("CORE_REGISTRY_PROCESSOR"), txProcessorARBI, ARBI);
        superRegistry.setAddress(keccak256("CORE_REGISTRY_UPDATER"), txUpdaterARBI, ARBI);
        vm.stopPrank();
    }

    function test_manipulationsBySendingFeesIntoRouter() public {
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

    function test_withdrawNativeToFailure() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address feeCollector = getContract(ETH, "PayMaster");
        PayMaster(feeCollector).makePayment{ value: 2 wei }(deployer);

        address mock = address(new KeeperMockThatWontAcceptEth());

        superRegistry.setAddress(keccak256("KEEPER_MOCK"), mock, ETH);

        /// @dev admin tries withdraw more than balance (check if handled gracefully)
        vm.expectRevert(Error.FAILED_WITHDRAW.selector);
        PayMaster(feeCollector).withdrawTo(keccak256("KEEPER_MOCK"), 1 wei);
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

        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(1, NATIVE, NATIVE, feeCollector, ETH, ARBI, 1 ether, feeCollectorDst, false)
        );

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        PayMaster(feeCollector).rebalanceTo(
            keccak256("CORE_REGISTRY_PROCESSOR"), LiqRequest(1, txData, NATIVE, ARBI, 1 ether), 420
        );

        superRegistry.setAddress(keccak256("CORE_REGISTRY_PROCESSOR"), txProcessorETH, ETH);
        txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(1, NATIVE, NATIVE, feeCollector, ETH, ARBI, 1 ether, feeCollectorDst, false)
        );
        /// @dev admin moves the payment from fee collector to different address on another chain
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        PayMaster(feeCollector).rebalanceTo(
            keccak256("CORE_REGISTRY_PROCESSOR"), LiqRequest(1, txData, NATIVE, ARBI, 1 ether), ARBI
        );
        txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(1, NATIVE, NATIVE, feeCollector, ETH, ARBI, 1 ether, txProcessorARBI, false)
        );
        /// @dev admin moves the payment from fee collector to different address on another chain
        vm.expectRevert(Error.INVALID_TXDATA_CHAIN_ID.selector);
        PayMaster(feeCollector).rebalanceTo(
            keccak256("CORE_REGISTRY_PROCESSOR"), LiqRequest(1, txData, NATIVE, ETH, 1 ether), ARBI
        );

        /// @dev admin moves the payment from fee collector (ideal conditions)
        PayMaster(feeCollector).rebalanceTo(
            keccak256("CORE_REGISTRY_PROCESSOR"),
            LiqRequest(
                1,
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        1, NATIVE, NATIVE, feeCollector, ETH, ARBI, 1 ether, txProcessorARBI, false
                    )
                ),
                NATIVE,
                ARBI,
                1 ether
            ),
            ARBI
        );

        assertEq(feeCollector.balance, 0);

        vm.selectFork(FORKS[ARBI]);
        /// @dev amount received will be bridge-slippage-adjusted
        assertEq(
            txProcessorARBI.balance,
            _updateAmountWithPricedSwapsAndSlippage(1 ether, totalSlippage, NATIVE, NATIVE, NATIVE, ETH, ARBI)
        );
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
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(1, NATIVE, NATIVE, feeCollector, ETH, ARBI, 1 ether, feeCollectorDst, false)
        );

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        PayMaster(feeCollector).rebalanceTo(
            keccak256("CORE_REGISTRY_UPDATER"), LiqRequest(1, txData, NATIVE, ARBI, 1 ether), 420
        );

        superRegistry.setAddress(keccak256("CORE_REGISTRY_UPDATER"), txUpdaterARBI, ETH);

        txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(1, NATIVE, NATIVE, feeCollector, ETH, ARBI, 1 ether, feeCollectorDst, false)
        );

        /// @dev admin moves the payment from fee collector to different address on another chain
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        PayMaster(feeCollector).rebalanceTo(
            keccak256("CORE_REGISTRY_UPDATER"), LiqRequest(1, txData, NATIVE, ARBI, 1 ether), ARBI
        );

        /// @dev admin moves the payment from fee collector (ideal conditions)
        PayMaster(feeCollector).rebalanceTo(
            keccak256("CORE_REGISTRY_UPDATER"),
            LiqRequest(
                1,
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        1, NATIVE, NATIVE, feeCollector, ETH, ARBI, 1 ether, txUpdaterARBI, false
                    )
                ),
                NATIVE,
                ARBI,
                1 ether
            ),
            ARBI
        );

        assertEq(feeCollector.balance, 0);

        vm.selectFork(FORKS[ARBI]);
        /// @dev amount received will be bridge-slippage-adjusted
        assertEq(
            txUpdaterARBI.balance,
            _updateAmountWithPricedSwapsAndSlippage(1 ether, totalSlippage, NATIVE, NATIVE, NATIVE, ETH, ARBI)
        );
    }

    function _successfulDeposit() internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            100,
            false,
            LiqRequest(1, bytes(""), getContract(ETH, "DAI"), ETH, 0),
            bytes(""),
            dstRefundAddress,
            bytes("")
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);
        (,, uint256 msgFees) =
            PaymentHelper(getContract(ETH, "PaymentHelper")).estimateSingleDirectSingleVault(req, true);
        msgFees = msgFees + 2 ether;

        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit{ value: msgFees }(
            req
        );
    }
}

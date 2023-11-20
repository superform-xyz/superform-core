/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import "test/utils/ProtocolActions.sol";

contract MockGasPriceOracle {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 28 gwei, block.timestamp, block.timestamp, 28 gwei);
    }
}

contract PaymentHelperTest is ProtocolActions {
    PaymentHelper public paymentHelper;
    MockGasPriceOracle public mockGasPriceOracle;

    address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address receiverAddress = address(444);

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        paymentHelper = PaymentHelper(getContract(ETH, "PaymentHelper"));
        mockGasPriceOracle = new MockGasPriceOracle();
    }

    function test_getGasPrice_chainlink_malfunction() public {
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 2, abi.encode(address(0x222)));

        address gasPriceOracle = address(paymentHelper.gasPriceOracle(ETH));
        vm.mockCall(
            gasPriceOracle,
            abi.encodeWithSelector(MockGasPriceOracle(gasPriceOracle).latestRoundData.selector),
            abi.encode(0, -10, block.timestamp, 0, 28 gwei)
        );

        vm.expectRevert(Error.CHAINLINK_MALFUNCTION.selector);
        bytes memory emptyBytes;
        paymentHelper.estimateSingleDirectSingleVault(
            SingleDirectSingleVaultStateReq(
                SingleVaultSFData(
                    _generateTimelockSuperformPackWithShift(),
                    /// timelock
                    420,
                    420,
                    false,
                    false,
                    LiqRequest(1, emptyBytes, address(0), ETH, 420),
                    emptyBytes,
                    receiverAddress,
                    emptyBytes
                )
            ),
            false
        );

        vm.clearMockedCalls();
    }

    function test_getGasPrice_chainlink_incomplete_round() public {
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 2, abi.encode(address(0x222)));

        address gasPriceOracle = address(paymentHelper.gasPriceOracle(ETH));

        vm.mockCall(
            gasPriceOracle,
            abi.encodeWithSelector(MockGasPriceOracle(gasPriceOracle).latestRoundData.selector),
            abi.encode(0, 10, block.timestamp, 0, 28 gwei)
        );

        vm.expectRevert(Error.CHAINLINK_INCOMPLETE_ROUND.selector);
        bytes memory emptyBytes;
        paymentHelper.estimateSingleDirectSingleVault(
            SingleDirectSingleVaultStateReq(
                SingleVaultSFData(
                    _generateTimelockSuperformPackWithShift(),
                    /// timelock
                    420,
                    420,
                    false,
                    false,
                    LiqRequest(1, emptyBytes, address(0), ETH, 420),
                    emptyBytes,
                    receiverAddress,
                    emptyBytes
                )
            ),
            false
        );

        vm.clearMockedCalls();
    }

    function test_estimateSingleDirectSingleVault() public {
        /// @dev scenario: single vault withdrawal involving timelock
        /// expected fees to be greater than zero
        bytes memory emptyBytes;
        (,, uint256 fees) = paymentHelper.estimateSingleDirectSingleVault(
            SingleDirectSingleVaultStateReq(
                SingleVaultSFData(
                    _generateTimelockSuperformPackWithShift(),
                    /// timelock
                    420,
                    420,
                    false,
                    false,
                    LiqRequest(1, emptyBytes, address(0), ETH, 420),
                    emptyBytes,
                    receiverAddress,
                    emptyBytes
                )
            ),
            false
        );

        assertGt(fees, 0);

        (,, uint256 fees2) = paymentHelper.estimateSingleDirectSingleVault(
            SingleDirectSingleVaultStateReq(
                SingleVaultSFData(
                    _generateTimelockSuperformPackWithShift(),
                    /// timelock
                    420,
                    420,
                    false,
                    false,
                    LiqRequest(1, emptyBytes, address(0), ETH, 420),
                    emptyBytes,
                    receiverAddress,
                    emptyBytes
                )
            ),
            true
        );

        assertGt(fees2, 0);

        (,, uint256 fees3) = paymentHelper.estimateSingleDirectSingleVault(
            SingleDirectSingleVaultStateReq(
                SingleVaultSFData(
                    _generateSuperformPackWithShift(),
                    /// timelock
                    420,
                    420,
                    false,
                    false,
                    LiqRequest(1, emptyBytes, address(0), ETH, 420),
                    emptyBytes,
                    receiverAddress,
                    emptyBytes
                )
            ),
            false
        );

        assertEq(fees3, 0);
    }

    function test_estimateSingleDirectMultiVault() public {
        /// @dev scenario: single vault withdrawal involving timelock
        /// expected fees to be greater than zero
        bytes memory emptyBytes;
        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = _generateTimelockSuperformPackWithShift();

        uint256[] memory uint256MemoryArray = new uint256[](1);
        uint256MemoryArray[0] = 420;

        LiqRequest[] memory liqRequestMemoryArray = new LiqRequest[](1);
        liqRequestMemoryArray[0] = LiqRequest(1, emptyBytes, address(0), ETH, 420);

        (,, uint256 fees) = paymentHelper.estimateSingleDirectMultiVault(
            SingleDirectMultiVaultStateReq(
                MultiVaultSFData(
                    superFormIds,
                    /// timelock
                    uint256MemoryArray,
                    uint256MemoryArray,
                    new bool[](1),
                    new bool[](1),
                    liqRequestMemoryArray,
                    emptyBytes,
                    receiverAddress,
                    emptyBytes
                )
            ),
            false
        );

        assertGt(fees, 0);

        (,, uint256 fees2) = paymentHelper.estimateSingleDirectMultiVault(
            SingleDirectMultiVaultStateReq(
                MultiVaultSFData(
                    superFormIds,
                    /// timelock
                    uint256MemoryArray,
                    uint256MemoryArray,
                    new bool[](1),
                    new bool[](1),
                    liqRequestMemoryArray,
                    emptyBytes,
                    receiverAddress,
                    emptyBytes
                )
            ),
            true
        );

        /// @dev there are always liq fees if there is liqRequests (native tokens to pay)
        assertGt(fees2, 0);
    }

    function test_ifZeroIsReturnedWhenDstValueIsZero() public {
        /// @dev scenario: when the dst native fee is returned as zero by oracle

        vm.prank(deployer);
        paymentHelper.updateRemoteChain(137, 1, abi.encode(address(0)));

        vm.prank(deployer);
        paymentHelper.updateRemoteChain(137, 7, abi.encode(0));

        bytes memory emptyBytes;
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1,
                native,
                address(0),
                getContract(ETH, "CoreStateRegistry"),
                ETH,
                ETH,
                1e18,
                getContract(ETH, "CoreStateRegistry"),
                false
            )
        );

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        (,, uint256 fees,) = paymentHelper.estimateSingleXChainSingleVault(
            SingleXChainSingleVaultStateReq(
                ambIds,
                137,
                SingleVaultSFData(
                    _generateTimelockSuperformPackWithShift(),
                    /// timelock
                    420,
                    420,
                    false,
                    false,
                    LiqRequest(1, txData, address(0), ETH, 420),
                    emptyBytes,
                    receiverAddress,
                    emptyBytes
                )
            ),
            true
        );

        assertEq(fees, 0);
    }

    function test_usageOfSrcNativePrice() public {
        /// @dev scenario: when the source native fee oracle is zero address
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 1, abi.encode(address(0)));

        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 7, abi.encode(1e8));

        bytes memory emptyBytes;
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1,
                native,
                address(0),
                getContract(ETH, "CoreStateRegistry"),
                ETH,
                ETH,
                1e18,
                getContract(ETH, "CoreStateRegistry"),
                false
            )
        );

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        (,,, uint256 fees) = paymentHelper.estimateSingleXChainSingleVault(
            SingleXChainSingleVaultStateReq(
                ambIds,
                137,
                SingleVaultSFData(
                    _generateTimelockSuperformPackWithShift(),
                    /// timelock
                    420,
                    420,
                    false,
                    false,
                    LiqRequest(1, txData, address(0), ETH, 420),
                    emptyBytes,
                    receiverAddress,
                    emptyBytes
                )
            ),
            true
        );

        assertGt(fees, 0);
    }

    function test_dstSwaps_swapFees() public {
        /// @dev scenario: when swap fees is set to 0

        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 3, abi.encode(1e8));

        bytes memory emptyBytes;
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1, native, address(0), address(0), ETH, ETH, 1e18, getContract(ETH, "DstSwapper"), false
            )
        );

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        (,, uint256 dstAmount,) = paymentHelper.estimateSingleXChainSingleVault(
            SingleXChainSingleVaultStateReq(
                ambIds,
                137,
                SingleVaultSFData(
                    _generateTimelockSuperformPackWithShift(),
                    /// timelock
                    420,
                    420,
                    false,
                    false,
                    LiqRequest(1, txData, address(0), ETH, 420),
                    emptyBytes,
                    receiverAddress,
                    emptyBytes
                )
            ),
            true
        );

        assertGt(dstAmount, 0);
    }

    function test_calculateAMBData() public {
        /// @dev scenario: when the source native fee oracle is zero address
        vm.prank(deployer);
        uint8[] memory ambIds = new uint8[](3);

        ambIds[0] = 1;
        ambIds[1] = 2;
        ambIds[2] = 3;
        (uint256 totalFees,) =
            paymentHelper.calculateAMBData(137, ambIds, abi.encode(AMBMessage(type(uint256).max, "0x")));

        assertGt(totalFees, 0);
    }

    function test_chainlink_malfunction() public {
        /// @dev scenario: when the source native fee oracle is zero address
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 1, abi.encode(address(0)));

        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 7, abi.encode(1e8));

        bytes memory emptyBytes;
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1,
                native,
                address(0),
                getContract(ETH, "CoreStateRegistry"),
                ETH,
                ETH,
                1e18,
                getContract(ETH, "CoreStateRegistry"),
                false
            )
        );

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        address nativeFeedOracleDst = address(paymentHelper.nativeFeedOracle(137));

        vm.mockCall(
            nativeFeedOracleDst,
            abi.encodeWithSelector(MockGasPriceOracle(nativeFeedOracleDst).latestRoundData.selector),
            abi.encode(0, -10, block.timestamp, 0, 28 gwei)
        );

        vm.expectRevert(Error.CHAINLINK_MALFUNCTION.selector);
        paymentHelper.estimateSingleXChainSingleVault(
            SingleXChainSingleVaultStateReq(
                ambIds,
                137,
                SingleVaultSFData(
                    _generateTimelockSuperformPackWithShift(),
                    /// timelock
                    420,
                    420,
                    false,
                    false,
                    LiqRequest(1, txData, address(0), ETH, 420),
                    emptyBytes,
                    receiverAddress,
                    emptyBytes
                )
            ),
            true
        );

        vm.clearMockedCalls();
    }

    function test_chainlink_incompleteround() public {
        /// @dev scenario: when the source native fee oracle is zero address
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 1, abi.encode(address(0)));

        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 7, abi.encode(1e8));

        bytes memory emptyBytes;
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1,
                native,
                address(0),
                getContract(ETH, "CoreStateRegistry"),
                ETH,
                ETH,
                1e18,
                getContract(ETH, "CoreStateRegistry"),
                false
            )
        );

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        address nativeFeedOracleDst = address(paymentHelper.nativeFeedOracle(137));

        vm.mockCall(
            nativeFeedOracleDst,
            abi.encodeWithSelector(MockGasPriceOracle(nativeFeedOracleDst).latestRoundData.selector),
            abi.encode(0, 10, block.timestamp, 0, 28 gwei)
        );

        vm.expectRevert(Error.CHAINLINK_INCOMPLETE_ROUND.selector);
        paymentHelper.estimateSingleXChainSingleVault(
            SingleXChainSingleVaultStateReq(
                ambIds,
                137,
                SingleVaultSFData(
                    _generateTimelockSuperformPackWithShift(),
                    /// timelock
                    420,
                    420,
                    false,
                    false,
                    LiqRequest(1, txData, address(0), ETH, 420),
                    emptyBytes,
                    receiverAddress,
                    emptyBytes
                )
            ),
            true
        );

        vm.clearMockedCalls();
    }

    function test_usageOfGasPriceOracle() public {
        /// @dev scenario: using mock gas price oracle
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 2, abi.encode(address(mockGasPriceOracle)));

        vm.prank(deployer);
        paymentHelper.updateRemoteChain(137, 2, abi.encode(address(mockGasPriceOracle)));

        bytes memory emptyBytes;
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1,
                native,
                address(0),
                getContract(ETH, "CoreStateRegistry"),
                ETH,
                ETH,
                1e18,
                getContract(ETH, "CoreStateRegistry"),
                false
            )
        );

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        (,,, uint256 fees) = paymentHelper.estimateSingleXChainSingleVault(
            SingleXChainSingleVaultStateReq(
                ambIds,
                137,
                SingleVaultSFData(
                    _generateTimelockSuperformPackWithShift(),
                    /// timelock
                    420,
                    420,
                    false,
                    false,
                    LiqRequest(1, txData, address(0), ETH, 420),
                    emptyBytes,
                    receiverAddress,
                    emptyBytes
                )
            ),
            true
        );

        assertGt(fees, 0);
    }

    function test_setSameChainConfig() public {
        vm.selectFork(FORKS[ETH]);

        /// set config type: 1
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 1, abi.encode(address(420)));

        address result1 = address(paymentHelper.nativeFeedOracle(1));
        assertEq(result1, address(420));

        /// set config type: 2
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 2, abi.encode(address(421)));

        address result2 = address(paymentHelper.gasPriceOracle(1));
        assertEq(result2, address(421));

        /// set config type: 3
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 3, abi.encode(422));

        uint256 result3 = paymentHelper.swapGasUsed(1);
        assertEq(result3, 422);

        /// set config type: 4
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 4, abi.encode(423));

        uint256 result4 = paymentHelper.updateGasUsed(1);
        assertEq(result4, 423);

        /// set config type: 5
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 5, abi.encode(424));

        uint256 result5 = paymentHelper.depositGasUsed(1);
        assertEq(result5, 424);

        /// set config type: 6
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 6, abi.encode(425));

        uint256 result6 = paymentHelper.withdrawGasUsed(1);
        assertEq(result6, 425);

        /// set config type: 7
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 7, abi.encode(426));

        uint256 result7 = paymentHelper.nativePrice(1);
        assertEq(result7, 426);

        /// set config type: 8
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 8, abi.encode(427));

        uint256 result8 = paymentHelper.gasPrice(1);
        assertEq(result8, 427);

        /// set config type: 9
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 9, abi.encode(428));

        uint256 result9 = paymentHelper.gasPerByte(1);
        assertEq(result9, 428);

        /// set config type: 10
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 10, abi.encode(429));

        uint256 result10 = paymentHelper.ackGasCost(1);
        assertEq(result10, 429);

        /// set config type: 11
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 11, abi.encode(430));

        uint256 result11 = paymentHelper.timelockCost(1);
        assertEq(result11, 430);
    }

    function test_addRemoteChain() public {
        vm.prank(deployer);
        paymentHelper.addRemoteChain(
            420,
            IPaymentHelper.PaymentHelperConfig(address(420), address(421), 422, 423, 424, 425, 426, 427, 428, 429, 430)
        );
    }

    function test_updateRemoteChain() public {
        /// chain id used: 420

        /// set config type: 1
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(420, 1, abi.encode(address(420)));

        address result1 = address(paymentHelper.nativeFeedOracle(420));
        assertEq(result1, address(420));

        /// set config type: 2
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(420, 2, abi.encode(address(421)));

        address result2 = address(paymentHelper.gasPriceOracle(420));
        assertEq(result2, address(421));

        /// set config type: 3
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(420, 3, abi.encode(422));

        uint256 result3 = paymentHelper.swapGasUsed(420);
        assertEq(result3, 422);

        /// set config type: 4
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(420, 4, abi.encode(423));

        uint256 result4 = paymentHelper.updateGasUsed(420);
        assertEq(result4, 423);

        /// set config type: 5
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(420, 5, abi.encode(424));

        uint256 result5 = paymentHelper.depositGasUsed(420);
        assertEq(result5, 424);

        /// set config type: 6
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(420, 6, abi.encode(425));

        uint256 result6 = paymentHelper.withdrawGasUsed(420);
        assertEq(result6, 425);

        /// set config type: 7
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(420, 7, abi.encode(426));

        uint256 result7 = paymentHelper.nativePrice(420);
        assertEq(result7, 426);

        /// set config type: 8
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(420, 8, abi.encode(427));

        uint256 result8 = paymentHelper.gasPrice(420);
        assertEq(result8, 427);

        /// set config type: 9
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(420, 9, abi.encode(428));

        uint256 result9 = paymentHelper.gasPerByte(420);
        assertEq(result9, 428);

        /// set config type: 10
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 10, abi.encode(429));

        uint256 result10 = paymentHelper.ackGasCost(1);
        assertEq(result10, 429);

        /// set config type: 11
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 11, abi.encode(430));

        uint256 result11 = paymentHelper.timelockCost(1);
        assertEq(result11, 430);
    }

    function _generateTimelockSuperformPackWithShift() internal pure returns (uint256 superformId_) {
        address superform_ = address(111);
        uint32 formImplementationId_ = 2;
        uint64 chainId_ = 1;

        superformId_ = uint256(uint160(superform_));
        superformId_ |= uint256(formImplementationId_) << 160;
        superformId_ |= uint256(chainId_) << 192;
    }

    function _generateSuperformPackWithShift() internal pure returns (uint256 superformId_) {
        address superform_ = address(111);
        uint32 formImplementationId_ = 1;
        uint64 chainId_ = 1;

        superformId_ = uint256(uint160(superform_));
        superformId_ |= uint256(formImplementationId_) << 160;
        superformId_ |= uint256(chainId_) << 192;
    }
}

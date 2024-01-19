// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "test/utils/ProtocolActions.sol";
import { AggregatorV3Interface } from "src/vendor/chainlink/AggregatorV3Interface.sol";

contract AggregatorV3MockInvalidDecimals is AggregatorV3Interface {
    function decimals() external pure override returns (uint8) {
        return 10;
    }

    // You need to implement the rest of the AggregatorV3Interface functions
    function description() external pure override returns (string memory) {
        return "Mock Aggregator";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        pure
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, 0, 0, 0, _roundId);
    }

    function latestRoundData()
        external
        pure
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 0, 0, 0, 0);
    }
}

contract MockGasPriceOracle {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 28 gwei, block.timestamp, block.timestamp, 28 gwei);
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }
}

contract MalFunctioningPriceOracle {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 0, block.timestamp, block.timestamp, 0);
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }
}

contract PaymentHelperTest is ProtocolActions {
    PaymentHelper public paymentHelper;
    MockGasPriceOracle public mockGasPriceOracle;
    MalFunctioningPriceOracle public malFunctioningOracle;

    address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address receiverAddress = address(444);

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        paymentHelper = PaymentHelper(getContract(ETH, "PaymentHelper"));
        mockGasPriceOracle = new MockGasPriceOracle();
        malFunctioningOracle = new MalFunctioningPriceOracle();
    }

    function test_getGasPrice_chainlink_malfunction() public {
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 2, abi.encode(address(malFunctioningOracle)));

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
                    420,
                    LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420),
                    emptyBytes,
                    false,
                    false,
                    receiverAddress,
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
        paymentHelper.updateRemoteChain(1, 2, abi.encode(address(malFunctioningOracle)));

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
                    420,
                    LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420),
                    emptyBytes,
                    false,
                    false,
                    receiverAddress,
                    receiverAddress,
                    emptyBytes
                )
            ),
            false
        );

        vm.clearMockedCalls();
    }

    function test_estimateSingleDirectSingleVault_formImplPaused() public {
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            2, ISuperformFactory.PauseStatus(1), ""
        );
        /// @dev scenario: single vault withdrawal involving timelock with paused implementation
        bytes memory emptyBytes;
        (,, uint256 fees) = paymentHelper.estimateSingleDirectSingleVault(
            SingleDirectSingleVaultStateReq(
                SingleVaultSFData(
                    _generateTimelockSuperformPackWithShift(),
                    /// timelock
                    420,
                    420,
                    420,
                    LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420),
                    emptyBytes,
                    false,
                    false,
                    receiverAddress,
                    receiverAddress,
                    emptyBytes
                )
            ),
            false
        );
        assertGt(fees, 0);
    }

    function test_estimateSingleDirectMultiVault_formImplPaused() public {
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            2, ISuperformFactory.PauseStatus(1), ""
        );
        bytes memory emptyBytes;
        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = _generateTimelockSuperformPackWithShift();

        uint256[] memory uint256MemoryArray = new uint256[](1);
        uint256MemoryArray[0] = 420;

        LiqRequest[] memory liqRequestMemoryArray = new LiqRequest[](1);
        liqRequestMemoryArray[0] = LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420);

        (,, uint256 fees) = paymentHelper.estimateSingleDirectMultiVault(
            SingleDirectMultiVaultStateReq(
                MultiVaultSFData(
                    superFormIds,
                    /// timelock
                    uint256MemoryArray,
                    uint256MemoryArray,
                    uint256MemoryArray,
                    liqRequestMemoryArray,
                    emptyBytes,
                    new bool[](1),
                    new bool[](1),
                    receiverAddress,
                    receiverAddress,
                    emptyBytes
                )
            ),
            false
        );
        assertGt(fees, 0);
    }

    function test_estimateSingleXChainSingleVault_formImplPaused() public {
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            2, ISuperformFactory.PauseStatus(1), ""
        );

        uint8[] memory ambIds = new uint8[](1);

        ambIds[0] = 1;
        ambIds[0] = 2;

        /// @dev scenario: single vault withdrawal involving timelock with paused implementation
        bytes memory emptyBytes;
        (,,, uint256 fees) = paymentHelper.estimateSingleXChainSingleVault(
            SingleXChainSingleVaultStateReq(
                ambIds,
                ARBI,
                SingleVaultSFData(
                    _generateTimelockSuperformPackWithShift(),
                    /// timelock
                    420,
                    420,
                    420,
                    LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420),
                    emptyBytes,
                    false,
                    false,
                    receiverAddress,
                    receiverAddress,
                    emptyBytes
                )
            ),
            false
        );
        assertGt(fees, 0);
    }

    function test_estimateSingleXChainMultiVault_formImplPaused() public {
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            2, ISuperformFactory.PauseStatus(1), ""
        );

        uint8[] memory ambIds = new uint8[](1);

        ambIds[0] = 1;
        ambIds[0] = 2;

        bytes memory emptyBytes;
        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = _generateTimelockSuperformPackWithShift();

        uint256[] memory uint256MemoryArray = new uint256[](1);
        uint256MemoryArray[0] = 420;

        LiqRequest[] memory liqRequestMemoryArray = new LiqRequest[](1);
        liqRequestMemoryArray[0] = LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420);

        (,,, uint256 fees) = paymentHelper.estimateSingleXChainMultiVault(
            SingleXChainMultiVaultStateReq(
                ambIds,
                ARBI,
                MultiVaultSFData(
                    superFormIds,
                    /// timelock
                    uint256MemoryArray,
                    uint256MemoryArray,
                    uint256MemoryArray,
                    liqRequestMemoryArray,
                    emptyBytes,
                    new bool[](1),
                    new bool[](1),
                    receiverAddress,
                    receiverAddress,
                    emptyBytes
                )
            ),
            false
        );
        assertGt(fees, 0);
    }

    function test_estimateSingleXChainMultiVault_retain4626() public {
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            2, ISuperformFactory.PauseStatus(1), ""
        );

        uint8[] memory ambIds = new uint8[](1);

        ambIds[0] = 1;
        ambIds[0] = 2;

        bytes memory emptyBytes;
        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = _generateTimelockSuperformPackWithShift();

        uint256[] memory uint256MemoryArray = new uint256[](1);
        uint256MemoryArray[0] = 420;

        LiqRequest[] memory liqRequestMemoryArray = new LiqRequest[](1);
        liqRequestMemoryArray[0] = LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420);
        bool[] memory retain4626 = new bool[](1);

        retain4626[0] = true;

        (,,, uint256 fees) = paymentHelper.estimateSingleXChainMultiVault(
            SingleXChainMultiVaultStateReq(
                ambIds,
                ARBI,
                MultiVaultSFData(
                    superFormIds,
                    /// timelock
                    uint256MemoryArray,
                    uint256MemoryArray,
                    uint256MemoryArray,
                    liqRequestMemoryArray,
                    emptyBytes,
                    new bool[](1),
                    retain4626,
                    receiverAddress,
                    receiverAddress,
                    emptyBytes
                )
            ),
            false
        );
        assertGt(fees, 0);
    }

    function test_estimateSingleXChainMultiVault_sameDst() public {
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            2, ISuperformFactory.PauseStatus(1), ""
        );

        uint8[] memory ambIds = new uint8[](1);

        ambIds[0] = 1;
        ambIds[0] = 2;

        bytes memory emptyBytes;
        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = _generateTimelockSuperformPackWithShift();

        uint256[] memory uint256MemoryArray = new uint256[](1);
        uint256MemoryArray[0] = 420;

        LiqRequest[] memory liqRequestMemoryArray = new LiqRequest[](1);
        liqRequestMemoryArray[0] = LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420);

        (,,, uint256 fees) = paymentHelper.estimateSingleXChainMultiVault(
            SingleXChainMultiVaultStateReq(
                ambIds,
                ETH,
                MultiVaultSFData(
                    superFormIds,
                    /// timelock
                    uint256MemoryArray,
                    uint256MemoryArray,
                    uint256MemoryArray,
                    liqRequestMemoryArray,
                    emptyBytes,
                    new bool[](1),
                    new bool[](1),
                    receiverAddress,
                    receiverAddress,
                    emptyBytes
                )
            ),
            false
        );
        assertGt(fees, 0);
    }

    function test_estimateMultiDstSingleVault_formImplPaused() public {
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            2, ISuperformFactory.PauseStatus(1), ""
        );
        bytes memory emptyBytes;

        uint64[] memory dstChainIds = new uint64[](1);
        dstChainIds[0] = ARBI;
        uint8[][] memory ambIdsMulti = new uint8[][](1);
        uint8[] memory ambIds = new uint8[](2);

        ambIds[0] = 1;
        ambIds[1] = 2;

        ambIdsMulti[0] = ambIds;

        SingleVaultSFData[] memory superformsData = new SingleVaultSFData[](1);

        superformsData[0] = SingleVaultSFData(
            _generateTimelockSuperformPackWithShift(),
            /// timelock
            420,
            420,
            420,
            LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420),
            emptyBytes,
            false,
            false,
            receiverAddress,
            receiverAddress,
            emptyBytes
        );

        /// @dev scenario: single vault withdrawal involving timelock with paused implementation
        (,,, uint256 fees) = paymentHelper.estimateMultiDstSingleVault(
            MultiDstSingleVaultStateReq(ambIdsMulti, dstChainIds, superformsData), false
        );
        assertGt(fees, 0);
    }

    function test_estimateMultiDstMultiVault_formImplPaused() public {
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            2, ISuperformFactory.PauseStatus(1), ""
        );
        bytes memory emptyBytes;

        uint64[] memory dstChainIds = new uint64[](1);
        dstChainIds[0] = ARBI;
        uint8[][] memory ambIdsMulti = new uint8[][](1);
        uint8[] memory ambIds = new uint8[](2);

        ambIds[0] = 1;
        ambIds[1] = 2;

        ambIdsMulti[0] = ambIds;
        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = _generateTimelockSuperformPackWithShift();

        uint256[] memory uint256MemoryArray = new uint256[](1);
        uint256MemoryArray[0] = 420;

        LiqRequest[] memory liqRequestMemoryArray = new LiqRequest[](1);
        liqRequestMemoryArray[0] = LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420);
        MultiVaultSFData[] memory superformsData = new MultiVaultSFData[](1);

        superformsData[0] = MultiVaultSFData(
            superFormIds,
            /// timelock
            uint256MemoryArray,
            uint256MemoryArray,
            uint256MemoryArray,
            liqRequestMemoryArray,
            emptyBytes,
            new bool[](1),
            new bool[](1),
            receiverAddress,
            receiverAddress,
            emptyBytes
        );

        /// @dev scenario: single vault withdrawal involving timelock with paused implementation
        (,,, uint256 fees) = paymentHelper.estimateMultiDstMultiVault(
            MultiDstMultiVaultStateReq(ambIdsMulti, dstChainIds, superformsData), false
        );
        assertGt(fees, 0);
    }

    function test_estimateSingleXChainSingleVault_sameDst() public {
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            2, ISuperformFactory.PauseStatus(1), ""
        );

        uint8[] memory ambIds = new uint8[](1);

        ambIds[0] = 1;
        ambIds[0] = 2;

        /// @dev scenario: single vault withdrawal involving timelock with paused implementation
        bytes memory emptyBytes;
        (,,, uint256 fees) = paymentHelper.estimateSingleXChainSingleVault(
            SingleXChainSingleVaultStateReq(
                ambIds,
                ETH,
                SingleVaultSFData(
                    _generateTimelockSuperformPackWithShift(),
                    /// timelock
                    420,
                    420,
                    420,
                    LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420),
                    emptyBytes,
                    false,
                    false,
                    receiverAddress,
                    receiverAddress,
                    emptyBytes
                )
            ),
            false
        );
        assertGt(fees, 0);
    }

    function test_estimateAMBFees_differentChainId() public {
        // Define ambIds_, dstChainId_, message_, and extraData_
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        uint64 dstChainId_ = ARBI; // Different than CHAIN_ID

        bytes memory message_ = abi.encode(1);

        bytes[] memory extraData_ = new bytes[](2);
        extraData_[0] = "";
        extraData_[1] = abi.encode("0");

        // Call estimateAMBFees
        (uint256 totalFees,) = paymentHelper.estimateAMBFees(ambIds_, dstChainId_, message_, extraData_);

        // Verify totalFees is greater than 0
        assertGt(totalFees, 0);
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
                    420,
                    LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420),
                    emptyBytes,
                    false,
                    false,
                    receiverAddress,
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
                    420,
                    LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420),
                    emptyBytes,
                    false,
                    false,
                    receiverAddress,
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
                    420,
                    LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420),
                    emptyBytes,
                    false,
                    false,
                    receiverAddress,
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
        liqRequestMemoryArray[0] = LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420);

        (,, uint256 fees) = paymentHelper.estimateSingleDirectMultiVault(
            SingleDirectMultiVaultStateReq(
                MultiVaultSFData(
                    superFormIds,
                    /// timelock
                    uint256MemoryArray,
                    uint256MemoryArray,
                    uint256MemoryArray,
                    liqRequestMemoryArray,
                    emptyBytes,
                    new bool[](1),
                    new bool[](1),
                    receiverAddress,
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
                    uint256MemoryArray,
                    liqRequestMemoryArray,
                    emptyBytes,
                    new bool[](1),
                    new bool[](1),
                    receiverAddress,
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
                    420,
                    LiqRequest(txData, address(0), address(0), 1, ETH, 420),
                    emptyBytes,
                    false,
                    false,
                    receiverAddress,
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
                    420,
                    LiqRequest(txData, address(0), address(0), 1, ETH, 420),
                    emptyBytes,
                    false,
                    false,
                    receiverAddress,
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
                    420,
                    LiqRequest(txData, address(0), address(0), 1, ETH, 420),
                    emptyBytes,
                    false,
                    false,
                    receiverAddress,
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
                    420,
                    LiqRequest(txData, address(0), address(0), 1, ETH, 420),
                    emptyBytes,
                    false,
                    false,
                    receiverAddress,
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
                    420,
                    LiqRequest(txData, address(0), address(0), 1, ETH, 420),
                    emptyBytes,
                    false,
                    false,
                    receiverAddress,
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
                    420,
                    LiqRequest(txData, address(0), address(0), 1, ETH, 420),
                    emptyBytes,
                    false,
                    false,
                    receiverAddress,
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
        paymentHelper.updateRemoteChain(1, 1, abi.encode(address(mockGasPriceOracle)));

        address mockInvalidDecimals = address(new AggregatorV3MockInvalidDecimals());
        address result1 = address(paymentHelper.nativeFeedOracle(1));
        assertEq(result1, address(mockGasPriceOracle));

        vm.prank(deployer);
        vm.expectRevert(Error.CHAINLINK_UNSUPPORTED_DECIMAL.selector);
        paymentHelper.updateRemoteChain(1, 1, abi.encode(mockInvalidDecimals));

        /// set config type: 2
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 2, abi.encode(address(mockGasPriceOracle)));

        address result2 = address(paymentHelper.gasPriceOracle(1));
        assertEq(result2, address(mockGasPriceOracle));

        vm.prank(deployer);
        vm.expectRevert(Error.CHAINLINK_UNSUPPORTED_DECIMAL.selector);
        paymentHelper.updateRemoteChain(1, 2, abi.encode(mockInvalidDecimals));

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
        vm.startPrank(deployer);
        paymentHelper.addRemoteChain(
            420,
            IPaymentHelper.PaymentHelperConfig(address(0), address(0), 422, 423, 424, 425, 426, 427, 428, 429, 430, 431)
        );

        paymentHelper.addRemoteChain(
            421,
            IPaymentHelper.PaymentHelperConfig(
                0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
                0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
                422,
                423,
                424,
                425,
                426,
                427,
                428,
                429,
                430,
                431
            )
        );

        address mock = address(new AggregatorV3MockInvalidDecimals());

        vm.expectRevert(Error.CHAINLINK_UNSUPPORTED_DECIMAL.selector);
        paymentHelper.addRemoteChain(
            421,
            IPaymentHelper.PaymentHelperConfig(
                mock, 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431
            )
        );

        vm.expectRevert(Error.CHAINLINK_UNSUPPORTED_DECIMAL.selector);
        paymentHelper.addRemoteChain(
            421,
            IPaymentHelper.PaymentHelperConfig(
                0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, mock, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431
            )
        );

        vm.stopPrank();
    }

    function test_updateRemoteChain() public {
        /// chain id used: 420

        /// set config type: 1
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(420, 1, abi.encode(address(mockGasPriceOracle)));

        address result1 = address(paymentHelper.nativeFeedOracle(420));
        assertEq(result1, address(mockGasPriceOracle));

        /// set config type: 2
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(420, 2, abi.encode(address(mockGasPriceOracle)));

        address result2 = address(paymentHelper.gasPriceOracle(420));
        assertEq(result2, address(mockGasPriceOracle));

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

        /// set config type: 12
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 12, abi.encode(431));

        uint256 result12 = paymentHelper.emergencyCost(1);
        assertEq(result12, 431);
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

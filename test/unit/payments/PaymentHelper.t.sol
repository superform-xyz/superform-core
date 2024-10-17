// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "test/utils/ProtocolActions.sol";
import { AggregatorV3Interface } from "src/vendor/chainlink/AggregatorV3Interface.sol";
import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";

contract AggregatorV3MockInvalidDecimals is AggregatorV3Interface {
    function decimals() external pure override returns (uint8) {
        return 20;
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
                    _generateSuperformPackWithShift(),
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
                    _generateSuperformPackWithShift(),
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
            1, ISuperformFactory.PauseStatus(1), ""
        );
        /// @dev scenario: single vault withdrawal with paused implementation
        bytes memory emptyBytes;
        (,, uint256 fees) = paymentHelper.estimateSingleDirectSingleVault(
            SingleDirectSingleVaultStateReq(
                SingleVaultSFData(
                    _generateSuperformPackWithShift(),
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
            1, ISuperformFactory.PauseStatus(1), ""
        );
        bytes memory emptyBytes;
        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = _generateSuperformPackWithShift();

        uint256[] memory uint256MemoryArray = new uint256[](1);
        uint256MemoryArray[0] = 420;

        LiqRequest[] memory liqRequestMemoryArray = new LiqRequest[](1);
        liqRequestMemoryArray[0] = LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420);

        (,, uint256 fees) = paymentHelper.estimateSingleDirectMultiVault(
            SingleDirectMultiVaultStateReq(
                MultiVaultSFData(
                    superFormIds,
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
            1, ISuperformFactory.PauseStatus(1), ""
        );

        uint8[] memory ambIds = new uint8[](1);

        ambIds[0] = 1;
        ambIds[0] = 2;

        /// @dev scenario: single vault withdrawal with paused implementation
        bytes memory emptyBytes;
        (,,, uint256 fees) = paymentHelper.estimateSingleXChainSingleVault(
            SingleXChainSingleVaultStateReq(
                ambIds,
                ARBI,
                SingleVaultSFData(
                    _generateSuperformPackWithShift(),
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
            1, ISuperformFactory.PauseStatus(1), ""
        );

        uint8[] memory ambIds = new uint8[](1);

        ambIds[0] = 1;
        ambIds[0] = 2;

        bytes memory emptyBytes;
        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = _generateSuperformPackWithShift();

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

    function test_estimateSingleXChainMultiVault_retain4626() public view {
        uint8[] memory ambIds = new uint8[](1);

        ambIds[0] = 1;
        ambIds[0] = 2;

        bytes memory emptyBytes;
        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = _generateSuperformPackWithShift();

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

    function test_estimateSingleXChainMultiVault_sameDst_deposit() public view {
        uint8[] memory ambIds = new uint8[](1);

        ambIds[0] = 1;
        ambIds[0] = 2;

        bytes memory emptyBytes;
        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = _generateSuperformPackWithShift();

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
        assertGt(fees, 0);
    }

    function test_estimateMultiDstSingleVault_formImplPaused() public {
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            1, ISuperformFactory.PauseStatus(1), ""
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
            _generateSuperformPackWithShift(),
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

        /// @dev scenario: single vault withdrawal with paused implementation
        (,,, uint256 fees) = paymentHelper.estimateMultiDstSingleVault(
            MultiDstSingleVaultStateReq(ambIdsMulti, dstChainIds, superformsData), false
        );
        assertGt(fees, 0);
    }

    function test_estimateMultiDstMultiVault_formImplPaused() public {
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            1, ISuperformFactory.PauseStatus(1), ""
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
        superFormIds[0] = _generateSuperformPackWithShift();

        uint256[] memory uint256MemoryArray = new uint256[](1);
        uint256MemoryArray[0] = 420;

        LiqRequest[] memory liqRequestMemoryArray = new LiqRequest[](1);
        liqRequestMemoryArray[0] = LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420);
        MultiVaultSFData[] memory superformsData = new MultiVaultSFData[](1);

        superformsData[0] = MultiVaultSFData(
            superFormIds,
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

        /// @dev scenario: single vault withdrawal with paused implementation
        (,,, uint256 fees) = paymentHelper.estimateMultiDstMultiVault(
            MultiDstMultiVaultStateReq(ambIdsMulti, dstChainIds, superformsData), false
        );
        assertGt(fees, 0);
    }

    function test_estimateSingleXChainSingleVault_sameDst() public {
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            1, ISuperformFactory.PauseStatus(1), ""
        );

        uint8[] memory ambIds = new uint8[](1);

        ambIds[0] = 1;
        ambIds[0] = 2;

        /// @dev scenario: single vault withdrawal with paused implementation
        bytes memory emptyBytes;
        (,,, uint256 fees) = paymentHelper.estimateSingleXChainSingleVault(
            SingleXChainSingleVaultStateReq(
                ambIds,
                ETH,
                SingleVaultSFData(
                    _generateSuperformPackWithShift(),
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

    function test_estimateAMBFees_differentChainId() public view {
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

    function test_estimateSingleDirectSingleVault() public view {
        bytes memory emptyBytes;

        (,, uint256 fees2) = paymentHelper.estimateSingleDirectSingleVault(
            SingleDirectSingleVaultStateReq(
                SingleVaultSFData(
                    _generateSuperformPackWithShift(),
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
    

    function test_estimateSingleDirectMultiVault() public view {
        /// @dev scenario: single vault withdrawal
        /// expected fees to be greater than zero
        bytes memory emptyBytes;
        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = _generateSuperformPackWithShift();

        uint256[] memory uint256MemoryArray = new uint256[](1);
        uint256MemoryArray[0] = 420;

        LiqRequest[] memory liqRequestMemoryArray = new LiqRequest[](1);
        liqRequestMemoryArray[0] = LiqRequest(emptyBytes, address(0), address(0), 1, ETH, 420);

        (,, uint256 fees) = paymentHelper.estimateSingleDirectMultiVault(
            SingleDirectMultiVaultStateReq(
                MultiVaultSFData(
                    superFormIds,
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

        assertEq(fees, 0);

        (,, uint256 fees2) = paymentHelper.estimateSingleDirectMultiVault(
            SingleDirectMultiVaultStateReq(
                MultiVaultSFData(
                    superFormIds,
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
                    _generateSuperformPackWithShift(),
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
                    _generateSuperformPackWithShift(),
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

    function test_estimateWithNativeTokenPriceAsZero() public {
        /// @dev setting native token price as zero
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 1, abi.encode(address(0)));

        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 7, abi.encode(0));

        bytes memory emptyBytes;
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1, native, address(0), address(0), ETH, ETH, 1e18, getContract(ETH, "DstSwapper"), false
            )
        );

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        vm.expectRevert(Error.INVALID_NATIVE_TOKEN_PRICE.selector);
        paymentHelper.estimateSingleXChainSingleVault(
            SingleXChainSingleVaultStateReq(
                ambIds,
                137,
                SingleVaultSFData(
                    _generateSuperformPackWithShift(),
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
    }

    function test_estimateAckCostDefaultNativeSourceAsZero() public {
        /// @dev setting native token price as zero
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(137, 1, abi.encode(address(0)));

        vm.prank(deployer);
        paymentHelper.updateRemoteChain(137, 7, abi.encode(0));

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        vm.expectRevert(Error.INVALID_NATIVE_TOKEN_PRICE.selector);
        paymentHelper.estimateAckCostDefaultNativeSource(false, ambIds, 137);
    }

    function test_estimateAckCostDefaultNativeSourceForZeroDstAmount() public {
        /// @dev setting native token price as zero
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        address lzImpl = getContract(ETH, "LayerzeroImplementation");

        vm.mockCall(lzImpl, abi.encodeWithSelector(IAmbImplementation(lzImpl).estimateFees.selector), abi.encode(0));

        uint256 est = paymentHelper.estimateAckCostDefaultNativeSource(false, ambIds, 137);
        assertEq(est, 0);
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
                    _generateSuperformPackWithShift(),
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
                    _generateSuperformPackWithShift(),
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
                    _generateSuperformPackWithShift(),
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
                    _generateSuperformPackWithShift(),
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

        uint256 result4 = paymentHelper.updateDepositGasUsed(1);
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
    }

    function test_addRemoteChain_NOT_PROTOCOL_ADMIN() public {
        vm.prank(address(0x8282));
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        paymentHelper.addRemoteChain(
            420,
            IPaymentHelper.PaymentHelperConfig(
                address(0), address(0), 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432
            )
        );
    }

    function test_addRemoteChains_NOT_PROTOCOL_ADMIN() public {
        uint64[] memory chainIds_ = new uint64[](1);
        chainIds_[0] = 422;

        IPaymentHelper.PaymentHelperConfig[] memory configs = new IPaymentHelper.PaymentHelperConfig[](1);
        configs[0] = IPaymentHelper.PaymentHelperConfig(
            address(0), address(0), 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432
        );
        vm.prank(address(0x8282));
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        paymentHelper.addRemoteChains(chainIds_, configs);
    }

    function test_addRemoteChain() public {
        vm.startPrank(deployer);
        paymentHelper.addRemoteChain(
            420,
            IPaymentHelper.PaymentHelperConfig(
                address(0), address(0), 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432
            )
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
                431,
                432
            )
        );

        address mock = address(new AggregatorV3MockInvalidDecimals());

        vm.expectRevert(Error.CHAINLINK_UNSUPPORTED_DECIMAL.selector);
        paymentHelper.addRemoteChain(
            421,
            IPaymentHelper.PaymentHelperConfig(
                mock, 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432
            )
        );

        vm.expectRevert(Error.CHAINLINK_UNSUPPORTED_DECIMAL.selector);
        paymentHelper.addRemoteChain(
            421,
            IPaymentHelper.PaymentHelperConfig(
                0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, mock, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432
            )
        );

        vm.stopPrank();
    }

    function test_addRemoteChains() public {
        vm.startPrank(deployer);
        uint64[] memory chainIds = new uint64[](2);
        chainIds[0] = 422;
        chainIds[1] = 423;

        IPaymentHelper.PaymentHelperConfig[] memory configs = new IPaymentHelper.PaymentHelperConfig[](2);
        configs[0] = IPaymentHelper.PaymentHelperConfig(
            address(0), address(0), 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432
        );
        configs[1] = IPaymentHelper.PaymentHelperConfig(
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
            431,
            432
        );
        paymentHelper.addRemoteChains(chainIds, configs);

        vm.stopPrank();
    }

    function test_addRemoteChains_differentLen() public {
        vm.startPrank(deployer);
        uint64[] memory chainIds = new uint64[](1);
        chainIds[0] = 422;

        IPaymentHelper.PaymentHelperConfig[] memory configs = new IPaymentHelper.PaymentHelperConfig[](2);
        configs[0] = IPaymentHelper.PaymentHelperConfig(
            address(0), address(0), 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432
        );
        configs[1] = IPaymentHelper.PaymentHelperConfig(
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
            431,
            432
        );

        vm.expectRevert(Error.ARRAY_LENGTH_MISMATCH.selector);
        paymentHelper.addRemoteChains(chainIds, configs);

        vm.stopPrank();
    }

    function test_addRemoteChains_zeroInputLen() public {
        vm.startPrank(deployer);
        uint64[] memory chainIds;

        IPaymentHelper.PaymentHelperConfig[] memory configs = new IPaymentHelper.PaymentHelperConfig[](2);
        configs[0] = IPaymentHelper.PaymentHelperConfig(
            address(0), address(0), 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432
        );
        configs[1] = IPaymentHelper.PaymentHelperConfig(
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
            431,
            432
        );

        vm.expectRevert(Error.ZERO_INPUT_VALUE.selector);
        paymentHelper.addRemoteChains(chainIds, configs);

        vm.stopPrank();
    }

    function test_updateRemoteChain_NOT_PAYMENT_ADMIN() public {
        vm.prank(address(0x8282));
        vm.expectRevert(Error.NOT_PAYMENT_ADMIN.selector);
        paymentHelper.updateRemoteChain(420, 1, abi.encode(address(mockGasPriceOracle)));
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

        uint256 result4 = paymentHelper.updateDepositGasUsed(420);
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

        /// set config type: 12
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 12, abi.encode(431));

        uint256 result12 = paymentHelper.emergencyCost(1);
        assertEq(result12, 431);

        /// set config type: 13
        vm.prank(deployer);
        paymentHelper.updateRemoteChain(1, 13, abi.encode(431));

        uint256 result13 = paymentHelper.updateWithdrawGasUsed(1);
        assertEq(result13, 431);
    }

    function test_batchUpdateRemoteChain() public {
        /// chain id used: 420
        uint256[] memory configTypes = new uint256[](13);
        configTypes[0] = 1;
        configTypes[1] = 2;
        configTypes[2] = 3;
        configTypes[3] = 4;
        configTypes[4] = 5;
        configTypes[5] = 6;
        configTypes[6] = 7;
        configTypes[7] = 8;
        configTypes[8] = 9;
        configTypes[9] = 10;
        configTypes[10] = 11;
        configTypes[11] = 12;
        configTypes[12] = 13;

        bytes[] memory configs = new bytes[](13);
        configs[0] = abi.encode(address(mockGasPriceOracle));
        configs[1] = abi.encode(address(mockGasPriceOracle));
        configs[2] = abi.encode(422);
        configs[3] = abi.encode(423);
        configs[4] = abi.encode(424);
        configs[5] = abi.encode(425);
        configs[6] = abi.encode(426);
        configs[7] = abi.encode(427);
        configs[8] = abi.encode(428);
        configs[9] = abi.encode(429);
        configs[10] = abi.encode(430);
        configs[11] = abi.encode(431);
        configs[12] = abi.encode(432);

        vm.prank(deployer);
        paymentHelper.batchUpdateRemoteChain(420, configTypes, configs);

        address result1 = address(paymentHelper.nativeFeedOracle(420));
        assertEq(result1, address(mockGasPriceOracle));

        address result2 = address(paymentHelper.gasPriceOracle(420));
        assertEq(result2, address(mockGasPriceOracle));

        uint256 result3 = paymentHelper.swapGasUsed(420);
        assertEq(result3, 422);

        uint256 result4 = paymentHelper.updateDepositGasUsed(420);
        assertEq(result4, 423);

        uint256 result5 = paymentHelper.depositGasUsed(420);
        assertEq(result5, 424);

        uint256 result6 = paymentHelper.withdrawGasUsed(420);
        assertEq(result6, 425);

        uint256 result7 = paymentHelper.nativePrice(420);
        assertEq(result7, 426);

        uint256 result8 = paymentHelper.gasPrice(420);
        assertEq(result8, 427);

        uint256 result9 = paymentHelper.gasPerByte(420);
        assertEq(result9, 428);

        uint256 result10 = paymentHelper.ackGasCost(420);
        assertEq(result10, 429);

        uint256 result12 = paymentHelper.emergencyCost(420);
        assertEq(result12, 431);

        uint256 result13 = paymentHelper.updateWithdrawGasUsed(420);
        assertEq(result13, 432);
    }

    function test_batchUpdateRemoteChain_zeroLen() public {
        /// chain id used: 420
        uint256[] memory configTypes;
        bytes[] memory configs;

        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_INPUT_VALUE.selector);
        paymentHelper.batchUpdateRemoteChain(420, configTypes, configs);
    }

    function test_batchUpdateRemoteChain_invalidLen() public {
        /// chain id used: 420
        uint256[] memory configTypes = new uint256[](12);
        configTypes[0] = 1;
        configTypes[1] = 2;
        configTypes[2] = 3;
        configTypes[3] = 4;
        configTypes[4] = 5;
        configTypes[5] = 6;
        configTypes[6] = 7;
        configTypes[7] = 8;
        configTypes[8] = 9;
        configTypes[9] = 10;
        configTypes[10] = 11;
        configTypes[11] = 12;

        bytes[] memory configs = new bytes[](13);
        configs[0] = abi.encode(address(mockGasPriceOracle));
        configs[1] = abi.encode(address(mockGasPriceOracle));
        configs[2] = abi.encode(422);
        configs[3] = abi.encode(423);
        configs[4] = abi.encode(424);
        configs[5] = abi.encode(425);
        configs[6] = abi.encode(426);
        configs[7] = abi.encode(427);
        configs[8] = abi.encode(428);
        configs[9] = abi.encode(429);
        configs[10] = abi.encode(430);
        configs[11] = abi.encode(431);
        configs[12] = abi.encode(432);

        vm.prank(deployer);
        vm.expectRevert(Error.ARRAY_LENGTH_MISMATCH.selector);
        paymentHelper.batchUpdateRemoteChain(420, configTypes, configs);
    }

    function test_batchUpdateRemoteChains() public {
        uint64[] memory chainIds = new uint64[](2);
        chainIds[0] = 422;
        chainIds[1] = 423;

        uint256[][] memory configTypes = new uint256[][](2);

        /// chain id used: 420
        uint256[] memory configTypesTemp = new uint256[](13);
        configTypesTemp[0] = 1;
        configTypesTemp[1] = 2;
        configTypesTemp[2] = 3;
        configTypesTemp[3] = 4;
        configTypesTemp[4] = 5;
        configTypesTemp[5] = 6;
        configTypesTemp[6] = 7;
        configTypesTemp[7] = 8;
        configTypesTemp[8] = 9;
        configTypesTemp[9] = 10;
        configTypesTemp[10] = 11;
        configTypesTemp[11] = 12;
        configTypesTemp[12] = 13;

        configTypes[0] = configTypesTemp;
        configTypes[1] = configTypesTemp;

        bytes[][] memory configs = new bytes[][](2);
        bytes[] memory configsTemp = new bytes[](13);
        configsTemp[0] = abi.encode(address(mockGasPriceOracle));
        configsTemp[1] = abi.encode(address(mockGasPriceOracle));
        configsTemp[2] = abi.encode(422);
        configsTemp[3] = abi.encode(423);
        configsTemp[4] = abi.encode(424);
        configsTemp[5] = abi.encode(425);
        configsTemp[6] = abi.encode(426);
        configsTemp[7] = abi.encode(427);
        configsTemp[8] = abi.encode(428);
        configsTemp[9] = abi.encode(429);
        configsTemp[10] = abi.encode(430);
        configsTemp[11] = abi.encode(431);
        configsTemp[12] = abi.encode(432);

        configs[0] = configsTemp;
        configs[1] = configsTemp;

        vm.prank(deployer);
        paymentHelper.batchUpdateRemoteChains(chainIds, configTypes, configs);

        address result1 = address(paymentHelper.nativeFeedOracle(422));
        assertEq(result1, address(mockGasPriceOracle));
        result1 = address(paymentHelper.nativeFeedOracle(423));
        assertEq(result1, address(mockGasPriceOracle));

        address result2 = address(paymentHelper.gasPriceOracle(422));
        assertEq(result2, address(mockGasPriceOracle));
        result2 = address(paymentHelper.gasPriceOracle(423));
        assertEq(result2, address(mockGasPriceOracle));

        uint256 result3 = paymentHelper.swapGasUsed(422);
        assertEq(result3, 422);
        result3 = paymentHelper.swapGasUsed(423);
        assertEq(result3, 422);

        uint256 result4 = paymentHelper.updateDepositGasUsed(422);
        assertEq(result4, 423);
        result4 = paymentHelper.updateDepositGasUsed(423);
        assertEq(result4, 423);

        uint256 result5 = paymentHelper.depositGasUsed(422);
        assertEq(result5, 424);
        result5 = paymentHelper.depositGasUsed(423);
        assertEq(result5, 424);

        uint256 result6 = paymentHelper.withdrawGasUsed(422);
        assertEq(result6, 425);
        result6 = paymentHelper.withdrawGasUsed(423);
        assertEq(result6, 425);

        uint256 result7 = paymentHelper.nativePrice(422);
        assertEq(result7, 426);
        result7 = paymentHelper.nativePrice(423);
        assertEq(result7, 426);

        uint256 result8 = paymentHelper.gasPrice(422);
        assertEq(result8, 427);
        result8 = paymentHelper.gasPrice(423);
        assertEq(result8, 427);

        uint256 result9 = paymentHelper.gasPerByte(422);
        assertEq(result9, 428);
        result9 = paymentHelper.gasPerByte(423);
        assertEq(result9, 428);

        uint256 result10 = paymentHelper.ackGasCost(422);
        assertEq(result10, 429);
        result10 = paymentHelper.ackGasCost(423);
        assertEq(result10, 429);

        uint256 result12 = paymentHelper.emergencyCost(422);
        assertEq(result12, 431);
        result12 = paymentHelper.emergencyCost(423);
        assertEq(result12, 431);

        uint256 result13 = paymentHelper.updateWithdrawGasUsed(422);
        assertEq(result13, 432);
        result13 = paymentHelper.updateWithdrawGasUsed(423);
        assertEq(result13, 432);
    }

    function test_batchUpdateRemoteChains_invalidLen() public {
        uint64[] memory chainIds = new uint64[](2);
        chainIds[0] = 422;
        chainIds[1] = 423;

        uint256[][] memory configTypes = new uint256[][](2);

        /// chain id used: 420
        uint256[] memory configTypesTemp = new uint256[](13);
        configTypesTemp[0] = 1;
        configTypesTemp[1] = 2;
        configTypesTemp[2] = 3;
        configTypesTemp[3] = 4;
        configTypesTemp[4] = 5;
        configTypesTemp[5] = 6;
        configTypesTemp[6] = 7;
        configTypesTemp[7] = 8;
        configTypesTemp[8] = 9;
        configTypesTemp[9] = 10;
        configTypesTemp[10] = 11;
        configTypesTemp[11] = 12;
        configTypesTemp[12] = 13;

        configTypes[0] = configTypesTemp;
        configTypes[1] = configTypesTemp;

        bytes[][] memory configs = new bytes[][](1);
        bytes[] memory configsTemp = new bytes[](13);
        configsTemp[0] = abi.encode(address(mockGasPriceOracle));
        configsTemp[1] = abi.encode(address(mockGasPriceOracle));
        configsTemp[2] = abi.encode(422);
        configsTemp[3] = abi.encode(423);
        configsTemp[4] = abi.encode(424);
        configsTemp[5] = abi.encode(425);
        configsTemp[6] = abi.encode(426);
        configsTemp[7] = abi.encode(427);
        configsTemp[8] = abi.encode(428);
        configsTemp[9] = abi.encode(429);
        configsTemp[10] = abi.encode(430);
        configsTemp[11] = abi.encode(431);
        configsTemp[12] = abi.encode(432);

        configs[0] = configsTemp;

        vm.prank(deployer);
        vm.expectRevert(Error.ARRAY_LENGTH_MISMATCH.selector);
        paymentHelper.batchUpdateRemoteChains(chainIds, configTypes, configs);
    }

    function test_batchUpdateRemoteChains_zeroLen() public {
        uint64[] memory chainIds;
        uint256[][] memory configTypes = new uint256[][](2);

        bytes[][] memory configs = new bytes[][](2);

        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_INPUT_VALUE.selector);
        paymentHelper.batchUpdateRemoteChains(chainIds, configTypes, configs);
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
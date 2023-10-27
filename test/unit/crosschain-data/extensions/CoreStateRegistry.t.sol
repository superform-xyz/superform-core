// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import { Error } from "src/utils/Error.sol";
import "test/utils/ProtocolActions.sol";

contract CoreStateRegistryTest is ProtocolActions {
    uint64 internal chainId = ETH;
    address dstRefundAddress = address(444);

    function setUp() public override {
        super.setUp();
    }

    /// @dev test processPayload reverts with insufficient collateral
    function test_processPayloadRevertingWithoutCollateral() public {
        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        _successfulSingleDeposit(ambIds);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        uint256[] memory amounts = new uint256[](1);
        /// @dev 1e18 after decimal corrections and bridge slippage would give the following value
        amounts[0] = 999_900_000_000_000_000;
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(1, amounts);

        vm.prank(getContract(AVAX, "CoreStateRegistry"));
        MockERC20(getContract(AVAX, "DAI")).transfer(deployer, 999_900_000_000_000_000);

        uint256 nativeAmount = PaymentHelper(getContract(AVAX, "PaymentHelper")).estimateAckCost(1);

        vm.prank(deployer);
        vm.expectRevert(Error.BRIDGE_TOKENS_PENDING.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload{ value: nativeAmount }(1);
    }

    /// @dev test processPayload reverts with insufficient collateral for multi vault case
    function test_processPayloadRevertingWithoutCollateralMultiVault() public {
        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        _successfulMultiDeposit(ambIds);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        uint256[] memory finalAmounts = new uint256[](2);
        finalAmounts[0] = 419;
        finalAmounts[1] = 419;

        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(1, finalAmounts);

        vm.prank(getContract(AVAX, "CoreStateRegistry"));
        MockERC20(getContract(AVAX, "DAI")).transfer(deployer, 840);

        uint256 nativeValue = PaymentHelper(getContract(AVAX, "PaymentHelper")).estimateAckCost(1);

        vm.prank(deployer);
        vm.expectRevert(Error.BRIDGE_TOKENS_PENDING.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload{ value: nativeValue }(1);
    }

    /// @dev test processPayload with just 1 AMB
    function test_processPayloadWithoutReachingQuorum() public {
        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        _successfulSingleDeposit(ambIds);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        vm.expectRevert(Error.INSUFFICIENT_QUORUM.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload(1);
    }

    /// @dev test processPayload without updating deposit payload
    function test_processPayloadWithoutUpdating() public {
        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        _successfulSingleDeposit(ambIds);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        vm.expectRevert(Error.PAYLOAD_NOT_UPDATED.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload(1);
    }

    /// @dev test processPayload without updating deposit payload
    function test_processPayloadForAlreadyProcessedPayload() public {
        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        _successfulSingleDeposit(ambIds);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 999_900_000_000_000_000;
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(1, amounts);

        uint256 nativeValue = PaymentHelper(getContract(AVAX, "PaymentHelper")).estimateAckCost(1);

        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload{ value: nativeValue }(1);

        vm.prank(deployer);
        vm.expectRevert(Error.PAYLOAD_ALREADY_PROCESSED.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload{ value: nativeValue }(1);
    }

    /// @dev test processPayload without updating multi vault deposit payload
    function test_processPayloadWithoutUpdatingMultiVaultDeposit() public {
        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        _successfulMultiDeposit(ambIds);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        vm.expectRevert(Error.PAYLOAD_NOT_UPDATED.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload(1);
    }

    /// @dev test all revert cases with single vault deposit payload update
    function test_updatePayloadSingleVaultDepositRevertCases() public {
        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        _successfulSingleDeposit(ambIds);

        uint256[] memory amounts = new uint256[](1);
        /// @dev 1e18 after decimal corrections and bridge slippage would give the following value
        amounts[0] = 999_900_000_000_000_000;

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        vm.expectRevert(Error.INSUFFICIENT_QUORUM.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(1, amounts);
    }

    /// @dev test all revert cases with single vault withdraw payload update
    function test_updatePayloadSingleVaultWithdrawQuorumCheck() public {
        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        _successfulSingleWithdrawal(ambIds, 0);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);

        bytes[] memory txData = new bytes[](1);
        txData[0] = bytes("");
        vm.expectRevert(Error.INSUFFICIENT_QUORUM.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateWithdrawPayload(1, txData);
    }

    /// @dev test all revert cases with multi vault withdraw payload update
    function test_updatePayloadMultiVaultWithdrawRevertCases() public {
        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        _successfulMultiWithdrawal(ambIds);

        bytes[] memory txData = new bytes[](1);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        vm.expectRevert(Error.INSUFFICIENT_QUORUM.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateWithdrawPayload(1, txData);

        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        vm.expectRevert(Error.DIFFERENT_PAYLOAD_UPDATE_TX_DATA_LENGTH.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateWithdrawPayload(1, txData);

        txData = new bytes[](2);

        address superform = getContract(
            AVAX, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        /// @dev number of superpositions to be burned per withdraw is 1e18, specified in _successfulMultiWithdrawal()
        uint256 actualWithdrawAmount = IBaseForm(superform).previewWithdrawFrom(
            IERC4626(IBaseForm(superform).getVaultAddress()).previewRedeem(1e18)
        );

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(AVAX, "DAI"),
            getContract(AVAX, "DAI"),
            getContract(ETH, "DAI"),
            superform,
            AVAX,
            ETH,
            ETH,
            false,
            deployer,
            uint256(ETH),
            /// @dev amount is 1 less than (actualWithdrawAmount * 0.9) => slippage > 10% => should revert
            ((actualWithdrawAmount * 9) / 10) - 1,
            true,
            /// @dev currently testing with 0 bridge slippage
            0,
            1,
            1,
            1
        );

        txData[0] = _buildLiqBridgeTxData(liqBridgeTxDataArgs, false);
        txData[1] = _buildLiqBridgeTxData(liqBridgeTxDataArgs, false);

        vm.prank(deployer);
        vm.expectRevert(Error.SLIPPAGE_OUT_OF_BOUNDS.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateWithdrawPayload(1, txData);
    }

    /// @dev test all revert cases with multi vault deposit payload update
    function test_updatePayloadMultiVaultDepositRevertCases() public {
        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        _successfulMultiDeposit(ambIds);

        uint256[] memory finalAmounts = new uint256[](1);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        vm.expectRevert(Error.INSUFFICIENT_QUORUM.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(1, finalAmounts);

        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        vm.expectRevert(Error.DIFFERENT_PAYLOAD_UPDATE_AMOUNTS_LENGTH.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(1, finalAmounts);
    }

    /// @dev test revert cases for duplicate proof bridge id
    function test_trySendingMessageThroughDuplicateAMBs() public {
        uint8[] memory ambIds = new uint8[](4);
        ambIds[0] = 1;
        ambIds[1] = 2;
        ambIds[2] = 3;
        ambIds[3] = 2;
        _failingMultiDeposit(ambIds, Error.DUPLICATE_PROOF_BRIDGE_ID.selector);

        ambIds[2] = 2;
        ambIds[3] = 3;
        _failingMultiDeposit(ambIds, Error.DUPLICATE_PROOF_BRIDGE_ID.selector);
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _successfulSingleDeposit(uint8[] memory ambIds) internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            AVAX, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], AVAX);

        address superformRouter = getContract(ETH, "SuperformRouter");

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(AVAX, "DAI"),
            superformRouter,
            ETH,
            AVAX,
            AVAX,
            false,
            getContract(AVAX, "CoreStateRegistry"),
            uint256(AVAX),
            1e18,
            //1e18,
            false,
            /// @dev placeholder value, not used
            1,
            /// @dev assuming same price of DAI on ETH and AVAX for this test
            1,
            1,
            1
        );

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            /// @dev 1e18 after decimal corrections and bridge slippage would give the following value
            999_900_000_000_000_000,
            100,
            false,
            LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), AVAX, 0),
            bytes(""),
            dstRefundAddress,
            bytes("")
        );
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.recordLogs();
        SuperformRouter(payable(superformRouter)).singleXChainSingleVaultDeposit{ value: 2 ether }(
            SingleXChainSingleVaultStateReq(ambIds, AVAX, data)
        );
        vm.stopPrank();

        /// @dev mocks the cross-chain payload delivery
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).helpWithEstimates(
            LZ_ENDPOINTS[AVAX],
            5_000_000,
            /// note: using some max limit
            FORKS[AVAX],
            vm.getRecordedLogs()
        );
    }

    function _successfulSingleWithdrawal(uint8[] memory ambIds, uint256 formImplementationId) internal {
        vm.selectFork(FORKS[ETH]);

        address superform = formImplementationId == 1
            ? getContract(
                AVAX,
                string.concat(
                    "DAI",
                    "ERC4626TimelockMock",
                    "Superform",
                    Strings.toString(FORM_IMPLEMENTATION_IDS[formImplementationId])
                )
            )
            : getContract(
                AVAX,
                string.concat(
                    "DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[formImplementationId])
                )
            );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[formImplementationId], AVAX);
        address superformRouter = getContract(ETH, "SuperformRouter");

        vm.prank(superformRouter);
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingle(deployer, superformId, 1e18);

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

        vm.prank(deployer);

        SuperPositions(getContract(ETH, "SuperPositions")).increaseAllowance(superformRouter, superformId, 1e18);

        vm.prank(deployer);
        vm.recordLogs();

        SuperformRouter(payable(superformRouter)).singleXChainSingleVaultWithdraw{ value: 2 ether }(
            SingleXChainSingleVaultStateReq(ambIds, AVAX, data)
        );

        /// @dev mocks the cross-chain payload delivery
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).helpWithEstimates(
            LZ_ENDPOINTS[AVAX],
            5_000_000,
            /// note: using some max limit
            FORKS[AVAX],
            vm.getRecordedLogs()
        );
    }

    function _successfulMultiDeposit(uint8[] memory ambIds) internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            AVAX, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], AVAX);

        address superformRouter = getContract(ETH, "SuperformRouter");

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId;
        superformIds[1] = superformId;

        uint256[] memory uint256MemArr = new uint256[](2);
        uint256MemArr[0] = 420;
        uint256MemArr[1] = 420;

        LiqRequest[] memory liqReqArr = new LiqRequest[](2);

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(AVAX, "DAI"),
            superformRouter,
            ETH,
            AVAX,
            AVAX,
            false,
            getContract(AVAX, "CoreStateRegistry"),
            uint256(AVAX),
            420,
            //420,
            false,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1
        );

        liqReqArr[0] =
            LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), AVAX, 0);
        liqReqArr[1] = liqReqArr[0];

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds, uint256MemArr, uint256MemArr, new bool[](2), liqReqArr, bytes(""), dstRefundAddress, bytes("")
        );
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.recordLogs();
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(ambIds, AVAX, data)
        );
        vm.stopPrank();

        /// @dev mocks the cross-chain payload delivery
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).helpWithEstimates(
            LZ_ENDPOINTS[AVAX],
            5_000_000,
            /// note: using some max limit
            FORKS[AVAX],
            vm.getRecordedLogs()
        );
    }

    function _failingMultiDeposit(uint8[] memory ambIds, bytes4 errorSelector) internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            AVAX, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], AVAX);

        address superformRouter = getContract(ETH, "SuperformRouter");

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId;
        superformIds[1] = superformId;

        uint256[] memory uint256MemArr = new uint256[](2);
        uint256MemArr[0] = 420;
        uint256MemArr[1] = 420;

        LiqRequest[] memory liqReqArr = new LiqRequest[](2);

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(AVAX, "DAI"),
            superformRouter,
            ETH,
            AVAX,
            AVAX,
            false,
            getContract(AVAX, "CoreStateRegistry"),
            uint256(AVAX),
            420,
            //420,
            false,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1
        );

        liqReqArr[0] =
            LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), AVAX, 0);
        liqReqArr[1] = liqReqArr[0];

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds, uint256MemArr, uint256MemArr, new bool[](2), liqReqArr, bytes(""), dstRefundAddress, bytes("")
        );
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.expectRevert(errorSelector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(ambIds, AVAX, data)
        );
        vm.stopPrank();
    }

    function _successfulMultiWithdrawal(uint8[] memory ambIds) internal {
        vm.selectFork(FORKS[ETH]);

        address superform = getContract(
            AVAX, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], AVAX);
        address superformRouter = getContract(ETH, "SuperformRouter");

        vm.prank(superformRouter);
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingle(deployer, superformId, 2e18);

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId;
        superformIds[1] = superformId;

        uint256[] memory amountArr = new uint256[](2);
        amountArr[0] = 1e18;
        amountArr[1] = 1e18;

        LiqRequest[] memory liqReqArr = new LiqRequest[](2);
        liqReqArr[0] = LiqRequest(1, bytes(""), getContract(AVAX, "DAI"), ETH, 0);
        liqReqArr[1] = liqReqArr[0];

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds, amountArr, maxSlippages, new bool[](2), liqReqArr, bytes(""), dstRefundAddress, bytes("")
        );

        vm.prank(deployer);

        SuperPositions(getContract(ETH, "SuperPositions")).increaseAllowance(superformRouter, superformId, 2e18);
        vm.prank(deployer);
        vm.recordLogs();

        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultWithdraw{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(ambIds, AVAX, data)
        );

        /// @dev mocks the cross-chain payload delivery
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).helpWithEstimates(
            LZ_ENDPOINTS[AVAX],
            50_000_000,
            /// note: using some max limit
            FORKS[AVAX],
            vm.getRecordedLogs()
        );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import { ICoreStateRegistry } from "src/interfaces/ICoreStateRegistry.sol";
import "test/utils/ProtocolActions.sol";

contract CoreStateRegistryTest is ProtocolActions {
    uint64 internal chainId = ETH;
    address receiverAddress = address(444);

    function setUp() public override {
        super.setUp();
    }

    /// @dev test processPayload reverts with insufficient asset
    function test_processPayloadRevertingWithoutAsset() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulSingleDeposit(ambIds_);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        uint256[] memory amounts = new uint256[](1);
        address[] memory bridgedTokens = new address[](1);
        /// @dev 1e18 after decimal corrections and bridge slippage would give the following value
        amounts[0] = 999_900_000_000_000_000;
        bridgedTokens[0] = getContract(AVAX, "DAI");

        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
            1, bridgedTokens, amounts
        );

        vm.prank(getContract(AVAX, "CoreStateRegistry"));
        MockERC20(getContract(AVAX, "DAI")).transfer(deployer, 999_900_000_000_000_000);

        vm.expectRevert(Error.INVALID_PAYLOAD_ID.selector);
        PaymentHelper(getContract(AVAX, "PaymentHelper")).estimateAckCost(100);

        uint256 nativeAmount = PaymentHelper(getContract(AVAX, "PaymentHelper")).estimateAckCost(1);

        vm.prank(deployer);
        vm.expectRevert(Error.BRIDGE_TOKENS_PENDING.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload{ value: nativeAmount }(1);
    }

    /// @dev test processPayload reverts with insufficient asset for multi vault case
    function test_processPayloadRevertingWithoutAssetMultiVault() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulMultiDeposit(ambIds_);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        uint256[] memory finalAmounts = new uint256[](2);
        finalAmounts[0] = 0;
        finalAmounts[1] = 419;

        address[] memory bridgedTokens = new address[](2);
        bridgedTokens[0] = getContract(AVAX, "DAI");
        bridgedTokens[1] = getContract(AVAX, "DAI");

        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_AMOUNT.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
            1, bridgedTokens, finalAmounts
        );

        finalAmounts[0] = 419;
        finalAmounts[1] = 419;

        vm.prank(deployer);
        bridgedTokens[0] = getContract(AVAX, "WETH");
        vm.expectRevert(Error.INVALID_UPDATE_FINAL_TOKEN.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
            1, bridgedTokens, finalAmounts
        );

        vm.prank(deployer);
        bridgedTokens[0] = getContract(AVAX, "DAI");
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
            1, bridgedTokens, finalAmounts
        );

        vm.prank(getContract(AVAX, "CoreStateRegistry"));
        MockERC20(getContract(AVAX, "DAI")).transfer(deployer, 840);

        uint256 nativeValue = PaymentHelper(getContract(AVAX, "PaymentHelper")).estimateAckCost(1);

        vm.prank(deployer);
        vm.expectRevert(Error.BRIDGE_TOKENS_PENDING.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload{ value: nativeValue }(1);

        vm.prank(deployer);
        MockERC20(getContract(AVAX, "DAI")).transfer(getContract(AVAX, "CoreStateRegistry"), 838);

        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload{ value: nativeValue }(1);
    }

    /// @dev this test ensures that if a superform update failed because of slippage in 2 of 4 vaults
    /// @dev that the other 2 get processed and the loop doesn't become infinite
    function test_processPayload_loop() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            AVAX, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], AVAX);

        address superformRouter = getContract(ETH, "SuperformRouter");

        uint256[] memory superformIds = new uint256[](4);
        superformIds[0] = superformId;
        superformIds[1] = superformId;
        superformIds[2] = superformId;
        superformIds[3] = superformId;

        uint256[] memory uint256MemArr = new uint256[](4);
        uint256MemArr[0] = 420;
        uint256MemArr[1] = 420;
        uint256MemArr[2] = 420;
        uint256MemArr[3] = 420;

        LiqRequest[] memory liqReqArr = new LiqRequest[](4);

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

        liqReqArr[0] = LiqRequest(
            _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, AVAX, 0
        );
        liqReqArr[1] = liqReqArr[0];
        liqReqArr[2] = liqReqArr[0];
        liqReqArr[3] = liqReqArr[0];

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            uint256MemArr,
            uint256MemArr,
            uint256MemArr,
            liqReqArr,
            bytes(""),
            new bool[](4),
            new bool[](4),
            receiverAddress,
            receiverAddress,
            bytes("")
        );
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.recordLogs();
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(ambIds_, AVAX, data)
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
        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        uint256[] memory finalAmounts = new uint256[](4);
        finalAmounts[0] = 419;
        finalAmounts[1] = 100;
        finalAmounts[2] = 419;
        finalAmounts[3] = 100;

        address[] memory bridgedTokens = new address[](4);
        bridgedTokens[0] = getContract(AVAX, "DAI");
        bridgedTokens[1] = getContract(AVAX, "DAI");
        bridgedTokens[2] = getContract(AVAX, "DAI");
        bridgedTokens[3] = getContract(AVAX, "DAI");

        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
            1, bridgedTokens, finalAmounts
        );
        uint256 nativeValue = PaymentHelper(getContract(AVAX, "PaymentHelper")).estimateAckCost(1);

        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload{ value: nativeValue }(1);
    }

    /// @dev test processPayload with just 1 AMB
    function test_processPayloadWithoutReachingQuorum() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulSingleDeposit(ambIds_);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        vm.expectRevert(Error.INSUFFICIENT_QUORUM.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload(1);
    }

    /// @dev test processPayload without updating deposit payload
    function test_processPayloadWithoutUpdating() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulSingleDeposit(ambIds_);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        vm.expectRevert(Error.PAYLOAD_NOT_UPDATED.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload(1);
    }

    /// @dev test updateDepositPayload with zero final token input
    function test_updateDepositPayloadWithZeroFinalToken() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulSingleDeposit(ambIds_);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10_000;

        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_FINAL_TOKEN.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
            1, new address[](1), amounts
        );
    }

    /// @dev test processPayload without updating deposit payload
    function test_processPayloadForAlreadyProcessedPayload() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulSingleDeposit(ambIds_);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 999_900_000_000_000_000;

        address[] memory bridgedTokens = new address[](1);
        bridgedTokens[0] = getContract(AVAX, "WETH");
        vm.expectRevert(Error.INVALID_UPDATE_FINAL_TOKEN.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
            1, bridgedTokens, amounts
        );

        vm.prank(deployer);
        bridgedTokens[0] = getContract(AVAX, "DAI");
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
            1, bridgedTokens, amounts
        );

        uint256 nativeValue = PaymentHelper(getContract(AVAX, "PaymentHelper")).estimateAckCost(1);

        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload{ value: nativeValue }(1);

        vm.prank(deployer);
        vm.expectRevert(Error.PAYLOAD_ALREADY_PROCESSED.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload{ value: nativeValue }(1);
    }

    /// @dev test processPayload without updating deposit payload
    function test_processPayload_moveToFailedDeposit() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulSingleDeposit(ambIds_);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 2222;

        address[] memory bridgedTokens = new address[](1);
        bridgedTokens[0] = getContract(AVAX, "DAI");

        vm.prank(deployer);
        vm.expectEmit();
        // We emit the event we expect to see.
        emit ICoreStateRegistry.FailedXChainDeposits(1);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
            1, bridgedTokens, amounts
        );
    }

    /// @dev test processPayload without updating multi vault deposit payload
    function test_processPayloadWithoutUpdatingMultiVaultDeposit() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulMultiDeposit(ambIds_);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        vm.expectRevert(Error.PAYLOAD_NOT_UPDATED.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload(1);
    }

    /// @dev test all revert cases with single vault deposit payload update
    function test_updatePayloadSingleVaultDepositRevertCases() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulSingleDeposit(ambIds_);
        vm.selectFork(FORKS[AVAX]);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;

        address[] memory bridgedTokens = new address[](1);
        bridgedTokens[0] = getContract(AVAX, "DAI");

        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_AMOUNT.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
            1, bridgedTokens, amounts
        );

        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 2);

        /// @dev 1e18 after decimal corrections and bridge slippage would give the following value
        amounts[0] = 999_900_000_000_000_000;

        vm.prank(deployer);
        vm.expectRevert(Error.INSUFFICIENT_QUORUM.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
            1, bridgedTokens, amounts
        );
    }

    /// @dev test all revert cases with single vault withdraw payload update
    function test_updatePayloadSingleVaultWithdrawQuorumCheck() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulSingleWithdrawal(ambIds_, 0);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);

        bytes[] memory txData = new bytes[](1);
        txData[0] = bytes("");
        vm.expectRevert(Error.INSUFFICIENT_QUORUM.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateWithdrawPayload(1, txData);
    }

    /// @dev test all revert cases with multi vault withdraw payload update
    function test_updatePayloadMultiVaultWithdrawRevertCases() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulMultiWithdrawal(ambIds_);

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
            receiverAddress,
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
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulMultiDeposit(ambIds_);

        uint256[] memory finalAmounts = new uint256[](1);
        address[] memory bridgedTokens = new address[](1);

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        vm.expectRevert(Error.INSUFFICIENT_QUORUM.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
            1, bridgedTokens, finalAmounts
        );

        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        vm.expectRevert(Error.DIFFERENT_PAYLOAD_UPDATE_AMOUNTS_LENGTH.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
            1, bridgedTokens, finalAmounts
        );
    }

    /// @dev test revert cases for duplicate proof bridge id
    function test_trySendingMessageThroughDuplicateAMBs() public {
        uint8[] memory ambIds_ = new uint8[](4);
        ambIds_[0] = 1;
        ambIds_[1] = 2;
        ambIds_[2] = 3;
        ambIds_[3] = 2;
        _failingMultiDeposit(ambIds_, Error.INVALID_PROOF_BRIDGE_IDS.selector);

        ambIds_[2] = 2;
        ambIds_[3] = 3;
        _failingMultiDeposit(ambIds_, Error.INVALID_PROOF_BRIDGE_IDS.selector);
    }

    function test_processPayload_reverts() public {
        vm.selectFork(FORKS[ETH]);
        vm.prank(getContract(ETH, "LayerzeroImplementation"));
        CoreStateRegistry(getContract(ETH, "CoreStateRegistry")).receivePayload(
            POLY,
            abi.encode(AMBMessage(DataLib.packTxInfo(1, 4, 1, 1, address(420), uint64(137)), abi.encode(ambIds, "")))
        );

        vm.prank(deployer);
        SuperRegistry(getContract(ETH, "SuperRegistry")).setRequiredMessagingQuorum(POLY, 0);

        vm.prank(deployer);
        vm.expectRevert(Error.INVALID_PAYLOAD_TYPE.selector);
        CoreStateRegistry(getContract(ETH, "CoreStateRegistry")).processPayload(1);

        vm.prank(address(0x777));
        vm.expectRevert(
            abi.encodeWithSelector(
                Error.NOT_PRIVILEGED_CALLER.selector, keccak256("CORE_STATE_REGISTRY_PROCESSOR_ROLE")
            )
        );
        CoreStateRegistry(getContract(ETH, "CoreStateRegistry")).processPayload(1);

        vm.prank(deployer);
        vm.expectRevert(Error.INVALID_PAYLOAD_ID.selector);
        CoreStateRegistry(getContract(ETH, "CoreStateRegistry")).processPayload(3);
    }

    function test_multiWithdraw_inexistentSuperformId() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;
        uint256 superformId = _successfulMultiWithdrawal(ambIds_);

        vm.selectFork(FORKS[AVAX]);
        vm.mockCall(
            getContract(AVAX, "SuperformFactory"),
            abi.encodeWithSelector(
                SuperformFactory(getContract(AVAX, "SuperformFactory")).isSuperform.selector, superformId
            ),
            abi.encode(false)
        );

        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        vm.expectRevert(Error.SUPERFORM_ID_NONEXISTENT.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload(1);

        vm.clearMockedCalls();
    }

    function test_singleWithdraw_inexistentSuperformId() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;
        uint256 superformId = _successfulSingleWithdrawal(ambIds_, 0);

        vm.selectFork(FORKS[AVAX]);
        vm.mockCall(
            getContract(AVAX, "SuperformFactory"),
            abi.encodeWithSelector(
                SuperformFactory(getContract(AVAX, "SuperformFactory")).isSuperform.selector, superformId
            ),
            abi.encode(false)
        );

        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        vm.expectRevert(Error.SUPERFORM_ID_NONEXISTENT.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload(1);

        vm.clearMockedCalls();
    }

    /// @dev this test highlights a payload that is failed and cannot be rescued
    function test_multiDeposit_inexistentSuperformId_PAYLOAD_ALREADY_PROCESSED() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;
        uint256 superformId = _successfulMultiDeposit(ambIds_);

        uint256[] memory finalAmounts = new uint256[](2);
        finalAmounts[0] = 420;
        finalAmounts[1] = 420;

        address[] memory bridgedTokens = new address[](2);
        bridgedTokens[0] = getContract(AVAX, "DAI");
        bridgedTokens[1] = getContract(AVAX, "DAI");

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.mockCall(
            getContract(AVAX, "SuperformFactory"),
            abi.encodeWithSelector(
                SuperformFactory(getContract(AVAX, "SuperformFactory")).isSuperform.selector, superformId
            ),
            abi.encode(false)
        );
        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
            1, bridgedTokens, finalAmounts
        );

        vm.prank(deployer);
        vm.expectRevert(Error.PAYLOAD_ALREADY_PROCESSED.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload(1);

        vm.clearMockedCalls();
    }

    /// @dev this test highlights a payload that is failed and cannot be rescued
    function test_singleDeposit_inexistentSuperformId_PAYLOAD_ALREADY_PROCESSED() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;
        uint256 superformId = _successfulSingleDeposit(ambIds_);

        uint256[] memory finalAmounts = new uint256[](1);
        finalAmounts[0] = 999_900_000_000_000_000;

        address[] memory bridgedTokens = new address[](1);
        bridgedTokens[0] = getContract(AVAX, "DAI");

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.mockCall(
            getContract(AVAX, "SuperformFactory"),
            abi.encodeWithSelector(
                SuperformFactory(getContract(AVAX, "SuperformFactory")).isSuperform.selector, superformId
            ),
            abi.encode(false)
        );

        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
            1, bridgedTokens, finalAmounts
        );

        vm.prank(deployer);
        vm.expectRevert(Error.PAYLOAD_ALREADY_PROCESSED.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload(1);

        vm.clearMockedCalls();
    }

    function test_ackGasCost_single_paymentHelperComparison() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulSingleDeposit(ambIds_);

        vm.selectFork(FORKS[AVAX]);

        uint256 defaultEstimate =
            PaymentHelper(getContract(AVAX, "PaymentHelper")).estimateAckCostDefault(false, ambIds_, ETH);

        uint256 realEstimate = PaymentHelper(getContract(AVAX, "PaymentHelper")).estimateAckCost(1);

        console.log("defaultEstimate: %s", defaultEstimate);
        console.log("realEstimate: %s", realEstimate);

        assertEq(realEstimate, defaultEstimate);

        uint256 defaultEstimateNativeSrc =
            PaymentHelper(getContract(AVAX, "PaymentHelper")).estimateAckCostDefaultNativeSource(false, ambIds_, ETH);

        console.log("defaultEstimateNativeSrc: %s", defaultEstimateNativeSrc);
    }

    function test_estimateWithNativeTokenPriceAsZero() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulMultiDeposit(ambIds_);
        vm.selectFork(FORKS[AVAX]);

        /// @dev setting native token price as zero
        vm.prank(deployer);
        PaymentHelper(getContract(AVAX, "PaymentHelper")).updateRemoteChain(AVAX, 1, abi.encode(address(0)));

        vm.prank(deployer);
        PaymentHelper(getContract(AVAX, "PaymentHelper")).updateRemoteChain(AVAX, 7, abi.encode(0));

        assertEq(
            PaymentHelper(getContract(AVAX, "PaymentHelper")).estimateAckCostDefaultNativeSource(true, ambIds_, ETH), 0
        );
    }

    function test_ackGasCost_multi_paymentHelperComparison() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulMultiDeposit(ambIds_);

        vm.selectFork(FORKS[AVAX]);

        uint256 defaultEstimate =
            PaymentHelper(getContract(AVAX, "PaymentHelper")).estimateAckCostDefault(true, ambIds_, ETH);

        uint256 realEstimate = PaymentHelper(getContract(AVAX, "PaymentHelper")).estimateAckCost(1);

        console.log("defaultEstimate: %s", defaultEstimate);
        console.log("realEstimate: %s", realEstimate);

        assertLe(realEstimate, defaultEstimate);

        uint256 defaultEstimateNativeSrc =
            PaymentHelper(getContract(AVAX, "PaymentHelper")).estimateAckCostDefaultNativeSource(true, ambIds_, ETH);

        console.log("defaultEstimateNativeSrc: %s", defaultEstimateNativeSrc);
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _successfulSingleDeposit(uint8[] memory ambIds_) internal returns (uint256 superformId) {
        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            AVAX, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], AVAX);

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
            999_900_000_000_000_000,
            100,
            LiqRequest(
                _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, AVAX, 0
            ),
            bytes(""),
            false,
            false,
            receiverAddress,
            receiverAddress,
            bytes("")
        );
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.recordLogs();
        SuperformRouter(payable(superformRouter)).singleXChainSingleVaultDeposit{ value: 2 ether }(
            SingleXChainSingleVaultStateReq(ambIds_, AVAX, data)
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

    function _successfulSingleWithdrawal(
        uint8[] memory ambIds_,
        uint256 formImplementationId
    )
        internal
        returns (uint256 superformId)
    {
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

        superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[formImplementationId], AVAX);
        address superformRouter = getContract(ETH, "SuperformRouter");

        vm.prank(superformRouter);
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingle(deployer, superformId, 1e18);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest(bytes(""), getContract(ETH, "DAI"), address(0), 1, ETH, 0),
            bytes(""),
            false,
            false,
            receiverAddress,
            receiverAddress,
            bytes("")
        );

        vm.prank(deployer);

        SuperPositions(getContract(ETH, "SuperPositions")).increaseAllowance(superformRouter, superformId, 1e18);

        vm.prank(deployer);
        vm.recordLogs();

        SuperformRouter(payable(superformRouter)).singleXChainSingleVaultWithdraw{ value: 2 ether }(
            SingleXChainSingleVaultStateReq(ambIds_, AVAX, data)
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

    function _successfulMultiDeposit(uint8[] memory ambIds_) internal returns (uint256 superformId) {
        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            AVAX, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], AVAX);

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

        liqReqArr[0] = LiqRequest(
            _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, AVAX, 0
        );
        liqReqArr[1] = liqReqArr[0];

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            uint256MemArr,
            uint256MemArr,
            uint256MemArr,
            liqReqArr,
            bytes(""),
            new bool[](2),
            new bool[](2),
            receiverAddress,
            receiverAddress,
            bytes("")
        );
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.recordLogs();
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(ambIds_, AVAX, data)
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

    function test_FailingIndex1VaultAllDstSwap() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulMultiDepositWithDstSwapShowcase(ambIds_, true, true);
    }

    function test_FailingIndex1VaultOneDstSwap() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        /// @notice, this is similar to the issue with
        /// https://dashboard.tenderly.co/superform/v1/simulator/eaa8d796-81df-45d2-9cc9-d7bfc958d947

        _successfulMultiDepositWithDstSwapShowcase(ambIds_, false, true);
    }

    function test_DstSwapIndex0DirectToCSRIndex1() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        /// @notice, this is similar to the issue with
        /// https://dashboard.tenderly.co/superform/v1/simulator/eaa8d796-81df-45d2-9cc9-d7bfc958d947

        _successfulMultiDepositWithDstSwapShowcase(ambIds_, false, false);
    }

    struct MultiDepositDstSwapSpecialCaseVars {
        uint256[] superformIds;
        uint256[] amounts;
        uint256[] uint256MemArr;
        LiqRequest[] liqReqArr;
        bool[] hasDstSwaps;
        bool[] hasSrcSwaps;
        address superform;
        address superformRouter;
        address externalToken;
        address underlyingToken1;
        address underlyingToken2;
        address interimOrUnderlyingDstToken1;
        address interimToken2;
        int256 USDPerExternalToken;
        int256 USDPerUnderlyingToken1;
        int256 USDPerUnderlyingToken2;
        int256 USDPerInterimOrUnderlyingDstToken1;
        int256 USDPerInterimToken2;
        bytes txDataPasses;
        bytes txDataFails;
        uint256[] indices;
        uint8[] bridgeIds_;
        bytes[] txDataArr;
        address[] interimTokens;
        address[] finalTokens;
        uint256 wethBalOfSwapper;
    }

    function _successfulMultiDepositWithDstSwapShowcase(
        uint8[] memory ambIds_,
        bool vaultWithDstSwap,
        bool isFailingIndex1Vault
    )
        internal
        returns (uint256 superformId)
    {
        MultiDepositDstSwapSpecialCaseVars memory v;
        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        v.superform = getContract(
            AVAX, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        superformId = DataLib.packSuperform(v.superform, FORM_IMPLEMENTATION_IDS[0], AVAX);

        v.superformRouter = getContract(ETH, "SuperformRouter");

        v.superformIds = new uint256[](2);
        v.superformIds[0] = superformId;
        v.superformIds[1] = superformId;

        v.uint256MemArr = new uint256[](2);
        v.uint256MemArr[0] = 420;
        v.uint256MemArr[1] = 420;

        v.amounts = new uint256[](2);

        /// this should fail as it is larger than the balance difference (result of swapping 0.1 WETH (1e17 in in
        /// txDataFails) to DAI )
        v.amounts[0] = isFailingIndex1Vault ? 419_972_359 : 419_950_757_613_293_461_130;

        v.amounts[1] = isFailingIndex1Vault ? 1e21 : 419_972_359;

        v.externalToken = getContract(ETH, "DAI");
        v.underlyingToken1 = getContract(ETH, "DAI");
        v.underlyingToken2 = getContract(ETH, "DAI");
        v.interimOrUnderlyingDstToken1 = vaultWithDstSwap ? getContract(AVAX, "USDC") : getContract(AVAX, "DAI");
        v.interimToken2 = getContract(AVAX, "WETH");

        vm.selectFork(FORKS[ETH]);

        (, v.USDPerExternalToken,,,) = AggregatorV3Interface(tokenPriceFeeds[ETH][v.externalToken]).latestRoundData();
        (, v.USDPerUnderlyingToken1,,,) =
            AggregatorV3Interface(tokenPriceFeeds[ETH][v.underlyingToken1]).latestRoundData();
        (, v.USDPerUnderlyingToken2,,,) =
            AggregatorV3Interface(tokenPriceFeeds[ETH][v.underlyingToken2]).latestRoundData();

        vm.selectFork(FORKS[AVAX]);

        (, v.USDPerInterimOrUnderlyingDstToken1,,,) =
            AggregatorV3Interface(tokenPriceFeeds[AVAX][v.interimOrUnderlyingDstToken1]).latestRoundData();
        (, v.USDPerInterimToken2,,,) = AggregatorV3Interface(tokenPriceFeeds[AVAX][v.interimToken2]).latestRoundData();

        vm.selectFork(FORKS[ETH]);

        LiqBridgeTxDataArgs memory liqBridgeTxData1 = LiqBridgeTxDataArgs(
            1,
            v.externalToken,
            v.externalToken,
            v.interimOrUnderlyingDstToken1,
            v.superformRouter,
            ETH,
            AVAX,
            AVAX,
            vaultWithDstSwap,
            vaultWithDstSwap ? getContract(AVAX, "DstSwapper") : getContract(AVAX, "CoreStateRegistry"),
            uint256(AVAX),
            420e18,
            //420,
            false,
            /// @dev placeholder value, not used
            0,
            uint256(v.USDPerExternalToken),
            uint256(v.USDPerInterimOrUnderlyingDstToken1),
            uint256(v.USDPerUnderlyingToken1)
        );

        LiqBridgeTxDataArgs memory liqBridgeTxData2 = LiqBridgeTxDataArgs(
            1,
            v.externalToken,
            v.externalToken,
            v.interimToken2,
            v.superformRouter,
            ETH,
            AVAX,
            AVAX,
            true,
            getContract(AVAX, "DstSwapper"),
            uint256(AVAX),
            420e18,
            //420,
            false,
            /// @dev placeholder value, not used
            0,
            uint256(v.USDPerExternalToken),
            uint256(v.USDPerInterimToken2),
            uint256(v.USDPerUnderlyingToken2)
        );
        v.liqReqArr = new LiqRequest[](2);
        LiqRequest memory liqRequest1 = LiqRequest(
            _buildLiqBridgeTxData(liqBridgeTxData1, false),
            v.externalToken,
            vaultWithDstSwap ? v.interimOrUnderlyingDstToken1 : address(0),
            1,
            AVAX,
            0
        );

        LiqRequest memory liqRequest2 =
            LiqRequest(_buildLiqBridgeTxData(liqBridgeTxData2, false), v.externalToken, v.interimToken2, 1, AVAX, 0);

        /// @notice interim token will be address 0 anyway if not dstSwap (superRouter overrides)
        v.liqReqArr[0] = isFailingIndex1Vault ? liqRequest1 : liqRequest2;

        v.liqReqArr[1] = isFailingIndex1Vault ? liqRequest2 : liqRequest1;

        v.hasDstSwaps = new bool[](2);
        v.hasDstSwaps[0] = isFailingIndex1Vault ? vaultWithDstSwap : true;
        v.hasDstSwaps[1] = isFailingIndex1Vault ? true : vaultWithDstSwap;

        MultiVaultSFData memory data = MultiVaultSFData(
            v.superformIds,
            v.amounts,
            v.uint256MemArr,
            v.uint256MemArr,
            v.liqReqArr,
            bytes(""),
            v.hasDstSwaps,
            new bool[](2),
            receiverAddress,
            receiverAddress,
            bytes("")
        );
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(v.superformRouter, 1000e18);

        vm.recordLogs();
        SuperformRouter(payable(v.superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(ambIds_, AVAX, data)
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
        vm.selectFork(FORKS[AVAX]);

        if (vaultWithDstSwap && isFailingIndex1Vault) {
            console.log(
                "USDC bal of dstSwapper:",
                IERC20(v.interimOrUnderlyingDstToken1).balanceOf(getContract(AVAX, "DstSwapper"))
            );
            v.wethBalOfSwapper = IERC20(v.interimToken2).balanceOf(getContract(AVAX, "DstSwapper"));
            console.log("WETH bal of dstSwapper:", IERC20(v.interimToken2).balanceOf(getContract(AVAX, "DstSwapper")));
            v.txDataPasses = _buildLiqBridgeTxDataDstSwap(
                1,
                v.interimOrUnderlyingDstToken1,
                getContract(AVAX, "DAI"),
                getContract(AVAX, "DstSwapper"),
                AVAX,
                419_972_359,
                0
            );

            v.txDataFails = _buildLiqBridgeTxDataDstSwap(
                1, v.interimToken2, getContract(AVAX, "DAI"), getContract(AVAX, "DstSwapper"), AVAX, 1e17, 0
            );

            v.indices = new uint256[](2);
            v.indices[0] = 0;
            v.indices[1] = 1;

            v.bridgeIds_ = new uint8[](2);
            v.bridgeIds_[0] = 1;
            v.bridgeIds_[1] = 1;

            v.txDataArr = new bytes[](2);
            v.txDataArr[0] = v.txDataPasses;
            v.txDataArr[1] = v.txDataFails;

            /// @dev first this calls batchProcessTx with both the index that would pass and the one that would fail
            vm.prank(deployer);
            vm.expectRevert(Error.SLIPPAGE_OUT_OF_BOUNDS.selector);
            DstSwapper(payable(getContract(AVAX, "DstSwapper"))).batchProcessTx(1, v.indices, v.bridgeIds_, v.txDataArr);

            v.indices = new uint256[](1);
            v.indices[0] = 0;

            v.bridgeIds_ = new uint8[](1);
            v.bridgeIds_[0] = 1;

            v.txDataArr = new bytes[](1);
            v.txDataArr[0] = v.txDataPasses;

            /// @dev then calls just batchProcessTx with one that will pass
            vm.prank(deployer);
            DstSwapper(payable(getContract(AVAX, "DstSwapper"))).batchProcessTx(1, v.indices, v.bridgeIds_, v.txDataArr);

            v.indices = new uint256[](1);
            v.indices[0] = 1;

            v.interimTokens = new address[](1);
            v.interimTokens[0] = v.interimToken2;

            v.amounts = new uint256[](1);
            v.amounts[0] = v.wethBalOfSwapper;

            /// @dev try to call batchUpdateFailedTx, assert that it will fail due to indexes issue!
            vm.prank(deployer);
            vm.expectRevert(stdError.indexOOBError);
            DstSwapper(payable(getContract(AVAX, "DstSwapper"))).batchUpdateFailedTx(
                1, v.indices, v.interimTokens, v.amounts
            );

            /// @dev assert that it is possible to recover from this situation by marking index 0 as failed, although it
            /// was processed to csr earlier
            /// WARNING: This is only possible because all were DST swap so indexes are cleanly passed insided
            /// dstSwapper and the bug is avoided
            v.indices = new uint256[](2);
            v.indices[0] = 0;
            v.indices[1] = 1;

            v.interimTokens = new address[](2);
            v.interimTokens[0] = v.interimOrUnderlyingDstToken1;
            v.interimTokens[1] = v.interimToken2;

            /// @dev mark index 0 with amount as failed 1 (symbolic value)
            v.amounts = new uint256[](2);
            v.amounts[0] = 1;
            v.amounts[1] = v.wethBalOfSwapper;

            /// @dev Potential Problem: How to grab this balance and transfer it
            /// @dev ALWAYS have to have a minimum of 1 for this to work (will be lost)
            vm.prank(deployer);
            IERC20(v.interimOrUnderlyingDstToken1).transfer(getContract(AVAX, "DstSwapper"), 1);

            /// @dev try to call batchUpdateFailedTx, assert that it will pass
            vm.prank(deployer);
            DstSwapper(payable(getContract(AVAX, "DstSwapper"))).batchUpdateFailedTx(
                1, v.indices, v.interimTokens, v.amounts
            );

            /// @dev try performing updateDeposit and assert that index 0 will succeed and index 1 will go to failed
            /// queue
            v.finalTokens = new address[](2);
            v.finalTokens[0] = getContract(AVAX, "DAI");
            v.finalTokens[1] = v.interimToken2;

            v.amounts[0] = 419_972_359;
            v.amounts[1] = v.wethBalOfSwapper;

            vm.prank(deployer);
            SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

            vm.prank(deployer);
            CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
                1, v.finalTokens, v.amounts
            );

            /// @dev assert only 1 superform is in failed deposit
            (uint256[] memory failedSuperFormIds,,) =
                CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).getFailedDeposits(1);

            assertEq(failedSuperFormIds.length, 1);

            /// @dev check that propose / rescue queue works just for the one that failed
            v.amounts = new uint256[](1);
            v.amounts[0] = v.wethBalOfSwapper;

            vm.prank(deployer);
            CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).proposeRescueFailedDeposits(1, v.amounts);

            vm.warp(block.timestamp + 2 days);
            vm.prank(deployer);
            CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).finalizeRescueFailedDeposits(1);
            uint256 nativeFee = PaymentHelper(getContract(ETH, "PaymentHelper")).estimateAckCost(1);

            /// @dev check that processing works for the one that passed
            vm.prank(deployer);
            CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload{ value: nativeFee }(1);

            assertGt(IERC20(IBaseForm(v.superform).getVaultAddress()).balanceOf(v.superform), 0);
        } else if (!vaultWithDstSwap && isFailingIndex1Vault) {
            v.wethBalOfSwapper = IERC20(v.interimToken2).balanceOf(getContract(AVAX, "DstSwapper"));
            console.log("WETH bal of dstSwapper:", IERC20(v.interimToken2).balanceOf(getContract(AVAX, "DstSwapper")));

            v.txDataFails = _buildLiqBridgeTxDataDstSwap(
                1, v.interimToken2, getContract(AVAX, "DAI"), getContract(AVAX, "DstSwapper"), AVAX, 1e17, 0
            );

            v.indices = new uint256[](1);
            v.indices[0] = 1;

            v.bridgeIds_ = new uint8[](1);
            v.bridgeIds_[0] = 1;

            v.txDataArr = new bytes[](1);
            v.txDataArr[0] = v.txDataFails;

            /// @dev calling batchProcessTx with the problematic txData
            vm.prank(deployer);
            vm.expectRevert(Error.SLIPPAGE_OUT_OF_BOUNDS.selector);
            DstSwapper(payable(getContract(AVAX, "DstSwapper"))).batchProcessTx(1, v.indices, v.bridgeIds_, v.txDataArr);

            v.indices = new uint256[](1);
            v.indices[0] = 1;

            v.interimTokens = new address[](1);
            v.interimTokens[0] = v.interimToken2;

            v.amounts = new uint256[](1);
            v.amounts[0] = v.wethBalOfSwapper;

            /// @dev try to call batchUpdateFailedTx, assert that it will fail due to indexes issue!
            vm.prank(deployer);
            vm.expectRevert(stdError.indexOOBError);
            DstSwapper(payable(getContract(AVAX, "DstSwapper"))).batchUpdateFailedTx(
                1, v.indices, v.interimTokens, v.amounts
            );

            /// @dev assert that it is impossible to recover from this  due to the fact that the interimToken was not
            /// set
            v.indices = new uint256[](2);
            v.indices[0] = 0;
            v.indices[1] = 1;

            v.interimTokens = new address[](2);
            v.interimTokens[0] = v.interimOrUnderlyingDstToken1;
            /// DAI
            v.interimTokens[1] = v.interimToken2;

            /// @dev mark index 0 with amount as failed 1 (symbolic value)
            v.amounts = new uint256[](2);
            v.amounts[0] = 1;
            v.amounts[1] = v.wethBalOfSwapper;

            /// @dev try to call batchUpdateFailedTx, assert that it will fail and this will be impossible to recover
            /// due to
            /// INVALID_INTERIM_TOKEN
            vm.prank(deployer);
            vm.expectRevert(Error.INVALID_INTERIM_TOKEN.selector);
            DstSwapper(payable(getContract(AVAX, "DstSwapper"))).batchUpdateFailedTx(
                1, v.indices, v.interimTokens, v.amounts
            );

            /// @dev do update deposit to assert it is impossible to continue
            v.finalTokens = new address[](2);
            v.finalTokens[0] = getContract(AVAX, "DAI");
            v.finalTokens[1] = v.interimToken2;

            v.amounts[0] = 419_972_359;
            v.amounts[1] = v.wethBalOfSwapper;

            vm.prank(deployer);
            SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

            /// @dev it cannot proceed because nothing was marked as failed
            vm.prank(deployer);
            vm.expectRevert(Error.INVALID_DST_SWAPPER_FAILED_SWAP.selector);
            CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
                1, v.finalTokens, v.amounts
            );
        } else if (!vaultWithDstSwap && !isFailingIndex1Vault) {
            v.wethBalOfSwapper = IERC20(v.interimToken2).balanceOf(getContract(AVAX, "DstSwapper"));
            console.log("WETH bal of dstSwapper:", IERC20(v.interimToken2).balanceOf(getContract(AVAX, "DstSwapper")));

            v.txDataPasses = _buildLiqBridgeTxDataDstSwap(
                1,
                v.interimToken2,
                getContract(AVAX, "DAI"),
                getContract(AVAX, "DstSwapper"),
                AVAX,
                234_296_506_866_750_873,
                0
            );

            v.indices = new uint256[](1);
            v.indices[0] = 0;

            v.bridgeIds_ = new uint8[](1);
            v.bridgeIds_[0] = 1;

            v.txDataArr = new bytes[](1);
            v.txDataArr[0] = v.txDataPasses;

            /// @dev calling batchProcessTx will pass
            vm.prank(deployer);
            DstSwapper(payable(getContract(AVAX, "DstSwapper"))).batchProcessTx(1, v.indices, v.bridgeIds_, v.txDataArr);

            /// @dev do update deposit to assert it continues normally
            v.finalTokens = new address[](2);
            v.finalTokens[0] = getContract(AVAX, "DAI");
            v.finalTokens[1] = getContract(AVAX, "DAI");

            v.amounts[0] = 419_950_757_613_293_461_130;
            v.amounts[1] = 419_972_359;

            vm.prank(deployer);
            SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

            /// @dev it cannot proceed because nothing was marked as failed
            vm.prank(deployer);
            CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(
                1, v.finalTokens, v.amounts
            );

            uint256 nativeFee = PaymentHelper(getContract(ETH, "PaymentHelper")).estimateAckCost(1);

            /// @dev check that processing works for the one that passed
            vm.prank(deployer);
            CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload{ value: nativeFee }(1);

            assertGt(IERC20(IBaseForm(v.superform).getVaultAddress()).balanceOf(v.superform), 0);
        }
    }

    function _successfulMultiWithdrawal(uint8[] memory ambIds_) internal returns (uint256 superformId) {
        vm.selectFork(FORKS[ETH]);

        address superform = getContract(
            AVAX, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], AVAX);
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
        liqReqArr[0] = LiqRequest(bytes(""), getContract(AVAX, "DAI"), address(0), 1, ETH, 0);
        liqReqArr[1] = liqReqArr[0];

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amountArr,
            amountArr,
            maxSlippages,
            liqReqArr,
            bytes(""),
            new bool[](2),
            new bool[](2),
            receiverAddress,
            receiverAddress,
            bytes("")
        );

        vm.prank(deployer);

        SuperPositions(getContract(ETH, "SuperPositions")).increaseAllowance(superformRouter, superformId, 2e18);
        vm.prank(deployer);
        vm.recordLogs();

        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultWithdraw{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(ambIds_, AVAX, data)
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

    function _failingMultiDeposit(uint8[] memory ambIds_, bytes4 errorSelector) internal {
        /// scenario: user deposits with his own token and has approved enough tokens
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

        liqReqArr[0] = LiqRequest(
            _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, AVAX, 0
        );
        liqReqArr[1] = liqReqArr[0];

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            uint256MemArr,
            uint256MemArr,
            uint256MemArr,
            liqReqArr,
            bytes(""),
            new bool[](2),
            new bool[](2),
            receiverAddress,
            receiverAddress,
            bytes("")
        );
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.expectRevert(errorSelector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(ambIds_, AVAX, data)
        );
        vm.stopPrank();
    }
}

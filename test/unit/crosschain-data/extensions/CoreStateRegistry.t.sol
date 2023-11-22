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
        /// @dev 1e18 after decimal corrections and bridge slippage would give the following value
        amounts[0] = 999_900_000_000_000_000;
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(1, amounts);

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

        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_AMOUNT.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(1, finalAmounts);

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

        liqReqArr[0] =
            LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), AVAX, 0);
        liqReqArr[1] = liqReqArr[0];
        liqReqArr[2] = liqReqArr[0];
        liqReqArr[3] = liqReqArr[0];

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            uint256MemArr,
            uint256MemArr,
            new bool[](4),
            new bool[](4),
            liqReqArr,
            bytes(""),
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

        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(1, finalAmounts);
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
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(1, amounts);

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

        vm.prank(deployer);
        vm.expectEmit();
        // We emit the event we expect to see.
        emit ICoreStateRegistry.FailedXChainDeposits(1);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(1, amounts);
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
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_AMOUNT.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(1, amounts);

        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 2);

        /// @dev 1e18 after decimal corrections and bridge slippage would give the following value
        amounts[0] = 999_900_000_000_000_000;

        vm.prank(deployer);
        vm.expectRevert(Error.INSUFFICIENT_QUORUM.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(1, amounts);
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
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        _successfulMultiDeposit(ambIds_);

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
        uint8[] memory ambIds_ = new uint8[](4);
        ambIds_[0] = 1;
        ambIds_[1] = 2;
        ambIds_[2] = 3;
        ambIds_[3] = 2;
        _failingMultiDeposit(ambIds_, Error.DUPLICATE_PROOF_BRIDGE_ID.selector);

        ambIds_[2] = 2;
        ambIds_[3] = 3;
        _failingMultiDeposit(ambIds_, Error.DUPLICATE_PROOF_BRIDGE_ID.selector);
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

    function test_multiDeposit_inexistentSuperformId() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;
        uint256 superformId = _successfulMultiDeposit(ambIds_);

        uint256[] memory finalAmounts = new uint256[](2);
        finalAmounts[0] = 420;
        finalAmounts[1] = 420;
        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(1, finalAmounts);

        vm.mockCall(
            getContract(AVAX, "SuperformFactory"),
            abi.encodeWithSelector(
                SuperformFactory(getContract(AVAX, "SuperformFactory")).isSuperform.selector, superformId
            ),
            abi.encode(false)
        );

        vm.prank(deployer);
        vm.expectRevert(Error.SUPERFORM_ID_NONEXISTENT.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload(1);

        vm.clearMockedCalls();
    }

    function test_singleDeposit_inexistentSuperformId() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;
        uint256 superformId = _successfulSingleDeposit(ambIds_);

        uint256[] memory finalAmounts = new uint256[](1);
        finalAmounts[0] = 999_900_000_000_000_000;

        vm.selectFork(FORKS[AVAX]);
        vm.prank(deployer);
        SuperRegistry(getContract(AVAX, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).updateDepositPayload(1, finalAmounts);

        vm.mockCall(
            getContract(AVAX, "SuperformFactory"),
            abi.encodeWithSelector(
                SuperformFactory(getContract(AVAX, "SuperformFactory")).isSuperform.selector, superformId
            ),
            abi.encode(false)
        );

        vm.prank(deployer);
        vm.expectRevert(Error.SUPERFORM_ID_NONEXISTENT.selector);
        CoreStateRegistry(payable(getContract(AVAX, "CoreStateRegistry"))).processPayload(1);

        vm.clearMockedCalls();
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
            100,
            false,
            false,
            LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), AVAX, 0),
            bytes(""),
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
            100,
            false,
            false,
            LiqRequest(1, bytes(""), getContract(ETH, "DAI"), ETH, 0),
            bytes(""),
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

        liqReqArr[0] =
            LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), AVAX, 0);
        liqReqArr[1] = liqReqArr[0];

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            uint256MemArr,
            uint256MemArr,
            new bool[](2),
            new bool[](2),
            liqReqArr,
            bytes(""),
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
        liqReqArr[0] = LiqRequest(1, bytes(""), getContract(AVAX, "DAI"), ETH, 0);
        liqReqArr[1] = liqReqArr[0];

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amountArr,
            maxSlippages,
            new bool[](2),
            new bool[](2),
            liqReqArr,
            bytes(""),
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

        liqReqArr[0] =
            LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), AVAX, 0);
        liqReqArr[1] = liqReqArr[0];

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            uint256MemArr,
            uint256MemArr,
            new bool[](2),
            new bool[](2),
            liqReqArr,
            bytes(""),
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

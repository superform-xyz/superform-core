// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import { Error } from "src/utils/Error.sol";

import { IStateSyncer } from "src/interfaces/IStateSyncer.sol";
import "test/utils/ProtocolActions.sol";

contract DstSwapperTest is ProtocolActions {
    address dstRefundAddress = address(444);

    function setUp() public override {
        super.setUp();
    }

    function test_failed_native_process_tx() public {
        address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(ETH, "CoreStateRegistry"));

        vm.selectFork(FORKS[ETH]);
        _simulateSingleVaultExistingPayload(coreStateRegistry);
        _simulateSingleVaultExistingPayload(coreStateRegistry);

        vm.startPrank(deployer);
        address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        (bool success,) = payable(dstSwapper).call{ value: 1e18 }("");

        if (success) {
            DstSwapper(dstSwapper).processTx(
                1, 0, 1, _buildLiqBridgeTxDataDstSwap(1, native, getContract(ETH, "DAI"), dstSwapper, ETH, 1e18, 0)
            );

            bytes memory txData =
                _buildLiqBridgeTxDataDstSwap(1, native, getContract(ETH, "DAI"), dstSwapper, ETH, 1e18, 0);

            /// @dev try with a non-existent index
            vm.expectRevert(Error.INVALID_INDEX.selector);
            DstSwapper(dstSwapper).processTx(1, 420, 1, txData);

            txData = _buildLiqBridgeTxDataDstSwap(1, native, getContract(ETH, "DAI"), dstSwapper, ETH, 1e18, 0);

            /// @dev retry the same payload id and indices
            vm.expectRevert(Error.DST_SWAP_ALREADY_PROCESSED.selector);
            DstSwapper(dstSwapper).processTx(1, 0, 1, txData);

            txData = _buildLiqBridgeTxDataDstSwap(1, native, getContract(ETH, "DAI"), dstSwapper, ETH, 1e18, 0);

            /// @dev no funds in multi-tx processor at this point; should revert
            vm.expectRevert(Error.FAILED_TO_EXECUTE_TXDATA_NATIVE.selector);
            DstSwapper(dstSwapper).processTx(2, 0, 1, txData);
        } else {
            revert();
        }
    }

    function test_failed_non_native_process_tx() public {
        address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(ETH, "CoreStateRegistry"));

        vm.selectFork(FORKS[ETH]);
        _simulateSingleVaultExistingPayload(coreStateRegistry);

        vm.startPrank(deployer);
        bytes memory txData =
            _buildLiqBridgeTxDataDstSwap(1, getContract(ETH, "WETH"), getContract(ETH, "DAI"), dstSwapper, ETH, 1e18, 0);
        /// @dev no funds in multi-tx processor at this point; should revert
        vm.expectRevert(Error.FAILED_TO_EXECUTE_TXDATA.selector);
        DstSwapper(dstSwapper).processTx(1, 0, 1, txData);
    }

    function test_single_non_native_updateFailedTx() public {
        address payable dstSwapper = payable(getContract(OP, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(OP, "CoreStateRegistry"));

        vm.selectFork(FORKS[OP]);
        uint256 superformId = _simulateSingleVaultExistingPayloadOnOP(coreStateRegistry);

        vm.startPrank(deployer);
        address weth = getContract(OP, "WETH");
        deal(weth, dstSwapper, 1e18);

        DstSwapper(dstSwapper).updateFailedTx(1, 0, weth, 1e18);

        /// @dev set quorum to 0 for simplicity in testing setup
        SuperRegistry(getContract(OP, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        uint256[] memory finalAmounts = new uint256[](1);
        finalAmounts[0] = 1e18;
        CoreStateRegistry(coreStateRegistry).updateDepositPayload(1, finalAmounts);

        vm.stopPrank();

        AMBs = [2, 3];
        CHAIN_0 = ETH;
        DST_CHAINS = [OP];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][0] = [2];
        TARGET_VAULTS[OP][0] = [0];

        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[OP][0] = [0];

        AMOUNTS[OP][0] = [1e18];
        MAX_SLIPPAGE = 1000;
        LIQ_BRIDGES[OP][0] = [1];

        actions.push(
            TestAction({
                action: Actions.RescueFailedDeposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 100, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: true,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        _rescueFailedDeposits(actions[0], 0, 1);
        actions.pop();
    }

    function test_single_native_updateFailedTx() public {
        address payable dstSwapper = payable(getContract(OP, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(OP, "CoreStateRegistry"));

        vm.selectFork(FORKS[OP]);
        uint256 superformId = _simulateSingleVaultExistingPayloadOnOP(coreStateRegistry);

        vm.startPrank(deployer);
        address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        deal(dstSwapper, 1e18);

        DstSwapper(dstSwapper).updateFailedTx(1, 0, native, 1e18);

        /// @dev set quorum to 0 for simplicity in testing setup
        SuperRegistry(getContract(OP, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        uint256[] memory finalAmounts = new uint256[](1);
        finalAmounts[0] = 1e18;
        CoreStateRegistry(coreStateRegistry).updateDepositPayload(1, finalAmounts);

        vm.stopPrank();

        AMBs = [2, 3];
        CHAIN_0 = ETH;
        DST_CHAINS = [OP];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][0] = [2];
        TARGET_VAULTS[OP][0] = [0];

        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[OP][0] = [0];

        AMOUNTS[OP][0] = [1e18];
        MAX_SLIPPAGE = 1000;
        LIQ_BRIDGES[OP][0] = [1];

        actions.push(
            TestAction({
                action: Actions.RescueFailedDeposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 100, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: true,
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        _rescueFailedDeposits(actions[0], 0, 1);
        actions.pop();
    }

    function test_multi_non_native_batchUpdateFailedTx() public {
        address payable dstSwapper = payable(getContract(OP, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(OP, "CoreStateRegistry"));

        vm.selectFork(FORKS[OP]);
        uint256[] memory superformIds = _simulateMultiVaultExistingPayloadOnOP(coreStateRegistry);

        vm.startPrank(deployer);
        address weth = getContract(OP, "WETH");
        deal(weth, dstSwapper, 2e18);

        address[] memory interimTokens = new address[](2);
        interimTokens[0] = weth;
        interimTokens[1] = weth;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        uint256[] memory indices = new uint256[](2);
        indices[0] = 0;
        indices[1] = 1;

        DstSwapper(dstSwapper).batchUpdateFailedTx(1, indices, interimTokens, amounts);

        /// @dev set quorum to 0 for simplicity in testing setup
        SuperRegistry(getContract(OP, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        CoreStateRegistry(coreStateRegistry).updateDepositPayload(1, amounts);

        vm.stopPrank();

        AMBs = [2, 3];
        CHAIN_0 = ETH;
        DST_CHAINS = [OP];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][0] = [2, 2];
        TARGET_VAULTS[OP][0] = [0, 3];

        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[OP][0] = [0, 0];

        AMOUNTS[OP][0] = [1e18, 1e18];
        MAX_SLIPPAGE = 1000;
        LIQ_BRIDGES[OP][0] = [1];

        actions.push(
            TestAction({
                action: Actions.RescueFailedDeposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 100, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: true,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        _rescueFailedDeposits(actions[0], 0, 1);
        actions.pop();
    }

    function test_multi_native_batchUpdateFailedTx() public {
        address payable dstSwapper = payable(getContract(OP, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(OP, "CoreStateRegistry"));

        vm.selectFork(FORKS[OP]);

        uint256[] memory superformIds = _simulateMultiVaultExistingPayloadOnOP(coreStateRegistry);
        vm.startPrank(deployer);
        address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        /// @dev simulating a failed swap in DstSwapper that leaves these tokens there
        deal(dstSwapper, 2e18);

        address[] memory interimTokens = new address[](2);
        interimTokens[0] = native;
        interimTokens[1] = native;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        uint256[] memory indices = new uint256[](2);
        indices[0] = 0;
        indices[1] = 1;

        DstSwapper(dstSwapper).batchUpdateFailedTx(1, indices, interimTokens, amounts);

        /// @dev set quorum to 0 for simplicity in testing setup
        SuperRegistry(getContract(OP, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        CoreStateRegistry(coreStateRegistry).updateDepositPayload(1, amounts);

        vm.stopPrank();

        AMBs = [2, 3];
        CHAIN_0 = ETH;
        DST_CHAINS = [OP];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][0] = [2, 2];
        TARGET_VAULTS[OP][0] = [0, 3];

        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[OP][0] = [0, 0];

        AMOUNTS[OP][0] = [1e18, 1e18];
        MAX_SLIPPAGE = 1000;
        LIQ_BRIDGES[OP][0] = [1];

        actions.push(
            TestAction({
                action: Actions.RescueFailedDeposit,
                multiVaults: true, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 100, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: true,
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        _rescueFailedDeposits(actions[0], 0, 1);
        actions.pop();
    }

    function test_failed_batch_process_tx() public {
        address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(ETH, "CoreStateRegistry"));

        vm.selectFork(FORKS[ETH]);
        _simulateMultiVaultExistingPayload(coreStateRegistry);
        _simulateMultiVaultExistingPayload(coreStateRegistry);

        vm.startPrank(deployer);

        address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        uint8[] memory bridgeId = new uint8[](2);
        bridgeId[0] = 1;
        bridgeId[1] = 1;

        address[] memory approvalToken = new address[](2);
        approvalToken[0] = native;
        approvalToken[1] = native;

        bytes[] memory txData = new bytes[](2);
        txData[0] = _buildLiqBridgeTxDataDstSwap(1, native, getContract(ETH, "DAI"), dstSwapper, ETH, 1e18, 0);
        txData[1] = _buildLiqBridgeTxDataDstSwap(1, native, getContract(ETH, "DAI"), dstSwapper, ETH, 1e18, 0);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        uint256[] memory indices = new uint256[](2);
        indices[0] = 2;
        indices[1] = 2;

        (bool success,) = payable(dstSwapper).call{ value: 2e18 }("");
        if (!success) revert();

        vm.expectRevert(Error.INVALID_INDEX.selector);
        DstSwapper(dstSwapper).batchProcessTx(1, indices, bridgeId, txData);
        indices[0] = 0;
        indices[1] = 1;
        DstSwapper(dstSwapper).batchProcessTx(1, indices, bridgeId, txData);

        /// @dev retry the same payload id and indices
        vm.expectRevert(Error.DST_SWAP_ALREADY_PROCESSED.selector);
        DstSwapper(dstSwapper).batchProcessTx(1, indices, bridgeId, txData);

        /// @dev retry the same payload id and indices in reversed manner
        vm.expectRevert(Error.DST_SWAP_ALREADY_PROCESSED.selector);
        indices[0] = 1;
        indices[1] = 0;
        DstSwapper(dstSwapper).batchProcessTx(1, indices, bridgeId, txData);

        /// @dev no funds in multi-tx processor at this point; should revert
        vm.expectRevert(Error.FAILED_TO_EXECUTE_TXDATA_NATIVE.selector);
        DstSwapper(dstSwapper).batchProcessTx(2, indices, bridgeId, txData);
    }

    function test_failed_batch_process_tx_INVALID_PAYLOAD_STATUS() public {
        address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(ETH, "CoreStateRegistry"));

        vm.selectFork(FORKS[ETH]);
        _simulateMultiVaultExistingPayload(coreStateRegistry);

        vm.startPrank(deployer);

        address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        uint8[] memory bridgeId = new uint8[](2);
        bridgeId[0] = 1;
        bridgeId[1] = 1;

        address[] memory approvalToken = new address[](2);
        approvalToken[0] = native;
        approvalToken[1] = native;

        bytes[] memory txData = new bytes[](2);
        txData[0] = _buildLiqBridgeTxDataDstSwap(1, native, getContract(ETH, "DAI"), dstSwapper, ETH, 1e18, 0);
        txData[1] = _buildLiqBridgeTxDataDstSwap(1, native, getContract(ETH, "DAI"), dstSwapper, ETH, 1e18, 0);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        uint256[] memory indices = new uint256[](2);
        indices[0] = 0;
        indices[1] = 1;

        (bool success,) = payable(dstSwapper).call{ value: 2e18 }("");
        if (!success) revert();
        SuperRegistry(getContract(ETH, "SuperRegistry")).setRequiredMessagingQuorum(POLY, 0);

        (uint256 nativeAmount,) = PaymentHelper(getContract(ETH, "PaymentHelper")).estimateAckCost(1);
        CoreStateRegistry(coreStateRegistry).processPayload{ value: nativeAmount }(1);

        vm.expectRevert(Error.INVALID_PAYLOAD_STATUS.selector);
        DstSwapper(dstSwapper).batchProcessTx(1, indices, bridgeId, txData);
    }

    function test_failed_INVALID_SWAP_OUTPUT() public {
        address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(ETH, "CoreStateRegistry"));

        vm.selectFork(FORKS[ETH]);
        _simulateSingleVaultExistingPayload(coreStateRegistry);

        vm.startPrank(deployer);

        bytes memory txData =
            _buildLiqBridgeTxDataDstSwap(1, getContract(ETH, "WETH"), getContract(ETH, "DAI"), dstSwapper, ETH, 0, 0);
        /// @dev txData with amount 0 should revert
        vm.expectRevert(Error.INVALID_SWAP_OUTPUT.selector);
        DstSwapper(dstSwapper).processTx(1, 0, 1, txData);
    }

    function _simulateSingleVaultExistingPayload(address payable coreStateRegistry)
        internal
        returns (uint256 superformId)
    {
        /// simulate an existing payload in csr
        address superform = getContract(ETH, string.concat("DAI", "VaultMock", "Superform", "1"));
        superformId = DataLib.packSuperform(superform, 1, ETH);

        LiqRequest memory liq;
        vm.prank(getContract(ETH, "LayerzeroImplementation"));
        CoreStateRegistry(coreStateRegistry).receivePayload(
            137,
            abi.encode(
                AMBMessage(
                    0,
                    abi.encode(InitSingleVaultData(1, 1, superformId, 1e18, 0, true, liq, dstRefundAddress, bytes("")))
                )
            )
        );
    }

    function _simulateSingleVaultExistingPayloadOnOP(address payable coreStateRegistry)
        internal
        returns (uint256 superformId)
    {
        /// simulate an existing payload in csr
        address superform = getContract(OP, string.concat("WETH", "VaultMock", "Superform", "1"));
        superformId = DataLib.packSuperform(superform, 1, OP);

        LiqRequest memory liq;
        bytes memory message = abi.encode(
            AMBMessage(
                DataLib.packTxInfo(
                    uint8(TransactionType.DEPOSIT),
                    /// @dev TransactionType
                    uint8(CallbackType.INIT),
                    0,
                    /// @dev isMultiVaults
                    1,
                    /// @dev STATE_REGISTRY_TYPE,
                    users[0],
                    /// @dev srcSender,
                    ETH
                ),
                abi.encode(InitSingleVaultData(1, 1, superformId, 1e18, 1000, true, liq, users[0], bytes("")))
            )
        );

        vm.prank(getContract(OP, "LayerzeroImplementation"));
        CoreStateRegistry(coreStateRegistry).receivePayload(1, message);
    }

    function _simulateMultiVaultExistingPayloadOnOP(address payable coreStateRegistry)
        internal
        returns (uint256[] memory superformIds)
    {
        /// simulate an existing payload in csr
        address superform = getContract(OP, string.concat("WETH", "VaultMock", "Superform", "1"));
        uint256 superformId1 = DataLib.packSuperform(superform, 1, OP);
        uint256 superformId2 = DataLib.packSuperform(
            getContract(OP, string.concat("WETH", "VaultMockRevertDeposit", "Superform", "1")), 1, OP
        );

        vm.prank(getContract(OP, "LayerzeroImplementation"));

        superformIds = new uint256[](2);
        superformIds[0] = superformId1;
        superformIds[1] = superformId2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        bool[] memory hasDstSwaps = new bool[](2);
        hasDstSwaps[0] = true;
        hasDstSwaps[1] = true;

        uint256[] memory maxSlippages = new uint256[](2);
        amounts[0] = 1000;
        amounts[1] = 1000;

        LiqRequest[] memory liq = new LiqRequest[](2);
        CoreStateRegistry(coreStateRegistry).receivePayload(
            ETH,
            abi.encode(
                AMBMessage(
                    DataLib.packTxInfo(uint8(TransactionType.DEPOSIT), uint8(CallbackType.INIT), 1, 1, users[0], ETH),
                    abi.encode(
                        InitMultiVaultData(
                            1, 1, superformIds, amounts, maxSlippages, hasDstSwaps, liq, users[0], bytes("")
                        )
                    )
                )
            )
        );
    }

    function _simulateMultiVaultExistingPayload(address payable coreStateRegistry) internal {
        /// simulate an existing payload in csr
        address superform = getContract(ETH, string.concat("DAI", "VaultMock", "Superform", "1"));
        uint256 superformId = DataLib.packSuperform(superform, 1, ETH);

        vm.prank(getContract(ETH, "LayerzeroImplementation"));

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId;
        superformIds[1] = superformId;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        bool[] memory hasDstSwaps = new bool[](2);
        hasDstSwaps[0] = true;
        hasDstSwaps[1] = true;

        LiqRequest[] memory liq = new LiqRequest[](2);
        CoreStateRegistry(coreStateRegistry).receivePayload(
            POLY,
            abi.encode(
                AMBMessage(
                    DataLib.packTxInfo(1, 0, 1, 1, address(420), uint64(137)),
                    abi.encode(
                        InitMultiVaultData(
                            1, 1, superformIds, amounts, new uint256[](2), hasDstSwaps, liq, dstRefundAddress, bytes("")
                        )
                    )
                )
            )
        );
    }
}

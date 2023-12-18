// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import { AggregatorV3Interface } from "src/vendor/chainlink/AggregatorV3Interface.sol";
import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";

contract FakeUser is ERC1155Holder {
    receive() external payable {
        revert();
    }
}

contract DstSwapperTest is ProtocolActions {
    address receiverAddress = address(444);
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public override {
        super.setUp();
    }

    function test_failed_invalid_interim_token() public {
        address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(ETH, "CoreStateRegistry"));

        vm.selectFork(FORKS[ETH]);
        address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        _simulateSingleVaultExistingPayload(coreStateRegistry, address(0));

        vm.startPrank(deployer);

        (bool success,) = payable(dstSwapper).call{ value: 1e18 }("");

        if (success) {
            bytes memory txData =
                _buildLiqBridgeTxDataDstSwap(1, native, getContract(ETH, "DAI"), dstSwapper, ETH, 1e18, 0);
            vm.expectRevert(Error.INVALID_INTERIM_TOKEN.selector);

            DstSwapper(dstSwapper).processTx(1, 1, txData);
        } else {
            revert();
        }
    }

    function test_failed_native_process_tx() public {
        address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(ETH, "CoreStateRegistry"));

        vm.selectFork(FORKS[ETH]);
        address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        _simulateSingleVaultExistingPayload(coreStateRegistry, native);
        _simulateSingleVaultExistingPayload(coreStateRegistry, native);

        vm.startPrank(deployer);

        (bool success,) = payable(dstSwapper).call{ value: 1e18 }("");

        if (success) {
            bytes memory txData =
                _buildLiqBridgeTxDataDstSwap(1, native, getContract(ETH, "DAI"), dstSwapper, ETH, 1e18, 0);
            vm.expectRevert(Error.INVALID_PAYLOAD_ID.selector);
            DstSwapper(dstSwapper).processTx(1000, 1, txData);

            DstSwapper(dstSwapper).processTx(1, 1, txData);

            /// @dev retry the same payload id and indices
            vm.expectRevert(Error.DST_SWAP_ALREADY_PROCESSED.selector);
            DstSwapper(dstSwapper).processTx(1, 1, txData);

            /// @dev no funds in multi-tx processor at this point; should revert
            vm.expectRevert(abi.encodeWithSelector(Error.FAILED_TO_EXECUTE_TXDATA.selector, native));
            DstSwapper(dstSwapper).processTx(2, 1, txData);
        } else {
            revert();
        }
    }

    function test_failed_non_native_process_tx() public {
        address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(ETH, "CoreStateRegistry"));

        vm.selectFork(FORKS[ETH]);
        _simulateSingleVaultExistingPayload(coreStateRegistry, getContract(ETH, "WETH"));

        vm.startPrank(deployer);
        bytes memory txData =
            _buildLiqBridgeTxDataDstSwap(1, getContract(ETH, "WETH"), getContract(ETH, "DAI"), dstSwapper, ETH, 1e18, 0);
        /// @dev no funds in multi-tx processor at this point; should revert
        vm.expectRevert(abi.encodeWithSelector(Error.FAILED_TO_EXECUTE_TXDATA.selector, getContract(ETH, "WETH")));
        DstSwapper(dstSwapper).processTx(1, 1, txData);
    }

    function test_partial_multi_vault_dstSwap() public {
        address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(ETH, "CoreStateRegistry"));

        vm.selectFork(FORKS[ETH]);

        /// simulate an existing payload in csr
        address superform = getContract(ETH, string.concat("DAI", "VaultMock", "Superform", "1"));
        uint256 superformId = DataLib.packSuperform(superform, 1, ETH);

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId;
        superformIds[1] = superformId;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        uint256[] memory slippages = new uint256[](2);
        slippages[0] = 1000;
        slippages[1] = 1000;

        LiqRequest memory liq;
        liq.interimToken = getContract(ETH, "WETH");

        LiqRequest[] memory liqs = new LiqRequest[](2);
        liqs[1] = liq;

        bool[] memory hasDstSwaps = new bool[](2);
        hasDstSwaps[1] = true;

        vm.prank(getContract(ETH, "LayerzeroImplementation"));
        CoreStateRegistry(coreStateRegistry).receivePayload(
            137,
            abi.encode(
                AMBMessage(
                    DataLib.packTxInfo(1, 1, 1, 1, address(0), 1),
                    abi.encode(
                        new uint8[](0),
                        abi.encode(
                            InitMultiVaultData(
                                1,
                                superformIds,
                                amounts,
                                new uint256[](2),
                                liqs,
                                hasDstSwaps,
                                new bool[](2),
                                receiverAddress,
                                bytes("")
                            )
                        )
                    )
                )
            )
        );

        vm.startPrank(deployer);
        deal(getContract(ETH, "WETH"), dstSwapper, 1e18);

        bytes memory txData = _buildLiqBridgeTxDataDstSwap(
            1, getContract(ETH, "WETH"), getContract(ETH, "DAI"), dstSwapper, ETH, 1e17, 1001
        );

        uint256[] memory indices = new uint256[](1);
        indices[0] = 1;

        uint8[] memory bridgeIds = new uint8[](1);
        bridgeIds[0] = 1;

        bytes[] memory txDataArr = new bytes[](1);
        txDataArr[0] = txData;

        DstSwapper(dstSwapper).batchProcessTx(1, indices, bridgeIds, txDataArr);
    }

    function test_single_non_native_updateFailedTx() public {
        address payable dstSwapper = payable(getContract(OP, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(OP, "CoreStateRegistry"));

        vm.selectFork(FORKS[OP]);
        address weth = getContract(OP, "WETH");

        _simulateSingleVaultExistingPayloadOnOP(coreStateRegistry, weth);
        _simulateMultiVaultExistingPayloadOnOP(coreStateRegistry, weth);
        _simulateSingleVaultExistingPayloadOnOP(coreStateRegistry, address(0x2222));

        vm.startPrank(deployer);
        deal(weth, dstSwapper, 1e18);

        vm.expectRevert(Error.ZERO_AMOUNT.selector);
        DstSwapper(dstSwapper).updateFailedTx(1, weth, 0);

        vm.expectRevert(Error.INSUFFICIENT_BALANCE.selector);
        DstSwapper(dstSwapper).updateFailedTx(1, weth, 3e18);

        DstSwapper(dstSwapper).updateFailedTx(1, weth, 1e18);

        vm.expectRevert(Error.FAILED_DST_SWAP_ALREADY_UPDATED.selector);
        DstSwapper(dstSwapper).updateFailedTx(1, weth, 1e18);

        vm.expectRevert(Error.INVALID_PAYLOAD_TYPE.selector);
        DstSwapper(dstSwapper).updateFailedTx(2, weth, 1e18);

        vm.expectRevert(Error.INVALID_INTERIM_TOKEN.selector);
        DstSwapper(dstSwapper).updateFailedTx(3, weth, 1e18);

        /// @dev set quorum to 0 for simplicity in testing setup
        SuperRegistry(getContract(OP, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        uint256[] memory finalAmounts = new uint256[](1);

        finalAmounts[0] = 2e18;
        vm.expectRevert(Error.INVALID_DST_SWAP_AMOUNT.selector);
        CoreStateRegistry(coreStateRegistry).updateDepositPayload(1, finalAmounts);

        finalAmounts[0] = 1e18;
        CoreStateRegistry(coreStateRegistry).updateDepositPayload(1, finalAmounts);

        vm.expectRevert(Error.INVALID_PAYLOAD_STATUS.selector);
        DstSwapper(dstSwapper).updateFailedTx(1, weth, 1e18);
        vm.stopPrank();

        AMBs = [2, 3];
        CHAIN_0 = ETH;
        DST_CHAINS = [OP];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][0] = [2];
        TARGET_VAULTS[OP][0] = [0];

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

    function test_single_non_native_updateFailedTx_postRescue_getPostDstSwapFailureUpdatedTokenAmount() public {
        address payable dstSwapper = payable(getContract(OP, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(OP, "CoreStateRegistry"));

        vm.selectFork(FORKS[OP]);
        address weth = getContract(OP, "WETH");

        _simulateSingleVaultExistingPayloadOnOP(coreStateRegistry, weth);

        vm.startPrank(deployer);
        deal(weth, dstSwapper, 1e18);

        DstSwapper(dstSwapper).updateFailedTx(1, weth, 1e18);

        vm.stopPrank();

        vm.prank(coreStateRegistry);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        DstSwapper(dstSwapper).processFailedTx(address(0), weth, 1e18);

        vm.prank(coreStateRegistry);
        DstSwapper(dstSwapper).processFailedTx(users[0], weth, 1e18);

        vm.expectRevert(Error.INVALID_DST_SWAPPER_FAILED_SWAP_NO_TOKEN_BALANCE.selector);
        DstSwapper(dstSwapper).getPostDstSwapFailureUpdatedTokenAmount(1, 0);

        address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        _simulateSingleVaultExistingPayloadOnOP(coreStateRegistry, native);

        vm.startPrank(deployer);
        deal(dstSwapper, 1e18);

        DstSwapper(dstSwapper).updateFailedTx(2, native, 1e18);

        vm.stopPrank();

        vm.prank(coreStateRegistry);
        DstSwapper(dstSwapper).processFailedTx(users[0], native, 1e18);

        vm.expectRevert(Error.INVALID_DST_SWAPPER_FAILED_SWAP_NO_NATIVE_BALANCE.selector);
        DstSwapper(dstSwapper).getPostDstSwapFailureUpdatedTokenAmount(2, 0);
    }

    function test_single_native_updateFailedTx() public {
        address payable dstSwapper = payable(getContract(OP, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(OP, "CoreStateRegistry"));

        vm.selectFork(FORKS[OP]);
        address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        _simulateSingleVaultExistingPayloadOnOP(coreStateRegistry, native);

        vm.startPrank(deployer);
        vm.expectRevert(Error.INSUFFICIENT_BALANCE.selector);
        DstSwapper(dstSwapper).updateFailedTx(1, native, 1e18);

        deal(dstSwapper, 1e18);

        DstSwapper(dstSwapper).updateFailedTx(1, native, 1e18);

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
        address weth = getContract(OP, "WETH");

        address interimToken = weth;
        _simulateMultiVaultExistingPayloadOnOP(coreStateRegistry, interimToken);
        _simulateSingleVaultExistingPayloadOnOP(coreStateRegistry, interimToken);

        vm.startPrank(deployer);
        deal(interimToken, dstSwapper, 2e18);

        address[] memory interimTokens = new address[](2);
        interimTokens[0] = interimToken;
        interimTokens[1] = interimToken;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        uint256[] memory indices = new uint256[](2);
        indices[0] = 2;
        indices[1] = 1;

        vm.expectRevert(Error.INDEX_OUT_OF_BOUNDS.selector);
        DstSwapper(dstSwapper).batchUpdateFailedTx(1, indices, interimTokens, amounts);

        indices[0] = 1;
        indices[1] = 1;

        vm.expectRevert(Error.DUPLICATE_INDEX.selector);
        DstSwapper(dstSwapper).batchUpdateFailedTx(1, indices, interimTokens, amounts);

        indices[0] = 0;
        indices[1] = 1;

        DstSwapper(dstSwapper).batchUpdateFailedTx(1, indices, interimTokens, amounts);

        vm.expectRevert(Error.INVALID_PAYLOAD_TYPE.selector);
        DstSwapper(dstSwapper).batchUpdateFailedTx(2, indices, interimTokens, amounts);

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
        address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        address interimToken = native;
        _simulateMultiVaultExistingPayloadOnOP(coreStateRegistry, interimToken);
        vm.startPrank(deployer);
        /// @dev simulating a failed swap in DstSwapper that leaves these tokens there
        deal(dstSwapper, 2e18);

        address[] memory interimTokens = new address[](2);
        interimTokens[0] = interimToken;
        interimTokens[1] = interimToken;

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

        vm.expectRevert(Error.INDEX_OUT_OF_BOUNDS.selector);
        DstSwapper(dstSwapper).batchProcessTx(1, indices, bridgeId, txData);

        vm.expectRevert(Error.DUPLICATE_INDEX.selector);
        indices[0] = 1;
        indices[1] = 1;
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
        vm.expectRevert(abi.encodeWithSelector(Error.FAILED_TO_EXECUTE_TXDATA.selector, native));
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

        uint256 nativeAmount = PaymentHelper(getContract(ETH, "PaymentHelper")).estimateAckCost(1);
        CoreStateRegistry(coreStateRegistry).processPayload{ value: nativeAmount }(1);

        vm.expectRevert(Error.INVALID_PAYLOAD_STATUS.selector);
        DstSwapper(dstSwapper).batchProcessTx(1, indices, bridgeId, txData);
    }

    function test_failed_INVALID_SWAP_OUTPUT() public {
        address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(ETH, "CoreStateRegistry"));

        vm.selectFork(FORKS[ETH]);
        _simulateSingleVaultExistingPayload(coreStateRegistry, getContract(ETH, "WETH"));

        vm.startPrank(deployer);

        bytes memory txData =
            _buildLiqBridgeTxDataDstSwap(1, getContract(ETH, "WETH"), getContract(ETH, "DAI"), dstSwapper, ETH, 0, 0);
        /// @dev txData with amount 0 should revert
        vm.expectRevert(Error.INVALID_SWAP_OUTPUT.selector);
        DstSwapper(dstSwapper).processTx(1, 1, txData);
    }

    function test_failed_MAX_SLIPPAGE_INVARIANT_BROKEN() public {
        address payable dstSwapper = payable(getContract(ETH, "DstSwapper"));
        address payable coreStateRegistry = payable(getContract(ETH, "CoreStateRegistry"));

        vm.selectFork(FORKS[ETH]);

        /// simulate an existing payload in csr
        address superform = getContract(ETH, string.concat("DAI", "VaultMock", "Superform", "1"));
        uint256 superformId = DataLib.packSuperform(superform, 1, ETH);

        LiqRequest memory liq;

        liq.interimToken = getContract(ETH, "WETH");

        vm.prank(getContract(ETH, "LayerzeroImplementation"));
        CoreStateRegistry(coreStateRegistry).receivePayload(
            137,
            abi.encode(
                AMBMessage(
                    0,
                    abi.encode(
                        new uint8[](0),
                        abi.encode(
                            InitSingleVaultData(
                                1,
                                superformId,
                                1_798_823_082_965_464_723_525,
                                0,
                                liq,
                                true,
                                false,
                                receiverAddress,
                                bytes("")
                            )
                        )
                    )
                )
            )
        );

        vm.startPrank(deployer);
        deal(getContract(ETH, "WETH"), dstSwapper, 1e18);

        bytes memory txData = _buildLiqBridgeTxDataDstSwap(
            1, getContract(ETH, "WETH"), getContract(ETH, "DAI"), dstSwapper, ETH, 1e17, 1001
        );
        /// @dev txData with amount 0 should revert
        vm.expectRevert(Error.SLIPPAGE_OUT_OF_BOUNDS.selector);
        DstSwapper(dstSwapper).processTx(1, 1, txData);
    }

    function test_processFailedTx_invalidUserCall() public {
        vm.selectFork(FORKS[ETH]);
        address payable fakeUser = payable(address(new FakeUser()));

        vm.prank(deployer);
        payable(getContract(ETH, "DstSwapper")).transfer(1);

        vm.prank(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.FAILED_TO_SEND_NATIVE.selector);
        DstSwapper(payable(getContract(ETH, "DstSwapper"))).processFailedTx(fakeUser, NATIVE, 1);
    }

    function test_single_non_native_updateDepositPayload_noUpdateFailedTx() public {
        address payable coreStateRegistry = payable(getContract(OP, "CoreStateRegistry"));

        vm.selectFork(FORKS[OP]);
        _simulateSingleVaultExistingPayloadOnOP(coreStateRegistry, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

        vm.startPrank(deployer);

        /// @dev set quorum to 0 for simplicity in testing setup
        SuperRegistry(getContract(OP, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        uint256[] memory finalAmounts = new uint256[](1);

        finalAmounts[0] = 2e18;
        vm.expectRevert(Error.INVALID_DST_SWAPPER_FAILED_SWAP.selector);
        CoreStateRegistry(coreStateRegistry).updateDepositPayload(1, finalAmounts);
    }

    function _simulateSingleVaultExistingPayload(
        address payable coreStateRegistry,
        address interimToken_
    )
        internal
        returns (uint256 superformId)
    {
        /// simulate an existing payload in csr
        address superform = getContract(ETH, string.concat("DAI", "VaultMock", "Superform", "1"));
        superformId = DataLib.packSuperform(superform, 1, ETH);

        LiqRequest memory liq;

        liq.interimToken = interimToken_;

        (, int256 USDPerSendingTokenDst,,,) = AggregatorV3Interface(tokenPriceFeeds[ETH][NATIVE]).latestRoundData();
        (, int256 USDPerReceivingTokenDst,,,) =
            AggregatorV3Interface(tokenPriceFeeds[ETH][getContract(ETH, "DAI")]).latestRoundData();

        uint256 amount = (1e18 * uint256(USDPerSendingTokenDst)) / uint256(USDPerReceivingTokenDst);

        vm.prank(getContract(ETH, "LayerzeroImplementation"));
        CoreStateRegistry(coreStateRegistry).receivePayload(
            137,
            abi.encode(
                AMBMessage(
                    0,
                    abi.encode(
                        new uint8[](0),
                        abi.encode(
                            InitSingleVaultData(1, superformId, amount, 0, liq, true, false, receiverAddress, bytes(""))
                        )
                    )
                )
            )
        );
    }

    function _simulateSingleVaultExistingPayloadOnOP(
        address payable coreStateRegistry,
        address interimToken_
    )
        internal
        returns (uint256 superformId)
    {
        /// simulate an existing payload in csr
        address superform = getContract(OP, string.concat("WETH", "VaultMock", "Superform", "1"));
        superformId = DataLib.packSuperform(superform, 1, OP);

        LiqRequest memory liq = LiqRequest("", getContract(OP, "WETH"), interimToken_, 1, OP, 0);

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
                abi.encode(
                    new uint8[](0),
                    abi.encode(InitSingleVaultData(1, superformId, 1e18, 1000, liq, true, false, users[0], bytes("")))
                )
            )
        );

        vm.prank(getContract(OP, "LayerzeroImplementation"));
        CoreStateRegistry(coreStateRegistry).receivePayload(1, message);
    }

    function _simulateMultiVaultExistingPayloadOnOP(
        address payable coreStateRegistry,
        address interimToken_
    )
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
        liq[0] = LiqRequest("", getContract(OP, "DAI"), interimToken_, 1, OP, 0);
        liq[1] = LiqRequest("", getContract(OP, "DAI"), interimToken_, 1, OP, 0);
        CoreStateRegistry(coreStateRegistry).receivePayload(
            ETH,
            abi.encode(
                AMBMessage(
                    DataLib.packTxInfo(
                        uint8(TransactionType.DEPOSIT), uint8(CallbackType.INIT), uint8(1), 1, users[0], ETH
                    ),
                    abi.encode(
                        new uint8[](1),
                        abi.encode(
                            InitMultiVaultData(
                                1,
                                superformIds,
                                amounts,
                                maxSlippages,
                                liq,
                                hasDstSwaps,
                                new bool[](2),
                                users[0],
                                bytes("")
                            )
                        )
                    )
                )
            )
        );
    }

    function _simulatePartialMultiVaultExistingPayloadOnOP(
        address payable coreStateRegistry,
        address interimToken_
    )
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
        hasDstSwaps[0] = false;
        hasDstSwaps[1] = true;

        uint256[] memory maxSlippages = new uint256[](2);
        amounts[0] = 1000;
        amounts[1] = 1000;

        LiqRequest[] memory liq = new LiqRequest[](2);
        liq[0] = LiqRequest("", getContract(OP, "DAI"), interimToken_, 1, OP, 0);
        liq[1] = LiqRequest("", getContract(OP, "DAI"), interimToken_, 1, OP, 0);
        CoreStateRegistry(coreStateRegistry).receivePayload(
            ETH,
            abi.encode(
                AMBMessage(
                    DataLib.packTxInfo(
                        uint8(TransactionType.DEPOSIT), uint8(CallbackType.INIT), uint8(1), 1, users[0], ETH
                    ),
                    abi.encode(
                        new uint8[](1),
                        abi.encode(
                            InitMultiVaultData(
                                1,
                                superformIds,
                                amounts,
                                maxSlippages,
                                liq,
                                hasDstSwaps,
                                new bool[](2),
                                users[0],
                                bytes("")
                            )
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

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId;
        superformIds[1] = superformId;

        (, int256 USDPerSendingTokenDst,,,) = AggregatorV3Interface(tokenPriceFeeds[ETH][NATIVE]).latestRoundData();
        (, int256 USDPerReceivingTokenDst,,,) =
            AggregatorV3Interface(tokenPriceFeeds[ETH][getContract(ETH, "DAI")]).latestRoundData();

        uint256 amount = (1e18 * uint256(USDPerSendingTokenDst)) / uint256(USDPerReceivingTokenDst);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = amount;

        bool[] memory hasDstSwaps = new bool[](2);
        hasDstSwaps[0] = true;
        hasDstSwaps[1] = true;

        LiqRequest[] memory liq = new LiqRequest[](2);

        liq[0].interimToken = NATIVE;
        liq[1].interimToken = NATIVE;

        uint8[] memory ambIds_ = new uint8[](1);
        ambIds_[0] = 1;
        vm.prank(getContract(ETH, "LayerzeroImplementation"));
        CoreStateRegistry(coreStateRegistry).receivePayload(
            POLY,
            abi.encode(
                AMBMessage(
                    DataLib.packTxInfo(1, 0, 1, 1, address(420), uint64(137)),
                    abi.encode(
                        ambIds_,
                        abi.encode(
                            InitMultiVaultData(
                                1,
                                superformIds,
                                amounts,
                                new uint256[](2),
                                liq,
                                hasDstSwaps,
                                new bool[](2),
                                receiverAddress,
                                bytes("")
                            )
                        )
                    )
                )
            )
        );
    }
}

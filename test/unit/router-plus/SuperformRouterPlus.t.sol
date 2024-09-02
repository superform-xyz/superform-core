// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";

import { ISuperformRouterPlus } from "src/interfaces/ISuperformRouterPlus.sol";

import { IBaseRouter } from "src/interfaces/IBaseRouter.sol";

contract SuperformRouterPlusTest is ProtocolActions {
    using DataLib for uint256;

    error InvalidSigner();

    address receiverAddress = address(444);

    struct MultiVaultDepositVars {
        address superformRouter;
        uint256[] superformIds;
        uint256[] amounts;
        uint256[] outputAmounts;
        uint256[] maxSlippages;
        bool[] hasDstSwaps;
        bool[] retain4626s;
        LiqRequest[] liqReqs;
        IPermit2.PermitTransferFrom permit;
        LiqBridgeTxDataArgs liqBridgeTxDataArgs;
        uint8[] ambIds;
        bytes permit2Data;
    }

    address superform1;
    uint256 superformId1;
    address superform2;
    uint256 superformId2;
    address superform3;
    uint256 superformId3;

    address superform4OP;
    uint256 superformId4OP;

    address ROUTER_PLUS_ARBI;
    address SUPER_POSITIONS_ARBI;

    function setUp() public override {
        super.setUp();
        AMBs = [2, 3];
        vm.selectFork(FORKS[ARBI]);

        superform1 = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        superformId1 = DataLib.packSuperform(superform1, FORM_IMPLEMENTATION_IDS[0], ARBI);

        superform2 = getContract(
            ARBI, string.concat("USDC", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        superformId2 = DataLib.packSuperform(superform2, FORM_IMPLEMENTATION_IDS[0], ARBI);

        superform3 = getContract(
            ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        superformId3 = DataLib.packSuperform(superform3, FORM_IMPLEMENTATION_IDS[0], ARBI);

        superform4OP = getContract(
            OP, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        superformId4OP = DataLib.packSuperform(superform4OP, FORM_IMPLEMENTATION_IDS[0], OP);

        ROUTER_PLUS_ARBI = getContract(ARBI, "SuperformRouterPlus");

        SUPER_POSITIONS_ARBI = getContract(ARBI, "SuperPositions");
    }

    function test_rebalanceFromSinglePosition_toOneVault() public {
        vm.startPrank(deployer);

        _directDeposit(superformId1);

        ISuperformRouterPlus.RebalanceSinglePositionSyncArgs memory args = _buildRebalanceSinglePositionToOneVaultArgs();

        SuperPositions(SUPER_POSITIONS_ARBI).increaseAllowance(ROUTER_PLUS_ARBI, superformId1, args.sharesToRedeem);
        SuperformRouterPlus(ROUTER_PLUS_ARBI).rebalanceSinglePosition{ value: 2 ether }(args);

        assertEq(SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId1), 0);

        assertGt(SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId2), 0);
    }

    function test_rebalanceFromSinglePosition_toTwoVaults() public {
        vm.startPrank(deployer);

        _directDeposit(superformId1);

        ISuperformRouterPlus.RebalanceSinglePositionSyncArgs memory args =
            _buildRebalanceSinglePositionToTwoVaultsArgs();

        SuperPositions(SUPER_POSITIONS_ARBI).increaseAllowance(ROUTER_PLUS_ARBI, superformId1, args.sharesToRedeem);
        SuperformRouterPlus(ROUTER_PLUS_ARBI).rebalanceSinglePosition{ value: 2 ether }(args);

        assertEq(SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId1), 0);

        assertGt(SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId2), 0);
    }

    function test_rebalanceFromTwoPositions_toOneXChainVault() public {
        vm.startPrank(deployer);

        _directDeposit(superformId1);
        _directDeposit(superformId2);

        (ISuperformRouterPlus.RebalanceMultiPositionsSyncArgs memory args, uint256 totalAmountToDeposit) =
            _buildRebalanceTwoPositionsToOneVaultXChainArgs();

        SuperPositions(SUPER_POSITIONS_ARBI).increaseAllowance(ROUTER_PLUS_ARBI, superformId1, args.sharesToRedeem[0]);
        SuperPositions(SUPER_POSITIONS_ARBI).increaseAllowance(ROUTER_PLUS_ARBI, superformId2, args.sharesToRedeem[1]);
        vm.recordLogs();

        SuperformRouterPlus(ROUTER_PLUS_ARBI).rebalanceMultiPositions{ value: 2 ether }(args);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        assertEq(SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId1), 0);
        assertEq(SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId2), 0);
        /// @dev have to perform remaining of async CSR flow
        vm.stopPrank();

        // Simulate AMB message delivery
        _deliverAMBMessage(ARBI, OP, logs);

        vm.startPrank(deployer);

        uint256 initialFork = vm.activeFork();
        uint256 decimal1 = MockERC20(args.interimAsset).decimals();

        // Switch to Optimism fork
        vm.selectFork(FORKS[OP]);

        // Perform updateDeposit on CoreStateRegistry on Optimism
        CoreStateRegistry coreStateRegistry = CoreStateRegistry(getContract(OP, "CoreStateRegistry"));

        uint256 decimal2 = MockERC20(getContract(OP, "DAI")).decimals();

        uint256 expectedAmountToReceiveAfterBridge;
        if (decimal1 > decimal2) {
            expectedAmountToReceiveAfterBridge = totalAmountToDeposit / (10 ** (decimal1 - decimal2));
        } else {
            expectedAmountToReceiveAfterBridge = totalAmountToDeposit * 10 ** (decimal2 - decimal1);
        }
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = expectedAmountToReceiveAfterBridge;

        address[] memory bridgedTokens = new address[](1);
        bridgedTokens[0] = getContract(OP, "DAI");

        coreStateRegistry.updateDepositPayload(1, bridgedTokens, amounts);

        // Perform processPayload on CoreStateRegistry on Optimism
        uint256 nativeAmount = PaymentHelper(getContract(OP, "PaymentHelper")).estimateAckCost(1);
        vm.recordLogs();

        coreStateRegistry.processPayload{ value: nativeAmount }(1);
        logs = vm.getRecordedLogs();

        vm.stopPrank();

        // Simulate AMB message delivery
        _deliverAMBMessage(OP, ARBI, logs);

        vm.startPrank(deployer);
        // Switch back to Arbitrum fork
        vm.selectFork(initialFork);

        // Perform processPayload on Arbitrum to mint SuperPositions
        coreStateRegistry = CoreStateRegistry(getContract(ARBI, "CoreStateRegistry"));
        coreStateRegistry.processPayload(1);

        assertGt(SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId4OP), 0);
    }

    //////////////////////////////////////////////////////////////
    //                     INTERNAL                             //
    //////////////////////////////////////////////////////////////

    function _buildRebalanceSinglePositionToOneVaultArgs()
        internal
        view
        returns (ISuperformRouterPlus.RebalanceSinglePositionSyncArgs memory args)
    {
        args.id = superformId1;
        args.sharesToRedeem = SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId1);
        args.rebalanceFromMsgValue = 1 ether;
        args.rebalanceToMsgValue = 1 ether;
        args.interimAsset = getContract(ARBI, "USDC");
        args.slippage = 100;
        args.receiverAddressSP = deployer;
        args.callData = _callDataRebalanceFrom(args.interimAsset);

        uint256 decimal1 = MockERC20(getContract(ARBI, "DAI")).decimals();
        uint256 decimal2 = MockERC20(args.interimAsset).decimals();
        uint256 previewRedeemAmount = IBaseForm(superform1).previewRedeemFrom(args.sharesToRedeem);

        if (decimal1 > decimal2) {
            args.expectedAmountToReceivePostRebalanceFrom = previewRedeemAmount / (10 ** (decimal1 - decimal2));
        } else {
            args.expectedAmountToReceivePostRebalanceFrom = previewRedeemAmount * 10 ** (decimal2 - decimal1);
        }

        args.rebalanceToCallData =
            _callDataRebalanceToOneVaultSameChain(args.expectedAmountToReceivePostRebalanceFrom, args.interimAsset);
    }

    function _buildRebalanceSinglePositionToTwoVaultsArgs()
        internal
        view
        returns (ISuperformRouterPlus.RebalanceSinglePositionSyncArgs memory args)
    {
        args.id = superformId1;
        args.sharesToRedeem = SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId1);
        args.rebalanceFromMsgValue = 1 ether;
        args.rebalanceToMsgValue = 1 ether;
        args.interimAsset = getContract(ARBI, "USDC");
        args.slippage = 100;
        args.receiverAddressSP = deployer;
        args.callData = _callDataRebalanceFrom(args.interimAsset);

        uint256 decimal1 = MockERC20(getContract(ARBI, "DAI")).decimals();
        uint256 decimal2 = MockERC20(args.interimAsset).decimals();
        uint256 previewRedeemAmount = IBaseForm(superform1).previewRedeemFrom(args.sharesToRedeem);

        if (decimal1 > decimal2) {
            args.expectedAmountToReceivePostRebalanceFrom = previewRedeemAmount / (10 ** (decimal1 - decimal2));
        } else {
            args.expectedAmountToReceivePostRebalanceFrom = previewRedeemAmount * 10 ** (decimal2 - decimal1);
        }

        args.rebalanceToCallData =
            _callDataRebalanceToTwoVaultSameChain(args.expectedAmountToReceivePostRebalanceFrom, args.interimAsset);
    }

    function _buildRebalanceTwoPositionsToOneVaultXChainArgs()
        internal
        returns (ISuperformRouterPlus.RebalanceMultiPositionsSyncArgs memory args, uint256 totalAmountToDeposit)
    {
        args.ids = new uint256[](2);
        args.ids[0] = superformId1;
        args.ids[1] = superformId2;

        args.sharesToRedeem = new uint256[](2);
        args.sharesToRedeem[0] = SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId1);
        args.sharesToRedeem[1] = SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId2);

        args.rebalanceFromMsgValue = 1 ether;
        args.rebalanceToMsgValue = 1 ether;
        args.interimAsset = getContract(ARBI, "USDC");
        args.slippage = 100;
        args.receiverAddressSP = deployer;
        args.callData = _callDataRebalanceFromTwoVaults(args.interimAsset);

        uint256 decimal1 = MockERC20(getContract(ARBI, "DAI")).decimals();
        uint256 decimal2 = MockERC20(args.interimAsset).decimals();
        uint256 previewRedeemAmount1 = IBaseForm(superform1).previewRedeemFrom(args.sharesToRedeem[0]);

        uint256 expectedAmountToReceivePostRebalanceFrom1;
        if (decimal1 > decimal2) {
            expectedAmountToReceivePostRebalanceFrom1 = previewRedeemAmount1 / (10 ** (decimal1 - decimal2));
        } else {
            expectedAmountToReceivePostRebalanceFrom1 = previewRedeemAmount1 * 10 ** (decimal2 - decimal1);
        }

        uint256 previewRedeemAmount2 = IBaseForm(superform2).previewRedeemFrom(args.sharesToRedeem[1]);

        uint256 expectedAmountToReceivePostRebalanceFrom2;
        if (decimal1 > decimal2) {
            expectedAmountToReceivePostRebalanceFrom2 = previewRedeemAmount2 / (10 ** (decimal1 - decimal2));
        } else {
            expectedAmountToReceivePostRebalanceFrom2 = previewRedeemAmount2 * 10 ** (decimal2 - decimal1);
        }

        totalAmountToDeposit = expectedAmountToReceivePostRebalanceFrom1 + expectedAmountToReceivePostRebalanceFrom2;

        args.rebalanceToCallData = _callDataRebalanceToOneVaultxChain(totalAmountToDeposit, args.interimAsset);
    }

    function _callDataRebalanceFrom(address interimToken) internal view returns (bytes memory) {
        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ARBI, "DAI"),
            getContract(ARBI, "DAI"),
            interimToken,
            superform1,
            ARBI,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "SuperformRouterPlus"),
            uint256(ARBI),
            1e18,
            //1e18,
            true,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1,
            address(0)
        );

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId1,
            1e18,
            1e18,
            100,
            LiqRequest(_buildLiqBridgeTxData(liqBridgeTxDataArgs, false), interimToken, address(0), 1, ARBI, 0),
            "",
            false,
            false,
            ROUTER_PLUS_ARBI,
            deployer,
            ""
        );
        return abi.encodeCall(IBaseRouter.singleDirectSingleVaultWithdraw, SingleDirectSingleVaultStateReq(data));
    }

    function _callDataRebalanceFromTwoVaults(address interimToken) internal view returns (bytes memory) {
        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId1;
        superformIds[1] = superformId2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        uint256[] memory outputAmounts = new uint256[](2);
        outputAmounts[0] = 1e18;
        outputAmounts[1] = 1e18;

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 100;
        maxSlippages[1] = 100;

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ARBI, "DAI"),
            getContract(ARBI, "DAI"),
            interimToken,
            superform1,
            ARBI,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "SuperformRouterPlus"),
            uint256(ARBI),
            1e18,
            //1e18,
            true,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1,
            address(0)
        );

        liqReqs[0] = LiqRequest(_buildLiqBridgeTxData(liqBridgeTxDataArgs, true), interimToken, address(0), 1, ARBI, 0);
        liqReqs[1] = LiqRequest("", interimToken, address(0), 1, ARBI, 0);

        bool[] memory falseBool = new bool[](2);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReqs,
            "",
            falseBool,
            falseBool,
            ROUTER_PLUS_ARBI,
            deployer,
            ""
        );
        return abi.encodeCall(IBaseRouter.singleDirectMultiVaultWithdraw, SingleDirectMultiVaultStateReq(data));
    }

    function _callDataRebalanceToOneVaultSameChain(
        uint256 amountToDeposit,
        address interimToken
    )
        internal
        view
        returns (bytes memory)
    {
        SingleVaultSFData memory data = SingleVaultSFData(
            superformId2,
            amountToDeposit,
            IBaseForm(superform2).previewDepositTo(amountToDeposit),
            100,
            LiqRequest("", interimToken, address(0), 1, ARBI, 0),
            "",
            false,
            false,
            deployer,
            deployer,
            ""
        );
        return abi.encodeCall(IBaseRouter.singleDirectSingleVaultDeposit, SingleDirectSingleVaultStateReq(data));
    }

    function _callDataRebalanceToTwoVaultSameChain(
        uint256 amountToDeposit,
        address interimToken
    )
        internal
        view
        returns (bytes memory)
    {
        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId2;
        superformIds[1] = superformId3;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amountToDeposit / 2;
        amounts[1] = amountToDeposit / 2;

        uint256[] memory outputAmounts = new uint256[](2);
        outputAmounts[0] = IBaseForm(superform2).previewDepositTo(amounts[0]);
        outputAmounts[1] = IBaseForm(superform3).previewDepositTo(amounts[1]);

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 100;
        maxSlippages[1] = 100;

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest("", interimToken, address(0), 1, ARBI, 0);

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            interimToken,
            getContract(ARBI, "WETH"),
            getContract(ARBI, "WETH"),
            superform3,
            ARBI,
            ARBI,
            ARBI,
            false,
            superform3,
            uint256(ARBI),
            amounts[1],
            //1e18,
            false,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1,
            address(0)
        );

        // interimToken != vault asset here so we need txData
        liqReqs[1] = LiqRequest(_buildLiqBridgeTxData(liqBridgeTxDataArgs, true), interimToken, address(0), 1, ARBI, 0);

        bool[] memory falseBoolean = new bool[](2);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReqs,
            "",
            falseBoolean,
            falseBoolean,
            deployer,
            deployer,
            ""
        );
        return abi.encodeCall(IBaseRouter.singleDirectMultiVaultDeposit, SingleDirectMultiVaultStateReq(data));
    }

    function _callDataRebalanceToOneVaultxChain(
        uint256 amountToDeposit,
        address interimToken
    )
        internal
        returns (bytes memory)
    {
        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            interimToken,
            getContract(OP, "DAI"),
            getContract(OP, "DAI"),
            getContract(ARBI, "SuperformRouter"),
            ARBI,
            OP,
            OP,
            false,
            getContract(OP, "CoreStateRegistry"),
            uint256(OP),
            amountToDeposit,
            //1e18,
            false,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1,
            address(0)
        );
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[OP]);

        uint256 outputAmount = IBaseForm(superform4OP).previewDepositTo(amountToDeposit);
        vm.selectFork(initialFork);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId4OP,
            amountToDeposit,
            outputAmount,
            100,
            LiqRequest(_buildLiqBridgeTxData(liqBridgeTxDataArgs, false), interimToken, address(0), 1, OP, 0),
            "",
            false,
            false,
            deployer,
            deployer,
            ""
        );

        return
            abi.encodeCall(IBaseRouter.singleXChainSingleVaultDeposit, SingleXChainSingleVaultStateReq(AMBs, OP, data));
    }

    function _directDeposit(uint256 superformId) internal {
        vm.selectFork(FORKS[ARBI]);
        (address superform,,) = superformId.getSuperform();

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest("", IBaseForm(superform).getVaultAsset(), address(0), 1, ARBI, 0),
            "",
            false,
            false,
            deployer,
            deployer,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);
        MockERC20(IBaseForm(superform).getVaultAsset()).approve(
            address(payable(getContract(ARBI, "SuperformRouter"))), req.superformData.amount
        );

        /// @dev msg sender is wallet, tx origin is deployer
        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultDeposit{ value: 2 ether }(
            req
        );

        assertGt(SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId), 0);
    }

    function _deliverAMBMessage(uint64 fromChain, uint64 toChain, Vm.Log[] memory logs) internal {
        for (uint256 i = 0; i < AMBs.length; i++) {
            if (AMBs[i] == 2) {
                // Hyperlane
                HyperlaneHelper(getContract(fromChain, "HyperlaneHelper")).help(
                    address(HYPERLANE_MAILBOXES[fromChain]), address(HYPERLANE_MAILBOXES[toChain]), FORKS[toChain], logs
                );
            } else if (AMBs[i] == 3) {
                WormholeHelper(getContract(fromChain, "WormholeHelper")).help(
                    WORMHOLE_CHAIN_IDS[fromChain], FORKS[toChain], wormholeRelayer, logs
                );
            }
            // Add other AMB helpers as needed
        }
    }
}

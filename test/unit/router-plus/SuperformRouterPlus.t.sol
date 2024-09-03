// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";

import { ISuperformRouterPlus } from "src/interfaces/ISuperformRouterPlus.sol";
import { ISuperformRouterPlusAsync } from "src/interfaces/ISuperformRouterPlusAsync.sol";

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

    address superform5ETH;
    uint256 superformId5ETH;

    address ROUTER_PLUS_SOURCE;
    address ROUTER_PLUS_ASYNC_SOURCE;
    address SUPER_POSITIONS_SOURCE;

    uint64 SOURCE_CHAIN;

    function setUp() public override {
        super.setUp();
        AMBs = [2, 3];
        SOURCE_CHAIN = ARBI;
        vm.selectFork(FORKS[SOURCE_CHAIN]);

        superform1 = getContract(
            SOURCE_CHAIN, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        superformId1 = DataLib.packSuperform(superform1, FORM_IMPLEMENTATION_IDS[0], SOURCE_CHAIN);

        superform2 = getContract(
            SOURCE_CHAIN, string.concat("USDC", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        superformId2 = DataLib.packSuperform(superform2, FORM_IMPLEMENTATION_IDS[0], SOURCE_CHAIN);

        superform3 = getContract(
            SOURCE_CHAIN, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        superformId3 = DataLib.packSuperform(superform3, FORM_IMPLEMENTATION_IDS[0], SOURCE_CHAIN);

        superform4OP = getContract(
            OP, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        superformId4OP = DataLib.packSuperform(superform4OP, FORM_IMPLEMENTATION_IDS[0], OP);

        superform5ETH = getContract(
            ETH, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        superformId5ETH = DataLib.packSuperform(superform5ETH, FORM_IMPLEMENTATION_IDS[0], ETH);

        ROUTER_PLUS_SOURCE = getContract(SOURCE_CHAIN, "SuperformRouterPlus");
        ROUTER_PLUS_ASYNC_SOURCE = getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync");
        SUPER_POSITIONS_SOURCE = getContract(SOURCE_CHAIN, "SuperPositions");
    }

    function test_rebalanceFromSinglePosition_toOneVault() public {
        vm.startPrank(deployer);

        _directDeposit(superformId1);

        ISuperformRouterPlus.RebalanceSinglePositionSyncArgs memory args = _buildRebalanceSinglePositionToOneVaultArgs();

        SuperPositions(SUPER_POSITIONS_SOURCE).increaseAllowance(ROUTER_PLUS_SOURCE, superformId1, args.sharesToRedeem);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceSinglePosition{ value: 2 ether }(args);

        assertEq(SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId1), 0);

        assertGt(SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId2), 0);
    }

    function test_rebalanceFromSinglePosition_toTwoVaults() public {
        vm.startPrank(deployer);

        _directDeposit(superformId1);

        ISuperformRouterPlus.RebalanceSinglePositionSyncArgs memory args =
            _buildRebalanceSinglePositionToTwoVaultsArgs();

        SuperPositions(SUPER_POSITIONS_SOURCE).increaseAllowance(ROUTER_PLUS_SOURCE, superformId1, args.sharesToRedeem);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceSinglePosition{ value: 2 ether }(args);

        assertEq(SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId1), 0);

        assertGt(SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId2), 0);
    }

    function test_rebalanceFromTwoPositions_toOneXChainVault() public {
        vm.startPrank(deployer);

        _directDeposit(superformId1);
        _directDeposit(superformId2);

        (ISuperformRouterPlus.RebalanceMultiPositionsSyncArgs memory args, uint256 totalAmountToDeposit) =
            _buildRebalanceTwoPositionsToOneVaultXChainArgs();

        SuperPositions(SUPER_POSITIONS_SOURCE).increaseAllowance(
            ROUTER_PLUS_SOURCE, superformId1, args.sharesToRedeem[0]
        );
        SuperPositions(SUPER_POSITIONS_SOURCE).increaseAllowance(
            ROUTER_PLUS_SOURCE, superformId2, args.sharesToRedeem[1]
        );
        vm.recordLogs();

        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceMultiPositions{ value: 2 ether }(args);

        assertEq(SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId1), 0);
        assertEq(SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId2), 0);

        /// @dev have to perform remaining of async CSR flow
        vm.stopPrank();

        _processXChainDepositOneVault(SOURCE_CHAIN, OP, vm.getRecordedLogs(), getContract(OP, "DAI"), 1);

        assertGt(SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId4OP), 0);
    }

    function test_crossChainRebalanceSinglePosition_toOneVaultSameChain() public {
        vm.startPrank(deployer);

        // Step 1: Initial XCHAIN Deposit
        _xChainDeposit(superformId5ETH, ETH, 1);

        // Step 2: Start cross-chain rebalance
        vm.selectFork(FORKS[SOURCE_CHAIN]);
        ISuperformRouterPlus.InitiateXChainRebalanceArgs memory args = _buildInitiateXChainRebalanceArgs();

        SuperPositions(SUPER_POSITIONS_SOURCE).increaseAllowance(
            ROUTER_PLUS_SOURCE, superformId5ETH, args.sharesToRedeem
        );
        vm.recordLogs();
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalance{ value: 2 ether }(args);

        // Step 3: Process XChain Withdraw (rebalance from)
        uint256 balanceOfInterimAssetBefore =
            MockERC20(args.interimAsset).balanceOf(getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"));

        _processXChainWithdrawOneVault(ETH, SOURCE_CHAIN, vm.getRecordedLogs(), 2);

        vm.selectFork(FORKS[SOURCE_CHAIN]);
        uint256 balanceOfInterimAssetAfter =
            MockERC20(args.interimAsset).balanceOf(getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"));

        // Step 4: Complete cross-chain rebalance
        vm.startPrank(deployer);

        ISuperformRouterPlusAsync.CompleteCrossChainRebalanceArgs memory completeArgs =
        _buildCompleteCrossChainRebalanceArgs(
            balanceOfInterimAssetAfter - balanceOfInterimAssetBefore, superformId4OP, OP
        );

        vm.recordLogs();

        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).completeCrossChainRebalance{ value: 1 ether }(completeArgs);

        vm.stopPrank();

        _processXChainDepositOneVault(SOURCE_CHAIN, OP, vm.getRecordedLogs(), getContract(OP, "DAI"), 1);

        // Step 5: Verify the results
        vm.selectFork(FORKS[SOURCE_CHAIN]);
        assertEq(
            SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId5ETH),
            0,
            "Source superform balance should be 0"
        );

        assertGt(
            SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId4OP),
            0,
            "Destination superform balance should be greater than 0"
        );
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
        args.sharesToRedeem = SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId1);
        args.rebalanceFromMsgValue = 1 ether;
        args.rebalanceToMsgValue = 1 ether;
        args.interimAsset = getContract(SOURCE_CHAIN, "USDC");
        args.slippage = 100;
        args.receiverAddressSP = deployer;
        args.callData = _callDataRebalanceFrom(args.interimAsset);

        uint256 decimal1 = MockERC20(getContract(SOURCE_CHAIN, "DAI")).decimals();
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
        args.sharesToRedeem = SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId1);
        args.rebalanceFromMsgValue = 1 ether;
        args.rebalanceToMsgValue = 1 ether;
        args.interimAsset = getContract(SOURCE_CHAIN, "USDC");
        args.slippage = 100;
        args.receiverAddressSP = deployer;
        args.callData = _callDataRebalanceFrom(args.interimAsset);

        uint256 decimal1 = MockERC20(getContract(SOURCE_CHAIN, "DAI")).decimals();
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
        args.sharesToRedeem[0] = SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId1);
        args.sharesToRedeem[1] = SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId2);

        args.rebalanceFromMsgValue = 1 ether;
        args.rebalanceToMsgValue = 1 ether;
        args.interimAsset = getContract(SOURCE_CHAIN, "USDC");
        args.slippage = 100;
        args.receiverAddressSP = deployer;
        args.callData = _callDataRebalanceFromTwoVaults(args.interimAsset);

        uint256 decimal1 = MockERC20(getContract(SOURCE_CHAIN, "DAI")).decimals();
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

    function _buildInitiateXChainRebalanceArgs()
        internal
        returns (ISuperformRouterPlus.InitiateXChainRebalanceArgs memory args)
    {
        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[ETH]);
        args.id = superformId5ETH;
        args.sharesToRedeem = SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId5ETH);
        args.interimAsset = getContract(SOURCE_CHAIN, "USDC");
        args.receiverAddressSP = deployer;
        args.expectedAmountInterimAsset = IBaseForm(superform5ETH).previewRedeemFrom(args.sharesToRedeem);
        args.finalizeSlippage = 100; // 1%
        args.callData = _callDataRebalanceFromXChain(args.interimAsset, superformId5ETH, ETH);

        /// @dev rebalance to call data formulation for a xchain deposit
        args.rebalanceToSelector = IBaseRouter.singleXChainSingleVaultDeposit.selector;
        args.rebalanceToAmbIds = abi.encode(AMBs);
        args.rebalanceToDstChainIds = abi.encode(uint64(OP));

        /// data for a bridge from Router to Core State Registry
        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            args.interimAsset,
            getContract(OP, "DAI"),
            getContract(OP, "DAI"),
            getContract(SOURCE_CHAIN, "SuperformRouter"),
            SOURCE_CHAIN,
            OP,
            OP,
            false,
            getContract(OP, "CoreStateRegistry"),
            uint256(OP),
            1e18,
            //1e18,
            false,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1,
            address(0)
        );

        uint256 expectedAmountToReceiveAfterBridge = _convertDecimals(
            args.expectedAmountInterimAsset, args.interimAsset, getContract(OP, "DAI"), SOURCE_CHAIN, OP
        );

        uint256 expectedOutputAmount = IBaseForm(superform4OP).previewDepositTo(expectedAmountToReceiveAfterBridge);

        vm.selectFork(initialFork);

        SingleVaultSFData memory sfData = SingleVaultSFData({
            superformId: superformId4OP,
            amount: args.expectedAmountInterimAsset,
            outputAmount: expectedOutputAmount,
            maxSlippage: 100,
            liqRequest: LiqRequest({
                txData: _buildLiqBridgeTxData(liqBridgeTxDataArgs, false),
                token: args.interimAsset,
                interimToken: address(0),
                bridgeId: 1,
                liqDstChainId: OP,
                nativeAmount: 0
            }),
            permit2data: "",
            hasDstSwap: false,
            retain4626: false,
            receiverAddress: deployer,
            receiverAddressSP: deployer,
            extraFormData: ""
        });
        args.rebalanceToSfData = abi.encode(sfData);

        return args;
    }

    function _buildCompleteCrossChainRebalanceArgs(
        uint256 amountReceivedInterimAssetInRouterPlusAsync,
        uint256 superformIdRebalanceTo,
        uint64 chainIdRebalanceTo
    )
        internal
        returns (ISuperformRouterPlusAsync.CompleteCrossChainRebalanceArgs memory args)
    {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[chainIdRebalanceTo]);
        (address superform,,) = superformIdRebalanceTo.getSuperform();
        address underlyingToken = IBaseForm(superform4OP).getVaultAsset();
        vm.selectFork(initialFork);

        args.receiverAddressSP = deployer;
        args.routerPlusPayloadId = 1; // Assuming this is the first payload
        args.amountReceivedInterimAsset = amountReceivedInterimAssetInRouterPlusAsync;

        LiqRequest[][] memory liqRequests = new LiqRequest[][](1);
        liqRequests[0] = new LiqRequest[](1);
        liqRequests[0][0] = LiqRequest({
            txData: _buildLiqBridgeTxData(
                LiqBridgeTxDataArgs({
                    liqBridgeKind: 1,
                    externalToken: getContract(SOURCE_CHAIN, "USDC"),
                    underlyingToken: underlyingToken,
                    underlyingTokenDst: underlyingToken,
                    from: getContract(SOURCE_CHAIN, "SuperformRouter"),
                    srcChainId: SOURCE_CHAIN,
                    toChainId: chainIdRebalanceTo,
                    liqDstChainId: chainIdRebalanceTo,
                    dstSwap: false,
                    toDst: getContract(chainIdRebalanceTo, "CoreStateRegistry"),
                    liqBridgeToChainId: uint256(chainIdRebalanceTo),
                    amount: amountReceivedInterimAssetInRouterPlusAsync,
                    withdraw: false,
                    slippage: 100,
                    USDPerExternalToken: 1,
                    USDPerUnderlyingTokenDst: 1,
                    USDPerUnderlyingToken: 1,
                    deBridgeRefundAddress: address(0)
                }),
                false
            ),
            token: getContract(SOURCE_CHAIN, "USDC"),
            interimToken: underlyingToken,
            bridgeId: 1,
            liqDstChainId: chainIdRebalanceTo,
            nativeAmount: 0
        });
        args.liqRequests = liqRequests;

        args.newAmounts = new uint256[][](1);
        args.newAmounts[0] = new uint256[](1);
        args.newAmounts[0][0] = amountReceivedInterimAssetInRouterPlusAsync;

        uint256 underlyingAmount = _convertDecimals(
            amountReceivedInterimAssetInRouterPlusAsync,
            getContract(SOURCE_CHAIN, "USDC"),
            underlyingToken,
            SOURCE_CHAIN,
            chainIdRebalanceTo
        );

        args.newOutputAmounts = new uint256[][](1);
        args.newOutputAmounts[0] = new uint256[](1);
        args.newOutputAmounts[0][0] = IBaseForm(superform).previewDepositTo(underlyingAmount);

        vm.selectFork(initialFork);
        return args;
    }

    function _callDataRebalanceFrom(address interimToken) internal view returns (bytes memory) {
        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(SOURCE_CHAIN, "DAI"),
            getContract(SOURCE_CHAIN, "DAI"),
            interimToken,
            superform1,
            SOURCE_CHAIN,
            SOURCE_CHAIN,
            SOURCE_CHAIN,
            false,
            getContract(SOURCE_CHAIN, "SuperformRouterPlus"),
            uint256(SOURCE_CHAIN),
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
            LiqRequest(_buildLiqBridgeTxData(liqBridgeTxDataArgs, false), interimToken, address(0), 1, SOURCE_CHAIN, 0),
            "",
            false,
            false,
            ROUTER_PLUS_SOURCE,
            deployer,
            ""
        );
        return abi.encodeCall(IBaseRouter.singleDirectSingleVaultWithdraw, SingleDirectSingleVaultStateReq(data));
    }

    function _callDataRebalanceFromXChain(
        address interimToken,
        uint256 superformId,
        uint64 superformChainId
    )
        internal
        returns (bytes memory)
    {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[superformChainId]);
        (address superform,,) = superformId.getSuperform();
        address underlyingToken = IBaseForm(superform).getVaultAsset();

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            underlyingToken,
            underlyingToken,
            interimToken,
            superform,
            superformChainId,
            SOURCE_CHAIN,
            SOURCE_CHAIN,
            false,
            getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"),
            uint256(SOURCE_CHAIN),
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
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest(_buildLiqBridgeTxData(liqBridgeTxDataArgs, false), interimToken, address(0), 1, SOURCE_CHAIN, 0),
            "",
            false,
            false,
            ROUTER_PLUS_SOURCE,
            deployer,
            ""
        );
        vm.selectFork(initialFork);
        return abi.encodeCall(
            IBaseRouter.singleXChainSingleVaultWithdraw, SingleXChainSingleVaultStateReq(AMBs, SOURCE_CHAIN, data)
        );
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
            getContract(SOURCE_CHAIN, "DAI"),
            getContract(SOURCE_CHAIN, "DAI"),
            interimToken,
            superform1,
            SOURCE_CHAIN,
            SOURCE_CHAIN,
            SOURCE_CHAIN,
            false,
            getContract(SOURCE_CHAIN, "SuperformRouterPlus"),
            uint256(SOURCE_CHAIN),
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

        liqReqs[0] =
            LiqRequest(_buildLiqBridgeTxData(liqBridgeTxDataArgs, true), interimToken, address(0), 1, SOURCE_CHAIN, 0);
        liqReqs[1] = LiqRequest("", interimToken, address(0), 1, SOURCE_CHAIN, 0);

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
            ROUTER_PLUS_SOURCE,
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
            LiqRequest("", interimToken, address(0), 1, SOURCE_CHAIN, 0),
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
        liqReqs[0] = LiqRequest("", interimToken, address(0), 1, SOURCE_CHAIN, 0);

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            interimToken,
            getContract(SOURCE_CHAIN, "WETH"),
            getContract(SOURCE_CHAIN, "WETH"),
            superform3,
            SOURCE_CHAIN,
            SOURCE_CHAIN,
            SOURCE_CHAIN,
            false,
            superform3,
            uint256(SOURCE_CHAIN),
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
        liqReqs[1] =
            LiqRequest(_buildLiqBridgeTxData(liqBridgeTxDataArgs, true), interimToken, address(0), 1, SOURCE_CHAIN, 0);

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
            getContract(SOURCE_CHAIN, "SuperformRouter"),
            SOURCE_CHAIN,
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
        vm.selectFork(FORKS[SOURCE_CHAIN]);
        (address superform,,) = superformId.getSuperform();

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest("", IBaseForm(superform).getVaultAsset(), address(0), 1, SOURCE_CHAIN, 0),
            "",
            false,
            false,
            deployer,
            deployer,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);
        MockERC20(IBaseForm(superform).getVaultAsset()).approve(
            address(payable(getContract(SOURCE_CHAIN, "SuperformRouter"))), req.superformData.amount
        );

        /// @dev msg sender is wallet, tx origin is deployer
        SuperformRouter(payable(getContract(SOURCE_CHAIN, "SuperformRouter"))).singleDirectSingleVaultDeposit{
            value: 2 ether
        }(req);

        assertGt(SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId), 0);
    }

    function _xChainDeposit(uint256 superformId, uint64 dstChainId, uint256 payloadIdToProcess) internal {
        (address superform,,) = superformId.getSuperform();

        vm.selectFork(FORKS[dstChainId]);

        address underlyingToken = IBaseForm(superform).getVaultAsset();

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest(
                _buildLiqBridgeTxData(
                    LiqBridgeTxDataArgs(
                        1,
                        getContract(SOURCE_CHAIN, "DAI"),
                        underlyingToken,
                        underlyingToken,
                        getContract(SOURCE_CHAIN, "SuperformRouter"),
                        SOURCE_CHAIN,
                        dstChainId,
                        dstChainId,
                        false,
                        getContract(dstChainId, "CoreStateRegistry"),
                        uint256(dstChainId),
                        1e18,
                        //1e18,
                        false,
                        /// @dev placeholder value, not used
                        0,
                        1,
                        1,
                        1,
                        address(0)
                    ),
                    false
                ),
                underlyingToken,
                address(0),
                1,
                dstChainId,
                0
            ),
            "",
            false,
            false,
            deployer,
            deployer,
            ""
        );
        vm.selectFork(FORKS[SOURCE_CHAIN]);

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(AMBs, dstChainId, data);
        MockERC20(getContract(SOURCE_CHAIN, "DAI")).approve(
            address(payable(getContract(SOURCE_CHAIN, "SuperformRouter"))), req.superformData.amount
        );

        vm.recordLogs();
        /// @dev msg sender is wallet, tx origin is deployer
        SuperformRouter(payable(getContract(SOURCE_CHAIN, "SuperformRouter"))).singleXChainSingleVaultDeposit{
            value: 2 ether
        }(req);

        _processXChainDepositOneVault(
            SOURCE_CHAIN, dstChainId, vm.getRecordedLogs(), underlyingToken, payloadIdToProcess
        );

        vm.selectFork(FORKS[SOURCE_CHAIN]);

        assertGt(SuperPositions(getContract(SOURCE_CHAIN, "SuperPositions")).balanceOf(deployer, superformId), 0);
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

    function _convertDecimals(
        uint256 amount,
        address token1,
        address token2,
        uint64 chainId1,
        uint64 chainId2
    )
        internal
        returns (uint256 convertedAmount)
    {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[chainId1]);
        uint256 decimals1 = MockERC20(token1).decimals();
        vm.selectFork(FORKS[chainId2]);
        uint256 decimals2 = MockERC20(token2).decimals();

        if (decimals1 > decimals2) {
            convertedAmount = amount / (10 ** (decimals1 - decimals2));
        } else {
            convertedAmount = amount * 10 ** (decimals2 - decimals1);
        }
        vm.selectFork(initialFork);
    }

    function _processXChainDepositOneVault(
        uint64 fromChain,
        uint64 toChain,
        Vm.Log[] memory logs,
        address destinationToken,
        uint256 payloadIdToProcess
    )
        internal
    {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[toChain]);
        uint256 balanceOfInterimAssetBefore =
            IERC20(destinationToken).balanceOf(getContract(toChain, "CoreStateRegistry"));

        // Simulate AMB message delivery
        _deliverAMBMessage(fromChain, toChain, logs);

        vm.selectFork(FORKS[toChain]);
        uint256 balanceOfInterimAssetAfter =
            IERC20(destinationToken).balanceOf(getContract(toChain, "CoreStateRegistry"));

        vm.selectFork(initialFork);

        vm.startPrank(deployer);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = balanceOfInterimAssetAfter - balanceOfInterimAssetBefore;

        address[] memory bridgedTokens = new address[](1);
        bridgedTokens[0] = destinationToken;

        CoreStateRegistry coreStateRegistry = CoreStateRegistry(getContract(toChain, "CoreStateRegistry"));

        coreStateRegistry.updateDepositPayload(payloadIdToProcess, bridgedTokens, amounts);

        // Perform processPayload on CoreStateRegistry on destination chain
        uint256 nativeAmount = PaymentHelper(getContract(toChain, "PaymentHelper")).estimateAckCost(payloadIdToProcess);
        vm.recordLogs();

        coreStateRegistry.processPayload{ value: nativeAmount }(payloadIdToProcess);
        logs = vm.getRecordedLogs();

        vm.stopPrank();

        // Simulate AMB message delivery back to source chain
        _deliverAMBMessage(toChain, fromChain, logs);

        vm.startPrank(deployer);
        // Switch back to source chain fork
        vm.selectFork(FORKS[fromChain]);

        // Perform processPayload on source chain to mint SuperPositions
        coreStateRegistry = CoreStateRegistry(getContract(fromChain, "CoreStateRegistry"));
        coreStateRegistry.processPayload(payloadIdToProcess);

        vm.stopPrank();
    }

    function _processXChainWithdrawOneVault(
        uint64 fromChain,
        uint64 toChain,
        Vm.Log[] memory logs,
        uint256 payloadIdToProcess
    )
        internal
    {
        // Simulate AMB message delivery
        _deliverAMBMessage(fromChain, toChain, logs);

        vm.selectFork(FORKS[toChain]);
        CoreStateRegistry coreStateRegistry = CoreStateRegistry(getContract(toChain, "CoreStateRegistry"));

        // Perform processPayload on CoreStateRegistry on destination chain
        uint256 nativeAmount = PaymentHelper(getContract(toChain, "PaymentHelper")).estimateAckCost(payloadIdToProcess);
        vm.recordLogs();

        coreStateRegistry.processPayload{ value: nativeAmount }(payloadIdToProcess);
        logs = vm.getRecordedLogs();

        vm.stopPrank();
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";

import { ISuperformRouterPlus } from "src/interfaces/ISuperformRouterPlus.sol";

import { IBaseRouter } from "src/interfaces/IBaseRouter.sol";

contract SuperformRouterPlusTest is ProtocolActions {
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

    address ROUTER_PLUS_ARBI;
    address SUPER_POSITIONS_ARBI;

    function setUp() public override {
        super.setUp();
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

        ROUTER_PLUS_ARBI = getContract(ARBI, "SuperformRouterPlus");

        SUPER_POSITIONS_ARBI = getContract(ARBI, "SuperPositions");
    }

    function test_rebalanceFromSinglePosition_toOneVault() public {
        vm.startPrank(deployer);

        _directDeposit(false);

        ISuperformRouterPlus.RebalanceSinglePositionSyncArgs memory args = _buildRebalanceSinglePositionToOneVaultArgs();

        SuperPositions(SUPER_POSITIONS_ARBI).increaseAllowance(ROUTER_PLUS_ARBI, superformId1, args.sharesToRedeem);
        SuperformRouterPlus(ROUTER_PLUS_ARBI).rebalanceSinglePosition{ value: 2 ether }(args);

        assertEq(SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId1), 0);

        assertGt(SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId2), 0);
    }

    function test_rebalanceFromSinglePosition_toTwoVaults() public {
        vm.startPrank(deployer);

        _directDeposit(false);

        ISuperformRouterPlus.RebalanceSinglePositionSyncArgs memory args =
            _buildRebalanceSinglePositionToTwoVaultsArgs();

        SuperPositions(SUPER_POSITIONS_ARBI).increaseAllowance(ROUTER_PLUS_ARBI, superformId1, args.sharesToRedeem);
        SuperformRouterPlus(ROUTER_PLUS_ARBI).rebalanceSinglePosition{ value: 2 ether }(args);

        assertEq(SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId1), 0);

        assertGt(SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId2), 0);
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

    function _directDeposit(bool receive4626_) internal {
        vm.selectFork(FORKS[ARBI]);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId1,
            1e18,
            1e18,
            100,
            LiqRequest("", getContract(ARBI, "DAI"), address(0), 1, ARBI, 0),
            "",
            false,
            receive4626_,
            deployer,
            deployer,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        MockERC20(getContract(ARBI, "DAI")).approve(
            address(payable(getContract(ARBI, "SuperformRouter"))), req.superformData.amount
        );

        /// @dev msg sender is wallet, tx origin is deployer
        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultDeposit{ value: 2 ether }(
            req
        );

        if (!receive4626_) {
            assertGt(SuperPositions(SUPER_POSITIONS_ARBI).balanceOf(deployer, superformId1), 0);
        }
    }
}

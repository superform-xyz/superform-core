// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";
import { ISuperformRouterPlus } from "src/interfaces/ISuperformRouterPlus.sol";
import { ISuperformRouterPlusAsync } from "src/interfaces/ISuperformRouterPlusAsync.sol";
import { IBaseSuperformRouterPlus } from "src/interfaces/IBaseSuperformRouterPlus.sol";
import { IBaseRouter } from "src/interfaces/IBaseRouter.sol";
import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract RejectEther {
    // This function will revert when called, simulating a contract that can't receive native tokens
    receive() external payable {
        revert("Cannot receive native tokens");
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function supportsInterface(bytes4) external pure returns (bool) {
        return true;
    }
}

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
    address superform6ETH;

    uint256 superformId5ETH;
    uint256 superformId6ETH;

    address ROUTER_PLUS_SOURCE;
    address ROUTER_PLUS_ASYNC_SOURCE;
    address SUPER_POSITIONS_SOURCE;

    uint64 SOURCE_CHAIN;

    function setUp() public override {
        super.setUp();
        MULTI_TX_SLIPPAGE_SHARE = 0;
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

        superform6ETH = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        superformId6ETH = DataLib.packSuperform(superform6ETH, FORM_IMPLEMENTATION_IDS[0], ETH);

        ROUTER_PLUS_SOURCE = getContract(SOURCE_CHAIN, "SuperformRouterPlus");
        ROUTER_PLUS_ASYNC_SOURCE = getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync");
        SUPER_POSITIONS_SOURCE = getContract(SOURCE_CHAIN, "SuperPositions");
    }

    //////////////////////////////////////////////////////////////
    //                   ROUTER PLUS UNIT TESTS                 //
    //////////////////////////////////////////////////////////////

    function test_zeroAddressConstructor() public {
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new SuperformRouterPlus(address(0));
    }

    function test_supportsInterface() public view {
        /// @dev IERC165 interfaceId
        bytes4 interfaceId = 0x01ffc9a7;
        assertTrue(SuperformRouterPlus(ROUTER_PLUS_SOURCE).supportsInterface(interfaceId));

        interfaceId = 0xffffffff;
        assertFalse(SuperformRouterPlus(ROUTER_PLUS_SOURCE).supportsInterface(interfaceId));
    }

    function test_forwardDustToPaymaster_fromRouterPlus() public {
        address dustToken = getContract(ARBI, "DAI");
        deal(dustToken, ROUTER_PLUS_SOURCE, 1 ether);

        SuperformRouterPlus(ROUTER_PLUS_SOURCE).forwardDustToPaymaster(dustToken);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).forwardDustToPaymaster(address(0));
    }

    function test_rebalanceMultiPositions_arrayLengthMismatch() public {
        vm.startPrank(deployer);

        // Set up test data
        uint256[] memory ids = new uint256[](2);
        ids[0] = superformId1;
        ids[1] = superformId2;

        uint256[] memory sharesToRedeem = new uint256[](1); // Mismatch in length
        sharesToRedeem[0] = 1e18;

        ISuperformRouterPlus.RebalanceMultiPositionsSyncArgs memory args = ISuperformRouterPlus
            .RebalanceMultiPositionsSyncArgs({
            ids: ids,
            sharesToRedeem: sharesToRedeem,
            rebalanceFromMsgValue: 1 ether,
            rebalanceToMsgValue: 1 ether,
            interimAsset: getContract(SOURCE_CHAIN, "USDC"),
            slippage: 100,
            receiverAddressSP: deployer,
            callData: new bytes(0),
            rebalanceToCallData: new bytes(0),
            expectedAmountToReceivePostRebalanceFrom: 1e18
        });

        // Expect the function to revert with ARRAY_LENGTH_MISMATCH error
        vm.expectRevert(Error.ARRAY_LENGTH_MISMATCH.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceMultiPositions{ value: 2 ether }(args);

        vm.stopPrank();
    }

    function test_startCrossChainRebalance_allErrors() public {
        // Setup base valid arguments
        ISuperformRouterPlus.InitiateXChainRebalanceArgs memory args = _setupValidXChainRebalanceArgs();

        // Test ZERO_ADDRESS error
        args.interimAsset = address(0);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalance{ value: 2 ether }(args);

        args = _setupValidXChainRebalanceArgs();
        args.receiverAddressSP = address(0);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalance{ value: 2 ether }(args);

        // Test ZERO_AMOUNT error
        args = _setupValidXChainRebalanceArgs();
        args.expectedAmountInterimAsset = 0;
        vm.expectRevert(Error.ZERO_AMOUNT.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalance{ value: 2 ether }(args);

        // Test INVALID_REBALANCE_FROM_SELECTOR error
        args = _setupValidXChainRebalanceArgs();
        args.callData = abi.encodeWithSelector(bytes4(keccak256("invalidSelector()")));
        vm.expectRevert(ISuperformRouterPlus.INVALID_REBALANCE_FROM_SELECTOR.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalance{ value: 2 ether }(args);

        // Test REBALANCE_SINGLE_POSITIONS_DIFFERENT_TOKEN error
        args = _setupValidXChainRebalanceArgs();
        args.interimAsset = address(0x123); // Different from the one in callData
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_SINGLE_POSITIONS_DIFFERENT_TOKEN.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalance{ value: 2 ether }(args);

        // Test REBALANCE_SINGLE_POSITIONS_DIFFERENT_CHAIN error
        args = _setupValidXChainRebalanceArgs();
        SingleXChainSingleVaultStateReq memory req =
            abi.decode(_parseCallData(args.callData), (SingleXChainSingleVaultStateReq));
        req.superformData.liqRequest.liqDstChainId = 9999; // Different chain
        args.callData = abi.encodeWithSelector(IBaseRouter.singleXChainSingleVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_SINGLE_POSITIONS_DIFFERENT_CHAIN.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalance{ value: 2 ether }(args);

        // Test REBALANCE_SINGLE_POSITIONS_DIFFERENT_AMOUNT error
        args = _setupValidXChainRebalanceArgs();
        req = abi.decode(_parseCallData(args.callData), (SingleXChainSingleVaultStateReq));
        req.superformData.amount = args.sharesToRedeem - 1; // Different amount
        args.callData = abi.encodeWithSelector(IBaseRouter.singleXChainSingleVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_SINGLE_POSITIONS_DIFFERENT_AMOUNT.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalance{ value: 2 ether }(args);

        // Test REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS error
        args = _setupValidXChainRebalanceArgs();
        req = abi.decode(_parseCallData(args.callData), (SingleXChainSingleVaultStateReq));
        req.superformData.receiverAddress = address(0x123); // Invalid receiver
        args.callData = abi.encodeWithSelector(IBaseRouter.singleXChainSingleVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalance{ value: 2 ether }(args);

        // Test INVALID_DEPOSIT_SELECTOR error
        args = _setupValidXChainRebalanceArgs();
        args.rebalanceToSelector = bytes4(keccak256("invalidDepositSelector()"));
        vm.expectRevert(ISuperformRouterPlus.INVALID_DEPOSIT_SELECTOR.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalance{ value: 2 ether }(args);

        vm.stopPrank();
    }

    function test_startCrossChainRebalanceMulti_singleXChainMultiVaultWithdraw_allErrors() public {
        // Setup base valid arguments
        ISuperformRouterPlus.InitiateXChainRebalanceMultiArgs memory args = _setupValidXChainRebalanceMultiArgs();

        // Test ARRAY_LENGTH_MISMATCH error
        args.ids = new uint256[](2);
        args.sharesToRedeem = new uint256[](1);
        vm.expectRevert(Error.ARRAY_LENGTH_MISMATCH.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 3 ether }(args);

        // Reset args
        args = _setupValidXChainRebalanceMultiArgs();

        // Test ZERO_ADDRESS error
        args.interimAsset = address(0);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 3 ether }(args);

        args = _setupValidXChainRebalanceMultiArgs();
        args.receiverAddressSP = address(0);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 3 ether }(args);

        // Test ZERO_AMOUNT error
        args = _setupValidXChainRebalanceMultiArgs();
        args.expectedAmountInterimAsset = 0;
        vm.expectRevert(Error.ZERO_AMOUNT.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 3 ether }(args);

        // Test INVALID_REBALANCE_FROM_SELECTOR error
        args = _setupValidXChainRebalanceMultiArgs();
        args.callData = abi.encodeWithSelector(bytes4(keccak256("invalidSelector()")));
        vm.expectRevert(ISuperformRouterPlus.INVALID_REBALANCE_FROM_SELECTOR.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 3 ether }(args);

        // Test errors for singleXChainMultiVaultWithdraw
        args = _setupValidXChainRebalanceMultiArgs();
        args.callData = _buildSingleXChainMultiVaultWithdrawCallData(args.interimAsset, args.ids, ETH);

        // Test REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN error
        SingleXChainMultiVaultStateReq memory req =
            abi.decode(_parseCallData(args.callData), (SingleXChainMultiVaultStateReq));
        req.superformsData.liqRequests[0].token = address(0x123);
        args.callData = abi.encodeWithSelector(IBaseRouter.singleXChainMultiVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 3 ether }(args);

        // Test REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN error
        args = _setupValidXChainRebalanceMultiArgs();
        args.callData = _buildSingleXChainMultiVaultWithdrawCallData(args.interimAsset, args.ids, ETH);
        req = abi.decode(_parseCallData(args.callData), (SingleXChainMultiVaultStateReq));
        req.superformsData.liqRequests[0].liqDstChainId = 9999;
        args.callData = abi.encodeWithSelector(IBaseRouter.singleXChainMultiVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 3 ether }(args);

        // Test REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS error
        args = _setupValidXChainRebalanceMultiArgs();
        args.callData = _buildSingleXChainMultiVaultWithdrawCallData(args.interimAsset, args.ids, ETH);
        req = abi.decode(_parseCallData(args.callData), (SingleXChainMultiVaultStateReq));
        req.superformsData.amounts[0] = args.sharesToRedeem[0] + 1;
        args.callData = abi.encodeWithSelector(IBaseRouter.singleXChainMultiVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 3 ether }(args);

        // Test REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS error
        args = _setupValidXChainRebalanceMultiArgs();
        args.callData = _buildSingleXChainMultiVaultWithdrawCallData(args.interimAsset, args.ids, ETH);
        req = abi.decode(_parseCallData(args.callData), (SingleXChainMultiVaultStateReq));
        req.superformsData.receiverAddress = address(0x123);
        args.callData = abi.encodeWithSelector(IBaseRouter.singleXChainMultiVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 3 ether }(args);

        vm.stopPrank();
    }

    function test_startCrossChainRebalanceMulti_multiDstMultiVaultWithdraw_allErrors() public {
        vm.startPrank(deployer);

        uint64 REBALANCE_FROM_1 = ETH;
        uint64 REBALANCE_FROM_2 = OP;
        uint64 REBALANCE_TO = OP;

        _xChainDeposit(superformId5ETH, REBALANCE_FROM_1, 1);

        vm.startPrank(deployer);
        _xChainDeposit(superformId6ETH, REBALANCE_FROM_1, 2);

        vm.startPrank(deployer);
        _xChainDeposit(superformId4OP, REBALANCE_FROM_2, 1);

        vm.selectFork(FORKS[SOURCE_CHAIN]);
        ISuperformRouterPlus.InitiateXChainRebalanceMultiArgs memory args =
            _buildInitiateXChainRebalanceMultiDstToMultiArgs(REBALANCE_FROM_1, REBALANCE_FROM_2, REBALANCE_TO);

        vm.startPrank(deployer);
        SuperPositions(SUPER_POSITIONS_SOURCE).setApprovalForAll(ROUTER_PLUS_SOURCE, true);

        // Test REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN error
        args.interimAsset = getContract(SOURCE_CHAIN, "WETH");
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 3 ether }(args);

        // Test REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN error
        args = _buildInitiateXChainRebalanceMultiDstToMultiArgs(REBALANCE_FROM_1, REBALANCE_FROM_2, REBALANCE_TO);
        MultiDstMultiVaultStateReq memory req = abi.decode(_parseCallData(args.callData), (MultiDstMultiVaultStateReq));
        req.superformsData[0].liqRequests[0].liqDstChainId = ETH;
        args.callData = abi.encodeWithSelector(IBaseRouter.multiDstMultiVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 3 ether }(args);

        // Test REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS error
        args = _buildInitiateXChainRebalanceMultiDstToMultiArgs(REBALANCE_FROM_1, REBALANCE_FROM_2, REBALANCE_TO);
        req = abi.decode(_parseCallData(args.callData), (MultiDstMultiVaultStateReq));
        req.superformsData[0].amounts[0] = req.superformsData[0].amounts[0] - 1;
        args.callData = abi.encodeWithSelector(IBaseRouter.multiDstMultiVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 3 ether }(args);

        // Test REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS error
        args = _buildInitiateXChainRebalanceMultiDstToMultiArgs(REBALANCE_FROM_1, REBALANCE_FROM_2, REBALANCE_TO);
        req = abi.decode(_parseCallData(args.callData), (MultiDstMultiVaultStateReq));
        req.superformsData[0].receiverAddress = address(0x123);
        args.callData = abi.encodeWithSelector(IBaseRouter.multiDstMultiVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 3 ether }(args);
    }

    function test_startCrossChainRebalanceMulti_multiDstSingleVaultWithdraw_allErrors() public {
        vm.startPrank(deployer);

        uint64 REBALANCE_FROM_1 = ETH;
        uint64 REBALANCE_FROM_2 = OP;
        uint64 REBALANCE_TO = OP;

        // Step 1: Initial XCHAIN Deposits
        _xChainDeposit(superformId5ETH, REBALANCE_FROM_1, 1);

        vm.startPrank(deployer);
        _xChainDeposit(superformId4OP, REBALANCE_FROM_2, 1);

        // // Step 2: Start cross-chain rebalance
        vm.selectFork(FORKS[SOURCE_CHAIN]);
        ISuperformRouterPlus.InitiateXChainRebalanceMultiArgs memory args =
            _buildInitiateXChainRebalanceMultiDstArgs(REBALANCE_FROM_1, REBALANCE_FROM_2, REBALANCE_TO);

        vm.startPrank(deployer);

        SuperPositions(SUPER_POSITIONS_SOURCE).setApprovalForAll(ROUTER_PLUS_SOURCE, true);

        // Test REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN error
        args.interimAsset = getContract(SOURCE_CHAIN, "WETH");
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 4 ether }(args);

        // Test REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN error
        args = _buildInitiateXChainRebalanceMultiDstArgs(REBALANCE_FROM_1, REBALANCE_FROM_2, REBALANCE_TO);
        MultiDstSingleVaultStateReq memory req =
            abi.decode(_parseCallData(args.callData), (MultiDstSingleVaultStateReq));
        req.superformsData[0].liqRequest.liqDstChainId = ETH;
        args.callData = abi.encodeWithSelector(IBaseRouter.multiDstSingleVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 4 ether }(args);

        // Test REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS error
        args = _buildInitiateXChainRebalanceMultiDstArgs(REBALANCE_FROM_1, REBALANCE_FROM_2, REBALANCE_TO);
        req = abi.decode(_parseCallData(args.callData), (MultiDstSingleVaultStateReq));
        req.superformsData[0].amount = req.superformsData[0].amount - 1;
        args.callData = abi.encodeWithSelector(IBaseRouter.multiDstSingleVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 4 ether }(args);

        // Test REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS error
        args = _buildInitiateXChainRebalanceMultiDstArgs(REBALANCE_FROM_1, REBALANCE_FROM_2, REBALANCE_TO);
        req = abi.decode(_parseCallData(args.callData), (MultiDstSingleVaultStateReq));
        req.superformsData[0].receiverAddress = address(0x123);
        args.callData = abi.encodeWithSelector(IBaseRouter.multiDstSingleVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 4 ether }(args);

        // Test INVALID_DEPOSIT_SELECTOR error
        args = _buildInitiateXChainRebalanceMultiDstArgs(REBALANCE_FROM_1, REBALANCE_FROM_2, REBALANCE_TO);
        args.rebalanceToSelector = bytes4(keccak256("invalidSelector()"));
        vm.expectRevert(ISuperformRouterPlus.INVALID_DEPOSIT_SELECTOR.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 4 ether }(args);
    }

    function test_deposit4626_invalidDepositSelector() public {
        vm.startPrank(deployer);

        // Deploy a mock ERC4626 vault
        VaultMock mockVault = new VaultMock(IERC20(getContract(SOURCE_CHAIN, "DAI")), "Mock Vault", "mVLT");

        // Mint some DAI to the deployer
        uint256 daiAmount = 1e18;

        // Approve and deposit DAI into the mock vault
        MockERC20(getContract(SOURCE_CHAIN, "DAI")).approve(address(mockVault), daiAmount);
        uint256 vaultTokenAmount = mockVault.deposit(daiAmount, deployer);

        // Prepare deposit4626 args with an invalid deposit selector
        ISuperformRouterPlus.Deposit4626Args memory args = ISuperformRouterPlus.Deposit4626Args({
            amount: vaultTokenAmount,
            expectedOutputAmount: daiAmount,
            maxSlippage: 100, // 1%
            receiverAddressSP: deployer,
            depositCallData: abi.encodeWithSelector(bytes4(keccak256("invalidDepositSelector()")), superformId1, daiAmount)
        });

        // Approve RouterPlus to spend vault tokens
        mockVault.approve(ROUTER_PLUS_SOURCE, vaultTokenAmount);

        // Expect the function to revert with INVALID_DEPOSIT_SELECTOR error
        vm.expectRevert(ISuperformRouterPlus.INVALID_DEPOSIT_SELECTOR.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).deposit4626{ value: 1 ether }(address(mockVault), args);

        vm.stopPrank();
    }

    function test_rebalanceSinglePosition_zeroAddressInterimAsset() public {
        vm.startPrank(deployer);

        ISuperformRouterPlus.RebalanceSinglePositionSyncArgs memory args =
            _buildRebalanceSinglePositionToOneVaultArgs(deployer);
        args.interimAsset = address(0); // Set interim asset to zero address

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceSinglePosition{ value: 2 ether }(args);

        vm.stopPrank();
    }

    function test_rebalanceSinglePosition_zeroAddressReceiverAddressSP() public {
        vm.startPrank(deployer);

        ISuperformRouterPlus.RebalanceSinglePositionSyncArgs memory args =
            _buildRebalanceSinglePositionToOneVaultArgs(deployer);
        args.receiverAddressSP = address(0); // Set receiver address to zero address

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceSinglePosition{ value: 2 ether }(args);

        vm.stopPrank();
    }

    function test_rebalanceSinglePosition_invalidFee() public {
        vm.startPrank(deployer);

        ISuperformRouterPlus.RebalanceSinglePositionSyncArgs memory args =
            _buildRebalanceSinglePositionToOneVaultArgs(deployer);
        args.rebalanceFromMsgValue = 1 ether;
        args.rebalanceToMsgValue = 1 ether;

        // Send less value than required
        vm.expectRevert(ISuperformRouterPlus.INVALID_FEE.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceSinglePosition{ value: 1.5 ether }(args);

        vm.stopPrank();
    }

    function test_refundUnusedAndResetApprovals_failedToSendNative() public {
        address rejectEther = address(new RejectEther());
        deal(rejectEther, 3 ether);

        vm.startPrank(deployer);
        _directDeposit(superformId1);

        SuperPositions(SUPER_POSITIONS_SOURCE).safeTransferFrom(deployer, rejectEther, superformId1, 1e18, abi.encode());

        ISuperformRouterPlus.RebalanceSinglePositionSyncArgs memory args =
            _buildRebalanceSinglePositionToOneVaultArgs(rejectEther);

        vm.startPrank(rejectEther);
        SuperPositions(SUPER_POSITIONS_SOURCE).increaseAllowance(ROUTER_PLUS_SOURCE, superformId1, args.sharesToRedeem);
        vm.expectRevert(Error.FAILED_TO_SEND_NATIVE.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceSinglePosition{ value: 3 ether }(args);

        vm.stopPrank();
    }

    function test_deposit4626_assetReceivedOutOfSlippage() public {
        vm.startPrank(deployer);

        // Deploy a mock ERC4626 vault
        VaultMock mockVault = new VaultMock(IERC20(getContract(SOURCE_CHAIN, "DAI")), "Mock Vault", "mVLT");

        // Mint some DAI to the deployer
        uint256 daiAmount = 1e18;

        // Approve and deposit DAI into the mock vault
        MockERC20(getContract(SOURCE_CHAIN, "DAI")).approve(address(mockVault), daiAmount);
        uint256 vaultTokenAmount = mockVault.deposit(daiAmount, deployer);

        // Prepare deposit4626 args
        ISuperformRouterPlus.Deposit4626Args memory args = ISuperformRouterPlus.Deposit4626Args({
            amount: vaultTokenAmount,
            expectedOutputAmount: daiAmount * 10, // Assuming a large value for revert
            maxSlippage: 100, // 1%
            receiverAddressSP: deployer,
            depositCallData: _buildDepositCallData(superformId1, daiAmount)
        });

        // Approve RouterPlus to spend vault tokens
        mockVault.approve(ROUTER_PLUS_SOURCE, vaultTokenAmount);

        // Execute deposit4626
        vm.expectRevert(ISuperformRouterPlus.ASSETS_RECEIVED_OUT_OF_SLIPPAGE.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).deposit4626{ value: 1 ether }(address(mockVault), args);
    }

    function test_rebalanceSinglePosition_errors() public {
        vm.startPrank(deployer);

        _directDeposit(superformId1);

        ISuperformRouterPlus.RebalanceSinglePositionSyncArgs memory args =
            _buildRebalanceSinglePositionToOneVaultArgs(deployer);

        SuperPositions(SUPER_POSITIONS_SOURCE).increaseAllowance(ROUTER_PLUS_SOURCE, superformId1, args.sharesToRedeem);

        // Test INVALID_REBALANCE_FROM_SELECTOR error
        args.callData = abi.encodeWithSelector(bytes4(keccak256("invalidSelector()")));
        vm.expectRevert(ISuperformRouterPlus.INVALID_REBALANCE_FROM_SELECTOR.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceSinglePosition{ value: 2 ether }(args);

        // Test REBALANCE_SINGLE_POSITIONS_DIFFERENT_TOKEN error
        args = _buildRebalanceSinglePositionToOneVaultArgs(deployer);
        args.interimAsset = getContract(SOURCE_CHAIN, "WETH");
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_SINGLE_POSITIONS_DIFFERENT_TOKEN.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceSinglePosition{ value: 2 ether }(args);

        // Test REBALANCE_SINGLE_POSITIONS_DIFFERENT_AMOUNT error
        args = _buildRebalanceSinglePositionToOneVaultArgs(deployer);
        args.sharesToRedeem = args.sharesToRedeem - 1;
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_SINGLE_POSITIONS_DIFFERENT_AMOUNT.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceSinglePosition{ value: 2 ether }(args);

        /// Test REBALANCE_SINGLE_POSITIONS_DIFFERENT_CHAIN error
        args = _buildRebalanceSinglePositionToOneVaultArgs(deployer);
        SingleDirectSingleVaultStateReq memory req =
            abi.decode(_parseCallData(args.callData), (SingleDirectSingleVaultStateReq));
        req.superformData.liqRequest.liqDstChainId = ETH;
        args.callData = abi.encodeWithSelector(IBaseRouter.singleDirectSingleVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_SINGLE_POSITIONS_DIFFERENT_CHAIN.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceSinglePosition{ value: 2 ether }(args);

        // Test REBALANCE_SINGLE_POSITIONS_UNEXPECTED_RECEIVER_ADDRESS error
        args = _buildRebalanceSinglePositionToOneVaultArgs(deployer);
        req = abi.decode(_parseCallData(args.callData), (SingleDirectSingleVaultStateReq));
        req.superformData.receiverAddress = address(0x123);
        args.callData = abi.encodeWithSelector(IBaseRouter.singleDirectSingleVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_SINGLE_POSITIONS_UNEXPECTED_RECEIVER_ADDRESS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceSinglePosition{ value: 2 ether }(args);

        vm.stopPrank();
    }

    function test_rebalanceMultiPositions_errors() public {
        vm.startPrank(deployer);

        _directDeposit(superformId1);
        _directDeposit(superformId2);

        (ISuperformRouterPlus.RebalanceMultiPositionsSyncArgs memory args,) =
            _buildRebalanceTwoPositionsToOneVaultXChainArgs();

        SuperPositions(SUPER_POSITIONS_SOURCE).increaseAllowance(
            ROUTER_PLUS_SOURCE, superformId1, args.sharesToRedeem[0]
        );
        SuperPositions(SUPER_POSITIONS_SOURCE).increaseAllowance(
            ROUTER_PLUS_SOURCE, superformId2, args.sharesToRedeem[1]
        );

        // Test INVALID_REBALANCE_FROM_SELECTOR error
        args.callData = abi.encodeWithSelector(bytes4(keccak256("invalidSelector()")));
        vm.expectRevert(ISuperformRouterPlus.INVALID_REBALANCE_FROM_SELECTOR.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceMultiPositions{ value: 2 ether }(args);

        // Test REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN error
        (args,) = _buildRebalanceTwoPositionsToOneVaultXChainArgs();
        args.interimAsset = getContract(SOURCE_CHAIN, "WETH");
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceMultiPositions{ value: 2 ether }(args);

        // Test REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS error
        (args,) = _buildRebalanceTwoPositionsToOneVaultXChainArgs();
        args.sharesToRedeem[0] = args.sharesToRedeem[0] - 1;
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceMultiPositions{ value: 2 ether }(args);

        // Test REBALANCE_MULTI_POSITIONS_UNEXPECTED_RECEIVER_ADDRESS error
        (args,) = _buildRebalanceTwoPositionsToOneVaultXChainArgs();
        SingleDirectMultiVaultStateReq memory req =
            abi.decode(_parseCallData(args.callData), (SingleDirectMultiVaultStateReq));
        req.superformData.receiverAddress = address(0x123);
        args.callData = abi.encodeWithSelector(IBaseRouter.singleDirectMultiVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_MULTI_POSITIONS_UNEXPECTED_RECEIVER_ADDRESS.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceMultiPositions{ value: 2 ether }(args);

        // Test REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN error
        (args,) = _buildRebalanceTwoPositionsToOneVaultXChainArgs();
        req = abi.decode(_parseCallData(args.callData), (SingleDirectMultiVaultStateReq));
        req.superformData.liqRequests[0].liqDstChainId = ETH;
        args.callData = abi.encodeWithSelector(IBaseRouter.singleDirectMultiVaultWithdraw.selector, req);
        vm.expectRevert(ISuperformRouterPlus.REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceMultiPositions{ value: 2 ether }(args);

        // Test INVALID_DEPOSIT_SELECTOR error
        (args,) = _buildRebalanceTwoPositionsToOneVaultXChainArgs();
        args.rebalanceToCallData = abi.encodeWithSelector(bytes4(keccak256("invalidSelector()")));
        vm.expectRevert(ISuperformRouterPlus.INVALID_DEPOSIT_SELECTOR.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceMultiPositions{ value: 2 ether }(args);

        // Test VAULT_IMPLEMENTATION_FAILED error
        (args,) = _buildRebalanceTwoPositionsToOneVaultXChainArgs();
        /// expect 5x more
        args.expectedAmountToReceivePostRebalanceFrom = 100e18;
        vm.expectRevert(Error.VAULT_IMPLEMENTATION_FAILED.selector);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceMultiPositions{ value: 2 ether }(args);

        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////////
    //                  ASYNC ROUTER PLUS UNIT TESTS            //
    //////////////////////////////////////////////////////////////

    function test_setXChainRebalanceCallData_alreadySet() public {
        IBaseSuperformRouterPlus.XChainRebalanceData memory data = IBaseSuperformRouterPlus.XChainRebalanceData({
            rebalanceSelector: bytes4(keccak256("someRandomSelector()")),
            interimAsset: getContract(SOURCE_CHAIN, "USDC"),
            slippage: 100,
            expectedAmountInterimAsset: 1e18,
            rebalanceToAmbIds: abi.encode(new uint8[](0)),
            rebalanceToDstChainIds: abi.encode(new uint64[](0)),
            rebalanceToSfData: abi.encode(new bytes[](0))
        });

        vm.expectRevert(ISuperformRouterPlusAsync.NOT_ROUTER_PLUS.selector);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).setXChainRebalanceCallData(deployer, 1, data);

        vm.startPrank(ROUTER_PLUS_SOURCE);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).setXChainRebalanceCallData(deployer, 1, data);

        vm.expectRevert(ISuperformRouterPlusAsync.ALREADY_SET.selector);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).setXChainRebalanceCallData(deployer, 1, data);
    }

    function test_decodeXChainRebalanceCallData() public {
        vm.startPrank(ROUTER_PLUS_SOURCE);

        // Test case 1: singleDirectSingleVaultDeposit
        {
            IBaseSuperformRouterPlus.XChainRebalanceData memory data = IBaseSuperformRouterPlus.XChainRebalanceData({
                rebalanceSelector: IBaseRouter.singleDirectSingleVaultDeposit.selector,
                interimAsset: address(0x123),
                slippage: 100,
                expectedAmountInterimAsset: 1e18,
                rebalanceToAmbIds: "",
                rebalanceToDstChainIds: "",
                rebalanceToSfData: abi.encode(
                    SingleVaultSFData({
                        superformId: 1,
                        amount: 1e18,
                        outputAmount: 1e18,
                        maxSlippage: 100,
                        liqRequest: LiqRequest({
                            txData: "",
                            token: address(0),
                            interimToken: address(0),
                            bridgeId: 0,
                            liqDstChainId: 0,
                            nativeAmount: 0
                        }),
                        permit2data: "",
                        hasDstSwap: false,
                        retain4626: false,
                        receiverAddress: address(0x456),
                        receiverAddressSP: address(0x789),
                        extraFormData: ""
                    })
                )
            });

            SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).setXChainRebalanceCallData(deployer, 1, data);

            ISuperformRouterPlusAsync.DecodedRouterPlusRebalanceCallData memory decoded =
                SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).decodeXChainRebalanceCallData(deployer, 1);

            assertEq(decoded.interimAsset, address(0x123));
            assertEq(decoded.userSlippage, 100);
            assertEq(decoded.rebalanceSelector, IBaseRouter.singleDirectSingleVaultDeposit.selector);
            assertEq(decoded.superformIds[0][0], 1);
            assertEq(decoded.amounts[0][0], 1e18);
            assertEq(decoded.outputAmounts[0][0], 1e18);
            assertEq(decoded.receiverAddress[0], address(0x456));
        }

        // Test case 2: singleXChainSingleVaultDeposit
        {
            IBaseSuperformRouterPlus.XChainRebalanceData memory data = IBaseSuperformRouterPlus.XChainRebalanceData({
                rebalanceSelector: IBaseRouter.singleXChainSingleVaultDeposit.selector,
                interimAsset: address(0x234),
                slippage: 200,
                expectedAmountInterimAsset: 2e18,
                rebalanceToAmbIds: abi.encode(AMBs),
                rebalanceToDstChainIds: abi.encode(uint64(OP)),
                rebalanceToSfData: abi.encode(
                    SingleVaultSFData({
                        superformId: 2,
                        amount: 2e18,
                        outputAmount: 2e18,
                        maxSlippage: 200,
                        liqRequest: LiqRequest({
                            txData: "",
                            token: address(0),
                            interimToken: address(0),
                            bridgeId: 0,
                            liqDstChainId: 0,
                            nativeAmount: 0
                        }),
                        permit2data: "",
                        hasDstSwap: false,
                        retain4626: false,
                        receiverAddress: address(0x567),
                        receiverAddressSP: address(0x890),
                        extraFormData: ""
                    })
                )
            });

            SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).setXChainRebalanceCallData(deployer, 2, data);

            ISuperformRouterPlusAsync.DecodedRouterPlusRebalanceCallData memory decoded =
                SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).decodeXChainRebalanceCallData(deployer, 2);

            assertEq(decoded.interimAsset, address(0x234));
            assertEq(decoded.userSlippage, 200);
            assertEq(decoded.rebalanceSelector, IBaseRouter.singleXChainSingleVaultDeposit.selector);
            assertEq(decoded.superformIds[0][0], 2);
            assertEq(decoded.amounts[0][0], 2e18);
            assertEq(decoded.outputAmounts[0][0], 2e18);
            assertEq(decoded.receiverAddress[0], address(0x567));
            assertEq(decoded.ambIds[0][0], AMBs[0]);
            assertEq(decoded.ambIds[0][1], AMBs[1]);
            assertEq(decoded.dstChainIds[0], OP);
        }

        // Test case 3: singleDirectMultiVaultDeposit
        {
            IBaseSuperformRouterPlus.XChainRebalanceData memory data = IBaseSuperformRouterPlus.XChainRebalanceData({
                rebalanceSelector: IBaseRouter.singleDirectMultiVaultDeposit.selector,
                interimAsset: address(0x345),
                slippage: 300,
                expectedAmountInterimAsset: 3e18,
                rebalanceToAmbIds: "",
                rebalanceToDstChainIds: "",
                rebalanceToSfData: abi.encode(
                    MultiVaultSFData({
                        superformIds: new uint256[](2),
                        amounts: new uint256[](2),
                        outputAmounts: new uint256[](2),
                        maxSlippages: new uint256[](2),
                        liqRequests: new LiqRequest[](2),
                        permit2data: "",
                        hasDstSwaps: new bool[](2),
                        retain4626s: new bool[](2),
                        receiverAddress: address(0x678),
                        receiverAddressSP: address(0x901),
                        extraFormData: ""
                    })
                )
            });

            MultiVaultSFData memory sfData = abi.decode(data.rebalanceToSfData, (MultiVaultSFData));
            sfData.superformIds[0] = 3;
            sfData.superformIds[1] = 4;
            sfData.amounts[0] = 1.5e18;
            sfData.amounts[1] = 1.5e18;
            sfData.outputAmounts[0] = 1.5e18;
            sfData.outputAmounts[1] = 1.5e18;
            sfData.maxSlippages[0] = 300;
            sfData.maxSlippages[1] = 300;
            data.rebalanceToSfData = abi.encode(sfData);

            SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).setXChainRebalanceCallData(deployer, 3, data);

            ISuperformRouterPlusAsync.DecodedRouterPlusRebalanceCallData memory decoded =
                SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).decodeXChainRebalanceCallData(deployer, 3);

            assertEq(decoded.interimAsset, address(0x345));
            assertEq(decoded.userSlippage, 300);
            assertEq(decoded.rebalanceSelector, IBaseRouter.singleDirectMultiVaultDeposit.selector);
            assertEq(decoded.superformIds[0][0], 3);
            assertEq(decoded.superformIds[0][1], 4);
            assertEq(decoded.amounts[0][0], 1.5e18);
            assertEq(decoded.amounts[0][1], 1.5e18);
            assertEq(decoded.outputAmounts[0][0], 1.5e18);
            assertEq(decoded.outputAmounts[0][1], 1.5e18);
            assertEq(decoded.receiverAddress[0], address(0x678));
        }

        // Test case 4: singleXChainMultiVaultDeposit
        {
            MultiVaultSFData memory multiVaultData = MultiVaultSFData({
                superformIds: new uint256[](2),
                amounts: new uint256[](2),
                outputAmounts: new uint256[](2),
                maxSlippages: new uint256[](2),
                liqRequests: new LiqRequest[](2),
                permit2data: "",
                hasDstSwaps: new bool[](2),
                retain4626s: new bool[](2),
                receiverAddress: address(0x789),
                receiverAddressSP: address(0x012),
                extraFormData: ""
            });

            multiVaultData.superformIds[0] = 5;
            multiVaultData.superformIds[1] = 6;
            multiVaultData.amounts[0] = 2e18;
            multiVaultData.amounts[1] = 2e18;
            multiVaultData.outputAmounts[0] = 2e18;
            multiVaultData.outputAmounts[1] = 2e18;
            multiVaultData.maxSlippages[0] = 400;
            multiVaultData.maxSlippages[1] = 400;

            IBaseSuperformRouterPlus.XChainRebalanceData memory data = IBaseSuperformRouterPlus.XChainRebalanceData({
                rebalanceSelector: IBaseRouter.singleXChainMultiVaultDeposit.selector,
                interimAsset: address(0x456),
                slippage: 400,
                expectedAmountInterimAsset: 4e18,
                rebalanceToAmbIds: abi.encode(AMBs),
                rebalanceToDstChainIds: abi.encode(uint64(ETH)),
                rebalanceToSfData: abi.encode(multiVaultData)
            });

            SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).setXChainRebalanceCallData(deployer, 4, data);

            ISuperformRouterPlusAsync.DecodedRouterPlusRebalanceCallData memory decoded =
                SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).decodeXChainRebalanceCallData(deployer, 4);

            assertEq(decoded.interimAsset, address(0x456));
            assertEq(decoded.userSlippage, 400);
            assertEq(decoded.rebalanceSelector, IBaseRouter.singleXChainMultiVaultDeposit.selector);
            assertEq(decoded.superformIds[0][0], 5);
            assertEq(decoded.superformIds[0][1], 6);
            assertEq(decoded.amounts[0][0], 2e18);
            assertEq(decoded.amounts[0][1], 2e18);
            assertEq(decoded.outputAmounts[0][0], 2e18);
            assertEq(decoded.outputAmounts[0][1], 2e18);
            assertEq(decoded.receiverAddress[0], address(0x789));
            assertEq(decoded.ambIds[0][0], AMBs[0]);
            assertEq(decoded.ambIds[0][1], AMBs[1]);
            assertEq(decoded.dstChainIds[0], ETH);
        }

        // Test case 5: multiDstSingleVaultDeposit
        {
            SingleVaultSFData[] memory singleVaultData = new SingleVaultSFData[](2);
            singleVaultData[0] = SingleVaultSFData({
                superformId: 7,
                amount: 2.5e18,
                outputAmount: 2.5e18,
                maxSlippage: 500,
                liqRequest: LiqRequest({
                    txData: "",
                    token: address(0),
                    interimToken: address(0),
                    bridgeId: 0,
                    liqDstChainId: 0,
                    nativeAmount: 0
                }),
                permit2data: "",
                hasDstSwap: false,
                retain4626: false,
                receiverAddress: address(0x890),
                receiverAddressSP: address(0x123),
                extraFormData: ""
            });
            singleVaultData[1] = SingleVaultSFData({
                superformId: 8,
                amount: 2.5e18,
                outputAmount: 2.5e18,
                maxSlippage: 500,
                liqRequest: LiqRequest({
                    txData: "",
                    token: address(0),
                    interimToken: address(0),
                    bridgeId: 0,
                    liqDstChainId: 0,
                    nativeAmount: 0
                }),
                permit2data: "",
                hasDstSwap: false,
                retain4626: false,
                receiverAddress: address(0x901),
                receiverAddressSP: address(0x234),
                extraFormData: ""
            });

            uint8[][] memory ambIds = new uint8[][](2);
            ambIds[0] = new uint8[](2);
            ambIds[0][0] = AMBs[0];
            ambIds[0][1] = AMBs[1];
            ambIds[1] = new uint8[](2);
            ambIds[1][0] = AMBs[0];
            ambIds[1][1] = AMBs[1];

            uint64[] memory dstChainIds = new uint64[](2);
            dstChainIds[0] = OP;
            dstChainIds[1] = ETH;

            IBaseSuperformRouterPlus.XChainRebalanceData memory data = IBaseSuperformRouterPlus.XChainRebalanceData({
                rebalanceSelector: IBaseRouter.multiDstSingleVaultDeposit.selector,
                interimAsset: address(0x567),
                slippage: 500,
                expectedAmountInterimAsset: 5e18,
                rebalanceToAmbIds: abi.encode(ambIds),
                rebalanceToDstChainIds: abi.encode(dstChainIds),
                rebalanceToSfData: abi.encode(singleVaultData)
            });

            SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).setXChainRebalanceCallData(deployer, 5, data);

            ISuperformRouterPlusAsync.DecodedRouterPlusRebalanceCallData memory decoded =
                SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).decodeXChainRebalanceCallData(deployer, 5);

            assertEq(decoded.interimAsset, address(0x567));
            assertEq(decoded.userSlippage, 500);
            assertEq(decoded.rebalanceSelector, IBaseRouter.multiDstSingleVaultDeposit.selector);
            assertEq(decoded.superformIds[0][0], 7);
            assertEq(decoded.superformIds[1][0], 8);
            assertEq(decoded.amounts[0][0], 2.5e18);
            assertEq(decoded.amounts[1][0], 2.5e18);
            assertEq(decoded.outputAmounts[0][0], 2.5e18);
            assertEq(decoded.outputAmounts[1][0], 2.5e18);
            assertEq(decoded.receiverAddress[0], address(0x890));
            assertEq(decoded.receiverAddress[1], address(0x901));
            assertEq(decoded.ambIds[0][0], AMBs[0]);
            assertEq(decoded.ambIds[0][1], AMBs[1]);
            assertEq(decoded.ambIds[1][0], AMBs[0]);
            assertEq(decoded.ambIds[1][1], AMBs[1]);
            assertEq(decoded.dstChainIds[0], OP);
            assertEq(decoded.dstChainIds[1], ETH);
        }

        // Test case 6: multiDstMultiVaultDeposit
        {
            MultiVaultSFData[] memory multiVaultData = new MultiVaultSFData[](2);
            for (uint256 i = 0; i < 2; i++) {
                multiVaultData[i] = MultiVaultSFData({
                    superformIds: new uint256[](2),
                    amounts: new uint256[](2),
                    outputAmounts: new uint256[](2),
                    maxSlippages: new uint256[](2),
                    liqRequests: new LiqRequest[](2),
                    permit2data: "",
                    hasDstSwaps: new bool[](2),
                    retain4626s: new bool[](2),
                    receiverAddress: i == 0 ? address(0x012) : address(0x123),
                    receiverAddressSP: i == 0 ? address(0x345) : address(0x456),
                    extraFormData: ""
                });
                multiVaultData[i].superformIds[0] = i == 0 ? 9 : 11;
                multiVaultData[i].superformIds[1] = i == 0 ? 10 : 12;
                multiVaultData[i].amounts[0] = 1.5e18;
                multiVaultData[i].amounts[1] = 1.5e18;
                multiVaultData[i].outputAmounts[0] = 1.5e18;
                multiVaultData[i].outputAmounts[1] = 1.5e18;
                multiVaultData[i].maxSlippages[0] = 600;
                multiVaultData[i].maxSlippages[1] = 600;
            }

            uint8[][] memory ambIds = new uint8[][](2);
            ambIds[0] = new uint8[](2);
            ambIds[0][0] = AMBs[0];
            ambIds[0][1] = AMBs[1];
            ambIds[1] = new uint8[](2);
            ambIds[1][0] = AMBs[0];
            ambIds[1][1] = AMBs[1];

            uint64[] memory dstChainIds = new uint64[](2);
            dstChainIds[0] = OP;
            dstChainIds[1] = ETH;

            IBaseSuperformRouterPlus.XChainRebalanceData memory data = IBaseSuperformRouterPlus.XChainRebalanceData({
                rebalanceSelector: IBaseRouter.multiDstMultiVaultDeposit.selector,
                interimAsset: address(0x678),
                slippage: 600,
                expectedAmountInterimAsset: 6e18,
                rebalanceToAmbIds: abi.encode(ambIds),
                rebalanceToDstChainIds: abi.encode(dstChainIds),
                rebalanceToSfData: abi.encode(multiVaultData)
            });

            SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).setXChainRebalanceCallData(deployer, 6, data);

            ISuperformRouterPlusAsync.DecodedRouterPlusRebalanceCallData memory decoded =
                SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).decodeXChainRebalanceCallData(deployer, 6);

            assertEq(decoded.interimAsset, address(0x678));
            assertEq(decoded.userSlippage, 600);
            assertEq(decoded.rebalanceSelector, IBaseRouter.multiDstMultiVaultDeposit.selector);

            // Check first destination
            assertEq(decoded.superformIds[0][0], 9);
            assertEq(decoded.superformIds[0][1], 10);
            assertEq(decoded.amounts[0][0], 1.5e18);
            assertEq(decoded.amounts[0][1], 1.5e18);
            assertEq(decoded.outputAmounts[0][0], 1.5e18);
            assertEq(decoded.outputAmounts[0][1], 1.5e18);
            assertEq(decoded.receiverAddress[0], address(0x012));

            // Check second destination
            assertEq(decoded.superformIds[1][0], 11);
            assertEq(decoded.superformIds[1][1], 12);
            assertEq(decoded.amounts[1][0], 1.5e18);
            assertEq(decoded.amounts[1][1], 1.5e18);
            assertEq(decoded.outputAmounts[1][0], 1.5e18);
            assertEq(decoded.outputAmounts[1][1], 1.5e18);
            assertEq(decoded.receiverAddress[1], address(0x123));

            // Check AMB IDs and destination chain IDs
            assertEq(decoded.ambIds[0][0], AMBs[0]);
            assertEq(decoded.ambIds[0][1], AMBs[1]);
            assertEq(decoded.ambIds[1][0], AMBs[0]);
            assertEq(decoded.ambIds[1][1], AMBs[1]);
            assertEq(decoded.dstChainIds[0], OP);
            assertEq(decoded.dstChainIds[1], ETH);
        }

        // Test case 7: Invalid rebalance selector
        {
            IBaseSuperformRouterPlus.XChainRebalanceData memory data = IBaseSuperformRouterPlus.XChainRebalanceData({
                rebalanceSelector: bytes4(keccak256("invalidSelector()")),
                interimAsset: address(0x789),
                slippage: 700,
                expectedAmountInterimAsset: 7e18,
                rebalanceToAmbIds: "",
                rebalanceToDstChainIds: "",
                rebalanceToSfData: ""
            });

            SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).setXChainRebalanceCallData(deployer, 7, data);

            vm.expectRevert(IBaseSuperformRouterPlus.INVALID_REBALANCE_SELECTOR.selector);
            SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).decodeXChainRebalanceCallData(deployer, 7);
        }

        vm.stopPrank();
    }

    function test_crossChainRebalance_singleDirectSingleVaultDeposit() public {
        vm.selectFork(FORKS[SOURCE_CHAIN]);
        SingleVaultSFData memory sfData = SingleVaultSFData({
            superformId: superformId1,
            amount: 1e18,
            outputAmount: 1e18,
            maxSlippage: 100,
            liqRequest: LiqRequest({
                txData: "",
                token: getContract(SOURCE_CHAIN, "DAI"),
                interimToken: address(0),
                bridgeId: 0,
                liqDstChainId: SOURCE_CHAIN,
                nativeAmount: 0
            }),
            permit2data: "",
            hasDstSwap: false,
            retain4626: false,
            receiverAddress: address(deployer),
            receiverAddressSP: address(deployer),
            extraFormData: ""
        });

        IBaseSuperformRouterPlus.XChainRebalanceData memory data = IBaseSuperformRouterPlus.XChainRebalanceData({
            rebalanceSelector: IBaseRouter.singleDirectSingleVaultDeposit.selector,
            interimAsset: getContract(SOURCE_CHAIN, "DAI"),
            slippage: 100,
            expectedAmountInterimAsset: 1e18,
            rebalanceToAmbIds: abi.encode(new uint8[](0)),
            rebalanceToDstChainIds: abi.encode(new uint64[](0)),
            rebalanceToSfData: abi.encode(sfData)
        });

        vm.startPrank(ROUTER_PLUS_SOURCE);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).setXChainRebalanceCallData(deployer, 1, data);
        vm.stopPrank();

        uint256[][] memory newAmounts = new uint256[][](1);
        newAmounts[0] = new uint256[](1);
        newAmounts[0][0] = 1e18;

        uint256[][] memory newOutputAmounts = new uint256[][](1);
        newOutputAmounts[0] = new uint256[](1);
        newOutputAmounts[0][0] = 1e18;

        LiqRequest[][] memory liqRequests = new LiqRequest[][](1);
        liqRequests[0] = new LiqRequest[](1);
        liqRequests[0][0] = sfData.liqRequest;

        ISuperformRouterPlusAsync.CompleteCrossChainRebalanceArgs memory completeArgs = ISuperformRouterPlusAsync
            .CompleteCrossChainRebalanceArgs({
            receiverAddressSP: address(deployer),
            routerPlusPayloadId: 1,
            amountReceivedInterimAsset: 1e18,
            newAmounts: newAmounts,
            newOutputAmounts: newOutputAmounts,
            liqRequests: liqRequests
        });

        deal(sfData.liqRequest.token, address(ROUTER_PLUS_ASYNC_SOURCE), 1e18);

        vm.startPrank(deployer);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).completeCrossChainRebalance{ value: 1 ether }(completeArgs);
        vm.stopPrank();
    }

    function test_crossChainRebalance_allErrors() public {
        vm.startPrank(deployer);

        uint64 REBALANCE_FROM = ETH;
        uint64 REBALANCE_TO = OP;

        // Step 1: Initial XCHAIN Deposit
        _xChainDeposit(superformId5ETH, REBALANCE_FROM, 1);

        // Step 2: Start cross-chain rebalance
        vm.selectFork(FORKS[SOURCE_CHAIN]);
        ISuperformRouterPlus.InitiateXChainRebalanceArgs memory args =
            _buildInitiateXChainRebalanceArgs(REBALANCE_FROM, REBALANCE_TO, deployer);

        vm.startPrank(deployer);

        SuperPositions(SUPER_POSITIONS_SOURCE).increaseAllowance(
            ROUTER_PLUS_SOURCE, superformId5ETH, args.sharesToRedeem
        );
        vm.recordLogs();
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalance{ value: 2 ether }(args);

        // Step 3: Process XChain Withdraw (rebalance from)
        uint256 balanceOfInterimAssetBefore =
            MockERC20(args.interimAsset).balanceOf(getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"));

        _processXChainWithdrawOneVault(SOURCE_CHAIN, REBALANCE_FROM, vm.getRecordedLogs(), 2);

        vm.selectFork(FORKS[SOURCE_CHAIN]);
        uint256 balanceOfInterimAssetAfter =
            MockERC20(args.interimAsset).balanceOf(getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"));

        uint256 interimAmountOnRouterPlusAsync = balanceOfInterimAssetAfter - balanceOfInterimAssetBefore;

        ISuperformRouterPlusAsync.CompleteCrossChainRebalanceArgs memory completeArgs =
            _buildCompleteCrossChainRebalanceArgs(interimAmountOnRouterPlusAsync, superformId4OP, REBALANCE_TO);

        vm.expectRevert(ISuperformRouterPlusAsync.NOT_ROUTER_PLUS_PROCESSOR.selector);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).completeCrossChainRebalance{ value: 1 ether }(completeArgs);

        // Step 4: Complete cross-chain rebalance
        vm.startPrank(deployer);

        completeArgs.amountReceivedInterimAsset = completeArgs.amountReceivedInterimAsset * 100;
        vm.expectRevert(Error.INSUFFICIENT_BALANCE.selector);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).completeCrossChainRebalance{ value: 1 ether }(completeArgs);

        completeArgs =
            _buildCompleteCrossChainRebalanceArgs(interimAmountOnRouterPlusAsync, superformId4OP, REBALANCE_TO);
        args.expectedAmountInterimAsset = args.expectedAmountInterimAsset - 10 wei;
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).completeCrossChainRebalance{ value: 1 ether }(completeArgs);

        vm.expectRevert(ISuperformRouterPlusAsync.REBALANCE_ALREADY_PROCESSED.selector);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).completeCrossChainRebalance{ value: 1 ether }(completeArgs);
    }

    function test_crossChainRebalance_refundFlow() public {
        vm.startPrank(deployer);

        uint64 REBALANCE_FROM = ETH;
        uint64 REBALANCE_TO = OP;

        // Step 1: Initial XCHAIN Deposit
        _xChainDeposit(superformId5ETH, REBALANCE_FROM, 1);

        // Step 2: Start cross-chain rebalance
        vm.selectFork(FORKS[SOURCE_CHAIN]);
        ISuperformRouterPlus.InitiateXChainRebalanceArgs memory args =
            _buildInitiateXChainRebalanceArgs(REBALANCE_FROM, REBALANCE_TO, deployer);

        vm.startPrank(deployer);

        SuperPositions(SUPER_POSITIONS_SOURCE).increaseAllowance(
            ROUTER_PLUS_SOURCE, superformId5ETH, args.sharesToRedeem
        );
        vm.recordLogs();
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalance{ value: 2 ether }(args);

        // Step 3: Process XChain Withdraw (rebalance from)
        uint256 balanceOfInterimAssetBefore =
            MockERC20(args.interimAsset).balanceOf(getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"));

        _processXChainWithdrawOneVault(SOURCE_CHAIN, REBALANCE_FROM, vm.getRecordedLogs(), 2);

        vm.selectFork(FORKS[SOURCE_CHAIN]);
        uint256 balanceOfInterimAssetAfter =
            MockERC20(args.interimAsset).balanceOf(getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"));

        uint256 interimAmountOnRouterPlusAsync = balanceOfInterimAssetAfter - balanceOfInterimAssetBefore;

        ISuperformRouterPlusAsync.CompleteCrossChainRebalanceArgs memory completeArgs =
            _buildCompleteCrossChainRebalanceArgs(interimAmountOnRouterPlusAsync, superformId4OP, REBALANCE_TO);

        // Step 4: Complete cross-chain rebalance
        vm.startPrank(deployer);

        completeArgs =
            _buildCompleteCrossChainRebalanceArgs(interimAmountOnRouterPlusAsync, superformId4OP, REBALANCE_TO);
        completeArgs.amountReceivedInterimAsset = completeArgs.amountReceivedInterimAsset / 3;
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).completeCrossChainRebalance{ value: 1 ether }(completeArgs);
        vm.stopPrank();

        vm.expectRevert(Error.NOT_VALID_DISPUTER.selector);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).disputeRefund(1);

        vm.startPrank(deployer);
        vm.mockCall(
            address(getContract(SOURCE_CHAIN, "SuperRegistry")),
            abi.encodeWithSelector(ISuperRegistry.delay.selector),
            abi.encode(0)
        );
        vm.expectRevert(Error.DELAY_NOT_SET.selector);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).disputeRefund(1);
        vm.clearMockedCalls();

        vm.warp(block.timestamp + 100 days);
        vm.expectRevert(Error.DISPUTE_TIME_ELAPSED.selector);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).disputeRefund(1);

        vm.warp(block.timestamp - 100 days);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).disputeRefund(1);

        vm.expectRevert(Error.DISPUTE_TIME_ELAPSED.selector);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).disputeRefund(1);
        vm.stopPrank();

        vm.expectRevert(ISuperformRouterPlusAsync.INVALID_PROPOSER.selector);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).proposeRefund(1, completeArgs.amountReceivedInterimAsset);

        vm.startPrank(deployer);
        vm.expectRevert(ISuperformRouterPlusAsync.INVALID_REFUND_DATA.selector);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).proposeRefund(2, completeArgs.amountReceivedInterimAsset);

        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).proposeRefund(1, completeArgs.amountReceivedInterimAsset);

        vm.expectRevert(ISuperformRouterPlusAsync.REFUND_ALREADY_PROPOSED.selector);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).proposeRefund(1, completeArgs.amountReceivedInterimAsset);

        vm.expectRevert(ISuperformRouterPlusAsync.IN_DISPUTE_PHASE.selector);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).finalizeRefund(1);

        (, address refundToken,,) = SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).refunds(1);
        uint256 balanceBefore = MockERC20(refundToken).balanceOf(deployer);

        vm.warp(block.timestamp + 100 days);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).finalizeRefund(1);
        uint256 balanceAfter = MockERC20(refundToken).balanceOf(deployer);

        assertGt(balanceAfter, balanceBefore);

        vm.expectRevert(ISuperformRouterPlusAsync.IN_DISPUTE_PHASE.selector);
        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).finalizeRefund(1);
    }

    //////////////////////////////////////////////////////////////
    //                 SAME_CHAIN REBALANCING TESTS             //
    //////////////////////////////////////////////////////////////

    /// @dev rebalance from a single position to a single vault
    function test_rebalanceFromSinglePosition_toOneVault() public {
        vm.startPrank(deployer);

        _directDeposit(superformId1);

        ISuperformRouterPlus.RebalanceSinglePositionSyncArgs memory args =
            _buildRebalanceSinglePositionToOneVaultArgs(deployer);

        SuperPositions(SUPER_POSITIONS_SOURCE).increaseAllowance(ROUTER_PLUS_SOURCE, superformId1, args.sharesToRedeem);
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).rebalanceSinglePosition{ value: 2 ether }(args);

        assertEq(SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId1), 0);

        assertGt(SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId2), 0);
    }

    /// @dev rebalance from a single position to two vaults
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

    /// @dev rebalance from two positions to one vault
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
        _processXChainDepositOneVault(
            SOURCE_CHAIN, OP, vm.getRecordedLogs(), getContract(OP, "DAI"), totalAmountToDeposit, 1
        );

        assertGt(SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId4OP), 0);
    }

    //////////////////////////////////////////////////////////////
    //                 X_CHAIN REBALANCING TESTS                //
    //////////////////////////////////////////////////////////////

    /// @dev rebalance from a single position to a single vault on another chain
    function test_crossChainRebalanceSinglePosition_toOneVaultXChain() public {
        vm.startPrank(deployer);

        uint64 REBALANCE_FROM = ETH;
        uint64 REBALANCE_TO = OP;

        // Step 1: Initial XCHAIN Deposit
        _xChainDeposit(superformId5ETH, REBALANCE_FROM, 1);

        // Step 2: Start cross-chain rebalance
        vm.selectFork(FORKS[SOURCE_CHAIN]);
        ISuperformRouterPlus.InitiateXChainRebalanceArgs memory args =
            _buildInitiateXChainRebalanceArgs(REBALANCE_FROM, REBALANCE_TO, deployer);

        vm.startPrank(deployer);

        SuperPositions(SUPER_POSITIONS_SOURCE).increaseAllowance(
            ROUTER_PLUS_SOURCE, superformId5ETH, args.sharesToRedeem
        );
        vm.recordLogs();
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalance{ value: 2 ether }(args);

        // Step 3: Process XChain Withdraw (rebalance from)
        uint256 balanceOfInterimAssetBefore =
            MockERC20(args.interimAsset).balanceOf(getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"));

        _processXChainWithdrawOneVault(SOURCE_CHAIN, REBALANCE_FROM, vm.getRecordedLogs(), 2);

        vm.selectFork(FORKS[SOURCE_CHAIN]);
        uint256 balanceOfInterimAssetAfter =
            MockERC20(args.interimAsset).balanceOf(getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"));

        // Step 4: Complete cross-chain rebalance
        vm.startPrank(deployer);

        uint256 interimAmountOnRouterPlusAsync = balanceOfInterimAssetAfter - balanceOfInterimAssetBefore;

        ISuperformRouterPlusAsync.CompleteCrossChainRebalanceArgs memory completeArgs =
            _buildCompleteCrossChainRebalanceArgs(interimAmountOnRouterPlusAsync, superformId4OP, REBALANCE_TO);

        vm.recordLogs();

        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).completeCrossChainRebalance{ value: 1 ether }(completeArgs);

        vm.selectFork(FORKS[REBALANCE_TO]);

        (address superformRebalanceTo,,) = superformId4OP.getSuperform();
        address underlyingTokenRebalanceTo = IBaseForm(superformRebalanceTo).getVaultAsset();

        uint256 interimAmountOnCoreStateRegistry = _convertDecimals(
            interimAmountOnRouterPlusAsync,
            getContract(SOURCE_CHAIN, "USDC"),
            getContract(REBALANCE_TO, ERC20(underlyingTokenRebalanceTo).symbol()),
            SOURCE_CHAIN,
            REBALANCE_TO
        );

        _processXChainDepositOneVault(
            SOURCE_CHAIN,
            REBALANCE_TO,
            vm.getRecordedLogs(),
            getContract(REBALANCE_TO, ERC20(underlyingTokenRebalanceTo).symbol()),
            interimAmountOnCoreStateRegistry,
            1
        );

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

    /// @dev rebalance from two positions to one vault
    function test_crossChainRebalanceMultiPositions_toOneVaultXChain() public {
        vm.startPrank(deployer);

        uint64 REBALANCE_FROM = ETH;
        uint64 REBALANCE_TO = OP;

        // Step 1: Initial XCHAIN Deposits
        _xChainDeposit(superformId5ETH, REBALANCE_FROM, 1);

        vm.startPrank(deployer);
        _xChainDeposit(superformId6ETH, REBALANCE_FROM, 2);

        // Step 2: Start cross-chain rebalance
        vm.selectFork(FORKS[SOURCE_CHAIN]);
        ISuperformRouterPlus.InitiateXChainRebalanceMultiArgs memory args =
            _buildInitiateXChainRebalanceMultiArgs(REBALANCE_FROM, REBALANCE_TO);

        vm.startPrank(deployer);

        SuperPositions(SUPER_POSITIONS_SOURCE).setApprovalForAll(ROUTER_PLUS_SOURCE, true);
        vm.recordLogs();
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 3 ether }(args);

        // Step 3: Process XChain Withdraw (rebalance from)
        uint256 balanceOfInterimAssetBefore =
            MockERC20(args.interimAsset).balanceOf(getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"));

        _processXChainWithdrawMultiVault(SOURCE_CHAIN, REBALANCE_FROM, vm.getRecordedLogs(), 3);

        vm.selectFork(FORKS[SOURCE_CHAIN]);
        uint256 balanceOfInterimAssetAfter =
            MockERC20(args.interimAsset).balanceOf(getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"));

        // Step 4: Complete cross-chain rebalance
        vm.startPrank(deployer);

        uint256 interimAmountOnRouterPlusAsync = balanceOfInterimAssetAfter - balanceOfInterimAssetBefore;

        ISuperformRouterPlusAsync.CompleteCrossChainRebalanceArgs memory completeArgs =
            _buildCompleteCrossChainRebalanceMultiArgs(interimAmountOnRouterPlusAsync, superformId4OP, REBALANCE_TO);

        vm.recordLogs();

        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).completeCrossChainRebalance{ value: 1 ether }(completeArgs);

        vm.selectFork(FORKS[REBALANCE_TO]);

        (address superformRebalanceTo,,) = superformId4OP.getSuperform();
        address underlyingTokenRebalanceTo = IBaseForm(superformRebalanceTo).getVaultAsset();

        uint256 interimAmountOnCoreStateRegistry = _convertDecimals(
            interimAmountOnRouterPlusAsync,
            getContract(SOURCE_CHAIN, "USDC"),
            getContract(REBALANCE_TO, ERC20(underlyingTokenRebalanceTo).symbol()),
            SOURCE_CHAIN,
            REBALANCE_TO
        );

        _processXChainDepositOneVault(
            SOURCE_CHAIN,
            REBALANCE_TO,
            vm.getRecordedLogs(),
            getContract(REBALANCE_TO, ERC20(underlyingTokenRebalanceTo).symbol()),
            interimAmountOnCoreStateRegistry,
            1
        );

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

    /// @dev rebalance two positions from two chains to one vault on another chain
    function test_crossChainRebalanceMultiDst_toSingleVaultXChain() public {
        vm.startPrank(deployer);

        uint64 REBALANCE_FROM_1 = ETH;
        uint64 REBALANCE_FROM_2 = OP;
        uint64 REBALANCE_TO = OP;

        // Step 1: Initial XCHAIN Deposits
        _xChainDeposit(superformId5ETH, REBALANCE_FROM_1, 1);

        vm.startPrank(deployer);
        _xChainDeposit(superformId4OP, REBALANCE_FROM_2, 1);

        // // Step 2: Start cross-chain rebalance
        vm.selectFork(FORKS[SOURCE_CHAIN]);
        ISuperformRouterPlus.InitiateXChainRebalanceMultiArgs memory args =
            _buildInitiateXChainRebalanceMultiDstArgs(REBALANCE_FROM_1, REBALANCE_FROM_2, REBALANCE_TO);

        vm.startPrank(deployer);

        SuperPositions(SUPER_POSITIONS_SOURCE).setApprovalForAll(ROUTER_PLUS_SOURCE, true);
        vm.recordLogs();
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 4 ether }(args);

        Vm.Log[] memory logs = vm.getRecordedLogs();

        uint256 balanceOfInterimAssetBefore =
            MockERC20(args.interimAsset).balanceOf(getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"));

        // Step 3: Process XChain Withdraw (rebalance from)
        _processXChainWithdrawMultiVault(SOURCE_CHAIN, REBALANCE_FROM_1, logs, 2);
        _processXChainWithdrawMultiVault(SOURCE_CHAIN, REBALANCE_FROM_2, logs, 2);

        vm.selectFork(FORKS[SOURCE_CHAIN]);
        uint256 balanceOfInterimAssetAfter =
            MockERC20(args.interimAsset).balanceOf(getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"));

        // Step 4: Complete cross-chain rebalance
        vm.startPrank(deployer);

        uint256 interimAmountOnRouterPlusAsync = balanceOfInterimAssetAfter - balanceOfInterimAssetBefore;

        ISuperformRouterPlusAsync.CompleteCrossChainRebalanceArgs memory completeArgs =
            _buildCompleteCrossChainRebalanceArgs(interimAmountOnRouterPlusAsync, superformId4OP, REBALANCE_TO);

        vm.recordLogs();

        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).completeCrossChainRebalance{ value: 1 ether }(completeArgs);

        vm.selectFork(FORKS[REBALANCE_TO]);

        (address superformRebalanceTo,,) = superformId4OP.getSuperform();
        address underlyingTokenRebalanceTo = IBaseForm(superformRebalanceTo).getVaultAsset();

        uint256 interimAmountOnCoreStateRegistry = _convertDecimals(
            interimAmountOnRouterPlusAsync,
            getContract(SOURCE_CHAIN, "USDC"),
            getContract(REBALANCE_TO, ERC20(underlyingTokenRebalanceTo).symbol()),
            SOURCE_CHAIN,
            REBALANCE_TO
        );

        _processXChainDepositOneVault(
            SOURCE_CHAIN,
            REBALANCE_TO,
            vm.getRecordedLogs(),
            getContract(REBALANCE_TO, ERC20(underlyingTokenRebalanceTo).symbol()),
            interimAmountOnCoreStateRegistry,
            3
        );

        // Step 5: Verify the results
        vm.selectFork(FORKS[SOURCE_CHAIN]);
        assertEq(
            SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId5ETH),
            0,
            "Source superform 1 balance should be 0"
        );
        assertEq(
            SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId1),
            0,
            "Source superform 2 balance should be 0"
        );

        assertGt(
            SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId4OP),
            0,
            "Destination superform balance should be greater than 0"
        );
    }

    /// @dev rebalance two positions from two chains to one vault on another chain
    function test_crossChainRebalanceMultiDstMultiVault_toSingleVaultXChain() public {
        vm.startPrank(deployer);

        uint64 REBALANCE_FROM_1 = ETH;
        uint64 REBALANCE_FROM_2 = OP;
        uint64 REBALANCE_TO = OP;

        // Step 1: Initial XCHAIN Deposits
        _xChainDeposit(superformId5ETH, REBALANCE_FROM_1, 1);

        vm.startPrank(deployer);
        _xChainDeposit(superformId6ETH, REBALANCE_FROM_1, 2);

        vm.startPrank(deployer);
        _xChainDeposit(superformId4OP, REBALANCE_FROM_2, 1);

        // Step 2: Start cross-chain rebalance
        vm.selectFork(FORKS[SOURCE_CHAIN]);
        ISuperformRouterPlus.InitiateXChainRebalanceMultiArgs memory args =
            _buildInitiateXChainRebalanceMultiDstToMultiArgs(REBALANCE_FROM_1, REBALANCE_FROM_2, REBALANCE_TO);
        uint256 balanceOfInterimAssetBefore =
            MockERC20(args.interimAsset).balanceOf(getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"));

        vm.startPrank(deployer);

        SuperPositions(SUPER_POSITIONS_SOURCE).setApprovalForAll(ROUTER_PLUS_SOURCE, true);
        vm.recordLogs();
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).startCrossChainRebalanceMulti{ value: 4 ether }(args);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        // Step 3: Process XChain Withdraw (rebalance from)
        _processXChainWithdrawMultiVault(SOURCE_CHAIN, REBALANCE_FROM_1, logs, 3);
        _processXChainWithdrawMultiVault(SOURCE_CHAIN, REBALANCE_FROM_2, logs, 2);

        vm.selectFork(FORKS[SOURCE_CHAIN]);
        uint256 balanceOfInterimAssetAfter =
            MockERC20(args.interimAsset).balanceOf(getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"));

        // Step 4: Complete cross-chain rebalance
        vm.startPrank(deployer);

        uint256 interimAmountOnRouterPlusAsync = balanceOfInterimAssetAfter - balanceOfInterimAssetBefore;

        ISuperformRouterPlusAsync.CompleteCrossChainRebalanceArgs memory completeArgs =
            _buildCompleteCrossChainRebalanceArgs(interimAmountOnRouterPlusAsync, superformId4OP, REBALANCE_TO);

        vm.recordLogs();

        SuperformRouterPlusAsync(ROUTER_PLUS_ASYNC_SOURCE).completeCrossChainRebalance{ value: 1 ether }(completeArgs);

        vm.selectFork(FORKS[REBALANCE_TO]);

        (address superformRebalanceTo,,) = superformId4OP.getSuperform();
        address underlyingTokenRebalanceTo = IBaseForm(superformRebalanceTo).getVaultAsset();

        uint256 interimAmountOnCoreStateRegistry = _convertDecimals(
            interimAmountOnRouterPlusAsync,
            getContract(SOURCE_CHAIN, "USDC"),
            getContract(REBALANCE_TO, ERC20(underlyingTokenRebalanceTo).symbol()),
            SOURCE_CHAIN,
            REBALANCE_TO
        );

        _processXChainDepositOneVault(
            SOURCE_CHAIN,
            REBALANCE_TO,
            vm.getRecordedLogs(),
            getContract(REBALANCE_TO, ERC20(underlyingTokenRebalanceTo).symbol()),
            interimAmountOnCoreStateRegistry,
            3
        );

        // Step 5: Verify the results
        vm.selectFork(FORKS[SOURCE_CHAIN]);
        assertEq(
            SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId5ETH),
            0,
            "Source superform 1 balance should be 0"
        );
        assertEq(
            SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId6ETH),
            0,
            "Destination superform 2 balance should be 0"
        );

        assertGt(
            SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId4OP),
            0,
            "Destination superform 3 balance should be greater than 0"
        );
    }

    //////////////////////////////////////////////////////////////
    //                     4626 COLLATERAL                      //
    //////////////////////////////////////////////////////////////

    function test_enterWith4626() public {
        vm.startPrank(deployer);

        // Deploy a mock ERC4626 vault
        VaultMock mockVault = new VaultMock(IERC20(getContract(SOURCE_CHAIN, "DAI")), "Mock Vault", "mVLT");

        // Mint some DAI to the deployer
        uint256 daiAmount = 1e18;

        // Approve and deposit DAI into the mock vault
        MockERC20(getContract(SOURCE_CHAIN, "DAI")).approve(address(mockVault), daiAmount);
        uint256 vaultTokenAmount = mockVault.deposit(daiAmount, deployer);

        // Prepare deposit4626 args
        ISuperformRouterPlus.Deposit4626Args memory args = ISuperformRouterPlus.Deposit4626Args({
            amount: vaultTokenAmount,
            expectedOutputAmount: daiAmount, // Assuming 1:1 ratio for simplicity
            maxSlippage: 100, // 1%
            receiverAddressSP: deployer,
            depositCallData: _buildDepositCallData(superformId1, daiAmount)
        });

        // Approve RouterPlus to spend vault tokens
        mockVault.approve(ROUTER_PLUS_SOURCE, vaultTokenAmount);

        // Execute deposit4626
        vm.recordLogs();
        SuperformRouterPlus(ROUTER_PLUS_SOURCE).deposit4626{ value: 1 ether }(address(mockVault), args);

        // Verify the results
        assertGt(
            SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId1),
            0,
            "Superform balance should be greater than 0"
        );

        // Check that the vault tokens were transferred from the deployer
        assertEq(mockVault.balanceOf(deployer), 0, "Deployer's vault token balance should be 0");

        // Check that the RouterPlus contract doesn't hold any tokens
        assertEq(mockVault.balanceOf(ROUTER_PLUS_SOURCE), 0, "RouterPlus should not hold any vault tokens");
        assertEq(
            MockERC20(getContract(SOURCE_CHAIN, "DAI")).balanceOf(ROUTER_PLUS_SOURCE),
            0,
            "RouterPlus should not hold any DAI"
        );
    }

    //////////////////////////////////////////////////////////////
    //                     INTERNAL HELPERS                     //
    //////////////////////////////////////////////////////////////

    function _buildDepositCallData(uint256 superformId, uint256 amount) internal view returns (bytes memory) {
        SingleVaultSFData memory data = SingleVaultSFData({
            superformId: superformId,
            amount: amount,
            outputAmount: amount, // Assuming 1:1 ratio for simplicity
            maxSlippage: 100, // 1% slippage
            liqRequest: LiqRequest("", getContract(SOURCE_CHAIN, "DAI"), address(0), 1, SOURCE_CHAIN, 0),
            permit2data: "",
            hasDstSwap: false,
            retain4626: false,
            receiverAddress: deployer,
            receiverAddressSP: deployer,
            extraFormData: ""
        });

        return abi.encodeWithSelector(
            IBaseRouter.singleDirectSingleVaultDeposit.selector, SingleDirectSingleVaultStateReq(data)
        );
    }

    function _buildRebalanceSinglePositionToOneVaultArgs(address user)
        internal
        view
        returns (ISuperformRouterPlus.RebalanceSinglePositionSyncArgs memory args)
    {
        args.id = superformId1;
        args.sharesToRedeem = SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(user, superformId1);
        args.rebalanceFromMsgValue = 1 ether;
        args.rebalanceToMsgValue = 1 ether;
        args.interimAsset = getContract(SOURCE_CHAIN, "USDC");
        args.slippage = 100;
        args.receiverAddressSP = user;
        args.callData = _callDataRebalanceFrom(args.interimAsset);

        uint256 decimal1 = MockERC20(getContract(SOURCE_CHAIN, "DAI")).decimals();
        uint256 decimal2 = MockERC20(args.interimAsset).decimals();
        uint256 previewRedeemAmount = IBaseForm(superform1).previewRedeemFrom(args.sharesToRedeem);

        if (decimal1 > decimal2) {
            args.expectedAmountToReceivePostRebalanceFrom = previewRedeemAmount / (10 ** (decimal1 - decimal2));
        } else {
            args.expectedAmountToReceivePostRebalanceFrom = previewRedeemAmount * 10 ** (decimal2 - decimal1);
        }

        args.rebalanceToCallData = _callDataRebalanceToOneVaultSameChain(
            args.expectedAmountToReceivePostRebalanceFrom, args.interimAsset, user
        );
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

    function _buildInitiateXChainRebalanceArgs(
        uint64 REBALANCE_FROM,
        uint64 REBALANCE_TO,
        address user
    )
        internal
        returns (ISuperformRouterPlus.InitiateXChainRebalanceArgs memory args)
    {
        uint256 initialFork = vm.activeFork();

        args.id = superformId5ETH;
        args.sharesToRedeem = SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(user, superformId5ETH);
        args.interimAsset = getContract(SOURCE_CHAIN, "USDC");
        args.receiverAddressSP = user;
        vm.selectFork(FORKS[REBALANCE_FROM]);
        uint256 expectedAmountOfRebalanceFrom = IBaseForm(superform5ETH).previewRedeemFrom(args.sharesToRedeem);
        // conversion from WETH on DSTCHAIN to USDC on SOURCE CHAIN
        args.expectedAmountInterimAsset = _convertDecimals(
            expectedAmountOfRebalanceFrom,
            getContract(REBALANCE_FROM, "WETH"),
            args.interimAsset,
            REBALANCE_FROM,
            SOURCE_CHAIN
        );
        vm.selectFork(initialFork);
        args.finalizeSlippage = 100; // 1%
        args.callData = _callDataRebalanceFromXChain(args.interimAsset, superformId5ETH, REBALANCE_FROM);

        /// @dev rebalance to call data formulation for a xchain deposit
        args.rebalanceToSelector = IBaseRouter.singleXChainSingleVaultDeposit.selector;
        args.rebalanceToAmbIds = abi.encode(AMBs);
        args.rebalanceToDstChainIds = abi.encode(uint64(REBALANCE_TO));

        vm.selectFork(FORKS[REBALANCE_TO]);

        (address superformRebalanceTo,,) = superformId4OP.getSuperform();
        address underlyingTokenRebalanceTo = IBaseForm(superformRebalanceTo).getVaultAsset();
        /// data for a bridge from Router to Core State Registry
        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            args.interimAsset,
            getContract(SOURCE_CHAIN, ERC20(underlyingTokenRebalanceTo).symbol()),
            underlyingTokenRebalanceTo,
            getContract(SOURCE_CHAIN, "SuperformRouter"),
            SOURCE_CHAIN,
            REBALANCE_TO,
            REBALANCE_TO,
            false,
            getContract(REBALANCE_TO, "CoreStateRegistry"),
            uint256(REBALANCE_TO),
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

        // conversion from USDC on SOURCE CHAIN to DAI on DSTCHAIN
        uint256 expectedAmountToReceiveAfterBridge = _convertDecimals(
            args.expectedAmountInterimAsset,
            args.interimAsset,
            getContract(REBALANCE_TO, "DAI"),
            SOURCE_CHAIN,
            REBALANCE_TO
        );

        uint256 expectedOutputAmount = IBaseForm(superform4OP).previewDepositTo(expectedAmountToReceiveAfterBridge);

        SingleVaultSFData memory sfData = SingleVaultSFData({
            superformId: superformId4OP,
            amount: expectedAmountToReceiveAfterBridge,
            outputAmount: expectedOutputAmount,
            maxSlippage: 100,
            liqRequest: LiqRequest({
                txData: _buildLiqBridgeTxData(liqBridgeTxDataArgs, false),
                token: args.interimAsset,
                interimToken: address(0),
                bridgeId: 1,
                liqDstChainId: REBALANCE_TO,
                nativeAmount: 0
            }),
            permit2data: "",
            hasDstSwap: false,
            retain4626: false,
            receiverAddress: user,
            receiverAddressSP: user,
            extraFormData: ""
        });
        args.rebalanceToSfData = abi.encode(sfData);

        vm.selectFork(initialFork);

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
                    slippage: 0,
                    USDPerExternalToken: 1,
                    USDPerUnderlyingTokenDst: 1,
                    USDPerUnderlyingToken: 1,
                    deBridgeRefundAddress: address(0)
                }),
                false
            ),
            token: getContract(SOURCE_CHAIN, "USDC"),
            interimToken: address(0),
            bridgeId: 1,
            liqDstChainId: chainIdRebalanceTo,
            nativeAmount: 0
        });
        args.liqRequests = liqRequests;

        uint256 totalAmountOfUnderlyingToDeposit = _convertDecimals(
            amountReceivedInterimAssetInRouterPlusAsync,
            getContract(SOURCE_CHAIN, "USDC"),
            underlyingToken,
            SOURCE_CHAIN,
            chainIdRebalanceTo
        );

        args.newAmounts = new uint256[][](1);
        args.newAmounts[0] = new uint256[](1);
        args.newAmounts[0][0] = totalAmountOfUnderlyingToDeposit;

        vm.selectFork(FORKS[chainIdRebalanceTo]);

        args.newOutputAmounts = new uint256[][](1);
        args.newOutputAmounts[0] = new uint256[](1);
        args.newOutputAmounts[0][0] = IBaseForm(superform).previewDepositTo(totalAmountOfUnderlyingToDeposit);

        vm.selectFork(initialFork);
    }

    function _buildCompleteCrossChainRebalanceMultiArgs(
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
        address underlyingToken = IBaseForm(superform).getVaultAsset();
        vm.selectFork(initialFork);

        args.receiverAddressSP = deployer;
        args.routerPlusPayloadId = 1; // Assuming this is the first payload
        args.amountReceivedInterimAsset = amountReceivedInterimAssetInRouterPlusAsync;

        args.liqRequests = new LiqRequest[][](1);
        args.liqRequests[0] = new LiqRequest[](1);
        args.liqRequests[0][0] = LiqRequest({
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
                    slippage: 0,
                    USDPerExternalToken: 1,
                    USDPerUnderlyingTokenDst: 1,
                    USDPerUnderlyingToken: 1,
                    deBridgeRefundAddress: address(0)
                }),
                false
            ),
            token: getContract(SOURCE_CHAIN, "USDC"),
            interimToken: address(0),
            bridgeId: 1,
            liqDstChainId: chainIdRebalanceTo,
            nativeAmount: 0
        });

        uint256 totalAmountOfUnderlyingToDeposit = _convertDecimals(
            amountReceivedInterimAssetInRouterPlusAsync,
            getContract(SOURCE_CHAIN, "USDC"),
            underlyingToken,
            SOURCE_CHAIN,
            chainIdRebalanceTo
        );

        args.newAmounts = new uint256[][](1);
        args.newAmounts[0] = new uint256[](1);
        args.newAmounts[0][0] = totalAmountOfUnderlyingToDeposit;

        vm.selectFork(FORKS[chainIdRebalanceTo]);

        args.newOutputAmounts = new uint256[][](1);
        args.newOutputAmounts[0] = new uint256[](1);
        args.newOutputAmounts[0][0] = IBaseForm(superform).previewDepositTo(totalAmountOfUnderlyingToDeposit);

        vm.selectFork(initialFork);

        return args;
    }

    function _buildInitiateXChainRebalanceMultiArgs(
        uint64 REBALANCE_FROM,
        uint64 REBALANCE_TO
    )
        internal
        returns (ISuperformRouterPlus.InitiateXChainRebalanceMultiArgs memory args)
    {
        uint256 initialFork = vm.activeFork();

        args.ids = new uint256[](2);
        args.ids[0] = superformId5ETH;
        args.ids[1] = superformId6ETH;

        args.sharesToRedeem = new uint256[](2);
        args.sharesToRedeem[0] = SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId5ETH);
        args.sharesToRedeem[1] = SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId6ETH);

        args.interimAsset = getContract(SOURCE_CHAIN, "USDC");
        args.receiverAddressSP = deployer;

        vm.selectFork(FORKS[REBALANCE_FROM]);
        uint256 expectedAmountOfRebalanceFrom = IBaseForm(superform5ETH).previewRedeemFrom(args.sharesToRedeem[0]);
        uint256 expectedAmountOfRebalanceFrom2 = IBaseForm(superform6ETH).previewRedeemFrom(args.sharesToRedeem[1]);

        // Convert both amounts to USDC on SOURCE_CHAIN
        args.expectedAmountInterimAsset = _convertDecimals(
            expectedAmountOfRebalanceFrom,
            getContract(REBALANCE_FROM, "WETH"),
            args.interimAsset,
            REBALANCE_FROM,
            SOURCE_CHAIN
        );

        args.expectedAmountInterimAsset += _convertDecimals(
            expectedAmountOfRebalanceFrom2,
            getContract(REBALANCE_FROM, "DAI"),
            args.interimAsset,
            REBALANCE_FROM,
            SOURCE_CHAIN
        );

        vm.selectFork(initialFork);
        args.finalizeSlippage = 100; // 1%
        args.callData = _callDataRebalanceFromMultiXChain(args.interimAsset, args.ids, REBALANCE_FROM);

        args.rebalanceToSelector = IBaseRouter.singleXChainSingleVaultDeposit.selector;
        args.rebalanceToAmbIds = abi.encode(AMBs);
        args.rebalanceToDstChainIds = abi.encode(uint64(REBALANCE_TO));

        vm.selectFork(FORKS[REBALANCE_TO]);

        (address superformRebalanceTo,,) = superformId4OP.getSuperform();
        address underlyingTokenRebalanceTo = IBaseForm(superformRebalanceTo).getVaultAsset();

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            args.interimAsset,
            getContract(SOURCE_CHAIN, ERC20(underlyingTokenRebalanceTo).symbol()),
            underlyingTokenRebalanceTo,
            getContract(SOURCE_CHAIN, "SuperformRouter"),
            SOURCE_CHAIN,
            REBALANCE_TO,
            REBALANCE_TO,
            false,
            getContract(REBALANCE_TO, "CoreStateRegistry"),
            uint256(REBALANCE_TO),
            args.expectedAmountInterimAsset,
            false,
            0,
            1,
            1,
            1,
            address(0)
        );

        // Convert from USDC on SOURCE_CHAIN to DAI on REBALANCE_TO
        uint256 expectedAmountToReceiveAfterBridge = _convertDecimals(
            args.expectedAmountInterimAsset,
            args.interimAsset,
            getContract(REBALANCE_TO, "DAI"),
            SOURCE_CHAIN,
            REBALANCE_TO
        );

        uint256 expectedOutputAmount = IBaseForm(superform4OP).previewDepositTo(expectedAmountToReceiveAfterBridge);

        SingleVaultSFData memory sfData = SingleVaultSFData({
            superformId: superformId4OP,
            amount: expectedAmountToReceiveAfterBridge,
            outputAmount: expectedOutputAmount,
            maxSlippage: 100,
            liqRequest: LiqRequest({
                txData: _buildLiqBridgeTxData(liqBridgeTxDataArgs, false),
                token: args.interimAsset,
                interimToken: address(0),
                bridgeId: 1,
                liqDstChainId: REBALANCE_TO,
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

        vm.selectFork(initialFork);

        return args;
    }

    function _buildInitiateXChainRebalanceMultiDstArgs(
        uint64 REBALANCE_FROM_1,
        uint64 REBALANCE_FROM_2,
        uint64 REBALANCE_TO
    )
        internal
        returns (ISuperformRouterPlus.InitiateXChainRebalanceMultiArgs memory args)
    {
        uint256 initialFork = vm.activeFork();

        args.ids = new uint256[](2);
        args.ids[0] = superformId5ETH;
        args.ids[1] = superformId4OP;

        args.sharesToRedeem = new uint256[](2);
        args.sharesToRedeem[0] = SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId5ETH);
        args.sharesToRedeem[1] = SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId4OP);

        args.interimAsset = getContract(SOURCE_CHAIN, "USDC");
        args.receiverAddressSP = deployer;

        vm.selectFork(FORKS[REBALANCE_FROM_1]);
        uint256 expectedAmountOfRebalanceFrom1 = IBaseForm(superform5ETH).previewRedeemFrom(args.sharesToRedeem[0]);

        vm.selectFork(FORKS[REBALANCE_FROM_2]);
        uint256 expectedAmountOfRebalanceFrom2 = IBaseForm(superform4OP).previewRedeemFrom(args.sharesToRedeem[1]);

        // Convert both amounts to USDC on SOURCE_CHAIN
        args.expectedAmountInterimAsset = _convertDecimals(
            expectedAmountOfRebalanceFrom1,
            getContract(REBALANCE_FROM_1, "WETH"),
            args.interimAsset,
            REBALANCE_FROM_1,
            SOURCE_CHAIN
        );

        args.expectedAmountInterimAsset += _convertDecimals(
            expectedAmountOfRebalanceFrom2,
            getContract(REBALANCE_FROM_2, "DAI"),
            args.interimAsset,
            REBALANCE_FROM_2,
            SOURCE_CHAIN
        );

        vm.selectFork(initialFork);
        args.finalizeSlippage = 100; // 1%
        args.callData = _callDataRebalanceFromMultiDst(args.interimAsset, args.ids, REBALANCE_FROM_1, REBALANCE_FROM_2);

        args.rebalanceToSelector = IBaseRouter.singleXChainSingleVaultDeposit.selector;
        args.rebalanceToAmbIds = abi.encode(AMBs);
        args.rebalanceToDstChainIds = abi.encode(uint64(REBALANCE_TO));

        vm.selectFork(FORKS[REBALANCE_TO]);
        // Prepare rebalanceToSfData for single vault deposit
        (address superformRebalanceTo,,) = superformId4OP.getSuperform();
        address underlyingTokenRebalanceTo = IBaseForm(superformRebalanceTo).getVaultAsset();

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            args.interimAsset,
            getContract(SOURCE_CHAIN, ERC20(underlyingTokenRebalanceTo).symbol()),
            underlyingTokenRebalanceTo,
            getContract(SOURCE_CHAIN, "SuperformRouter"),
            SOURCE_CHAIN,
            REBALANCE_TO,
            REBALANCE_TO,
            false,
            getContract(REBALANCE_TO, "CoreStateRegistry"),
            uint256(REBALANCE_TO),
            args.expectedAmountInterimAsset,
            false,
            0,
            1,
            1,
            1,
            address(0)
        );

        uint256 expectedAmountToReceiveAfterBridge = _convertDecimals(
            args.expectedAmountInterimAsset,
            args.interimAsset,
            getContract(REBALANCE_TO, "DAI"),
            SOURCE_CHAIN,
            REBALANCE_TO
        );

        uint256 expectedOutputAmount = IBaseForm(superform4OP).previewDepositTo(expectedAmountToReceiveAfterBridge);

        SingleVaultSFData memory sfData = SingleVaultSFData({
            superformId: superformId4OP,
            amount: expectedAmountToReceiveAfterBridge,
            outputAmount: expectedOutputAmount,
            maxSlippage: 100,
            liqRequest: LiqRequest({
                txData: _buildLiqBridgeTxData(liqBridgeTxDataArgs, false),
                token: args.interimAsset,
                interimToken: address(0),
                bridgeId: 1,
                liqDstChainId: REBALANCE_TO,
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

        vm.selectFork(initialFork);
        return args;
    }

    function _buildInitiateXChainRebalanceMultiDstToMultiArgs(
        uint64 REBALANCE_FROM_1,
        uint64 REBALANCE_FROM_2,
        uint64 REBALANCE_TO
    )
        internal
        returns (ISuperformRouterPlus.InitiateXChainRebalanceMultiArgs memory args)
    {
        uint256 initialFork = vm.activeFork();

        args.ids = new uint256[](3);
        args.ids[0] = superformId5ETH;
        args.ids[1] = superformId6ETH;
        args.ids[2] = superformId4OP;

        args.sharesToRedeem = new uint256[](3);
        args.sharesToRedeem[0] = SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId5ETH);
        args.sharesToRedeem[1] = SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId6ETH);
        args.sharesToRedeem[2] = SuperPositions(SUPER_POSITIONS_SOURCE).balanceOf(deployer, superformId4OP);

        args.interimAsset = getContract(SOURCE_CHAIN, "USDC");
        args.receiverAddressSP = deployer;

        vm.selectFork(FORKS[REBALANCE_FROM_1]);
        uint256 expectedAmountOfRebalanceFrom1 = IBaseForm(superform5ETH).previewRedeemFrom(args.sharesToRedeem[0]);
        uint256 expectedAmountOfRebalanceFrom2 = IBaseForm(superform6ETH).previewRedeemFrom(args.sharesToRedeem[1]);

        vm.selectFork(FORKS[REBALANCE_FROM_2]);
        uint256 expectedAmountOfRebalanceFrom3 = IBaseForm(superform4OP).previewRedeemFrom(args.sharesToRedeem[2]);

        // Convert all amounts to USDC on SOURCE_CHAIN
        args.expectedAmountInterimAsset = _convertDecimals(
            expectedAmountOfRebalanceFrom1,
            getContract(REBALANCE_FROM_1, "WETH"),
            args.interimAsset,
            REBALANCE_FROM_1,
            SOURCE_CHAIN
        );

        args.expectedAmountInterimAsset += _convertDecimals(
            expectedAmountOfRebalanceFrom2,
            getContract(REBALANCE_FROM_1, "DAI"),
            args.interimAsset,
            REBALANCE_FROM_1,
            SOURCE_CHAIN
        );

        args.expectedAmountInterimAsset += _convertDecimals(
            expectedAmountOfRebalanceFrom3,
            getContract(REBALANCE_FROM_2, "DAI"),
            args.interimAsset,
            REBALANCE_FROM_2,
            SOURCE_CHAIN
        );

        vm.selectFork(initialFork);
        args.finalizeSlippage = 100; // 1%
        args.callData =
            _callDataRebalanceFromMultiDstMultiVault(args.interimAsset, args.ids, REBALANCE_FROM_1, REBALANCE_FROM_2);

        args.rebalanceToSelector = IBaseRouter.singleXChainSingleVaultDeposit.selector;
        args.rebalanceToAmbIds = abi.encode(AMBs);
        args.rebalanceToDstChainIds = abi.encode(uint64(REBALANCE_TO));

        vm.selectFork(FORKS[REBALANCE_TO]);
        // Prepare rebalanceToSfData for single vault deposit
        (address superformRebalanceTo,,) = superformId4OP.getSuperform();
        address underlyingTokenRebalanceTo = IBaseForm(superformRebalanceTo).getVaultAsset();

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            args.interimAsset,
            getContract(SOURCE_CHAIN, ERC20(underlyingTokenRebalanceTo).symbol()),
            underlyingTokenRebalanceTo,
            getContract(SOURCE_CHAIN, "SuperformRouter"),
            SOURCE_CHAIN,
            REBALANCE_TO,
            REBALANCE_TO,
            false,
            getContract(REBALANCE_TO, "CoreStateRegistry"),
            uint256(REBALANCE_TO),
            args.expectedAmountInterimAsset,
            false,
            0,
            1,
            1,
            1,
            address(0)
        );

        uint256 expectedAmountToReceiveAfterBridge = _convertDecimals(
            args.expectedAmountInterimAsset,
            args.interimAsset,
            getContract(REBALANCE_TO, "DAI"),
            SOURCE_CHAIN,
            REBALANCE_TO
        );

        uint256 expectedOutputAmount = IBaseForm(superform4OP).previewDepositTo(expectedAmountToReceiveAfterBridge);

        SingleVaultSFData memory sfData = SingleVaultSFData({
            superformId: superformId4OP,
            amount: expectedAmountToReceiveAfterBridge,
            outputAmount: expectedOutputAmount,
            maxSlippage: 100,
            liqRequest: LiqRequest({
                txData: _buildLiqBridgeTxData(liqBridgeTxDataArgs, false),
                token: args.interimAsset,
                interimToken: address(0),
                bridgeId: 1,
                liqDstChainId: REBALANCE_TO,
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

        vm.selectFork(initialFork);
        return args;
    }

    // Define the struct outside the function
    struct LocalVaultData {
        uint256[] superformIds;
        uint256[] amounts;
        uint256[] outputAmounts;
        uint256[] maxSlippages;
        LiqRequest[] liqRequests;
        bool[] hasDstSwaps;
        bool[] retain4626s;
    }

    function _callDataRebalanceFromMultiDstMultiVault(
        address interimToken,
        uint256[] memory superformIds,
        uint64 superformChainId1,
        uint64 superformChainId2
    )
        internal
        returns (bytes memory)
    {
        uint256 initialFork = vm.activeFork();

        MultiVaultSFData[] memory multiVaultData = new MultiVaultSFData[](2);

        uint64[] memory chainIds = new uint64[](2);
        chainIds[0] = superformChainId1;
        chainIds[1] = superformChainId2;

        for (uint256 i = 0; i < 2; i++) {
            vm.selectFork(FORKS[chainIds[i]]);

            LocalVaultData memory localData;

            if (i == 0) {
                // For REBALANCE_FROM_1 (ETH), we have two superforms
                localData = LocalVaultData({
                    superformIds: new uint256[](2),
                    amounts: new uint256[](2),
                    outputAmounts: new uint256[](2),
                    maxSlippages: new uint256[](2),
                    liqRequests: new LiqRequest[](2),
                    hasDstSwaps: new bool[](2),
                    retain4626s: new bool[](2)
                });
                localData.superformIds[0] = superformIds[0];
                localData.superformIds[1] = superformIds[1];
            } else {
                // For REBALANCE_FROM_2 (OP), we have one superform
                localData = LocalVaultData({
                    superformIds: new uint256[](1),
                    amounts: new uint256[](1),
                    outputAmounts: new uint256[](1),
                    maxSlippages: new uint256[](1),
                    liqRequests: new LiqRequest[](1),
                    hasDstSwaps: new bool[](1),
                    retain4626s: new bool[](1)
                });
                localData.superformIds[0] = superformIds[2];
            }

            for (uint256 j = 0; j < localData.superformIds.length; j++) {
                (address superform,,) = localData.superformIds[j].getSuperform();
                address underlyingToken = IBaseForm(superform).getVaultAsset();

                LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
                    1,
                    underlyingToken,
                    underlyingToken,
                    interimToken,
                    superform,
                    chainIds[i],
                    SOURCE_CHAIN,
                    SOURCE_CHAIN,
                    false,
                    getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"),
                    uint256(SOURCE_CHAIN),
                    1e18, // This should be updated with the actual amount if available
                    true,
                    0,
                    1,
                    1,
                    1,
                    address(0)
                );

                localData.amounts[j] = 1e18; // This should be updated with the actual amount if available
                localData.outputAmounts[j] = 1e18; // This should be updated with the actual output amount if available
                localData.maxSlippages[j] = 100; // 1% slippage, adjust as needed
                localData.liqRequests[j] = LiqRequest(
                    _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), interimToken, address(0), 1, SOURCE_CHAIN, 0
                );
                localData.hasDstSwaps[j] = false;
                localData.retain4626s[j] = false;
            }

            multiVaultData[i] = MultiVaultSFData({
                superformIds: localData.superformIds,
                amounts: localData.amounts,
                outputAmounts: localData.outputAmounts,
                maxSlippages: localData.maxSlippages,
                liqRequests: localData.liqRequests,
                permit2data: "",
                hasDstSwaps: localData.hasDstSwaps,
                retain4626s: localData.retain4626s,
                receiverAddress: ROUTER_PLUS_ASYNC_SOURCE,
                receiverAddressSP: deployer,
                extraFormData: ""
            });
        }

        vm.selectFork(initialFork);

        // Set ambIds to AMBs for both destinations
        uint8[][] memory ambIds = new uint8[][](2);
        ambIds[0] = AMBs;
        ambIds[1] = AMBs;

        return abi.encodeCall(
            IBaseRouter.multiDstMultiVaultWithdraw, MultiDstMultiVaultStateReq(ambIds, chainIds, multiVaultData)
        );
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
            ROUTER_PLUS_ASYNC_SOURCE,
            deployer,
            ""
        );
        vm.selectFork(initialFork);
        return abi.encodeCall(
            IBaseRouter.singleXChainSingleVaultWithdraw, SingleXChainSingleVaultStateReq(AMBs, superformChainId, data)
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
        address interimToken,
        address user
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
            user,
            user,
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
        address underlyingTokenSuperform3 = IBaseForm(superform3).getVaultAsset();
        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            interimToken,
            underlyingTokenSuperform3,
            underlyingTokenSuperform3,
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

    function _callDataRebalanceFromMultiXChain(
        address interimToken,
        uint256[] memory superformIds,
        uint64 superformChainId
    )
        internal
        returns (bytes memory)
    {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[superformChainId]);

        MultiVaultSFData memory data = MultiVaultSFData({
            superformIds: superformIds,
            amounts: new uint256[](superformIds.length),
            outputAmounts: new uint256[](superformIds.length),
            maxSlippages: new uint256[](superformIds.length),
            liqRequests: new LiqRequest[](superformIds.length),
            permit2data: "",
            hasDstSwaps: new bool[](superformIds.length),
            retain4626s: new bool[](superformIds.length),
            receiverAddress: ROUTER_PLUS_ASYNC_SOURCE,
            receiverAddressSP: deployer,
            extraFormData: ""
        });

        for (uint256 i = 0; i < superformIds.length; i++) {
            (address superform,,) = superformIds[i].getSuperform();
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
                1e18, // This should be updated with the actual amount if available
                true,
                0,
                1,
                1,
                1,
                address(0)
            );

            data.amounts[i] = 1e18; // This should be updated with the actual amount if available
            data.outputAmounts[i] = 1e18; // This should be updated with the actual output amount if available
            data.maxSlippages[i] = 100; // 1% slippage, adjust as needed
            data.liqRequests[i] = LiqRequest(
                _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), interimToken, address(0), 1, SOURCE_CHAIN, 0
            );
        }

        vm.selectFork(initialFork);
        return abi.encodeCall(
            IBaseRouter.singleXChainMultiVaultWithdraw, SingleXChainMultiVaultStateReq(AMBs, superformChainId, data)
        );
    }

    function _callDataRebalanceFromMultiDst(
        address interimToken,
        uint256[] memory superformIds,
        uint64 superformChainId1,
        uint64 superformChainId2
    )
        internal
        returns (bytes memory)
    {
        uint256 initialFork = vm.activeFork();

        SingleVaultSFData[] memory singleVaultData = new SingleVaultSFData[](2);

        uint64[] memory chainIds = new uint64[](2);
        chainIds[0] = superformChainId1;
        chainIds[1] = superformChainId2;

        for (uint256 i = 0; i < superformIds.length; i++) {
            vm.selectFork(FORKS[chainIds[i]]);
            (address superform,,) = superformIds[i].getSuperform();
            address underlyingToken = IBaseForm(superform).getVaultAsset();

            LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
                1,
                underlyingToken,
                underlyingToken,
                interimToken,
                superform,
                chainIds[i],
                SOURCE_CHAIN,
                SOURCE_CHAIN,
                false,
                getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"),
                uint256(SOURCE_CHAIN),
                1e18, // This should be updated with the actual amount if available
                true,
                0,
                1,
                1,
                1,
                address(0)
            );

            singleVaultData[i] = SingleVaultSFData({
                superformId: superformIds[i],
                amount: 1e18,
                outputAmount: 1e18,
                maxSlippage: 100,
                liqRequest: LiqRequest(
                    _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), interimToken, address(0), 1, SOURCE_CHAIN, 0
                ),
                permit2data: "",
                hasDstSwap: false,
                retain4626: false,
                receiverAddress: ROUTER_PLUS_ASYNC_SOURCE,
                receiverAddressSP: deployer,
                extraFormData: ""
            });
        }

        vm.selectFork(initialFork);

        /// @dev set ambIds to AMBs for both dst
        uint8[][] memory ambIds = new uint8[][](2);
        ambIds[0] = AMBs;
        ambIds[1] = AMBs;

        return abi.encodeCall(
            IBaseRouter.multiDstSingleVaultWithdraw, MultiDstSingleVaultStateReq(ambIds, chainIds, singleVaultData)
        );
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
                        getContract(SOURCE_CHAIN, ERC20(underlyingToken).symbol()),
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
                getContract(SOURCE_CHAIN, "DAI"),
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

        uint256 totalAmountToDeposit =
            _convertDecimals(data.amount, getContract(SOURCE_CHAIN, "DAI"), underlyingToken, SOURCE_CHAIN, dstChainId);

        _processXChainDepositOneVault(
            SOURCE_CHAIN, dstChainId, vm.getRecordedLogs(), underlyingToken, totalAmountToDeposit, payloadIdToProcess
        );

        vm.selectFork(FORKS[SOURCE_CHAIN]);

        assertGt(SuperPositions(getContract(SOURCE_CHAIN, "SuperPositions")).balanceOf(deployer, superformId), 0);
    }

    function _deliverAMBMessage(uint64 fromChain, uint64 toChain, Vm.Log[] memory logs) internal {
        address[] memory toMailboxes = new address[](1);
        toMailboxes[0] = address(HYPERLANE_MAILBOXES[toChain]);

        uint256[] memory forkIds = new uint256[](1);
        forkIds[0] = FORKS[toChain];

        uint32[] memory expDstDomains = new uint32[](1);
        expDstDomains[0] = uint32(toChain);

        address[] memory wormholeRelayers = new address[](1);
        wormholeRelayers[0] = address(wormholeRelayer);

        address[] memory expDstChainAddresses = new address[](1);
        expDstChainAddresses[0] = address(getContract(toChain, "WormholeARImplementation"));

        for (uint256 i = 0; i < AMBs.length; i++) {
            if (AMBs[i] == 2) {
                // Hyperlane
                HyperlaneHelper(getContract(fromChain, "HyperlaneHelper")).help(
                    address(HYPERLANE_MAILBOXES[fromChain]), toMailboxes, expDstDomains, forkIds, logs
                );
            } else if (AMBs[i] == 3) {
                WormholeHelper(getContract(fromChain, "WormholeHelper")).help(
                    WORMHOLE_CHAIN_IDS[fromChain], forkIds, expDstChainAddresses, wormholeRelayers, logs
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
        uint256 amountArrivedInDst,
        uint256 payloadIdToProcess
    )
        internal
    {
        vm.stopPrank();
        // Simulate AMB message delivery
        _deliverAMBMessage(fromChain, toChain, logs);

        vm.startPrank(deployer);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountArrivedInDst;

        address[] memory bridgedTokens = new address[](1);
        bridgedTokens[0] = destinationToken;

        CoreStateRegistry coreStateRegistry = CoreStateRegistry(getContract(toChain, "CoreStateRegistry"));
        vm.selectFork(FORKS[toChain]);

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

        coreStateRegistry.processPayload(coreStateRegistry.payloadsCount());

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
        vm.stopPrank();

        // Simulate AMB message delivery
        _deliverAMBMessage(fromChain, toChain, logs);

        vm.startPrank(deployer);

        vm.selectFork(FORKS[toChain]);
        CoreStateRegistry coreStateRegistry = CoreStateRegistry(getContract(toChain, "CoreStateRegistry"));

        // Perform processPayload on CoreStateRegistry on destination chain
        uint256 nativeAmount = PaymentHelper(getContract(toChain, "PaymentHelper")).estimateAckCost(payloadIdToProcess);
        vm.recordLogs();

        coreStateRegistry.processPayload{ value: nativeAmount }(payloadIdToProcess);

        vm.stopPrank();
    }

    function _processXChainWithdrawMultiVault(
        uint64 fromChain,
        uint64 toChain,
        Vm.Log[] memory logs,
        uint256 payloadIdToProcess
    )
        internal
    {
        vm.stopPrank();

        // Simulate AMB message delivery
        _deliverAMBMessage(fromChain, toChain, logs);

        vm.startPrank(deployer);

        vm.selectFork(FORKS[toChain]);
        CoreStateRegistry coreStateRegistry = CoreStateRegistry(getContract(toChain, "CoreStateRegistry"));

        // Perform processPayload on CoreStateRegistry on destination chain
        uint256 nativeAmount = PaymentHelper(getContract(toChain, "PaymentHelper")).estimateAckCost(payloadIdToProcess);
        vm.recordLogs();

        coreStateRegistry.processPayload{ value: nativeAmount }(payloadIdToProcess);

        vm.stopPrank();
    }

    function _setupValidXChainRebalanceArgs()
        internal
        returns (ISuperformRouterPlus.InitiateXChainRebalanceArgs memory)
    {
        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId5ETH;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        vm.startPrank(getContract(SOURCE_CHAIN, "SuperformRouter"));
        SuperPositions(SUPER_POSITIONS_SOURCE).mintBatch(deployer, superformIds, amounts);

        vm.startPrank(deployer);
        SuperPositions(SUPER_POSITIONS_SOURCE).setApprovalForOne(
            getContract(SOURCE_CHAIN, "SuperformRouterPlus"), superformId5ETH, 1e18
        );

        address interimAsset = getContract(SOURCE_CHAIN, "USDC");
        uint256 sharesToRedeem = 1e18;

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq({
            ambIds: AMBs,
            dstChainId: OP,
            superformData: SingleVaultSFData({
                superformId: superformId4OP,
                amount: sharesToRedeem,
                outputAmount: 1e18,
                maxSlippage: 100,
                liqRequest: LiqRequest({
                    txData: "",
                    token: interimAsset,
                    interimToken: address(0),
                    bridgeId: 1,
                    liqDstChainId: SOURCE_CHAIN,
                    nativeAmount: 0
                }),
                permit2data: "",
                hasDstSwap: false,
                retain4626: false,
                receiverAddress: getContract(SOURCE_CHAIN, "SuperformRouterPlus"),
                receiverAddressSP: deployer,
                extraFormData: ""
            })
        });

        return ISuperformRouterPlus.InitiateXChainRebalanceArgs({
            id: superformId5ETH,
            sharesToRedeem: sharesToRedeem,
            interimAsset: interimAsset,
            receiverAddressSP: deployer,
            expectedAmountInterimAsset: 1e18,
            finalizeSlippage: 100,
            callData: abi.encodeWithSelector(IBaseRouter.singleXChainSingleVaultWithdraw.selector, req),
            rebalanceToSelector: IBaseRouter.singleXChainSingleVaultDeposit.selector,
            rebalanceToAmbIds: abi.encode(AMBs),
            rebalanceToDstChainIds: abi.encode(uint64(OP)),
            rebalanceToSfData: ""
        });
    }

    function _setupValidXChainRebalanceMultiArgs()
        internal
        returns (ISuperformRouterPlus.InitiateXChainRebalanceMultiArgs memory)
    {
        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId5ETH;
        superformIds[1] = superformId6ETH;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        vm.startPrank(getContract(SOURCE_CHAIN, "SuperformRouter"));
        SuperPositions(SUPER_POSITIONS_SOURCE).mintBatch(deployer, superformIds, amounts);

        vm.startPrank(deployer);
        SuperPositions(SUPER_POSITIONS_SOURCE).setApprovalForAll(getContract(SOURCE_CHAIN, "SuperformRouterPlus"), true);

        address interimAsset = getContract(SOURCE_CHAIN, "USDC");
        uint256[] memory sharesToRedeem = new uint256[](2);
        sharesToRedeem[0] = 1e18;
        sharesToRedeem[1] = 1e18;

        uint64 REBALANCE_FROM = ETH;
        uint64 REBALANCE_TO = OP;

        return ISuperformRouterPlus.InitiateXChainRebalanceMultiArgs({
            ids: superformIds,
            sharesToRedeem: sharesToRedeem,
            interimAsset: interimAsset,
            receiverAddressSP: deployer,
            expectedAmountInterimAsset: 2e18, // Assuming 1:1 conversion for simplicity
            finalizeSlippage: 100,
            callData: _buildSingleXChainMultiVaultWithdrawCallData(interimAsset, superformIds, REBALANCE_FROM),
            rebalanceToSelector: IBaseRouter.singleXChainSingleVaultDeposit.selector,
            rebalanceToAmbIds: abi.encode(AMBs),
            rebalanceToDstChainIds: abi.encode(REBALANCE_TO),
            rebalanceToSfData: "" // This would typically contain encoded data for the destination superform
         });
    }

    function _buildSingleXChainMultiVaultWithdrawCallData(
        address interimToken,
        uint256[] memory superformIds,
        uint64 superformChainId
    )
        internal
        returns (bytes memory)
    {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[superformChainId]);

        MultiVaultSFData memory data = MultiVaultSFData({
            superformIds: superformIds,
            amounts: new uint256[](superformIds.length),
            outputAmounts: new uint256[](superformIds.length),
            maxSlippages: new uint256[](superformIds.length),
            liqRequests: new LiqRequest[](superformIds.length),
            permit2data: "",
            hasDstSwaps: new bool[](superformIds.length),
            retain4626s: new bool[](superformIds.length),
            receiverAddress: getContract(SOURCE_CHAIN, "SuperformRouterPlusAsync"),
            receiverAddressSP: deployer,
            extraFormData: ""
        });

        for (uint256 i = 0; i < superformIds.length; i++) {
            (address superform,,) = superformIds[i].getSuperform();
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
                1e18, // This should be updated with the actual amount if available
                true,
                0,
                1,
                1,
                1,
                address(0)
            );

            data.amounts[i] = 1e18; // This should be updated with the actual amount if available
            data.outputAmounts[i] = 1e18; // This should be updated with the actual output amount if available
            data.maxSlippages[i] = 100; // 1% slippage, adjust as needed
            data.liqRequests[i] = LiqRequest(
                _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), interimToken, address(0), 1, SOURCE_CHAIN, 0
            );
        }

        vm.selectFork(initialFork);
        return abi.encodeCall(
            IBaseRouter.singleXChainMultiVaultWithdraw, SingleXChainMultiVaultStateReq(AMBs, superformChainId, data)
        );
    }

    function _parseCallData(bytes memory data) internal pure returns (bytes memory calldata_) {
        assembly {
            calldata_ := add(data, 0x04)
        }
    }
}

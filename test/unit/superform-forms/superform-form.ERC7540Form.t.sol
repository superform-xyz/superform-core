// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/ProtocolActions.sol";
import "src/libraries/DataLib.sol";

import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import { ERC7575Mock } from "test/mocks/ERC7575Mock.sol";

import { MockERC20 } from "test/mocks/MockERC20.sol";

import { IERC7540FormBase } from "src/forms/interfaces/IERC7540Form.sol";

import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";

contract SuperformERC7540FormTest is ProtocolActions {
    using DataLib for uint256;
    using Math for uint256;

    function setUp() public override {
        chainIds = [BSC_TESTNET, SEPOLIA];
        LAUNCH_TESTNETS = true;

        AMBs = [2, 5];
        super.setUp();
    }

    function test_7540_claimDeposit_allErrors() external {
        vm.selectFork(FORKS[BSC_TESTNET]);

        uint64 srcChainId = BSC_TESTNET;
        uint256 superformId = _getSuperformId(srcChainId, "ERC7540FullyAsyncMock");

        (address superform,,) = superformId.getSuperform();

        ERC7540Form form = ERC7540Form(superform);

        vm.expectRevert(IERC7540FormBase.NOT_ASYNC_STATE_REGISTRY.selector);
        form.claimDeposit(users[0], superformId, 0, false);

        vm.startPrank(getContract(srcChainId, "AsyncStateRegistry"));
        vm.expectRevert(Error.RECEIVER_ADDRESS_NOT_SET.selector);
        form.claimDeposit(address(0), superformId, 0, false);

        vm.store(address(form), bytes32(uint256(1)), bytes32(uint256(0)));
        vm.expectRevert(IERC7540FormBase.VAULT_KIND_NOT_SET.selector);
        form.claimDeposit(users[0], superformId, 0, false);

        uint256 depositId = _getSuperformId(srcChainId, "ERC7540AsyncRedeemMock");
        (address depositForm,,) = depositId.getSuperform();

        bytes32 slotValueForRedeemAsync = vm.load(address(depositForm), bytes32(uint256(1)));

        vm.store(address(form), bytes32(uint256(1)), slotValueForRedeemAsync);
        vm.expectRevert(IERC7540FormBase.INVALID_VAULT_KIND.selector);
        form.claimDeposit(users[0], superformId, 0, false);

        vm.stopPrank();
    }

    function test_7540_claimDeposit_pausedForm() external {
        vm.selectFork(FORKS[BSC_TESTNET]);

        uint64 srcChainId = BSC_TESTNET;
        uint256 superformId = _getSuperformId(srcChainId, "ERC7540FullyAsyncMock");

        (address superform,,) = superformId.getSuperform();

        ERC7540Form form = ERC7540Form(superform);

        vm.startPrank(deployer);
        SuperformFactory(getContract(srcChainId, "SuperformFactory")).changeFormImplementationPauseStatus(
            5, ISuperformFactory.PauseStatus.PAUSED, ""
        );
        vm.stopPrank();

        /// Tests paused form claimDeposit
        vm.startPrank(getContract(srcChainId, "AsyncStateRegistry"));
        uint256 returnVal = form.claimDeposit(users[0], superformId, 0, false);
        assertEq(returnVal, 0);
        vm.stopPrank();
    }

    function test_7540_claimRedeem_allErrors() external {
        vm.selectFork(FORKS[BSC_TESTNET]);

        uint64 srcChainId = BSC_TESTNET;
        uint256 superformId = _getSuperformId(srcChainId, "ERC7540FullyAsyncMock");

        (address superform,,) = superformId.getSuperform();

        ERC7540Form form = ERC7540Form(superform);
        LiqRequest memory liqRequest;

        vm.expectRevert(IERC7540FormBase.NOT_ASYNC_STATE_REGISTRY.selector);
        form.claimRedeem(users[0], superformId, 0, 0, 1, BSC_TESTNET, liqRequest);

        vm.startPrank(getContract(srcChainId, "AsyncStateRegistry"));
        vm.expectRevert(Error.RECEIVER_ADDRESS_NOT_SET.selector);
        form.claimRedeem(address(0), superformId, 0, 0, 1, BSC_TESTNET, liqRequest);

        vm.store(address(form), bytes32(uint256(1)), bytes32(uint256(0)));
        vm.expectRevert(IERC7540FormBase.VAULT_KIND_NOT_SET.selector);
        form.claimRedeem(users[0], superformId, 0, 0, 1, BSC_TESTNET, liqRequest);

        vm.store(address(form), bytes32(uint256(1)), 0x000000000000000000000001013cce8d377b70d17fdb24fb17de9d4fe8fa58f3);
        vm.expectRevert(IERC7540FormBase.INVALID_VAULT_KIND.selector);
        form.claimRedeem(users[0], superformId, 0, 0, 1, BSC_TESTNET, liqRequest);

        vm.stopPrank();
    }

    function test_7540_claimRedeem_pausedForm() external {
        vm.selectFork(FORKS[BSC_TESTNET]);

        uint64 srcChainId = BSC_TESTNET;
        uint256 superformId = _getSuperformId(srcChainId, "ERC7540FullyAsyncMock");

        (address superform,,) = superformId.getSuperform();

        ERC7540Form form = ERC7540Form(superform);
        LiqRequest memory liqRequest;

        vm.startPrank(deployer);
        SuperformFactory(getContract(srcChainId, "SuperformFactory")).changeFormImplementationPauseStatus(
            5, ISuperformFactory.PauseStatus.PAUSED, ""
        );
        vm.stopPrank();

        /// Tests paused form claimDeposit
        vm.startPrank(getContract(srcChainId, "AsyncStateRegistry"));
        uint256 returnVal = form.claimRedeem(users[0], superformId, 0, 0, 1, BSC_TESTNET, liqRequest);
        assertEq(returnVal, 0);
        vm.stopPrank();
    }

    function test_7540OtherFunctionCalls() external {
        uint64 srcChainId = BSC_TESTNET;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 depositAmount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId, "ERC7540FullyAsyncMock");

        (address superform,,) = superformId.getSuperform();

        ERC7540Form form = ERC7540Form(superform);

        form.getPendingDepositRequest(1, user);
        form.getPendingRedeemRequest(1, user);
        form.getVaultName();
        form.getVaultSymbol();
        form.getPricePerVaultShare();
        form.getVaultShareBalance();
        form.getTotalAssets();
        form.getTotalSupply();
        vm.expectRevert(Error.NOT_IMPLEMENTED.selector);
        form.getPreviewPricePerVaultShare();
        vm.expectRevert(Error.NOT_IMPLEMENTED.selector);
        form.previewWithdrawFrom(0);
        vm.expectRevert(Error.NOT_IMPLEMENTED.selector);
        form.previewRedeemFrom(depositAmount);
        form.superformYieldTokenName();
        form.superformYieldTokenSymbol();
    }

    function test_7540_sameChainDeposit_RedeemAsync_VAULT_IMPLEMENTATION_FAILED() external {
        uint64 srcChainId = BSC_TESTNET;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 depositAmount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId, "ERC7540AsyncRedeemMock");

        _performSameChainDeposit(
            SameChainArgs(
                dstChainId, user, depositAmount, superformId, true, 100, Error.VAULT_IMPLEMENTATION_FAILED.selector
            )
        );
    }

    function test_7540_sameChainDeposit_RedeemAsync() external {
        uint64 srcChainId = BSC_TESTNET;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 depositAmount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId, "ERC7540AsyncRedeemMock");

        _performSameChainDeposit(SameChainArgs(dstChainId, user, depositAmount, superformId, true, 1000, bytes4(0)));
    }

    function test_7540_sameChainDeposit_RedeemAsync_withDifferentAsset_revertsInsufficientAllowance() external {
        uint64 srcChainId = BSC_TESTNET;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 depositAmount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId, "ERC7540AsyncRedeemMock");

        _performSameChainDepositWithdDifferentAsset(
            SameChainArgs(
                dstChainId,
                user,
                depositAmount,
                superformId,
                true,
                1000,
                Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT.selector
            )
        );
    }

    function test_7540_sameChainDeposit_RedeemAsync_withDifferentAsset() external {
        uint64 srcChainId = BSC_TESTNET;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 depositAmount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId, "ERC7540AsyncRedeemMock");

        _performSameChainDepositWithdDifferentAsset(
            SameChainArgs(dstChainId, user, depositAmount, superformId, true, 1000, bytes4(0))
        );
    }

    function test_7540_sameChainDeposit_RedeemAsync_withDifferentAsset_DIFFERENT_TOKENS() external {
        uint64 srcChainId = BSC_TESTNET;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 depositAmount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId, "ERC7540AsyncRedeemMock");

        _performSameChainDepositWithdDifferentAsset(
            SameChainArgs(dstChainId, user, depositAmount, superformId, true, 1000, Error.DIFFERENT_TOKENS.selector)
        );
    }

    function test_7540_sameChainDeposit_RedeemAsync_withDifferentAsset_DIRECT_DEPOSIT_SWAP_FAILED() external {
        uint64 srcChainId = BSC_TESTNET;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 depositAmount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId, "ERC7540AsyncRedeemMock");

        _performSameChainDepositWithdDifferentAsset(
            SameChainArgs(
                dstChainId, user, depositAmount, superformId, true, 1000, Error.DIRECT_DEPOSIT_SWAP_FAILED.selector
            )
        );
    }

    function test_7540AccumulateXChain() external {
        uint64 srcChainId = BSC_TESTNET;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 depositAmount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId, "ERC7540FullyAsyncMock");

        _performSameChainDeposit(SameChainArgs(dstChainId, user, depositAmount, superformId, false, 100, bytes4(0)));
        _performCrossChainDeposit(srcChainId, dstChainId, user, depositAmount, superformId);

        _processCrossChainDeposit(dstChainId);

        _checkAndClaimAccumulatedAmounts(dstChainId, srcChainId, user, superformId, true);
    }

    function test_7540AccumulateWithdrawXChain() external {
        uint64 srcChainId = BSC_TESTNET;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 depositAmount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId, "ERC7540FullyAsyncMock");

        // Perform a deposit first
        _performCrossChainDeposit(srcChainId, dstChainId, user, depositAmount, superformId);
        _processCrossChainDeposit(dstChainId);

        _checkAndClaimAccumulatedAmounts(dstChainId, srcChainId, user, superformId, true);

        // Perform cross-chain withdrawal
        _performCrossChainWithdraw(srcChainId, dstChainId, user, depositAmount / 2, superformId);
        _processCrossChainWithdraw(dstChainId, 2);

        _performCrossChainWithdraw(srcChainId, dstChainId, user, depositAmount / 2, superformId);
        _processCrossChainWithdraw(dstChainId, 3);

        // Check the withdrawn amount
        _checkAndRedeemAccumulatedAmounts(
            dstChainId,
            srcChainId,
            getContract(dstChainId, string.concat("tUSDERC7540FullyAsyncMockSuperform5")),
            user,
            superformId,
            false
        );
    }

    function test_7540AccumulateSameChain() external {
        uint64 srcChainId = BSC_TESTNET;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 depositAmount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId, "ERC7540FullyAsyncMock");

        _performCrossChainDeposit(srcChainId, dstChainId, user, depositAmount, superformId);
        _processCrossChainDeposit(dstChainId);

        _performSameChainDeposit(SameChainArgs(dstChainId, user, depositAmount, superformId, false, 100, bytes4(0)));

        _checkAndClaimAccumulatedAmounts(
            dstChainId,
            /// src chain id == dst chain id (same chain)
            dstChainId,
            user,
            superformId,
            false
        );
    }

    function test_7540AccumulateOnlySameChain() external {
        /// src chain id == dst chain id (same chain)
        uint64 srcChainId = SEPOLIA;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 depositAmount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId, "ERC7540FullyAsyncMock");

        _performSameChainDeposit(SameChainArgs(dstChainId, user, depositAmount, superformId, false, 100, bytes4(0)));
        _performSameChainDeposit(SameChainArgs(dstChainId, user, depositAmount, superformId, false, 100, bytes4(0)));

        _checkAndClaimAccumulatedAmounts(dstChainId, srcChainId, user, superformId, false);
    }

    function test_7540_sameChainWithdraw() external {
        /// src chain id == dst chain id (same chain)
        uint64 srcChainId = SEPOLIA;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 amount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId, "ERC7540AsyncDepositMock");
        (address superform,,) = superformId.getSuperform();

        // Simulate deposit
        _simulateDeposit(dstChainId, user, superformId, amount);

        _performSameChainWithdraw(SameChainArgs(dstChainId, user, amount, superformId, false, 100, bytes4(0)));
    }

    function test_7540_sameChainWithdraw_retain4626() external {
        /// src chain id == dst chain id (same chain)
        uint64 srcChainId = SEPOLIA;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 amount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId, "ERC7540AsyncDepositMock");
        (address superform,,) = superformId.getSuperform();

        // Simulate deposit
        _simulateDeposit(dstChainId, user, superformId, amount);

        _performSameChainWithdraw(SameChainArgs(dstChainId, user, amount, superformId, true, 100, bytes4(0)));
    }

    function test_7540_sameChainWithdraw_swapAsset_DIRECT_WITHDRAW_INVALID_LIQ_REQUEST() external {
        /// src chain id == dst chain id (same chain)
        uint64 srcChainId = SEPOLIA;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 amount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId, "ERC7540AsyncDepositMock");
        (address superform,,) = superformId.getSuperform();

        // Simulate deposit
        _simulateDeposit(dstChainId, user, superformId, amount);

        _performSameChainWithdrawWithDifferentAsset(
            SameChainArgs(
                dstChainId, user, amount, superformId, false, 100, Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST.selector
            )
        );
    }

    function _getSuperformId(uint64 dstChainId, string memory vaultKind) internal view returns (uint256) {
        address superform = getContract(
            dstChainId, string.concat("tUSD", vaultKind, "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[2]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[2], dstChainId);
        return superformId;
    }

    struct SameChainArgs {
        uint64 dstChainId;
        address user;
        uint256 amount;
        uint256 superformId;
        bool hasRetain4626;
        uint256 slippage;
        bytes4 error;
    }

    struct SameChainLocalVars {
        address dstSuperformRouter;
        address superform1;
        address token;
        address outputSwapToken;
        uint256 amountAdjusted;
        bytes txData;
    }

    function _simulateDeposit(uint64 dstChainId, address user, uint256 superformId, uint256 depositAmount) internal {
        (address superform,,) = superformId.getSuperform();

        vm.prank(getContract(dstChainId, "SuperformRouter"));
        SuperPositions(getContract(dstChainId, "SuperPositions")).mintSingle(user, superformId, depositAmount);
        address vault = IBaseForm(superform).getVaultAddress();
        ERC7575Mock(IERC7540(vault).share()).mint(superform, depositAmount);

        address vaultAsset = IBaseForm(superform).getVaultAsset();
        vm.prank(0x423420Ae467df6e90291fd0252c0A8a637C1e03f);
        MockERC20(vaultAsset).mint(vault, depositAmount * 2);
    }

    function _performSameChainDeposit(SameChainArgs memory args) internal {
        vm.selectFork(FORKS[args.dstChainId]);
        vm.startPrank(args.user);

        address dstSuperformRouter = getContract(args.dstChainId, "SuperformRouter");
        MockERC20(getContract(args.dstChainId, "tUSD")).approve(dstSuperformRouter, args.amount);

        if (args.error != bytes4(0)) {
            vm.expectRevert(args.error);
        }
        SuperformRouter(payable(dstSuperformRouter)).singleDirectSingleVaultDeposit(
            SingleDirectSingleVaultStateReq(
                SingleVaultSFData(
                    args.superformId,
                    args.amount,
                    args.amount,
                    args.slippage,
                    LiqRequest(bytes(""), getContract(args.dstChainId, "tUSD"), address(0), 0, args.dstChainId, 0),
                    bytes(""),
                    args.hasRetain4626,
                    false,
                    args.user,
                    args.user,
                    abi.encode(args.superformId, new uint8[](0))
                )
            )
        );

        vm.stopPrank();
    }

    function _performSameChainDepositWithdDifferentAsset(SameChainArgs memory args) internal {
        SameChainLocalVars memory v;
        vm.selectFork(FORKS[args.dstChainId]);
        vm.startPrank(args.user);

        v.dstSuperformRouter = getContract(args.dstChainId, "SuperformRouter");
        MockERC20(getContract(args.dstChainId, "USDC")).approve(v.dstSuperformRouter, args.amount);

        (v.superform1,,) = args.superformId.getSuperform();
        v.outputSwapToken = args.error == Error.DIFFERENT_TOKENS.selector
            ? getContract(args.dstChainId, "USDC")
            : getContract(args.dstChainId, "tUSD");
        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(args.dstChainId, "USDC"),
            v.outputSwapToken,
            v.outputSwapToken,
            v.superform1,
            args.dstChainId,
            args.dstChainId,
            args.dstChainId,
            false,
            v.superform1,
            uint256(args.dstChainId),
            args.amount,
            //1e18,
            false,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1,
            address(0)
        );
        v.txData = _buildLiqBridgeTxData(liqBridgeTxDataArgs, true);

        v.token = args.error == Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT.selector
            ? getContract(args.dstChainId, "tUSD")
            : getContract(args.dstChainId, "USDC");
        v.amountAdjusted = _convertDecimals(
            args.amount, v.token, getContract(args.dstChainId, "tUSD"), args.dstChainId, args.dstChainId
        );
        if (args.error != bytes4(0)) {
            vm.expectRevert(args.error);
        }
        SuperformRouter(payable(v.dstSuperformRouter)).singleDirectSingleVaultDeposit(
            SingleDirectSingleVaultStateReq(
                SingleVaultSFData(
                    args.superformId,
                    args.error == Error.DIRECT_DEPOSIT_SWAP_FAILED.selector
                        ? v.amountAdjusted.mulDiv(20_000, 10_000)
                        : v.amountAdjusted,
                    v.amountAdjusted,
                    args.slippage,
                    LiqRequest(v.txData, v.token, address(0), 1, args.dstChainId, 0),
                    bytes(""),
                    args.hasRetain4626,
                    false,
                    args.user,
                    args.user,
                    abi.encode(args.superformId, new uint8[](0))
                )
            )
        );

        vm.stopPrank();
    }

    function _performSameChainWithdraw(SameChainArgs memory args) internal {
        vm.selectFork(FORKS[args.dstChainId]);
        vm.startPrank(args.user);

        address dstSuperformRouter = getContract(args.dstChainId, "SuperformRouter");

        SuperPositions(getContract(args.dstChainId, "SuperPositions")).setApprovalForOne(
            dstSuperformRouter, args.superformId, args.amount
        );

        if (args.error != bytes4(0)) {
            vm.expectRevert(args.error);
        }
        SuperformRouter(payable(dstSuperformRouter)).singleDirectSingleVaultWithdraw(
            SingleDirectSingleVaultStateReq(
                SingleVaultSFData(
                    args.superformId,
                    args.amount,
                    args.amount,
                    args.slippage,
                    LiqRequest(bytes(""), getContract(args.dstChainId, "tUSD"), address(0), 0, args.dstChainId, 0),
                    bytes(""),
                    args.hasRetain4626,
                    false,
                    args.user,
                    args.user,
                    abi.encode(args.superformId, new uint8[](0))
                )
            )
        );

        vm.stopPrank();
    }

    function _performSameChainWithdrawWithDifferentAsset(SameChainArgs memory args) internal {
        SameChainLocalVars memory v;
        vm.selectFork(FORKS[args.dstChainId]);
        vm.startPrank(args.user);

        v.dstSuperformRouter = getContract(args.dstChainId, "SuperformRouter");

        SuperPositions(getContract(args.dstChainId, "SuperPositions")).setApprovalForOne(
            v.dstSuperformRouter, args.superformId, args.amount
        );

        (v.superform1,,) = args.superformId.getSuperform();

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(args.dstChainId, "tUSD"),
            getContract(args.dstChainId, "USDC"),
            getContract(args.dstChainId, "USDC"),
            v.superform1,
            args.dstChainId,
            args.dstChainId,
            args.dstChainId,
            false,
            v.superform1,
            uint256(args.dstChainId),
            args.amount,
            //1e18,
            true,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1,
            address(0)
        );
        v.txData = _buildLiqBridgeTxData(liqBridgeTxDataArgs, true);

        if (args.error != bytes4(0)) {
            vm.expectRevert(args.error);
        }
        SuperformRouter(payable(v.dstSuperformRouter)).singleDirectSingleVaultWithdraw(
            SingleDirectSingleVaultStateReq(
                SingleVaultSFData(
                    args.superformId,
                    args.amount,
                    args.amount,
                    args.slippage,
                    LiqRequest(v.txData, getContract(args.dstChainId, "tUSD"), address(0), 1, args.dstChainId, 0),
                    bytes(""),
                    args.hasRetain4626,
                    false,
                    args.user,
                    args.user,
                    abi.encode(args.superformId, new uint8[](0))
                )
            )
        );

        vm.stopPrank();
    }

    struct CrossChainDepositLocalVars {
        address srcSuperformRouter;
        uint8[] ambIds;
        bytes[] extraFormData;
    }

    function _performCrossChainDeposit(
        uint64 srcChainId,
        uint64 dstChainId,
        address user,
        uint256 depositAmount,
        uint256 superformId
    )
        internal
    {
        CrossChainDepositLocalVars memory v;

        vm.selectFork(FORKS[srcChainId]);
        vm.startPrank(user);

        v.srcSuperformRouter = getContract(srcChainId, "SuperformRouter");
        v.ambIds = new uint8[](2);
        v.ambIds[0] = 2;
        v.ambIds[1] = 5;

        MockERC20(getContract(srcChainId, "DAI")).approve(v.srcSuperformRouter, depositAmount);
        vm.recordLogs();

        v.extraFormData = new bytes[](1);
        v.extraFormData[0] = abi.encode(superformId, abi.encode(v.ambIds));

        SuperformRouter(payable(v.srcSuperformRouter)).singleXChainSingleVaultDeposit{ value: 0.5 ether }(
            SingleXChainSingleVaultStateReq(
                v.ambIds,
                dstChainId,
                SingleVaultSFData(
                    superformId,
                    depositAmount,
                    depositAmount,
                    100,
                    _createLiqRequest(srcChainId, dstChainId, depositAmount, user),
                    bytes(""),
                    false,
                    false,
                    user,
                    user,
                    abi.encode(1, v.extraFormData)
                )
            )
        );
        vm.stopPrank();

        _payloadDeliveryHelper(dstChainId, srcChainId, vm.getRecordedLogs());
    }

    function _performCrossChainWithdraw(
        uint64 srcChainId,
        uint64 dstChainId,
        address user,
        uint256 withdrawAmount,
        uint256 superformId
    )
        internal
    {
        vm.selectFork(FORKS[srcChainId]);
        vm.startPrank(user);

        address srcSuperformRouter = getContract(srcChainId, "SuperformRouter");

        SuperPositions(getContract(srcChainId, "SuperPositions")).setApprovalForAll(srcSuperformRouter, true);
        SuperformRouter(payable(srcSuperformRouter)).singleXChainSingleVaultWithdraw{ value: 0.5 ether }(
            SingleXChainSingleVaultStateReq(
                AMBs,
                dstChainId,
                SingleVaultSFData(
                    superformId,
                    withdrawAmount,
                    withdrawAmount,
                    10_000,
                    LiqRequest(bytes(""), address(0), address(0), 0, dstChainId, 0),
                    bytes(""),
                    false,
                    false,
                    user,
                    user,
                    abi.encode(1, new bytes[](0))
                )
            )
        );

        vm.stopPrank();

        _payloadDeliveryHelper(dstChainId, srcChainId, vm.getRecordedLogs());
    }

    function _createLiqRequest(
        uint64 srcChainId,
        uint64 dstChainId,
        uint256 depositAmount,
        address user
    )
        internal
        view
        returns (LiqRequest memory)
    {
        return LiqRequest(
            abi.encodeWithSelector(
                DeBridgeMock.createSaltedOrder.selector,
                DlnOrderLib.OrderCreation(
                    getContract(srcChainId, "DAI"),
                    depositAmount,
                    abi.encodePacked(getContract(dstChainId, "tUSD")),
                    depositAmount,
                    uint256(dstChainId),
                    abi.encodePacked(getContract(dstChainId, "CoreStateRegistry")),
                    address(user),
                    abi.encodePacked(deployer),
                    bytes(""),
                    bytes(""),
                    abi.encodePacked(user)
                ),
                uint64(block.timestamp),
                bytes(""),
                uint32(0),
                bytes(""),
                abi.encode(user, FORKS[srcChainId], FORKS[dstChainId])
            ),
            getContract(srcChainId, "DAI"),
            address(0),
            7,
            dstChainId,
            0
        );
    }

    function _processCrossChainDeposit(uint64 dstChainId) internal {
        vm.selectFork(FORKS[dstChainId]);
        address csr = getContract(dstChainId, "CoreStateRegistry");

        address[] memory finalTokens = new address[](1);
        finalTokens[0] = getContract(dstChainId, "tUSD");

        uint256[] memory finalAmounts = new uint256[](1);
        finalAmounts[0] = MockERC20(finalTokens[0]).balanceOf(csr);

        vm.prank(deployer);
        CoreStateRegistry(csr).updateDepositPayload(1, finalTokens, finalAmounts);

        vm.prank(deployer);
        CoreStateRegistry(csr).processPayload(1);
    }

    function _processCrossChainWithdraw(uint64 dstChainId, uint256 payloadId) internal {
        vm.selectFork(FORKS[dstChainId]);
        address csr = getContract(dstChainId, "CoreStateRegistry");

        vm.prank(deployer);
        CoreStateRegistry(csr).processPayload(payloadId);
    }

    function _checkAndClaimAccumulatedAmounts(
        uint64 dstChainId,
        uint64 srcChainId,
        address user,
        uint256 superformId,
        bool xChain
    )
        internal
    {
        vm.selectFork(FORKS[srcChainId]);
        uint256 superPositionsBefore =
            SuperPositions(getContract(dstChainId, "SuperPositions")).balanceOf(user, superformId);

        vm.selectFork(FORKS[dstChainId]);

        (address superform,,) = superformId.getSuperform();

        address vault = IBaseForm(superform).getVaultAddress();
        address investmentManager = ERC7540VaultLike(vault).manager();
        address asset = IBaseForm(superform).getVaultAsset();

        _authorizeOperator(superform, 0);

        vm.startPrank(InvestmentManagerLike(investmentManager).root());
        _fulfillDepositRequest(investmentManager, vault, asset, 2e18, user);
        vm.stopPrank();

        vm.startPrank(deployer);
        vm.recordLogs();
        AsyncStateRegistry(getContract(dstChainId, "AsyncStateRegistry")).claimAvailableDeposits{ value: 0.5 ether }(
            user, superformId
        );
        vm.stopPrank();

        if (xChain) {
            _payloadDeliveryHelper(srcChainId, dstChainId, vm.getRecordedLogs());

            vm.selectFork(FORKS[srcChainId]);
            vm.startPrank(deployer);
            AsyncStateRegistry(getContract(srcChainId, "AsyncStateRegistry")).processPayload(1);
            vm.stopPrank();
        }

        vm.selectFork(FORKS[srcChainId]);
        uint256 superPositionsAfter =
            SuperPositions(getContract(dstChainId, "SuperPositions")).balanceOf(user, superformId);

        assertGt(
            superPositionsAfter, superPositionsBefore, "User's SuperPositions balance should increase after claiming"
        );
    }

    function _checkAndRedeemAccumulatedAmounts(
        uint64 dstChainId,
        uint64 srcChainId,
        address superform,
        address user,
        uint256 superformId,
        bool failedRemint
    )
        internal
    {
        vm.selectFork(FORKS[srcChainId]);
        uint256 superPositionsBefore =
            SuperPositions(getContract(dstChainId, "SuperPositions")).balanceOf(user, superformId);

        vm.selectFork(FORKS[dstChainId]);

        address vault = IBaseForm(superform).getVaultAddress();
        address investmentManager = ERC7540VaultLike(vault).manager();
        address asset = IBaseForm(superform).getVaultAsset();

        _authorizeOperator(superform, 0);

        vm.startPrank(InvestmentManagerLike(investmentManager).root());
        _fulfillRedeemRequest(investmentManager, vault, asset, 0.9e18, user);
        vm.stopPrank();

        vm.startPrank(deployer);
        vm.recordLogs();
        AsyncStateRegistry(getContract(dstChainId, "AsyncStateRegistry")).claimAvailableRedeem(
            user, superformId, bytes("")
        );
        vm.stopPrank();

        if (failedRemint) {
            _payloadDeliveryHelper(srcChainId, dstChainId, vm.getRecordedLogs());

            vm.selectFork(FORKS[srcChainId]);
            vm.startPrank(deployer);
            AsyncStateRegistry(getContract(srcChainId, "AsyncStateRegistry")).processPayload(2);
            vm.stopPrank();
        }

        uint256 superPositionsAfter =
            SuperPositions(getContract(dstChainId, "SuperPositions")).balanceOf(user, superformId);

        assertLt(
            superPositionsAfter, superPositionsBefore, "User's SuperPositions balance should decrease after redeeming"
        );
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
}

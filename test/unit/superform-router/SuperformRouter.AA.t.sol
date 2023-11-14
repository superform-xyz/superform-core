// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import { Error } from "src/utils/Error.sol";
import "test/utils/ProtocolActions.sol";

import { ERC1155Holder } from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract SmartContractWallet is ERC1155Holder {
    SuperformRouter immutable router;
    address immutable dai;

    constructor(SuperformRouter router_, address dai_) {
        router = router_;
        dai = dai_;
    }

    receive() external payable { }

    function singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq memory req) external payable {
        MockERC20(dai).approve(address(router), req.superformData.amount);
        router.singleXChainSingleVaultDeposit{ value: msg.value }(req);
    }

    function singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq memory req) external payable {
        router.singleXChainSingleVaultWithdraw{ value: msg.value }(req);
    }
}

contract SuperformRouterAATest is ProtocolActions {
    address receiverAddress = address(444);
    SmartContractWallet walletSource;
    SmartContractWallet walletDestination;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        walletSource =
        new SmartContractWallet(SuperformRouter(payable(getContract(ETH, "SuperformRouter"))), getContract(ETH, "DAI"));

        vm.selectFork(FORKS[ARBI]);
        walletDestination =
        new SmartContractWallet(SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))), getContract(ARBI, "DAI"));
    }

    function test_depositWithSmartContractWallet() public {
        _xChainDeposit_SmartContractWallet(false, true);
    }

    function test_depositWithSmartContractWallet_revertsReceive4626_noReceiveAddress() public {
        _xChainDeposit_SmartContractWallet(false, false);
    }

    function test_depositWithSmartContractWallet_receive4626_HasReceiveAddress() public {
        _xChainDeposit_SmartContractWallet(true, true);
    }

    function test_withdrawWithSmartContractWallet() public {
        _xChainDeposit_SmartContractWallet(false, true);

        _xChainWithdraw_SmartContractWallet(ETH, address(walletDestination), false, true);
    }

    function test_withdrawWithSmartContractWallet_3rdChainId() public {
        _xChainDeposit_SmartContractWallet(false, true);
        vm.selectFork(FORKS[AVAX]);
        SmartContractWallet walletDestinationAVAX =
        new SmartContractWallet(SuperformRouter(payable(getContract(AVAX, "SuperformRouter"))), getContract(AVAX, "DAI"));

        _xChainWithdraw_SmartContractWallet(AVAX, address(walletDestinationAVAX), false, true);
    }

    function _xChainDeposit_SmartContractWallet(bool receive4626_, bool receiveAddress_) internal {
        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);
        vm.startPrank(deployer);

        vm.selectFork(FORKS[ETH]);
        address superformRouter = getContract(ETH, "SuperformRouter");

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "DAI"),
            superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
            1e18,
            false,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1
        );

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            10_000,
            false,
            receive4626_,
            /// @dev invalid slippage
            LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), ARBI, 0),
            "",
            receiveAddress_ ? address(walletDestination) : address(0),
            ""
        );

        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds_, ARBI, data);

        vm.deal(address(walletSource), 2 ether);
        deal(getContract(ETH, "DAI"), address(walletSource), 1e18);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(walletSource), 1e18);
        vm.stopPrank();

        vm.recordLogs();

        vm.prank(deployer);

        if (!receiveAddress_ && !receive4626_) {
            vm.expectRevert(Error.RECEIVER_ADDRESS_NOT_SET.selector);
            /// @dev msg sender is wallet, tx origin is deployer
            walletSource.singleXChainSingleVaultDeposit{ value: 2 ether }(req);
            return;
        }
        /// @dev msg sender is wallet, tx origin is deployer
        walletSource.singleXChainSingleVaultDeposit{ value: 2 ether }(req);

        Vm.Log[] memory logs = vm.getRecordedLogs();

        /// @dev simulate cross-chain payload delivery
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).helpWithEstimates(
            LZ_ENDPOINTS[ARBI],
            500_000,
            /// note: using some max limit
            FORKS[ARBI],
            logs
        );

        HyperlaneHelper(getContract(ETH, "HyperlaneHelper")).help(
            HYPERLANE_MAILBOXES[ETH], HYPERLANE_MAILBOXES[ARBI], FORKS[ARBI], logs
        );

        /// @dev update and process the payload on ARBI
        vm.selectFork(FORKS[ARBI]);
        vm.prank(deployer);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).updateDepositPayload(1, amounts);

        uint256 nativeAmount = PaymentHelper(getContract(ARBI, "PaymentHelper")).estimateAckCost(1);

        vm.recordLogs();
        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).processPayload{ value: nativeAmount }(1);

        if (!receive4626_) {
            logs = vm.getRecordedLogs();

            /// @dev simulate cross-chain payload delivery
            LayerZeroHelper(getContract(ARBI, "LayerZeroHelper")).helpWithEstimates(
                LZ_ENDPOINTS[ETH],
                500_000,
                /// note: using some max limit
                FORKS[ETH],
                logs
            );

            HyperlaneHelper(getContract(ARBI, "HyperlaneHelper")).help(
                HYPERLANE_MAILBOXES[ARBI], HYPERLANE_MAILBOXES[ETH], FORKS[ETH], logs
            );

            /// @dev mint super positions on source chain
            vm.selectFork(FORKS[ETH]);
            vm.prank(deployer);
            CoreStateRegistry(payable(getContract(ETH, "CoreStateRegistry"))).processPayload(1);
        }
    }

    function _xChainWithdraw_SmartContractWallet(
        uint64 liqDstChainId_,
        address scWalletAtLiqDst_,
        bool sameChainTxData_,
        bool receiveAddress_
    )
        internal
    {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);

        address superformRouter = getContract(ETH, "SuperformRouter");

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ARBI, "DAI"),
            getContract(ARBI, "DAI"),
            getContract(ETH, "DAI"),
            superform,
            ARBI,
            ETH,
            liqDstChainId_,
            false,
            scWalletAtLiqDst_,
            uint256(liqDstChainId_),
            1e18,
            true,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1
        );
        address walletDst = liqDstChainId_ != ETH ? scWalletAtLiqDst_ : address(walletDestination);
        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1000,
            false,
            false,
            LiqRequest(
                1,
                _buildLiqBridgeTxData(liqBridgeTxDataArgs, sameChainTxData_),
                getContract(ARBI, "DAI"),
                liqDstChainId_,
                0
            ),
            "",
            receiveAddress_ ? walletDst : address(0),
            ""
        );

        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds_, ARBI, data);

        /// @dev approves before call
        vm.prank(address(walletSource));
        SuperPositions(getContract(ETH, "SuperPositions")).increaseAllowance(superformRouter, superformId, 1e18);
        vm.recordLogs();

        vm.prank(deployer);
        vm.deal(deployer, 2 ether);
        walletSource.singleXChainSingleVaultWithdraw{ value: 2 ether }(req);

        Vm.Log[] memory logs = vm.getRecordedLogs();

        /// @dev simulate cross-chain payload delivery
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).helpWithEstimates(
            LZ_ENDPOINTS[ARBI],
            10_000_000,
            /// note: using some max limit
            FORKS[ARBI],
            logs
        );

        HyperlaneHelper(getContract(ETH, "HyperlaneHelper")).help(
            HYPERLANE_MAILBOXES[ETH], HYPERLANE_MAILBOXES[ARBI], FORKS[ARBI], logs
        );

        /// @dev update and process the payload on ARBI
        vm.selectFork(FORKS[ARBI]);

        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).processPayload(2);
    }
}

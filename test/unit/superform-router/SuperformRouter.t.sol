// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";

contract SuperformRouterTest is ProtocolActions {
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

    function setUp() public override {
        super.setUp();
    }

    function test_validateSlippage() public {
        vm.selectFork(FORKS[ETH]);

        vm.expectRevert(Error.INVALID_INTERNAL_CALL.selector);
        CoreStateRegistry(getContract(ETH, "CoreStateRegistry")).validateSlippage(1, 2, 3);
    }

    function test_depositToInvalidFormId() public {
        /// scenario: deposit to an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// try depositing without approval
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0),
            "",
            false,
            false,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }

    function test_deposit_noTxData() public {
        /// scenario: deposit to an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// try depositing without approval
        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0),
            "",
            false,
            false,
            receiverAddress,
            receiverAddress,
            ""
        );
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ARBI, data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);

        vm.expectRevert(Error.NO_TXDATA_PRESENT.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleXChainSingleVaultDeposit(req);
    }

    function test_deposit_noReceiverAddress() public {
        /// scenario: deposit to an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// try depositing without approval
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0),
            "",
            false,
            false,
            receiverAddress,
            address(0),
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }

    function test_deposit_multiVault_noReceiverAddress() public {
        /// scenario: deposit to an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// try depositing without approval
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        uint256[] memory superformids = new uint256[](1);
        superformids[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory outputAmounts = new uint256[](1);
        outputAmounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformids,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReq,
            "",
            new bool[](1),
            new bool[](1),
            receiverAddress,
            address(0),
            ""
        );

        SingleDirectMultiVaultStateReq memory req = SingleDirectMultiVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectMultiVaultDeposit(req);
    }

    function test_withdrawFromInvalidFormImplId() public {
        /// scenario: withdraw from a superform by modifying the form implementation id
        vm.selectFork(FORKS[ETH]);

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[1], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0),
            "",
            false,
            false,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        vm.prank(router);
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingle(deployer, superformId, 2e18);
        SuperPositions(getContract(ETH, "SuperPositions")).setApprovalForAll(router, true);

        vm.prank(deployer);
        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(router)).singleDirectSingleVaultWithdraw(req);
    }

    function test_depositToCraftedSuperformId() public {
        /// scenario: deposit to an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// try depositing without approval
        address superform = address(4202);

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0),
            "",
            false,
            false,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }

    function test_depositToInvalidFormId_multiVault() public {
        /// scenario: deposit to an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// try depositing without approval
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory outputAmounts = new uint256[](1);
        outputAmounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        bool[] memory retain4626s = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest("", getContract(ARBI, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReq,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleDirectMultiVaultStateReq memory req = SingleDirectMultiVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectMultiVaultDeposit(req);
    }

    function test_depositMultiVault_retain4626_butReceiveAddressIs0() public {
        /// scenario: deposit to an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// try depositing without approval
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory outputAmounts = new uint256[](1);
        outputAmounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        bool[] memory retain4626s = new bool[](1);

        retain4626s[0] = true;

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReq,
            "",
            hasDstSwaps,
            retain4626s,
            address(0),
            address(0),
            ""
        );

        SingleDirectMultiVaultStateReq memory req = SingleDirectMultiVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectMultiVaultDeposit(req);
    }

    function test_depositMultiVault_VaultLimitPassed() public {
        /// scenario: deposit to an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// try depositing without approval
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId;
        superformIds[1] = superformId;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        uint256[] memory outputAmounts = new uint256[](2);
        outputAmounts[0] = 1e18;
        outputAmounts[1] = 1e18;

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 100;
        maxSlippages[1] = 100;

        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 1;

        bool[] memory hasDstSwaps = new bool[](2);

        bool[] memory retain4626s = new bool[](2);

        LiqRequest[] memory liqReq = new LiqRequest[](2);
        liqReq[0] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);
        liqReq[1] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReq,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleDirectMultiVaultStateReq memory req = SingleDirectMultiVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);
        SuperRegistry(getContract(ETH, "SuperRegistry")).setVaultLimitPerDestination(ETH, 1);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectMultiVaultDeposit(req);
    }

    function test_withdrawFromInvalidFormId() public {
        /// scenario: withdraw from an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        vm.startPrank(getContract(ETH, "SuperformRouter"));
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingle(deployer, superformId, 1e18);

        vm.startPrank(deployer);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory outputAmounts = new uint256[](1);
        outputAmounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        bool[] memory retain4626s = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](2);
        liqReq[0] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);
        liqReq[1] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReq,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleDirectMultiVaultStateReq memory req = SingleDirectMultiVaultStateReq(data);

        SuperPositions(getContract(ETH, "SuperPositions")).increaseAllowance(
            getContract(ETH, "SuperformRouter"), superformId, 1e18
        );

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectMultiVaultWithdraw(req);
    }

    function test_withdrawInvalidSuperformData() public {
        vm.selectFork(FORKS[ETH]);

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        vm.startPrank(getContract(ETH, "SuperformRouter"));
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingle(deployer, superformId, 1e18);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1e18,
            10_001,
            LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0),
            "",
            false,
            false,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultWithdraw(req);
    }

    function test_withdrawWithWrongLiqDataLength() public {
        /// note: unlikely scenario, deposit should fail for such cases
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        vm.startPrank(getContract(ETH, "SuperformRouter"));
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingle(deployer, superformId, 1e18);

        vm.startPrank(deployer);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory outputAmounts = new uint256[](1);
        outputAmounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        bool[] memory retain4626s = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](2);
        liqReq[0] = LiqRequest("", getContract(ARBI, "DAI"), address(0), 1, ETH, 0);
        liqReq[1] = LiqRequest("", getContract(ARBI, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReq,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        address superformRouter = getContract(ETH, "SuperformRouter");

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultWithdraw(req);
    }

    function test_withdrawWithInvalidChainIds() public {
        /// note: unlikely scenario, deposit should fail for such cases
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        vm.startPrank(getContract(ETH, "SuperformRouter"));
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingle(deployer, superformId, 1e18);

        vm.startPrank(deployer);

        uint256 amount = 1e18;

        uint256 outputAmount = 1e18;

        uint256 maxSlippage = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest memory liqReq = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            amount,
            outputAmount,
            maxSlippage,
            liqReq,
            "",
            false,
            false,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ETH, data);

        address superformRouter = getContract(ETH, "SuperformRouter");

        vm.expectRevert(Error.INVALID_ACTION.selector);
        SuperformRouter(payable(superformRouter)).singleXChainSingleVaultWithdraw(req);
    }

    function test_withdrawInvalidSuperformData_xChain() public {
        /// note: unlikely scenario, deposit should fail for such cases
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        vm.startPrank(getContract(ETH, "SuperformRouter"));
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingle(deployer, superformId, 1e18);

        vm.startPrank(deployer);

        uint256 amount = 1e18;

        uint256 outputAmount = 1e18;

        uint256 maxSlippage = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest memory liqReq = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            amount,
            outputAmount,
            maxSlippage,
            liqReq,
            "",
            false,
            false,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ARBI, data);

        address superformRouter = getContract(ETH, "SuperformRouter");

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainSingleVaultWithdraw(req);
    }

    function test_withdrawWithWrongSlippageLength() public {
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        vm.startPrank(getContract(ETH, "SuperformRouter"));
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingle(deployer, superformId, 1e18);

        vm.startPrank(deployer);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory outputAmounts = new uint256[](1);
        outputAmounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](0);

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        bool[] memory retain4626s = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest("", getContract(ARBI, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReq,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        address superformRouter = getContract(ETH, "SuperformRouter");

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultWithdraw(req);
    }

    function test_depositWithWrongSlippageLength() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory outputAmounts = new uint256[](1);
        outputAmounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](0);

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        bool[] memory retain4626s = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest("", getContract(ARBI, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReq,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit(req);
    }

    function test_depositWithMismatchingChainIdsInStateReqAndSuperformsDataMulti() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        /// @dev incorrect chainId (should be ARBI)
        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], POLY);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory outputAmounts = new uint256[](1);
        outputAmounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        bool[] memory retain4626s = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest("", getContract(ARBI, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReq,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit(req);
    }

    function test_depositWithWrongAmountsLength() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        /// @dev 0 amounts length
        uint256[] memory amounts = new uint256[](0);

        uint256[] memory outputAmounts = new uint256[](1);
        outputAmounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        bool[] memory retain4626s = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest("", getContract(ARBI, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReq,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit(req);
    }

    function test_depositWithWrongOutputAmountsLength() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        /// @dev 0 amounts length
        uint256[] memory outputAmounts = new uint256[](0);

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        bool[] memory retain4626s = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest("", getContract(ARBI, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReq,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit(req);
    }

    function test_depositWithMismatchingAmountsAndLiqRequestsLengths() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;
        /// @dev new amount

        uint256[] memory outputAmounts = new uint256[](1);
        outputAmounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        bool[] memory retain4626s = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest("", getContract(ARBI, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReq,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit(req);
    }

    function test_depositWithInvalidMaxSlippage() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory outputAmounts = new uint256[](1);
        outputAmounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 10_001;
        /// @dev invalid max slippage

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        bool[] memory retain4626s = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest("", getContract(ARBI, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReq,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit(req);
    }

    function test_withdrawWithMismatchingChainIdsInStateReqAndSuperformsDataMulti() public {
        _successfulMultiVaultDeposit();

        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superformRouter = getContract(ETH, "SuperformRouter");

        address superform1 = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        address superform2 = getContract(
            ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_IMPLEMENTATION_IDS[0], POLY);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_IMPLEMENTATION_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId1;
        superformIds[1] = superformId2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        bool[] memory hasDstSwaps = new bool[](2);

        bool[] memory retain4626s = new bool[](2);

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);
        liqReqs[1] = LiqRequest("", getContract(ETH, "WETH"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            amounts,
            maxSlippages,
            liqReqs,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );

        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);
        MockERC20(getContract(ETH, "WETH")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
    }

    function test_withdrawWithWrongAmountsLength() public {
        _successfulMultiVaultDeposit();

        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superformRouter = getContract(ETH, "SuperformRouter");

        address superform1 = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        address superform2 = getContract(
            ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_IMPLEMENTATION_IDS[0], ARBI);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_IMPLEMENTATION_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId1;
        superformIds[1] = superformId2;

        uint256[] memory amounts = new uint256[](0);

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        bool[] memory hasDstSwaps = new bool[](2);

        bool[] memory retain4626s = new bool[](2);

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);
        liqReqs[1] = LiqRequest("", getContract(ETH, "WETH"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            maxSlippages,
            maxSlippages,
            liqReqs,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );
        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);
        MockERC20(getContract(ETH, "WETH")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
    }

    function test_withdrawWithWrongOutputAmountsLength() public {
        _successfulMultiVaultDeposit();

        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superformRouter = getContract(ETH, "SuperformRouter");

        address superform1 = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        address superform2 = getContract(
            ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_IMPLEMENTATION_IDS[0], ARBI);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_IMPLEMENTATION_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId1;
        superformIds[1] = superformId2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        uint256[] memory outputAmounts = new uint256[](0);

        bool[] memory hasDstSwaps = new bool[](2);

        bool[] memory retain4626s = new bool[](2);

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);
        liqReqs[1] = LiqRequest("", getContract(ETH, "WETH"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            amounts,
            liqReqs,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );
        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);
        MockERC20(getContract(ETH, "WETH")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
    }

    function test_withdrawWithInvalidMaxSlippage() public {
        _successfulMultiVaultDeposit();

        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superformRouter = getContract(ETH, "SuperformRouter");

        address superform1 = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        address superform2 = getContract(
            ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_IMPLEMENTATION_IDS[0], ARBI);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_IMPLEMENTATION_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId1;
        superformIds[1] = superformId2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 10_001;
        maxSlippages[1] = 99_999;

        bool[] memory hasDstSwaps = new bool[](2);

        bool[] memory retain4626s = new bool[](2);

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);
        liqReqs[1] = LiqRequest("", getContract(ETH, "WETH"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            amounts,
            maxSlippages,
            liqReqs,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );
        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);
        MockERC20(getContract(ETH, "WETH")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
    }

    function test_depositWithInvalidFeeForward() public {
        /// scenario: deposit to an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// try depositing without approval
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0),
            "",
            false,
            false,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }

    function test_depositWithZeroAmount() public {
        /// scenario: deposit to an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// try depositing without approval
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            0,
            /// @dev 0 amount here and in the LiqRequest,
            1e18,
            100,
            LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0),
            "",
            false,
            false,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        /// @dev no point approving 0 tokens
        // MockERC20(getContract(ETH, "DAI")).approve(formImplementation, 0);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }

    function test_depositWithZeroOutputAmount() public {
        /// scenario: deposit to an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// try depositing without approval
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            0,
            100,
            LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 1e18),
            "",
            false,
            false,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }

    function test_withdrawMultiVaultXChain_InvalidAction() public {
        /// scenario: withdraw from an paused form form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        vm.startPrank(getContract(ETH, "SuperformRouter"));
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingle(deployer, superformId, 1e18);

        vm.startPrank(deployer);
        SuperPositions(getContract(ETH, "SuperPositions")).increaseAllowance(
            getContract(ETH, "SuperformRouter"), superformId, 1e18
        );

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        bool[] memory hasDstSwaps = new bool[](1);

        bool[] memory retain4626s = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest("", getContract(ARBI, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            amounts,
            maxSlippages,
            liqReq,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ETH, data);

        address superformRouter = getContract(ETH, "SuperformRouter");

        vm.expectRevert(Error.INVALID_ACTION.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
    }

    function test_withdrawWithPausedImplementations() public {
        _pauseFormImplementation();

        /// scenario: withdraw from an paused form form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        vm.startPrank(getContract(ETH, "SuperformRouter"));
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingle(deployer, superformId, 1e18);

        vm.startPrank(deployer);
        SuperPositions(getContract(ETH, "SuperPositions")).increaseAllowance(
            getContract(ETH, "SuperformRouter"), superformId, 1e18
        );

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        bool[] memory hasDstSwaps = new bool[](1);

        bool[] memory retain4626s = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest("", getContract(ARBI, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            amounts,
            maxSlippages,
            liqReq,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        address superformRouter = getContract(ETH, "SuperformRouter");

        vm.recordLogs();
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
        vm.stopPrank();

        Vm.Log[] memory logs = vm.getRecordedLogs();

        /// @dev mocks the cross-chain payload delivery
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).helpWithEstimates(
            LZ_ENDPOINTS[ARBI],
            5_000_000,
            /// note: using some max limit
            FORKS[ARBI],
            logs
        );

        HyperlaneHelper(getContract(ETH, "HyperlaneHelper")).help(
            HYPERLANE_MAILBOXES[ETH], HYPERLANE_MAILBOXES[ARBI], FORKS[ARBI], logs
        );

        vm.selectFork(FORKS[ARBI]);
        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).processPayload(1);
        assertEq(EmergencyQueue(getContract(ARBI, "EmergencyQueue")).queueCounter(), 1);
    }

    function test_depositWithPausedImplementation() public {
        _pauseFormImplementation();

        /// scenario: deposit from an paused form form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        bool[] memory retain4626s = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest("", getContract(ARBI, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            amounts,
            maxSlippages,
            liqReq,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit(req);
    }

    function test_depositWithInvalidDstChainId() public {
        /// scenario: deposit from an paused form form id (which doesn't exist on the chain)

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        vm.selectFork(FORKS[ETH]);

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        1,
                        getContract(ETH, "DAI"),
                        getContract(ETH, "DAI"),
                        superform,
                        ETH,
                        ETH,
                        1e18,
                        getContract(ETH, "CoreStateRegistry"),
                        false
                    )
                ),
                getContract(ETH, "DAI"),
                address(0),
                1,
                ETH,
                0
            ),
            "",
            false,
            false,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ETH, data);

        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_ACTION.selector);
        SuperformRouter(payable(superformRouter)).singleXChainSingleVaultDeposit(req);
    }

    function test_depositMultiVaultWithInvalidDstChainId() public {
        MultiVaultDepositVars memory v;

        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        v.superformRouter = getContract(ETH, "SuperformRouter");

        v.superformIds = new uint256[](2);
        v.superformIds[0] = DataLib.packSuperform(
            getContract(
                ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ETH
        );
        v.superformIds[1] = DataLib.packSuperform(
            getContract(
                ETH, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ETH
        );

        v.amounts = new uint256[](2);
        v.amounts[0] = 1e18;
        v.amounts[1] = 1e18;

        v.outputAmounts = new uint256[](2);
        v.outputAmounts[0] = 1e18;
        v.outputAmounts[1] = 1e18;

        v.maxSlippages = new uint256[](2);
        v.maxSlippages[0] = 1000;
        v.maxSlippages[1] = 1000;

        v.hasDstSwaps = new bool[](2);

        v.retain4626s = new bool[](2);

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "DAI"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
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

        v.liqReqs = new LiqRequest[](2);
        v.liqReqs[0] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ARBI, 0
        );

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "WETH"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
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

        v.liqReqs[1] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ARBI, 0
        );

        MultiVaultSFData memory data = MultiVaultSFData(
            v.superformIds,
            v.amounts,
            v.outputAmounts,
            v.maxSlippages,
            v.liqReqs,
            "",
            v.hasDstSwaps,
            v.retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );
        v.ambIds = new uint8[](1);
        v.ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(v.ambIds, ETH, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(v.superformRouter, 2e18);
        vm.expectRevert(Error.INVALID_ACTION.selector);
        SuperformRouter(payable(v.superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(req);
    }

    function test_depositWithMismatchingChainIdsInStateReqAndSuperformsData() public {
        /// scenario: deposit from an paused form form id (which doesn't exist on the chain)

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        /// @dev incorrect chainId (should be ARBI)
        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], POLY);

        vm.selectFork(FORKS[ARBI]);

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        1,
                        getContract(ETH, "DAI"),
                        getContract(ARBI, "DAI"),
                        superform,
                        ETH,
                        ARBI,
                        1e18,
                        getContract(ARBI, "CoreStateRegistry"),
                        false
                    )
                ),
                getContract(ARBI, "DAI"),
                address(0),
                1,
                ETH,
                0
            ),
            "",
            false,
            false,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ARBI, data);

        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainSingleVaultDeposit(req);
    }

    function test_depositWithInvalidSlippage() public {
        /// scenario: deposit from an paused form form id (which doesn't exist on the chain)

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        vm.selectFork(FORKS[ARBI]);

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1e18,
            10_001,
            /// @dev invalid slippage
            LiqRequest(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        1,
                        getContract(ETH, "DAI"),
                        getContract(ARBI, "DAI"),
                        superform,
                        ETH,
                        ARBI,
                        1e18,
                        getContract(ARBI, "CoreStateRegistry"),
                        false
                    )
                ),
                getContract(ARBI, "DAI"),
                address(0),
                1,
                ETH,
                0
            ),
            "",
            false,
            false,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ARBI, data);

        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainSingleVaultDeposit(req);
    }

    function test_multiVaultTokenForward_INVALID_DEPOSIT_TOKEN() public {
        MultiVaultDepositVars memory v;

        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        v.superformRouter = getContract(ETH, "SuperformRouter");

        v.superformIds = new uint256[](2);
        v.superformIds[0] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );
        v.superformIds[1] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );

        v.amounts = new uint256[](2);
        v.amounts[0] = 1e18;
        v.amounts[1] = 1e18;

        v.outputAmounts = new uint256[](2);
        v.outputAmounts[0] = 1e18;
        v.outputAmounts[1] = 1e18;

        v.maxSlippages = new uint256[](2);
        v.maxSlippages[0] = 1000;
        v.maxSlippages[1] = 1000;

        v.hasDstSwaps = new bool[](2);

        v.retain4626s = new bool[](2);

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "DAI"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
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

        v.liqReqs = new LiqRequest[](2);
        v.liqReqs[0] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ARBI, 0
        );

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "WETH"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
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

        v.liqReqs[1] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "WETH"), address(0), 1, ARBI, 0
        );

        MultiVaultSFData memory data = MultiVaultSFData(
            v.superformIds,
            v.amounts,
            v.outputAmounts,
            v.maxSlippages,
            v.liqReqs,
            "",
            v.hasDstSwaps,
            v.retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );
        v.ambIds = new uint8[](1);
        v.ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(v.ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(v.superformRouter, 2e18);

        vm.expectRevert(Error.INVALID_DEPOSIT_TOKEN.selector);
        SuperformRouter(payable(v.superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(req);
        vm.stopPrank();
    }

    function test_depositMultiVaultWithRepeatedInterimTokens() public {
        MultiVaultDepositVars memory v;

        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        v.superformRouter = getContract(ETH, "SuperformRouter");

        v.superformIds = new uint256[](2);
        v.superformIds[0] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );
        v.superformIds[1] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );

        v.amounts = new uint256[](2);
        v.amounts[0] = 1e18;
        v.amounts[1] = 1e18;

        v.outputAmounts = new uint256[](2);
        v.outputAmounts[0] = 1e18;
        v.outputAmounts[1] = 1e18;

        v.maxSlippages = new uint256[](2);
        v.maxSlippages[0] = 1000;
        v.maxSlippages[1] = 1000;

        v.hasDstSwaps = new bool[](2);
        v.hasDstSwaps[0] = true;
        v.hasDstSwaps[1] = true;

        v.retain4626s = new bool[](2);

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "USDC"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            true,
            getContract(ARBI, "DstSwapper"),
            uint256(ARBI),
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

        v.liqReqs = new LiqRequest[](2);
        v.liqReqs[0] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false),
            getContract(ETH, "DAI"),
            getContract(ARBI, "DAI"),
            1,
            ARBI,
            0
        );

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "USDC"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "DstSwapper"),
            uint256(ARBI),
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

        v.liqReqs[1] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false),
            getContract(ETH, "WETH"),
            getContract(ARBI, "DAI"),
            1,
            ARBI,
            0
        );

        MultiVaultSFData memory data = MultiVaultSFData(
            v.superformIds,
            v.amounts,
            v.outputAmounts,
            v.maxSlippages,
            v.liqReqs,
            "",
            v.hasDstSwaps,
            v.retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );
        v.ambIds = new uint8[](1);
        v.ambIds[0] = 1;

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(v.ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(v.superformRouter, 2e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(v.superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(req);
        vm.stopPrank();
    }

    function test_multiVaultTokenForward_withPermit2_passing() public {
        MultiVaultDepositVars memory v;
        /// @dev in this test no tokens would be bridged (no txData)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(users[1]);

        v.superformRouter = getContract(ETH, "SuperformRouter");

        v.superformIds = new uint256[](2);
        v.superformIds[0] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );
        v.superformIds[1] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );

        v.amounts = new uint256[](2);
        v.amounts[0] = 1e18;
        v.amounts[1] = 1e18;

        v.outputAmounts = new uint256[](2);
        v.outputAmounts[0] = 1e18;
        v.outputAmounts[1] = 1e18;

        v.maxSlippages = new uint256[](2);
        v.maxSlippages[0] = 1000;
        v.maxSlippages[1] = 1000;

        v.hasDstSwaps = new bool[](2);

        v.retain4626s = new bool[](2);

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "DAI"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
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

        v.liqReqs = new LiqRequest[](2);
        v.liqReqs[0] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ARBI, 0
        );

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "WETH"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
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

        v.liqReqs[1] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ARBI, 0
        );
        /// @dev approve total amount
        v.permit = IPermit2.PermitTransferFrom({
            permitted: IPermit2.TokenPermissions({ token: IERC20(getContract(ETH, "DAI")), amount: 2e18 }),
            nonce: _randomUint256(),
            deadline: block.timestamp
        });
        MockERC20(getContract(ETH, "DAI")).approve(getContract(ETH, "CanonicalPermit2"), type(uint256).max);

        v.ambIds = new uint8[](2);
        v.ambIds[0] = 1;
        v.ambIds[1] = 2;

        SuperformRouter(payable(v.superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(
                v.ambIds,
                ARBI,
                MultiVaultSFData(
                    v.superformIds,
                    v.amounts,
                    v.outputAmounts,
                    v.maxSlippages,
                    v.liqReqs,
                    abi.encode(
                        v.permit.nonce, v.permit.deadline, _signPermit(v.permit, v.superformRouter, userKeys[1], ETH)
                    ),
                    v.hasDstSwaps,
                    v.retain4626s,
                    receiverAddress,
                    receiverAddress,
                    ""
                )
            )
        );
        vm.stopPrank();
    }

    function test_tokenForwardWithManInMiddlePermit2Sig() public {
        MultiVaultDepositVars memory v;
        /// @dev in this test no tokens would be bridged (no txData)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(users[1]);

        v.superformRouter = getContract(ETH, "SuperformRouter");

        v.superformIds = new uint256[](2);
        v.superformIds[0] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );
        v.superformIds[1] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );

        v.amounts = new uint256[](2);
        v.amounts[0] = 1e18;
        v.amounts[1] = 1e18;

        v.outputAmounts = new uint256[](2);
        v.outputAmounts[0] = 1e18;
        v.outputAmounts[1] = 1e18;

        v.maxSlippages = new uint256[](2);
        v.maxSlippages[0] = 1000;
        v.maxSlippages[1] = 1000;

        v.hasDstSwaps = new bool[](2);

        v.retain4626s = new bool[](2);

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "DAI"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
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

        v.liqReqs = new LiqRequest[](2);
        v.liqReqs[0] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ARBI, 0
        );

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "WETH"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
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

        v.liqReqs[1] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ARBI, 0
        );
        /// @dev approve total amount
        v.permit = IPermit2.PermitTransferFrom({
            permitted: IPermit2.TokenPermissions({ token: IERC20(getContract(ETH, "DAI")), amount: 2e18 }),
            nonce: _randomUint256(),
            deadline: block.timestamp
        });
        MockERC20(getContract(ETH, "DAI")).approve(getContract(ETH, "CanonicalPermit2"), type(uint256).max);

        v.ambIds = new uint8[](2);
        v.ambIds[0] = 1;
        v.ambIds[1] = 2;

        /// @dev sign using keys of user 0 to simulate the scenario
        bytes memory signedPermit = _signPermit(v.permit, v.superformRouter, userKeys[0], ETH);

        vm.expectRevert(InvalidSigner.selector);
        SuperformRouter(payable(v.superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(
                v.ambIds,
                ARBI,
                MultiVaultSFData(
                    v.superformIds,
                    v.amounts,
                    v.outputAmounts,
                    v.maxSlippages,
                    v.liqReqs,
                    abi.encode(v.permit.nonce, v.permit.deadline, signedPermit),
                    v.hasDstSwaps,
                    v.retain4626s,
                    receiverAddress,
                    receiverAddress,
                    ""
                )
            )
        );
        vm.stopPrank();
    }

    function test_multiVaultTokenForward_withPermit2_noAmounts() public {
        MultiVaultDepositVars memory v;
        /// @dev in this test no tokens would be bridged (no txData)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(users[1]);

        v.superformRouter = getContract(ETH, "SuperformRouter");

        v.superformIds = new uint256[](2);
        v.superformIds[0] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );
        v.superformIds[1] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );

        v.amounts = new uint256[](2);
        v.amounts[0] = 1e18;
        v.amounts[1] = 1e18;

        v.outputAmounts = new uint256[](2);
        v.outputAmounts[0] = 1e18;
        v.outputAmounts[1] = 1e18;

        v.maxSlippages = new uint256[](2);
        v.maxSlippages[0] = 1000;
        v.maxSlippages[1] = 1000;

        v.hasDstSwaps = new bool[](2);

        v.retain4626s = new bool[](2);

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "DAI"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
            0,
            //1e18,
            false,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1,
            address(0)
        );

        v.liqReqs = new LiqRequest[](2);
        v.liqReqs[0] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ARBI, 0
        );

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "WETH"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
            0,
            //1e18,
            false,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1,
            address(0)
        );

        v.liqReqs[1] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ARBI, 0
        );
        /// @dev approve total amount
        v.permit = IPermit2.PermitTransferFrom({
            permitted: IPermit2.TokenPermissions({ token: IERC20(getContract(ETH, "DAI")), amount: 2e18 }),
            nonce: _randomUint256(),
            deadline: block.timestamp
        });
        MockERC20(getContract(ETH, "DAI")).approve(getContract(ETH, "CanonicalPermit2"), type(uint256).max);

        v.ambIds = new uint8[](2);
        v.ambIds[0] = 1;
        v.ambIds[1] = 2;

        bytes memory permitSigned = _signPermit(v.permit, v.superformRouter, userKeys[1], ETH);
        vm.expectRevert(Error.ZERO_AMOUNT.selector);
        SuperformRouter(payable(v.superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(
                v.ambIds,
                ARBI,
                MultiVaultSFData(
                    v.superformIds,
                    v.amounts,
                    v.outputAmounts,
                    v.maxSlippages,
                    v.liqReqs,
                    abi.encode(v.permit.nonce, v.permit.deadline, permitSigned),
                    v.hasDstSwaps,
                    v.retain4626s,
                    receiverAddress,
                    receiverAddress,
                    ""
                )
            )
        );
        vm.stopPrank();
    }

    function test_multiVaultTokenForward_noTxData_withNormalApprove_passing() public {
        MultiVaultDepositVars memory v;
        /// @dev in this test no tokens would be bridged (no txData)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(users[1]);

        v.superformRouter = getContract(ETH, "SuperformRouter");

        v.superformIds = new uint256[](2);
        v.superformIds[0] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );
        v.superformIds[1] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );

        v.amounts = new uint256[](2);
        v.amounts[0] = 1e18;
        v.amounts[1] = 1e18;

        v.outputAmounts = new uint256[](2);
        v.outputAmounts[0] = 1e18;
        v.outputAmounts[1] = 1e18;

        v.maxSlippages = new uint256[](2);
        v.maxSlippages[0] = 1000;
        v.maxSlippages[1] = 1000;

        v.hasDstSwaps = new bool[](2);

        v.retain4626s = new bool[](2);

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "DAI"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
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

        v.liqReqs = new LiqRequest[](2);
        v.liqReqs[0] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ARBI, 0
        );

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "WETH"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
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

        v.liqReqs[1] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ARBI, 0
        );
        /// @dev approve total amount

        MockERC20(getContract(ETH, "DAI")).approve(v.superformRouter, 2e18);

        v.ambIds = new uint8[](2);
        v.ambIds[0] = 1;
        v.ambIds[1] = 2;

        SuperformRouter(payable(v.superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(
                v.ambIds,
                ARBI,
                MultiVaultSFData(
                    v.superformIds,
                    v.amounts,
                    v.outputAmounts,
                    v.maxSlippages,
                    v.liqReqs,
                    "",
                    v.hasDstSwaps,
                    v.retain4626s,
                    receiverAddress,
                    receiverAddress,
                    ""
                )
            )
        );
        vm.stopPrank();
    }

    function test_multiVaultTokenForward_noTxData_withNormalApprove_INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT() public {
        MultiVaultDepositVars memory v;
        /// @dev in this test no tokens would be bridged (no txData)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(users[1]);

        v.superformRouter = getContract(ETH, "SuperformRouter");

        v.superformIds = new uint256[](2);
        v.superformIds[0] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );
        v.superformIds[1] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );

        v.amounts = new uint256[](2);
        v.amounts[0] = 1e18;
        v.amounts[1] = 1e18;

        v.outputAmounts = new uint256[](2);
        v.outputAmounts[0] = 1e18;
        v.outputAmounts[1] = 1e18;

        v.maxSlippages = new uint256[](2);
        v.maxSlippages[0] = 1000;
        v.maxSlippages[1] = 1000;

        v.hasDstSwaps = new bool[](2);

        v.retain4626s = new bool[](2);

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "DAI"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
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

        v.liqReqs = new LiqRequest[](2);
        v.liqReqs[0] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ARBI, 0
        );

        v.liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "WETH"),
            v.superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
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

        v.liqReqs[1] = LiqRequest(
            _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ARBI, 0
        );
        /// @dev approve a part of the amount amount

        MockERC20(getContract(ETH, "DAI")).approve(v.superformRouter, 1e18);

        v.ambIds = new uint8[](1);
        v.ambIds[0] = 1;

        vm.expectRevert(Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT.selector);
        SuperformRouter(payable(v.superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(
                v.ambIds,
                ARBI,
                MultiVaultSFData(
                    v.superformIds,
                    v.amounts,
                    v.outputAmounts,
                    v.maxSlippages,
                    v.liqReqs,
                    "",
                    v.hasDstSwaps,
                    v.retain4626s,
                    receiverAddress,
                    receiverAddress,
                    ""
                )
            )
        );
        vm.stopPrank();
    }

    function test_multiVaultTokenForward_noTxData() public {
        MultiVaultDepositVars memory v;
        /// @dev in this test no tokens would be bridged (no txData)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(users[1]);

        v.superformRouter = getContract(ETH, "SuperformRouter");

        v.superformIds = new uint256[](2);
        v.superformIds[0] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );
        v.superformIds[1] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );

        v.amounts = new uint256[](2);
        v.amounts[0] = 1e18;
        v.amounts[1] = 1e18;

        v.outputAmounts = new uint256[](2);
        v.outputAmounts[0] = 1e18;
        v.outputAmounts[1] = 1e18;

        v.maxSlippages = new uint256[](2);
        v.maxSlippages[0] = 1000;
        v.maxSlippages[1] = 1000;

        v.hasDstSwaps = new bool[](2);

        v.retain4626s = new bool[](2);

        v.liqReqs = new LiqRequest[](2);
        v.liqReqs[0] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ARBI, 0);

        v.liqReqs[1] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ARBI, 0);
        /// @dev approve total amount
        v.permit = IPermit2.PermitTransferFrom({
            permitted: IPermit2.TokenPermissions({ token: IERC20(getContract(ETH, "DAI")), amount: 2e18 }),
            nonce: _randomUint256(),
            deadline: block.timestamp
        });
        MockERC20(getContract(ETH, "DAI")).approve(getContract(ETH, "CanonicalPermit2"), type(uint256).max);

        v.ambIds = new uint8[](1);
        v.ambIds[0] = 1;
        v.permit2Data =
            abi.encode(v.permit.nonce, v.permit.deadline, _signPermit(v.permit, v.superformRouter, userKeys[1], ETH));

        vm.expectRevert(Error.NO_TXDATA_PRESENT.selector);
        SuperformRouter(payable(v.superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(
                v.ambIds,
                ARBI,
                MultiVaultSFData(
                    v.superformIds,
                    v.amounts,
                    v.outputAmounts,
                    v.maxSlippages,
                    v.liqReqs,
                    v.permit2Data,
                    v.hasDstSwaps,
                    v.retain4626s,
                    receiverAddress,
                    receiverAddress,
                    ""
                )
            )
        );

        vm.stopPrank();
    }

    function test_multiVaultTokenForward_successfulSingleDirectWithNotxData() public {
        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);
        address superformRouter = getContract(ETH, "SuperformRouter");
        address superform1 = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        address superform2 = getContract(
            ETH, string.concat("DAI", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[1]))
        );

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_IMPLEMENTATION_IDS[0], ETH);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_IMPLEMENTATION_IDS[1], ETH);

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
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        LiqRequest[] memory liqReqs = new LiqRequest[](2);

        liqReqs[0] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);
        liqReqs[1] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReqs,
            "",
            new bool[](2),
            new bool[](2),
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleDirectMultiVaultStateReq memory req = SingleDirectMultiVaultStateReq(data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouter), 2e18);

        SuperformRouter(payable(superformRouter)).singleDirectMultiVaultDeposit{ value: 10 ether }(req);
        vm.stopPrank();
    }

    function test_multiVaultTokenForward_successfulSingleDirectWithNotxData_receive4626() public {
        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);
        address superformRouter = getContract(ETH, "SuperformRouter");
        address superform1 = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        address superform2 = getContract(
            ETH, string.concat("DAI", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[1]))
        );

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_IMPLEMENTATION_IDS[0], ETH);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_IMPLEMENTATION_IDS[1], ETH);

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
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        LiqRequest[] memory liqReqs = new LiqRequest[](2);

        liqReqs[0] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);
        liqReqs[1] = LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0);

        bool[] memory receive4626 = new bool[](2);
        receive4626[0] = true;
        receive4626[1] = true;

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReqs,
            "",
            new bool[](2),
            receive4626,
            receiverAddress,
            receiverAddress,
            ""
        );

        SingleDirectMultiVaultStateReq memory req = SingleDirectMultiVaultStateReq(data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouter), 2e18);

        SuperformRouter(payable(superformRouter)).singleDirectMultiVaultDeposit{ value: 10 ether }(req);

        assertEq(SuperPositions(getContract(ETH, "SuperPositions")).balanceOf(deployer, superformId1), 0);
        assertEq(SuperPositions(getContract(ETH, "SuperPositions")).balanceOf(deployer, superformId2), 0);

        vm.stopPrank();
    }

    function test_multiVault_retain4626() public {
        address mrperfect = vm.addr(421);

        uint256 superformId = _successfulDepositXChain(1, "VaultMock", 0, mrperfect, true);
        vm.selectFork(FORKS[ETH]);

        assertEq(SuperPositions(getContract(ETH, "SuperPositions")).balanceOf(mrperfect, superformId), 0);

        (address superform,,) = DataLib.getSuperform(superformId);
        vm.selectFork(FORKS[ARBI]);

        address vault = IBaseForm(superform).getVaultAddress();

        assertGt(IERC4626(vault).balanceOf(mrperfect), 0);
    }

    function test_negativeBridgeSlippage() public {
        /// case: where bridge 3 DAI updater updates 2 DAI
        /// outcome: deposit goes through depositing 2 DAI and 1 DAI remains on DstSwapper
        uint256 superformId = _simulateXChainDepositWithNegativeSlippage(false, false, true);

        /// @dev assert that the minted amount is the amount sent in superformData.amount
        vm.selectFork(FORKS[ETH]);
        assertEq(SuperPositions(getContract(ETH, "SuperPositions")).balanceOf(address(420), superformId), 2e18);

        /// @dev residual tokens live on CSR
        vm.selectFork(FORKS[ARBI]);
        assertEq(MockERC20(getContract(ARBI, "DAI")).balanceOf(getContract(ARBI, "CoreStateRegistry")), 1e18);
    }

    function test_negativeDstSwapSlippage() public {
        /// case: where bridge 3 DAI, dst swapper swapped 2 DAI, but updater updates 2 DAI
        /// outcome: deposit goes through depositing 2 DAI and 1 DAI remains on DstSwapper
        uint256 superformId = _simulateXChainDepositWithNegativeSlippage(true, false, false);

        /// @dev assert that the minted amount is the amount sent in superformData.amount
        vm.selectFork(FORKS[ETH]);
        assertEq(SuperPositions(getContract(ETH, "SuperPositions")).balanceOf(address(420), superformId), 2e18);

        /// @dev residual tokens live on DstSwapper
        vm.selectFork(FORKS[ARBI]);
        assertEq(MockERC20(getContract(ARBI, "DAI")).balanceOf(getContract(ARBI, "DstSwapper")), 1e18);
    }

    function test_negativeDstSwapSlippageAndUpdateSwappedAmount_RevertsInvalidKeeperCall() public {
        /// case: where bridge 3 DAI, dst swapper swapped 3 DAI (capped to 2) updater updates 3 DAI
        /// outcome: deposit should revert on update
        _simulateXChainDepositWithNegativeSlippage(true, true, true);

        /// @dev swapped tokens remain on DstSwapper
        vm.selectFork(FORKS[ARBI]);
        assertEq(MockERC20(getContract(ARBI, "DAI")).balanceOf(getContract(ARBI, "CoreStateRegistry")), 3e18);
    }

    function test_negativeDstSwapSlippageAndUpdateSuperformDataAmount() public {
        /// keeperUpdateExactAmount = false means keeper will update with the capped amount (2 DAI)
        uint256 superformId = _simulateXChainDepositWithNegativeSlippage(true, true, false);

        /// @dev assert that the minted amount is the amount sent in superformData.amount
        vm.selectFork(FORKS[ETH]);
        assertEq(SuperPositions(getContract(ETH, "SuperPositions")).balanceOf(address(420), superformId), 2e18);

        /// @dev swapped tokens (remainder of negative slippage) remain on dstSwapper
        vm.selectFork(FORKS[ARBI]);
        assertEq(MockERC20(getContract(ARBI, "DAI")).balanceOf(getContract(ARBI, "CoreStateRegistry")), 1e18);
    }

    function test_forwardDustToPaymaster_router() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address payable router = payable(getContract(ETH, "SuperformRouter"));

        address token = getContract(ETH, "DAI");
        /// @dev transfer 10 dai to router
        deal(token, router, 10e18);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperformRouter(router).forwardDustToPaymaster(address(0));

        SuperformRouter(router).forwardDustToPaymaster(token);
    }

    struct SimulateUpdateTestLocalVars {
        SingleVaultSFData data;
        uint8[] ambIds;
        address[] bridgedTokens;
        uint256[] amounts;
        uint256 nativeAmount;
        uint256 swapAmount;
    }

    function _simulateXChainDepositWithNegativeSlippage(
        bool hasDstSwap,
        bool swapperSwapExactBridgeAmount,
        bool keeperUpdateExactAmount
    )
        internal
        returns (uint256 superformId)
    {
        SimulateUpdateTestLocalVars memory v;

        /// scenario: user deposits but bridge provided more than expected output
        vm.selectFork(FORKS[ETH]);

        vm.prank(deployer);
        MockERC20(getContract(ETH, "DAI")).transfer(address(420), 3e18);

        superformId = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );

        vm.selectFork(FORKS[ETH]);
        v.data = SingleVaultSFData(
            superformId,
            2e18,
            2e18,
            1000,
            LiqRequest(
                _buildLiqBridgeTxData(
                    LiqBridgeTxDataArgs(
                        1,
                        getContract(ETH, "DAI"),
                        getContract(ETH, "DAI"),
                        getContract(ARBI, "DAI"),
                        getContract(ETH, "SuperformRouter"),
                        ETH,
                        ARBI,
                        ARBI,
                        false,
                        hasDstSwap ? getContract(ARBI, "DstSwapper") : getContract(ARBI, "CoreStateRegistry"),
                        uint256(ARBI),
                        3e18,
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
                getContract(ETH, "DAI"),
                getContract(ARBI, "DAI"),
                1,
                ARBI,
                0
            ),
            "",
            hasDstSwap,
            false,
            address(420),
            address(420),
            ""
        );

        v.ambIds = new uint8[](2);
        v.ambIds[0] = 1;
        v.ambIds[1] = 2;

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(v.ambIds, ARBI, v.data);

        /// @dev approves before call
        vm.prank(address(420));
        MockERC20(getContract(ETH, "DAI")).approve(getContract(ETH, "SuperformRouter"), 3e18);
        vm.recordLogs();

        vm.prank(address(420));
        vm.deal(address(420), 2 ether);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleXChainSingleVaultDeposit{ value: 2 ether }(
            req
        );

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
            address(HYPERLANE_MAILBOXES[ETH]), address(HYPERLANE_MAILBOXES[ARBI]), FORKS[ARBI], logs
        );

        /// @dev update and process the payload on ARBI
        vm.selectFork(FORKS[ARBI]);
        vm.startPrank(deployer);

        v.amounts = new uint256[](1);
        v.amounts[0] = keeperUpdateExactAmount ? 3e18 : 2e18; // false -± 2e18

        v.bridgedTokens = new address[](1);
        v.bridgedTokens[0] = getContract(ARBI, "DAI");

        v.swapAmount = swapperSwapExactBridgeAmount ? 3e18 : 2e18; // true -± 3e18

        if (hasDstSwap) {
            DstSwapper(payable(getContract(ARBI, "DstSwapper"))).processTx(
                1,
                1,
                _buildLiqBridgeTxDataDstSwap(
                    1,
                    getContract(ARBI, "DAI"),
                    getContract(ARBI, "DAI"),
                    getContract(ARBI, "DstSwapper"),
                    ARBI,
                    v.swapAmount,
                    0
                )
            );
        }

        if (hasDstSwap && keeperUpdateExactAmount && swapperSwapExactBridgeAmount) {
            vm.expectRevert(Error.INVALID_DST_SWAPPER_FAILED_SWAP.selector);
            CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).updateDepositPayload(
                1, v.bridgedTokens, v.amounts
            );
        } else {
            CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).updateDepositPayload(
                1, v.bridgedTokens, v.amounts
            );
            v.nativeAmount = PaymentHelper(getContract(ARBI, "PaymentHelper")).estimateAckCost(1);

            vm.recordLogs();
            vm.stopPrank();

            vm.prank(deployer);
            CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).processPayload{ value: v.nativeAmount }(
                1
            );

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
                address(HYPERLANE_MAILBOXES[ARBI]), address(HYPERLANE_MAILBOXES[ETH]), FORKS[ETH], logs
            );

            /// @dev mint super positions on source chain
            vm.selectFork(FORKS[ETH]);
            vm.prank(deployer);
            CoreStateRegistry(payable(getContract(ETH, "CoreStateRegistry"))).processPayload(1);
        }
    }

    function _successfulMultiVaultDeposit() internal {
        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superformRouter = getContract(ETH, "SuperformRouter");

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );
        superformIds[1] = DataLib.packSuperform(
            getContract(
                ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ARBI
        );

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        uint256[] memory outputAmounts = new uint256[](2);
        outputAmounts[0] = 1e18;
        outputAmounts[1] = 1e18;

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        bool[] memory hasDstSwaps = new bool[](2);

        bool[] memory retain4626s = new bool[](2);

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
            //1e18,
            false,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1,
            address(0)
        );

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest(
            _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ARBI, 0
        );

        liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ARBI, "WETH"),
            superformRouter,
            ETH,
            ARBI,
            ARBI,
            false,
            getContract(ARBI, "CoreStateRegistry"),
            uint256(ARBI),
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

        liqReqs[1] = LiqRequest(
            _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ARBI, 0
        );

        MultiVaultSFData memory data = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippages,
            liqReqs,
            "",
            hasDstSwaps,
            retain4626s,
            receiverAddress,
            receiverAddress,
            ""
        );
        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 2e18);
        vm.recordLogs();

        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(req);
        vm.stopPrank();
    }

    function _buildMaliciousTxData(
        uint8 liqBridgeKind_,
        address underlyingToken_,
        address from_,
        uint64 toChainId_,
        uint256 amount_,
        address receiver_
    )
        internal
        view
        returns (bytes memory txData)
    {
        if (liqBridgeKind_ == 1) {
            ILiFi.BridgeData memory bridgeData;
            LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);

            swapData[0] = LibSwap.SwapData(
                address(0),
                /// callTo (arbitrary)
                address(0),
                /// callTo (approveTo)
                underlyingToken_,
                underlyingToken_,
                amount_,
                abi.encode(from_, FORKS[toChainId_]),
                false // arbitrary
            );

            bridgeData = ILiFi.BridgeData(
                bytes32("1"),
                /// request id
                "",
                "",
                address(0),
                underlyingToken_,
                receiver_,
                amount_,
                uint256(toChainId_),
                false,
                true
            );

            txData = abi.encodeWithSelector(LiFiMock.swapAndStartBridgeTokensViaBridge.selector, bridgeData, swapData);
        }
    }

    function _pauseFormImplementation() public {
        /// pausing form form id 1 from ARBI
        uint32 formImplementationId = 1;

        vm.selectFork(FORKS[ARBI]);
        vm.startPrank(deployer);

        vm.recordLogs();
        SuperformFactory(getContract(ARBI, "SuperformFactory")).changeFormImplementationPauseStatus{ value: 800 ether }(
            formImplementationId, ISuperformFactory.PauseStatus.PAUSED, generateBroadcastParams(0)
        );

        _broadcastPayloadHelper(ARBI, vm.getRecordedLogs());

        for (uint256 i = 0; i < chainIds.length; ++i) {
            if (chainIds[i] != ARBI ) {
                vm.selectFork(FORKS[chainIds[i]]);

                bool statusBefore = SuperformFactory(getContract(chainIds[i], "SuperformFactory"))
                    .isFormImplementationPaused(formImplementationId);
                BroadcastRegistry(payable(getContract(chainIds[i], "BroadcastRegistry"))).processPayload(1);
                bool statusAfter = SuperformFactory(getContract(chainIds[i], "SuperformFactory"))
                    .isFormImplementationPaused(formImplementationId);

                /// @dev assert status update before and after processing the payload
                assertEq(statusBefore, false);
                assertEq(statusAfter, true);
            }
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import { Error } from "src/utils/Error.sol";
import "test/utils/ProtocolActions.sol";

contract SuperformRouterTest is ProtocolActions {
    address refundAddress = address(444);

    function setUp() public override {
        super.setUp();
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
            superformId, 1e18, 100, false, LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0), "", refundAddress, ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
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

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](2);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);
        liqReq[1] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReq, "", refundAddress, "");

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
            superformId, 1e18, 10_001, false, LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0), "", refundAddress, ""
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

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](2);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);
        liqReq[1] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReq, "", refundAddress, "");

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

        uint256 maxSlippage = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest memory liqReq = LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0);

        SingleVaultSFData memory data =
            SingleVaultSFData(superformId, amount, maxSlippage, false, liqReq, "", refundAddress, "");

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ETH, data);

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

        uint256[] memory maxSlippages = new uint256[](0);

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReq, "", refundAddress, "");

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

        uint256[] memory maxSlippages = new uint256[](0);

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReq, "", refundAddress, "");

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

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReq, "", refundAddress, "");

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

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReq, "", refundAddress, "");

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

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        bool[] memory hasDstSwaps = new bool[](1);

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReq, "", refundAddress, "");

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

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 10_001;
        /// @dev invalid max slippage

        bool[] memory hasDstSwaps = new bool[](1);

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReq, "", refundAddress, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit(req);
    }

    function test_withdrawWithMismatchingChainIdsInStateReqAndSuperformsDataMulti() public {
        _successfulMultiVaultDeposit();

        /// scenario: user deposits with his own collateral and has approved enough tokens
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

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0);
        liqReqs[1] = LiqRequest(1, "", getContract(ETH, "WETH"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReqs, "", refundAddress, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);
        MockERC20(getContract(ETH, "WETH")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
    }

    function test_withdrawWithWrongAmountsLength() public {
        _successfulMultiVaultDeposit();

        /// scenario: user deposits with his own collateral and has approved enough tokens
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

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0);
        liqReqs[1] = LiqRequest(1, "", getContract(ETH, "WETH"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReqs, "", refundAddress, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 1e18);
        MockERC20(getContract(ETH, "WETH")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
    }

    function test_withdrawWithInvalidMaxSlippage() public {
        _successfulMultiVaultDeposit();

        /// scenario: user deposits with his own collateral and has approved enough tokens
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

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0);
        liqReqs[1] = LiqRequest(1, "", getContract(ETH, "WETH"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReqs, "", refundAddress, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
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
            superformId, 1e18, 100, false, LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0), "", refundAddress, ""
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
            /// @dev 0 amount here and in the LiqRequest
            100,
            false,
            LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0),
            "",
            refundAddress,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        /// @dev no point approving 0 tokens
        // MockERC20(getContract(ETH, "DAI")).approve(formImplementation, 0);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
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

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReq, "", refundAddress, "");

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
            address(HyperlaneMailbox), address(HyperlaneMailbox), FORKS[ARBI], logs
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

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReq, "", refundAddress, "");

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
            100,
            false,
            LiqRequest(
                1,
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
                ETH,
                0
            ),
            "",
            refundAddress,
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
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superformRouter = getContract(ETH, "SuperformRouter");

        address superform1 = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        address superform2 = getContract(
            ETH, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_IMPLEMENTATION_IDS[0], ETH);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_IMPLEMENTATION_IDS[0], ETH);

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
            1
        );

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), ARBI, 0);

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
            1
        );

        liqReqs[1] = LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), ARBI, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReqs, "", refundAddress, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ETH, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 2e18);
        vm.expectRevert(Error.INVALID_ACTION.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(req);
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
            100,
            false,
            LiqRequest(
                1,
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
                ETH,
                0
            ),
            "",
            refundAddress,
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
            10_001,
            false,
            /// @dev invalid slippage
            LiqRequest(
                1,
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
                ETH,
                0
            ),
            "",
            refundAddress,
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
        /// scenario: user deposits with his own collateral and has approved enough tokens
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
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        bool[] memory hasDstSwaps = new bool[](2);

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
            1
        );

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), ARBI, 0);

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
            1
        );

        liqReqs[1] = LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "WETH"), ARBI, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReqs, "", refundAddress, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 2e18);

        vm.expectRevert(Error.INVALID_DEPOSIT_TOKEN.selector);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(req);
        vm.stopPrank();
    }

    struct MultiVaultDepositVars {
        address superformRouter;
        uint256[] superformIds;
        uint256[] amounts;
        uint256[] maxSlippages;
        bool[] hasDstSwaps;
        LiqRequest[] liqReqs;
        IPermit2.PermitTransferFrom permit;
        LiqBridgeTxDataArgs liqBridgeTxDataArgs;
        uint8[] ambIds;
        bytes permit2Data;
    }

    function test_multiVaultTokenForward_noTxData_withPermit2_passing() public {
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

        v.maxSlippages = new uint256[](2);
        v.maxSlippages[0] = 1000;
        v.maxSlippages[1] = 1000;

        v.hasDstSwaps = new bool[](2);

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
            1
        );

        v.liqReqs = new LiqRequest[](2);
        v.liqReqs[0] =
            LiqRequest(1, _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), ARBI, 0);

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
            1
        );

        v.liqReqs[1] =
            LiqRequest(1, _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), ARBI, 0);
        /// @dev approve total amount
        v.permit = IPermit2.PermitTransferFrom({
            permitted: IPermit2.TokenPermissions({ token: IERC20(getContract(ETH, "DAI")), amount: 2e18 }),
            nonce: _randomUint256(),
            deadline: block.timestamp
        });
        MockERC20(getContract(ETH, "DAI")).approve(getContract(ETH, "CanonicalPermit2"), type(uint256).max);

        v.ambIds = new uint8[](1);
        v.ambIds[0] = 1;

        SuperformRouter(payable(v.superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(
                v.ambIds,
                ARBI,
                MultiVaultSFData(
                    v.superformIds,
                    v.amounts,
                    v.maxSlippages,
                    v.hasDstSwaps,
                    v.liqReqs,
                    abi.encode(
                        v.permit.nonce, v.permit.deadline, _signPermit(v.permit, v.superformRouter, userKeys[1], ETH)
                    ),
                    refundAddress,
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

        v.maxSlippages = new uint256[](2);
        v.maxSlippages[0] = 1000;
        v.maxSlippages[1] = 1000;

        v.hasDstSwaps = new bool[](2);

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
            1
        );

        v.liqReqs = new LiqRequest[](2);
        v.liqReqs[0] =
            LiqRequest(1, _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), ARBI, 0);

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
            1
        );

        v.liqReqs[1] =
            LiqRequest(1, _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), ARBI, 0);
        /// @dev approve total amount

        MockERC20(getContract(ETH, "DAI")).approve(v.superformRouter, 2e18);

        v.ambIds = new uint8[](1);
        v.ambIds[0] = 1;

        SuperformRouter(payable(v.superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(
                v.ambIds,
                ARBI,
                MultiVaultSFData(
                    v.superformIds, v.amounts, v.maxSlippages, v.hasDstSwaps, v.liqReqs, "", refundAddress, ""
                )
            )
        );
        vm.stopPrank();
    }

    function test_multiVaultTokenForward_noTxData_withNormalApprove_DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE() public {
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

        v.maxSlippages = new uint256[](2);
        v.maxSlippages[0] = 1000;
        v.maxSlippages[1] = 1000;

        v.hasDstSwaps = new bool[](2);

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
            1
        );

        v.liqReqs = new LiqRequest[](2);
        v.liqReqs[0] =
            LiqRequest(1, _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), ARBI, 0);

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
            1
        );

        v.liqReqs[1] =
            LiqRequest(1, _buildLiqBridgeTxData(v.liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), ARBI, 0);
        /// @dev approve a part of the amount amount

        MockERC20(getContract(ETH, "DAI")).approve(v.superformRouter, 1e18);

        v.ambIds = new uint8[](1);
        v.ambIds[0] = 1;

        vm.expectRevert(Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE.selector);
        SuperformRouter(payable(v.superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(
            SingleXChainMultiVaultStateReq(
                v.ambIds,
                ARBI,
                MultiVaultSFData(
                    v.superformIds, v.amounts, v.maxSlippages, v.hasDstSwaps, v.liqReqs, "", refundAddress, ""
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

        v.maxSlippages = new uint256[](2);
        v.maxSlippages[0] = 1000;
        v.maxSlippages[1] = 1000;

        v.hasDstSwaps = new bool[](2);

        v.liqReqs = new LiqRequest[](2);
        v.liqReqs[0] = LiqRequest(1, "", getContract(ETH, "DAI"), ARBI, 0);

        v.liqReqs[1] = LiqRequest(1, "", getContract(ETH, "DAI"), ARBI, 0);
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
                    v.maxSlippages,
                    v.hasDstSwaps,
                    v.liqReqs,
                    v.permit2Data,
                    refundAddress,
                    ""
                )
            )
        );

        vm.stopPrank();
    }

    function test_multiVaultTokenForward_successfulSingleDirectWithNotxData() public {
        /// scenario: user deposits with his own collateral and has approved enough tokens
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

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        LiqRequest[] memory liqReqs = new LiqRequest[](2);

        liqReqs[0] = LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0);
        liqReqs[1] = LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](2), liqReqs, "", refundAddress, "");

        SingleDirectMultiVaultStateReq memory req = SingleDirectMultiVaultStateReq(data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouter), 2e18);

        SuperformRouter(payable(superformRouter)).singleDirectMultiVaultDeposit{ value: 10 ether }(req);
        vm.stopPrank();
    }

    function _successfulMultiVaultDeposit() internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
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
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        bool[] memory hasDstSwaps = new bool[](2);

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
            1
        );

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), ARBI, 0);

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
            1
        );

        liqReqs[1] = LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), ARBI, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, hasDstSwaps, liqReqs, "", refundAddress, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 2e18);
        vm.recordLogs();

        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultDeposit{ value: 2 ether }(req);
        vm.stopPrank();

        /// @dev mocks the cross-chain payload delivery
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).helpWithEstimates(
            LZ_ENDPOINTS[ARBI],
            500_000,
            /// note: using some max limit
            FORKS[ARBI],
            vm.getRecordedLogs()
        );
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
            formImplementationId, true, generateBroadcastParams(5, 1)
        );

        _broadcastPayloadHelper(ARBI, vm.getRecordedLogs());

        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] != ARBI) {
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

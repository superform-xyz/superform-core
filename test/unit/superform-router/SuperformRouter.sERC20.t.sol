// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import { IERC1155A } from "ERC1155A/interfaces/IERC1155A.sol";
import { sERC20 } from "ERC1155A/transmuter/sERC20.sol";
import { Error } from "src/utils/Error.sol";
import "test/utils/ProtocolActions.sol";
import { SuperformRouter } from "src/SuperformRouter.sol";
import { SuperTransmuter } from "src/SuperTransmuter.sol";

contract SuperformRouterSERC20Test is ProtocolActions {
    SuperformRouter superformRouterSERC20;
    SuperformRouter superformRouterSERC20Arbi;

    SuperTransmuter superTransmuterSyncer;
    SuperTransmuter superTransmuterSyncerArbi;

    address refundAddress = address(444);

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        superformRouterSERC20 = new SuperformRouter(getContract(ETH, "SuperRegistry"), 1, 2);

        superTransmuterSyncer = SuperTransmuter(getContract(ETH, "SuperTransmuter"));

        vm.selectFork(FORKS[ARBI]);

        superformRouterSERC20Arbi = new SuperformRouter(getContract(ARBI, "SuperRegistry"), 1, 2);

        superTransmuterSyncerArbi = SuperTransmuter(getContract(ARBI, "SuperTransmuter"));

        vm.selectFork(FORKS[ETH]);

        SuperRBAC superRBACC = SuperRBAC(getContract(ETH, "SuperRBAC"));
        SuperRegistry superRegistryC = SuperRegistry(getContract(ETH, "SuperRegistry"));

        superRegistryC.setAddress(keccak256("SUPERFORM_ROUTER_SERC20"), address(superformRouterSERC20), ETH);
        superRegistryC.setAddress(keccak256("SUPER_TRANSMUTER_SYNCER"), address(superTransmuterSyncer), ETH);

        uint8[] memory superformRouterIds = new uint8[](1);
        superformRouterIds[0] = 2;

        address[] memory stateSyncers = new address[](1);
        stateSyncers[0] = address(superTransmuterSyncer);

        address[] memory routers = new address[](1);
        routers[0] = address(superformRouterSERC20);

        superRegistryC.setRouterInfo(superformRouterIds, stateSyncers, routers);

        vm.selectFork(FORKS[ARBI]);

        superRBACC = SuperRBAC(getContract(ARBI, "SuperRBAC"));
        superRegistryC = SuperRegistry(getContract(ARBI, "SuperRegistry"));

        superRegistryC.setAddress(keccak256("SUPERFORM_ROUTER_SERC20"), address(superformRouterSERC20Arbi), ARBI);
        superRegistryC.setAddress(keccak256("SUPER_TRANSMUTER_SYNCER"), address(superTransmuterSyncerArbi), ARBI);

        superformRouterIds[0] = 2;

        stateSyncers[0] = address(superTransmuterSyncerArbi);

        routers[0] = address(superformRouterSERC20Arbi);

        superRegistryC.setRouterInfo(superformRouterIds, stateSyncers, routers);

        vm.stopPrank();
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

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleDirectSingleVaultDeposit(req);
    }

    function test_withdrawInvalidSuperformData() public {
        vm.selectFork(FORKS[ETH]);

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        _registerTransmuter(ETH, superformId, 1);
        vm.startPrank(address(superformRouterSERC20));
        superTransmuterSyncer.mintSingle(deployer, superformId, 1e18);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId, 1e18, 10_001, false, LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0), "", refundAddress, ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleDirectSingleVaultWithdraw(req);
    }

    function test_withdrawWithWrongLiqDataLength() public {
        /// note: unlikely scenario, deposit should fail for such cases
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        vm.selectFork(FORKS[ARBI]);

        _registerTransmuter(ARBI, superformId, 1);

        vm.selectFork(FORKS[ETH]);

        vm.startPrank(address(superformRouterSERC20));
        superTransmuterSyncer.mintSingle(deployer, superformId, 1e18);

        vm.startPrank(deployer);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest[] memory liqReq = new LiqRequest[](2);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);
        liqReq[1] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](1), liqReq, "", refundAddress, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultWithdraw(req);
    }

    function test_withdrawWithInvalidChainIds() public {
        /// note: unlikely scenario, deposit should fail for such cases

        /// simulating deposits by just minting superPosition
        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);
        vm.selectFork(FORKS[ARBI]);

        _registerTransmuter(ARBI, superformId, 1);

        vm.selectFork(FORKS[ETH]);

        vm.startPrank(address(superformRouterSERC20));

        superTransmuterSyncer.mintSingle(deployer, superformId, 1e18);

        vm.startPrank(deployer);

        uint256 amount = 1e18;

        uint256 maxSlippage = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest memory liqReq = LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0);

        SingleVaultSFData memory data =
            SingleVaultSFData(superformId, amount, maxSlippage, false, liqReq, "", refundAddress, "");

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ETH, data);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainSingleVaultWithdraw(req);
    }

    function test_withdrawWithWrongSlippageLength() public {
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        vm.selectFork(FORKS[ARBI]);

        _registerTransmuter(ARBI, superformId, 1);

        vm.selectFork(FORKS[ETH]);

        vm.startPrank(address(superformRouterSERC20));

        superTransmuterSyncer.mintSingle(deployer, superformId, 1e18);

        vm.startPrank(deployer);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](0);

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](1), liqReq, "", refundAddress, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultWithdraw(req);
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

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](1), liqReq, "", refundAddress, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultDeposit(req);
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

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](1), liqReq, "", refundAddress, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultDeposit(req);
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

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](1), liqReq, "", refundAddress, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultDeposit(req);
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

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](1), liqReq, "", refundAddress, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultDeposit(req);
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

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](1), liqReq, "", refundAddress, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultDeposit(req);
    }

    function test_withdrawWithWrongAmountsLength() public {
        _successfulXChainMultiVaultDeposit();

        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

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

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0);
        liqReqs[1] = LiqRequest(1, "", getContract(ETH, "WETH"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](2), liqReqs, "", refundAddress, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 1e18);
        MockERC20(getContract(ETH, "WETH")).approve(address(superformRouterSERC20), 1e18);

        address sERC20add1 = superTransmuterSyncer.synthethicTokenId(superformId1);
        address sERC20add2 = superTransmuterSyncer.synthethicTokenId(superformId2);

        sERC20(sERC20add1).approve(address(superformRouterSERC20), 1e18);
        sERC20(sERC20add2).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
    }

    function test_withdrawWithInvalidMaxSlippage() public {
        _successfulXChainMultiVaultDeposit();

        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

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

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0);
        liqReqs[1] = LiqRequest(1, "", getContract(ETH, "WETH"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](2), liqReqs, "", refundAddress, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 1e18);
        MockERC20(getContract(ETH, "WETH")).approve(address(superformRouterSERC20), 1e18);

        address sERC20add1 = superTransmuterSyncer.synthethicTokenId(superformId1);
        address sERC20add2 = superTransmuterSyncer.synthethicTokenId(superformId2);

        sERC20(sERC20add1).approve(address(superformRouterSERC20), 1e18);
        sERC20(sERC20add2).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
    }

    function test_successful_xchain_multivault_withdraw() public {
        _successfulXChainMultiVaultDeposit();

        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

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

        SuperTransmuter transmuter = SuperTransmuter(getContract(ETH, "SuperTransmuter"));

        amounts[0] = sERC20(transmuter.synthethicTokenId(superformId1)).balanceOf(deployer);
        amounts[1] = sERC20(transmuter.synthethicTokenId(superformId2)).balanceOf(deployer);

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest(1, "", address(0), ETH, 0);
        liqReqs[1] = LiqRequest(1, "", address(0), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](2), liqReqs, "", refundAddress, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        address sERC20add1 = superTransmuterSyncer.synthethicTokenId(superformId1);
        address sERC20add2 = superTransmuterSyncer.synthethicTokenId(superformId2);
        /// @dev approves before call
        sERC20(sERC20add1).approve(address(superformRouterSERC20), 1e18);
        sERC20(sERC20add2).approve(address(superformRouterSERC20), 1e18);
        vm.recordLogs();

        superformRouterSERC20.singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
        vm.stopPrank();

        /// @dev mocks the cross-chain payload delivery
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).helpWithEstimates(
            LZ_ENDPOINTS[ARBI],
            1_000_000,
            /// note: using some max limit
            FORKS[ARBI],
            vm.getRecordedLogs()
        );
        vm.selectFork(FORKS[ARBI]);

        (uint256 nativeAmount,) = PaymentHelper(getContract(ARBI, "PaymentHelper")).estimateAckCost(2);

        vm.startPrank(deployer);
        vm.recordLogs();
        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).processPayload{ value: nativeAmount }(2);
        vm.stopPrank();
    }

    function test_successful_direct_multivault_withdraw() public {
        _successfulDirectMultiVaultDeposit();

        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

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
        amounts[0] = sERC20(SuperTransmuter(getContract(ETH, "SuperTransmuter")).synthethicTokenId(superformId1))
            .balanceOf(deployer);
        amounts[1] = sERC20(SuperTransmuter(getContract(ETH, "SuperTransmuter")).synthethicTokenId(superformId2))
            .balanceOf(deployer);

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0);
        liqReqs[1] = LiqRequest(1, "", getContract(ETH, "WETH"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](2), liqReqs, "", refundAddress, "");

        SingleDirectMultiVaultStateReq memory req = SingleDirectMultiVaultStateReq(data);

        address sERC20add1 = superTransmuterSyncer.synthethicTokenId(superformId1);
        address sERC20add2 = superTransmuterSyncer.synthethicTokenId(superformId2);

        sERC20(sERC20add1).approve(address(superformRouterSERC20), 1e18);
        sERC20(sERC20add2).approve(address(superformRouterSERC20), 1e18);

        superformRouterSERC20.singleDirectMultiVaultWithdraw{ value: 2 ether }(req);
    }

    function test_successful_xchain_singlevault_withdraw() public {
        _successfulXChainSingleVaultDeposit();

        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        uint256 amount = sERC20(SuperTransmuter(getContract(ETH, "SuperTransmuter")).synthethicTokenId(superformId))
            .balanceOf(deployer);

        uint256 maxSlippage = 1000;
        LiqRequest memory liqReq = LiqRequest(1, "", address(0), ETH, 0);

        SingleVaultSFData memory data =
            SingleVaultSFData(superformId, amount, maxSlippage, false, liqReq, "", refundAddress, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ARBI, data);

        address sERC20add = superTransmuterSyncer.synthethicTokenId(superformId);

        sERC20(sERC20add).approve(address(superformRouterSERC20), 1e18);
        vm.recordLogs();

        /// @dev approves before call
        superformRouterSERC20.singleXChainSingleVaultWithdraw{ value: 2 ether }(req);

        vm.stopPrank();

        /// @dev mocks the cross-chain payload delivery
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).helpWithEstimates(
            LZ_ENDPOINTS[ARBI],
            1_000_000,
            /// note: using some max limit
            FORKS[ARBI],
            vm.getRecordedLogs()
        );

        vm.selectFork(FORKS[ARBI]);
        vm.startPrank(deployer);
        vm.recordLogs();
        (uint256 nativeAmount,) = PaymentHelper(getContract(ARBI, "PaymentHelper")).estimateAckCost(2);
        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).processPayload{ value: nativeAmount }(2);
        vm.stopPrank();
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

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleDirectSingleVaultDeposit(req);
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

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleDirectSingleVaultDeposit(req);
    }

    function test_withdrawWithPausedImplementationsa() public {
        _pauseFormImplementation();

        /// scenario: withdraw from an paused form form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        vm.selectFork(FORKS[ARBI]);

        /// @dev payloadId 1 already used in pauseFormImplementation
        _registerTransmuter(ARBI, superformId, 2);

        vm.selectFork(FORKS[ETH]);

        vm.startPrank(address(superformRouterSERC20));

        superTransmuterSyncer.mintSingle(deployer, superformId, 1e18);

        vm.startPrank(deployer);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](1), liqReq, "", refundAddress, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        vm.recordLogs();
        superformRouterSERC20.singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
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

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](1), liqReq, "", refundAddress, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultDeposit(req);
    }

    function test_depositWithInvalidDstChainId() public {
        /// scenario: deposit from an paused form form id (which doesn't exist on the chain)

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        _registerTransmuter(ETH, superformId, 1);

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
                    1,
                    getContract(ETH, "DAI"),
                    getContract(ETH, "DAI"),
                    superform,
                    ETH,
                    1e18,
                    getContract(ETH, "CoreStateRegistry"),
                    false
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

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_ACTION.selector);
        superformRouterSERC20.singleXChainSingleVaultDeposit(req);
    }

    function test_depositWithMismatchingChainIdsInStateReqAndSuperformsData() public {
        /// scenario: deposit from an paused form form id (which doesn't exist on the chain)

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        /// @dev incorrect chainId (should be ARBI)
        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], POLY);

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
                    1,
                    getContract(ETH, "DAI"),
                    getContract(ARBI, "DAI"),
                    superform,
                    ARBI,
                    1e18,
                    getContract(ARBI, "CoreStateRegistry"),
                    false
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

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainSingleVaultDeposit(req);
    }

    function test_depositWithInvalidSlippage() public {
        /// scenario: deposit from an paused form form id (which doesn't exist on the chain)

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);
        _registerTransmuter(ARBI, superformId, 1);

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
                    1,
                    getContract(ETH, "DAI"),
                    getContract(ARBI, "DAI"),
                    superform,
                    ARBI,
                    1e18,
                    getContract(ARBI, "CoreStateRegistry"),
                    false
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

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainSingleVaultDeposit(req);
    }

    function _successfulXChainMultiVaultDeposit() internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform1 = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        address superform2 = getContract(
            ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_IMPLEMENTATION_IDS[0], ARBI);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_IMPLEMENTATION_IDS[0], ARBI);

        vm.selectFork(FORKS[ARBI]);
        _registerTransmuter(ARBI, superformId1, 1);
        _registerTransmuter(ARBI, superformId2, 2);

        vm.selectFork(FORKS[ETH]);

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

        liqReqs[0] = LiqRequest(
            1,
            _buildLiqBridgeTxData(
                LiqBridgeTxDataArgs(
                    1,
                    getContract(ETH, "DAI"),
                    getContract(ETH, "DAI"),
                    getContract(ARBI, "DAI"),
                    address(superformRouterSERC20),
                    ETH,
                    ARBI,
                    ARBI,
                    false,
                    getContract(ARBI, "CoreStateRegistry"),
                    uint256(ARBI),
                    1e18,
                    //1e18,
                    false,
                    0,
                    1,
                    1,
                    1
                ),
                false
            ),
            getContract(ETH, "DAI"),
            ARBI,
            0
        );
        liqReqs[1] = LiqRequest(
            1,
            _buildLiqBridgeTxData(
                LiqBridgeTxDataArgs(
                    1,
                    getContract(ETH, "DAI"),
                    getContract(ETH, "DAI"),
                    getContract(ARBI, "WETH"),
                    address(superformRouterSERC20),
                    ETH,
                    ARBI,
                    ARBI,
                    false,
                    getContract(ARBI, "CoreStateRegistry"),
                    uint256(ARBI),
                    1e18,
                    //1e18,
                    false,
                    0,
                    1,
                    1,
                    1
                ),
                false
            ),
            getContract(ETH, "DAI"),
            ARBI,
            0
        );

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](2), liqReqs, "", refundAddress, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 2e18);
        vm.recordLogs();

        superformRouterSERC20.singleXChainMultiVaultDeposit{ value: 10 ether }(req);
        vm.stopPrank();

        /// @dev mocks the cross-chain payload delivery
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).helpWithEstimates(
            LZ_ENDPOINTS[ARBI],
            1_000_000,
            /// note: using some max limit
            FORKS[ARBI],
            vm.getRecordedLogs()
        );
        vm.selectFork(FORKS[ARBI]);

        vm.startPrank(deployer);
        SuperRegistry(getContract(ARBI, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).updateDepositPayload(1, amounts);

        vm.recordLogs();
        (uint256 nativeAmount,) = PaymentHelper(getContract(ARBI, "PaymentHelper")).estimateAckCost(1);
        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).processPayload{ value: nativeAmount }(1);
        vm.stopPrank();

        LayerZeroHelper(getContract(ARBI, "LayerZeroHelper")).helpWithEstimates(
            LZ_ENDPOINTS[ETH],
            1_000_000,
            /// note: using some max limit
            FORKS[ETH],
            vm.getRecordedLogs()
        );

        vm.selectFork(FORKS[ETH]);

        vm.startPrank(deployer);
        SuperRegistry(getContract(ETH, "SuperRegistry")).setRequiredMessagingQuorum(ARBI, 0);

        (nativeAmount,) = PaymentHelper(getContract(ETH, "PaymentHelper")).estimateAckCost(1);
        CoreStateRegistry(payable(getContract(ETH, "CoreStateRegistry"))).processPayload{ value: nativeAmount }(1);
        vm.stopPrank();
    }

    function _successfulDirectMultiVaultDeposit() internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform1 = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        address superform2 = getContract(
            ETH, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_IMPLEMENTATION_IDS[0], ETH);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_IMPLEMENTATION_IDS[0], ETH);

        _registerTransmuter(ETH, superformId1, 1);
        _registerTransmuter(ETH, superformId2, 2);

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

        liqReqs[0] = LiqRequest(
            1,
            _buildLiqBridgeTxData(
                LiqBridgeTxDataArgs(
                    1,
                    getContract(ETH, "DAI"),
                    getContract(ETH, "DAI"),
                    getContract(ETH, "DAI"),
                    superform1,
                    ETH,
                    ETH,
                    ETH,
                    false,
                    superform1,
                    uint256(ETH),
                    1e18,
                    //1e18,
                    false,
                    0,
                    1,
                    1,
                    1
                ),
                true
            ),
            getContract(ETH, "DAI"),
            ETH,
            0
        );
        liqReqs[1] = LiqRequest(
            1,
            _buildLiqBridgeTxData(
                LiqBridgeTxDataArgs(
                    1,
                    getContract(ETH, "DAI"),
                    getContract(ETH, "WETH"),
                    getContract(ETH, "WETH"),
                    superform2,
                    ETH,
                    ETH,
                    ETH,
                    false,
                    superform2,
                    uint256(ETH),
                    1e18,
                    //1e18,
                    false,
                    0,
                    1,
                    1,
                    1
                ),
                true
            ),
            getContract(ETH, "DAI"),
            ETH,
            0
        );

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](2), liqReqs, "", refundAddress, "");

        SingleDirectMultiVaultStateReq memory req = SingleDirectMultiVaultStateReq(data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 2e18);

        vm.recordLogs();

        superformRouterSERC20.singleDirectMultiVaultDeposit{ value: 10 ether }(req);
        vm.stopPrank();
    }

    function _successfulXChainSingleVaultDeposit() internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        _registerTransmuter(ARBI, superformId, 1);

        vm.selectFork(FORKS[ETH]);

        uint256 amount = 1e18;

        uint256 maxSlippage = 1000;

        LiqRequest memory liqReq = LiqRequest(
            1,
            _buildLiqBridgeTxData(
                LiqBridgeTxDataArgs(
                    1,
                    getContract(ETH, "DAI"),
                    getContract(ETH, "DAI"),
                    getContract(ARBI, "DAI"),
                    address(superformRouterSERC20),
                    ETH,
                    ARBI,
                    ARBI,
                    false,
                    getContract(ARBI, "CoreStateRegistry"),
                    uint256(ARBI),
                    1e18,
                    //1e18,
                    false,
                    0,
                    1,
                    1,
                    1
                ),
                false
            ),
            getContract(ETH, "DAI"),
            ARBI,
            0
        );

        SingleVaultSFData memory data =
            SingleVaultSFData(superformId, amount, maxSlippage, false, liqReq, "", refundAddress, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouterSERC20), 1e18);
        vm.recordLogs();

        superformRouterSERC20.singleXChainSingleVaultDeposit{ value: 10 ether }(req);
        vm.stopPrank();

        /// @dev mocks the cross-chain payload delivery
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).helpWithEstimates(
            LZ_ENDPOINTS[ARBI],
            1_000_000,
            /// note: using some max limit
            FORKS[ARBI],
            vm.getRecordedLogs()
        );
        vm.selectFork(FORKS[ARBI]);

        vm.startPrank(deployer);

        SuperRegistry(getContract(ARBI, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);
        uint256[] memory updatedAmounts = new uint256[](1);

        updatedAmounts[0] = amount;

        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).updateDepositPayload(1, updatedAmounts);

        vm.recordLogs();

        (uint256 nativeAmount,) = PaymentHelper(getContract(ARBI, "PaymentHelper")).estimateAckCost(1);
        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).processPayload{ value: nativeAmount }(1);
        vm.stopPrank();
        LayerZeroHelper(getContract(ARBI, "LayerZeroHelper")).helpWithEstimates(
            LZ_ENDPOINTS[ETH],
            1_000_000,
            /// note: using some max limit
            FORKS[ETH],
            vm.getRecordedLogs()
        );

        vm.selectFork(FORKS[ETH]);

        vm.startPrank(deployer);
        SuperRegistry(getContract(ETH, "SuperRegistry")).setRequiredMessagingQuorum(ARBI, 0);

        (nativeAmount,) = PaymentHelper(getContract(ETH, "PaymentHelper")).estimateAckCost(1);
        CoreStateRegistry(payable(getContract(ETH, "CoreStateRegistry"))).processPayload{ value: nativeAmount }(1);
        vm.stopPrank();
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

    function _registerTransmuter(uint64 srcChainId, uint256 superformId, uint256 payloadId) internal {
        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[srcChainId]);
        vm.recordLogs();
        SuperTransmuter(getContract(srcChainId, "SuperTransmuter")).registerTransmuter(
            superformId, generateBroadcastParams(5, 1)
        );

        vm.startPrank(deployer);
        _broadcastPayloadHelper(srcChainId, vm.getRecordedLogs());

        for (uint256 i; i < chainIds.length; i++) {
            if (chainIds[i] != srcChainId) {
                vm.selectFork(FORKS[chainIds[i]]);
                BroadcastRegistry(payable(getContract(chainIds[i], "BroadcastRegistry"))).processPayload(payloadId);

                assertGt(
                    uint256(
                        uint160(
                            SuperTransmuter(getContract(chainIds[i], "SuperTransmuter")).synthethicTokenId(superformId)
                        )
                    ),
                    uint256(0)
                );
            }
        }

        vm.selectFork(initialFork);
    }
}

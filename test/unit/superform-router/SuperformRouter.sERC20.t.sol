// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { IERC1155A } from "ERC1155A/interfaces/IERC1155A.sol";
import { sERC20 } from "ERC1155A/transmuter/sERC20.sol";

import { Error } from "src/utils/Error.sol";
import "test/utils/ProtocolActions.sol";
import { SuperformRouter } from "src/SuperformRouter.sol";
import { SuperTransmuterSyncer } from "test/mocks/SuperTransmuterSyncer.sol";

contract SuperformRouterSERC20Test is ProtocolActions {
    SuperformRouter superformRouterSERC20;
    SuperTransmuterSyncer superTransmuterSyncer;

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        superformRouterSERC20 = new SuperformRouter(getContract(ETH, "SuperRegistry"), 1, 2);

        superTransmuterSyncer =
        new SuperTransmuterSyncer(IERC1155A(getContract(ETH, "SuperPositions")), getContract(ETH, "SuperRegistry"), 2);

        SuperRBAC superRBACC = SuperRBAC(getContract(ETH, "SuperRBAC"));
        SuperRegistry superRegistryC = SuperRegistry(getContract(ETH, "SuperRegistry"));

        superRBACC.grantRole(superRBACC.SUPERPOSITIONS_MINTER_ROLE(), address(superformRouterSERC20));
        superRBACC.grantRole(superRBACC.SUPERPOSITIONS_BURNER_ROLE(), address(superformRouterSERC20));

        superRegistryC.setAddress(keccak256("SUPERFORM_ROUTER_SERC20"), address(superformRouterSERC20), ETH);
        superRegistryC.setAddress(keccak256("SUPER_TRANSMUTER_SYNCER"), address(superTransmuterSyncer), ETH);

        uint8[] memory superformRouterIds = new uint8[](2);
        superformRouterIds[0] = 1;
        superformRouterIds[1] = 2;

        address[] memory stateSyncers = new address[](2);
        stateSyncers[0] = getContract(ETH, "SuperPositions");
        stateSyncers[1] = address(superTransmuterSyncer);

        address[] memory routers = new address[](2);
        routers[0] = getContract(ETH, "SuperformRouter");
        routers[1] = address(superformRouterSERC20);

        superRegistryC.setRouterInfo(superformRouterIds, stateSyncers, routers);

        vm.stopPrank();
    }

    function test_depositToInvalidFormId() public {
        /// scenario: deposit to an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// try depositing without approval
        address superform =
            getContract(ETH, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ARBI);

        SingleVaultSFData memory data =
            SingleVaultSFData(superformId, 1e18, 100, LiqRequest(1, "", getContract(ETH, "USDT"), ETH, 1e18, 0, ""), "");

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        (address formBeacon,,) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);

        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(formBeacon, 1e18);

        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        superformRouterSERC20.singleDirectSingleVaultDeposit(req);
    }

    function test_withdrawFromInvalidFormId() public {
        /// scenario: withdraw from an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);

        address superform =
            getContract(ETH, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ARBI);

        superTransmuterSyncer.registerTransmuter(superformId);
        vm.startPrank(getContract(ETH, "SuperformRouter"));
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
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), ETH, 1e18, 0, "");
        liqReq[1] = LiqRequest(1, "", getContract(ARBI, "USDT"), ETH, 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReq, "");

        SingleDirectMultiVaultStateReq memory req = SingleDirectMultiVaultStateReq(data);

        (address formBeacon,,) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);
        address sERC20add = superTransmuterSyncer.synthethicTokenId(superformId);

        sERC20(sERC20add).approve(address(superformRouterSERC20), 1e18);
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        superformRouterSERC20.singleDirectMultiVaultWithdraw(req);
    }

    function test_withdrawInvalidSuperformData() public {
        vm.selectFork(FORKS[ETH]);

        address superform =
            getContract(ETH, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ETH);

        superTransmuterSyncer.registerTransmuter(superformId);
        vm.startPrank(getContract(ETH, "SuperformRouter"));
        superTransmuterSyncer.mintSingle(deployer, superformId, 1e18);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId, 1e18, 10_001, LiqRequest(1, "", getContract(ETH, "USDT"), ETH, 1e18, 0, ""), ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        (address formBeacon,,) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);

        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(formBeacon, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleDirectSingleVaultWithdraw(req);
    }

    function test_withdrawWithWrongLiqDataLength() public {
        /// note: unlikely scenario, deposit should fail for such cases
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superform =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ARBI);

        superTransmuterSyncer.registerTransmuter(superformId);
        vm.startPrank(getContract(ETH, "SuperformRouter"));
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
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), ETH, 1e18, 0, "");
        liqReq[1] = LiqRequest(1, "", getContract(ARBI, "USDT"), ETH, 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReq, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        address superformRouter = getContract(ETH, "SuperformRouter");

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultWithdraw(req);
    }

    function test_withdrawWithInvalidChainIds() public {
        /// note: unlikely scenario, deposit should fail for such cases
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superform =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ARBI);

        superTransmuterSyncer.registerTransmuter(superformId);
        vm.startPrank(getContract(ETH, "SuperformRouter"));
        superTransmuterSyncer.mintSingle(deployer, superformId, 1e18);

        vm.startPrank(deployer);

        uint256 amount = 1e18;

        uint256 maxSlippage = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest memory liqReq = LiqRequest(1, "", getContract(ETH, "USDT"), ETH, 1e18, 0, "");

        SingleVaultSFData memory data = SingleVaultSFData(superformId, amount, maxSlippage, liqReq, "");

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ETH, data);

        address superformRouter = getContract(ETH, "SuperformRouter");

        vm.expectRevert(Error.INVALID_CHAIN_IDS.selector);
        superformRouterSERC20.singleXChainSingleVaultWithdraw(req);
    }

    function test_withdrawWithWrongSlippageLength() public {
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superform =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ARBI);

        superTransmuterSyncer.registerTransmuter(superformId);
        vm.startPrank(getContract(ETH, "SuperformRouter"));
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
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), ETH, 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReq, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        address superformRouter = getContract(ETH, "SuperformRouter");

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultWithdraw(req);
    }

    function test_depositWithWrongSlippageLength() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](0);

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), ETH, 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReq, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultDeposit(req);
    }

    function test_depositWithMismatchingChainIdsInStateReqAndSuperformsDataMulti() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        /// @dev incorrect chainId (should be ARBI)
        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], POLY);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), ETH, 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReq, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultDeposit(req);
    }

    function test_depositWithAmountMismatchInSuperformsDataAndLiqRequest() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ARBI);

        vm.selectFork(FORKS[ARBI]);
        (address formBeacon,,) = SuperformFactory(getContract(ARBI, "SuperformFactory")).getSuperform(superformId);
        vm.selectFork(FORKS[ETH]);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        /// @dev incorrect amount (should be 1e18)
        liqReq[0] = LiqRequest(
            1,
            _buildMaliciousTxData(
                1,
                getContract(ARBI, "USDT"),
                formBeacon,
                ARBI,
                1e16,
                /// @dev incorrect amount (should be 1e18)
                getContract(ARBI, "CoreStateRegistry")
            ),
            getContract(ARBI, "USDT"),
            ETH,
            1e18,
            0,
            ""
        );

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReq, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultDeposit(req);
    }

    function test_depositWithWrongAmountsLength() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        /// @dev 0 amounts length
        uint256[] memory amounts = new uint256[](0);

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), ETH, 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReq, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultDeposit(req);
    }

    function test_depositWithMismatchingAmountsAndLiqRequestsLengths() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ARBI);

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
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), ETH, 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReq, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultDeposit(req);
    }

    function test_depositWithInvalidMaxSlippage() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ARBI);

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
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), ETH, 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReq, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultDeposit(req);
    }

    function test_withdrawWithMismatchingChainIdsInStateReqAndSuperformsDataMulti() public {
        _successfulMultiVaultDeposit();

        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superformRouter = getContract(ETH, "SuperformRouter");

        address superform1 =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        address superform2 =
            getContract(ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_BEACON_IDS[0], POLY);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_BEACON_IDS[0], ARBI);

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
        liqReqs[0] = LiqRequest(1, "", getContract(ETH, "USDT"), ETH, 1e18, 0, "");
        liqReqs[1] = LiqRequest(1, "", getContract(ETH, "WETH"), ETH, 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReqs, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superformRouter, 1e18);
        MockERC20(getContract(ETH, "WETH")).approve(superformRouter, 1e18);

        address sERC20add1 = superTransmuterSyncer.synthethicTokenId(superformId1);
        address sERC20add2 = superTransmuterSyncer.synthethicTokenId(superformId2);

        sERC20(sERC20add1).approve(address(superformRouterSERC20), 1e18);
        sERC20(sERC20add2).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
    }

    function test_withdrawWithWrongAmountsLength() public {
        _successfulMultiVaultDeposit();

        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superformRouter = getContract(ETH, "SuperformRouter");

        address superform1 =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        address superform2 =
            getContract(ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_BEACON_IDS[0], ARBI);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_BEACON_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId1;
        superformIds[1] = superformId2;

        uint256[] memory amounts = new uint256[](0);

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest(1, "", getContract(ETH, "USDT"), ETH, 1e18, 0, "");
        liqReqs[1] = LiqRequest(1, "", getContract(ETH, "WETH"), ETH, 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReqs, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superformRouter, 1e18);
        MockERC20(getContract(ETH, "WETH")).approve(superformRouter, 1e18);

        address sERC20add1 = superTransmuterSyncer.synthethicTokenId(superformId1);
        address sERC20add2 = superTransmuterSyncer.synthethicTokenId(superformId2);

        sERC20(sERC20add1).approve(address(superformRouterSERC20), 1e18);
        sERC20(sERC20add2).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
    }

    function test_withdrawWithInvalidMaxSlippage() public {
        _successfulMultiVaultDeposit();

        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superformRouter = getContract(ETH, "SuperformRouter");

        address superform1 =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        address superform2 =
            getContract(ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_BEACON_IDS[0], ARBI);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_BEACON_IDS[0], ARBI);

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
        liqReqs[0] = LiqRequest(1, "", getContract(ETH, "USDT"), ETH, 1e18, 0, "");
        liqReqs[1] = LiqRequest(1, "", getContract(ETH, "WETH"), ETH, 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReqs, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superformRouter, 1e18);
        MockERC20(getContract(ETH, "WETH")).approve(superformRouter, 1e18);

        address sERC20add1 = superTransmuterSyncer.synthethicTokenId(superformId1);
        address sERC20add2 = superTransmuterSyncer.synthethicTokenId(superformId2);

        sERC20(sERC20add1).approve(address(superformRouterSERC20), 1e18);
        sERC20(sERC20add2).approve(address(superformRouterSERC20), 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
    }

    function test_successful_withdraw() public {
        _successfulMultiVaultDeposit();

        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superformRouter = getContract(ETH, "SuperformRouter");

        address superform1 =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        address superform2 =
            getContract(ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_BEACON_IDS[0], ARBI);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_BEACON_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId1;
        superformIds[1] = superformId2;

        uint256[] memory amounts = new uint256[](0);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        LiqRequest[] memory liqReqs = new LiqRequest[](2);
        liqReqs[0] = LiqRequest(1, "", getContract(ETH, "USDT"), ETH, 1e18, 0, "");
        liqReqs[1] = LiqRequest(1, "", getContract(ETH, "WETH"), ETH, 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReqs, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        address sERC20add1 = superTransmuterSyncer.synthethicTokenId(superformId1);
        address sERC20add2 = superTransmuterSyncer.synthethicTokenId(superformId2);

        sERC20(sERC20add1).approve(address(superformRouterSERC20), 1e18);
        sERC20(sERC20add2).approve(address(superformRouterSERC20), 1e18);

        /// @dev approves before call
        superformRouterSERC20.singleXChainMultiVaultWithdraw{ value: 2 ether }(req);
    }

    function test_depositWithInvalidFeeForward() public {
        /// scenario: deposit to an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// try depositing without approval
        address superform =
            getContract(ETH, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ARBI);

        SingleVaultSFData memory data =
            SingleVaultSFData(superformId, 1e18, 100, LiqRequest(1, "", getContract(ETH, "USDT"), ETH, 1e18, 0, ""), "");

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        (address formBeacon,,) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);

        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(formBeacon, 1e18);

        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        superformRouterSERC20.singleDirectSingleVaultDeposit(req);
    }

    function test_depositWithZeroAmount() public {
        /// scenario: deposit to an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// try depositing without approval
        address superform =
            getContract(ETH, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            0,
            /// @dev 0 amount here and in the LiqRequest
            100,
            LiqRequest(1, "", getContract(ETH, "USDT"), ETH, 0, 0, ""),
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        (address formBeacon,,) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);

        /// @dev no point approving 0 tokens
        // MockERC20(getContract(ETH, "USDT")).approve(formBeacon, 0);

        vm.expectRevert(Error.ZERO_AMOUNT.selector);
        superformRouterSERC20.singleDirectSingleVaultDeposit(req);
    }

    function test_withdrawWithPausedBeacon() public {
        _pauseFormBeacon();

        /// scenario: withdraw from an paused form beacon id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superform =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ARBI);

        superTransmuterSyncer.registerTransmuter(superformId);
        vm.startPrank(getContract(ETH, "SuperformRouter"));
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

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), ETH, 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReq, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        address superformRouter = getContract(ETH, "SuperformRouter");

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultWithdraw(req);
    }

    function test_depositWithPausedBeacon() public {
        _pauseFormBeacon();

        /// scenario: deposit from an paused form beacon id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ARBI);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), ETH, 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReq, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainMultiVaultDeposit(req);
    }

    function test_depositWithInvalidAmountThanLiqDataAmount() public {
        /// scenario: deposit from an paused form beacon id (which doesn't exist on the chain)

        address superform =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ARBI);

        vm.selectFork(FORKS[ARBI]);
        (address formBeacon,,) = SuperformFactory(getContract(ARBI, "SuperformFactory")).getSuperform(superformId);

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            3e18,
            100,
            LiqRequest(
                1,
                _buildMaliciousTxData(
                    1, getContract(ARBI, "USDT"), formBeacon, ARBI, 1e18, getContract(ARBI, "CoreStateRegistry")
                ),
                getContract(ARBI, "USDT"),
                ETH,
                1e18,
                0,
                ""
            ),
            ""
        );

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ARBI, data);

        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_TXDATA_AMOUNTS.selector);
        superformRouterSERC20.singleXChainSingleVaultDeposit(req);
    }

    function test_depositWithInvalidDstChainId() public {
        /// scenario: deposit from an paused form beacon id (which doesn't exist on the chain)

        address superform =
            getContract(ETH, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ETH);

        vm.selectFork(FORKS[ETH]);
        (address formBeacon,,) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            100,
            LiqRequest(
                1,
                _buildMaliciousTxData(
                    1, getContract(ETH, "USDT"), formBeacon, ETH, 1e18, getContract(ETH, "CoreStateRegistry")
                ),
                getContract(ETH, "USDT"),
                ETH,
                1e18,
                0,
                ""
            ),
            ""
        );

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ETH, data);

        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_CHAIN_IDS.selector);
        superformRouterSERC20.singleXChainSingleVaultDeposit(req);
    }

    function test_depositWithMismatchingChainIdsInStateReqAndSuperformsData() public {
        /// scenario: deposit from an paused form beacon id (which doesn't exist on the chain)

        address superform =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        /// @dev incorrect chainId (should be ARBI)
        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], POLY);

        vm.selectFork(FORKS[ARBI]);
        (address formBeacon,,) = SuperformFactory(getContract(ARBI, "SuperformFactory")).getSuperform(superformId);

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            100,
            LiqRequest(
                1,
                _buildMaliciousTxData(
                    1, getContract(ARBI, "USDT"), formBeacon, ARBI, 1e18, getContract(ARBI, "CoreStateRegistry")
                ),
                getContract(ARBI, "USDT"),
                ETH,
                1e18,
                0,
                ""
            ),
            ""
        );

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ARBI, data);

        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainSingleVaultDeposit(req);
    }

    function test_depositWithInvalidSlippage() public {
        /// scenario: deposit from an paused form beacon id (which doesn't exist on the chain)

        address superform =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ARBI);

        vm.selectFork(FORKS[ARBI]);
        (address formBeacon,,) = SuperformFactory(getContract(ARBI, "SuperformFactory")).getSuperform(superformId);

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            10_001,
            /// @dev invalid slippage
            LiqRequest(
                1,
                _buildMaliciousTxData(
                    1, getContract(ARBI, "USDT"), formBeacon, ARBI, 1e18, getContract(ARBI, "CoreStateRegistry")
                ),
                getContract(ARBI, "USDT"),
                ETH,
                1e18,
                0,
                ""
            ),
            ""
        );

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ARBI, data);

        address superformRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superformRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        superformRouterSERC20.singleXChainSingleVaultDeposit(req);
    }

    function _successfulMultiVaultDeposit() internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superformRouter = getContract(ETH, "SuperformRouter");

        address superform1 =
            getContract(ARBI, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        address superform2 =
            getContract(ARBI, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0])));

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_BEACON_IDS[0], ARBI);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_BEACON_IDS[0], ARBI);

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
                1,
                getContract(ETH, "USDT"),
                getContract(ETH, "USDT"),
                getContract(ARBI, "USDT"),
                address(superformRouterSERC20),
                ARBI,
                false,
                getContract(ARBI, "CoreStateRegistry"),
                uint256(ARBI),
                1e18,
                false
            ),
            getContract(ETH, "USDT"),
            ARBI,
            1e18,
            0,
            ""
        );
        liqReqs[1] = LiqRequest(
            1,
            _buildLiqBridgeTxData(
                1,
                getContract(ETH, "WETH"),
                getContract(ETH, "WETH"),
                getContract(ARBI, "WETH"),
                address(superformRouterSERC20),
                ARBI,
                false,
                getContract(ARBI, "CoreStateRegistry"),
                uint256(ARBI),
                1e18,
                false
            ),
            getContract(ETH, "WETH"),
            ARBI,
            1e18,
            0,
            ""
        );

        MultiVaultSFData memory data = MultiVaultSFData(superformIds, amounts, maxSlippages, liqReqs, "");
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(address(superformRouterSERC20), 1e18);
        MockERC20(getContract(ETH, "WETH")).approve(address(superformRouterSERC20), 1e18);
        vm.recordLogs();

        superformRouterSERC20.singleXChainMultiVaultDeposit{ value: 2 ether }(req);
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
        returns (bytes memory txData)
    {
        if (liqBridgeKind_ == 1) {
            ISocketRegistry.BridgeRequest memory bridgeRequest;
            ISocketRegistry.MiddlewareRequest memory middlewareRequest;
            ISocketRegistry.UserRequest memory userRequest;
            /// @dev middlware request is used if there is a swap involved before the bridging action
            /// @dev the input token should be the token the user deposits, which will be swapped to the input token of
            /// bridging request
            middlewareRequest = ISocketRegistry.MiddlewareRequest(
                1,
                /// request id
                0,
                underlyingToken_,
                abi.encode(from_, FORKS[toChainId_])
            );

            /// @dev empty bridge request
            bridgeRequest = ISocketRegistry.BridgeRequest(
                0,
                /// id
                0,
                address(0),
                abi.encode(receiver_, FORKS[toChainId_])
            );

            userRequest =
                ISocketRegistry.UserRequest(receiver_, uint256(toChainId_), amount_, middlewareRequest, bridgeRequest);

            txData = abi.encodeWithSelector(SocketRouterMock.outboundTransferTo.selector, userRequest);
        } else if (liqBridgeKind_ == 2) {
            ILiFi.BridgeData memory bridgeData;
            ILiFi.SwapData[] memory swapData = new ILiFi.SwapData[](1);

            swapData[0] = ILiFi.SwapData(
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

    function _pauseFormBeacon() public {
        /// pausing form beacon id 1 from ARBI
        uint32 formBeaconId = 1;

        vm.selectFork(FORKS[ARBI]);
        vm.startPrank(deployer);

        vm.recordLogs();
        SuperformFactory(getContract(ARBI, "SuperformFactory")).changeFormBeaconPauseStatus{ value: 800 ether }(
            formBeaconId, true, generateBroadcastParams(5, 2)
        );

        _broadcastPayloadHelper(ARBI, vm.getRecordedLogs());

        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] != ARBI) {
                vm.selectFork(FORKS[chainIds[i]]);

                bool statusBefore =
                    SuperformFactory(getContract(chainIds[i], "SuperformFactory")).isFormBeaconPaused(formBeaconId);
                FactoryStateRegistry(payable(getContract(chainIds[i], "FactoryStateRegistry"))).processPayload(1);
                bool statusAfter =
                    SuperformFactory(getContract(chainIds[i], "SuperformFactory")).isFormBeaconPaused(formBeaconId);

                /// @dev assert status update before and after processing the payload
                assertEq(statusBefore, false);
                assertEq(statusAfter, true);
            }
        }
    }
}

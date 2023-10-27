// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import "test/utils/ProtocolActions.sol";

import { KYCDaoNFTMock } from "test/mocks/KYCDaoNFTMock.sol";

contract EmergencyQueueTest is ProtocolActions {
    /// our intended user who is a nice person
    address mrperfect;

    /// our users who is a friend of nice person that wants the refunds
    address mrimperfect;

    function setUp() public override {
        super.setUp();

        mrperfect = vm.addr(421);
        mrimperfect = vm.addr(420);
    }

    /*///////////////////////////////////////////////////////////////
                    PESSIMISTIC TEST_CASES
    //////////////////////////////////////////////////////////////*/

    /// @dev tries to process emergency queue by random user
    function test_emergencyQueueProcessingPrivilleges() public {
        /// user deposits successfully to a form
        _successfulDeposit();

        /// now pause the form and try to withdraw
        _pauseForm();

        /// try to withdraw after pause (mrperfect panicks)
        _withdrawAfterPause();

        vm.selectFork(FORKS[ETH]);
        address emergencyQueue = getContract(ETH, "EmergencyQueue");

        vm.expectRevert(Error.NOT_EMERGENCY_ADMIN.selector);
        vm.prank(mrimperfect);

        EmergencyQueue(emergencyQueue).executeQueuedWithdrawal(1);
    }

    /// @dev tries to queue emergency transaction by invalid caller
    function test_emergencyQueueAdditionPrivilleges() public {
        vm.selectFork(FORKS[ETH]);
        address emergencyQueue = getContract(ETH, "EmergencyQueue");

        vm.expectRevert(Error.NOT_SUPERFORM.selector);
        vm.prank(mrimperfect);

        EmergencyQueue(emergencyQueue).queueWithdrawal(
            InitSingleVaultData(
                1,
                1,
                _getTestSuperformId(),
                1e18, // good hacker tries to take only 1e18
                1000,
                false,
                LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0),
                mrimperfect,
                ""
            ),
            mrperfect
        );
    }

    /// @dev tries to queue emergency transaction by invalid superform
    /// @dev cross-form attack
    function test_emergencyQueueAdditionFormImplIdMismatch() public {
        vm.selectFork(FORKS[ETH]);
        address emergencyQueue = getContract(ETH, "EmergencyQueue");

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[1], ETH);

        vm.prank(superform);

        vm.expectRevert(Error.SUPERFORM_ID_NONEXISTENT.selector);
        EmergencyQueue(emergencyQueue).queueWithdrawal(
            InitSingleVaultData(
                1,
                1,
                superformId,
                1e18, // good hacker tries to take only 1e18
                1000,
                false,
                LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0),
                mrimperfect,
                ""
            ),
            mrperfect
        );
    }

    /// @dev tries to queue emergency transaction by invalid superform
    /// @dev cross-form attack
    function test_emergencyQueueAdditionChainIdMismatch() public {
        vm.selectFork(FORKS[ETH]);
        address emergencyQueue = getContract(ETH, "EmergencyQueue");

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        vm.prank(superform);

        vm.expectRevert(Error.SUPERFORM_ID_NONEXISTENT.selector);
        EmergencyQueue(emergencyQueue).queueWithdrawal(
            InitSingleVaultData(
                1,
                1,
                superformId,
                1e18, // good hacker tries to take only 1e18
                1000,
                false,
                LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0),
                mrimperfect,
                ""
            ),
            mrperfect
        );
    }

    /*///////////////////////////////////////////////////////////////
                    OPTIMISTIC TEST_CASES
    //////////////////////////////////////////////////////////////*/

    function test_emergencyQueueAddition() public {
        /// user deposits successfully to a form
        _successfulDeposit();

        /// pause the form
        _pauseForm();

        /// try to withdraw after pause (mrperfect panicks)
        _withdrawAfterPause();
    }

    function test_emergencyQueueProcessing() public {
        /// user deposits successfully to a form
        _successfulDeposit();

        /// now pause the form and try to withdraw
        _pauseForm();

        /// try to withdraw after pause (mrperfect panicks)
        _withdrawAfterPause();

        /// processing the queued withdrawal and assert
        vm.selectFork(FORKS[ETH]);

        /// @dev deployer has emergency admin role
        address emergencyQueue = getContract(ETH, "EmergencyQueue");

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 balanceBefore = MockERC20(IBaseForm(superform).getVaultAddress()).balanceOf(mrimperfect);

        assertFalse(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));
        vm.prank(deployer);
        EmergencyQueue(emergencyQueue).executeQueuedWithdrawal(1);
        assertTrue(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));

        uint256 balanceAfter = MockERC20(IBaseForm(superform).getVaultAddress()).balanceOf(mrimperfect);
        assertEq(balanceBefore + 1e18, balanceAfter);
    }

    function test_emergencyQueueProcessingNonExistentId() public {
        vm.selectFork(FORKS[ETH]);

        /// @dev deployer has emergency admin role
        address emergencyQueue = getContract(ETH, "EmergencyQueue");
        vm.prank(deployer);
        vm.expectRevert(Error.EMERGENCY_WITHDRAW_NOT_QUEUED.selector);
        EmergencyQueue(emergencyQueue).executeQueuedWithdrawal(1);
    }

    function test_emergencyQueueProcessingMultiVault() public {
        /// user deposits successfully to a form
        _successfulDeposit();
        _successfulDeposit();

        /// now pause the form and try to withdraw
        _pauseForm();

        /// try to withdraw after pause (mrperfect panicks)
        _withdrawAfterPauseMulti();

        /// processing the queued withdrawal and assert
        vm.selectFork(FORKS[ETH]);

        /// @dev deployer has emergency admin role
        address emergencyQueue = getContract(ETH, "EmergencyQueue");

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 balanceBefore = MockERC20(IBaseForm(superform).getVaultAddress()).balanceOf(mrimperfect);

        assertFalse(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));
        assertFalse(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(2));

        vm.prank(deployer);
        EmergencyQueue(emergencyQueue).executeQueuedWithdrawal(1);

        vm.prank(deployer);
        EmergencyQueue(emergencyQueue).executeQueuedWithdrawal(2);

        assertTrue(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));
        assertTrue(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(2));

        uint256 balanceAfter = MockERC20(IBaseForm(superform).getVaultAddress()).balanceOf(mrimperfect);
        assertEq(balanceBefore + (0.9e18 * 2), balanceAfter);
    }

    function test_emergencyQueueProcessingXChain() public {
        /// user deposits successfully to a form
        _successfulDepositXChain(1, "VaultMock", 0);

        /// now pause the form and try to withdraw
        _pauseFormXChain(0);

        /// try to withdraw after pause (mrperfect panicks)
        _withdrawXchain("VaultMock", 0, true);

        /// processing the queued withdrawal and assert
        vm.selectFork(FORKS[ARBI]);

        /// @dev deployer has emergency admin role
        address emergencyQueue = getContract(ARBI, "EmergencyQueue");

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 balanceBefore = MockERC20(IBaseForm(superform).getVaultAddress()).balanceOf(mrimperfect);

        assertFalse(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));
        vm.prank(deployer);
        EmergencyQueue(emergencyQueue).executeQueuedWithdrawal(1);
        assertTrue(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));

        uint256 balanceAfter = MockERC20(IBaseForm(superform).getVaultAddress()).balanceOf(mrimperfect);
        assertEq(balanceBefore + 1e18, balanceAfter);
    }

    function test_emergencyQueueProcessingXChainTimelockSpecialCase() public {
        /// user deposits successfully to a form
        _successfulDepositXChain(1, "ERC4626TimelockMock", 1);

        /// send to timelock unlock queue
        _withdrawXchain("ERC4626TimelockMock", 1, false);

        /// now pause the form
        _pauseFormXChain(1);

        /// processing the queued withdrawal and assert
        vm.selectFork(FORKS[ARBI]);
        vm.warp(block.timestamp + (86_400 * 5));

        vm.prank(deployer);
        TimelockStateRegistry(payable(getContract(ARBI, "TimelockStateRegistry"))).finalizePayload(1, bytes(""));

        assertEq(EmergencyQueue(getContract(ARBI, "EmergencyQueue")).queueCounter(), 1);

        /// @dev deployer has emergency admin role
        address emergencyQueue = getContract(ARBI, "EmergencyQueue");

        address superform = getContract(
            ARBI, string.concat("DAI", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[1]))
        );

        uint256 balanceBefore = MockERC20(IBaseForm(superform).getVaultAddress()).balanceOf(mrimperfect);

        assertFalse(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));
        vm.prank(deployer);
        EmergencyQueue(emergencyQueue).executeQueuedWithdrawal(1);
        assertTrue(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));

        uint256 balanceAfter = MockERC20(IBaseForm(superform).getVaultAddress()).balanceOf(mrimperfect);
        assertEq(balanceBefore + 1e18, balanceAfter);
    }

    function test_emergencyQueueProcessingXChainUnpause() public {
        /// user deposits successfully to a form
        _successfulDepositXChain(1, "VaultMock", 0);

        /// now pause the form and try to withdraw
        _pauseFormXChain(0);

        /// try to withdraw after pause (mrperfect panicks)
        _withdrawXchain("VaultMock", 0, true);

        _unpauseFormXChain(0);
        /// processing the queued withdrawal and assert
        vm.selectFork(FORKS[ARBI]);

        /// @dev deployer has emergency admin role
        address emergencyQueue = getContract(ARBI, "EmergencyQueue");

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 balanceBefore = MockERC20(IBaseForm(superform).getVaultAddress()).balanceOf(mrimperfect);

        assertFalse(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));
        vm.prank(deployer);
        EmergencyQueue(emergencyQueue).executeQueuedWithdrawal(1);
        assertTrue(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));

        uint256 balanceAfter = MockERC20(IBaseForm(superform).getVaultAddress()).balanceOf(mrimperfect);
        assertEq(balanceBefore + 1e18, balanceAfter);
    }

    function test_emergencyWithdraw() public {
        /// user deposits successfully to a form
        _successfulDepositXChain(1, "VaultMock", 0);

        /// processing the queued withdrawal and assert
        vm.selectFork(FORKS[ARBI]);

        /// @dev deployer has emergency admin role
        address emergencyQueue = getContract(ARBI, "EmergencyQueue");

        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        vm.prank(emergencyQueue);
        vm.expectRevert(Error.EMERGENCY_WITHDRAW_INSUFFICIENT_BALANCE.selector);
        IBaseForm(superform).emergencyWithdraw(address(0), address(0), 10e20);
    }

    function test_emergencyQueueProcessingXChainMultiVault() public {
        string[] memory vaultKinds = new string[](2);
        vaultKinds[0] = "ERC4626TimelockMock";
        vaultKinds[1] = "kycDAO4626";

        uint256[] memory formImplIds = new uint256[](2);
        formImplIds[0] = 1;
        formImplIds[1] = 2;
        /// user deposits successfully to a form
        _successfulDepositXChain(1, vaultKinds[0], formImplIds[0]);
        _successfulDepositXChain(2, vaultKinds[1], formImplIds[1]);

        /// now pause the form and try to withdraw
        _pauseFormXChain(formImplIds[0]);
        _pauseFormXChain(formImplIds[1]);

        /// try to withdraw after pause (mrperfect panicks)
        _withdrawAfterPauseXChainMulti(vaultKinds, formImplIds);

        /// processing the queued withdrawal and assert
        vm.selectFork(FORKS[ARBI]);

        /// @dev deployer has emergency admin role
        address emergencyQueue = getContract(ARBI, "EmergencyQueue");

        address superform1 = getContract(
            ARBI,
            string.concat("DAI", vaultKinds[0], "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[formImplIds[0]]))
        );

        uint256 balanceBefore = MockERC20(IBaseForm(superform1).getVaultAddress()).balanceOf(mrimperfect);

        assertFalse(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));
        assertFalse(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(2));

        uint256[] memory emergencyWithdrawIds = new uint256[](2);

        emergencyWithdrawIds[0] = 1;
        emergencyWithdrawIds[1] = 2;

        vm.prank(deployer);
        EmergencyQueue(emergencyQueue).batchExecuteQueuedWithdrawal(emergencyWithdrawIds);

        vm.prank(deployer);
        vm.expectRevert(Error.EMERGENCY_WITHDRAW_PROCESSED_ALREADY.selector);
        EmergencyQueue(emergencyQueue).executeQueuedWithdrawal(2);

        assertTrue(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));
        assertTrue(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(2));

        uint256 balanceAfter = MockERC20(IBaseForm(superform1).getVaultAddress()).balanceOf(mrimperfect);
        assertEq(balanceBefore + 0.9e18, balanceAfter);
    }

    function test_emergencyQueueProcessingXChainMultiVaultUnpause() public {
        string[] memory vaultKinds = new string[](2);
        vaultKinds[0] = "ERC4626TimelockMock";
        vaultKinds[1] = "kycDAO4626";

        uint256[] memory formImplIds = new uint256[](2);
        formImplIds[0] = 1;
        formImplIds[1] = 2;
        /// user deposits successfully to a form
        _successfulDepositXChain(1, vaultKinds[0], formImplIds[0]);
        _successfulDepositXChain(2, vaultKinds[1], formImplIds[1]);

        /// now pause the form and try to withdraw
        _pauseFormXChain(formImplIds[0]);
        _pauseFormXChain(formImplIds[1]);

        /// try to withdraw after pause (mrperfect panicks)
        _withdrawAfterPauseXChainMulti(vaultKinds, formImplIds);

        /// now pause the form and try to withdraw
        _unpauseFormXChain(formImplIds[0]);
        _unpauseFormXChain(formImplIds[1]);

        /// processing the queued withdrawal and assert
        vm.selectFork(FORKS[ARBI]);

        /// @dev deployer has emergency admin role
        address emergencyQueue = getContract(ARBI, "EmergencyQueue");

        address superform1 = getContract(
            ARBI,
            string.concat("DAI", vaultKinds[0], "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[formImplIds[0]]))
        );

        uint256 balanceBefore = MockERC20(IBaseForm(superform1).getVaultAddress()).balanceOf(mrimperfect);

        assertFalse(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));
        assertFalse(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(2));

        uint256[] memory emergencyWithdrawIds = new uint256[](2);

        emergencyWithdrawIds[0] = 1;
        emergencyWithdrawIds[1] = 2;

        vm.prank(deployer);
        EmergencyQueue(emergencyQueue).batchExecuteQueuedWithdrawal(emergencyWithdrawIds);

        vm.prank(deployer);
        vm.expectRevert(Error.EMERGENCY_WITHDRAW_PROCESSED_ALREADY.selector);
        EmergencyQueue(emergencyQueue).executeQueuedWithdrawal(2);

        assertTrue(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));
        assertTrue(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(2));

        uint256 balanceAfter = MockERC20(IBaseForm(superform1).getVaultAddress()).balanceOf(mrimperfect);
        assertEq(balanceBefore + 0.9e18, balanceAfter);
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _withdrawAfterPause() internal {
        vm.selectFork(FORKS[ETH]);
        address payable router = payable(getContract(ETH, "SuperformRouter"));
        address superPositions = getContract(ETH, "SuperPositions");

        SingleVaultSFData memory data = SingleVaultSFData(
            _getTestSuperformId(),
            1e18,
            100,
            false,
            LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0),
            "",
            mrimperfect,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        vm.prank(mrperfect);
        SuperPositions(superPositions).increaseAllowance(router, _getTestSuperformId(), 100e18);

        vm.prank(mrperfect);
        SuperformRouter(router).singleDirectSingleVaultWithdraw(req);

        assertEq(EmergencyQueue(getContract(ETH, "EmergencyQueue")).queueCounter(), 1);
    }

    function _withdrawAfterPauseMulti() internal {
        vm.selectFork(FORKS[ETH]);
        address payable router = payable(getContract(ETH, "SuperformRouter"));
        address superPositions = getContract(ETH, "SuperPositions");

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = _getTestSuperformId();
        superformIds[1] = _getTestSuperformId();

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 0.9e18;
        amounts[1] = 0.9e18;

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 100;
        maxSlippages[1] = 100;

        LiqRequest[] memory liqRequests = new LiqRequest[](2);
        liqRequests[0] = LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0);
        liqRequests[1] = liqRequests[0];

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](2), liqRequests, "", mrimperfect, "");

        SingleDirectMultiVaultStateReq memory req = SingleDirectMultiVaultStateReq(data);

        vm.prank(mrperfect);
        SuperPositions(superPositions).increaseAllowance(router, _getTestSuperformId(), 100e18);

        vm.prank(mrperfect);
        SuperformRouter(router).singleDirectMultiVaultWithdraw(req);

        assertEq(EmergencyQueue(getContract(ETH, "EmergencyQueue")).queueCounter(), 2);
    }

    function _withdrawXchain(string memory vaultKind, uint256 formImplId, bool checkForEmergency) internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);

        address superformRouter = getContract(ETH, "SuperformRouter");

        address superform = getContract(
            ARBI, string.concat("DAI", vaultKind, "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[formImplId]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[formImplId], ARBI);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId, 1e18, 1000, false, LiqRequest(1, "", address(0), ETH, 0), "", mrimperfect, ""
        );

        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        vm.prank(mrperfect);
        SuperPositions(getContract(ETH, "SuperPositions")).increaseAllowance(superformRouter, superformId, 2e18);
        vm.recordLogs();

        vm.prank(mrperfect);
        vm.deal(mrperfect, 2 ether);
        SuperformRouter(payable(superformRouter)).singleXChainSingleVaultWithdraw{ value: 2 ether }(req);

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
            address(HyperlaneMailbox), address(HyperlaneMailbox), FORKS[ARBI], logs
        );

        /// @dev update and process the payload on ARBI
        vm.selectFork(FORKS[ARBI]);

        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).processPayload(2);

        /// @dev assert emergency withdrawal added to queue on ARBI
        if (checkForEmergency) assertEq(EmergencyQueue(getContract(ARBI, "EmergencyQueue")).queueCounter(), 1);
    }

    function _withdrawAfterPauseXChainMulti(string[] memory vaultKinds, uint256[] memory formImplIds) internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);

        address superformRouter = getContract(ETH, "SuperformRouter");

        address superform1 = getContract(
            ARBI,
            string.concat("DAI", vaultKinds[0], "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[formImplIds[0]]))
        );
        address superform2 = getContract(
            ARBI,
            string.concat("DAI", vaultKinds[1], "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[formImplIds[1]]))
        );

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_IMPLEMENTATION_IDS[formImplIds[0]], ARBI);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_IMPLEMENTATION_IDS[formImplIds[1]], ARBI);

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId1;
        superformIds[1] = superformId2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 0.9e18;
        amounts[1] = 0.9e18;

        uint256[] memory slippages = new uint256[](2);
        slippages[0] = 100;
        slippages[1] = 100;

        LiqRequest[] memory liqRequests = new LiqRequest[](2);
        liqRequests[0] = LiqRequest(1, "", address(0), ETH, 0);
        liqRequests[1] = liqRequests[0];

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, slippages, new bool[](2), liqRequests, "", mrimperfect, "");

        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        vm.prank(mrperfect);
        SuperPositions(getContract(ETH, "SuperPositions")).increaseAllowance(superformRouter, superformId1, 2e18);

        vm.prank(mrperfect);
        SuperPositions(getContract(ETH, "SuperPositions")).increaseAllowance(superformRouter, superformId2, 2e18);
        vm.recordLogs();

        vm.prank(mrperfect);
        vm.deal(mrperfect, 2 ether);
        SuperformRouter(payable(superformRouter)).singleXChainMultiVaultWithdraw{ value: 2 ether }(req);

        Vm.Log[] memory logs = vm.getRecordedLogs();

        /// @dev simulate cross-chain payload delivery
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

        /// @dev update and process the payload on ARBI
        vm.selectFork(FORKS[ARBI]);

        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).processPayload(3);

        /// @dev assert emergency withdrawal added to queue on ARBI
        assertEq(EmergencyQueue(getContract(ARBI, "EmergencyQueue")).queueCounter(), 2);
    }

    function _pauseForm() internal {
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            FORM_IMPLEMENTATION_IDS[0], true, bytes("")
        );
    }

    function _pauseFormXChain(uint256 formImplId) internal {
        vm.selectFork(FORKS[ARBI]);
        vm.prank(deployer);
        SuperformFactory(getContract(ARBI, "SuperformFactory")).changeFormImplementationPauseStatus(
            FORM_IMPLEMENTATION_IDS[formImplId], true, bytes("")
        );
    }

    function _unpauseFormXChain(uint256 formImplId) internal {
        vm.selectFork(FORKS[ARBI]);
        vm.prank(deployer);
        SuperformFactory(getContract(ARBI, "SuperformFactory")).changeFormImplementationPauseStatus(
            FORM_IMPLEMENTATION_IDS[formImplId], false, bytes("")
        );
    }

    function _successfulDeposit() internal {
        vm.selectFork(FORKS[ETH]);
        address dai = getContract(ETH, "DAI");

        vm.prank(deployer);
        MockERC20(dai).transfer(mrperfect, 2e18);

        vm.startPrank(mrperfect);

        address superformRouter = getContract(ETH, "SuperformRouter");
        uint256 superformId = _getTestSuperformId();

        SingleVaultSFData memory data =
            SingleVaultSFData(superformId, 2e18, 100, false, LiqRequest(1, "", dai, 1, 0), "", mrperfect, "");

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        /// @dev approves before call
        MockERC20(dai).approve(address(superformRouter), 2e18);

        SuperformRouter(payable(superformRouter)).singleDirectSingleVaultDeposit(req);
        vm.stopPrank();
    }

    function _successfulDepositXChain(uint256 payloadId, string memory vaultKind, uint256 formImplId) internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);

        vm.prank(deployer);
        MockERC20(getContract(ETH, "DAI")).transfer(mrperfect, 2e18);

        address superformRouter = getContract(ETH, "SuperformRouter");

        address superform = getContract(
            ARBI, string.concat("DAI", vaultKind, "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[formImplId]))
        );

        vm.selectFork(FORKS[ARBI]);

        KYCDaoNFTMock(getContract(ARBI, "KYCDAOMock")).mint(mrperfect);
        vm.selectFork(FORKS[ETH]);

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[formImplId], ARBI);

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
            2e18,
            false,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1
        );

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            2e18,
            1000,
            false,
            LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), ARBI, 0),
            "",
            mrimperfect,
            ""
        );

        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 1;
        ambIds[1] = 2;

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ARBI, data);

        /// @dev approves before call
        vm.prank(mrperfect);
        MockERC20(getContract(ETH, "DAI")).approve(superformRouter, 2e18);
        vm.recordLogs();

        vm.prank(mrperfect);
        vm.deal(mrperfect, 2 ether);
        SuperformRouter(payable(superformRouter)).singleXChainSingleVaultDeposit{ value: 2 ether }(req);

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
            address(HyperlaneMailbox), address(HyperlaneMailbox), FORKS[ARBI], logs
        );

        /// @dev update and process the payload on ARBI
        vm.selectFork(FORKS[ARBI]);
        vm.prank(deployer);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 2e18;

        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).updateDepositPayload(payloadId, amounts);

        uint256 nativeAmount = PaymentHelper(getContract(ARBI, "PaymentHelper")).estimateAckCost(1);

        vm.recordLogs();
        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(ARBI, "CoreStateRegistry"))).processPayload{ value: nativeAmount }(
            payloadId
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
            address(HyperlaneMailbox), address(HyperlaneMailbox), FORKS[ETH], logs
        );

        /// @dev mint super positions on source chain
        vm.selectFork(FORKS[ETH]);
        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(ETH, "CoreStateRegistry"))).processPayload(payloadId);
    }

    function _getTestSuperformId() internal view returns (uint256) {
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        return DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);
    }

    function _getTestSuperformIdXChain() internal view returns (uint256) {
        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        return DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "test/utils/ProtocolActions.sol";

contract EmergencyQueueTest is ProtocolActions {
    /// our intended user who is a nice person
    address mrperfect;

    /// our users who is not a nice person
    address mrimperfect;

    function setUp() public override {
        super.setUp();
        mrperfect = vm.addr(421);
    }

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

        uint256 balanceBefore = MockERC20(IBaseForm(superform).getVaultAddress()).balanceOf(mrperfect);

        assertFalse(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));
        vm.prank(deployer);
        EmergencyQueue(emergencyQueue).executeQueuedWithdrawal(1);
        assertTrue(EmergencyQueue(emergencyQueue).queuedWithdrawalStatus(1));

        uint256 balanceAfter = MockERC20(IBaseForm(superform).getVaultAddress()).balanceOf(mrperfect);
        assertEq(balanceBefore + 1e18, balanceAfter);
    }

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
            mrperfect,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        vm.prank(mrperfect);
        SuperPositions(superPositions).increaseAllowance(router, _getTestSuperformId(), 100e18);

        vm.prank(mrperfect);
        SuperformRouter(router).singleDirectSingleVaultWithdraw(req);

        assertEq(EmergencyQueue(getContract(ETH, "EmergencyQueue")).queueCounter(), 1);
    }

    function _pauseForm() internal {
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            FORM_IMPLEMENTATION_IDS[0], true, bytes("")
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

    function _getTestSuperformId() internal view returns (uint256) {
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        return DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);
    }
}

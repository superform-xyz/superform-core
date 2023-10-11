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

    function test_emergencyQueue() public {
        vm.selectFork(FORKS[ETH]);
        address payable router = payable(getContract(ETH, "SuperformRouter"));
        address superPositions = getContract(ETH, "SuperPositions");

        /// deal some super positions to our perfect user
        vm.prank(router);
        SuperPositions(superPositions).mintSingle(mrperfect, _getTestSuperformId(), 100e18);

        /// pause the form
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            FORM_IMPLEMENTATION_IDS[0], true, bytes("")
        );

        /// try to withdraw
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

    function _getTestSuperformId() internal view returns (uint256) {
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        return DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);
    }
}

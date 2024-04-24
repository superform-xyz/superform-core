// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { RewardsDistributorHandler } from "./handlers/RewardsDistributorHandler.sol";
import { RewardsDistributorStore } from "./stores/RewardsDistributorStore.sol";
import { BaseInvariantTest } from "../common/Base.invariant.t.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";

abstract contract RewardsDistributorBase is BaseInvariantTest {
    RewardsDistributorStore internal rewardsDistributorStore;
    RewardsDistributorHandler internal rewardsDistributorHandler;

    function setUp() public virtual override {
        super.setUp();
        (address[][] memory coreAddresses,,,, uint256[] memory forksArray) = _grabStateForHandler();

        /// @dev set fork back to OP to create a store and a handler (which will be shared by all forks)
        vm.selectFork(FORKS[OP]);
        rewardsDistributorStore = new RewardsDistributorStore();

        rewardsDistributorHandler =
            new RewardsDistributorHandler(chainIds, contractNames, coreAddresses, forksArray, rewardsDistributorStore);

        vm.label({ account: address(rewardsDistributorStore), newLabel: "RewardsDistributorStore" });
        vm.label({ account: address(rewardsDistributorHandler), newLabel: "RewardsDistributorHandler" });
        targetContract(address(rewardsDistributorHandler));
    }

    /*///////////////////////////////////////////////////////////////
                    INVARIANT TESTS
    //////////////////////////////////////////////////////////////*/

    /// forge-config: localdev.invariant.runs = 25
    /// forge-config: localdev.invariant.depth = 2
    /// forge-config: localdev.invariant.fail-on-revert = true
    function invariant_tokenBalances() public {
        string memory path = "output.txt";
        vm.writeLine(path, string.concat("--Invariant asserts--"));

        vm.selectFork(FORKS[OP]);
        for (uint256 i; i < 3; i++) {
            vm.writeLine(path, string.concat("Stats for period id: ", Strings.toString(i)));

            uint256 totalSelectedUsers = rewardsDistributorStore.totalSelectedUsersPeriod(i);
            uint256 testUsers = rewardsDistributorStore.totalTestUsersPeriod(i);
            vm.writeLine(path, string.concat("total users claimed: ", Strings.toString(totalSelectedUsers)));
            vm.writeLine(path, string.concat("total test users claimed: ", Strings.toString(testUsers)));

            assertEq(totalSelectedUsers, testUsers);
        }

        uint256 usdcBalanceAfter = rewardsDistributorStore.usdcBalanceAfter();
        uint256 daiBalanceAfter = rewardsDistributorStore.daiBalanceAfter();
        vm.writeLine(path, string.concat("usdcBalanceAfter: ", Strings.toString(usdcBalanceAfter)));
        vm.writeLine(path, string.concat("daiBalanceAfter: ", Strings.toString(daiBalanceAfter)));
        assertEq(usdcBalanceAfter, 0);
        assertEq(daiBalanceAfter, 0);

        vm.writeLine(path, string.concat("--Run end--"));
    }
}

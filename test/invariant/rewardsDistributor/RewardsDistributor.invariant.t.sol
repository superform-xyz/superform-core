// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { RewardsDistributorHandler } from "./handlers/RewardsDistributorHandler.sol";
import { RewardsDistributorStore } from "./stores/RewardsDistributorStore.sol";
import { BaseInvariantTest } from "../common/Base.invariant.t.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract RewardsDistributor is BaseInvariantTest {
    RewardsDistributorStore internal rewardsDistributorStore;
    RewardsDistributorHandler internal rewardsDistributorHandler;

    function setUp() public override {
        super.setUp();
        (address[][] memory coreAddresses,,,, uint256[] memory forksArray) = _grabStateForHandler();

        /// @dev set fork back to OP to create a store and a handler (which will be shared by all forks)
        vm.selectFork(FORKS[OP]);
        rewardsDistributorStore = new RewardsDistributorStore();

        rewardsDistributorHandler =
            new RewardsDistributorHandler(chainIds, contractNames, coreAddresses, forksArray, rewardsDistributorStore);

        vm.label({ account: address(rewardsDistributorStore), newLabel: "RewardsDistributorStore" });
        vm.label({ account: address(rewardsDistributorHandler), newLabel: "RewardsDistributorHandler" });

        /// @dev Note: disable some of the selectors to test a bunch of them only
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = RewardsDistributorHandler.full_claim.selector;
        selectors[1] = RewardsDistributorHandler.full_batch_claim.selector;
        targetSelector(FuzzSelector({ addr: address(rewardsDistributorHandler), selectors: selectors }));
        targetContract(address(rewardsDistributorHandler));
    }

    /*///////////////////////////////////////////////////////////////
                    INVARIANT TESTS
    //////////////////////////////////////////////////////////////*/

    /// forge-config: localdev.invariant.runs = 50
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

            assertEq(totalSelectedUsers, testUsers);
        }

        uint256 usdcBalanceAfter = rewardsDistributorStore.usdcBalanceAfter();
        uint256 daiBalanceAfter = rewardsDistributorStore.daiBalanceAfter();

        assertEq(usdcBalanceAfter, 0);
        assertEq(daiBalanceAfter, 0);

        vm.writeLine(path, string.concat("--Run end--"));
    }
}

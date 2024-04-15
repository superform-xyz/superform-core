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
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = RewardsDistributorHandler.full_claim.selector;
        targetSelector(FuzzSelector({ addr: address(rewardsDistributorHandler), selectors: selectors }));
        targetContract(address(rewardsDistributorHandler));
    }

    /*///////////////////////////////////////////////////////////////
                    INVARIANT TESTS
    //////////////////////////////////////////////////////////////*/

    /// forge-config: localdev.invariant.runs = 25
    /// forge-config: localdev.invariant.depth = 1
    /// forge-config: localdev.invariant.fail-on-revert = false
    function invariant_tokenBalances() public {
        string memory path = "output.txt";
        vm.writeLine(path, string.concat("--Run end--"));

        vm.selectFork(FORKS[OP]);
        uint256 usdcBalanceAfter = rewardsDistributorStore.usdcBalanceAfter();
        uint256 daiBalanceAfter = rewardsDistributorStore.daiBalanceAfter();
        uint256 totalSelectedUsers = rewardsDistributorStore.totalSelectedUsers();
        uint256 testUsers = rewardsDistributorStore.totalTestUsers();
        vm.writeLine(path, string.concat("stored total users: ", Strings.toString(totalSelectedUsers)));
        vm.writeLine(path, string.concat("usdc balance: ", Strings.toString(usdcBalanceAfter)));
        vm.writeLine(path, string.concat("dai balance: ", Strings.toString(daiBalanceAfter)));
        assertEq(usdcBalanceAfter, 0);
        assertEq(daiBalanceAfter, 0);
        assertEq(totalSelectedUsers, testUsers);
    }
}

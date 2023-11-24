// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { VaultSharesHandler } from "./handlers/VaultSharesHandler.sol";
import { VaultSharesStore } from "./stores/VaultSharesStore.sol";
import { BaseInvariantTest } from "./Base.invariant.t.sol";

contract VaultSharesInvariantTest is BaseInvariantTest {
    VaultSharesStore internal vaultSharesStore;
    VaultSharesHandler internal vaultSharesHandler;

    function setUp() public override {
        super.setUp();
        (
            address[][] memory coreAddresses,
            address[][] memory underlyingAddresses,
            address[][][] memory vaultAddresses,
            address[][][] memory superformAddresses,
            uint256[] memory forksArray
        ) = _grabStateForHandler();

        /// @dev set fork back to id 0 to create a store and a handler (which will be shared by all forks)
        vm.selectFork(FORKS[0]);
        vaultSharesStore = new VaultSharesStore();

        vaultSharesHandler =
        new VaultSharesHandler(chainIds, contractNames, coreAddresses, underlyingAddresses, vaultAddresses,
        superformAddresses, forksArray, vaultSharesStore, timestampStore);

        vm.label({ account: address(vaultSharesStore), newLabel: "VaultSharesStore" });
        vm.label({ account: address(vaultSharesHandler), newLabel: "VaultSharesHandler" });

        /// @dev Note: disable some of the selectors to test a bunch of them only
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = VaultSharesHandler.singleXChainSingleVaultDeposit.selector;
        selectors[1] = VaultSharesHandler.singleDirectSingleVaultDeposit.selector;
        targetSelector(FuzzSelector({ addr: address(vaultSharesHandler), selectors: selectors }));
        targetContract(address(vaultSharesHandler));
        targetSender(users[0]);
    }

    /*///////////////////////////////////////////////////////////////
                    INVARIANT TESTS
    //////////////////////////////////////////////////////////////*/

    function invariant_vaultShares() public {
        assertEq(vaultSharesStore.superPositionsSum(), vaultSharesStore.vaultShares());
    }
}

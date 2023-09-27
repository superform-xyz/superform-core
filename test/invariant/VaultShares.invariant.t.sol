/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "../utils/ProtocolActions.sol";

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

        vm.selectFork(FORKS[0]);
        vaultSharesStore = new VaultSharesStore();

        vaultSharesHandler =
        new VaultSharesHandler(chainIds, contractNames, coreAddresses, underlyingAddresses, vaultAddresses,
        superformAddresses, forksArray, vaultSharesStore, timestampStore);

        vm.label({ account: address(vaultSharesStore), newLabel: "VaultSharesStore" });
        vm.label({ account: address(vaultSharesHandler), newLabel: "VaultSharesHandler" });

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = VaultSharesHandler.singleDirectSingleVaultDeposit.selector;
        //selectors[1] = VaultSharesHandler.singleDirectSingleVaultWithdraw.selector;
        //selectors[2] = VaultSharesHandler.singleXChainRescueFailedDeposit.selector;

        targetSelector(FuzzSelector({ addr: address(vaultSharesHandler), selectors: selectors }));
        targetContract(address(vaultSharesHandler));

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(vaultSharesStore));
        excludeSender(address(vaultSharesHandler));
    }

    /*///////////////////////////////////////////////////////////////
                    INVARIANT TESTS
    //////////////////////////////////////////////////////////////*/

    function invariant_vaultShares() public useCurrentTimestamp {
        assertEq(vaultSharesStore.superPositionsSum(), vaultSharesStore.vaultShares());
    }
}

/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "../utils/ProtocolActions.sol";

import { VaultSharesHandler } from "./handlers/VaultSharesHandler.sol";

import { VaultSharesStore } from "./stores/VaultSharesStore.sol";
import { BaseInvariantTest } from "./Base.invariant.t.sol";

contract VaultSharesInvariantTest is BaseInvariantTest {
    VaultSharesHandler internal vaultSharesHandler;
    VaultSharesStore internal vaultSharesStore;

    function setUp() public override {
        BaseInvariantTest.setUp();
        vaultSharesStore = new VaultSharesStore();
        vaultSharesHandler =
        new VaultSharesHandler(chainIds, contractNames, coreAddresses, underlyingAddresses, vaultAddresses, superformAddresses, forksArray, vaultSharesStore, timestampStore);

        vm.label({ account: address(vaultSharesStore), newLabel: "VaultSharesStore" });
        vm.label({ account: address(vaultSharesHandler), newLabel: "VaultSharesHandler" });

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = VaultSharesHandler.singleDirectSingleVaultDeposit.selector;
        //selectors[1] = VaultSharesHandler.singleDirectSingleVaultWithdraw.selector;
        //selectors[2] = VaultSharesHandler.singleXChainRescueFailedDeposit.selector;

        targetSelector(FuzzSelector({ addr: address(vaultSharesHandler), selectors: selectors }));
        targetContract(address(vaultSharesHandler));

        console.log("vaultSharesstore ", address(vaultSharesStore));

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(vaultSharesStore));
        excludeSender(address(vaultSharesHandler));
    }

    /*///////////////////////////////////////////////////////////////
                    INVARIANT TESTS
    //////////////////////////////////////////////////////////////*/

    function invariant_vaultShares() public useCurrentTimestamp {
        console.log("vaultSharesstore ", address(vaultSharesStore));

        assertEq(vaultSharesStore.superPositionsSum(), vaultSharesStore.vaultShares());
    }
}

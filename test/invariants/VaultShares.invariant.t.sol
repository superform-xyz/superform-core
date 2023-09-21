/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import "../utils/ProtocolActions.sol";
import "./handlers/VaultSharesHandler.sol";
import "forge-std/Test.sol";

contract VaultShares is Test, ProtocolActions {
    VaultSharesHandler public handler;

    function setUp() public override {
        handler = new VaultSharesHandler();

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = VaultSharesHandler.singleDirectSingleVaultDeposit.selector;
        selectors[1] = VaultSharesHandler.singleDirectSingleVaultWithdraw.selector;

        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
        targetContract(address(handler));
    }

    function invariant_vaultShares() public returns (bool) {
        return true;
    }
}

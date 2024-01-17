// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import { Test } from "forge-std/Test.sol";
import { VaultClaimer } from "src/VaultClaimer.sol";

contract VaultClaimerTest is Test {
    string public constant TEST_PROTOCOL_ID = "vault_420";
    address public constant CLAIMER = address(69);

    VaultClaimer public vaultClaimer;

    // test event
    event Claimed(address indexed claimer, string protocolId);

    /// test error case
    error AlreadyClaimed();

    function setUp() public {
        vaultClaimer = new VaultClaimer();
    }

    // case: successful claiming of TEST_PROTOCOL_ADMIN
    function test_successfulClaim() public {
        vm.prank(CLAIMER);

        vm.expectEmit(true, true, true, true);
        emit Claimed(CLAIMER, TEST_PROTOCOL_ID);

        vaultClaimer.claimProtocolOwnership(TEST_PROTOCOL_ID);
    }

    /// case: duplicate claiming of TEST_PROTOCOL_ADMIN
    function test_duplicateClaim() public {
        vm.prank(CLAIMER);
        vaultClaimer.claimProtocolOwnership(TEST_PROTOCOL_ID);

        vm.prank(CLAIMER);

        vm.expectEmit(true, true, true, true);
        emit Claimed(CLAIMER, TEST_PROTOCOL_ID);

        vaultClaimer.claimProtocolOwnership(TEST_PROTOCOL_ID);
    }
}

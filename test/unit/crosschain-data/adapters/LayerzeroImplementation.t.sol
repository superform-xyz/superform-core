// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "../../../utils/BaseSetup.sol";

import { AMBMessage } from "src/types/DataTypes.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { LayerzeroImplementation } from "src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol";
import { Error } from "src/libraries/Error.sol";

contract LayerzeroImplementationUnitTest is BaseSetup {
    ISuperRegistry public superRegistry;
    LayerzeroImplementation layerzeroImplementation;
    address public bond;
    bytes public srcAddressOP;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRegistry = ISuperRegistry(getContract(ETH, "SuperRegistry"));
        layerzeroImplementation = LayerzeroImplementation(payable(superRegistry.getAmbAddress(1)));

        srcAddressOP =
            abi.encodePacked(getContract(ETH, "LayerzeroImplementation"), getContract(OP, "LayerzeroImplementation"));

        /// @dev malicious caller
        bond = address(7);
        /// @dev (who's a brokie)
        vm.deal(bond, 1 ether);
    }

    function test_isTrustedRemote_InvalidChainId() public {
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        layerzeroImplementation.isTrustedRemote(0, bytes("hello"));
    }

    function test_layerzeroDispatchPayload_InvalidChainId() public {
        vm.prank(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        layerzeroImplementation.dispatchPayload(deployer, 420, bytes("hi test"), "");
    }

    function test_lzReceive_InvalidChainId() public {
        vm.prank(deployer);
        layerzeroImplementation.setTrustedRemote(0, bytes("test"));

        vm.prank(address(layerzeroImplementation.lzEndpoint()));
        AMBMessage memory ambMessage;
        ambMessage.txInfo = DataLib.packTxInfo(0, 0, 0, 1, address(0), 0);

        layerzeroImplementation.lzReceive(0, bytes("test"), 420, abi.encode(ambMessage));
        assertGt(layerzeroImplementation.failedMessages(0, bytes("test"), 420).length, 0);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "../../../utils/BaseSetup.sol";

import { AMBMessage } from "src/types/DataTypes.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { LayerzeroImplementation } from "src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol";
import { Error } from "src/libraries/Error.sol";
import { ProofLib } from "src/libraries/ProofLib.sol";
import { IAmbImplementationV2 } from "src/interfaces/IAmbImplementationV2.sol";

contract LayerzeroImplementationUnitTest is BaseSetup {
    ISuperRegistry public superRegistry;
    LayerzeroImplementation layerzeroImplementation;
    address public bond;
    bytes public srcAddressOP;

    using ProofLib for bytes;

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

    function test_layerzeroDispatchPayload_InvalidChainId2() public {
        vm.prank(deployer);
        layerzeroImplementation.setTrustedRemote(111, bytes(""));

        vm.prank(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        layerzeroImplementation.dispatchPayload(deployer, 10, bytes("hi test"), "");
    }

    function test_lzReceive_InvalidChainId() public {
        vm.prank(deployer);
        layerzeroImplementation.setTrustedRemote(0, bytes("test"));

        vm.prank(address(layerzeroImplementation.lzEndpoint()));
        AMBMessage memory ambMessage;
        ambMessage.txInfo = DataLib.packTxInfo(0, 0, 0, 1, address(0), 0);

        uint8[] memory ambIds = new uint8[](1);
        ambMessage.params = abi.encode(ambIds, bytes(""));

        layerzeroImplementation.lzReceive(0, bytes("test"), 420, abi.encode(ambMessage));
        assertGt(layerzeroImplementation.failedMessages(0, bytes("test"), 420).length, 0);
    }

    function test_revert_LzReceiveMaliciousDelivery() public {
        vm.selectFork(FORKS[ETH]);
        bytes memory trustedRemote = layerzeroImplementation.trustedRemoteLookup(106);

        vm.prank(address(layerzeroImplementation.lzEndpoint()));

        uint8[] memory ambIds = new uint8[](1);

        AMBMessage memory ambMessage;
        ambMessage.txInfo = DataLib.packTxInfo(0, 0, 0, 1, address(0), 0);
        ambMessage.params = abi.encode(ambIds, bytes(""));

        layerzeroImplementation.lzReceive(106, trustedRemote, 420, abi.encode(ambMessage));

        AMBMessage memory proofAmbMessage;
        proofAmbMessage.txInfo = DataLib.packTxInfo(0, 0, 0, 1, address(0), 0);
        proofAmbMessage.params = bytes("");

        proofAmbMessage.params = abi.encode(proofAmbMessage).computeProofBytes();

        bytes memory proofEncoded = abi.encode(proofAmbMessage);

        vm.prank(address(layerzeroImplementation.lzEndpoint()));
        vm.expectRevert(IAmbImplementationV2.MALICIOUS_DELIVERY.selector);
        layerzeroImplementation.lzReceive(106, trustedRemote, 420, proofEncoded);
    }
}

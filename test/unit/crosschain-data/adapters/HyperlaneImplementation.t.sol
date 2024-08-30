// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "../../../utils/BaseSetup.sol";

import { DataLib } from "src/libraries/DataLib.sol";
import { ProofLib } from "src/libraries/ProofLib.sol";
import { IAmbImplementationV2 } from "src/interfaces/IAmbImplementationV2.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { HyperlaneImplementation } from "src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol";
import { Error } from "src/libraries/Error.sol";

contract HyperlaneImplementationUnitTest is BaseSetup {
    using ProofLib for AMBMessage;

    HyperlaneImplementation hyperlaneImplementation;

    function setUp() public override {
        super.setUp();

        ISuperRegistry superRegistry = ISuperRegistry(getContract(ETH, "SuperRegistry"));

        vm.selectFork(FORKS[ETH]);
        hyperlaneImplementation = HyperlaneImplementation(payable(superRegistry.getAmbAddress(2)));
    }

    function test_setHyperlaneConfig_ZERO_ADDRESS() public {
        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        hyperlaneImplementation.setHyperlaneConfig(IMailbox(address(0)), IInterchainGasPaymaster(address(420)));

        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        hyperlaneImplementation.setHyperlaneConfig(IMailbox(address(420)), IInterchainGasPaymaster(address(0)));
    }

    function test_handle_ambProtect() public {
        uint32 origin = 137;
        bytes32 sender = bytes32(uint256(uint160(address(hyperlaneImplementation))));

        AMBMessage memory ambMessage = AMBMessage(
            DataLib.packTxInfo(uint8(TransactionType.DEPOSIT), uint8(CallbackType.INIT), 0, 1, deployer, ETH),
            abi.encode(new uint8[](0), "")
        );

        bytes32 proof = AMBMessage(ambMessage.txInfo, "").computeProof();

        vm.prank(address(hyperlaneImplementation.mailbox()));
        hyperlaneImplementation.handle(origin, sender, abi.encode(ambMessage));

        // Test with proof in params
        AMBMessage memory ambMessageWithProof = AMBMessage(
            DataLib.packTxInfo(uint8(TransactionType.DEPOSIT), uint8(CallbackType.INIT), 0, 1, deployer, ETH),
            abi.encode(proof)
        );

        vm.prank(address(hyperlaneImplementation.mailbox()));
        vm.expectRevert(IAmbImplementationV2.MALICIOUS_DELIVERY.selector);
        hyperlaneImplementation.handle(origin, sender, abi.encode(ambMessageWithProof));
    }
}

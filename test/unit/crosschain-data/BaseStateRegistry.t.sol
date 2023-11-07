// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import "test/utils/BaseSetup.sol";
import { AMBMessage } from "src/types/DataTypes.sol";
import { CoreStateRegistry } from "src/crosschain-data/extensions/CoreStateRegistry.sol";
import { Error } from "src/utils/Error.sol";
import { IQuorumManager } from "src/interfaces/IQuorumManager.sol";

contract BaseStateRegistryTest is BaseSetup {
    CoreStateRegistry public coreStateRegistry;
    address public bond;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        coreStateRegistry = CoreStateRegistry(payable(getContract(ETH, "CoreStateRegistry")));

        /// @dev malicious caller
        bond = address(7);
        /// @dev (who's a brokie)
        vm.deal(bond, 1 ether);
    }

    function test_callingReceivePayloadDirectly() public {
        vm.expectRevert(Error.NOT_AMB_IMPLEMENTATION.selector);
        coreStateRegistry.receivePayload(ARBI, abi.encode(542));
    }

    function test_callDispatchUsingInvalidAmbId() public {
        vm.selectFork(FORKS[ETH]);

        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 9;
        ambIds_[1] = 10;

        uint256[] memory gasPerAMB = new uint256[](2);
        bytes[] memory extraDataPerAMB = new bytes[](2);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        vm.prank(getContract(ETH, "SuperformRouter"));
        coreStateRegistry.dispatchPayload(
            bond,
            ambIds_,
            ARBI,
            abi.encode(AMBMessage(type(uint256).max, abi.encode(420))),
            abi.encode(AMBExtraData(gasPerAMB, extraDataPerAMB))
        );
    }

    function test_callDispatchUsingInvalidProofAmbId() public {
        vm.selectFork(FORKS[ETH]);

        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 2;
        ambIds_[1] = 2;

        uint256[] memory gasPerAMB = new uint256[](2);
        gasPerAMB[0] = 1 ether;
        gasPerAMB[1] = 1 ether;

        bytes[] memory extraDataPerAMB = new bytes[](2);

        vm.expectRevert(Error.INVALID_PROOF_BRIDGE_ID.selector);
        vm.prank(getContract(ETH, "SuperformRouter"));
        vm.deal(getContract(ETH, "SuperformRouter"), 2 ether);

        coreStateRegistry.dispatchPayload{ value: 2 ether }(
            bond,
            ambIds_,
            ARBI,
            abi.encode(AMBMessage(420, bytes("whatif"))),
            abi.encode(AMBExtraData(gasPerAMB, extraDataPerAMB))
        );

        ambIds_[1] = 9;
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        vm.prank(getContract(ETH, "SuperformRouter"));
        vm.deal(getContract(ETH, "SuperformRouter"), 2 ether);

        coreStateRegistry.dispatchPayload{ value: 2 ether }(
            bond,
            ambIds_,
            ARBI,
            abi.encode(AMBMessage(420, bytes("whatif"))),
            abi.encode(AMBExtraData(gasPerAMB, extraDataPerAMB))
        );
    }

    function test_callDispatch_ZeroAmbLength() public {
        vm.selectFork(FORKS[ETH]);

        uint8[] memory ambIds_;

        uint256[] memory gasPerAMB = new uint256[](2);
        gasPerAMB[0] = 1 ether;
        gasPerAMB[1] = 1 ether;

        bytes[] memory extraDataPerAMB = new bytes[](2);

        vm.expectRevert(Error.ZERO_AMB_ID_LENGTH.selector);
        vm.prank(getContract(ETH, "SuperformRouter"));
        vm.deal(getContract(ETH, "SuperformRouter"), 2 ether);

        coreStateRegistry.dispatchPayload{ value: 2 ether }(
            bond,
            ambIds_,
            ARBI,
            abi.encode(AMBMessage(420, bytes("whatif"))),
            abi.encode(AMBExtraData(gasPerAMB, extraDataPerAMB))
        );
    }

    function test_callDispatch_InsufficientQuorum() public {
        vm.selectFork(FORKS[ETH]);

        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;

        uint256[] memory gasPerAMB = new uint256[](2);
        gasPerAMB[0] = 1 ether;
        gasPerAMB[1] = 1 ether;

        bytes[] memory extraDataPerAMB = new bytes[](2);

        vm.prank(getContract(ETH, "SuperformRouter"));
        vm.deal(getContract(ETH, "SuperformRouter"), 2 ether);
        vm.mockCall(
            getContract(ETH, "SuperRegistry"),
            abi.encodeWithSelector(
                IQuorumManager(getContract(ETH, "SuperRegistry")).getRequiredMessagingQuorum.selector, ARBI
            ),
            abi.encode(2)
        );

        vm.expectRevert(Error.INSUFFICIENT_QUORUM.selector);
        coreStateRegistry.dispatchPayload{ value: 2 ether }(
            bond,
            ambIds_,
            ARBI,
            abi.encode(AMBMessage(420, bytes("whatif"))),
            abi.encode(AMBExtraData(gasPerAMB, extraDataPerAMB))
        );
        vm.clearMockedCalls();
    }

    function test_readPayloadFromStateRegistry() public {
        vm.selectFork(FORKS[ETH]);

        bytes memory payload = _payload(address(coreStateRegistry), ETH, type(uint256).max);
        assertEq(payload, bytes(""));
    }
}

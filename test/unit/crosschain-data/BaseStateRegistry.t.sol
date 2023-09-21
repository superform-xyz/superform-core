// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "test/utils/BaseSetup.sol";
import { TransactionType, CallbackType, AMBMessage } from "src/types/DataTypes.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { CoreStateRegistry } from "src/crosschain-data/extensions/CoreStateRegistry.sol";
import { Error } from "src/utils/Error.sol";

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

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 9;

        uint256[] memory gasPerAMB = new uint256[](1);
        bytes[] memory extraDataPerAMB = new bytes[](1);

        vm.expectRevert(Error.INVALID_BRIDGE_ID.selector);
        vm.prank(getContract(ETH, "SuperformRouter"));
        coreStateRegistry.dispatchPayload(
            bond, ambIds, ARBI, abi.encode(420), abi.encode(AMBExtraData(gasPerAMB, extraDataPerAMB))
        );
    }

    function test_callDispatchUsingInvalidProofAmbId() public {
        vm.selectFork(FORKS[ETH]);

        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 2;
        ambIds[1] = 2;

        uint256[] memory gasPerAMB = new uint256[](2);
        gasPerAMB[0] = 1 wei;
        gasPerAMB[1] = 1 wei;

        bytes[] memory extraDataPerAMB = new bytes[](2);

        vm.expectRevert(Error.INVALID_PROOF_BRIDGE_ID.selector);
        vm.prank(getContract(ETH, "SuperformRouter"));
        vm.deal(getContract(ETH, "SuperformRouter"), 2 wei);

        coreStateRegistry.dispatchPayload{ value: 2 wei }(
            bond,
            ambIds,
            ARBI,
            abi.encode(AMBMessage(420, bytes("whatif"))),
            abi.encode(AMBExtraData(gasPerAMB, extraDataPerAMB))
        );

        ambIds[1] = 9;
        vm.expectRevert(Error.INVALID_BRIDGE_ID.selector);
        vm.prank(getContract(ETH, "SuperformRouter"));
        vm.deal(getContract(ETH, "SuperformRouter"), 2 wei);

        coreStateRegistry.dispatchPayload{ value: 2 wei }(
            bond,
            ambIds,
            ARBI,
            abi.encode(AMBMessage(420, bytes("whatif"))),
            abi.encode(AMBExtraData(gasPerAMB, extraDataPerAMB))
        );
    }

    function test_readPayloadFromStateRegistry() public {
        vm.selectFork(FORKS[ETH]);

        bytes memory payload = _payload(address(coreStateRegistry), ETH, type(uint256).max);
        assertEq(payload, bytes(""));
    }
}

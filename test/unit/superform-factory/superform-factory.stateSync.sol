// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/ProtocolActions.sol";
import { Error } from "src/libraries/Error.sol";

contract SuperformFactoryStateSyncTest is BaseSetup {
    function setUp() public override {
        super.setUp();
    }

    function test_formImplementationStatusBroadcast() public {
        /// pausing form form id 1 from ETH
        uint32 formImplementationId = 1;

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        vm.recordLogs();
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            formImplementationId, ISuperformFactory.PauseStatus.PAUSED, generateBroadcastParams(5, 1)
        );

        _broadcastPayloadHelper(ETH, vm.getRecordedLogs());

        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] != ETH) {
                vm.selectFork(FORKS[chainIds[i]]);

                bool statusBefore = SuperformFactory(getContract(chainIds[i], "SuperformFactory"))
                    .isFormImplementationPaused(formImplementationId);

                vm.expectRevert(Error.NOT_BROADCAST_REGISTRY.selector);
                bytes memory data_ = hex"ffff";
                SuperformFactory(getContract(chainIds[i], "SuperformFactory")).stateSyncBroadcast(data_);

                BroadcastRegistry(payable(getContract(chainIds[i], "BroadcastRegistry"))).processPayload(1);
                bool statusAfter = SuperformFactory(getContract(chainIds[i], "SuperformFactory"))
                    .isFormImplementationPaused(formImplementationId);

                /// @dev assert status update before and after processing the payload
                assertEq(statusBefore, false);
                assertEq(statusAfter, true);
            }
        }

        /// try processing the same payload again
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] != ETH) {
                vm.selectFork(FORKS[chainIds[i]]);

                vm.expectRevert(Error.PAYLOAD_ALREADY_PROCESSED.selector);
                BroadcastRegistry(payable(getContract(chainIds[i], "BroadcastRegistry"))).processPayload(1);
            }
        }

        /// try processing not available payload id
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] != ETH) {
                vm.selectFork(FORKS[chainIds[i]]);

                vm.expectRevert(Error.INVALID_PAYLOAD_ID.selector);
                BroadcastRegistry(payable(getContract(chainIds[i], "BroadcastRegistry"))).processPayload(2);
            }
        }

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// @dev checks if proof for this next one is diff
        vm.recordLogs();
        SuperformFactory(getContract(ETH, "SuperformFactory")).changeFormImplementationPauseStatus(
            formImplementationId, ISuperformFactory.PauseStatus.PAUSED, generateBroadcastParams(5, 1)
        );

        _broadcastPayloadHelper(ETH, vm.getRecordedLogs());
    }

    function test_revert_stateSync_invalidFormId() public {
        /// pausing random form form id
        uint32 formImplementationId = 4_000_000_000;
        vm.selectFork(FORKS[ETH]);

        bytes32 SYNC_IMPLEMENTATION_STATUS = keccak256("SYNC_IMPLEMENTATION_STATUS");
        bytes memory extraData = hex"ffff";

        BroadcastMessage memory factoryPayload = BroadcastMessage(
            "SUPERFORM_FACTORY", SYNC_IMPLEMENTATION_STATUS, abi.encode(ETH, 1, formImplementationId, false)
        );

        vm.expectRevert(Error.INVALID_FORM_ID.selector);
        vm.prank(getContract(ETH, "BroadcastRegistry"));
        SuperformFactory(getContract(ETH, "SuperformFactory")).stateSyncBroadcast(abi.encode(factoryPayload, extraData));
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "test/utils/BaseSetup.sol";
import "test/utils/Utilities.sol";

import { BroadcastRegistry } from "src/crosschain-data/BroadcastRegistry.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { SuperRBAC } from "src/settings/SuperRBAC.sol";

import { Error } from "src/utils/Error.sol";

contract SuperRBACTest is BaseSetup {
    SuperRBAC public superRBAC;
    ISuperRegistry public superRegistry;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRBAC = SuperRBAC(getContract(ETH, "SuperRBAC"));
        superRegistry = ISuperRegistry(getContract(ETH, "SuperRegistry"));
    }

    function test_setSuperRegistry() public {
        vm.prank(deployer);
        superRBAC.setSuperRegistry(address(0x1));
        assertEq(address(superRBAC.superRegistry()), address(0x1));
    }

    function test_grantProtocolAdminRole() public {
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.PROTOCOL_ADMIN_ROLE(), address(0x1));
        assertEq(superRBAC.hasProtocolAdminRole(address(0x1)), true);
        superRBAC.revokeRole(superRBAC.PROTOCOL_ADMIN_ROLE(), address(0x1));
        vm.stopPrank();
    }

    function test_revokeProtocolAdminRole_CannotRevokeLastAdmin() public {
        vm.startPrank(deployer);
        bytes32 role = superRBAC.PROTOCOL_ADMIN_ROLE();
        vm.expectRevert(Error.CANNOT_REVOKE_LAST_ADMIN.selector);
        superRBAC.revokeRole(role, deployer);
        vm.stopPrank();
    }

    function test_revokeProtocolAdminRole() public {
        address test = address(1000);
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.PROTOCOL_ADMIN_ROLE(), test);
        superRBAC.revokeRole(superRBAC.PROTOCOL_ADMIN_ROLE(), deployer);
        vm.stopPrank();

        assertEq(superRBAC.hasProtocolAdminRole(deployer), false);
    }

    function test_grantPaymentAdminRole() public {
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.PAYMENT_ADMIN_ROLE(), address(0x1));
        vm.stopPrank();

        assertEq(superRBAC.hasPaymentAdminRole(address(0x1)), true);
    }

    function test_revokePaymentAdminRole() public {
        _revokeAndCheck(
            superRBAC.hasPaymentAdminRole.selector,
            superRBAC.PAYMENT_ADMIN_ROLE(),
            superRegistry.PAYMENT_ADMIN(),
            deployer,
            "",
            generateBroadcastParams(5, 1),
            0
        );
    }

    function test_grantEmergencyAdminRole() public {
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.EMERGENCY_ADMIN_ROLE(), address(0x1));
        vm.stopPrank();

        assertEq(superRBAC.hasEmergencyAdminRole(address(0x1)), true);
    }

    function test_revokeEmergencyAdminRole() public {
        address test = address(1000);
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.EMERGENCY_ADMIN_ROLE(), test);
        superRBAC.revokeRole(superRBAC.EMERGENCY_ADMIN_ROLE(), deployer);
        vm.stopPrank();

        assertEq(superRBAC.hasEmergencyAdminRole(deployer), false);
    }

    function test_revokeEmergencyAdminRole_CannotRevokeLastAdmin() public {
        vm.startPrank(deployer);
        bytes32 role = superRBAC.EMERGENCY_ADMIN_ROLE();

        vm.expectRevert(Error.CANNOT_REVOKE_LAST_ADMIN.selector);
        superRBAC.revokeRole(role, deployer);
        vm.stopPrank();
    }

    function test_grantSwapperRole() public {
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.MULTI_TX_SWAPPER_ROLE(), address(0x1));
        vm.stopPrank();

        assertEq(superRBAC.hasMultiTxProcessorSwapperRole(address(0x1)), true);
    }

    function test_revokeMultiTxSwapperRole() public {
        _revokeAndCheck(
            superRBAC.hasMultiTxProcessorSwapperRole.selector,
            superRBAC.MULTI_TX_SWAPPER_ROLE(),
            superRegistry.MULTI_TX_SWAPPER(),
            deployer,
            "",
            generateBroadcastParams(5, 1),
            0
        );
    }

    function test_grantCoreStateRegistryProcessorRole() public {
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.CORE_STATE_REGISTRY_PROCESSOR_ROLE(), address(0x1));
        vm.stopPrank();

        assertEq(superRBAC.hasCoreStateRegistryProcessorRole(address(0x1)), true);
    }

    function test_revokeCoreStateRegistryProcessorRole() public {
        _revokeAndCheck(
            superRBAC.hasCoreStateRegistryProcessorRole.selector,
            superRBAC.CORE_STATE_REGISTRY_PROCESSOR_ROLE(),
            superRegistry.CORE_REGISTRY_PROCESSOR(),
            deployer,
            "",
            generateBroadcastParams(5, 1),
            0
        );
    }

    function test_grantBroadacastStateRegistryProcessorRole() public {
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE(), address(0x1));
        vm.stopPrank();

        assertEq(superRBAC.hasBroadcastStateRegistryProcessorRole(address(0x1)), true);
    }

    function test_revokeBroadcastStateRegistryProcessorRole() public {
        _revokeAndCheck(
            superRBAC.hasBroadcastStateRegistryProcessorRole.selector,
            superRBAC.BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE(),
            superRegistry.BROADCAST_REGISTRY_PROCESSOR(),
            deployer,
            "",
            generateBroadcastParams(5, 1),
            0
        );
    }

    function test_grantTwoStepsStateRegistryProcessorRole() public {
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.TWOSTEPS_STATE_REGISTRY_PROCESSOR_ROLE(), address(0x1));
        vm.stopPrank();

        assertEq(superRBAC.hasTwoStepsStateRegistryProcessorRole(address(0x1)), true);
    }

    function test_revokeTwoStepsStateRegistrvyProcessorRole() public {
        _revokeAndCheck(
            superRBAC.hasTwoStepsStateRegistryProcessorRole.selector,
            superRBAC.TWOSTEPS_STATE_REGISTRY_PROCESSOR_ROLE(),
            superRegistry.TWO_STEPS_REGISTRY_PROCESSOR(),
            deployer,
            "",
            generateBroadcastParams(5, 1),
            0
        );
    }

    function test_grantCoreStateRegistryUpdaterRole() public {
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.CORE_STATE_REGISTRY_UPDATER_ROLE(), address(0x1));
        vm.stopPrank();

        assertEq(superRBAC.hasCoreStateRegistryUpdaterRole(address(0x1)), true);
    }

    function test_revokeCoreStateRegistryUpdaterRole() public {
        _revokeAndCheck(
            superRBAC.hasCoreStateRegistryUpdaterRole.selector,
            superRBAC.CORE_STATE_REGISTRY_UPDATER_ROLE(),
            superRegistry.CORE_REGISTRY_UPDATER(),
            deployer,
            "",
            generateBroadcastParams(5, 1),
            0
        );
    }

    function test_grantMinterRole() public {
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.SUPERPOSITIONS_MINTER_ROLE(), address(0x1));
        vm.stopPrank();

        assertEq(superRBAC.hasSuperPositionsMinterRole(address(0x1)), true);
    }

    function test_revokeMinterRole() public {
        _revokeAndCheck(
            superRBAC.hasSuperPositionsMinterRole.selector,
            superRBAC.SUPERPOSITIONS_MINTER_ROLE(),
            superRegistry.TWO_STEPS_FORM_STATE_REGISTRY(),
            deployer,
            "TwoStepsFormStateRegistry",
            generateBroadcastParams(5, 1),
            0
        );
    }

    function test_grantBurnerRole() public {
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.SUPERPOSITIONS_BURNER_ROLE(), address(0x1));
        vm.stopPrank();

        assertEq(superRBAC.hasSuperPositionsBurnerRole(address(0x1)), true);
    }

    function test_revokeBurnerRole() public {
        _revokeAndCheck(
            superRBAC.hasSuperPositionsBurnerRole.selector,
            superRBAC.SUPERPOSITIONS_BURNER_ROLE(),
            superRegistry.SUPERFORM_ROUTER(),
            deployer,
            "SuperformRouter",
            generateBroadcastParams(5, 1),
            0
        );
    }

    function test_grantStateRegistryMinterRole() public {
        vm.startPrank(deployer);

        uint8[] memory registryIds = new uint8[](1);
        registryIds[0] = 1;

        address[] memory registryAddress = new address[](1);
        registryAddress[0] = address(0x1);

        superRegistry.setStateRegistryAddress(registryIds, registryAddress);

        superRBAC.grantRole(superRBAC.MINTER_STATE_REGISTRY_ROLE(), address(0x1));
        vm.stopPrank();

        assertEq(superRBAC.hasMinterStateRegistryRole(address(0x1)), true);
    }

    function test_revokeStateRegistryMinterRole() public {
        _revokeAndCheck(
            superRBAC.hasMinterStateRegistryRole.selector,
            superRBAC.MINTER_STATE_REGISTRY_ROLE(),
            superRegistry.CORE_STATE_REGISTRY(),
            deployer,
            "CoreStateRegistry",
            generateBroadcastParams(5, 1),
            0
        );
    }

    function test_stateSync_invalidCaller() public {
        vm.expectRevert(Error.NOT_BROADCAST_REGISTRY.selector);
        superRBAC.stateSyncBroadcast("");
    }

    function test_stateSync_addressToRevokeIs0() public {
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        vm.prank(getContract(ETH, "BroadcastRegistry"));
        superRBAC.stateSyncBroadcast(
            abi.encode(
                BroadcastMessage(
                    "SUPER_RBAC",
                    keccak256("SYNC_REVOKE"),
                    abi.encode(keccak256("SUPERPOSITIONS_MINTER_ROLE"), keccak256("NON_EXISTENT_ID"))
                )
            )
        );
    }

    function test_setup_new_role() public {
        vm.prank(deployer);
        superRBAC.setRoleAdmin(keccak256("NEW_ROLE"), keccak256("PROTOCOL_ADMIN_ROLE"));
    }

    function _revokeAndCheck(
        bytes4 checkRole_,
        bytes32 superRBACRole_,
        bytes32 superRegistryAddressId_,
        address actor_,
        string memory member_,
        bytes memory extraData_,
        uint256 value_
    )
        internal
    {
        vm.deal(actor_, value_ + 1 ether);
        vm.prank(actor_);

        vm.recordLogs();

        address memberAddress;
        if (bytes(member_).length == 0) {
            memberAddress = deployer;
        } else {
            memberAddress = getContract(ETH, member_);
        }

        /// @dev setting the status as false in chain id = ETH
        superRBAC.revokeRoleSuperBroadcast{ value: value_ }(
            superRBACRole_, memberAddress, extraData_, superRegistryAddressId_
        );

        vm.startPrank(deployer);
        _broadcastPayloadHelper(ETH, vm.getRecordedLogs());
        vm.stopPrank();

        /// @dev role revoked on ETH
        (, bytes memory isRevoked) = address(superRBAC).call(abi.encodeWithSelector(checkRole_, memberAddress));
        assertEq(abi.decode(isRevoked, (bool)), false);

        /// @dev broadcasting revokes to other chains on hold
        SuperRBAC superRBAC_;
        // /// @dev process the payload across all other chains
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (bytes(member_).length > 0) {
                memberAddress = getContract(chainIds[i], member_);
            }
            if (chainIds[i] != ETH) {
                vm.selectFork(FORKS[chainIds[i]]);
                superRBAC_ = SuperRBAC(getContract(chainIds[i], "SuperRBAC"));

                (, bytes memory statusBefore) =
                    address(superRBAC_).call(abi.encodeWithSelector(checkRole_, memberAddress));
                vm.prank(deployer);
                BroadcastRegistry(payable(getContract(chainIds[i], "BroadcastRegistry"))).processPayload(1);
                (, bytes memory statusAfter) =
                    address(superRBAC_).call(abi.encodeWithSelector(checkRole_, memberAddress));

                /// @dev assert status update before and after processing the payload
                assertEq(abi.decode(statusBefore, (bool)), true);
                assertEq(abi.decode(statusAfter, (bool)), false);
            }
        }

        /// try processing the same payload again
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] != ETH) {
                vm.selectFork(FORKS[chainIds[i]]);
                /// @dev re-grant roles state registry role in case it was revoked to test remaining of cases
                if (superRBACRole_ == keccak256("ROLES_STATE_REGISTRY_PROCESSOR_ROLE")) {
                    SuperRBAC(getContract(chainIds[i], "SuperRBAC")).grantRole(superRBACRole_, deployer);
                }

                vm.expectRevert(Error.PAYLOAD_ALREADY_PROCESSED.selector);
                vm.prank(deployer);
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
    }
}

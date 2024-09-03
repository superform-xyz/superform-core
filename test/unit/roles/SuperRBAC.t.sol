// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/BaseSetup.sol";
import "test/utils/Utilities.sol";

import { BroadcastRegistry } from "src/crosschain-data/BroadcastRegistry.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { SuperRBAC } from "src/settings/SuperRBAC.sol";

import { Error } from "src/libraries/Error.sol";

contract Invalid { }

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
        vm.startPrank(deployer);
        SuperRBAC newReg = new SuperRBAC(
            ISuperRBAC.InitialRoleSetup({
                admin: deployer,
                emergencyAdmin: deployer,
                paymentAdmin: deployer,
                csrProcessor: deployer,
                tlProcessor: deployer,
                brProcessor: deployer,
                csrUpdater: deployer,
                srcVaaRelayer: deployer,
                dstSwapper: deployer,
                csrRescuer: deployer,
                csrDisputer: deployer
            })
        );
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        newReg.setSuperRegistry(address(0));

        newReg.setSuperRegistry(address(0x1));
        assertEq(address(newReg.superRegistry()), address(0x1));

        vm.expectRevert(Error.DISABLED.selector);
        newReg.setSuperRegistry(address(0x1));

        vm.stopPrank();
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

        assertEq(superRBAC.hasRole(superRBAC.PAYMENT_ADMIN_ROLE(), address(0x1)), true);
    }

    function test_revokePaymentAdminRole() public {
        _revokeAndCheck(
            superRBAC.PAYMENT_ADMIN_ROLE(), superRegistry.PAYMENT_ADMIN(), deployer, "", generateBroadcastParams(0), 0
        );
    }

    function test_revokeCsrDisputerRole_withGasFeeGt0AndMsgValue0() public {
        _revokeAndCheck(
            superRBAC.CORE_STATE_REGISTRY_DISPUTER_ROLE(),
            superRegistry.CORE_REGISTRY_DISPUTER(),
            deployer,
            "",
            generateBroadcastParams(100),
            0
        );
    }

    function test_revokeCsrDisputerRole_withGasFeeGt0AndMsgValue101() public {
        _revokeAndCheck(
            superRBAC.CORE_STATE_REGISTRY_DISPUTER_ROLE(),
            superRegistry.CORE_REGISTRY_DISPUTER(),
            deployer,
            "",
            generateBroadcastParams(100),
            101
        );
    }

    function test_revokeCsrDisputerRole_withGasFeeGt0AndMsgValue101_invalidRefundReceiver() public {
        address invalid = address(new Invalid());
        _revokeAndCheck(
            superRBAC.CORE_STATE_REGISTRY_DISPUTER_ROLE(),
            superRegistry.CORE_REGISTRY_DISPUTER(),
            invalid,
            "",
            generateBroadcastParams(100),
            101
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

    function test_grantCoreStateRegistryProcessorRole() public {
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.CORE_STATE_REGISTRY_PROCESSOR_ROLE(), address(0x1));
        vm.stopPrank();

        assertEq(superRBAC.hasRole(superRBAC.CORE_STATE_REGISTRY_PROCESSOR_ROLE(), address(0x1)), true);
    }

    function test_revokeCoreStateRegistryProcessorRole() public {
        _revokeAndCheck(
            superRBAC.CORE_STATE_REGISTRY_PROCESSOR_ROLE(),
            superRegistry.CORE_REGISTRY_PROCESSOR(),
            deployer,
            "",
            generateBroadcastParams(0),
            0
        );
    }

    function test_grantBroadacastStateRegistryProcessorRole() public {
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE(), address(0x1));
        vm.stopPrank();

        assertEq(superRBAC.hasRole(superRBAC.BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE(), address(0x1)), true);
    }

    function test_revokeBroadcastStateRegistryProcessorRole() public {
        _revokeAndCheck(
            superRBAC.BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE(),
            superRegistry.BROADCAST_REGISTRY_PROCESSOR(),
            deployer,
            "",
            generateBroadcastParams(0),
            0
        );
    }

    function test_grantTimelockStateRegistryProcessorRole() public {
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE(), address(0x1));
        vm.stopPrank();

        assertEq(superRBAC.hasRole(superRBAC.TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE(), address(0x1)), true);
    }

    function test_revokeTimelockStateRegistrvyProcessorRole() public {
        _revokeAndCheck(
            superRBAC.TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE(),
            superRegistry.TIMELOCK_REGISTRY_PROCESSOR(),
            deployer,
            "",
            generateBroadcastParams(0),
            0
        );
    }

    function test_grantCoreStateRegistryUpdaterRole() public {
        vm.startPrank(deployer);
        superRBAC.grantRole(superRBAC.CORE_STATE_REGISTRY_UPDATER_ROLE(), address(0x1));
        vm.stopPrank();

        assertEq(superRBAC.hasRole(superRBAC.CORE_STATE_REGISTRY_UPDATER_ROLE(), address(0x1)), true);
    }

    function test_revokeCoreStateRegistryUpdaterRole() public {
        _revokeAndCheck(
            superRBAC.CORE_STATE_REGISTRY_UPDATER_ROLE(),
            superRegistry.CORE_REGISTRY_UPDATER(),
            deployer,
            "",
            generateBroadcastParams(0),
            0
        );
    }

    function test_revokeCoreStateRegistryRescuerRole() public {
        _revokeAndCheck(
            superRBAC.CORE_STATE_REGISTRY_RESCUER_ROLE(),
            superRegistry.CORE_REGISTRY_RESCUER(),
            deployer,
            "",
            generateBroadcastParams(0),
            0
        );
    }

    function test_revokeDstSwapperProcessorRole() public {
        _revokeAndCheck(
            superRBAC.DST_SWAPPER_ROLE(),
            superRegistry.DST_SWAPPER_PROCESSOR(),
            deployer,
            "",
            generateBroadcastParams(0),
            0
        );
    }

    function test_stateSync_invalidCaller() public {
        vm.expectRevert(Error.NOT_BROADCAST_REGISTRY.selector);
        superRBAC.stateSyncBroadcast("");
    }

    function test_stateSync_invalidType() public {
        vm.expectRevert(Error.INVALID_MESSAGE_TYPE.selector);
        vm.prank(getContract(ETH, "BroadcastRegistry"));

        superRBAC.stateSyncBroadcast(
            abi.encode(
                BroadcastMessage(
                    "SUPER_RBAC",
                    keccak256("OTHER_TYPE"),
                    abi.encode(1, keccak256("PAYMENT_ADMIN_ROLE"), keccak256("NON_EXISTENT_ID"))
                )
            )
        );
    }

    function test_stateSync_addressToRevokeIs0() public {
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        vm.prank(getContract(ETH, "BroadcastRegistry"));
        superRBAC.stateSyncBroadcast(
            abi.encode(
                BroadcastMessage(
                    "SUPER_RBAC",
                    keccak256("SYNC_REVOKE"),
                    abi.encode(1, keccak256("PAYMENT_ADMIN_ROLE"), keccak256("NON_EXISTENT_ID"))
                )
            )
        );
    }

    function test_stateSync_roleToRevokeDoesNotExist() public {
        vm.expectRevert(Error.ROLE_NOT_ASSIGNED.selector);
        vm.prank(getContract(ETH, "BroadcastRegistry"));
        superRBAC.stateSyncBroadcast(
            abi.encode(
                BroadcastMessage(
                    "SUPER_RBAC",
                    keccak256("SYNC_REVOKE"),
                    abi.encode(1, keccak256("NON_EXISTENT_ROLE"), keccak256("SUPERFORM_ROUTER"))
                )
            )
        );
    }

    function test_setup_new_role() public {
        vm.prank(deployer);
        superRBAC.setRoleAdmin(keccak256("NEW_ROLE"), keccak256("PROTOCOL_ADMIN_ROLE"));
    }

    function test_revokeRoleWithoutBroadcast() public {
        vm.startPrank(deployer);
        superRBAC.revokeRoleSuperBroadcast(superRBAC.PAYMENT_ADMIN_ROLE(), "", superRegistry.PAYMENT_ADMIN());
    }

    function test_revokeSuperBroadcast_CannotRevoke() public {
        vm.deal(deployer, 1 ether);
        vm.startPrank(deployer);
        bytes32 id = keccak256("id");
        vm.expectRevert(Error.CANNOT_REVOKE_NON_BROADCASTABLE_ROLES.selector);
        /// @dev setting the status as false in chain id = ETH
        superRBAC.revokeRoleSuperBroadcast{ value: 1 ether }(
            keccak256("BROADCASTER_ROLE"), generateBroadcastParams(0), id
        );
        vm.expectRevert(Error.CANNOT_REVOKE_NON_BROADCASTABLE_ROLES.selector);
        /// @dev setting the status as false in chain id = ETH
        superRBAC.revokeRoleSuperBroadcast{ value: 1 ether }(
            keccak256("PROTOCOL_ADMIN_ROLE"), generateBroadcastParams(0), id
        );
        vm.expectRevert(Error.CANNOT_REVOKE_NON_BROADCASTABLE_ROLES.selector);
        /// @dev setting the status as false in chain id = ETH
        superRBAC.revokeRoleSuperBroadcast{ value: 1 ether }(
            keccak256("EMERGENCY_ADMIN_ROLE"), generateBroadcastParams(0), id
        );
        vm.expectRevert(Error.CANNOT_REVOKE_NON_BROADCASTABLE_ROLES.selector);
        /// @dev setting the status as false in chain id = ETH
        superRBAC.revokeRoleSuperBroadcast{ value: 1 ether }(
            keccak256("WORMHOLE_VAA_RELAYER_ROLE"), generateBroadcastParams(0), id
        );
    }

    function test_revokeSuperBroadcast_RoleNotAssigned() public {
        vm.deal(deployer, 1 ether);
        vm.prank(deployer);
        /// @dev setting the status as false in chain id = ETH
        vm.expectRevert(Error.ROLE_NOT_ASSIGNED.selector);
        superRBAC.revokeRoleSuperBroadcast{ value: 1 ether }(
            keccak256("ROLE"), generateBroadcastParams(0), keccak256("SUPERFORM_ROUTER")
        );
    }

    function _revokeAndCheck(
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
        bytes32 roleToCompare = superRBAC.CORE_STATE_REGISTRY_DISPUTER_ROLE();

        vm.recordLogs();

        address memberAddress;
        if (bytes(member_).length == 0) {
            memberAddress = deployer;
        } else {
            memberAddress = getContract(ETH, member_);
        }

        /// @dev setting the status as false in chain id = ETH
        if (superRBACRole_ != roleToCompare) {
            vm.prank(actor_);

            superRBAC.revokeRoleSuperBroadcast{ value: value_ }(superRBACRole_, extraData_, superRegistryAddressId_);

            vm.startPrank(deployer);
            _broadcastPayloadHelper(ETH, vm.getRecordedLogs());
            vm.stopPrank();

            /// @dev role revoked on ETH
            assertFalse(superRBAC.hasRole(superRBACRole_, memberAddress));

            /// @dev broadcasting revokes to other chains on hold
            SuperRBAC superRBAC_;
            // /// @dev process the payload across all other chains
            for (uint256 i = 0; i < chainIds.length; ++i) {
                if (chainIds[i] == LINEA || chainIds[i] == SEPOLIA || chainIds[i] == BSC_TESTNET) continue;
                if (bytes(member_).length > 0) {
                    memberAddress = getContract(chainIds[i], member_);
                }
                if (chainIds[i] != ETH) {
                    vm.selectFork(FORKS[chainIds[i]]);
                    superRBAC_ = SuperRBAC(getContract(chainIds[i], "SuperRBAC"));

                    assertTrue(superRBAC_.hasRole(superRBACRole_, memberAddress));

                    vm.prank(deployer);
                    BroadcastRegistry(payable(getContract(chainIds[i], "BroadcastRegistry"))).processPayload(1);
                    assertFalse(superRBAC_.hasRole(superRBACRole_, memberAddress));
                }
            }

            /// try processing the same payload again
            for (uint256 i = 0; i < chainIds.length; ++i) {
                if (chainIds[i] == LINEA || chainIds[i] == SEPOLIA || chainIds[i] == BSC_TESTNET) continue;
                if (chainIds[i] != ETH) {
                    vm.selectFork(FORKS[chainIds[i]]);
                    /// @dev re-grant broadcast state registry role in case it was revoked to test remaining of cases
                    if (superRBACRole_ == keccak256("BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE")) {
                        vm.prank(deployer);
                        SuperRBAC(getContract(chainIds[i], "SuperRBAC")).grantRole(superRBACRole_, deployer);
                    }

                    vm.expectRevert(Error.PAYLOAD_ALREADY_PROCESSED.selector);
                    vm.prank(deployer);
                    BroadcastRegistry(payable(getContract(chainIds[i], "BroadcastRegistry"))).processPayload(1);
                }
            }

            /// try processing not available payload id
            for (uint256 i = 0; i < chainIds.length; ++i) {
                if (chainIds[i] == LINEA || chainIds[i] == SEPOLIA || chainIds[i] == BSC_TESTNET) continue;
                if (chainIds[i] != ETH) {
                    vm.selectFork(FORKS[chainIds[i]]);

                    vm.expectRevert(Error.INVALID_PAYLOAD_ID.selector);
                    vm.prank(deployer);
                    BroadcastRegistry(payable(getContract(chainIds[i], "BroadcastRegistry"))).processPayload(2);
                }
            }
        } else {
            if (value_ == 0) {
                vm.prank(actor_);
                vm.expectRevert(Error.INVALID_BROADCAST_FEE.selector);
                superRBAC.revokeRoleSuperBroadcast{ value: value_ }(superRBACRole_, extraData_, superRegistryAddressId_);
            } else if (value_ > 100 && actor_ == deployer) {
                vm.prank(actor_);
                superRBAC.revokeRoleSuperBroadcast{ value: value_ }(superRBACRole_, extraData_, superRegistryAddressId_);
            } else if (value_ > 100 && actor_ != deployer) {
                vm.mockCall(
                    address(superRegistry),
                    abi.encodeWithSelector(superRegistry.getAddress.selector, keccak256("PAYMASTER")),
                    abi.encode(actor_)
                );

                vm.prank(deployer);
                vm.expectRevert(Error.FAILED_TO_SEND_NATIVE.selector);
                superRBAC.revokeRoleSuperBroadcast{ value: value_ }(superRBACRole_, extraData_, superRegistryAddressId_);
                vm.clearMockedCalls();
            }
        }
    }
}

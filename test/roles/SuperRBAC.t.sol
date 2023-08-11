// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "../utils/BaseSetup.sol";
import "../utils/Utilities.sol";

import {ISuperformFactory} from "src/interfaces/ISuperformFactory.sol";
import {ISuperRegistry} from "src/interfaces/ISuperRegistry.sol";
import {SuperRBAC} from "src/settings/SuperRBAC.sol";
import {Error} from "src/utils/Error.sol";

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
        vm.prank(deployer);
        superRBAC.grantProtocolAdminRole(address(0x1));
        assertEq(superRBAC.hasProtocolAdminRole(address(0x1)), true);
    }

    function test_revokeProtocolAdminRole() public {
        vm.prank(deployer);
        superRBAC.revokeProtocolAdminRole(deployer);
        assertEq(superRBAC.hasProtocolAdminRole(deployer), false);
    }

    function test_grantFeeAdminRole() public {
        vm.prank(deployer);
        superRBAC.grantFeeAdminRole(address(0x1));
        assertEq(superRBAC.hasFeeAdminRole(address(0x1)), true);
    }

    function test_revokeFeeAdminRole() public {
        _revokeAndCheck(
            superRBAC.revokeFeeAdminRole.selector,
            superRBAC.hasFeeAdminRole.selector,
            deployer,
            "",
            generateBroadcastParams(5, 2),
            800 ether
        );
    }

    function test_grantEmergencyAdminRole() public {
        vm.prank(deployer);
        superRBAC.grantEmergencyAdminRole(address(0x1));
        assertEq(superRBAC.hasEmergencyAdminRole(address(0x1)), true);
    }

    function test_revokeEmergencyAdminRole() public {
        vm.prank(deployer);
        superRBAC.revokeEmergencyAdminRole(deployer);
        assertEq(superRBAC.hasEmergencyAdminRole(deployer), false);
    }

    function test_grantSwapperRole() public {
        vm.prank(deployer);
        superRBAC.grantSwapperRole(address(0x1));
        assertEq(superRBAC.hasSwapperRole(address(0x1)), true);
    }

    function test_revokeSwapperRole() public {
        _revokeAndCheck(
            superRBAC.revokeSwapperRole.selector,
            superRBAC.hasSwapperRole.selector,
            deployer,
            "",
            generateBroadcastParams(5, 2),
            800 ether
        );
    }

    function test_grantCoreContractsRole() public {
        vm.prank(deployer);
        superRBAC.grantCoreContractsRole(address(0x1));
        assertEq(superRBAC.hasCoreContractsRole(address(0x1)), true);
    }

    function test_revokeCoreContractsRole() public {
        vm.prank(deployer);
        superRBAC.grantCoreContractsRole(deployer);

        _revokeAndCheck(
            superRBAC.revokeCoreContractsRole.selector,
            superRBAC.hasCoreContractsRole.selector,
            deployer,
            "SuperformFactory",
            generateBroadcastParams(5, 2),
            800 ether
        );
    }

    function test_grantProcessorRole() public {
        vm.prank(deployer);
        superRBAC.grantProcessorRole(address(0x1));
        assertEq(superRBAC.hasProcessorRole(address(0x1)), true);
    }

    function test_revokeProcessorRole() public {
        _revokeAndCheck(
            superRBAC.revokeProcessorRole.selector,
            superRBAC.hasProcessorRole.selector,
            deployer,
            "",
            generateBroadcastParams(5, 2),
            800 ether
        );
    }

    function test_grantTwoStepsProcessorRole() public {
        vm.prank(deployer);
        superRBAC.grantTwoStepsProcessorRole(address(0x1));
        assertEq(superRBAC.hasTwoStepsProcessorRole(address(0x1)), true);
    }

    function test_revokeTwoStepsProcessorRole() public {
        _revokeAndCheck(
            superRBAC.revokeTwoStepsProcessorRole.selector,
            superRBAC.hasTwoStepsProcessorRole.selector,
            deployer,
            "",
            generateBroadcastParams(5, 2),
            800 ether
        );
    }

    function test_grantUpdaterRole() public {
        vm.prank(deployer);
        superRBAC.grantUpdaterRole(address(0x1));
        assertEq(superRBAC.hasUpdaterRole(address(0x1)), true);
    }

    function test_revokeUpdaterRole() public {
        _revokeAndCheck(
            superRBAC.revokeUpdaterRole.selector,
            superRBAC.hasUpdaterRole.selector,
            deployer,
            "",
            generateBroadcastParams(5, 2),
            800 ether
        );
    }

    function test_grantMinterRole() public {
        vm.prank(deployer);
        superRBAC.grantMinterRole(address(0x1));
        assertEq(superRBAC.hasMinterRole(address(0x1)), true);
    }

    function test_revokeMinterRole() public {
        _revokeAndCheck(
            superRBAC.revokeMinterRole.selector,
            superRBAC.hasMinterRole.selector,
            deployer,
            "TwoStepsFormStateRegistry",
            generateBroadcastParams(5, 2),
            800 ether
        );
    }

    function test_grantBurnerRole() public {
        vm.prank(deployer);
        superRBAC.grantBurnerRole(address(0x1));
        assertEq(superRBAC.hasBurnerRole(address(0x1)), true);
    }

    function test_revokeBurnerRole() public {
        _revokeAndCheck(
            superRBAC.revokeBurnerRole.selector,
            superRBAC.hasBurnerRole.selector,
            deployer,
            "SuperformRouter",
            generateBroadcastParams(5, 2),
            800 ether
        );
    }

    function test_grantStateRegistryMinterRole() public {
        vm.startPrank(deployer);

        uint8[] memory registryIds = new uint8[](1);
        registryIds[0] = 1;

        address[] memory registryAddress = new address[](1);
        registryAddress[0] = address(0x1);

        superRegistry.setStateRegistryAddress(registryIds, registryAddress);

        superRBAC.grantMinterStateRegistryRole(address(0x1));
        assertEq(superRBAC.hasMinterStateRegistryRole(address(0x1)), true);
    }

    function test_grantStateRegistryMinterRoleToWrongAddress() public {
        vm.startPrank(deployer);

        uint8[] memory registryIds = new uint8[](1);
        registryIds[0] = 1;

        address[] memory registryAddress = new address[](1);
        registryAddress[0] = address(0x1);

        superRegistry.setStateRegistryAddress(registryIds, registryAddress);

        vm.expectRevert(Error.NOT_VALID_STATE_REGISTRY.selector);
        superRBAC.grantMinterStateRegistryRole(address(0x2));
    }

    function test_revokeStateRegistryMinterRole() public {
        _revokeAndCheck(
            superRBAC.revokeMinterStateRegistryRole.selector,
            superRBAC.hasMinterStateRegistryRole.selector,
            deployer,
            "CoreStateRegistry",
            generateBroadcastParams(5, 2),
            800 ether
        );
    }

    function _revokeAndCheck(
        bytes4 revokeRole_,
        bytes4 checkRole_,
        address actor_,
        string memory member_,
        bytes memory extraData_,
        uint256 value_
    ) internal {
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
        (bool success, ) = address(superRBAC).call{value: value_}(
            abi.encodeWithSelector(revokeRole_, memberAddress, extraData_)
        );

        vm.prank(deployer);
        /// @dev broadcasting on hold
        // _broadcastPayloadHelper(ETH, vm.getRecordedLogs());

        /// @dev role revoked on ETH
        (, bytes memory isRevoked) = address(superRBAC).call(abi.encodeWithSelector(checkRole_, memberAddress));
        assertEq(abi.decode(isRevoked, (bool)), false);

        /// @dev broadcasting revokes to other chains on hold
        // SuperRBAC superRBAC_;
        // /// @dev process the payload across all other chains
        // for (uint256 i = 0; i < chainIds.length; i++) {
        //     if (bytes(member_).length > 0) {
        //         memberAddress = getContract(chainIds[i], member_);
        //     }
        //     if (chainIds[i] != ETH) {
        //         vm.selectFork(FORKS[chainIds[i]]);
        //         superRBAC_ = SuperRBAC(getContract(chainIds[i], "SuperRBAC"));

        //         (, bytes memory statusBefore) = address(superRBAC_).call(abi.encodeWithSelector(checkRole_, memberAddress));
        //         RolesStateRegistry(payable(getContract(chainIds[i], "RolesStateRegistry"))).processPayload(1, "");
        //         (, bytes memory statusAfter) = address(superRBAC_).call(abi.encodeWithSelector(checkRole_, memberAddress));

        //         /// @dev assert status update before and after processing the payload
        //         assertEq(abi.decode(statusBefore, (bool)), true);
        //         assertEq(abi.decode(statusAfter, (bool)), false);

        //         vm.selectFork(FORKS[ETH]);
        //     }
        // }
    }
}

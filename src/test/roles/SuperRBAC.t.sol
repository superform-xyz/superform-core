// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "../utils/BaseSetup.sol";
import "../utils/Utilities.sol";

import {ISuperFormFactory} from "../../interfaces/ISuperFormFactory.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {SuperRBAC} from "../../settings/SuperRBAC.sol";
import {RolesStateRegistry} from "../../crosschain-data/extensions/RolesStateRegistry.sol";
import {Error} from "../../utils/Error.sol";

contract SuperRBACTest is BaseSetup {
    SuperRBAC public superRBAC;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRBAC = SuperRBAC(getContract(ETH, "SuperRBAC"));
        vm.startPrank(deployer);
    }

    function test_setSuperRegistry() public {
        superRBAC.setSuperRegistry(address(0x1));
        assertEq(address(superRBAC.superRegistry()), address(0x1));
    }

    function test_grantProtocolAdminRole() public {
        superRBAC.grantProtocolAdminRole(address(0x1));
        assertEq(superRBAC.hasProtocolAdminRole(address(0x1)), true);
    }

    function test_revokeProtocolAdminRole() public {
        superRBAC.revokeProtocolAdminRole(deployer);
        assertEq(superRBAC.hasProtocolAdminRole(deployer), false);
    }

    function test_grantFeeAdminRole() public {
        superRBAC.grantFeeAdminRole(address(0x1));
        assertEq(superRBAC.hasFeeAdminRole(address(0x1)), true);
    }

    function test_revokeFeeAdminRole() public {
        _revokeAndCheck(
            superRBAC.revokeFeeAdminRole.selector, 
            superRBAC.hasFeeAdminRole.selector,
            deployer,
            deployer,
            generateBroadcastParams(5, 2),
            800 ether
        );
    }

    function test_grantEmergencyAdminRole() public {
        superRBAC.grantEmergencyAdminRole(address(0x1));
        assertEq(superRBAC.hasEmergencyAdminRole(address(0x1)), true);
    }

    function test_revokeEmergencyAdminRole() public {
        superRBAC.revokeEmergencyAdminRole(deployer);
        assertEq(superRBAC.hasEmergencyAdminRole(deployer), false);
    }

    function test_grantSwapperRole() public {
        superRBAC.grantSwapperRole(address(0x1));
        assertEq(superRBAC.hasSwapperRole(address(0x1)), true);
    }

    function test_revokeSwapperRole() public {
        _revokeAndCheck(
            superRBAC.revokeSwapperRole.selector, 
            superRBAC.hasSwapperRole.selector,
            deployer,
            deployer,
            generateBroadcastParams(5, 2),
            800 ether
        );
    }

    function test_grantCoreContractsRole() public {
        superRBAC.grantCoreContractsRole(address(0x1));
        assertEq(superRBAC.hasCoreContractsRole(address(0x1)), true);
    }

    function test_revokeCoreContractsRole() public {
        superRBAC.grantCoreContractsRole(deployer);

        _revokeAndCheck(
            superRBAC.revokeCoreContractsRole.selector, 
            superRBAC.hasCoreContractsRole.selector,
            deployer,
            getContract(ETH, "SuperFormFactory"),
            generateBroadcastParams(5, 2),
            800 ether
        );
    }

    function test_grantProcessorRole() public {
        superRBAC.grantProcessorRole(address(0x1));
        assertEq(superRBAC.hasProcessorRole(address(0x1)), true);
    }

    function test_revokeProcessorRole() public {
        _revokeAndCheck(
            superRBAC.revokeProcessorRole.selector, 
            superRBAC.hasProcessorRole.selector,
            deployer,
            deployer,
            generateBroadcastParams(5, 2),
            800 ether
        );
    }

    function test_grantTwoStepsProcessorRole() public {
        superRBAC.grantTwoStepsProcessorRole(address(0x1));
        assertEq(superRBAC.hasTwoStepsProcessorRole(address(0x1)), true);
    }

    function test_revokeTwoStepsProcessorRole() public {
        _revokeAndCheck(
            superRBAC.revokeTwoStepsProcessorRole.selector, 
            superRBAC.hasTwoStepsProcessorRole.selector,
            deployer,
            deployer,
            generateBroadcastParams(5, 2),
            800 ether
        );
    }

    function test_grantUpdaterRole() public {
        superRBAC.grantUpdaterRole(address(0x1));
        assertEq(superRBAC.hasUpdaterRole(address(0x1)), true);
    }

    function test_revokeUpdaterRole() public {
        _revokeAndCheck(
            superRBAC.revokeUpdaterRole.selector, 
            superRBAC.hasUpdaterRole.selector,
            deployer,
            deployer,
            generateBroadcastParams(5, 2),
            800 ether
        );
    }

    function _revokeAndCheck(
        bytes4 revokeRole_,
        bytes4 checkRole_,
        address actor_,
        address member_,
        bytes memory extraData_,
        uint256 value_
    ) internal {
        vm.stopPrank();

        vm.deal(actor_, value_ + 1 ether);
        vm.prank(actor_);

        vm.recordLogs();
        /// @dev setting the status as false in chain id = ETH & broadcasting it
        (bool success, ) = address(superRBAC).call{value: value_}(abi.encodeWithSelector(revokeRole_, member_, extraData_));
        vm.startPrank(deployer);
        _broadcastPayloadHelper(ETH, vm.getRecordedLogs());

        /// @dev role revoked on ETH
        ( , bytes memory isRevoked) = address(superRBAC).call(abi.encodeWithSelector(checkRole_, member_));
        assertEq(abi.decode(isRevoked, (bool)), false);

        /// @dev process the payload across all other chains
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] != ETH) {
                vm.selectFork(FORKS[chainIds[i]]);

                ( , bytes memory statusBefore) = address(superRBAC).call(abi.encodeWithSelector(checkRole_, member_));
                RolesStateRegistry(payable(getContract(chainIds[i], "RolesStateRegistry"))).processPayload(1, "");
                ( , bytes memory statusAfter) = address(superRBAC).call(abi.encodeWithSelector(checkRole_, member_));

                /// @dev assert status update before and after processing the payload
                assertEq(abi.decode(statusBefore, (bool)), true);
                assertEq(abi.decode(statusAfter, (bool)), false);
            }
        }
    } 
}

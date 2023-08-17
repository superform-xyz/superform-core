// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "../utils/BaseSetup.sol";
import "../utils/Utilities.sol";

import {ISuperformFactory} from "src/interfaces/ISuperformFactory.sol";
import {ISuperRegistry} from "src/interfaces/ISuperRegistry.sol";
import {SuperRegistry} from "src/settings/SuperRegistry.sol";
import {Error} from "src/utils/Error.sol";

contract SuperRegistryTest is BaseSetup {
    SuperRegistry public superRegistry;
    address public bond;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRegistry = SuperRegistry(getContract(ETH, "SuperRegistry"));

        /// @dev malicious caller
        bond = address(7);
        /// @dev (who's a brokie)
        vm.deal(bond, 1 ether);
    }

    function test_setImmutables_and_revert_invalidCaller() public {
        /// @dev resetting these to 0 as they were already set in BaseSetup
        vm.store(address(superRegistry), bytes32(uint256(0)), bytes32(uint256(0)));
        vm.store(address(superRegistry), bytes32(uint256(1)), bytes32(uint256(0)));

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        superRegistry.setImmutables(ETH, getContract(ETH, "CanonicalPermit2"), getContract(ETH, "SuperRBAC"));

        vm.expectRevert(Error.INVALID_INPUT_CHAIN_ID.selector);
        vm.prank(deployer);
        superRegistry.setImmutables(0, getContract(ETH, "CanonicalPermit2"), getContract(ETH, "SuperRBAC"));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        vm.prank(deployer);
        superRegistry.setImmutables(ETH, address(0), getContract(ETH, "SuperRBAC"));

        vm.prank(deployer);
        superRegistry.setImmutables(OP, getContract(OP, "CanonicalPermit2"), getContract(ETH, "SuperRBAC"));

        assertEq(superRegistry.chainId(), OP);
        assertEq(address(superRegistry.PERMIT2()), getContract(OP, "CanonicalPermit2"));

        vm.expectRevert(Error.DISABLED.selector);
        vm.prank(deployer);
        superRegistry.setImmutables(ETH, getContract(OP, "CanonicalPermit2"), getContract(ETH, "SuperRBAC"));
    }

    function test_setSuperRouter_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.SUPER_ROUTER(), address(0x1));
    }

    function test_setSuperformFactory_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.SUPERFORM_FACTORY(), address(0x1));
    }

    function test_setPayMaster_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.PAYMASTER(), address(0x1));
    }

    function test_setPaymentHelper_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.PAYMENT_HELPER(), address(0x1));
    }

    function test_setCoreStateRegistry_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.CORE_STATE_REGISTRY(), address(0x1));
    }

    function test_setTwoStepsFormStateRegistry_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.TWO_STEPS_FORM_STATE_REGISTRY(), address(0x1));
    }

    function test_setFactoryStateRegistry_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.FACTORY_STATE_REGISTRY(), address(0x1));
    }

    /*
    function test_setRolesStateRegistry_and_revert_invalidCaller() public {
        _setAndAssert(
            superRegistry.setRolesStateRegistry.selector,
            superRegistry.rolesStateRegistry.selector,
            address(0x1)
        );
    }
    */

    function test_setSuperPositions_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.SUPER_POSITIONS(), address(0x1));
    }

    function test_setSuperRBAC_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.SUPER_RBAC(), address(0x1));
    }

    function test_setMultiTxProcessor_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.MULTI_TX_PROCESSOR(), address(0x1));
    }

    function test_setTxProcessor_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.TX_PROCESSOR(), address(0x1));
    }

    function test_setTxUpdater_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.TX_UPDATER(), address(0x1));
    }

    function test_setBridgeAddresses_and_revert_invalidCaller() public {
        uint8[] memory bridgeId = new uint8[](3);
        address[] memory bridgeAddress = new address[](3);
        address[] memory bridgeValidator = new address[](3);

        bridgeId[0] = uint8(ETH);
        bridgeAddress[0] = address(0x1);
        bridgeValidator[0] = address(0x2);
        bridgeId[1] = uint8(OP);
        bridgeAddress[1] = address(0x3);
        bridgeValidator[1] = address(0x4);
        bridgeId[2] = uint8(POLY);
        bridgeAddress[2] = address(0x5);
        bridgeValidator[2] = address(0x6);

        vm.prank(deployer);
        superRegistry.setBridgeAddresses(bridgeId, bridgeAddress, bridgeValidator);
        assertEq(superRegistry.getBridgeAddress(uint8(OP)), address(0x3));
        assertEq(superRegistry.getBridgeValidator(uint8(POLY)), address(0x6));

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        superRegistry.setBridgeAddresses(bridgeId, bridgeAddress, bridgeValidator);
    }

    function test_setAmbAddress_and_revert_zeroAddress_invalidCaller() public {
        uint8[] memory ambId = new uint8[](2);
        address[] memory ambAddress = new address[](2);

        ambId[0] = 1;
        ambAddress[0] = address(0x1);
        ambId[1] = 3;
        ambAddress[1] = address(0x3);

        vm.startPrank(deployer);
        superRegistry.setAmbAddress(ambId, ambAddress);
        assertEq(superRegistry.getAmbAddress(3), address(0x3));

        ambAddress[1] = address(0);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        superRegistry.setAmbAddress(ambId, ambAddress);
        vm.stopPrank();

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        superRegistry.setAmbAddress(ambId, ambAddress);

        assertEq(superRegistry.isValidAmbImpl(getContract(ETH, "LayerzeroImplementation")), true);
        assertEq(superRegistry.isValidAmbImpl(address(0x9)), false);
    }

    function test_setStateRegistryAddress_and_revert_zeroAddress_invalidCaller() public {
        uint8[] memory registryId = new uint8[](2);
        address[] memory registryAddress = new address[](2);

        registryId[0] = 1;
        registryAddress[0] = address(0x1);
        registryId[1] = 3;
        registryAddress[1] = address(0x3);

        vm.startPrank(deployer);
        superRegistry.setStateRegistryAddress(registryId, registryAddress);
        assertEq(superRegistry.getStateRegistry(3), address(0x3));

        registryAddress[1] = address(0);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        vm.startPrank(deployer);
        superRegistry.setStateRegistryAddress(registryId, registryAddress);

        registryAddress[1] = address(0);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        superRegistry.setAmbAddress(registryId, registryAddress);
        vm.stopPrank();

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        superRegistry.setAmbAddress(registryId, registryAddress);

        assertEq(superRegistry.isValidStateRegistry(getContract(ETH, "CoreStateRegistry")), true);
    }

    function test_setRequiredMessagingQuorum_and_revert_invalidCaller() public {
        vm.prank(deployer);
        superRegistry.setRequiredMessagingQuorum(OP, 2);
        assertEq(superRegistry.getRequiredMessagingQuorum(OP), 2);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        superRegistry.setRequiredMessagingQuorum(OP, 5);
    }

    function _setAndAssert(bytes32 id_, address contractAddress) internal {
        vm.prank(deployer);
        (bool success, ) = address(superRegistry).call(
            abi.encodeWithSelector(superRegistry.setAddress.selector, id_, contractAddress, ETH)
        );

        (, bytes memory isSet) = address(superRegistry).call(
            abi.encodeWithSelector(superRegistry.getAddress.selector, id_)
        );
        assertEq(abi.decode(isSet, (bool)), true);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        (bool success_, ) = address(superRegistry).call(
            abi.encodeWithSelector(superRegistry.setAddress.selector, id_, address(0x2), ETH)
        );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/BaseSetup.sol";
import "test/utils/Utilities.sol";

import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { SuperRegistry } from "src/settings/SuperRegistry.sol";
import { Error } from "src/libraries/Error.sol";

contract SuperRegistryTest is BaseSetup {
    SuperRegistry public superRegistry;
    SuperRegistry public fakeRegistry;
    SuperRBAC public fakeRBAC;

    address public bond;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRegistry = SuperRegistry(getContract(ETH, "SuperRegistry"));
        fakeRBAC = new SuperRBAC(
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
        fakeRegistry = new SuperRegistry(address(fakeRBAC));

        /// @dev malicious caller
        bond = address(7);
        /// @dev (who's a brokie)
        vm.deal(bond, 1 ether);
    }

    function test_setPermit2_and_revert_invalidCaller() public {
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        fakeRegistry.setPermit2(getContract(ETH, "CanonicalPermit2"));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        vm.prank(deployer);
        fakeRegistry.setPermit2(address(0));

        vm.prank(deployer);
        fakeRegistry.setPermit2(getContract(ETH, "CanonicalPermit2"));

        assertEq(address(superRegistry.PERMIT2()), getContract(ETH, "CanonicalPermit2"));

        vm.expectRevert(Error.DISABLED.selector);
        vm.prank(deployer);
        superRegistry.setPermit2(getContract(ETH, "CanonicalPermit2"));
    }

    function test_setSuperRouter_and_revert_disabled() public {
        _setAndAssert(superRegistry.SUPERFORM_ROUTER(), address(0x1));
    }

    function test_setSuperformFactory_and_revert_disabled() public {
        _setAndAssert(superRegistry.SUPERFORM_FACTORY(), address(0x1));
    }

    function test_setPayMaster_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.PAYMASTER(), address(0x1));
    }

    function test_setPaymentHelper_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.PAYMENT_HELPER(), address(0x1));
    }

    function test_setCoreStateRegistry_and_revert_disabled() public {
        _setAndAssert(superRegistry.CORE_STATE_REGISTRY(), address(0x1));
    }

    function test_setTimelockStateRegistry_and_revert_disabled() public {
        _setAndAssert(superRegistry.TIMELOCK_STATE_REGISTRY(), address(0x1));
    }

    function test_setBroadcastRegistry_and_revert_disabled() public {
        _setAndAssert(superRegistry.BROADCAST_REGISTRY(), address(0x1));
    }

    function test_setSuperPositions_and_revert_disabled() public {
        _setAndAssert(superRegistry.SUPER_POSITIONS(), address(0x1));
    }

    function test_setSuperRBAC_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.SUPER_RBAC(), address(0x1));
    }

    function test_setPayloadHelper_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.PAYLOAD_HELPER(), address(0x1));
    }

    function test_setDstSwapper_and_revert_disabled() public {
        _setAndAssert(superRegistry.DST_SWAPPER(), address(0x1));
    }

    function test_setEmergencyQueue_and_revert_disabled() public {
        _setAndAssert(superRegistry.EMERGENCY_QUEUE(), address(0x1));
    }

    function test_setPAYMENT_ADMIN_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.PAYMENT_ADMIN(), address(0x1));
    }

    function test_setTxProcessor_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.CORE_REGISTRY_PROCESSOR(), address(0x1));
    }

    function test_setBroadcastTxProcessor_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.BROADCAST_REGISTRY_PROCESSOR(), address(0x1));
    }

    function test_setTimelockTxProcessor_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.TIMELOCK_REGISTRY_PROCESSOR(), address(0x1));
    }

    function test_setTxUpdater_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.CORE_REGISTRY_UPDATER(), address(0x1));
    }

    function test_setTxRescuer_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.CORE_REGISTRY_RESCUER(), address(0x1));
    }

    function test_setTxDisputer_and_revert_invalidCaller() public {
        _setAndAssert(superRegistry.CORE_REGISTRY_DISPUTER(), address(0x1));
    }

    function test_setBridgeAddresses_and_revert_invalidCaller() public {
        uint8[] memory bridgeId = new uint8[](3);
        address[] memory bridgeAddress = new address[](3);
        address[] memory bridgeValidator = new address[](3);

        bridgeId[0] = 20;
        bridgeAddress[0] = address(0x1);
        bridgeValidator[0] = address(0x2);
        bridgeId[1] = 30;
        bridgeAddress[1] = address(0x3);
        bridgeValidator[1] = address(0x4);
        bridgeId[2] = 40;
        bridgeAddress[2] = address(0x5);
        bridgeValidator[2] = address(0x6);

        vm.prank(deployer);
        superRegistry.setBridgeAddresses(bridgeId, bridgeAddress, bridgeValidator);
        /// @dev set same address
        vm.prank(deployer);
        vm.expectRevert(Error.DISABLED.selector);
        superRegistry.setBridgeAddresses(bridgeId, bridgeAddress, bridgeValidator);
        vm.prank(deployer);

        assertEq(superRegistry.getBridgeAddress(30), address(0x3));
        assertEq(superRegistry.getBridgeValidator(40), address(0x6));

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        superRegistry.setBridgeAddresses(bridgeId, bridgeAddress, bridgeValidator);
    }

    function test_setBridgeAddresses_array_mismatch_address() public {
        uint8[] memory bridgeId = new uint8[](3);
        address[] memory bridgeAddress = new address[](2);
        address[] memory bridgeValidator = new address[](3);

        bridgeId[0] = uint8(ETH);
        bridgeAddress[0] = address(0x1);
        bridgeValidator[0] = address(0x2);
        bridgeId[1] = uint8(OP);
        bridgeAddress[1] = address(0x3);
        bridgeValidator[1] = address(0x4);
        bridgeId[2] = uint8(POLY);
        bridgeValidator[2] = address(0x6);

        vm.prank(deployer);
        vm.expectRevert(Error.ARRAY_LENGTH_MISMATCH.selector);
        superRegistry.setBridgeAddresses(bridgeId, bridgeAddress, bridgeValidator);
    }

    function test_setBridgeAddresses_array_mismatch_validator() public {
        uint8[] memory bridgeId = new uint8[](3);
        address[] memory bridgeAddress = new address[](3);
        address[] memory bridgeValidator = new address[](2);

        bridgeId[0] = uint8(ETH);
        bridgeAddress[0] = address(0x1);
        bridgeValidator[0] = address(0x2);
        bridgeId[1] = uint8(OP);
        bridgeAddress[1] = address(0x3);
        bridgeValidator[1] = address(0x4);
        bridgeId[2] = uint8(POLY);
        bridgeAddress[2] = address(0x5);

        vm.prank(deployer);
        vm.expectRevert(Error.ARRAY_LENGTH_MISMATCH.selector);
        superRegistry.setBridgeAddresses(bridgeId, bridgeAddress, bridgeValidator);
    }

    function test_setAmbAddress_and_revert_zeroAddress_invalidCaller() public {
        uint8[] memory ambId = new uint8[](2);
        address[] memory ambAddress = new address[](2);
        bool[] memory broadcastAMB = new bool[](2);

        ambId[0] = 5;
        ambAddress[0] = address(0x1);
        ambId[1] = 6;
        ambAddress[1] = address(0x3);
        broadcastAMB[1] = true;
        vm.startPrank(deployer);
        superRegistry.setAmbAddress(ambId, ambAddress, broadcastAMB);
        assertEq(superRegistry.getAmbAddress(6), address(0x3));

        ///@dev set same address
        vm.expectRevert(Error.DISABLED.selector);
        superRegistry.setAmbAddress(ambId, ambAddress, broadcastAMB);

        /// @dev 0 address
        ambAddress[0] = address(0);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        superRegistry.setAmbAddress(ambId, ambAddress, broadcastAMB);
        vm.stopPrank();

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        superRegistry.setAmbAddress(ambId, ambAddress, broadcastAMB);

        assertEq(superRegistry.isValidAmbImpl(getContract(ETH, "LayerzeroImplementation")), true);
        assertEq(superRegistry.isValidAmbImpl(address(0x9)), false);

        assertEq(superRegistry.isValidBroadcastAmbImpl(address(0x1)), false);
        assertEq(superRegistry.isValidBroadcastAmbImpl(address(0x3)), true);
    }

    function test_setAmbAddress_array_mismatch_ambaddress() public {
        uint8[] memory ambId = new uint8[](2);
        address[] memory ambAddress = new address[](1);
        bool[] memory broadcastAMB = new bool[](2);

        ambId[0] = 1;
        ambAddress[0] = address(0x1);
        ambId[1] = 3;

        vm.startPrank(deployer);
        vm.expectRevert(Error.ARRAY_LENGTH_MISMATCH.selector);

        superRegistry.setAmbAddress(ambId, ambAddress, broadcastAMB);
    }

    function test_setAmbAddress_array_mismatch_broadcastamb() public {
        uint8[] memory ambId = new uint8[](2);
        address[] memory ambAddress = new address[](2);
        bool[] memory broadcastAMB = new bool[](1);

        ambId[0] = 1;
        ambAddress[0] = address(0x1);
        ambId[1] = 3;
        ambAddress[1] = address(0x3);

        vm.startPrank(deployer);
        vm.expectRevert(Error.ARRAY_LENGTH_MISMATCH.selector);

        superRegistry.setAmbAddress(ambId, ambAddress, broadcastAMB);
    }

    function test_getStateRegistry_ZeroAddress() public {
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        superRegistry.getStateRegistry(22);
    }

    function test_setStateRegistryAddress_and_revert_zeroAddress_invalidCaller() public {
        uint8[] memory registryId = new uint8[](2);
        address[] memory registryAddress = new address[](2);

        registryId[0] = 4;
        registryAddress[0] = address(0);
        registryId[1] = 5;
        registryAddress[1] = address(0x3);

        vm.startPrank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        superRegistry.setStateRegistryAddress(registryId, registryAddress);
        registryAddress[0] = address(0x1);

        superRegistry.setStateRegistryAddress(registryId, registryAddress);

        assertEq(superRegistry.getStateRegistry(5), address(0x3));

        vm.expectRevert(Error.DISABLED.selector);
        vm.startPrank(deployer);
        superRegistry.setStateRegistryAddress(registryId, registryAddress);

        vm.stopPrank();

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        superRegistry.setStateRegistryAddress(registryId, registryAddress);

        assertEq(superRegistry.isValidStateRegistry(getContract(ETH, "CoreStateRegistry")), true);
    }

    function test_setStateRegistryAddress_arraylength_mismatch() public {
        uint8[] memory registryId = new uint8[](2);
        address[] memory registryAddress = new address[](1);

        registryId[0] = 1;
        registryAddress[0] = address(0x1);
        registryId[1] = 3;

        vm.expectRevert(Error.ARRAY_LENGTH_MISMATCH.selector);
        vm.startPrank(deployer);
        superRegistry.setStateRegistryAddress(registryId, registryAddress);
    }

    function test_setVaultLimitPerDestination() public {
        vm.prank(deployer);
        superRegistry.setVaultLimitPerDestination(1, 100);
        assertEq(superRegistry.getVaultLimitPerDestination(1), 100);

        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_INPUT_VALUE.selector);
        superRegistry.setVaultLimitPerDestination(1, 0);

        vm.prank(address(420));
        vm.expectRevert(Error.NOT_EMERGENCY_ADMIN.selector);
        superRegistry.setVaultLimitPerDestination(1, 100);
    }

    function test_setRequiredMessagingQuorum_and_revert_invalidCaller() public {
        vm.prank(deployer);
        superRegistry.setRequiredMessagingQuorum(OP, 2);
        assertEq(superRegistry.getRequiredMessagingQuorum(OP), 2);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        superRegistry.setRequiredMessagingQuorum(OP, 5);
    }

    function test_setDelay() public {
        vm.prank(deployer);
        vm.expectRevert(Error.INVALID_TIMELOCK_DELAY.selector);
        superRegistry.setDelay(5 minutes);

        vm.prank(deployer);
        vm.expectRevert(Error.INVALID_TIMELOCK_DELAY.selector);
        superRegistry.setDelay(48 hours);

        vm.prank(deployer);
        superRegistry.setDelay(11 hours);
    }

    function test_setQuorum_invalid_chainId() public {
        vm.prank(deployer);
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        superRegistry.setRequiredMessagingQuorum(0,2);
    }

    function test_getAmbId() public {
        uint256 ambId_ = superRegistry.getAmbId(getContract(ETH, "LayerzeroImplementation"));
        assertEq(ambId_, 1);
    }

    function test_getBridgeAddress_zero() public {
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        superRegistry.getBridgeAddress(10);
    }

    function test_getBridgeValidator_zero() public {
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        superRegistry.getBridgeValidator(10);
    }

    function _setAndAssert(bytes32 id_, address contractAddress) internal {
        vm.prank(deployer);
        bool isLocked = false;
        if (id_ == keccak256("SUPERFORM_FACTORY")) {
            vm.expectRevert(Error.DISABLED.selector);
            isLocked = true;
        } else if (id_ == keccak256("CORE_STATE_REGISTRY")) {
            vm.expectRevert(Error.DISABLED.selector);
            isLocked = true;
        } else if (id_ == keccak256("TIMELOCK_STATE_REGISTRY")) {
            vm.expectRevert(Error.DISABLED.selector);
            isLocked = true;
        } else if (id_ == keccak256("BROADCAST_REGISTRY")) {
            vm.expectRevert(Error.DISABLED.selector);
            isLocked = true;
        } else if (id_ == keccak256("SUPER_RBAC")) {
            vm.expectRevert(Error.DISABLED.selector);
            isLocked = true;
        } else if (id_ == keccak256("DST_SWAPPER")) {
            vm.expectRevert(Error.DISABLED.selector);
            isLocked = true;
        } else if (id_ == keccak256("EMERGENCY_QUEUE")) {
            vm.expectRevert(Error.DISABLED.selector);
            isLocked = true;
        } else if (id_ == keccak256("SUPER_POSITIONS")) {
            vm.expectRevert(Error.DISABLED.selector);
            isLocked = true;
        } else if (id_ == keccak256("SUPERFORM_ROUTER")) {
            vm.expectRevert(Error.DISABLED.selector);
            isLocked = true;
        }

        (bool success,) = address(superRegistry).call(
            abi.encodeWithSelector(superRegistry.setAddress.selector, id_, contractAddress, ETH)
        );
        if (!success) revert();

        address moduleAddress = superRegistry.getAddress(id_);
        assertNotEq(moduleAddress, address(0));

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        superRegistry.getAddressByChainId(keccak256(abi.encode("")), ETH);

        if (!isLocked) {
            if (id_ != superRegistry.SUPER_RBAC()) {
                vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
                vm.prank(bond);
                (bool success_,) = address(superRegistry).call(
                    abi.encodeWithSelector(superRegistry.setAddress.selector, id_, address(0x2), ETH)
                );
                if (!success_) revert();
            }
        }
    }

    function test_batchSetAddress_twoNewAddresses() public {
        vm.selectFork(FORKS[ETH]);

        // Define ids, newAddresses, and chainIds
        bytes32[] memory ids = new bytes32[](2);
        ids[0] = keccak256(abi.encodePacked("id1"));
        ids[1] = keccak256(abi.encodePacked("id2"));

        address[] memory newAddresses = new address[](2);
        newAddresses[0] = address(0x123);
        newAddresses[1] = address(0x456);

        uint64[] memory chainIds = new uint64[](2);
        chainIds[0] = 1;
        chainIds[1] = 1;

        // Call batchSetAddress
        vm.prank(deployer);
        superRegistry.batchSetAddress(ids, newAddresses, chainIds);

        // Verify the addresses were set correctly
        assertEq(superRegistry.getAddress(ids[0]), newAddresses[0]);
        assertEq(superRegistry.getAddress(ids[1]), newAddresses[1]);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {ISuperFormFactory} from "src/interfaces/ISuperFormFactory.sol";
import {ISuperRegistry} from "src/interfaces/ISuperRegistry.sol";
import {SuperFormFactory} from "src/SuperFormFactory.sol";
import {FactoryStateRegistry} from "src/crosschain-data/extensions/FactoryStateRegistry.sol";
import {ERC4626Form} from "src/forms/ERC4626Form.sol";
import {ERC4626TimelockForm} from "src/forms/ERC4626TimelockForm.sol";
import "src/test/utils/BaseSetup.sol";
import "src/test/utils/Utilities.sol";
import {Error} from "src/utils/Error.sol";
import "src/utils/DataPacking.sol";

contract SuperFormFactoryTest is BaseSetup {
    /// @dev emitted when a new form is entered into the factory
    /// @param form is the address of the new form
    /// @param formId is the id of the new form
    event FormCreated(address indexed form, uint256 indexed formId);

    /// @dev emitted when a new SuperForm is created
    /// @param formId is the id of the form
    /// @param vault is the address of the vault
    /// @param superFormId is the id of the superform - pair (form,vault)
    event SuperFormCreated(uint256 indexed formId, address indexed vault, uint256 indexed superFormId);

    uint64 internal chainId = ETH;

    function setUp() public override {
        super.setUp();
    }
    
    /// Testing superform creation by adding beacon
    /// TODO: Implement create2 in superform ID to assert superform address is same as the one provided
    function test_addForm() public {
        vm.startPrank(deployer);
        address formImplementation = address(new ERC4626Form(getContract(chainId, "SuperRegistry")));
        uint32 formBeaconId = 0;

        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(
            formImplementation,
            formBeaconId,
            salt
        );

    }

    /// Testing adding two beacons with same formBeaconId
    /// Should Revert With BEACON_ID_ALREADY_EXISTS
    function test_revert_addForm_sameBeaconID() public {
        
        address formImplementation1 = address(new ERC4626Form(getContract(chainId, "SuperRegistry")));
        address formImplementation2 = address(new ERC4626Form(getContract(chainId, "SuperRegistry")));
        uint32 formBeaconId = 0;

        vm.startPrank(deployer);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(
            formImplementation1,
            formBeaconId,
            salt
        );
        
        vm.expectRevert(Error.BEACON_ID_ALREADY_EXISTS.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(
            formImplementation2,
            formBeaconId,
            salt
        );

    }

    /// Testing adding form with form address 0
    /// Should Revert With ZERO_ADDRESS
    function test_revert_addForm_addressZero() public {
        address form = address(0);
        uint32 formId = 1;

        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(form, formId, salt);
    }

    /// Testing adding becon with wrong form
    /// Should Revert With ERC165_UNSUPPORTED
    function test_revert_addForm_interfaceUnsupported() public {
        address form = address(0x1);
        uint32 formId = 1;

        vm.prank(deployer);
        vm.expectRevert(Error.ERC165_UNSUPPORTED.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(form, formId, salt);
    }
}
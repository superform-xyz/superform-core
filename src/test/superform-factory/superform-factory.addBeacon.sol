// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {ISuperFormFactory} from "src/interfaces/ISuperFormFactory.sol";
import {ISuperRegistry} from "src/interfaces/ISuperRegistry.sol";
import {SuperFormFactory} from "src/SuperFormFactory.sol";
import {FactoryStateRegistry} from "src/crosschain-data/extensions/FactoryStateRegistry.sol";
import {ERC4626Form} from "src/forms/ERC4626Form.sol";
import {ERC4626TimelockForm} from "src/forms/ERC4626TimelockForm.sol";
import {FormBeacon} from "src/forms/FormBeacon.sol";
import "src/test/utils/BaseSetup.sol";
import "src/test/utils/Utilities.sol";
import {Error} from "src/utils/Error.sol";
import "src/utils/DataPacking.sol";

contract SuperFormFactoryAddBeaconTest is BaseSetup {
    /// @dev emitted when Beacon Is Added
    /// @param formImplementation is the address of the formImplementation
    /// @param beacon is the beacon address using create2
    /// @param formBeaconId is the beacon ID
    event FormBeaconAdded(address indexed formImplementation, address indexed beacon, uint256 indexed formBeaconId);

    uint64 internal chainId = ETH;

    function setUp() public override {
        super.setUp();
    }
    
    /// Testing superform creation by adding beacon
    function test_addForm() public {
        vm.startPrank(deployer);
        address formImplementation = address(new ERC4626Form(getContract(chainId, "SuperRegistry")));
        uint32 formBeaconId = 0;

        /// @dev create2 event
        address superformBeacon= address(new FormBeacon{salt: salt}(getContract(chainId, "SuperRegistry"), formImplementation));

        /// @dev FIXME: Need to fix the superformBeacon emitted
        vm.expectEmit(true, false, true, true);
        emit FormBeaconAdded(formImplementation, superformBeacon, formBeaconId);

        address beacon_returned = SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(
            formImplementation,
            formBeaconId,
            salt
        );
    }

    /// @dev Testing adding two beacons with same formBeaconId
    /// @dev Should Revert With BEACON_ID_ALREADY_EXISTS
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

    /// @dev Testing adding becon with wrong form
    /// @dev Should Revert With ERC165_UNSUPPORTED
    function test_revert_addForm_interfaceUnsupported() public {
        address form = address(0x1);
        uint32 formId = 1;

        vm.prank(deployer);
        vm.expectRevert(Error.ERC165_UNSUPPORTED.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(form, formId, salt);
    }
}
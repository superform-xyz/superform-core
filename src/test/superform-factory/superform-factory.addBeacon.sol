// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {ISuperFormFactory} from "../../interfaces/ISuperFormFactory.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {SuperFormFactory} from "../../SuperFormFactory.sol";
import {FactoryStateRegistry} from "../../crosschain-data/extensions/FactoryStateRegistry.sol";
import {ERC4626Form} from "../../forms/ERC4626Form.sol";
import {ERC4626TimelockForm} from "../../forms/ERC4626TimelockForm.sol";
import {FormBeacon} from "../../forms/FormBeacon.sol";
import "../utils/BaseSetup.sol";
import "../utils/Utilities.sol";
import {Error} from "../../utils/Error.sol";

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

    function getBytecodeFormBeacon(address superRegistry_, address formLogic_) public pure returns (bytes memory) {
        bytes memory bytecode = type(FormBeacon).creationCode;

        return abi.encodePacked(bytecode, abi.encode(superRegistry_, formLogic_));
    }

    /// Testing superform creation by adding beacon
    function test_addForm() public {
        address formImplementation = address(new ERC4626Form(getContract(chainId, "SuperRegistry")));
        uint32 formBeaconId = 0;

        /// @dev create2 address calculation
        bytes memory byteCode = getBytecodeFormBeacon(getContract(chainId, "SuperRegistry"), formImplementation);
        address superFormMockBeacon = getAddress(byteCode, salt, getContract(chainId, "SuperFormFactory"));

        address superFormMockBeacon2 = computeCreate2Address(
            salt,
            hashInitCode(
                type(FormBeacon).creationCode,
                abi.encode(getContract(chainId, "SuperRegistry"), formImplementation)
            ),
            getContract(chainId, "SuperFormFactory")
        );

        vm.startPrank(deployer);
        /// @dev Event With Beacon
        vm.expectEmit(true, true, true, true);
        emit FormBeaconAdded(formImplementation, superFormMockBeacon, formBeaconId);

        console.log("superFormMockBeacon", superFormMockBeacon);

        console.log("superFormMockBeacon2", superFormMockBeacon2);

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

        vm.prank(deployer);
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

    /// @dev Testing adding form with form address 0
    /// @dev Should Revert With ZERO_ADDRESS
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

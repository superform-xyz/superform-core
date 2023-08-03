// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {SuperFormFactory} from "../../SuperFormFactory.sol";
import {ERC4626Form} from "../../forms/ERC4626Form.sol";
import "../utils/BaseSetup.sol";
import {Error} from "../../utils/Error.sol";

contract SuperFormFactoryAddBeaconsTest is BaseSetup {
    uint64 internal chainId = ETH;

    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/
    uint32 constant MAX_FORMS = 2;

    function setUp() public override {
        super.setUp();
    }

    /// @dev Testing superform creation by adding multiple forms
    function test_addForms() public {
        vm.selectFork(FORKS[chainId]);

        vm.startPrank(deployer);

        address[] memory formImplementations = new address[](MAX_FORMS);
        uint32[] memory formBeaconIds = new uint32[](MAX_FORMS);

        for (uint32 i = 0; i < MAX_FORMS; i++) {
            formImplementations[i] = (address(new ERC4626Form(getContract(chainId, "SuperRegistry"))));
            formBeaconIds[i] = i + 10;
        }

        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacons(
            formImplementations,
            formBeaconIds,
            salt
        );
    }

    /// @dev Testing adding same beacon id multiple times
    /// @dev Should Revert With BEACON_ID_ALREADY_EXISTS
    function test_revert_addForms_sameBeaconID() public {
        vm.selectFork(FORKS[chainId]);

        address[] memory formImplementations = new address[](MAX_FORMS);
        uint32[] memory formBeaconIds = new uint32[](MAX_FORMS);
        uint32 FORM_BEACON_ID = 0;

        for (uint32 i = 0; i < MAX_FORMS; i++) {
            formImplementations[i] = address(new ERC4626Form(getContract(chainId, "SuperRegistry")));
            formBeaconIds[i] = FORM_BEACON_ID;
        }

        vm.prank(deployer);

        vm.expectRevert(Error.BEACON_ID_ALREADY_EXISTS.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacons(
            formImplementations,
            formBeaconIds,
            salt
        );
    }

    /// @dev Testing adding form with form address 0
    /// @dev Should Revert With ZERO_ADDRESS
    function test_revert_addForms_addressZero() public {
        vm.selectFork(FORKS[chainId]);

        address[] memory formImplementations = new address[](MAX_FORMS);
        uint32[] memory formBeaconIds = new uint32[](MAX_FORMS);

        /// Providing zero address to each of the forms
        for (uint32 i = 0; i < MAX_FORMS; i++) {
            formImplementations[i] = address(0);
            formBeaconIds[i] = i;
        }

        vm.prank(deployer);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacons(
            formImplementations,
            formBeaconIds,
            salt
        );
    }

    /// Testing adding form with wrong form
    /// Should Revert With ERC165_UNSUPPORTED
    function test_revert_addForm_interfaceUnsupported() public {
        vm.selectFork(FORKS[chainId]);

        address[] memory formImplementations = new address[](MAX_FORMS);
        uint32[] memory formBeaconIds = new uint32[](MAX_FORMS);

        /// Keeping all but one beacon with right form
        for (uint32 i = 0; i < MAX_FORMS - 1; i++) {
            formImplementations[i] = address(new ERC4626Form(getContract(chainId, "SuperRegistry")));
            formBeaconIds[i] = i;
        }

        /// Last Beacon with wrong form
        formImplementations[MAX_FORMS - 1] = address(0x1);
        formBeaconIds[MAX_FORMS - 1] = formBeaconIds[MAX_FORMS - 2] + 1;

        vm.prank(deployer);

        vm.expectRevert(Error.ERC165_UNSUPPORTED.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacons(
            formImplementations,
            formBeaconIds,
            salt
        );
    }
}

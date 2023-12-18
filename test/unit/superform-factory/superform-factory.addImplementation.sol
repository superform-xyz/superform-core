// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { SuperformFactory } from "src/SuperformFactory.sol";
import { ERC4626Form } from "src/forms/ERC4626Form.sol";
import "test/utils/BaseSetup.sol";
import { Error } from "src/libraries/Error.sol";

contract SuperformFactoryAddImplementationTest is BaseSetup {
    uint64 internal chainId = ETH;
    /// @dev emitted when a new formImplementation is entered into the factory
    /// @param formImplementation is the address of the new form implementation
    /// @param formImplementationId is the id of the formImplementation

    event FormImplementationAdded(address indexed formImplementation, uint256 indexed formImplementationId);

    function setUp() public override {
        super.setUp();
    }

    /// Testing superform creation by adding form
    function test_addForm() public {
        vm.selectFork(FORKS[chainId]);

        address formImplementation = address(new ERC4626Form(getContract(chainId, "SuperRegistry")));
        uint32 formImplementationId = 44;

        vm.startPrank(deployer);
        /// @dev Event With Implementation
        vm.expectEmit(true, true, true, true);
        emit FormImplementationAdded(formImplementation, formImplementationId);

        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );
    }

    /// @dev Testing adding two forms with same formImplementationId
    /// @dev Should Revert With FORM_IMPLEMENTATION_ID_ALREADY_EXISTS
    function test_revert_addForm_sameformImplementationId() public {
        vm.selectFork(FORKS[chainId]);

        address formImplementation1 = address(new ERC4626Form(getContract(chainId, "SuperRegistry")));
        address formImplementation2 = address(new ERC4626Form(getContract(chainId, "SuperRegistry")));
        uint32 formImplementationId = 44;

        vm.startPrank(deployer);
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation1, formImplementationId
        );
        address imp =
            SuperformFactory(getContract(chainId, "SuperformFactory")).getFormImplementation(formImplementationId);
        assertEq(imp, formImplementation1);
        vm.expectRevert(Error.FORM_IMPLEMENTATION_ALREADY_EXISTS.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation2, formImplementationId
        );

        vm.expectRevert(Error.FORM_IMPLEMENTATION_ID_ALREADY_EXISTS.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(formImplementation1, 555);
    }

    /// @dev Testing adding form with form address 0
    /// @dev Should Revert With ZERO_ADDRESS
    function test_revert_addForm_addressZero() public {
        vm.selectFork(FORKS[chainId]);

        address form = address(0);
        uint32 formId = 1;

        vm.prank(deployer);
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(form, formId);
    }

    /// @dev Testing adding becon with wrong form
    /// @dev Should Revert With ERC165_UNSUPPORTED
    function test_revert_addForm_interfaceUnsupported() public {
        vm.selectFork(FORKS[chainId]);

        address form = address(0x1);
        uint32 formId = 1;

        vm.prank(deployer);
        vm.expectRevert(Error.ERC165_UNSUPPORTED.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(form, formId);
    }
}

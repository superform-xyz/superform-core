// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {Utilities} from "./utils/Utilities.sol";
import "forge-std/console.sol";

import {ISuperFormFactory} from "../interfaces/ISuperFormFactory.sol";
import {SuperFormFactory} from "../SuperFormFactory.sol";
import {ERC4626Form} from "../forms/ERC4626Form.sol";
import "../utils/DataPacking.sol";

contract SuperFormFactoryTest is Utilities {
    /// @dev emitted when a new form is entered into the factory
    /// @param form is the address of the new form
    /// @param formId is the id of the new form
    event FormCreated(address indexed form, uint256 indexed formId);

    /// @dev emitted when a new SuperForm is created
    /// @param formId is the id of the form
    /// @param vault is the address of the vault
    /// @param superFormId is the id of the superform - pair (form,vault)
    event SuperFormCreated(
        uint256 indexed formId,
        address indexed vault,
        uint256 indexed superFormId
    );

    address payable[] internal users;

    SuperFormFactory internal superFormFactory;
    uint16 internal chainId;
    address payable internal admin;

    function setUp() public {
        users = createUsers(5);
        admin = users[0];
        vm.label(admin, "Admin");
        chainId = uint16(block.chainid);
        vm.prank(admin);
        superFormFactory = new SuperFormFactory(chainId);
    }

    function test_chainId() public {
        assertEq(chainId, superFormFactory.chainId());
    }

    function test_revert_addForm_addressZero() public {
        address form = address(0);
        uint256 formId = 1;

        vm.prank(admin);
        vm.expectRevert(ISuperFormFactory.ZERO_ADDRESS.selector);
        superFormFactory.addForm(form, formId);
    }

    function test_revert_addForm_interfaceUnsupported() public {
        address form = address(0x1);
        uint256 formId = 1;

        vm.prank(admin);
        vm.expectRevert(ISuperFormFactory.ERC165_UNSUPPORTED.selector);
        superFormFactory.addForm(form, formId);
    }

    function test_addForm() public {
        vm.startPrank(admin);
        address form = address(new ERC4626Form(chainId, superFormFactory));
        uint256 formId = 1;

        vm.expectEmit(true, true, true, true, address(superFormFactory));
        emit FormCreated(form, 1);
        superFormFactory.addForm(form, formId);

        assertEq(formId, 1);
    }

    struct TestArgs {
        address form;
        uint256 formId;
        address vault1;
        address vault2;
        uint256 expectedSuperFormId1;
        uint256 superFormId;
    }

    function test_createSuperForm() public {
        TestArgs memory vars;
        vm.startPrank(admin);
        vars.form = address(new ERC4626Form(chainId, superFormFactory));
        vars.formId = 1;

        superFormFactory.addForm(vars.form, vars.formId);

        /// @dev as you can see we are not testing if the vaults are eoas or actual compliant contracts
        vars.vault1 = address(0x2);
        vars.vault2 = address(0x3);

        vars.expectedSuperFormId1 = uint256(uint160(vars.vault1));
        vars.expectedSuperFormId1 |= vars.formId << 160;
        vars.expectedSuperFormId1 |= uint256(chainId) << 176;

        vm.expectEmit(true, true, true, true, address(superFormFactory));
        emit SuperFormCreated(
            vars.formId,
            vars.vault1,
            vars.expectedSuperFormId1
        );
        uint256 superFormId = superFormFactory.createSuperForm(
            vars.formId,
            vars.vault1
        );

        assertEq(superFormId, vars.expectedSuperFormId1);

        vm.stopPrank();

        /// @dev test getSuperForm
        (
            address resVault,
            uint256 resFormid,
            uint16 resChainId
        ) = _getSuperForm(vars.superFormId);

        assertEq(resChainId, chainId);
        assertEq(resFormid, vars.formId);
        assertEq(resVault, vars.vault1);

        /// @dev add new vault
        uint256 expectedSuperFormId2 = uint256(uint160(vars.vault2));
        expectedSuperFormId2 |= vars.formId << 160;
        expectedSuperFormId2 |= uint256(chainId) << 176;
        vm.expectEmit(true, true, true, true, address(superFormFactory));
        emit SuperFormCreated(vars.formId, vars.vault2, expectedSuperFormId2);
        superFormFactory.createSuperForm(vars.formId, vars.vault2);

        /// @dev test getSuperFormFromVault
        uint256[] memory superFormIds_;
        uint256[] memory formIds_;
        uint16[] memory chainIds_;
        uint256[] memory transformedChainIds_;
        (superFormIds_, formIds_, chainIds_) = superFormFactory
            .getAllSuperFormsFromVault(vars.vault1);

        for (uint256 i = 0; i < chainIds_.length; i++) {
            transformedChainIds_[i] = uint256(chainIds_[i]);
        }

        uint256[] memory expectedSuperFormIds = new uint256[](1);
        expectedSuperFormIds[0] = vars.expectedSuperFormId1;

        uint256[] memory expectedFormIds = new uint256[](1);
        expectedFormIds[0] = vars.formId;

        uint256[] memory expectedChainIds = new uint256[](1);
        expectedChainIds[0] = chainId;

        assertEq(superFormIds_, expectedSuperFormIds);
        assertEq(formIds_, expectedFormIds);
        assertEq(transformedChainIds_, expectedChainIds);

        /// @dev test getAllSuperForms
        address[] memory vaults_;
        (superFormIds_, vaults_, formIds_, chainIds_) = superFormFactory
            .getAllSuperForms();

        for (uint256 i = 0; i < chainIds_.length; i++) {
            transformedChainIds_[i] = uint256(chainIds_[i]);
        }
        expectedSuperFormIds = new uint256[](2);
        expectedSuperFormIds[0] = vars.expectedSuperFormId1;
        expectedSuperFormIds[1] = expectedSuperFormId2;

        expectedFormIds = new uint256[](2);
        expectedFormIds[0] = vars.formId;
        expectedFormIds[1] = vars.formId;

        expectedChainIds = new uint256[](2);
        expectedChainIds[0] = chainId;
        expectedChainIds[1] = chainId;

        address[] memory expectedVaults = new address[](2);
        expectedVaults[0] = vars.vault1;
        expectedVaults[1] = vars.vault2;

        assertEq(superFormIds_, expectedSuperFormIds);
        assertEq(vaults_, expectedVaults);
        assertEq(formIds_, expectedFormIds);
        assertEq(transformedChainIds_, expectedChainIds);

        assertEq(superFormFactory.getAllFormsList(), 1);
        assertEq(superFormFactory.getAllSuperFormsList(), 2);
        assertEq(superFormFactory.getAllChainSuperFormsList(), 2);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "forge-std/console.sol";
import {ISuperFormFactory} from "../interfaces/ISuperFormFactory.sol";
import {SuperFormFactory} from "../SuperFormFactory.sol";
import {ERC4626Form} from "../forms/ERC4626Form.sol";
import "./utils/BaseSetup.sol";
import "./utils/Utilities.sol";

contract SuperFormFactoryTest is BaseSetup {
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

    uint16 internal chainId = chainIds[0];

    function setUp() public override {
        super.setUp();
    }

    function test_chainId() public {
        assertEq(
            chainId,
            SuperFormFactory(getContract(chainIds[0], "SuperFormFactory")).chainId()
        );
    }

    function test_revert_addForm_addressZero() public {
        address form = address(0);
        uint256 formId = 1;

        vm.prank(deployer);
        vm.expectRevert(ISuperFormFactory.ZERO_ADDRESS.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addForm(
            form,
            formId
        );
    }

    function test_revert_addForm_interfaceUnsupported() public {
        address form = address(0x1);
        uint256 formId = 1;

        vm.prank(deployer);
        vm.expectRevert(ISuperFormFactory.ERC165_UNSUPPORTED.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addForm(
            form,
            formId
        );
    }

    function test_addForm() public {
        vm.startPrank(deployer);
        address form = address(
            new ERC4626Form(
                chainId,
                ISuperFormFactory(getContract(chainId, "SuperFormFactory"))
            )
        );
        uint256 formId = 1;

        vm.expectEmit(
            true,
            true,
            true,
            true,
            getContract(chainId, "SuperFormFactory")
        );
        emit FormCreated(form, 1);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addForm(
            form,
            formId
        );

        assertEq(formId, 1);
    }

    struct TestArgs {
        address form;
        uint256 formId;
        address vault1;
        address vault2;
        uint256 expectedSuperFormId1;
        uint256 expectedSuperFormId2;
        uint256 superFormId;
        address resVault;
        uint256 resFormid;
        uint16 resChainId;
        uint256[] superFormIds_;
        uint256[] formIds_;
        uint16[] chainIds_;
        uint256[] transformedChainIds_;
        uint256[] expectedSuperFormIds;
        uint256[] expectedFormIds;
        uint256[] expectedChainIds;
        address[] vaults_;
        address[] expectedVaults;
    }

    function test_createSuperForm() public {
        TestArgs memory vars;
        vm.startPrank(deployer);
        vars.form = address(
            new ERC4626Form(
                chainId,
                ISuperFormFactory(getContract(chainId, "SuperFormFactory"))
            )
        );
        vars.formId = 1;

        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addForm(
            vars.form,
            vars.formId
        );

        /// @dev as you can see we are not testing if the vaults are eoas or actual compliant contracts
        vars.vault1 = address(0x2);
        vars.vault2 = address(0x3);

        vars.expectedSuperFormId1 = uint256(uint160(vars.vault1));
        vars.expectedSuperFormId1 |= vars.formId << 160;
        vars.expectedSuperFormId1 |= uint256(chainId) << 240;

        vm.expectEmit(
            true,
            true,
            true,
            true,
            getContract(chainId, "SuperFormFactory")
        );
        emit SuperFormCreated(
            vars.formId,
            vars.vault1,
            vars.expectedSuperFormId1
        );

        console.log("----FACTORY----");
        console.log(
            address(
                SuperFormFactory(getContract(chainId, "SuperFormFactory"))
                    .factoryRegistry()
            )
        );
        vars.superFormId = SuperFormFactory(
            getContract(chainId, "SuperFormFactory")
        ).createSuperForm{value: 5 * 10 ** 18}(vars.formId, vars.vault1);

        assertEq(vars.superFormId, vars.expectedSuperFormId1);

        vm.stopPrank();

        /// @dev test getSuperForm
        // (vars.resVault, vars.resFormid, vars.resChainId) = _getSuperForm(
        //     vars.superFormId
        // );

        // assertEq(vars.resChainId, chainId);
        // assertEq(vars.resFormid, vars.formId);
        // assertEq(vars.resVault, vars.vault1);

        /// @dev add new vault
        vars.expectedSuperFormId2 = uint256(uint160(vars.vault2));
        vars.expectedSuperFormId2 |= vars.formId << 160;
        vars.expectedSuperFormId2 |= uint256(chainId) << 240;
        vm.expectEmit(
            true,
            true,
            true,
            true,
            getContract(chainId, "SuperFormFactory")
        );
        emit SuperFormCreated(
            vars.formId,
            vars.vault2,
            vars.expectedSuperFormId2
        );
        SuperFormFactory(getContract(chainId, "SuperFormFactory"))
            .createSuperForm{value: 5 * 10 ** 18}(vars.formId, vars.vault2);

        /// @dev test getSuperFormFromVault

        (vars.superFormIds_, vars.formIds_, vars.chainIds_) = SuperFormFactory(
            getContract(chainId, "SuperFormFactory")
        ).getAllSuperFormsFromVault(vars.vault1);

        vars.transformedChainIds_ = new uint256[](vars.chainIds_.length);

        for (uint256 i = 0; i < vars.chainIds_.length; i++) {
            vars.transformedChainIds_[i] = uint256(vars.chainIds_[i]);
        }

        vars.expectedSuperFormIds = new uint256[](1);
        vars.expectedSuperFormIds[0] = vars.expectedSuperFormId1;

        vars.expectedFormIds = new uint256[](1);
        vars.expectedFormIds[0] = vars.formId;

        vars.expectedChainIds = new uint256[](1);
        vars.expectedChainIds[0] = chainId;

        assertEq(vars.superFormIds_, vars.expectedSuperFormIds);
        assertEq(vars.formIds_, vars.expectedFormIds);
        assertEq(vars.transformedChainIds_, vars.expectedChainIds);

        /// @dev test getAllSuperForms

        (
            vars.superFormIds_,
            vars.vaults_,
            vars.formIds_,
            vars.chainIds_
        ) = SuperFormFactory(getContract(chainId, "SuperFormFactory"))
            .getAllSuperForms();

        vars.transformedChainIds_ = new uint256[](vars.chainIds_.length);

        for (uint256 i = 0; i < vars.chainIds_.length; i++) {
            vars.transformedChainIds_[i] = uint256(vars.chainIds_[i]);
        }
        vars.expectedSuperFormIds = new uint256[](2);
        vars.expectedSuperFormIds[0] = vars.expectedSuperFormId1;
        vars.expectedSuperFormIds[1] = vars.expectedSuperFormId2;

        vars.expectedFormIds = new uint256[](2);
        vars.expectedFormIds[0] = vars.formId;
        vars.expectedFormIds[1] = vars.formId;

        vars.expectedChainIds = new uint256[](2);
        vars.expectedChainIds[0] = chainId;
        vars.expectedChainIds[1] = chainId;

        vars.expectedVaults = new address[](2);
        vars.expectedVaults[0] = vars.vault1;
        vars.expectedVaults[1] = vars.vault2;

        assertEq(vars.superFormIds_, vars.expectedSuperFormIds);
        assertEq(vars.vaults_, vars.expectedVaults);
        assertEq(vars.formIds_, vars.expectedFormIds);
        assertEq(vars.transformedChainIds_, vars.expectedChainIds);

        assertEq(
            SuperFormFactory(getContract(chainId, "SuperFormFactory"))
                .getAllFormsList(),
            1
        );
        assertEq(
            SuperFormFactory(getContract(chainId, "SuperFormFactory"))
                .getAllSuperFormsList(),
            2
        );
        assertEq(
            SuperFormFactory(getContract(chainId, "SuperFormFactory"))
                .getAllChainSuperFormsList(),
            2
        );
    }
}

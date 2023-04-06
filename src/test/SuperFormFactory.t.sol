// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "forge-std/console.sol";
import {ISuperFormFactory} from "../interfaces/ISuperFormFactory.sol";
import {SuperFormFactory} from "../SuperFormFactory.sol";
import {FactoryStateRegistry} from "../crosschain-data/FactoryStateRegistry.sol";
import {ERC4626Form} from "../forms/ERC4626Form.sol";
import "./utils/BaseSetup.sol";
import "./utils/Utilities.sol";
import "../utils/DataPacking.sol";

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

    uint16 internal chainId = ETH;

    function setUp() public override {
        super.setUp();
    }

    function xtest_chainId() public {
        vm.selectFork(FORKS[chainId]);

        assertEq(
            chainId,
            SuperFormFactory(getContract(chainId, "SuperFormFactory")).chainId()
        );
    }

    function xtest_revert_addForm_addressZero() public {
        address form = address(0);
        uint256 formId = 1;

        vm.prank(deployer);
        vm.expectRevert(ISuperFormFactory.ZERO_ADDRESS.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory"))
            .addFormBeacon(form, formId);
    }

    function xtest_revert_addForm_interfaceUnsupported() public {
        address form = address(0x1);
        uint256 formId = 1;

        vm.prank(deployer);
        vm.expectRevert(ISuperFormFactory.ERC165_UNSUPPORTED.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory"))
            .addFormBeacon(form, formId);
    }

    function xtest_addForm() public {
        vm.startPrank(deployer);
        address formImplementation = address(new ERC4626Form());
        uint256 formBeaconId = 1;

        /*
        /// @dev FIXME: cannot predict address of beacon
        vm.expectEmit(
            true,
            true,
            true,
            true,
            getContract(chainId, "SuperFormFactory")
        );
        emit FormCreated(form, 1);
        */
        SuperFormFactory(getContract(chainId, "SuperFormFactory"))
            .addFormBeacon(formImplementation, formBeaconId);

        //assertEq(formId, 1);
    }

    struct TestArgs {
        address formImplementation;
        uint256 formBeaconId;
        address vault1;
        address vault2;
        uint256 expectedSuperFormId1;
        uint256 expectedSuperFormId2;
        uint256 superFormId;
        address superForm;
        address resSuperForm;
        uint256 resFormid;
        uint16 resChainId;
        uint256[] superFormIds_;
        uint256[] formIds_;
        uint16[] chainIds_;
        uint256[] transformedChainIds_;
        uint256[] expectedSuperFormIds;
        uint256[] expectedFormIds;
        uint256[] expectedChainIds;
        address[] superForms_;
        address[] expectedVaults;
    }

    /// @dev FIXME: should have assertions for superForm addresses and ids (if we can predict them)
    function test_base_setup_superForms() public {
        TestArgs memory vars;
        vm.startPrank(deployer);
        vm.selectFork(FORKS[chainId]);
        vars.formImplementation = address(new ERC4626Form());

        vars.formBeaconId = 1;

        SuperFormFactory(getContract(chainId, "SuperFormFactory"))
            .addFormBeacon(vars.formImplementation, vars.formBeaconId);

        //console.log(FactoryStateRegistry(payable(getContract(chainIds[1], "FactoryStateRegistry")))
        //    .payloadsCount());

        /// @dev as you can see we are not testing if the vaults are eoas or actual compliant contracts
        vars.vault1 = address(0x2);
        vars.vault2 = address(0x3);

        /// @dev test getAllSuperForms

        (
            vars.superFormIds_,
            vars.superForms_,
            vars.formIds_,
            vars.chainIds_
        ) = SuperFormFactory(getContract(chainId, "SuperFormFactory"))
            .getAllSuperForms();

        vars.transformedChainIds_ = new uint256[](vars.chainIds_.length);

        for (uint256 i = 0; i < vars.chainIds_.length; i++) {
            vars.transformedChainIds_[i] = uint256(vars.chainIds_[i]);
        }

        vars.expectedFormIds = new uint256[](18);
        vars.expectedFormIds[0] = vars.formBeaconId;
        vars.expectedFormIds[1] = vars.formBeaconId;
        vars.expectedFormIds[2] = vars.formBeaconId;
        vars.expectedFormIds[3] = vars.formBeaconId;
        vars.expectedFormIds[4] = vars.formBeaconId;
        vars.expectedFormIds[5] = vars.formBeaconId;
        vars.expectedFormIds[6] = vars.formBeaconId;
        vars.expectedFormIds[7] = vars.formBeaconId;
        vars.expectedFormIds[8] = vars.formBeaconId;
        vars.expectedFormIds[9] = vars.formBeaconId;
        vars.expectedFormIds[10] = vars.formBeaconId;
        vars.expectedFormIds[11] = vars.formBeaconId;
        vars.expectedFormIds[12] = vars.formBeaconId;
        vars.expectedFormIds[13] = vars.formBeaconId;
        vars.expectedFormIds[14] = vars.formBeaconId;
        vars.expectedFormIds[15] = vars.formBeaconId;
        vars.expectedFormIds[16] = vars.formBeaconId;
        vars.expectedFormIds[17] = vars.formBeaconId;

        vars.expectedChainIds = new uint256[](18);
        vars.expectedChainIds[0] = chainId;
        vars.expectedChainIds[1] = chainId;
        vars.expectedChainIds[2] = chainId;
        vars.expectedChainIds[3] = chainIds[1];
        vars.expectedChainIds[4] = chainIds[1];
        vars.expectedChainIds[5] = chainIds[1];
        vars.expectedChainIds[6] = chainIds[2];
        vars.expectedChainIds[7] = chainIds[2];
        vars.expectedChainIds[8] = chainIds[2];
        vars.expectedChainIds[9] = chainIds[3];
        vars.expectedChainIds[10] = chainIds[3];
        vars.expectedChainIds[11] = chainIds[3];
        vars.expectedChainIds[12] = chainIds[4];
        vars.expectedChainIds[13] = chainIds[4];
        vars.expectedChainIds[14] = chainIds[4];
        vars.expectedChainIds[15] = chainIds[5];
        vars.expectedChainIds[16] = chainIds[5];
        vars.expectedChainIds[17] = chainIds[5];

        assertEq(vars.formIds_, vars.expectedFormIds);
        assertEq(vars.transformedChainIds_, vars.expectedChainIds);

        assertEq(
            SuperFormFactory(getContract(chainId, "SuperFormFactory"))
                .getAllSuperFormsList(),
            18
        ); /// 1 chain = 3; 6 chains = 6 * 3
    }
}

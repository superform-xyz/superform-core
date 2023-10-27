// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import { SuperformFactory } from "src/SuperformFactory.sol";
import { ERC4626Form } from "src/forms/ERC4626Form.sol";
import { ERC4626FormInterfaceNotSupported } from "test/mocks/InterfaceNotSupported/ERC4626InterFaceNotSupported.sol";
import "test/utils/BaseSetup.sol";
import { Error } from "src/utils/Error.sol";

contract SuperformFactoryCreateSuperformTest is BaseSetup {
    uint64 internal chainId = ETH;
    address public vault;

    function setUp() public override {
        super.setUp();

        /// @dev ERC4626 DAI vault on chainId
        vault = address(
            vaults[chainId][FORM_IMPLEMENTATION_IDS[0]][0][vaultBytecodes2[FORM_IMPLEMENTATION_IDS[0]]
                .vaultBytecode
                .length - 1]
        );
    }

    struct UtilityArgs {
        address formImplementation1;
        address formImplementation2;
        uint32 formformImplementationId1;
        uint32 formformImplementationId2;
        address vault1;
        address vault2;
        uint256 expectedSuperformId1;
        uint256 expectedSuperformId2;
        uint256 superformId;
        address superform;
        address resSuperform;
        uint256 resFormid;
        uint64 resChainId;
        uint256[] superformIds_;
        uint64[] chainIds_;
        uint32[] formIds_;
        uint256[] transformedChainIds_;
        uint256[] expectedSuperformIds;
        uint32[] expectedFormformImplementationIds;
        uint256[] expectedChainIds;
        address[] superforms_;
        address[] expectedVaults;
    }

    function test_utility_superforms() public {
        UtilityArgs memory vars;
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        /// @dev testing the getAllSuperforms function
        (vars.superformIds_, vars.superforms_) =
            SuperformFactory(getContract(chainId, "SuperformFactory")).getAllSuperforms();

        assertEq(vars.superformIds_.length, vars.superforms_.length);

        /// @dev Testing Coss Chain Superform Deployments
        vars.transformedChainIds_ = new uint256[](vars.chainIds_.length);

        for (uint256 j; j < vars.chainIds_.length; j++) {
            vars.transformedChainIds_[j] = uint256(vars.chainIds_[j]);
        }

        vars.expectedFormformImplementationIds = new uint32[](chainIds.length * UNDERLYING_TOKENS.length);
        vars.expectedChainIds = new uint256[](chainIds.length * UNDERLYING_TOKENS.length);

        uint256 expectedNumberOfSuperforms = UNDERLYING_TOKENS.length * VAULT_KINDS.length;

        assertEq(
            SuperformFactory(getContract(chainId, "SuperformFactory")).getSuperformCount(), expectedNumberOfSuperforms
        );
    }

    function test_base_setup_superforms() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formImplementationId = 0;

        // Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );

        uint256 totalSuperformsBefore = SuperformFactory(getContract(chainId, "SuperformFactory")).getSuperformCount();

        /// @dev Creating superform using form
        (uint256 superformIdCreated, address superformCreated) =
            SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(formImplementationId, vault);

        (uint256[] memory superformIds_, address[] memory superforms_) =
            SuperformFactory(getContract(chainId, "SuperformFactory")).getAllSuperformsFromVault(vault);

        assertEq(superformIdCreated, superformIds_[superformIds_.length - 1]);

        assertEq(superformCreated, superforms_[superforms_.length - 1]);

        uint256 totalSuperformsAfter = SuperformFactory(getContract(chainId, "SuperformFactory")).getSuperformCount();
        assertEq(totalSuperformsAfter, totalSuperformsBefore + 1);

        uint256 totalFormImplementations = SuperformFactory(getContract(chainId, "SuperformFactory")).getFormCount();
        assertEq(totalFormImplementations, 4);

        bool superformExists =
            SuperformFactory(getContract(chainId, "SuperformFactory")).isSuperform(superformIdCreated);
        assertEq(superformExists, true);
    }

    function test_revert_createSuperform_addressZero() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation1 = address(new ERC4626Form(superRegistry));
        uint32 formImplementationId = 0;

        /// Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation1, formImplementationId
        );

        /// @dev Creating superform using form
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(formImplementationId, address(0));
    }

    function test_revert_createSuperform_vaultImplementationCombinationExists() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formImplementationId = 0;

        // Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );

        /// @dev Creating superform using form
        SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(formImplementationId, vault);

        /// @dev Creating superform using same form and vault
        vm.expectRevert(Error.VAULT_FORM_IMPLEMENTATION_COMBINATION_EXISTS.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(formImplementationId, vault);
    }

    function test_revert_createSuperform_interfaceNotSupported() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626FormInterfaceNotSupported(superRegistry));
        uint32 formImplementationId = 0;

        // Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        vm.expectRevert(Error.FORM_INTERFACE_UNSUPPORTED.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );
    }

    function test_revert_createSuperform_formDoesNotExist() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        /// @dev random form form id
        uint32 formImplementationId = 4_000_000_000;

        /// @dev Creating superform using same form and vault
        vm.expectRevert(Error.FORM_DOES_NOT_EXIST.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(formImplementationId, vault);
    }
}

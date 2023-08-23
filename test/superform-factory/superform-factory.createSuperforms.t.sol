// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { SuperformFactory } from "src/SuperformFactory.sol";
import { ERC4626Form } from "src/forms/ERC4626Form.sol";
import { ERC4626FormInterfaceNotSupported } from "../mocks/InterfaceNotSupported/ERC4626InterFaceNotSupported.sol";
import "../utils/BaseSetup.sol";
import { Error } from "src/utils/Error.sol";

contract SuperformFactoryCreateSuperformTest is BaseSetup {
    uint64 internal chainId = ETH;
    address public vault;

    function setUp() public override {
        super.setUp();

        /// @dev ERC4626 DAI vault on chainId
        vault = address(
            vaults[chainId][FORM_BEACON_IDS[0]][0][vaultBytecodes2[FORM_BEACON_IDS[0]].vaultBytecode.length - 1]
        );
    }

    struct UtilityArgs {
        address formImplementation1;
        address formImplementation2;
        uint32 formBeaconId1;
        uint32 formBeaconId2;
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
        uint32[] expectedFormBeaconIds;
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

        vars.expectedFormBeaconIds = new uint32[](chainIds.length * UNDERLYING_TOKENS.length);
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
        uint32 formBeaconId = 0;

        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(formImplementation, formBeaconId, salt);

        uint256 totalSuperformsBefore = SuperformFactory(getContract(chainId, "SuperformFactory")).getSuperformCount();

        /// @dev Creating superform using beacon
        (uint256 superformIdCreated, address superformCreated) =
            SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(formBeaconId, vault);

        (uint256[] memory superformIds_, address[] memory superforms_) =
            SuperformFactory(getContract(chainId, "SuperformFactory")).getAllSuperformsFromVault(vault);

        assertEq(superformIdCreated, superformIds_[superformIds_.length - 1]);

        assertEq(superformCreated, superforms_[superforms_.length - 1]);

        uint256 totalSuperformsAfter = SuperformFactory(getContract(chainId, "SuperformFactory")).getSuperformCount();
        assertEq(totalSuperformsAfter, totalSuperformsBefore + 1);

        uint256 totalFormBeacons = SuperformFactory(getContract(chainId, "SuperformFactory")).getFormCount();
        assertEq(totalFormBeacons, 4);
    }

    function test_revert_createSuperform_addressZero() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation1 = address(new ERC4626Form(superRegistry));
        uint32 formBeaconId = 0;

        /// Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(
            formImplementation1, formBeaconId, salt
        );

        /// @dev Creating superform using beacon
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(formBeaconId, address(0));
    }

    function test_revert_createSuperform_vaultBeaconCombinationExists() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formBeaconId = 0;

        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(formImplementation, formBeaconId, salt);

        /// @dev Creating superform using beacon
        SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(formBeaconId, vault);

        /// @dev Creating superform using same beacon and vault
        vm.expectRevert(Error.VAULT_BEACON_COMBNATION_EXISTS.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(formBeaconId, vault);
    }

    function test_revert_createSuperform_interfaceNotSupported() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626FormInterfaceNotSupported(superRegistry));
        uint32 formBeaconId = 0;

        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        vm.expectRevert(Error.FORM_INTERFACE_UNSUPPORTED.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(formImplementation, formBeaconId, salt);
    }

    function test_revert_createSuperform_formDoesNotExist() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        /// @dev random form beacon id
        uint32 formBeaconId = 4_000_000_000;

        /// @dev Creating superform using same beacon and vault
        vm.expectRevert(Error.FORM_DOES_NOT_EXIST.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(formBeaconId, vault);
    }

    function test_createSuperforms() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formBeaconId = 0;
        // uint32 formBeaconId_2 = 1100;
        // uint32 formBeaconId_3 = 1111;

        uint32[] memory formBeaconIds_ = new uint32[](3);
        formBeaconIds_[0] = formBeaconId;
        formBeaconIds_[1] = formBeaconId;
        formBeaconIds_[2] = formBeaconId;

        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(formImplementation, formBeaconId, salt);

        /// @dev USDT vault
        address vault_2 = address(
            vaults[chainId][FORM_BEACON_IDS[0]][1][vaultBytecodes2[FORM_BEACON_IDS[0]].vaultBytecode.length - 1]
        );
        /// @dev WETH vault
        address vault_3 = address(
            vaults[chainId][FORM_BEACON_IDS[0]][2][vaultBytecodes2[FORM_BEACON_IDS[0]].vaultBytecode.length - 1]
        );

        address[] memory vaults_ = new address[](3);
        vaults_[0] = vault;
        vaults_[1] = vault_2;
        vaults_[2] = vault_3;

        uint256 totalSuperformsBefore = SuperformFactory(getContract(chainId, "SuperformFactory")).getSuperformCount();

        /// @dev Creating 3 superforms using same beacon and 3 different vaults
        (uint256[] memory superFormIdsCreated, address[] memory superFormsCreated) =
            SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperforms(formBeaconIds_, vaults_);

        /// @dev check first superform creation
        (uint256[] memory superFormIds_, address[] memory superForms_) =
            SuperformFactory(getContract(chainId, "SuperformFactory")).getAllSuperformsFromVault(vaults_[0]);

        assertEq(superFormIdsCreated[0], superFormIds_[superFormIds_.length - 1]);
        assertEq(superFormsCreated[0], superForms_[superForms_.length - 1]);

        /// @dev check second superform creation
        (uint256[] memory superFormIds_1, address[] memory superForms_1) =
            SuperformFactory(getContract(chainId, "SuperformFactory")).getAllSuperformsFromVault(vaults_[1]);

        assertEq(superFormIdsCreated[1], superFormIds_1[superFormIds_1.length - 1]);
        assertEq(superFormsCreated[1], superForms_1[superForms_1.length - 1]);

        /// @dev check third superform creation
        (uint256[] memory superFormIds_2, address[] memory superForms_2) =
            SuperformFactory(getContract(chainId, "SuperformFactory")).getAllSuperformsFromVault(vaults_[2]);

        assertEq(superFormIdsCreated[2], superFormIds_2[superFormIds_2.length - 1]);
        assertEq(superFormsCreated[2], superForms_2[superForms_2.length - 1]);

        uint256 totalSuperformsAfter = SuperformFactory(getContract(chainId, "SuperformFactory")).getSuperformCount();
        assertEq(totalSuperformsAfter, totalSuperformsBefore + 3);
    }
}

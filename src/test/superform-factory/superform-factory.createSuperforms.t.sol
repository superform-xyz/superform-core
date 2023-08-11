// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {SuperformFactory} from "../../SuperformFactory.sol";
import {ERC4626Form} from "../../forms/ERC4626Form.sol";
import {ERC4626FormInterfaceNotSupported} from "../mocks/InterfaceNotSupported/ERC4626InterFaceNotSupported.sol";
import "../utils/BaseSetup.sol";
import {Error} from "../../utils/Error.sol";

contract SuperformFactoryCreateSuperformTest is BaseSetup {
    uint64 internal chainId = ETH;

    function setUp() public override {
        super.setUp();
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
        (vars.superformIds_, vars.superforms_) = SuperformFactory(getContract(chainId, "SuperformFactory"))
            .getAllSuperforms();

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
            SuperformFactory(getContract(chainId, "SuperformFactory")).getSuperformCount(),
            expectedNumberOfSuperforms
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
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(
            formImplementation,
            formBeaconId,
            salt
        );

        /// @dev Creating superform using beacon
        (uint256 superformIdCreated, address superformCreated) = SuperformFactory(
            getContract(chainId, "SuperformFactory")
        ).createSuperform(formBeaconId, formImplementation);

        (uint256[] memory superformIds_, address[] memory superforms_) = SuperformFactory(
            getContract(chainId, "SuperformFactory")
        ).getAllSuperformsFromVault(formImplementation);

        assertEq(superformIdCreated, superformIds_[superformIds_.length - 1]);

        assertEq(superformCreated, superforms_[superforms_.length - 1]);

        uint256 totalSuperforms = SuperformFactory(getContract(chainId, "SuperformFactory")).getFormCount();
        assertEq(totalSuperforms, 4);
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
            formImplementation1,
            formBeaconId,
            salt
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
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(
            formImplementation,
            formBeaconId,
            salt
        );

        /// @dev Creating superform using beacon
        SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(formBeaconId, formImplementation);

        /// @dev Creating superform using same beacon and vault
        vm.expectRevert(Error.VAULT_BEACON_COMBNATION_EXISTS.selector);
        SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(formBeaconId, formImplementation);
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
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(
            formImplementation,
            formBeaconId,
            salt
        );
    }
}

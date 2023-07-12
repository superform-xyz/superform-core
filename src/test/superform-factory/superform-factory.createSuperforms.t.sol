// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {ISuperFormFactory} from "src/interfaces/ISuperFormFactory.sol";
import {ISuperRegistry} from "src/interfaces/ISuperRegistry.sol";
import {SuperFormFactory} from "src/SuperFormFactory.sol";
import {FactoryStateRegistry} from "src/crosschain-data/extensions/FactoryStateRegistry.sol";
import {ERC4626Form} from "src/forms/ERC4626Form.sol";
import "src/test/utils/BaseSetup.sol";
import "src/test/utils/Utilities.sol";
import {Error} from "src/utils/Error.sol";
import "src/utils/DataPacking.sol";

contract SuperFormFactoryCreateSuperformTest is BaseSetup {

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
        uint256 expectedSuperFormId1;
        uint256 expectedSuperFormId2;
        uint256 superFormId;
        address superForm;
        address resSuperForm;
        uint256 resFormid;
        uint64 resChainId;
        uint256[] superFormIds_;
        uint64[] chainIds_;
        uint32[] formIds_;
        uint256[] transformedChainIds_;
        uint256[] expectedSuperFormIds;
        uint32[] expectedFormBeaconIds;
        uint256[] expectedChainIds;
        address[] superForms_;
        address[] expectedVaults;
    }

    function test_utility_superForms() public {
        UtilityArgs memory vars;
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        /// @dev testing the getAllSuperForms function
        (vars.superFormIds_, vars.superForms_, vars.formIds_, vars.chainIds_) = SuperFormFactory(
            getContract(chainId, "SuperFormFactory")
        ).getAllSuperForms();

        assertEq(
            vars.superFormIds_.length,
            vars.superForms_.length
        );

        /// @dev Testing Coss Chain Superform Deployments
        vars.transformedChainIds_ = new uint256[](vars.chainIds_.length);

        for (uint256 j; j < vars.chainIds_.length; j++) {
            vars.transformedChainIds_[j] = uint256(vars.chainIds_[j]);
        }

        vars.expectedFormBeaconIds = new uint32[](chainIds.length * UNDERLYING_TOKENS.length);
        vars.expectedChainIds = new uint256[](chainIds.length * UNDERLYING_TOKENS.length);

        uint256 expectedNumberOfSuperforms = UNDERLYING_TOKENS.length * VAULT_KINDS.length;

        assertEq(
            SuperFormFactory(getContract(chainId, "SuperFormFactory")).getAllSuperFormsList(),
            expectedNumberOfSuperforms
        );

    }

    function test_base_setup_superForms() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formBeaconId = 0;


        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(
            formImplementation,
            formBeaconId,
            salt
        );

        /// @dev Creating superform using beacon
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).createSuperForm(
            formBeaconId,
            formImplementation
        );
    }

    function test_revert_createSuperForm_addressZero() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation1 = address(new ERC4626Form(superRegistry));
        uint32 formBeaconId = 0;


        /// Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(
            formImplementation1,
            formBeaconId,
            salt
        );

        /// @dev Creating superform using beacon
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).createSuperForm(
            formBeaconId,
            address(0)
        );
    }
}
// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {ISuperFormFactory} from "../../interfaces/ISuperFormFactory.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {SuperFormFactory} from "../../SuperFormFactory.sol";
import {FactoryStateRegistry} from "../../crosschain-data/extensions/FactoryStateRegistry.sol";
import {ERC4626Form} from "../../forms/ERC4626Form.sol";
import {VaultMock} from "../mocks/VaultMock.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {ERC4626FormExternal} from "../mocks/ERC4626FormExternal.sol";
import {BaseForm} from "../../BaseForm.sol";
import "../utils/BaseSetup.sol";
import "../utils/Utilities.sol";
import {Error} from "../../utils/Error.sol";

contract SuperFormERC4626FormTest is BaseSetup {

    uint64 internal chainId = ETH;

    function setUp() public override {
        super.setUp();
    }

    /// @dev Test vaultSharesAmountToUnderlyingAmount
    function test_vaultSharesAmountToUnderlyingAmount() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626FormExternal(superRegistry));
        uint32 formBeaconId = 0;

        /// @dev Vaults For The Superforms
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");


        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(
            formImplementation,
            formBeaconId,
            salt
        );

        /// @dev Creating superform using formBeaconId and vault
        (, address superFormCreated) = SuperFormFactory(getContract(chainId, "SuperFormFactory")).createSuperForm(
            formBeaconId,
            address(vault)
        );

        uint256 vaultShareAmount = 100;

        uint256 shareAmount = ERC4626FormExternal(payable(superFormCreated)).vaultSharesAmountToUnderlyingAmount(vaultShareAmount);

        assertEq (
            vaultShareAmount,
            shareAmount
        );
        }

    /// @dev Test vaultSharesAmountToUnderlyingAmountRoundingUp
    function test_vaultSharesAmountToUnderlyingAmountRoundingUp() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626FormExternal(superRegistry));
        uint32 formBeaconId = 0;

        /// @dev Vaults For The Superforms
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");


        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(
            formImplementation,
            formBeaconId,
            salt
        );

        /// @dev Creating superform using formBeaconId and vault
        (, address superFormCreated) = SuperFormFactory(getContract(chainId, "SuperFormFactory")).createSuperForm(
            formBeaconId,
            address(vault)
        );

        uint256 vaultShareAmount = 100;

        uint256 shareAmount = ERC4626FormExternal(payable(superFormCreated)).vaultSharesAmountToUnderlyingAmountRoundingUp(vaultShareAmount);

        assertEq (
            vaultShareAmount,
            shareAmount
        );
        }

    /// @dev Test underlyingAmountToVaultSharesAmount
    function test_underlyingAmountToVaultSharesAmount() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626FormExternal(superRegistry));
        uint32 formBeaconId = 0;

        /// @dev Vaults For The Superforms
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");


        // Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        SuperFormFactory(getContract(chainId, "SuperFormFactory")).addFormBeacon(
            formImplementation,
            formBeaconId,
            salt
        );

        /// @dev Creating superform using formBeaconId and vault
        (, address superFormCreated) = SuperFormFactory(getContract(chainId, "SuperFormFactory")).createSuperForm(
            formBeaconId,
            address(vault)
        );

        uint256 vaultShareAmount = 100;

        uint256 shareAmount = ERC4626FormExternal(payable(superFormCreated)).underlyingAmountToVaultSharesAmount(vaultShareAmount);

        assertEq (
            vaultShareAmount,
            shareAmount
        );
        }
}
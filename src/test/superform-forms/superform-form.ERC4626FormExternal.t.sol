// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {SuperformFactory} from "../../SuperformFactory.sol";
import {VaultMock} from "../mocks/VaultMock.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {ERC4626FormExternal} from "../mocks/ERC4626FormExternal.sol";
import "../utils/BaseSetup.sol";

contract SuperformERC4626FormTest is BaseSetup {
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
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(
            formImplementation,
            formBeaconId,
            salt
        );

        /// @dev Creating superform using formBeaconId and vault
        (, address superformCreated) = SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(
            formBeaconId,
            address(vault)
        );

        uint256 vaultShareAmount = 100;

        uint256 shareAmount = ERC4626FormExternal(payable(superformCreated)).vaultSharesAmountToUnderlyingAmount(
            vaultShareAmount
        );

        assertEq(vaultShareAmount, shareAmount);
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
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(
            formImplementation,
            formBeaconId,
            salt
        );

        /// @dev Creating superform using formBeaconId and vault
        (, address superformCreated) = SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(
            formBeaconId,
            address(vault)
        );

        uint256 vaultShareAmount = 100;

        uint256 shareAmount = ERC4626FormExternal(payable(superformCreated))
            .vaultSharesAmountToUnderlyingAmountRoundingUp(vaultShareAmount);

        assertEq(vaultShareAmount, shareAmount);
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
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormBeacon(
            formImplementation,
            formBeaconId,
            salt
        );

        /// @dev Creating superform using formBeaconId and vault
        (, address superformCreated) = SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(
            formBeaconId,
            address(vault)
        );

        uint256 vaultShareAmount = 100;

        uint256 shareAmount = ERC4626FormExternal(payable(superformCreated)).underlyingAmountToVaultSharesAmount(
            vaultShareAmount
        );

        assertEq(vaultShareAmount, shareAmount);
    }
}

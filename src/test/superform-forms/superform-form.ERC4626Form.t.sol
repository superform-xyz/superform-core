// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {ISuperFormFactory} from "../../interfaces/ISuperFormFactory.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {SuperFormFactory} from "../../SuperFormFactory.sol";
import {FactoryStateRegistry} from "../../crosschain-data/extensions/FactoryStateRegistry.sol";
import {ERC4626Form} from "../../forms/ERC4626Form.sol";
import {VaultMock} from "../mocks/VaultMock.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {BaseForm} from "../../BaseForm.sol";
import "../utils/BaseSetup.sol";
import "../utils/Utilities.sol";
import {Error} from "../../utils/Error.sol";

contract SuperFormERC4626FormTest is BaseSetup {

    uint64 internal chainId = ETH;

    function setUp() public override {
        super.setUp();
    }

    /// @dev Test Vault Symbol
    function test_superformVaultSymbol() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
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

        string memory symbol = ERC4626Form(payable(superFormCreated)).getVaultSymbol();

        assertEq(
            symbol,
            "Mock"
        );
    }

    /// @dev Test Yield Token Symbol
    function test_superformYieldTokenSymbol() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
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

        string memory symbol = ERC4626Form(payable(superFormCreated)).superformYieldTokenSymbol();

        assertEq(
            symbol,
            "SUP-Mock"
        );
    }

        /// @dev Test Yield Token Decimals
    function test_superformYieldTokenDecimals() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
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

        uint256 decimals = ERC4626Form(payable(superFormCreated)).superformYieldTokenDecimals();

        assertEq(
            decimals,
            18
        );
    }

    function test_superformVaultSharesAmountToUnderlyingAmount() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
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

        uint256 assets = 10;
        uint256 withdrawableAssets = ERC4626Form(payable(superFormCreated)).previewWithdrawFrom(assets);

        assertEq(
            assets,
            withdrawableAssets
        );
    }

    function test_superformVaultPreviewPricePerVaultShare() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
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

        uint256 withdrawableAssets = ERC4626Form(payable(superFormCreated)).getPreviewPricePerVaultShare();

        assertEq(
            withdrawableAssets,
            1000000000000000000
        );
    }

    function test_superformVaultConvertPricePerVaultShare() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
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

        uint256 priceVaultShare = ERC4626Form(payable(superFormCreated)).getConvertPricePerVaultShare();

        assertEq(
            priceVaultShare,
            1000000000000000000
        );
    }

    function test_superformVaultShareBalance() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
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

        uint256 totalAssets = ERC4626Form(payable(superFormCreated)).getTotalAssets();

        assertEq(
            totalAssets,
            0
        );
    }

    function test_superformVaultPricePerVaultShare() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
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

        uint256 vaultShareBalance = ERC4626Form(payable(superFormCreated)).getVaultShareBalance();

        assertEq(
            vaultShareBalance,
            0
        );
    }

    function test_superformVaultDecimals() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
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

        uint256 priceVaultShare = ERC4626Form(payable(superFormCreated)).getPricePerVaultShare();

        assertEq(
            priceVaultShare,
            1000000000000000000
        );
    }

    function test_superformVaultName() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
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

        uint256 vaultDecimals = ERC4626Form(payable(superFormCreated)).getVaultDecimals();

        assertEq(
            vaultDecimals,
            18
        );
    }

    function test_superformVaultTotalAssets() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
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

        string memory vaultName = ERC4626Form(payable(superFormCreated)).getVaultName();

        assertEq(
            vaultName,
            "SUP-Mock"
        );
    }

    function test_superformYieldTokenName() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
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

        string memory tokenName = ERC4626Form(payable(superFormCreated)).superformYieldTokenName();

        assertEq(
            tokenName,
            "SUP-Mock"
        );
    }
}
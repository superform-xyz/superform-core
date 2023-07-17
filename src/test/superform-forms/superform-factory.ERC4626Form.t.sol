// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {ISuperFormFactory} from "../../interfaces/ISuperFormFactory.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {SuperFormFactory} from "../../SuperFormFactory.sol";
import {FactoryStateRegistry} from "../../crosschain-data/extensions/FactoryStateRegistry.sol";
import {ERC4626Form} from "../../forms/ERC4626Form.sol";
import {VaultMock} from "../mocks/VaultMock.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import "../utils/BaseSetup.sol";
import "../utils/Utilities.sol";
import {Error} from "../../utils/Error.sol";

contract SuperFormERC4626FormTest is BaseSetup {

    uint64 internal chainId = ETH;

    function setUp() public override {
        super.setUp();
    }

    /// @dev Test Yield Token
    function test_superformYieldTokenName() public {
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        /// @dev Setting Vaults And Yield Tokens
        address superRegistry = getContract(chainId, "SuperRegistry");
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");

        /// @dev Deploying Forms
        ERC4626Form formImplementation = new ERC4626Form(superRegistry);
        formImplementation.initialize(superRegistry, address(vault));

        string memory vaultName = formImplementation.superformYieldTokenName();

        assertEq(
            vaultName,
            "Superform Mock"
        );
    }
    
    function test_superformYieldTokenSymbol() public {
        
        vm.startPrank(deployer);
        
        vm.selectFork(FORKS[chainId]);

        /// @dev Setting Vaults And Yield Tokens
        address superRegistry = getContract(chainId, "SuperRegistry");
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");

        /// @dev Deploying Forms
        ERC4626Form formImplementation = new ERC4626Form(superRegistry);
        formImplementation.initialize(superRegistry, address(vault));

        string memory tokenSymbol = formImplementation.superformYieldTokenSymbol();

        assertEq(
            tokenSymbol,
            "SUP-Mock"
        );
    }
}
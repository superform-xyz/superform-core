// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/ProtocolActions.sol";

contract SuperformERC5115FormTest is ProtocolActions {
    uint64 internal chainId = ARBI;
    ERC5115Form targetSuperform;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[chainId]);
        targetSuperform = ERC5115Form(getContract(chainId, "wstETHERC5115Superform4"));
    }

    /// @dev Test Vault Symbol
    function test_superformVaultSymbolERC5115() public {
        vm.startPrank(deployer);

        assertEq(targetSuperform.getVaultSymbol(), "SY-wstETH");
    }

    /// @dev Test Vault Name
    function test_superformVaultNameERC5115() public {
        vm.startPrank(deployer);

        assertEq(targetSuperform.getVaultName(), "SY wstETH");
    }

    /// @dev Test Vault Decimals
    function test_superformVaultDecimalsERC5115() public {
        vm.startPrank(deployer);

        assertEq(targetSuperform.getVaultDecimals(), 18);
    }

    /// @dev Test Price Per Vault Share
    function test_superformPricePerVaultShareERC5115() public {
        vm.startPrank(deployer);

        uint256 pricePerShare = targetSuperform.getPricePerVaultShare();
        assertGt(pricePerShare, 0);
    }

    /// @dev Test Vault Share Balance
    function test_superformVaultShareBalanceERC5115() public {
        vm.startPrank(deployer);

        uint256 shareBalance = targetSuperform.getVaultShareBalance();
        assertGe(shareBalance, 0);
    }

    /// @dev Test Total Assets
    function test_superformTotalAssetsERC5115() public {
        vm.startPrank(deployer);

        uint256 totalAssets = targetSuperform.getTotalAssets();
        assertGt(totalAssets, 0);
    }

    /// @dev Test Total Supply
    function test_superformTotalSupplyERC5115() public {
        vm.startPrank(deployer);

        uint256 totalSupply = targetSuperform.getTotalSupply();
        assertGt(totalSupply, 0);
    }

    /// @dev Test Preview Price Per Vault Share
    function test_superformPreviewPricePerVaultShareERC5115() public {
        vm.startPrank(deployer);

        uint256 previewPricePerShare = targetSuperform.getPreviewPricePerVaultShare();
        assertGt(previewPricePerShare, 0);
    }

    /// @dev Test Preview Deposit
    function test_superformPreviewDepositERC5115() public {
        vm.startPrank(deployer);

        uint256 assets = 1 ether;
        uint256 shares = targetSuperform.previewDepositTo(assets);
        assertGt(shares, 0);
    }

    /// @dev Test Preview Redeem
    function test_superformPreviewRedeemERC5115() public {
        vm.startPrank(deployer);

        uint256 shares = 1 ether;
        uint256 assets = targetSuperform.previewRedeemFrom(shares);
        assertGt(assets, 0);
    }

    /// @dev Test Superform Yield Token Name
    function test_superformYieldTokenNameERC5115() public {
        vm.startPrank(deployer);

        string memory yieldTokenName = targetSuperform.superformYieldTokenName();
        assertEq(yieldTokenName, "SY wstETH SuperPosition");
    }

    /// @dev Test Superform Yield Token Symbol
    function test_superformYieldTokenSymbolERC5115() public {
        vm.startPrank(deployer);

        string memory yieldTokenSymbol = targetSuperform.superformYieldTokenSymbol();
        assertEq(yieldTokenSymbol, "sp-SY-wstETH");
    }

    /// @dev Test State Registry Id
    function test_superformStateRegistryIdERC5115() public {
        vm.startPrank(deployer);

        uint8 stateRegistryId = targetSuperform.getStateRegistryId();
        assertEq(stateRegistryId, 1);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/ProtocolActions.sol";
import { IStandardizedYield } from "src/vendor/pendle/IStandardizedYield.sol";

contract SuperformERC5115FormTest is ProtocolActions {
    uint64 internal chainId = ARBI;
    ERC5115Form targetSuperform;
    IStandardizedYield targetVault;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[chainId]);
        targetSuperform = ERC5115Form(getContract(chainId, "wstETHERC5115Superform4"));
        targetVault = IStandardizedYield(targetSuperform.vault());
    }

    /// @dev Test Vault Symbol
    function test_superformVaultSymbolERC5115() public view {
        assertEq(targetSuperform.getVaultSymbol(), "SY-wstETH");
    }

    /// @dev Test Vault Name
    function test_superformVaultNameERC5115() public view {
        assertEq(targetSuperform.getVaultName(), "SY wstETH");
    }

    /// @dev Test Vault Decimals
    function test_superformVaultDecimalsERC5115() public view {
        assertEq(targetSuperform.getVaultDecimals(), 18);
    }

    /// @dev Test Price Per Vault Share
    function test_superformPricePerVaultShareERC5115() public view {
        uint256 pricePerShare = targetSuperform.getPricePerVaultShare();
        assertGt(pricePerShare, 0);
    }

    /// @dev Test Vault Share Balance
    function test_superformVaultShareBalanceERC5115() public view {
        uint256 shareBalance = targetSuperform.getVaultShareBalance();
        assertGe(shareBalance, 0);
    }

    /// @dev Test Total Assets
    function test_superformTotalAssetsERC5115() public view {
        uint256 totalAssets = targetSuperform.getTotalAssets();
        assertGt(totalAssets, 0);
    }

    /// @dev Test Total Supply
    function test_superformTotalSupplyERC5115() public view {
        uint256 totalSupply = targetSuperform.getTotalSupply();
        assertGt(totalSupply, 0);
    }

    /// @dev Test Preview Price Per Vault Share
    function test_superformPreviewPricePerVaultShareERC5115() public view {
        uint256 previewPricePerShare = targetSuperform.getPreviewPricePerVaultShare();
        assertGt(previewPricePerShare, 0);
    }

    /// @dev Test Preview Deposit
    function test_superformPreviewDepositERC5115() public view {
        uint256 assets = 1 ether;
        uint256 shares = targetSuperform.previewDepositTo(assets);
        assertGt(shares, 0);
    }

    /// @dev Test Preview Redeem
    function test_superformPreviewRedeemERC5115() public view {
        uint256 shares = 1 ether;
        uint256 assets = targetSuperform.previewRedeemFrom(shares);
        assertGt(assets, 0);
    }

    /// @dev Test Superform Yield Token Name
    function test_superformYieldTokenNameERC5115() public view {
        string memory yieldTokenName = targetSuperform.superformYieldTokenName();
        assertEq(yieldTokenName, "SY wstETH SuperPosition");
    }

    /// @dev Test Superform Yield Token Symbol
    function test_superformYieldTokenSymbolERC5115() public view {
        string memory yieldTokenSymbol = targetSuperform.superformYieldTokenSymbol();
        assertEq(yieldTokenSymbol, "sp-SY-wstETH");
    }

    /// @dev Test State Registry Id
    function test_superformStateRegistryIdERC5115() public view {
        uint8 stateRegistryId = targetSuperform.getStateRegistryId();
        assertEq(stateRegistryId, 1);
    }

    /// @dev Test Preview Withdraw From
    function test_superformPreviewWithdrawERC5115() public view {
        uint256 previewWithdrawReturnValue = targetSuperform.previewWithdrawFrom(100_000_000);
        assertEq(previewWithdrawReturnValue, 0);
    }

    /// @dev Test Get Yield Token
    function test_superformGetYieldTokenERC5115() public view {
        address yieldTokenSuperform = targetSuperform.getYieldToken();
        address yieldTokenVault = targetVault.yieldToken();

        assertEq(yieldTokenSuperform, yieldTokenVault);
    }

    /// @dev Test Get Tokens In
    function test_superformGetTokensInERC5115() public view {
        address[] memory tokensInSuperform = targetSuperform.getTokensIn();
        address[] memory tokensInVault = targetVault.getTokensIn();

        assertEq(tokensInSuperform, tokensInVault);
    }

    /// @dev Test Get Tokens Out
    function test_superformGetTokensOutERC5115() public view {
        address[] memory tokensOutSuperform = targetSuperform.getTokensOut();
        address[] memory tokensOutVault = targetVault.getTokensOut();

        assertEq(tokensOutSuperform, tokensOutVault);
    }

    /// @dev Test Valid Tokens In
    function test_superformIsValidTokenInERC5115() public view {
        address[] memory tokensInSuperform = targetSuperform.getTokensIn();

        for (uint256 i; i < tokensInSuperform.length; ++i) {
            assertTrue(targetSuperform.isValidTokenIn(tokensInSuperform[i]));
        }
    }

    /// @dev Test Valid Tokens Out
    function test_superformIsValidTokenOutERC5115() public view {
        address[] memory tokensOutSuperform = targetSuperform.getTokensOut();

        for (uint256 i; i < tokensOutSuperform.length; ++i) {
            assertTrue(targetSuperform.isValidTokenOut(tokensOutSuperform[i]));
        }
    }

    /// @dev Test Get Asset Info
    function test_superformGetAssetInfoERC5115() public view {
        (IStandardizedYield.AssetType assetType, address assetAddress, uint8 assetDecimals) =
            targetSuperform.getAssetInfo();
        assertEq(uint256(assetType), 0);
        assertEq(assetDecimals, 18);
        assertEq(assetAddress, 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/ProtocolActions.sol";
import { IStandardizedYield } from "src/vendor/pendle/IStandardizedYield.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";

contract MaliciousVault {
    address public constant asset = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    function deposit(address, address, uint256, uint256) external payable returns (uint256 amountSharesOut) {
        return 10e6;
    }

    function redeem(address, uint256, address, uint256, bool) external pure returns (uint256 amountTokenOut) {
        return 10e6;
    }

    function balanceOf(address) external pure returns (uint256) {
        return 0;
    }
}

contract MaliciousWithdrawVault {
    address public constant asset = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    uint256 _balance;

    function deposit(address, address, uint256, uint256 minSharesOut) external payable returns (uint256) {
        _balance = minSharesOut;
        return minSharesOut;
    }

    function redeem(address, uint256, address, uint256, bool) external pure returns (uint256) {
        return 0;
    }

    function balanceOf(address) external view returns (uint256) {
        return _balance;
    }

    function getUnderlying5115Vault() external view returns (address) {
        return address(this);
    }

    function allowance(address, address) external view returns (uint256) {
        return _balance;
    }

    function approve(address, uint256) external pure { }
}

contract Mock5115VaultWithNoRewards is Test {
    address public constant asset = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
}

contract Mock5115VaultWithRewards is Test {
    address public constant asset = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    function getRewardTokens() external pure returns (address[] memory) {
        address[] memory rewardTokens = new address[](2);
        rewardTokens[0] = USDT;
        rewardTokens[1] = USDC;

        return rewardTokens;
    }

    function claimRewards(address user) external returns (uint256[] memory rewardAmounts) {
        deal(USDT, user, 1e6);
        deal(USDC, user, 2e6);

        rewardAmounts = new uint256[](2);
        rewardAmounts[0] = 1e6;
        rewardAmounts[1] = 2e6;
    }

    function accruedRewards(address) external pure returns (uint256[] memory rewardAmounts) {
        rewardAmounts = new uint256[](2);
        rewardAmounts[0] = 1e6;
        rewardAmounts[1] = 2e6;
    }

    function rewardIndexesStored() external pure returns (uint256[] memory indices) {
        indices = new uint256[](2);
        indices[0] = 1;
        indices[1] = 2;
    }

    function isValidTokenIn(address) external pure returns (bool isValid) {
        isValid = true;
    }

    function isValidTokenOut(address) external pure returns (bool isValid) {
        isValid = true;
    }
}

contract SuperformERC5115FormTest is ProtocolActions {
    uint64 internal chainId = ARBI;
    uint32 FORM_ID = 4;

    ERC5115Form targetSuperform;
    ERC5115To4626Wrapper targetWrapper;

    IStandardizedYield targetVault;

    Mock5115VaultWithNoRewards noRewards;
    Mock5115VaultWithRewards rewards;
    ERC5115To4626Wrapper rewardsWrapper;

    MaliciousVault mal;
    MaliciousWithdrawVault malWithdraw;

    ERC5115Form noRewardsSuperform;
    ERC5115Form rewardsSuperform;
    ERC5115Form malSuperform;
    ERC5115Form malWithdrawSuperform;

    uint256 malSuperformId;
    uint256 malWithdrawSuperformId;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[chainId]);
        targetSuperform = ERC5115Form(getContract(chainId, "wstETHERC5115Superform4"));
        targetWrapper = ERC5115To4626Wrapper(targetSuperform.vault());
        targetVault = IStandardizedYield(targetSuperform.vault());

        noRewards = new Mock5115VaultWithNoRewards();
        rewards = new Mock5115VaultWithRewards();
        rewardsWrapper = new ERC5115To4626Wrapper(
            address(rewards), 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9, 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9
        );

        mal = new MaliciousVault();
        malWithdraw = new MaliciousWithdrawVault();

        (, address superformCreated) =
            ISuperformFactory(getContract(ARBI, "SuperformFactory")).createSuperform(FORM_ID, address(noRewards));
        noRewardsSuperform = ERC5115Form(superformCreated);

        (, superformCreated) =
            ISuperformFactory(getContract(ARBI, "SuperformFactory")).createSuperform(FORM_ID, address(rewards));
        rewardsSuperform = ERC5115Form(superformCreated);

        (malSuperformId, superformCreated) =
            ISuperformFactory(getContract(ARBI, "SuperformFactory")).createSuperform(FORM_ID, address(mal));
        malSuperform = ERC5115Form(superformCreated);

        (malWithdrawSuperformId, superformCreated) =
            ISuperformFactory(getContract(ARBI, "SuperformFactory")).createSuperform(FORM_ID, address(malWithdraw));
        malWithdrawSuperform = ERC5115Form(superformCreated);
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

    /// @dev Test Revert Claim Reward Tokens
    function test_superformRevertClaimRewardTokensERC5115() public {
        vm.expectRevert(ERC5115Form.FUNCTION_NOT_IMPLEMENTED.selector);
        noRewardsSuperform.claimRewardTokens();
    }

    /// @dev Test Revert Get Accrued Rewards
    function test_superformRevertGetAccruedRewardsERC5115() public {
        vm.expectRevert(ERC5115Form.FUNCTION_NOT_IMPLEMENTED.selector);
        noRewardsSuperform.getAccruedRewards(address(this));
    }

    /// @dev Test Revert Get Reward Indexes Stored
    function test_superformRevertGetRewardIndexesStoredERC5115() public {
        vm.expectRevert(ERC5115Form.FUNCTION_NOT_IMPLEMENTED.selector);
        noRewardsSuperform.getRewardIndexesStored();
    }

    /// @dev Test Revert Get Reward Tokens
    function test_superformRevertGetRewardTokensERC5115() public {
        vm.expectRevert(ERC5115Form.FUNCTION_NOT_IMPLEMENTED.selector);
        noRewardsSuperform.getRewardTokens();
    }

    /// @dev Test Claim Reward Tokens
    function test_superformClaimRewardTokensERC5115() public {
        uint256[] memory rewardsBalanceBefore = new uint256[](rewardsSuperform.getRewardTokens().length);
        for (uint256 i; i < rewardsBalanceBefore.length; ++i) {
            rewardsBalanceBefore[i] = IERC20(rewardsSuperform.getRewardTokens()[i]).balanceOf(address(this));
        }

        rewardsSuperform.claimRewardTokens();

        for (uint256 i; i < rewardsBalanceBefore.length; ++i) {
            uint256 rewardsBalanceAfter = IERC20(rewardsSuperform.getRewardTokens()[i]).balanceOf(address(this));
            assertGe(rewardsBalanceAfter, rewardsBalanceBefore[i]);
        }
    }

    /// @dev Test Get Accrued Rewards
    function test_superformGetAccruedRewardsERC5115() public view {
        uint256[] memory accruedRewards = rewardsSuperform.getAccruedRewards(address(this));
        assertGt(accruedRewards.length, 0);
        for (uint256 i; i < accruedRewards.length; ++i) {
            assertGe(accruedRewards[i], 0);
        }
    }

    /// @dev Test Get Reward Indexes Stored
    function test_superformGetRewardIndexesStoredERC5115() public view {
        uint256[] memory rewardIndexes = rewardsSuperform.getRewardIndexesStored();
        assertGt(rewardIndexes.length, 0);
        for (uint256 i; i < rewardIndexes.length; ++i) {
            assertGe(rewardIndexes[i], 0);
        }
    }

    /// @dev Test Get Reward Tokens
    function test_superformGetRewardTokensERC5115() public view {
        address[] memory rewardTokens = rewardsSuperform.getRewardTokens();
        assertGt(rewardTokens.length, 0);
        for (uint256 i; i < rewardTokens.length; ++i) {
            assertFalse(rewardTokens[i] == address(0));
        }
    }

    /// @dev Test Forwarding Dust To Paymaster
    function test_5115forwardDustToPaymaster() public {
        address superform = address(targetSuperform);

        deal(getContract(ARBI, "WETH"), superform, 1e18);
        uint256 balanceBefore = MockERC20(getContract(ARBI, "WETH")).balanceOf(superform);
        assertGt(balanceBefore, 0);
        IBaseForm(superform).forwardDustToPaymaster(getContract(ARBI, "WETH"));
        uint256 balanceAfter = MockERC20(getContract(ARBI, "WETH")).balanceOf(superform);

        assertEq(balanceAfter, 0);
    }

    /// @dev Test Forwarding No Dust To Paymaster
    function test_5115forwardDustToPaymasterNoDust() public {
        address superform = address(targetSuperform);

        uint256 balanceBefore = MockERC20(getContract(ARBI, "WETH")).balanceOf(superform);
        assertEq(balanceBefore, 0);
        IBaseForm(superform).forwardDustToPaymaster(getContract(ARBI, "WETH"));
        uint256 balanceAfter = MockERC20(getContract(ARBI, "WETH")).balanceOf(superform);

        assertEq(balanceAfter, 0);
    }

    /// @dev Test emergency withdraw revert
    function test_5115emergencyWithdraw_NotEmergencyQueue() public {
        vm.prank(address(1));
        vm.expectRevert(Error.NOT_EMERGENCY_QUEUE.selector);
        targetSuperform.emergencyWithdraw(address(0), 0);
    }

    /// @dev Test emergency withdraw
    function test_5115emergencyWithdraw() public {
        address vault = targetSuperform.getVaultAddress();

        bytes32 vaultFormImplementationCombination = keccak256(abi.encode(getContract(ARBI, "ERC5115Form"), vault));
        uint256 superformId = SuperformFactory(getContract(ARBI, "SuperformFactory"))
            .vaultFormImplCombinationToSuperforms(vaultFormImplementationCombination);

        bytes memory extra5115Data = abi.encode("", superformId, 0x5979D7b546E38E414F7E9822514be443A4800529);

        LiqRequest memory liqRequest = LiqRequest(
            bytes(""),
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0,
            ARBI,
            0
        );

        SingleVaultSFData memory sfData = SingleVaultSFData(
            superformId,
            1e6,
            1e6,
            100,
            liqRequest,
            bytes(""),
            false,
            false,
            deployer,
            deployer,
            abi.encode(1, extra5115Data)
        );

        vm.startPrank(deployer);
        IERC20(0x5979D7b546E38E414F7E9822514be443A4800529).approve(getContract(ARBI, "SuperformRouter"), 1e6);
        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultDeposit(
            SingleDirectSingleVaultStateReq(sfData)
        );

        SuperformFactory(getContract(ARBI, "SuperformFactory")).changeFormImplementationPauseStatus(
            4, ISuperformFactory.PauseStatus.PAUSED, ""
        );

        SuperPositions(getContract(ARBI, "SuperPositions")).setApprovalForAll(
            getContract(ARBI, "SuperformRouter"), true
        );
        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultWithdraw(
            SingleDirectSingleVaultStateReq(sfData)
        );

        /// @dev try to withdraw more than available
        vm.startPrank(SuperRegistry(getContract(ARBI, "SuperRegistry")).getAddress(keccak256("EMERGENCY_QUEUE")));
        vm.expectRevert(Error.INSUFFICIENT_BALANCE.selector);
        targetSuperform.emergencyWithdraw(deployer, 2e6);

        vm.startPrank(SuperRegistry(getContract(ARBI, "SuperRegistry")).getAddress(keccak256("EMERGENCY_QUEUE")));
        targetSuperform.emergencyWithdraw(deployer, 1e6);
    }

    /// @dev Test emergency withdraw
    function test_5115directWithdrawRetain() public {
        address vault = targetSuperform.getVaultAddress();

        bytes32 vaultFormImplementationCombination = keccak256(abi.encode(getContract(ARBI, "ERC5115Form"), vault));
        uint256 superformId = SuperformFactory(getContract(ARBI, "SuperformFactory"))
            .vaultFormImplCombinationToSuperforms(vaultFormImplementationCombination);

        bytes memory extra5115Data = abi.encode("", superformId, 0x5979D7b546E38E414F7E9822514be443A4800529);

        LiqRequest memory liqRequest = LiqRequest(
            bytes(""),
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0,
            ARBI,
            0
        );

        SingleVaultSFData memory sfData = SingleVaultSFData(
            superformId,
            1e6,
            1e6,
            100,
            liqRequest,
            bytes(""),
            false,
            false,
            deployer,
            deployer,
            abi.encode(1, extra5115Data)
        );

        vm.startPrank(deployer);
        IERC20(0x5979D7b546E38E414F7E9822514be443A4800529).approve(getContract(ARBI, "SuperformRouter"), 1e6);
        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultDeposit(
            SingleDirectSingleVaultStateReq(sfData)
        );

        SuperPositions(getContract(ARBI, "SuperPositions")).setApprovalForAll(
            getContract(ARBI, "SuperformRouter"), true
        );

        sfData.retain4626 = true;
        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultWithdraw(
            SingleDirectSingleVaultStateReq(sfData)
        );
    }

    /// @dev Test emergency withdraw xChain
    function test_5115xChainWithdrawRetain() public {
        address vault = targetSuperform.getVaultAddress();

        bytes32 vaultFormImplementationCombination = keccak256(abi.encode(getContract(ARBI, "ERC5115Form"), vault));
        uint256 superformId = SuperformFactory(getContract(ARBI, "SuperformFactory"))
            .vaultFormImplCombinationToSuperforms(vaultFormImplementationCombination);

        bytes memory extra5115Data = abi.encode("", superformId, 0x5979D7b546E38E414F7E9822514be443A4800529);

        LiqRequest memory liqRequest = LiqRequest(
            bytes(""),
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0,
            ARBI,
            0
        );

        SingleVaultSFData memory sfData = SingleVaultSFData(
            superformId,
            1e6,
            1e6,
            100,
            liqRequest,
            bytes(""),
            false,
            false,
            deployer,
            deployer,
            abi.encode(1, extra5115Data)
        );

        vm.startPrank(deployer);
        IERC20(0x5979D7b546E38E414F7E9822514be443A4800529).approve(getContract(ARBI, "SuperformRouter"), 1e6);
        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultDeposit(
            SingleDirectSingleVaultStateReq(sfData)
        );

        SuperPositions(getContract(ARBI, "SuperPositions")).setApprovalForAll(
            getContract(ARBI, "SuperformRouter"), true
        );

        LiqRequest memory withdrawLiqRequest =
            LiqRequest(bytes(""), address(0), 0x5979D7b546E38E414F7E9822514be443A4800529, 0, ARBI, 0);

        InitSingleVaultData memory withdrawSfData = InitSingleVaultData(
            1, superformId, 1e6, 1e6, 100, withdrawLiqRequest, false, true, deployer, abi.encode(1, extra5115Data)
        );

        vm.startPrank(getContract(ARBI, "CoreStateRegistry"));
        targetSuperform.xChainWithdrawFromVault(withdrawSfData, deployer, OP);
    }

    /// @dev Test direct withdrawals with invalid tx data
    function test_5115WithdrawTxDataInvalid() public {
        address vault = targetSuperform.getVaultAddress();

        bytes32 vaultFormImplementationCombination = keccak256(abi.encode(getContract(ARBI, "ERC5115Form"), vault));
        uint256 superformId = SuperformFactory(getContract(ARBI, "SuperformFactory"))
            .vaultFormImplCombinationToSuperforms(vaultFormImplementationCombination);

        bytes memory extra5115Data = abi.encode("", superformId, 0x5979D7b546E38E414F7E9822514be443A4800529);

        LiqRequest memory liqRequest = LiqRequest(
            bytes(""),
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0,
            ARBI,
            0
        );

        SingleVaultSFData memory sfData = SingleVaultSFData(
            superformId,
            1e6,
            1e6,
            100,
            liqRequest,
            bytes(""),
            false,
            false,
            deployer,
            deployer,
            abi.encode(1, extra5115Data)
        );

        vm.startPrank(deployer);
        IERC20(0x5979D7b546E38E414F7E9822514be443A4800529).approve(getContract(ARBI, "SuperformRouter"), 1e6);
        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultDeposit(
            SingleDirectSingleVaultStateReq(sfData)
        );

        SuperPositions(getContract(ARBI, "SuperPositions")).setApprovalForAll(
            getContract(ARBI, "SuperformRouter"), true
        );

        ISocketRegistry.BridgeRequest memory bridgeRequest;
        ISocketRegistry.MiddlewareRequest memory middlewareRequest;

        sfData.liqRequest.bridgeId = 3;
        sfData.liqRequest.txData = abi.encodeWithSelector(
            SocketMock.outboundTransferTo.selector,
            ISocketRegistry.UserRequest(deployer, ARBI, 2e6, middlewareRequest, bridgeRequest)
        );

        vm.expectRevert(Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST.selector);
        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultWithdraw(
            SingleDirectSingleVaultStateReq(sfData)
        );
    }

    /// @dev Test direct deposit with insufficient allowance
    function test_5115DirectDepositInsufficientAllowance() public {
        address vault = targetSuperform.getVaultAddress();

        bytes32 vaultFormImplementationCombination = keccak256(abi.encode(getContract(ARBI, "ERC5115Form"), vault));
        uint256 superformId = SuperformFactory(getContract(ARBI, "SuperformFactory"))
            .vaultFormImplCombinationToSuperforms(vaultFormImplementationCombination);

        bytes memory extra5115Data = abi.encode("", superformId, 0x5979D7b546E38E414F7E9822514be443A4800529);

        LiqRequest memory liqRequest = LiqRequest(
            bytes(""),
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0,
            ARBI,
            0
        );

        InitSingleVaultData memory sfData = InitSingleVaultData(
            1, superformId, 1e6, 1e6, 100, liqRequest, false, false, deployer, abi.encode(1, extra5115Data)
        );

        vm.startPrank(getContract(ARBI, "SuperformRouter"));
        vm.expectRevert(Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT.selector);
        targetSuperform.directDepositIntoVault(sfData, deployer);
    }

    /// @dev Test direct deposit with insufficient allowance
    function test_5115DirectDepositInsufficientAllowanceWithLiqData() public {
        address vault = targetSuperform.getVaultAddress();

        bytes32 vaultFormImplementationCombination = keccak256(abi.encode(getContract(ARBI, "ERC5115Form"), vault));
        uint256 superformId = SuperformFactory(getContract(ARBI, "SuperformFactory"))
            .vaultFormImplCombinationToSuperforms(vaultFormImplementationCombination);

        bytes memory extra5115Data = abi.encode("", superformId, 0x5979D7b546E38E414F7E9822514be443A4800529);

        ISocketRegistry.BridgeRequest memory bridgeRequest;
        ISocketRegistry.MiddlewareRequest memory middlewareRequest;

        LiqRequest memory liqRequest = LiqRequest(
            abi.encodeWithSelector(
                SocketMock.outboundTransferTo.selector,
                ISocketRegistry.UserRequest(deployer, ARBI, 5e6, middlewareRequest, bridgeRequest)
            ),
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0x5979D7b546E38E414F7E9822514be443A4800529,
            3,
            ARBI,
            0
        );

        InitSingleVaultData memory sfData = InitSingleVaultData(
            1, superformId, 1e6, 1e6, 100, liqRequest, false, false, deployer, abi.encode(1, extra5115Data)
        );

        vm.startPrank(getContract(ARBI, "SuperformRouter"));
        vm.expectRevert(Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT.selector);
        targetSuperform.directDepositIntoVault(sfData, deployer);
    }

    /// @dev Test xchain deposit without proper allowance
    function test_5115DepositInsufficientAllowance() public {
        address vault = targetSuperform.getVaultAddress();

        bytes32 vaultFormImplementationCombination = keccak256(abi.encode(getContract(ARBI, "ERC5115Form"), vault));
        uint256 superformId = SuperformFactory(getContract(ARBI, "SuperformFactory"))
            .vaultFormImplCombinationToSuperforms(vaultFormImplementationCombination);

        bytes memory extra5115Data = abi.encode("", superformId, 0x5979D7b546E38E414F7E9822514be443A4800529);

        LiqRequest memory liqRequest = LiqRequest(
            bytes(""),
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0,
            ARBI,
            0
        );

        InitSingleVaultData memory sfData = InitSingleVaultData(
            1, superformId, 2e6, 2e6, 100, liqRequest, false, false, deployer, abi.encode(1, extra5115Data)
        );

        vm.startPrank(SuperRegistry(getContract(ARBI, "SuperRegistry")).getAddress(keccak256("CORE_STATE_REGISTRY")));
        vm.expectRevert(Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT.selector);
        targetSuperform.xChainDepositIntoVault(sfData, deployer, OP);
    }

    /// @dev Test xchain withdraw with tx data not updated
    function test_5115XChainWithdrawTxDataNotUpdated() public {
        address vault = targetSuperform.getVaultAddress();

        bytes32 vaultFormImplementationCombination = keccak256(abi.encode(getContract(ARBI, "ERC5115Form"), vault));
        uint256 superformId = SuperformFactory(getContract(ARBI, "SuperformFactory"))
            .vaultFormImplCombinationToSuperforms(vaultFormImplementationCombination);

        bytes memory extra5115Data = abi.encode("", superformId, 0x5979D7b546E38E414F7E9822514be443A4800529);

        LiqRequest memory liqRequest = LiqRequest(
            bytes(""),
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0,
            ARBI,
            0
        );

        InitSingleVaultData memory sfData = InitSingleVaultData(
            1, superformId, 1e6, 1e6, 100, liqRequest, false, false, deployer, abi.encode(1, extra5115Data)
        );

        vm.startPrank(getContract(ARBI, "CoreStateRegistry"));
        vm.expectRevert(Error.WITHDRAW_TX_DATA_NOT_UPDATED.selector);
        targetSuperform.xChainWithdrawFromVault(sfData, deployer, OP);
    }

    /// @dev Test xchain withdraw token not updated
    function test_5115XChainWithdrawTokenNotUpdated() public {
        address vault = targetSuperform.getVaultAddress();

        bytes32 vaultFormImplementationCombination = keccak256(abi.encode(getContract(ARBI, "ERC5115Form"), vault));
        uint256 superformId = SuperformFactory(getContract(ARBI, "SuperformFactory"))
            .vaultFormImplCombinationToSuperforms(vaultFormImplementationCombination);

        bytes memory extra5115Data = abi.encode("", superformId, 0x5979D7b546E38E414F7E9822514be443A4800529);

        LiqRequest memory liqRequest =
            LiqRequest(bytes("invalid-random-data"), address(0), 0x5979D7b546E38E414F7E9822514be443A4800529, 0, ARBI, 0);

        InitSingleVaultData memory sfData = InitSingleVaultData(
            1, superformId, 1e6, 1e6, 100, liqRequest, false, false, deployer, abi.encode(1, extra5115Data)
        );

        vm.startPrank(getContract(ARBI, "CoreStateRegistry"));
        vm.expectRevert(Error.WITHDRAW_TOKEN_NOT_UPDATED.selector);
        targetSuperform.xChainWithdrawFromVault(sfData, deployer, OP);
    }

    /// @dev Test xchain withdraw invalid liq request
    function test_5115XChainWithdrawInvalidLiqRequest() public {
        address vault = targetSuperform.getVaultAddress();

        bytes32 vaultFormImplementationCombination = keccak256(abi.encode(getContract(ARBI, "ERC5115Form"), vault));
        uint256 superformId = SuperformFactory(getContract(ARBI, "SuperformFactory"))
            .vaultFormImplCombinationToSuperforms(vaultFormImplementationCombination);

        bytes memory extra5115Data = abi.encode("", superformId, 0x5979D7b546E38E414F7E9822514be443A4800529);

        LiqRequest memory liqRequest = LiqRequest(
            bytes(""),
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0,
            ARBI,
            0
        );

        SingleVaultSFData memory sfData = SingleVaultSFData(
            superformId,
            1e6,
            1e6,
            100,
            liqRequest,
            bytes(""),
            false,
            false,
            deployer,
            deployer,
            abi.encode(1, extra5115Data)
        );

        vm.startPrank(deployer);
        IERC20(0x5979D7b546E38E414F7E9822514be443A4800529).approve(getContract(ARBI, "SuperformRouter"), 1e6);
        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultDeposit(
            SingleDirectSingleVaultStateReq(sfData)
        );

        SuperPositions(getContract(ARBI, "SuperPositions")).setApprovalForAll(
            getContract(ARBI, "SuperformRouter"), true
        );

        ISocketRegistry.BridgeRequest memory bridgeRequest;
        ISocketRegistry.MiddlewareRequest memory middlewareRequest;

        LiqRequest memory withdrawLiqRequest = LiqRequest(
            abi.encodeWithSelector(
                SocketMock.outboundTransferTo.selector,
                ISocketRegistry.UserRequest(deployer, ARBI, 5e6, middlewareRequest, bridgeRequest)
            ),
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0x5979D7b546E38E414F7E9822514be443A4800529,
            3,
            ARBI,
            0
        );

        InitSingleVaultData memory withdrawSfData = InitSingleVaultData(
            1, superformId, 1e6, 1e6, 100, withdrawLiqRequest, false, false, deployer, abi.encode(1, extra5115Data)
        );

        vm.startPrank(getContract(ARBI, "CoreStateRegistry"));
        vm.expectRevert(Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST.selector);
        targetSuperform.xChainWithdrawFromVault(withdrawSfData, deployer, OP);
    }

    /// @dev Test direct deposit with different tokens
    function test_5115DirectDepositDifferentTokens() public {
        address vault = targetSuperform.getVaultAddress();

        bytes32 vaultFormImplementationCombination = keccak256(abi.encode(getContract(ARBI, "ERC5115Form"), vault));
        uint256 superformId = SuperformFactory(getContract(ARBI, "SuperformFactory"))
            .vaultFormImplCombinationToSuperforms(vaultFormImplementationCombination);

        bytes memory extra5115Data = abi.encode("", superformId, 0x5979D7b546E38E414F7E9822514be443A4800529);

        LiqRequest memory liqRequest =
            LiqRequest(bytes(""), getContract(ARBI, "DAI"), 0x5979D7b546E38E414F7E9822514be443A4800529, 0, ARBI, 0);

        SingleVaultSFData memory sfData = SingleVaultSFData(
            superformId,
            1e6,
            1e6,
            100,
            liqRequest,
            bytes(""),
            false,
            false,
            deployer,
            deployer,
            abi.encode(1, extra5115Data)
        );

        vm.startPrank(deployer);
        IERC20(getContract(ARBI, "DAI")).approve(getContract(ARBI, "SuperformRouter"), 1e6);
        vm.expectRevert(Error.DIFFERENT_TOKENS.selector);
        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultDeposit(
            SingleDirectSingleVaultStateReq(sfData)
        );
    }

    /// @dev Test direct deposit with different tokens and liqData
    function test_5115DirectDepositDifferentTokensLiqData() public {
        address vault = targetSuperform.getVaultAddress();

        bytes32 vaultFormImplementationCombination = keccak256(abi.encode(getContract(ARBI, "ERC5115Form"), vault));
        uint256 superformId = SuperformFactory(getContract(ARBI, "SuperformFactory"))
            .vaultFormImplCombinationToSuperforms(vaultFormImplementationCombination);

        bytes memory extra5115Data = abi.encode("", superformId, 0x5979D7b546E38E414F7E9822514be443A4800529);

        LiqRequest memory liqRequest = LiqRequest(
            abi.encodeWithSelector(
                SocketOneInchMock.performDirectAction.selector,
                getContract(ARBI, "DAI"),
                getContract(ARBI, "USDC"),
                address(targetSuperform),
                1e6,
                abi.encode(address(targetSuperform), 1, 1)
            ),
            getContract(ARBI, "DAI"),
            0x5979D7b546E38E414F7E9822514be443A4800529,
            3,
            ARBI,
            0
        );

        SingleVaultSFData memory sfData = SingleVaultSFData(
            superformId,
            1e6,
            1e6,
            100,
            liqRequest,
            bytes(""),
            false,
            false,
            deployer,
            deployer,
            abi.encode(1, extra5115Data)
        );

        vm.startPrank(deployer);
        IERC20(getContract(ARBI, "DAI")).approve(getContract(ARBI, "SuperformRouter"), 1e6);
        vm.expectRevert(Error.DIFFERENT_TOKENS.selector);
        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultDeposit(
            SingleDirectSingleVaultStateReq(sfData)
        );
    }

    /// @dev Test direct deposit swap failed
    function test_5115DirectDepositSwapFailed() public {
        address vault = targetSuperform.getVaultAddress();

        bytes32 vaultFormImplementationCombination = keccak256(abi.encode(getContract(ARBI, "ERC5115Form"), vault));
        uint256 superformId = SuperformFactory(getContract(ARBI, "SuperformFactory"))
            .vaultFormImplCombinationToSuperforms(vaultFormImplementationCombination);

        bytes memory extra5115Data = abi.encode("", superformId, 0x5979D7b546E38E414F7E9822514be443A4800529);

        LiqRequest memory liqRequest = LiqRequest(
            abi.encodeWithSelector(
                SocketOneInchMock.performDirectAction.selector,
                getContract(ARBI, "DAI"),
                0x5979D7b546E38E414F7E9822514be443A4800529,
                address(targetSuperform),
                10e6,
                abi.encode(address(targetSuperform), 1, 3)
            ),
            getContract(ARBI, "DAI"),
            0x5979D7b546E38E414F7E9822514be443A4800529,
            3,
            ARBI,
            0
        );

        SingleVaultSFData memory sfData = SingleVaultSFData(
            superformId,
            10e6,
            10e6,
            100,
            liqRequest,
            bytes(""),
            false,
            false,
            deployer,
            deployer,
            abi.encode(1, extra5115Data)
        );

        vm.startPrank(deployer);
        IERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1).approve(getContract(ARBI, "SuperformRouter"), 10e6);

        vm.expectRevert(Error.DIRECT_DEPOSIT_SWAP_FAILED.selector);
        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultDeposit(
            SingleDirectSingleVaultStateReq(sfData)
        );
    }

    /// @dev Test slippage validation checks
    function test_5115SlippageValidation() public {
        deal(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9, 0x7121207b118BbaCF0340A989527474Bd4495c3C6, 1e6);
        bytes memory extra5115Data = abi.encode("", malSuperformId, 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);

        LiqRequest memory liqRequest = LiqRequest(
            bytes(""),
            0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9,
            0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9,
            0,
            ARBI,
            0
        );

        SingleVaultSFData memory sfData = SingleVaultSFData(
            malSuperformId,
            1e6,
            1e6,
            0,
            liqRequest,
            bytes(""),
            false,
            false,
            deployer,
            deployer,
            abi.encode(1, extra5115Data)
        );

        vm.startPrank(deployer);
        IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9).approve(getContract(ARBI, "SuperformRouter"), 1e6);

        vm.expectRevert(Error.VAULT_IMPLEMENTATION_FAILED.selector);
        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultDeposit(
            SingleDirectSingleVaultStateReq(sfData)
        );
    }

    /// @dev Test xchain slippage validation checks
    function test_5115WithdrawSlippageValidation() public {
        deal(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9, 0x7121207b118BbaCF0340A989527474Bd4495c3C6, 1e6);
        bytes memory extra5115Data = abi.encode("", malWithdrawSuperformId, 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);

        LiqRequest memory liqRequest = LiqRequest(
            bytes(""),
            0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9,
            0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9,
            0,
            ARBI,
            0
        );

        SingleVaultSFData memory sfData = SingleVaultSFData(
            malWithdrawSuperformId,
            1e6,
            1e6,
            0,
            liqRequest,
            bytes(""),
            false,
            false,
            deployer,
            deployer,
            abi.encode(1, extra5115Data)
        );

        vm.startPrank(deployer);
        IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9).approve(getContract(ARBI, "SuperformRouter"), 1e6);

        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultDeposit(
            SingleDirectSingleVaultStateReq(sfData)
        );

        SuperPositions(getContract(ARBI, "SuperPositions")).setApprovalForAll(
            getContract(ARBI, "SuperformRouter"), true
        );

        vm.expectRevert(Error.VAULT_IMPLEMENTATION_FAILED.selector);
        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultWithdraw(
            SingleDirectSingleVaultStateReq(sfData)
        );
    }

    /// @dev Test get main token in / out
    function test_5115getMainTokenInOut() public view {
        address exptToken = 0x5979D7b546E38E414F7E9822514be443A4800529;
        address tokenIn = targetWrapper.getMainTokenIn();
        address tokenOut = targetWrapper.getMainTokenOut();

        assertEq(tokenIn, exptToken);
        assertEq(tokenOut, exptToken);
    }

    /// @dev Test all claim related functions in wrapper
    function test_5115WrapperClaim() public {
        uint256[] memory returnArr = targetWrapper.claimRewards(address(420));
        assertEq(returnArr.length, 0);

        returnArr = targetWrapper.rewardIndexesStored();
        assertEq(returnArr.length, 0);

        returnArr = targetWrapper.rewardIndexesCurrent();
        assertEq(returnArr.length, 0);

        returnArr = targetWrapper.accruedRewards(address(420));
        assertEq(returnArr.length, 0);

        address[] memory returnArr2 = targetWrapper.getRewardTokens();
        assertEq(returnArr2.length, 0);
    }

    /// @dev Test get total supply
    function test_5115getTotalSupplyOnWrapper() public view {
        uint256 vaultSupply = targetWrapper.totalSupply();
        assertGt(vaultSupply, 0);
    }

    /// @dev Test balance and transfer properties of wrapper
    function test_5115BalanceAndTransfer() public {
        address vault = targetSuperform.getVaultAddress();

        bytes32 vaultFormImplementationCombination = keccak256(abi.encode(getContract(ARBI, "ERC5115Form"), vault));
        uint256 superformId = SuperformFactory(getContract(ARBI, "SuperformFactory"))
            .vaultFormImplCombinationToSuperforms(vaultFormImplementationCombination);

        bytes memory extra5115Data = abi.encode("", superformId, 0x5979D7b546E38E414F7E9822514be443A4800529);

        LiqRequest memory liqRequest = LiqRequest(
            bytes(""),
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0x5979D7b546E38E414F7E9822514be443A4800529,
            0,
            ARBI,
            0
        );

        SingleVaultSFData memory sfData = SingleVaultSFData(
            superformId,
            1e6,
            1e6,
            0,
            liqRequest,
            bytes(""),
            false,
            true,
            deployer,
            deployer,
            abi.encode(1, extra5115Data)
        );

        vm.startPrank(deployer);
        IERC20(0x5979D7b546E38E414F7E9822514be443A4800529).approve(getContract(ARBI, "SuperformRouter"), 1e6);

        SuperformRouter(payable(getContract(ARBI, "SuperformRouter"))).singleDirectSingleVaultDeposit(
            SingleDirectSingleVaultStateReq(sfData)
        );

        uint256 balance = targetWrapper.balanceOf(deployer);
        uint256 allowance = targetWrapper.allowance(deployer, address(11));
        assertEq(allowance, 0);

        vm.expectRevert(Error.NOT_IMPLEMENTED.selector);
        targetWrapper.approve(address(10), balance);

        vm.expectRevert(Error.NOT_IMPLEMENTED.selector);
        targetWrapper.transfer(address(11), balance);

        vm.expectRevert(Error.NOT_IMPLEMENTED.selector);
        targetWrapper.transferFrom(address(targetWrapper), address(100), balance);
    }
}

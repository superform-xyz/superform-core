// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import { Error } from "src/utils/Error.sol";
import { ERC4626Form } from "src/forms/ERC4626Form.sol";
import { MockERC20 } from "test/mocks/MockERC20.sol";
import { VaultMock } from "test/mocks/VaultMock.sol";
import { SuperformFactory } from "src/SuperformFactory.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import "test/utils/ProtocolActions.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { SuperformRouter } from "src/SuperformRouter.sol";
import { SuperPositions } from "src/SuperPositions.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { ILiFi } from "src/vendor/lifi/ILiFi.sol";
import { LibSwap } from "src/vendor/lifi/LibSwap.sol";
import { LiFiMock } from "test/mocks/LiFiMock.sol";
import "src/types/DataTypes.sol";

contract SuperformERC4626FormTest is ProtocolActions {
    uint64 internal chainId = ETH;
    address refundAddress = address(444);

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
        uint32 formImplementationId = 0;

        /// @dev Vaults For The Superforms
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");

        // Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );

        /// @dev Creating superform using formImplementationId and vault
        (, address superformCreated) = SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(
            formImplementationId, address(vault)
        );

        string memory symbol = ERC4626Form(payable(superformCreated)).getVaultSymbol();

        assertEq(symbol, "Mock");
    }

    /// @dev Test Yield Token Symbol
    function test_superformYieldTokenSymbol() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formImplementationId = 0;

        /// @dev Vaults For The Superforms
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");

        // Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );

        /// @dev Creating superform using formImplementationId and vault
        (, address superformCreated) = SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(
            formImplementationId, address(vault)
        );

        string memory symbol = ERC4626Form(payable(superformCreated)).superformYieldTokenSymbol();

        assertEq(symbol, "SUP-Mock");
    }

    function test_superformVaultSharesAmountToUnderlyingAmount() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formImplementationId = 0;

        /// @dev Vaults For The Superforms
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");

        // Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );

        /// @dev Creating superform using formImplementationId and vault
        (, address superformCreated) = SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(
            formImplementationId, address(vault)
        );

        uint256 assets = 10;
        uint256 withdrawableAssets = ERC4626Form(payable(superformCreated)).previewWithdrawFrom(assets);

        assertEq(assets, withdrawableAssets);
    }

    function test_superformVaultPreviewPricePerVaultShare() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formImplementationId = 0;

        /// @dev Vaults For The Superforms
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");

        // Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );

        /// @dev Creating superform using formImplementationId and vault
        (, address superformCreated) = SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(
            formImplementationId, address(vault)
        );

        uint256 withdrawableAssets = ERC4626Form(payable(superformCreated)).getPreviewPricePerVaultShare();

        assertEq(withdrawableAssets, 1_000_000_000_000_000_000);
    }

    function test_superformVaultTotalAssets() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formImplementationId = 0;

        /// @dev Vaults For The Superforms
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");

        // Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );

        /// @dev Creating superform using formImplementationId and vault
        (, address superformCreated) = SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(
            formImplementationId, address(vault)
        );

        uint256 totalAssets = ERC4626Form(payable(superformCreated)).getTotalAssets();

        assertEq(totalAssets, 0);
    }

    function test_superformVaultShareBalance() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formImplementationId = 0;

        /// @dev Vaults For The Superforms
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");

        // Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );

        /// @dev Creating superform using formImplementationId and vault
        (, address superformCreated) = SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(
            formImplementationId, address(vault)
        );

        uint256 vaultShareBalance = ERC4626Form(payable(superformCreated)).getVaultShareBalance();

        assertEq(vaultShareBalance, 0);
    }

    function test_superformVaultPricePerVaultShare() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formImplementationId = 0;

        /// @dev Vaults For The Superforms
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");

        // Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );

        /// @dev Creating superform using formImplementationId and vault
        (, address superformCreated) = SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(
            formImplementationId, address(vault)
        );

        uint256 priceVaultShare = ERC4626Form(payable(superformCreated)).getPricePerVaultShare();

        assertEq(priceVaultShare, 1_000_000_000_000_000_000);
    }

    function test_superformVaultDecimals() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formImplementationId = 0;

        /// @dev Vaults For The Superforms
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");

        // Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );

        /// @dev Creating superform using formImplementationId and vault
        (, address superformCreated) = SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(
            formImplementationId, address(vault)
        );

        uint256 vaultDecimals = ERC4626Form(payable(superformCreated)).getVaultDecimals();

        assertEq(vaultDecimals, 18);
    }

    function test_superformVaultName() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formImplementationId = 0;

        /// @dev Vaults For The Superforms
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");

        // Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );

        /// @dev Creating superform using formImplementationId and vault
        (, address superformCreated) = SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(
            formImplementationId, address(vault)
        );

        string memory vaultName = ERC4626Form(payable(superformCreated)).getVaultName();

        assertEq(vaultName, "Mock Vault");
    }

    function test_superformYieldTokenName() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation = address(new ERC4626Form(superRegistry));
        uint32 formImplementationId = 0;

        /// @dev Vaults For The Superforms
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");

        // Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );

        /// @dev Creating superform using formImplementationId and vault
        (, address superformCreated) = SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(
            formImplementationId, address(vault)
        );

        string memory tokenName = ERC4626Form(payable(superformCreated)).superformYieldTokenName();

        assertEq(tokenName, "Superform Mock Vault");
    }

    function test_superformDirectDepositWithoutAllowance() public {
        /// scenario: user deposits with his own collateral but failed to approve
        vm.selectFork(FORKS[ETH]);

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId, 1e18, 100, false, LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0), "", refundAddress, ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        /// @dev no approval before call
        vm.expectRevert(Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }

    function test_superformDirectDepositWithAllowance() public {
        _successfulDeposit();
    }

    function test_superformDirectDepositWithoutEnoughAllowanceWithTokensForceSent() public {
        /// scenario: user deposits by utilizing any crude collateral available in the form proxy
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);
        /// try depositing without approval
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId, 2e18, 100, false, LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0), "", refundAddress, ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        /// @dev make sure the form proxy has enough usdc for the user to hack it
        MockERC20(getContract(ETH, "DAI")).transfer(superform, 3e18);
        MockERC20(getContract(ETH, "DAI")).approve(superform, 1e18);

        vm.expectRevert(Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }

    function test_superformDirectDepositWithMaliciousTxData() public {
        /// scenario: user deposits by utilizing any crude collateral available in the form proxy
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);
        /// try depositing without approval
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        /// @dev txData with 1e18 input amount
        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            superform,
            ETH,
            ETH,
            ETH,
            false,
            superform,
            uint256(ETH),
            1e18,
            //1e18,
            false,
            0,
            1,
            1,
            1
        );

        /// @dev superform data with 2e18 final amount
        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            2e18,
            100,
            false,
            LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, true), getContract(ETH, "DAI"), ETH, 0),
            "",
            refundAddress,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev make sure the form proxy has enough usdc for the user to hack it
        MockERC20(getContract(ETH, "DAI")).transfer(superform, 3e18);
        /// balanceBefore = 3e18
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);

        vm.expectRevert(Error.DIRECT_DEPOSIT_INVALID_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }

    function test_superformDirectWithdrawalWithMaliciousTxData() public {
        _successfulDeposit();

        /// scenario: user could hack the funds from the form
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );
        address DAI = getContract(ETH, "DAI");
        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            SuperPositions(getContract(ETH, "SuperPositions")).balanceOf(deployer, superformId),
            100,
            false,
            LiqRequest(1, _buildMaliciousTxData(1, DAI, superform, ETH, 2e18, deployer), DAI, ETH, 0),
            "",
            refundAddress,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        SuperPositions(getContract(ETH, "SuperPositions")).increaseAllowance(
            getContract(ETH, "SuperformRouter"), superformId, 1e18
        );

        /// @dev approves before call
        vm.expectRevert(Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultWithdraw(req);
    }

    function test_superformXChainWithdrawalWithoutUpdatingTxData() public {
        /// @dev prank deposits (just mint super-shares)
        _successfulDeposit();

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);
        IBaseForm(superform).getVaultAddress();

        MockERC20(getContract(ETH, "DAI")).transfer(superform, 1e18);
        vm.stopPrank();

        /// @dev simulating withdrawals with malicious tx data
        vm.startPrank(getContract(ETH, "CoreStateRegistry"));

        InitSingleVaultData memory data = InitSingleVaultData(
            1,
            1,
            superformId,
            1e18,
            100,
            false,
            LiqRequest(1, bytes(""), getContract(ETH, "DAI"), ARBI, 0),
            refundAddress,
            ""
        );

        vm.expectRevert(Error.WITHDRAW_TX_DATA_NOT_UPDATED.selector);
        IBaseForm(superform).xChainWithdrawFromVault(data, deployer, ARBI);
    }

    function test_superformXChainWithdrawalWithMaliciousTxData() public {
        /// @dev prank deposits (just mint super-shares)
        _successfulDeposit();

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        uint256 amount = SuperPositions(getContract(ETH, "SuperPositions")).balanceOf(deployer, superformId);

        MockERC20(getContract(ETH, "DAI")).transfer(superform, 1e18);
        vm.stopPrank();

        /// @dev simulating withdrawals with malicious tx data
        vm.startPrank(getContract(ETH, "CoreStateRegistry"));

        InitSingleVaultData memory data = InitSingleVaultData(
            1,
            1,
            superformId,
            amount,
            100,
            false,
            LiqRequest(
                1,
                _buildMaliciousTxData(1, getContract(ETH, "DAI"), superform, ARBI, 2e18, deployer),
                getContract(ETH, "DAI"),
                ARBI,
                0
            ),
            refundAddress,
            ""
        );

        vm.expectRevert(Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST.selector);
        IBaseForm(superform).xChainWithdrawFromVault(data, deployer, ARBI);
    }

    function test_superformDirectWithdrawWithInvalidLiqDataToken() public {
        /// @dev prank deposits (just mint super-shares)
        _successfulDeposit();

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        MockERC20(getContract(ETH, "DAI")).transfer(superform, 1e18);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            SuperPositions(getContract(ETH, "SuperPositions")).balanceOf(deployer, superformId),
            100,
            false,
            LiqRequest(1, "", getContract(ETH, "WETH"), ETH, 0),
            "",
            refundAddress,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        SuperPositions(getContract(ETH, "SuperPositions")).increaseAllowance(
            getContract(ETH, "SuperformRouter"), superformId, 1e18
        );
        vm.expectRevert(Error.DIRECT_WITHDRAW_INVALID_COLLATERAL.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultWithdraw(req);

        vm.stopPrank();
    }

    function test_superformXChainWithInvalidLiqDataToken() public {
        /// @dev prank deposits (just mint super-shares)
        _successfulDeposit();

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        MockERC20(getContract(ETH, "DAI")).transfer(superform, 1e18);
        vm.stopPrank();

        bytes memory invalidTxData = abi.encode(1);

        InitSingleVaultData memory data = InitSingleVaultData(
            1,
            1,
            superformId,
            0.9e18,
            100,
            false,
            LiqRequest(1, invalidTxData, getContract(ETH, "WETH"), ARBI, 0),
            refundAddress,
            ""
        );

        vm.startPrank(getContract(ETH, "CoreStateRegistry"));

        vm.expectRevert(Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST.selector);
        IBaseForm(superform).xChainWithdrawFromVault(data, deployer, ARBI);

        vm.stopPrank();
    }

    function test_revert_baseForm_notSuperRegistry() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        SuperformFactory superformFactory = SuperformFactory(getContract(chainId, "SuperformFactory"));

        address newSr = address(new SuperRegistry(address(0x2222)));
        vm.mockCall(
            newSr, abi.encodeWithSelector(SuperRegistry(newSr).getStateRegistry.selector, 1), abi.encode(address(0x444))
        );
        /// @dev Deploying Form with incorrect SuperRegistry
        address formImplementation = address(new ERC4626Form(newSr));
        vm.clearMockedCalls();

        uint32 formImplementationId = 0;

        /// @dev Vaults For The Superforms
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");

        /// @dev Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        superformFactory.addFormImplementation(formImplementation, formImplementationId);

        /// @dev should revert as superRegistry coming from SuperformFactory does not
        /// match the one set in the ERC4626Form
        vm.expectRevert(Error.NOT_SUPER_REGISTRY.selector);
        superformFactory.createSuperform(formImplementationId, address(vault));
    }

    function test_directDepositInvalidData() public {
        /// @dev no txData is sent for a vault that requires it
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);
        address superformRouter = getContract(ETH, "SuperformRouter");
        address superform1 = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        address superform2 = getContract(
            ETH, string.concat("WETH", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId1 = DataLib.packSuperform(superform1, FORM_IMPLEMENTATION_IDS[0], ETH);
        uint256 superformId2 = DataLib.packSuperform(superform2, FORM_IMPLEMENTATION_IDS[0], ETH);

        uint256[] memory superformIds = new uint256[](2);
        superformIds[0] = superformId1;
        superformIds[1] = superformId2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e18;
        amounts[1] = 1e18;

        uint256[] memory maxSlippages = new uint256[](2);
        maxSlippages[0] = 1000;
        maxSlippages[1] = 1000;

        LiqRequest[] memory liqReqs = new LiqRequest[](2);

        liqReqs[0] = LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0);
        liqReqs[1] = LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0);

        MultiVaultSFData memory data =
            MultiVaultSFData(superformIds, amounts, maxSlippages, new bool[](2), liqReqs, "", refundAddress, "");

        SingleDirectMultiVaultStateReq memory req = SingleDirectMultiVaultStateReq(data);

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(address(superformRouter), 2e18);

        vm.expectRevert(Error.DIRECT_DEPOSIT_INVALID_DATA.selector);
        SuperformRouter(payable(superformRouter)).singleDirectMultiVaultDeposit{ value: 10 ether }(req);
        vm.stopPrank();
    }

    function test_successfulDeposit_insufficientAllowance() public {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId, 1e18, 100, false, LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0), "", refundAddress, ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        vm.mockCall(
            getContract(ETH, "DAI"),
            abi.encodeWithSelector(IERC20(getContract(ETH, "DAI")).allowance.selector, router, superform),
            abi.encode(0)
        );
        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);
        vm.expectRevert(Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);

        data = SingleVaultSFData(
            superformId,
            1e18,
            100,
            false,
            LiqRequest(
                1,
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        1,
                        getContract(ETH, "DAI"),
                        getContract(ETH, "DAI"),
                        superform,
                        ETH,
                        ETH,
                        1e18,
                        getContract(ETH, "CoreStateRegistry"),
                        false
                    )
                ),
                getContract(ETH, "DAI"),
                ETH,
                0
            ),
            "",
            refundAddress,
            ""
        );
        req = SingleDirectSingleVaultStateReq(data);
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);
        vm.expectRevert(Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);

        vm.clearMockedCalls();
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _successfulDeposit() internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId, 1e18, 100, false, LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0), "", refundAddress, ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }

    function _buildMaliciousTxData(
        uint8 liqBridgeKind_,
        address underlyingToken_,
        address from_,
        uint64 toChainId_,
        uint256 amount_,
        address receiver_
    )
        internal
        view
        returns (bytes memory txData)
    {
        if (liqBridgeKind_ == 1) {
            ILiFi.BridgeData memory bridgeData;
            LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);

            swapData[0] = LibSwap.SwapData(
                address(0),
                /// callTo (arbitrary)
                address(0),
                /// callTo (approveTo)
                underlyingToken_,
                underlyingToken_,
                amount_,
                abi.encode(from_, FORKS[toChainId_]),
                false // arbitrary
            );

            bridgeData = ILiFi.BridgeData(
                bytes32("1"),
                /// request id
                "",
                "",
                address(0),
                underlyingToken_,
                receiver_,
                amount_,
                uint256(toChainId_),
                false,
                true
            );

            txData = abi.encodeWithSelector(LiFiMock.swapAndStartBridgeTokensViaBridge.selector, bridgeData, swapData);
        }
    }
}

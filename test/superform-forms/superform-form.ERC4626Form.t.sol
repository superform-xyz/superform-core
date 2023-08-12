// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {Error} from "src/utils/Error.sol";
import "../utils/ProtocolActions.sol";

contract SuperformERC4626FormTest is BaseSetup {
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

        string memory symbol = ERC4626Form(payable(superformCreated)).superformYieldTokenSymbol();

        assertEq(symbol, "SUP-Mock");
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

        uint256 withdrawableAssets = ERC4626Form(payable(superformCreated)).getPreviewPricePerVaultShare();

        assertEq(withdrawableAssets, 1000000000000000000);
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

        uint256 totalAssets = ERC4626Form(payable(superformCreated)).getTotalAssets();

        assertEq(totalAssets, 0);
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

        uint256 vaultShareBalance = ERC4626Form(payable(superformCreated)).getVaultShareBalance();

        assertEq(vaultShareBalance, 0);
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

        uint256 priceVaultShare = ERC4626Form(payable(superformCreated)).getPricePerVaultShare();

        assertEq(priceVaultShare, 1000000000000000000);
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

        uint256 vaultDecimals = ERC4626Form(payable(superformCreated)).getVaultDecimals();

        assertEq(vaultDecimals, 18);
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

        string memory vaultName = ERC4626Form(payable(superformCreated)).getVaultName();

        assertEq(vaultName, "Mock Vault");
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

        string memory tokenName = ERC4626Form(payable(superformCreated)).superformYieldTokenName();

        assertEq(tokenName, "Superform Mock Vault");
    }

    function test_superformDirectDepositWithoutAllowance() public {
        /// scenario: user deposits with his own collateral but failed to approve
        vm.selectFork(FORKS[ETH]);

        address superform = getContract(
            ETH,
            string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            100,
            LiqRequest(1, "", getContract(ETH, "USDT"), 1e18, 0, ""),
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        /// @dev no approval before call
        vm.expectRevert(Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }

    function test_superformDirectDepositWithAllowance() public {
        _successfulDeposit();
    }

    function test_superformDirectDepositWithoutCollateral() public {
        /// scenario: user deposits by utilizing any crude collateral available in the beacon proxy
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);
        /// try depositing without approval
        address superform = getContract(
            ETH,
            string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            2e18,
            100,
            LiqRequest(1, "", getContract(ETH, "USDT"), 1e18, 0, ""),
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        (address formBeacon, , ) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);

        /// @dev make sure the beacon proxy has enough usdc for the user to hack it
        MockERC20(getContract(ETH, "USDT")).transfer(formBeacon, 3e18);
        MockERC20(getContract(ETH, "USDT")).approve(formBeacon, 1e18);

        vm.expectRevert(Error.DIRECT_DEPOSIT_INVALID_DATA.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }

    function test_superformDirectWithdrawalWithMaliciousTxData() public {
        _successfulDeposit();

        /// scenario: user could hack the funds from the form
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH,
            string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );
        address USDT = getContract(ETH, "USDT");
        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ETH);
        (address formBeacon, , ) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            100,
            LiqRequest(1, _buildMaliciousTxData(1, USDT, formBeacon, ETH, 2e18, deployer), USDT, 2e18, 0, ""),
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

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
            ETH,
            string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ETH);
        (address formBeacon, , ) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);
        address vault = IBaseForm(superform).getVaultAddress();

        MockERC20(getContract(ETH, "USDT")).transfer(formBeacon, 1e18);
        vm.stopPrank();

        /// @dev simulating withdrawals with malicious tx data
        vm.startPrank(getContract(ETH, "CoreStateRegistry"));

        InitSingleVaultData memory data = InitSingleVaultData(
            1,
            superformId,
            1e18,
            100,
            LiqRequest(1, bytes(""), getContract(ETH, "USDT"), 3e18, 0, ""),
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
            ETH,
            string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ETH);
        (address formBeacon, , ) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);
        address vault = IBaseForm(superform).getVaultAddress();

        MockERC20(getContract(ETH, "USDT")).transfer(formBeacon, 1e18);
        vm.stopPrank();

        /// @dev simulating withdrawals with malicious tx data
        vm.startPrank(getContract(ETH, "CoreStateRegistry"));

        InitSingleVaultData memory data = InitSingleVaultData(
            1,
            superformId,
            1e18,
            100,
            LiqRequest(
                1,
                _buildMaliciousTxData(1, getContract(ETH, "USDT"), formBeacon, ARBI, 2e18, deployer),
                getContract(ETH, "USDT"),
                3e18,
                0,
                ""
            ),
            ""
        );

        vm.expectRevert(Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST.selector);
        IBaseForm(superform).xChainWithdrawFromVault(data, deployer, ARBI);
    }

    function test_revert_baseForm_notSuperRegistry() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");
        SuperformFactory superformFactory = SuperformFactory(getContract(chainId, "SuperformFactory"));

        /// @dev Deploying Form with incorrect SuperRegistry
        address formImplementation = address(new ERC4626Form(address(0x1)));
        uint32 formBeaconId = 0;

        /// @dev Vaults For The Superforms
        MockERC20 asset = new MockERC20("Mock ERC20 Token", "Mock", address(this), uint256(1000));
        VaultMock vault = new VaultMock(asset, "Mock Vault", "Mock");

        /// @dev Deploying Forms Using AddBeacon. Not Testing Reverts As Already Tested
        superformFactory.addFormBeacon(formImplementation, formBeaconId, salt);

        /// @dev should revert as superRegistry coming from SuperformFactory does not
        /// match the one set in the ERC4626Form
        vm.expectRevert(Error.NOT_SUPER_REGISTRY.selector);
        superformFactory.createSuperform(formBeaconId, address(vault));
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _successfulDeposit() internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH,
            string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[0], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            100,
            LiqRequest(1, "", getContract(ETH, "USDT"), 1e18, 0, ""),
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        (address formBeacon, , ) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);

        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(formBeacon, 1e18);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }

    function _buildMaliciousTxData(
        uint8 liqBridgeKind_,
        address underlyingToken_,
        address from_,
        uint64 toChainId_,
        uint256 amount_,
        address receiver_
    ) internal returns (bytes memory txData) {
        if (liqBridgeKind_ == 1) {
            ISocketRegistry.BridgeRequest memory bridgeRequest;
            ISocketRegistry.MiddlewareRequest memory middlewareRequest;
            ISocketRegistry.UserRequest memory userRequest;
            /// @dev middlware request is used if there is a swap involved before the bridging action
            /// @dev the input token should be the token the user deposits, which will be swapped to the input token of bridging request
            middlewareRequest = ISocketRegistry.MiddlewareRequest(
                1, /// request id
                0,
                underlyingToken_,
                abi.encode(from_, FORKS[toChainId_])
            );

            /// @dev empty bridge request
            bridgeRequest = ISocketRegistry.BridgeRequest(
                0, /// id
                0,
                address(0),
                abi.encode(receiver_, FORKS[toChainId_])
            );

            userRequest = ISocketRegistry.UserRequest(
                receiver_,
                uint256(toChainId_),
                amount_,
                middlewareRequest,
                bridgeRequest
            );

            txData = abi.encodeWithSelector(SocketRouterMock.outboundTransferTo.selector, userRequest);
        } else if (liqBridgeKind_ == 2) {
            ILiFi.BridgeData memory bridgeData;
            ILiFi.SwapData[] memory swapData = new ILiFi.SwapData[](1);

            swapData[0] = ILiFi.SwapData(
                address(0), /// callTo (arbitrary)
                address(0), /// callTo (approveTo)
                underlyingToken_,
                underlyingToken_,
                amount_,
                abi.encode(from_, FORKS[toChainId_]),
                false // arbitrary
            );

            bridgeData = ILiFi.BridgeData(
                bytes32("1"), /// request id
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

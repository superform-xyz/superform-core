// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import { MockERC20 } from "test/mocks/MockERC20.sol";
import { SuperformFactory } from "src/SuperformFactory.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import { ProtocolActions } from "test/utils/ProtocolActions.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { SuperformRouter } from "src/SuperformRouter.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { ERC4626TimelockForm } from "src/forms/ERC4626TimelockForm.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import "src/types/DataTypes.sol";
import "forge-std/console.sol";

contract SuperformERC4626TimelockFormTest is ProtocolActions {
    uint64 internal chainId = ETH;
    address receiverAddress = address(444);

    function setUp() public override {
        super.setUp();
    }

    function test_superformXChainTimelockWithdrawalWithoutUpdatingTxData() public {
        /// @dev prank deposits (just mint super-shares)
        _successfulDeposit();

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("DAI", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[1]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[1], ETH);

        MockERC20(getContract(ETH, "DAI")).transfer(superform, 1e18);
        vm.stopPrank();

        InitSingleVaultData memory data = InitSingleVaultData(
            1,
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest(bytes(""), getContract(ETH, "DAI"), address(0), 1, ARBI, 0),
            false,
            false,
            receiverAddress,
            ""
        );

        /// @dev simulating withdrawals with malicious tx data
        vm.prank(getContract(ETH, "CoreStateRegistry"));
        IBaseForm(superform).xChainWithdrawFromVault(data, deployer, ARBI);

        vm.prank(getContract(ETH, "TimelockStateRegistry"));
        vm.expectRevert(Error.WITHDRAW_TX_DATA_NOT_UPDATED.selector);
        ERC4626TimelockForm(payable(superform)).withdrawAfterCoolDown(
            TimelockPayload(1, ETH, block.timestamp, data, TimelockStatus.PENDING)
        );
    }

    function test_superformXChainTimelockWithdrawalEmptyTokenNonEmptyTxData() public {
        /// @dev prank deposits (just mint super-shares)
        _successfulDeposit();

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("DAI", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[1]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[1], ETH);

        MockERC20(getContract(ETH, "DAI")).transfer(superform, 1e18);
        vm.stopPrank();

        bytes memory invalidNonEmptyTxData = abi.encode(1);

        InitSingleVaultData memory data = InitSingleVaultData(
            1,
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest(invalidNonEmptyTxData, address(0), address(0), 1, ETH, 0),
            false,
            false,
            receiverAddress,
            ""
        );

        /// @dev simulating withdrawals with malicious tx data
        vm.prank(getContract(ETH, "CoreStateRegistry"));
        IBaseForm(superform).xChainWithdrawFromVault(data, deployer, ARBI);

        vm.prank(getContract(ETH, "TimelockStateRegistry"));
        vm.expectRevert(Error.WITHDRAW_TOKEN_NOT_UPDATED.selector);
        ERC4626TimelockForm(payable(superform)).withdrawAfterCoolDown(
            TimelockPayload(1, ETH, block.timestamp, data, TimelockStatus.PENDING)
        );
    }

    function test_superformXChainTimelockWithdrawalEmptyTokenAndTxData() public {
        /// @dev prank deposits (just mint super-shares)
        _successfulDeposit();

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("DAI", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[1]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[1], ETH);

        MockERC20(getContract(ETH, "DAI")).transfer(superform, 1e18);
        vm.stopPrank();

        InitSingleVaultData memory data = InitSingleVaultData(
            1,
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest("", address(0), address(0), 1, ETH, 0),
            false,
            false,
            receiverAddress,
            ""
        );

        vm.prank(getContract(ETH, "CoreStateRegistry"));
        IBaseForm(superform).xChainWithdrawFromVault(data, deployer, ARBI);

        vm.prank(getContract(ETH, "TimelockStateRegistry"));
        ERC4626TimelockForm(payable(superform)).withdrawAfterCoolDown(
            TimelockPayload(1, ETH, block.timestamp, data, TimelockStatus.PENDING)
        );
    }

    function test_superformXChainTimelockWithdrawalLiqDataAmountGreaterThanAmountRedeemed() public {
        /// @dev prank deposits (just mint super-shares)
        _successfulDeposit();

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("DAI", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[1]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[1], ETH);

        MockERC20(getContract(ETH, "DAI")).transfer(superform, 1e18);
        vm.stopPrank();

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            superform,
            ETH,
            ARBI,
            ETH,
            false,
            superform,
            uint256(ETH),
            2e18,
            //2e18,
            false,
            0,
            1,
            1,
            1
        );

        InitSingleVaultData memory data = InitSingleVaultData(
            1,
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest(
                _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ETH, 0
            ),
            false,
            false,
            receiverAddress,
            ""
        );

        vm.prank(getContract(ETH, "CoreStateRegistry"));
        IBaseForm(superform).xChainWithdrawFromVault(data, deployer, ARBI);

        vm.expectRevert(Error.XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST.selector);
        vm.prank(getContract(ETH, "TimelockStateRegistry"));
        ERC4626TimelockForm(payable(superform)).withdrawAfterCoolDown(
            TimelockPayload(1, ETH, block.timestamp, data, TimelockStatus.PENDING)
        );
    }

    function test_superformDirectTimelockWithdrawalLiqDataAmountGreaterThanAmountRedeemed() public {
        /// @dev prank deposits (just mint super-shares)
        _successfulDeposit();

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("DAI", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[1]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[1], ETH);

        MockERC20(getContract(ETH, "DAI")).transfer(superform, 1e18);
        vm.stopPrank();

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            superform,
            ETH,
            ARBI,
            ETH,
            false,
            superform,
            uint256(ETH),
            2e18,
            //2e18,
            false,
            0,
            1,
            1,
            1
        );

        InitSingleVaultData memory data = InitSingleVaultData(
            1,
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest(
                _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ETH, 0
            ),
            false,
            false,
            receiverAddress,
            ""
        );

        vm.prank(getContract(ETH, "SuperformRouter"));
        IBaseForm(superform).directWithdrawFromVault(data, deployer);

        vm.expectRevert(Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST.selector);
        vm.prank(getContract(ETH, "TimelockStateRegistry"));
        ERC4626TimelockForm(payable(superform)).withdrawAfterCoolDown(
            TimelockPayload(0, ETH, block.timestamp, data, TimelockStatus.PENDING)
        );
    }

    function test_superformDirectTimelockWithdrawalInvalidVaultImplementation() public {
        /// @dev prank deposits (just mint super-shares)
        _successfulDeposit();

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("DAI", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[1]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[1], ETH);

        MockERC20(getContract(ETH, "DAI")).transfer(superform, 1e18);
        vm.stopPrank();

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            superform,
            ETH,
            ARBI,
            ETH,
            false,
            superform,
            uint256(ETH),
            2e18,
            //2e18,
            false,
            0,
            1,
            1,
            1
        );

        InitSingleVaultData memory data = InitSingleVaultData(
            1,
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest(
                _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "DAI"), address(0), 1, ETH, 0
            ),
            false,
            false,
            receiverAddress,
            ""
        );

        vm.prank(getContract(ETH, "SuperformRouter"));
        IBaseForm(superform).directWithdrawFromVault(data, deployer);

        data.amount = 0.5e18;

        vm.expectRevert(Error.VAULT_IMPLEMENTATION_FAILED.selector);
        vm.prank(getContract(ETH, "TimelockStateRegistry"));
        ERC4626TimelockForm(payable(superform)).withdrawAfterCoolDown(
            TimelockPayload(0, ETH, block.timestamp, data, TimelockStatus.PENDING)
        );
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _successfulDeposit() internal {
        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("DAI", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[1]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[1], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            1e18,
            100,
            LiqRequest(bytes(""), getContract(ETH, "DAI"), address(0), 1, ETH, 0),
            bytes(""),
            false,
            false,
            receiverAddress,
            receiverAddress,
            bytes("")
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }
}

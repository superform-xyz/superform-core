// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import { Error } from "src/utils/Error.sol";
import { MockERC20 } from "test/mocks/MockERC20.sol";
import { SuperformFactory } from "src/SuperformFactory.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import { ProtocolActions } from "test/utils/ProtocolActions.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { SuperformRouter } from "src/SuperformRouter.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { ERC4626TimelockForm } from "src/forms/ERC4626TimelockForm.sol";
import "src/types/DataTypes.sol";

contract SuperformERC4626TimelockFormTest is ProtocolActions {
    uint64 internal chainId = ETH;
    address refundAddress = address(444);

    function setUp() public override {
        super.setUp();
    }

    function test_superformXChainTimelockWithdrawalWithoutUpdatingTxData() public {
        /// @dev prank deposits (just mint super-shares)
        _successfulDeposit();

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("USDT", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_BEACON_IDS[1]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[1], ETH);
        (address formBeacon,,) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);

        MockERC20(getContract(ETH, "USDT")).transfer(formBeacon, 1e18);
        vm.stopPrank();

        InitSingleVaultData memory data = InitSingleVaultData(
            1,
            1,
            superformId,
            1e18,
            100,
            false,
            LiqRequest(1, bytes(""), getContract(ETH, "USDT"), ARBI, 0),
            refundAddress,
            ""
        );

        /// @dev simulating withdrawals with malicious tx data
        vm.prank(getContract(ETH, "CoreStateRegistry"));
        IBaseForm(superform).xChainWithdrawFromVault(data, deployer, ARBI);

        vm.prank(getContract(ETH, "TimelockStateRegistry"));
        vm.expectRevert(Error.WITHDRAW_TX_DATA_NOT_UPDATED.selector);
        ERC4626TimelockForm(payable(superform)).withdrawAfterCoolDown(
            420, TimelockPayload(1, deployer, ETH, block.timestamp, data, TwoStepsStatus.PENDING)
        );
    }

    function test_superformXChainTimelockWithdrawalEmptyTokenNonEmptyTxData() public {
        /// @dev prank deposits (just mint super-shares)
        _successfulDeposit();

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("USDT", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_BEACON_IDS[1]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[1], ETH);
        (address formBeacon,,) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);

        MockERC20(getContract(ETH, "USDT")).transfer(formBeacon, 1e18);
        vm.stopPrank();

        bytes memory invalidNonEmptyTxData = abi.encode(1);

        InitSingleVaultData memory data = InitSingleVaultData(
            1,
            1,
            superformId,
            1e18,
            100,
            false,
            LiqRequest(1, invalidNonEmptyTxData, address(0), ETH, 0),
            refundAddress,
            ""
        );

        /// @dev simulating withdrawals with malicious tx data
        vm.prank(getContract(ETH, "CoreStateRegistry"));
        IBaseForm(superform).xChainWithdrawFromVault(data, deployer, ARBI);

        vm.prank(getContract(ETH, "TimelockStateRegistry"));
        vm.expectRevert(Error.EMPTY_TOKEN_NON_EMPTY_TXDATA.selector);
        ERC4626TimelockForm(payable(superform)).withdrawAfterCoolDown(
            420, TimelockPayload(1, deployer, ETH, block.timestamp, data, TwoStepsStatus.PENDING)
        );
    }

    function test_superformXChainTimelockWithdrawalEmptyTokenAndTxData() public {
        /// @dev prank deposits (just mint super-shares)
        _successfulDeposit();

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("USDT", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_BEACON_IDS[1]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[1], ETH);
        (address formBeacon,,) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);

        MockERC20(getContract(ETH, "USDT")).transfer(formBeacon, 1e18);
        vm.stopPrank();

        InitSingleVaultData memory data = InitSingleVaultData(
            1, 1, superformId, 1e18, 100, false, LiqRequest(1, "", address(0), ETH, 0), refundAddress, ""
        );

        vm.prank(getContract(ETH, "CoreStateRegistry"));
        IBaseForm(superform).xChainWithdrawFromVault(data, deployer, ARBI);

        vm.prank(getContract(ETH, "TimelockStateRegistry"));
        ERC4626TimelockForm(payable(superform)).withdrawAfterCoolDown(
            420, TimelockPayload(1, deployer, ETH, block.timestamp, data, TwoStepsStatus.PENDING)
        );
    }

    function test_superformXChainTimelockWithdrawalLiqDataAmountGreaterThanAmountRedeemed() public {
        /// @dev prank deposits (just mint super-shares)
        _successfulDeposit();

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("USDT", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_BEACON_IDS[1]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[1], ETH);

        MockERC20(getContract(ETH, "USDT")).transfer(superform, 1e18);
        vm.stopPrank();

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "USDT"),
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
            false,
            0
        );

        InitSingleVaultData memory data = InitSingleVaultData(
            1,
            1,
            superformId,
            1e18,
            100,
            false,
            LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, false), getContract(ETH, "USDT"), ETH, 0),
            refundAddress,
            ""
        );

        vm.prank(getContract(ETH, "CoreStateRegistry"));
        IBaseForm(superform).xChainWithdrawFromVault(data, deployer, ARBI);

        vm.expectRevert(Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST.selector);
        vm.prank(getContract(ETH, "TimelockStateRegistry"));
        ERC4626TimelockForm(payable(superform)).withdrawAfterCoolDown(
            420, TimelockPayload(1, deployer, ETH, block.timestamp, data, TwoStepsStatus.PENDING)
        );
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _successfulDeposit() internal {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH, string.concat("USDT", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_BEACON_IDS[1]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[1], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            100,
            false,
            LiqRequest(1, bytes(""), getContract(ETH, "USDT"), ETH, 0),
            bytes(""),
            refundAddress,
            bytes("")
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(router, 1e18);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }
}

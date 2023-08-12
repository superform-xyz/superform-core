// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {Error} from "src/utils/Error.sol";
import "../utils/ProtocolActions.sol";

contract SuperformERC4626TimelockFormTest is BaseSetup {
    uint64 internal chainId = ETH;

    function setUp() public override {
        super.setUp();
    }

    function test_superformXChainTimelockWithdrawalWithoutUpdatingTxData() public {
        /// @dev prank deposits (just mint super-shares)
        _successfulDeposit();

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform = getContract(
            ETH,
            string.concat("USDT", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_BEACON_IDS[1]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[1], ETH);
        (address formBeacon, , ) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);
        address vault = IBaseForm(superform).getVaultAddress();

        MockERC20(getContract(ETH, "USDT")).transfer(formBeacon, 1e18);
        vm.stopPrank();

        InitSingleVaultData memory data = InitSingleVaultData(
            1,
            superformId,
            1e18,
            100,
            LiqRequest(1, bytes(""), getContract(ETH, "USDT"), 3e18, 0, ""),
            ""
        );

        /// @dev simulating withdrawals with malicious tx data
        vm.prank(getContract(ETH, "CoreStateRegistry"));
        IBaseForm(superform).xChainWithdrawFromVault(data, deployer, ARBI);

        vm.prank(getContract(ETH, "TwoStepsFormStateRegistry"));
        vm.expectRevert(Error.WITHDRAW_TX_DATA_NOT_UPDATED.selector);
        ERC4626TimelockForm(payable(getContract(ETH, "ERC4626TimelockForm"))).withdrawAfterCoolDown(
            420,
            TimeLockPayload(1, deployer, ETH, block.timestamp, data, TimeLockStatus.PENDING)
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
            ETH,
            string.concat("USDT", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_BEACON_IDS[1]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[1], ETH);

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
}

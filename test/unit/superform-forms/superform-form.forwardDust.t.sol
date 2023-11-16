// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import { Error } from "src/utils/Error.sol";
import { MockERC20 } from "test/mocks/MockERC20.sol";
import { VaultMock } from "test/mocks/VaultMock.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import "test/utils/ProtocolActions.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { SuperformRouter } from "src/SuperformRouter.sol";
import { SuperPositions } from "src/SuperPositions.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { IERC4626TimelockForm } from "src/forms/interfaces/IERC4626TimelockForm.sol";
import "src/types/DataTypes.sol";

contract ForwardDustFormTest is ProtocolActions {
    uint64 internal chainId = ETH;
    address refundAddress = address(444);

    function setUp() public override {
        super.setUp();
    }

    function test_forwardDustToPaymaster() public {
        address superform = _successfulDepositWithdraw("VaultMock", 0, 1e18, 0, true, deployer);

        uint256 balanceBefore = MockERC20(getContract(ARBI, "WETH")).balanceOf(superform);
        assertGt(balanceBefore, 0);
        IBaseForm(superform).forwardDustToPaymaster();
        uint256 balanceAfter = MockERC20(getContract(ARBI, "WETH")).balanceOf(superform);

        assertEq(balanceAfter, 0);
    }

    function test_forwardDustToPaymasterNoDust() public {
        address superform = _successfulDepositWithdraw("VaultMock", 0, 1e18, 0, false, deployer);

        uint256 balanceBefore = MockERC20(getContract(ARBI, "WETH")).balanceOf(superform);
        assertEq(balanceBefore, 0);
        IBaseForm(superform).forwardDustToPaymaster();
        uint256 balanceAfter = MockERC20(getContract(ARBI, "WETH")).balanceOf(superform);

        assertEq(balanceAfter, 0);
    }

    function test_forwardDustToPaymasterTimelocked() public {
        address superform = _successfulDepositWithdraw("ERC4626TimelockMock", 1, 1e18, 0, true, deployer);

        uint256 balanceBefore = MockERC20(getContract(ARBI, "WETH")).balanceOf(superform);
        assertGt(balanceBefore, 0);
        IBaseForm(superform).forwardDustToPaymaster();
        uint256 balanceAfter = MockERC20(getContract(ARBI, "WETH")).balanceOf(superform);

        assertEq(balanceAfter, 0);
    }

    function _successfulDepositWithdraw(
        string memory vaultKind_,
        uint256 formImplementationId_,
        uint256 amountToDeposit_,
        uint256 spAmountToRedeem_, // set to 0 for full withdraw
        bool nasty_,
        address user
    )
        internal
        returns (address superform)
    {
        /// @dev prank deposits (just mint super-shares)
        /// scenario: user deposits with his own token and has approved enough tokens
        vm.selectFork(FORKS[ARBI]);
        vm.startPrank(user);

        superform = getContract(
            ARBI,
            string.concat(
                "WETH", vaultKind_, "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[formImplementationId_])
            )
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[formImplementationId_], ARBI);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            amountToDeposit_,
            100,
            false,
            false,
            LiqRequest(1, "", getContract(ARBI, "WETH"), ARBI, 0),
            "",
            refundAddress,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ARBI, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ARBI, "WETH")).approve(router, amountToDeposit_);
        SuperformRouter(payable(router)).singleDirectSingleVaultDeposit(req);

        IBaseForm(superform).getVaultAddress();

        vm.stopPrank();

        uint256 superPositionBalance = SuperPositions(getContract(ARBI, "SuperPositions")).balanceOf(user, superformId);

        InitSingleVaultData memory data2 = InitSingleVaultData(
            1,
            superformId,
            spAmountToRedeem_ == 0 ? superPositionBalance : spAmountToRedeem_,
            100,
            false,
            false,
            LiqRequest(
                1,
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        1,
                        getContract(ARBI, "WETH"),
                        getContract(ETH, "WETH"),
                        superform,
                        ARBI,
                        ETH,
                        nasty_ ? 0.2e18 : IBaseForm(superform).previewRedeemFrom(superPositionBalance), // nastiness
                            // here
                        user,
                        false
                    )
                ),
                getContract(ARBI, "WETH"),
                ETH,
                0
            ),
            refundAddress,
            ""
        );
        vm.selectFork(FORKS[ARBI]);

        if (formImplementationId_ != 1) {
            vm.prank(getContract(ARBI, "CoreStateRegistry"));

            IBaseForm(superform).xChainWithdrawFromVault(data2, user, ETH);
        } else {
            vm.prank(getContract(ARBI, "TimelockStateRegistry"));
            IERC4626TimelockForm(superform).withdrawAfterCoolDown(
                spAmountToRedeem_ == 0 ? superPositionBalance : spAmountToRedeem_,
                TimelockPayload(1, user, ETH, block.timestamp, data2, TimelockStatus.PENDING)
            );
        }
    }
}

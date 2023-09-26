// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import { Error } from "src/utils/Error.sol";
import { ERC4626KYCDaoForm } from "src/forms/ERC4626KYCDaoForm.sol";

import "test/utils/ProtocolActions.sol";

contract SuperformERC4626KYCDaoFormTest is BaseSetup {
    uint64 internal chainId = ETH;
    address refundAddress = address(444);

    function setUp() public override {
        super.setUp();
    }

    /// @dev Test Vault Symbol
    function test_superformRevertKYCDaoCheck() public {
        /// scenario: user deposits with his own collateral and has approved enough tokens
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superform =
            getContract(ETH, string.concat("DAI", "kycDAO4626", "Superform", Strings.toString(FORM_BEACON_IDS[2])));

        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[2], ETH);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId, 1e18, 100, false, LiqRequest(1, "", getContract(ETH, "DAI"), ETH, 0), "", refundAddress, ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        address router = getContract(ETH, "SuperformRouter");

        /// @dev approves before call
        MockERC20(getContract(ETH, "DAI")).approve(router, 1e18);
        vm.expectRevert(ERC4626KYCDaoForm.NO_VALID_KYC_TOKEN.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);

        vm.stopPrank();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { RewardsDistributorHandler } from "./handlers/RewardsDistributorHandler.sol";
import { RewardsDistributorBase } from "./RewardsDistributorBase.invariant.t.sol";

contract RewardsDistributorClaimBatch is RewardsDistributorBase {
    function setUp() public override {
        super.setUp();

        /// @dev Note: disable some of the selectors to test a bunch of them only
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = RewardsDistributorHandler.full_batch_claim.selector;
        targetSelector(FuzzSelector({ addr: address(rewardsDistributorHandler), selectors: selectors }));
    }
}

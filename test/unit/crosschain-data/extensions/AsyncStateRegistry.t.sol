// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";

contract AsyncStateRegistryTest is ProtocolActions {
    uint64 internal chainId = ETH;
    address receiverAddress = address(444);

    AsyncStateRegistry asyncStateRegistry;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        asyncStateRegistry = AsyncStateRegistry(getContract(ETH, "AsyncStateRegistry"));
    }

    function test_asyncStateRegistry_dispatchPayload_disabled() external {
        vm.expectRevert(Error.DISABLED.selector);
        asyncStateRegistry.dispatchPayload(users[0], new uint8[](1), ARBI, abi.encode(""), "");
    }

    function test_asyncStateRegistry_onlyAsyncStateRegistryProcessor() external {
        /// NOT_PRIVILEGED_CALLER(0xf70a9d85bb21e0d3c60df1a0967a13197bfa3ecb2339758f6411fd3a74fd98da)
        vm.expectRevert();
        asyncStateRegistry.processPayload(1);
    }

    // function test_asyncStateRegistry_onlyAsyncSuperform() external {
    //     InitSingleVaultData memory data;
    //     data.superformId = 420;

    //     vm.expectRevert(Error.SUPERFORM_ID_NONEXISTENT.selector);
    //     asyncStateRegistry.receiveSyncWithdrawTxDataPayload(ARBI, data);

    //     uint256 superformId = _getSuperformId(ETH, "ERC4626Vault");
    //     data.superformId = uint64(superformId);
    //     asyncStateRegistry.receiveSyncWithdrawTxDataPayload(ARBI, data);
    // }
}

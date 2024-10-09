// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";
import { NOT_ASYNC_SUPERFORM } from "src/interfaces/IAsyncStateRegistry.sol";

contract AsyncStateRegistry7540Test is ProtocolActions {
    using DataLib for uint256;

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
        vm.expectRevert(
            abi.encodeWithSelector(
                Error.NOT_PRIVILEGED_CALLER.selector, keccak256("ASYNC_STATE_REGISTRY_PROCESSOR_ROLE")
            )
        );
        asyncStateRegistry.processPayload(1);
    }

    function test_asyncStateRegistry_onlyAsyncSuperform() external {
        InitSingleVaultData memory data;
        data.superformId = 420;

        vm.expectRevert(Error.SUPERFORM_ID_NONEXISTENT.selector);
        asyncStateRegistry.receiveSyncWithdrawTxDataPayload(ARBI, data);

        address superform = getContract(
            ETH, string.concat("USDC", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);
        data.superformId = superformId;
        vm.mockCall(
            getContract(ETH, "SuperformFactory"),
            abi.encodeWithSelector(ISuperformFactory.isSuperform.selector, superformId),
            abi.encode(true)
        );

        vm.startPrank(superform);
        vm.expectRevert(NOT_ASYNC_SUPERFORM.selector);
        asyncStateRegistry.receiveSyncWithdrawTxDataPayload(ARBI, data);
    }
}

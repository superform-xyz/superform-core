// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";
import {
    NOT_ASYNC_SUPERFORM,
    ERC7540_AMBIDS_NOT_ENCODED,
    INVALID_AMOUNT_IN_TXDATA,
    REQUEST_CONFIG_NON_EXISTENT,
    NOT_READY_TO_CLAIM,
    INVALID_UPDATED_TX_DATA
} from "src/interfaces/IAsyncStateRegistry.sol";
import { IERC7540FormBase } from "src/forms/interfaces/IERC7540Form.sol";

/// @dev harness contract to test internal functions
contract AsyncStateRegistryHarness is AsyncStateRegistry {
    constructor(ISuperRegistry _superRegistry) AsyncStateRegistry(_superRegistry) { }

    function validateTxDataAsync(
        uint64 srcChainId_,
        uint256 claimableRedeem_,
        bytes calldata txData_,
        LiqRequest memory liqData_,
        address user_,
        address superformAddress_
    )
        external
    {
        _validateTxDataAsync(srcChainId_, claimableRedeem_, txData_, liqData_, user_, superformAddress_);
    }

    function validateTxData(
        bool async_,
        uint64 srcChainId_,
        bytes calldata txData_,
        InitSingleVaultData memory data_,
        address superformAddress_
    )
        external
    {
        _validateTxData(async_, srcChainId_, txData_, data_, superformAddress_);
    }
}

contract AsyncStateRegistry7540Test is ProtocolActions {
    using DataLib for uint256;

    uint64 internal chainId = ETH;
    address receiverAddress = address(444);

    AsyncStateRegistry asyncStateRegistry;
    AsyncStateRegistryHarness asyncStateRegistryHarness;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[BSC_TESTNET]);
        asyncStateRegistry = AsyncStateRegistry(getContract(BSC_TESTNET, "AsyncStateRegistry"));
        asyncStateRegistryHarness =
            new AsyncStateRegistryHarness(ISuperRegistry(getContract(BSC_TESTNET, "SuperRegistry")));
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
            BSC_TESTNET, string.concat("USDC", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);
        data.superformId = superformId;
        vm.mockCall(
            getContract(BSC_TESTNET, "SuperformFactory"),
            abi.encodeWithSelector(ISuperformFactory.isSuperform.selector, superformId),
            abi.encode(true)
        );

        vm.startPrank(superform);
        vm.expectRevert(NOT_ASYNC_SUPERFORM.selector);
        asyncStateRegistry.receiveSyncWithdrawTxDataPayload(ARBI, data);
    }

    function test_asyncStateRegistry_receiveSyncWithdrawTxDataPayload() external {
        address superform = getContract(
            BSC_TESTNET,
            string.concat("tUSD", "ERC7540FullyAsyncMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[2]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[2], BSC_TESTNET);

        InitSingleVaultData memory data;
        data.superformId = superformId;

        vm.startPrank(superform);
        vm.expectRevert(Error.RECEIVER_ADDRESS_NOT_SET.selector);
        asyncStateRegistry.receiveSyncWithdrawTxDataPayload(ARBI, data);
    }

    function test_asyncStateRegistry_processPayload_invalidPayloadId() external {
        vm.startPrank(deployer);
        vm.expectRevert(Error.INVALID_PAYLOAD_ID.selector);
        asyncStateRegistry.processPayload(12_345);
        vm.stopPrank();
    }

    function test_asyncStateRegistry_updateRequestConfig_allErrors() external {
        address superform = getContract(
            BSC_TESTNET,
            string.concat("tUSD", "ERC7540FullyAsyncMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[2]))
        );
        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[2], BSC_TESTNET);

        vm.startPrank(superform);

        InitSingleVaultData memory data;
        data.superformId = superformId;
        vm.expectRevert(Error.RECEIVER_ADDRESS_NOT_SET.selector);
        asyncStateRegistry.updateRequestConfig(0, 0, false, 0, data);

        data.receiverAddress = users[0];
        asyncStateRegistry.updateRequestConfig(0, 0, false, 1, data);

        bytes memory extraFormData;
        bytes[] memory encodedDatas = new bytes[](1);
        encodedDatas[0] = abi.encode(superformId, abi.encode(new uint8[](0)));
        extraFormData = abi.encode(uint256(1), encodedDatas);
        data.extraFormData = extraFormData;

        vm.expectRevert(ERC7540_AMBIDS_NOT_ENCODED.selector);
        asyncStateRegistry.updateRequestConfig(1, SEPOLIA, true, 1, data);

        vm.stopPrank();
    }

    function test_asyncStateRegistry_validateTxDataAsync_InvalidAmountIn() external {
        address superform = getContract(
            BSC_TESTNET,
            string.concat("tUSD", "ERC7540FullyAsyncMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[2]))
        );

        bytes memory txData = _buildLiqBridgeTxData(
            LiqBridgeTxDataArgs(
                1,
                getContract(BSC_TESTNET, "tUSD"),
                getContract(BSC_TESTNET, "tUSD"),
                getContract(BSC_TESTNET, "tUSD"),
                address(superform),
                BSC_TESTNET,
                SEPOLIA,
                SEPOLIA,
                false,
                users[0],
                uint256(SEPOLIA),
                2e18,
                false,
                /// @dev placeholder value, not used
                0,
                1,
                1,
                1,
                address(0)
            ),
            false
        );

        LiqRequest memory liqRequest = LiqRequest("", getContract(BSC_TESTNET, "tUSD"), address(0), 1, SEPOLIA, 0);

        vm.expectRevert(INVALID_AMOUNT_IN_TXDATA.selector);
        asyncStateRegistryHarness.validateTxDataAsync(SEPOLIA, 1, txData, liqRequest, users[0], superform);
    }

    function test_asyncStateRegistry_validateTxData_slippageOutOfBounds() external {
        address superform = getContract(
            BSC_TESTNET,
            string.concat("tUSD", "ERC7540FullyAsyncMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[2]))
        );
        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[2], BSC_TESTNET);

        bytes memory txData = _buildLiqBridgeTxData(
            LiqBridgeTxDataArgs(
                1,
                getContract(BSC_TESTNET, "tUSD"),
                getContract(BSC_TESTNET, "tUSD"),
                getContract(BSC_TESTNET, "tUSD"),
                address(superform),
                BSC_TESTNET,
                SEPOLIA,
                SEPOLIA,
                false,
                users[0],
                uint256(SEPOLIA),
                2e18,
                false,
                /// @dev placeholder value, not used
                0,
                1,
                1,
                1,
                address(0)
            ),
            false
        );

        InitSingleVaultData memory data;

        data.amount = 2e18;
        data.superformId = superformId;
        data.receiverAddress = users[0];
        data.liqData = LiqRequest("", getContract(BSC_TESTNET, "tUSD"), address(0), 1, SEPOLIA, 0);

        vm.expectRevert(Error.SLIPPAGE_OUT_OF_BOUNDS.selector);
        asyncStateRegistryHarness.validateTxData(true, SEPOLIA, txData, data, superform);
    }

    function test_claimAvailableRedeem_allErrors() external {
        address superform = getContract(
            BSC_TESTNET,
            string.concat("tUSD", "ERC7540FullyAsyncMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[2]))
        );
        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[2], BSC_TESTNET);

        vm.startPrank(deployer);
        vm.expectRevert(REQUEST_CONFIG_NON_EXISTENT.selector);
        asyncStateRegistry.claimAvailableRedeem(users[0], superformId, bytes(""));
        vm.stopPrank();

        vm.startPrank(superform);
        InitSingleVaultData memory data;
        data.superformId = superformId;
        data.receiverAddress = users[0];

        asyncStateRegistry.updateRequestConfig(0, SEPOLIA, false, 0, data);
        vm.stopPrank();

        vm.startPrank(deployer);
        vm.mockCall(
            superform,
            abi.encodeWithSelector(IERC7540FormBase.getClaimableRedeemRequest.selector, 0, users[0]),
            abi.encode(0)
        );
        vm.expectRevert(NOT_READY_TO_CLAIM.selector);
        asyncStateRegistry.claimAvailableRedeem(users[0], superformId, bytes(""));

        vm.mockCall(
            superform,
            abi.encodeWithSelector(IERC7540FormBase.getClaimableRedeemRequest.selector, 0, users[0]),
            abi.encode(1)
        );
        vm.expectRevert(INVALID_UPDATED_TX_DATA.selector);
        asyncStateRegistry.claimAvailableRedeem(users[0], superformId, abi.encode("0xDEADBEEF"));
        vm.stopPrank();
    }
}

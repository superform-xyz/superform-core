// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import "test/utils/BaseSetup.sol";
import "test/utils/Utilities.sol";

import { DataLib } from "src/libraries/DataLib.sol";
import { SuperPositions } from "src/SuperPositions.sol";
import { Error } from "src/utils/Error.sol";

import { IERC1155A } from "ERC1155A/interfaces/IERC1155A.sol";

contract SuperPositionsTest is BaseSetup {
    bytes4 INTERFACE_ID_ERC165 = 0x01ffc9a7;

    string public URI = "https://superform.xyz/metadata/";
    SuperPositions public superPositions;
    address formImplementation;
    address vault;
    uint32 formImplementationId = 4;

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
        superPositions = SuperPositions(payable(getContract(ETH, "SuperPositions")));

        address superRegistry = getContract(ETH, "SuperRegistry");

        formImplementation = address(new ERC4626Form(superRegistry));
        vault = getContract(ETH, VAULT_NAMES[0][0]);
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );
    }

    /// Test dynamic url addition without freeze
    function test_addDynamicURI() public {
        vm.startPrank(deployer);
        superPositions.setDynamicURI(URI, false);

        assertEq(superPositions.dynamicURI(), URI);
    }

    /// Test uri freeze
    function test_freezeDynamicURI() public {
        vm.startPrank(deployer);
        superPositions.setDynamicURI(URI, true);

        vm.expectRevert(Error.DYNAMIC_URI_FROZEN.selector);
        superPositions.setDynamicURI(URI, true);
    }

    /// Test uri returned for id
    function test_readURI() public {
        vm.startPrank(deployer);
        superPositions.setDynamicURI(URI, false);

        assertEq(superPositions.uri(1), "https://superform.xyz/metadata/1");
    }

    /// Test support interface
    function test_SupportsInterface() public {
        assertEq(superPositions.supportsInterface(INTERFACE_ID_ERC165), true);
    }

    function test_revert_stateSync_TX_HISTORY_NOT_FOUND() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        ReturnSingleData memory maliciousReturnData = ReturnSingleData(0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));
        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.TX_HISTORY_NOT_FOUND.selector);
        superPositions.stateSync(maliciousMessage);
    }
    /// Test revert for invalid txType (single)

    function test_revert_stateSync_InvalidPayloadStatus() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        SuperPositions(address(superPositions)).updateTxHistory(0, txInfo);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD_STATUS.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_NotMinterStateRegistry() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "SuperformRouter"));
        vm.expectRevert(Error.NOT_MINTER_STATE_REGISTRY_ROLE.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_NotMinterStateRegistry_InvalidRegistryId() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        address superform = getContract(
            ARBI, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(0, superformId, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "TimelockStateRegistry"));
        vm.expectRevert(Error.NOT_MINTER_STATE_REGISTRY_ROLE.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_InvalidPayload_CallbackType() public {
        /// @dev CallbackType = 0 (INIT)
        uint256 txInfo = DataLib.packTxInfo(0, 0, 0, 1, address(0), ETH);
        ReturnSingleData memory maliciousReturnData = ReturnSingleData(0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_InvalidPayload_Multi() public {
        /// @dev multi = 1
        uint256 txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        SuperPositions(address(superPositions)).updateTxHistory(0, 1);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_SrcSenderMismatch() public {
        /// @dev returnDataSrcSender = address(0x1)
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0x1), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        SuperPositions(address(superPositions)).updateTxHistory(0, 1);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.SRC_SENDER_MISMATCH.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_SrcTxTypeMismatch() public {
        /// @dev TxType = 1
        uint256 txInfo = DataLib.packTxInfo(1, 2, 0, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        SuperPositions(address(superPositions)).updateTxHistory(0, txInfo);

        txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        ReturnSingleData memory maliciousReturnData = ReturnSingleData(0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.SRC_TX_TYPE_MISMATCH.selector);
        superPositions.stateSync(maliciousMessage);
    }

    ///////////////////////////////////////////////////////////////////////////

    function test_revert_stateMultiSync_TX_HISTORY_NOT_FOUND() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0), ETH);

        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.TX_HISTORY_NOT_FOUND.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }

    /// Test revert for invalid txType (multi)
    /// case: accidental messaging back for failed withdrawals with CallBackType FAIL
    function test_revert_stateMultiSync_InvalidPayloadStatus() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        SuperPositions(address(superPositions)).updateTxHistory(0, txInfo);

        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD_STATUS.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_InvalidPayload_CallbackType() public {
        uint256 txInfo = DataLib.packTxInfo(0, 0, 1, 1, address(0), ETH);

        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_InvalidPayload_Multi() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        SuperPositions(address(superPositions)).updateTxHistory(0, 1);

        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_SrcSenderMismatch() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0x1), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        SuperPositions(address(superPositions)).updateTxHistory(0, 1);

        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.SRC_SENDER_MISMATCH.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_SrcTxTypeMismatch() public {
        uint256 txInfo = DataLib.packTxInfo(1, 2, 1, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        SuperPositions(address(superPositions)).updateTxHistory(0, txInfo);
        txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0), ETH);
        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.SRC_TX_TYPE_MISMATCH.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }

    function test_registerSERC20() public {
        (uint256 superformId,) =
            SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(formImplementationId, vault);
        superPositions.registerSERC20(superformId);
    }

    function test_registerSERC20_invalidExtraData() public {
        uint8[] memory ambId = new uint8[](1);
        ambId[0] = 4;
        (uint256 superformId,) =
            SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(formImplementationId, vault);
        vm.expectRevert();
        superPositions.registerSERC20(superformId);
    }

    function test_withdrawFromInvalidChainId() public {
        address superform = getContract(
            ETH, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        vm.expectRevert(Error.SUPERFORM_ID_NONEXISTENT.selector);

        superPositions.registerSERC20(superformId);
    }

    function test_InvalidSuperFormAddress() public {
        uint256 invalidSuperFormId = DataLib.packSuperform(address(0), 4, ETH);
        vm.expectRevert(Error.SUPERFORM_ID_NONEXISTENT.selector);
        superPositions.registerSERC20(invalidSuperFormId);
    }

    function test_InvalidFormImplementation() public {
        uint256 invalidSuperFormId = DataLib.packSuperform(address(0x777), 0, ETH);
        vm.expectRevert(Error.SUPERFORM_ID_NONEXISTENT.selector);
        superPositions.registerSERC20(invalidSuperFormId);
    }

    function test_alreadyRegistered() public {
        (uint256 superformId,) =
            SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(formImplementationId, vault);
        superPositions.registerSERC20(superformId);
        vm.expectRevert(IERC1155A.SYNTHETIC_ERC20_ALREADY_REGISTERED.selector);

        superPositions.registerSERC20(superformId);
    }

    function test_broadcastAndDeploy() public {
        (uint256 superformId,) =
            SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(formImplementationId, vault);

        vm.recordLogs();
        superPositions.registerSERC20(superformId);

        vm.startPrank(deployer);
        _broadcastPayloadHelper(ETH, vm.getRecordedLogs());

        for (uint256 i; i < chainIds.length; i++) {
            if (chainIds[i] != ETH) {
                vm.selectFork(FORKS[chainIds[i]]);
                BroadcastRegistry(payable(getContract(chainIds[i], "BroadcastRegistry"))).processPayload(1);

                assertGt(
                    uint256(
                        uint160(
                            SuperPositions(getContract(chainIds[i], "SuperPositions")).synthethicTokenId(superformId)
                        )
                    ),
                    uint256(0)
                );
            }
        }
    }

    function test_revert_stateSyncBroadcast() public {
        vm.prank(deployer);
        vm.expectRevert(Error.NOT_BROADCAST_REGISTRY.selector);
        superPositions.stateSyncBroadcast("");
    }
}

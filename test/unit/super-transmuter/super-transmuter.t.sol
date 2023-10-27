// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import "test/utils/BaseSetup.sol";
import "test/utils/Utilities.sol";
import "test/utils/AmbParams.sol";

import { DataLib } from "src/libraries/DataLib.sol";
import { Transmuter } from "ERC1155A/transmuter/Transmuter.sol";
import { SuperTransmuter } from "src/SuperTransmuter.sol";
import { Error } from "src/utils/Error.sol";
import { VaultMock } from "test/mocks/VaultMock.sol";
import { StateSyncer } from "src/StateSyncer.sol";

contract SuperTransmuterTest is BaseSetup {
    SuperTransmuter public superTransmuter;
    address formImplementation;
    address vault;
    uint32 formImplementationId = 4;

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
        superTransmuter = SuperTransmuter(payable(getContract(ETH, "SuperTransmuter")));

        address superRegistry = getContract(ETH, "SuperRegistry");

        formImplementation = address(new ERC4626Form(superRegistry));
        vault = getContract(ETH, VAULT_NAMES[0][0]);
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId
        );
    }

    function test_registerTransmuter_invalid_interface() public {
        SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(formImplementationId, vault);
        vm.expectRevert(Error.DISABLED.selector);
        superTransmuter.registerTransmuter(1, "", "", 1);
    }

    function test_registerTransmuter() public {
        (uint256 superformId,) =
            SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(formImplementationId, vault);
        superTransmuter.registerTransmuter(superformId);
    }

    function test_withdrawFromInvalidChainId() public {
        address superform = getContract(
            ETH, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);

        superTransmuter.registerTransmuter(superformId);
    }

    function test_InvalidSuperFormAddress() public {
        uint256 invalidSuperFormId = DataLib.packSuperform(address(0), 4, ETH);
        vm.expectRevert(Error.NOT_SUPERFORM.selector);
        superTransmuter.registerTransmuter(invalidSuperFormId);
    }

    function test_InvalidFormImplementation() public {
        uint256 invalidSuperFormId = DataLib.packSuperform(address(0x777), 0, ETH);
        vm.expectRevert(Error.FORM_DOES_NOT_EXIST.selector);
        superTransmuter.registerTransmuter(invalidSuperFormId);
    }

    function test_alreadyRegistered() public {
        (uint256 superformId,) =
            SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(formImplementationId, vault);
        superTransmuter.registerTransmuter(superformId);
        vm.expectRevert(Transmuter.TRANSMUTER_ALREADY_REGISTERED.selector);

        superTransmuter.registerTransmuter(superformId);
    }

    function test_broadcastAndDeploy() public {
        (uint256 superformId,) =
            SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(formImplementationId, vault);

        vm.recordLogs();
        superTransmuter.registerTransmuter(superformId);

        vm.startPrank(deployer);
        _broadcastPayloadHelper(ETH, vm.getRecordedLogs());

        for (uint256 i; i < chainIds.length; i++) {
            if (chainIds[i] != ETH) {
                vm.selectFork(FORKS[chainIds[i]]);
                BroadcastRegistry(payable(getContract(chainIds[i], "BroadcastRegistry"))).processPayload(1);

                assertGt(
                    uint256(
                        uint160(
                            SuperTransmuter(getContract(chainIds[i], "SuperTransmuter")).synthethicTokenId(superformId)
                        )
                    ),
                    uint256(0)
                );
            }
        }
    }

    /// Test revert for invalid txType (single)
    function test_revert_stateSync_TRANSMUTER_NOT_REGISTERED() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        ReturnSingleData memory maliciousReturnData = ReturnSingleData(2, 0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.TRANSMUTER_NOT_REGISTERED.selector);
        superTransmuter.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_InvalidPayloadStatus() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        StateSyncer(address(superTransmuter)).updateTxHistory(0, txInfo);

        uint256 superformId = DataLib.packSuperform(
            getContract(
                ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ETH
        );

        superTransmuter.registerTransmuter(superformId);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(2, 0, superformId, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD_STATUS.selector);
        superTransmuter.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_InvalidPayload_CallbackType() public {
        /// @dev CallbackType = 0 (INIT)
        uint256 txInfo = DataLib.packTxInfo(0, 0, 0, 1, address(0), ETH);
        uint256 superformId = DataLib.packSuperform(
            getContract(
                ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ETH
        );

        superTransmuter.registerTransmuter(superformId);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(2, 0, superformId, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        superTransmuter.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_InvalidPayload_Multi() public {
        /// @dev multi = 1
        uint256 txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0), ETH);

        vm.prank(getContract(ETH, "SuperformRouter"));
        StateSyncer(address(superTransmuter)).updateTxHistory(0, 1);

        uint256 superformId = DataLib.packSuperform(
            getContract(
                ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ETH
        );

        superTransmuter.registerTransmuter(superformId);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(2, 0, superformId, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        superTransmuter.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_SrcSenderMismatch() public {
        /// @dev returnDataSrcSender = address(0x1)
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0x1), ETH);

        vm.prank(getContract(ETH, "SuperformRouter"));
        StateSyncer(address(superTransmuter)).updateTxHistory(0, 1);

        uint256 superformId = DataLib.packSuperform(
            getContract(
                ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ETH
        );

        superTransmuter.registerTransmuter(superformId);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(2, 0, superformId, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.SRC_SENDER_MISMATCH.selector);
        superTransmuter.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_SrcTxTypeMismatch() public {
        /// @dev TxType = 1
        uint256 txInfo = DataLib.packTxInfo(1, 2, 0, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        StateSyncer(address(superTransmuter)).updateTxHistory(0, 1);
        txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        uint256 superformId = DataLib.packSuperform(
            getContract(
                ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ETH
        );

        superTransmuter.registerTransmuter(superformId);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(2, 0, superformId, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.SRC_TX_TYPE_MISMATCH.selector);
        superTransmuter.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_Invalid_payload_routerType_different() public {
        /// @dev TxType = 1
        uint256 txInfo = DataLib.packTxInfo(1, 2, 0, 1, address(0), ETH);
        uint256 superformId = DataLib.packSuperform(
            getContract(
                ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ETH
        );

        superTransmuter.registerTransmuter(superformId);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(1, 0, superformId, 100);

        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        superTransmuter.stateSync(maliciousMessage);
    }

    ///////////////////////////////////////////////////////////////////////////

    function test_revert_stateMultiSync_TRANSMUTER_NOT_REGISTERED() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0), ETH);

        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(2, 0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.TRANSMUTER_NOT_REGISTERED.selector);
        superTransmuter.stateMultiSync(maliciousMessage);
    }

    /// Test revert for invalid txType (multi)
    /// case: accidental messaging back for failed withdrawals with CallBackType FAIL
    function test_revert_stateMultiSync_InvalidPayloadStatus() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        StateSyncer(address(superTransmuter)).updateTxHistory(0, txInfo);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = DataLib.packSuperform(
            getContract(
                ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ETH
        );

        superTransmuter.registerTransmuter(superformIds[0]);

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(2, 0, superformIds, amounts);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD_STATUS.selector);
        superTransmuter.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_InvalidPayload_CallbackType() public {
        uint256 txInfo = DataLib.packTxInfo(0, 0, 1, 1, address(0), ETH);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = DataLib.packSuperform(
            getContract(
                ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ETH
        );

        superTransmuter.registerTransmuter(superformIds[0]);

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(2, 0, superformIds, amounts);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        superTransmuter.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_InvalidPayload_Multi() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        StateSyncer(address(superTransmuter)).updateTxHistory(0, 1);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = DataLib.packSuperform(
            getContract(
                ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ETH
        );

        superTransmuter.registerTransmuter(superformIds[0]);

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(2, 0, superformIds, amounts);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        superTransmuter.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_SrcSenderMismatch() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0x1), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        StateSyncer(address(superTransmuter)).updateTxHistory(0, 1);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = DataLib.packSuperform(
            getContract(
                ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ETH
        );

        superTransmuter.registerTransmuter(superformIds[0]);

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(2, 0, superformIds, amounts);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.SRC_SENDER_MISMATCH.selector);
        superTransmuter.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_SrcTxTypeMismatch() public {
        uint256 txInfo = DataLib.packTxInfo(1, 2, 1, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        StateSyncer(address(superTransmuter)).updateTxHistory(0, txInfo);
        txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0), ETH);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = DataLib.packSuperform(
            getContract(
                ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ETH
        );

        superTransmuter.registerTransmuter(superformIds[0]);

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(2, 0, superformIds, amounts);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.SRC_TX_TYPE_MISMATCH.selector);
        superTransmuter.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_Invalid_payload_routerType_different() public {
        uint256 txInfo = DataLib.packTxInfo(1, 2, 1, 1, address(0), ETH);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = DataLib.packSuperform(
            getContract(
                ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
            ),
            FORM_IMPLEMENTATION_IDS[0],
            ETH
        );

        superTransmuter.registerTransmuter(superformIds[0]);

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(1, 0, superformIds, amounts);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        superTransmuter.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateSyncBroadcast() public {
        vm.prank(deployer);
        vm.expectRevert(Error.NOT_BROADCAST_REGISTRY.selector);
        superTransmuter.stateSyncBroadcast("");
    }
}

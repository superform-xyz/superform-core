// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/BaseSetup.sol";
import "test/utils/Utilities.sol";

import { DataLib } from "src/libraries/DataLib.sol";
import { SuperPositions } from "src/SuperPositions.sol";
import { Error } from "src/libraries/Error.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IERC1155A } from "ERC1155A/interfaces/IERC1155A.sol";

contract SuperPositionsTest is BaseSetup {
    bytes4 INTERFACE_ID_ERC165 = 0x01ffc9a7;

    string public URI = "https://superform.xyz/metadata/";
    SuperPositions public superPositions;
    address formImplementation;
    address vault;
    uint32 formImplementationId = 444;

    address receiverAddress = deployer;

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
        superPositions = SuperPositions(payable(getContract(ETH, "SuperPositions")));

        address superRegistry = getContract(ETH, "SuperRegistry");

        formImplementation = address(new ERC4626Form(superRegistry));

        vault = getContract(ETH, "DAIVaultMock");
        vm.prank(deployer);
        SuperformFactory(getContract(ETH, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId, 1
        );
    }

    function test_addDynamicURI_NOT_PROTOCOL_ADMIN() public {
        vm.prank(address(0x2828));
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        superPositions.setDynamicURI(URI, false);
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
    function test_SupportsInterface() public view {
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

    function test_updateTxHistory_NOT_SUPERFORM_ROUTER() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        vm.prank(address(0x2828));
        vm.expectRevert(Error.NOT_SUPERFORM_ROUTER.selector);
        SuperPositions(address(superPositions)).updateTxHistory(0, txInfo, receiverAddress);
    }

    function test_revert_stateSync_InvalidPayloadStatus() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        SuperPositions(address(superPositions)).updateTxHistory(0, txInfo, receiverAddress);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD_TYPE.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_INVALID_REGISTRY_ID() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "SuperformRouter"));
        vm.expectRevert(Error.INVALID_REGISTRY_ID.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_NotMinterStateRegistry_InvalidRegistryId() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[2]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[2], ETH);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(0, superformId, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "TimelockStateRegistry"));
        vm.expectRevert(Error.NOT_MINTER_STATE_REGISTRY_ROLE.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_InvalidFormRegistryId() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        address superform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        /// non existent form implementation id so the get form state registry id returns 0
        uint256 superformId = DataLib.packSuperform(superform, 555, ETH);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(0, superformId, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "TimelockStateRegistry"));
        vm.expectRevert(Error.INVALID_FORM_REGISTRY_ID.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_InvalidPayload_CallbackType() public {
        /// @dev CallbackType = 0 (INIT)
        uint256 txInfo = DataLib.packTxInfo(0, 0, 0, 1, address(0), ETH);
        ReturnSingleData memory maliciousReturnData = ReturnSingleData(0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD_TYPE.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_InvalidPayload_Multi() public {
        /// @dev multi = 1
        uint256 txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        SuperPositions(address(superPositions)).updateTxHistory(0, 1, receiverAddress);

        ReturnSingleData memory maliciousReturnData = ReturnSingleData(0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD_TYPE.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_SrcTxTypeMismatch() public {
        /// @dev TxType = 1
        uint256 txInfo = DataLib.packTxInfo(1, 2, 0, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        SuperPositions(address(superPositions)).updateTxHistory(0, txInfo, receiverAddress);

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
        SuperPositions(address(superPositions)).updateTxHistory(0, txInfo, receiverAddress);

        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD_TYPE.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_InvalidPayload_CallbackType() public {
        uint256 txInfo = DataLib.packTxInfo(0, 0, 1, 1, address(0), ETH);

        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD_TYPE.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_InvalidPayload_Multi() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        SuperPositions(address(superPositions)).updateTxHistory(0, 1, receiverAddress);

        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD_TYPE.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_SrcTxTypeMismatch() public {
        uint256 txInfo = DataLib.packTxInfo(1, 2, 1, 1, address(0), ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        SuperPositions(address(superPositions)).updateTxHistory(0, txInfo, receiverAddress);
        txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0), ETH);
        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.SRC_TX_TYPE_MISMATCH.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }

    function test_mintSingle_NOT_MINTER() public {
        (uint256 superformId,) =
            SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(formImplementationId, vault);
        uint8[] memory srId = new uint8[](1);
        srId[0] = 8;

        address newSr = address(new CoreStateRegistry(ISuperRegistry(getContract(ETH, "SuperRegistry"))));

        address[] memory srAddresses = new address[](1);
        srAddresses[0] = newSr;

        vm.prank(deployer);
        SuperRegistry(getContract(ETH, "SuperRegistry")).setStateRegistryAddress(srId, srAddresses);

        vm.prank(newSr);
        vm.expectRevert(Error.NOT_MINTER.selector);
        superPositions.mintSingle(address(0x888), superformId, 1);
    }

    function test_mintBatch_NOT_MINTER() public {
        address superform = getContract(
            ETH, string.concat("DAI", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[1]))
        );
        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[1], ETH);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        uint8[] memory srId = new uint8[](1);
        srId[0] = 8;

        address newSr = address(new CoreStateRegistry(ISuperRegistry(getContract(ETH, "SuperRegistry"))));

        address[] memory srAddresses = new address[](1);
        srAddresses[0] = newSr;

        vm.prank(deployer);
        SuperRegistry(getContract(ETH, "SuperRegistry")).setStateRegistryAddress(srId, srAddresses);

        vm.prank(newSr);
        vm.expectRevert(Error.NOT_MINTER.selector);
        superPositions.mintBatch(address(0x888), superformIds, amounts);

        vm.prank(getContract(ETH, "TimelockStateRegistry"));
        superPositions.mintBatch(address(0x888), superformIds, amounts);
    }

    function test_registerAERC20() public {
        (uint256 superformId,) =
            SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(formImplementationId, vault);
        vm.prank(getContract(ETH, "SuperformRouter"));

        superPositions.mintSingle(address(0x888), superformId, 1);

        superPositions.registerAERC20{ value: 0.01 ether }(superformId);
    }

    function test_registerAERC20_notMintedYet() public {
        (uint256 superformId,) =
            SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(formImplementationId, vault);
        vm.expectRevert(IERC1155A.ID_NOT_MINTED_YET.selector);

        superPositions.registerAERC20{ value: 0.01 ether }(superformId);
    }

    function test_withdrawFromInvalidChainId() public {
        address superform = getContract(
            ETH, string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ARBI);

        vm.prank(getContract(ETH, "SuperformRouter"));
        superPositions.mintSingle(address(0x888), superformId, 1);

        vm.expectRevert(Error.SUPERFORM_ID_NONEXISTENT.selector);

        superPositions.registerAERC20{ value: 0.01 ether }(superformId);
    }

    function test_InvalidSuperFormAddress() public {
        uint256 invalidSuperFormId = DataLib.packSuperform(address(0), 4, ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        superPositions.mintSingle(address(0x888), invalidSuperFormId, 1);
        vm.expectRevert(Error.SUPERFORM_ID_NONEXISTENT.selector);
        superPositions.registerAERC20{ value: 0.01 ether }(invalidSuperFormId);
    }

    function test_InvalidFormImplementation() public {
        uint256 invalidSuperFormId = DataLib.packSuperform(address(0x777), 0, ETH);
        vm.prank(getContract(ETH, "SuperformRouter"));
        superPositions.mintSingle(address(0x888), invalidSuperFormId, 1);
        vm.expectRevert(Error.SUPERFORM_ID_NONEXISTENT.selector);
        superPositions.registerAERC20{ value: 0.01 ether }(invalidSuperFormId);
    }

    function test_alreadyRegistered() public {
        (uint256 superformId,) =
            SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(formImplementationId, vault);
        vm.prank(getContract(ETH, "SuperformRouter"));
        superPositions.mintSingle(address(0x888), superformId, 1);

        superPositions.registerAERC20{ value: 0.01 ether }(superformId);

        vm.expectRevert(IERC1155A.AERC20_ALREADY_REGISTERED.selector);
        superPositions.registerAERC20{ value: 0.01 ether }(superformId);
    }

    function test_invalidBroadcastFee() public {
        (uint256 superformId,) =
            SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(formImplementationId, vault);
        vm.prank(getContract(ETH, "SuperformRouter"));
        superPositions.mintSingle(address(0x888), superformId, 1);

        vm.expectRevert(Error.INVALID_BROADCAST_FEE.selector);
        superPositions.registerAERC20{ value: 0.009 ether }(superformId);
    }

    function test_broadcastAndDeploy() public {
        (uint256 superformId,) =
            SuperformFactory(getContract(ETH, "SuperformFactory")).createSuperform(formImplementationId, vault);
        vm.prank(getContract(ETH, "SuperformRouter"));
        superPositions.mintSingle(address(0x888), superformId, 1);

        vm.recordLogs();
        superPositions.registerAERC20{ value: 0.01 ether }(superformId);

        vm.startPrank(deployer);
        _broadcastPayloadHelper(ETH, vm.getRecordedLogs());

        for (uint256 i; i < chainIds.length; ++i) {
            if (chainIds[i] != ETH ) {
                vm.selectFork(FORKS[chainIds[i]]);
                BroadcastRegistry(payable(getContract(chainIds[i], "BroadcastRegistry"))).processPayload(1);

                assertGt(
                    uint256(
                        uint160(SuperPositions(getContract(chainIds[i], "SuperPositions")).aErc20TokenId(superformId))
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

    function test_revert_stateSyncBroadcast_invalidType() public {
        vm.expectRevert(Error.INVALID_MESSAGE_TYPE.selector);
        vm.prank(getContract(ETH, "BroadcastRegistry"));

        superPositions.stateSyncBroadcast(
            abi.encode(
                BroadcastMessage(
                    "SUPER_POSITIONS", keccak256("OTHER_TYPE"), abi.encode(1, 1, 222, "TOKEN", "TOKEN", 18)
                )
            )
        );
    }

    function test_stateSyncBroadcast_alreadyRegistered() public {
        vm.startPrank(getContract(ETH, "BroadcastRegistry"));

        superPositions.stateSyncBroadcast(
            abi.encode(
                BroadcastMessage(
                    "SUPER_POSITIONS", keccak256("DEPLOY_NEW_AERC20"), abi.encode(1, 1, 222, "TOKEN", "TOKEN", 18)
                )
            )
        );

        vm.expectRevert(IERC1155A.AERC20_ALREADY_REGISTERED.selector);
        superPositions.stateSyncBroadcast(
            abi.encode(
                BroadcastMessage(
                    "SUPER_POSITIONS", keccak256("DEPLOY_NEW_AERC20"), abi.encode(1, 1, 222, "NEWTOKEN", "TOKEN", 18)
                )
            )
        );
    }
}

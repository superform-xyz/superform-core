// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.21;

import "test/utils/BaseSetup.sol";
import "test/utils/Utilities.sol";

import { DataLib } from "src/libraries/DataLib.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { SuperPositions } from "src/SuperPositions.sol";
import { Error } from "src/utils/Error.sol";

contract SuperPositionTest is BaseSetup {
    bytes4 INTERFACE_ID_ERC165 = 0x01ffc9a7;

    string public URI = "https://superform.xyz/metadata/";
    SuperPositions public superPositions;

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
        superPositions = SuperPositions(payable(getContract(ETH, "SuperPositions")));
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

    /// Test revert for invalid txType (single)
    function test_revert_stateSync_InvalidPayloadStatus() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        ReturnSingleData memory maliciousReturnData = ReturnSingleData(1, 0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD_STATUS.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_InvalidPayload_CallbackType() public {
        /// @dev CallbackType = 0 (INIT)
        uint256 txInfo = DataLib.packTxInfo(0, 0, 0, 1, address(0), ETH);
        ReturnSingleData memory maliciousReturnData = ReturnSingleData(1, 0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_InvalidPayload_Multi() public {
        /// @dev multi = 1
        uint256 txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0), ETH);
        ReturnSingleData memory maliciousReturnData = ReturnSingleData(1, 0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_SrcSenderMismatch() public {
        /// @dev returnDataSrcSender = address(0x1)
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0x1), ETH);
        ReturnSingleData memory maliciousReturnData = ReturnSingleData(1, 0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.SRC_SENDER_MISMATCH.selector);
        superPositions.stateSync(maliciousMessage);
    }

    function test_revert_stateSync_SrcTxTypeMismatch() public {
        /// @dev TxType = 1
        uint256 txInfo = DataLib.packTxInfo(1, 2, 0, 1, address(0), ETH);
        ReturnSingleData memory maliciousReturnData = ReturnSingleData(1, 0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.SRC_TX_TYPE_MISMATCH.selector);
        superPositions.stateSync(maliciousMessage);
    }

    ///////////////////////////////////////////////////////////////////////////

    /// Test revert for invalid txType (multi)
    /// case: accidental messaging back for failed withdrawals with CallBackType FAIL
    function test_revert_stateMultiSync_InvalidPayloadStatus() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0), ETH);

        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(1, 0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD_STATUS.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_InvalidPayload_CallbackType() public {
        uint256 txInfo = DataLib.packTxInfo(0, 0, 1, 1, address(0), ETH);

        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(1, 0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_InvalidPayload_Multi() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);

        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(1, 0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_SrcSenderMismatch() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0x1), ETH);

        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(1, 0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.SRC_SENDER_MISMATCH.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }

    function test_revert_stateMultiSync_SrcTxTypeMismatch() public {
        uint256 txInfo = DataLib.packTxInfo(1, 2, 1, 1, address(0), ETH);

        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(1, 0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.SRC_TX_TYPE_MISMATCH.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }
}

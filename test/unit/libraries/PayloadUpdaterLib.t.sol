// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

import { Error } from "src/utils/Error.sol";
import { LiqRequest } from "src/types/LiquidityTypes.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { PayloadUpdaterLib } from "src/libraries/PayloadUpdaterLib.sol";
import "src/types/DataTypes.sol";

contract PayloadUpdaterLibUser {
    function validateSlippage(uint256 a, uint256 b, uint256 c) external pure returns (bool) {
        return PayloadUpdaterLib.validateSlippage(a, b, c);
    }

    function validatePayloadUpdate(uint256 a, uint8 b, PayloadState c, uint8 d) external pure {
        PayloadUpdaterLib.validatePayloadUpdate(a, b, c, d);
    }

    function validateLiqReq(LiqRequest memory a) external pure {
        PayloadUpdaterLib.validateLiqReq(a);
    }
}

contract PayloadUpdaterLibTest is Test {
    PayloadUpdaterLibUser payloadUpdateLib;

    function setUp() public {
        payloadUpdateLib = new PayloadUpdaterLibUser();
    }

    function test_validateDepositPayloadUpdate() public {
        /// @dev payload updater goes rogue and tries to update amounts for withdraw transaction
        uint256 txInfo =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.INIT), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo, uint8(TransactionType.DEPOSIT), PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for deposit return transaction
        uint256 txInfo2 =
            DataLib.packTxInfo(uint8(TransactionType.DEPOSIT), uint8(CallbackType.RETURN), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo2, uint8(TransactionType.DEPOSIT), PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for failed withdraw transaction
        uint256 txInfo3 =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.FAIL), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo3, uint8(TransactionType.DEPOSIT), PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for crafted type
        uint256 txInfo4 =
            DataLib.packTxInfo(uint8(TransactionType.DEPOSIT), uint8(CallbackType.FAIL), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo4, uint8(TransactionType.DEPOSIT), PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for crafted type
        uint256 txInfo5 =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.RETURN), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo5, uint8(TransactionType.DEPOSIT), PayloadState.STORED, 1);
    }

    function test_validateDepositPayloadUpdateForAlreadyUpdatedPayload() public {
        /// @dev payload updater goes rogue and tries to update already updated payload
        uint256 txInfo =
            DataLib.packTxInfo(uint8(TransactionType.DEPOSIT), uint8(CallbackType.INIT), 1, 1, address(420), 1);

        vm.expectRevert(Error.PAYLOAD_ALREADY_UPDATED.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo, uint8(TransactionType.DEPOSIT), PayloadState.UPDATED, 1);
    }

    function test_validateDepositPayloadUpdateForAlreadyProcessedPayload() public {
        /// @dev payload updater goes rogue and tries to update already updated payload
        uint256 txInfo =
            DataLib.packTxInfo(uint8(TransactionType.DEPOSIT), uint8(CallbackType.INIT), 1, 1, address(420), 1);

        vm.expectRevert(Error.PAYLOAD_ALREADY_UPDATED.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo, uint8(TransactionType.DEPOSIT), PayloadState.PROCESSED, 1);
    }

    function test_validateDepositPayloadUpdateForIsMultiMismatch() public {
        /// @dev payload updater goes rogue and tries to update already updated payload
        uint256 txInfo = DataLib.packTxInfo(
            uint8(TransactionType.DEPOSIT),
            uint8(CallbackType.INIT),
            0,
            /// 0 - not multi
            1,
            address(420),
            1
        );

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo, uint8(TransactionType.DEPOSIT), PayloadState.STORED, 1);
    }

    function test_validateLiqReq() public {
        bytes memory bytesTxData = abi.encode(420);
        /// @dev checks for liquidity request validation
        vm.expectRevert(Error.CANNOT_UPDATE_WITHDRAW_TX_DATA.selector);
        payloadUpdateLib.validateLiqReq(LiqRequest(1, bytesTxData, address(420), 1, 1e18));
    }

    /// WITHDRAW PAYLAOD UPDATER TESTS

    function test_validateWithdrawPayloadUpdate() public {
        /// @dev payload updater goes rogue and tries to update amounts for deposit transaction
        uint256 txInfo =
            DataLib.packTxInfo(uint8(TransactionType.DEPOSIT), uint8(CallbackType.INIT), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo, uint8(TransactionType.WITHDRAW), PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for withdraw return transaction
        uint256 txInfo2 =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.RETURN), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo2, uint8(TransactionType.WITHDRAW), PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for failed withdraw transaction
        uint256 txInfo3 =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.FAIL), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo3, uint8(TransactionType.WITHDRAW), PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for crafted type
        uint256 txInfo4 =
            DataLib.packTxInfo(uint8(TransactionType.DEPOSIT), uint8(CallbackType.FAIL), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo4, uint8(TransactionType.WITHDRAW), PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for crafted type
        uint256 txInfo5 =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.RETURN), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo5, uint8(TransactionType.WITHDRAW), PayloadState.STORED, 1);
    }

    function test_validateWithdrawPayloadUpdateForAlreadyUpdatedPayload() public {
        /// @dev payload updater goes rogue and tries to update already updated payload
        uint256 txInfo =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.INIT), 1, 1, address(420), 1);

        vm.expectRevert(Error.PAYLOAD_ALREADY_UPDATED.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo, uint8(TransactionType.WITHDRAW), PayloadState.UPDATED, 1);
    }

    function test_validateWithdrawPayloadUpdateForAlreadyProcessedPayload() public {
        /// @dev payload updater goes rogue and tries to update already updated payload
        uint256 txInfo =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.INIT), 1, 1, address(420), 1);

        vm.expectRevert(Error.PAYLOAD_ALREADY_UPDATED.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo, uint8(TransactionType.WITHDRAW), PayloadState.PROCESSED, 1);
    }

    function test_validateWithdrawPayloadUpdateForIsMultiMismatch() public {
        /// @dev payload updater goes rogue and tries to update already updated payload
        uint256 txInfo = DataLib.packTxInfo(
            uint8(TransactionType.WITHDRAW),
            uint8(CallbackType.INIT),
            0,
            /// 0 - not multi
            1,
            address(420),
            1
        );

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validatePayloadUpdate(txInfo, uint8(TransactionType.WITHDRAW), PayloadState.STORED, 1);
    }
}

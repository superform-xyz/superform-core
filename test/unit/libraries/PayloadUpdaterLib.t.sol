// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import { Error } from "src/utils/Error.sol";
import { LiqRequest } from "src/types/LiquidityTypes.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { PayloadUpdaterLib } from "src/libraries/PayloadUpdaterLib.sol";
import "src/types/DataTypes.sol";

contract PayloadUpdaterLibUser {
    function validateSlippage(uint256 a, uint256 b, uint256 c) external pure {
        PayloadUpdaterLib.validateSlippage(a, b, c);
    }

    function validateDepositPayloadUpdate(uint256 a, PayloadState b, uint8 c) external pure {
        PayloadUpdaterLib.validateDepositPayloadUpdate(a, b, c);
    }

    function validateLiqReq(LiqRequest memory a) external pure {
        PayloadUpdaterLib.validateLiqReq(a);
    }

    function validateWithdrawPayloadUpdate(uint256 a, PayloadState b, uint8 c) external pure {
        PayloadUpdaterLib.validateWithdrawPayloadUpdate(a, b, c);
    }
}

contract PayloadUpdaterLibTest is Test {
    PayloadUpdaterLibUser payloadUpdateLib;

    function setUp() public {
        payloadUpdateLib = new PayloadUpdaterLibUser();
    }

    function test_validateSlippage() public {
        /// @dev payload updater goes rogue and tries to update new amount > max amount
        uint256 newAmount = 100;
        uint256 newAmountBeyondSlippage = 97;

        uint256 maxAmount = 99;
        uint256 slippage = 100;
        /// 1%

        vm.expectRevert(Error.NEGATIVE_SLIPPAGE.selector);
        payloadUpdateLib.validateSlippage(newAmount, maxAmount, slippage);

        /// @dev payload updater goes rogue and tries to update new amount beyond slippage limit
        vm.expectRevert(Error.SLIPPAGE_OUT_OF_BOUNDS.selector);
        payloadUpdateLib.validateSlippage(newAmountBeyondSlippage, maxAmount, slippage);
    }

    function test_validateDepositPayloadUpdate() public {
        /// @dev payload updater goes rogue and tries to update amounts for withdraw transaction
        uint256 txInfo =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.INIT), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validateDepositPayloadUpdate(txInfo, PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for deposit return transaction
        uint256 txInfo2 =
            DataLib.packTxInfo(uint8(TransactionType.DEPOSIT), uint8(CallbackType.RETURN), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validateDepositPayloadUpdate(txInfo2, PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for failed withdraw transaction
        uint256 txInfo3 =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.FAIL), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validateDepositPayloadUpdate(txInfo3, PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for crafted type
        uint256 txInfo4 =
            DataLib.packTxInfo(uint8(TransactionType.DEPOSIT), uint8(CallbackType.FAIL), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validateDepositPayloadUpdate(txInfo4, PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for crafted type
        uint256 txInfo5 =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.RETURN), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validateDepositPayloadUpdate(txInfo5, PayloadState.STORED, 1);
    }

    function test_validateDepositPayloadUpdateForAlreadyUpdatedPayload() public {
        /// @dev payload updater goes rogue and tries to update already updated payload
        uint256 txInfo =
            DataLib.packTxInfo(uint8(TransactionType.DEPOSIT), uint8(CallbackType.INIT), 1, 1, address(420), 1);

        vm.expectRevert(Error.PAYLOAD_ALREADY_UPDATED.selector);
        payloadUpdateLib.validateDepositPayloadUpdate(txInfo, PayloadState.UPDATED, 1);
    }

    function test_validateDepositPayloadUpdateForAlreadyProcessedPayload() public {
        /// @dev payload updater goes rogue and tries to update already updated payload
        uint256 txInfo =
            DataLib.packTxInfo(uint8(TransactionType.DEPOSIT), uint8(CallbackType.INIT), 1, 1, address(420), 1);

        vm.expectRevert(Error.PAYLOAD_ALREADY_UPDATED.selector);
        payloadUpdateLib.validateDepositPayloadUpdate(txInfo, PayloadState.PROCESSED, 1);
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
        payloadUpdateLib.validateDepositPayloadUpdate(txInfo, PayloadState.STORED, 1);
    }

    function test_validateLiqReq() public {
        bytes memory bytesTxData = abi.encode(420);
        /// @dev checks for liquidity request validation
        vm.expectRevert(Error.CANNOT_UPDATE_WITHDRAW_TX_DATA.selector);
        payloadUpdateLib.validateLiqReq(LiqRequest(1, bytesTxData, address(420), 1, 1e18, bytesTxData));
    }

    /// WITHDRAW PAYLAOD UPDATER TESTS

    function test_validateWithdrawPayloadUpdate() public {
        /// @dev payload updater goes rogue and tries to update amounts for deposit transaction
        uint256 txInfo =
            DataLib.packTxInfo(uint8(TransactionType.DEPOSIT), uint8(CallbackType.INIT), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validateWithdrawPayloadUpdate(txInfo, PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for withdraw return transaction
        uint256 txInfo2 =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.RETURN), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validateWithdrawPayloadUpdate(txInfo2, PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for failed withdraw transaction
        uint256 txInfo3 =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.FAIL), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validateWithdrawPayloadUpdate(txInfo3, PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for crafted type
        uint256 txInfo4 =
            DataLib.packTxInfo(uint8(TransactionType.DEPOSIT), uint8(CallbackType.FAIL), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validateWithdrawPayloadUpdate(txInfo4, PayloadState.STORED, 1);

        /// @dev payload updater goes rogue and tries to update amounts for crafted type
        uint256 txInfo5 =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.RETURN), 1, 1, address(420), 1);

        vm.expectRevert(Error.INVALID_PAYLOAD_UPDATE_REQUEST.selector);
        payloadUpdateLib.validateWithdrawPayloadUpdate(txInfo5, PayloadState.STORED, 1);
    }

    function test_validateWithdrawPayloadUpdateForAlreadyUpdatedPayload() public {
        /// @dev payload updater goes rogue and tries to update already updated payload
        uint256 txInfo =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.INIT), 1, 1, address(420), 1);

        vm.expectRevert(Error.PAYLOAD_ALREADY_UPDATED.selector);
        payloadUpdateLib.validateWithdrawPayloadUpdate(txInfo, PayloadState.UPDATED, 1);
    }

    function test_validateWithdrawPayloadUpdateForAlreadyProcessedPayload() public {
        /// @dev payload updater goes rogue and tries to update already updated payload
        uint256 txInfo =
            DataLib.packTxInfo(uint8(TransactionType.WITHDRAW), uint8(CallbackType.INIT), 1, 1, address(420), 1);

        vm.expectRevert(Error.PAYLOAD_ALREADY_UPDATED.selector);
        payloadUpdateLib.validateWithdrawPayloadUpdate(txInfo, PayloadState.PROCESSED, 1);
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
        payloadUpdateLib.validateWithdrawPayloadUpdate(txInfo, PayloadState.STORED, 1);
    }
}

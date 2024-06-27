// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import { DeBridgeError } from "src/crosschain-liquidity/debridge/libraries/DeBridgeError.sol";
import "test/utils/ProtocolActions.sol";
import "src/interfaces/IBridgeValidator.sol";
import { DeBridgeValidator } from "src/crosschain-liquidity/debridge/DeBridgeValidator.sol";
import { DlnOrderLib } from "src/vendor/deBridge/DlnOrderLib.sol";
import { IDlnSource } from "src/vendor/deBridge/IDlnSource.sol";

contract DeBridgeValidatorTest is ProtocolActions {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // native for de-bridge is address(0)

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
    }

    function test_validateReceiver() public {
        vm.selectFork(ETH);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateReceiver(
            _buildDummyTxDataUnitTests(
                BuildDummyTxDataUnitTestsVars(
                    7,
                    address(0),
                    address(0),
                    deployer,
                    ETH,
                    BSC,
                    uint256(100),
                    getContract(BSC, "CoreStateRegistry"),
                    false
                )
            ),
            getContract(BSC, "CoreStateRegistry")
        );
    }

    function test_deBridge_validator() public {
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        7,
                        address(0),
                        address(0),
                        deployer,
                        ETH,
                        BSC,
                        uint256(100),
                        getContract(BSC, "CoreStateRegistry"),
                        false
                    )
                ),
                ETH,
                BSC,
                BSC,
                true,
                address(0),
                getContract(BSC, "CoreStateRegistry"),
                NATIVE,
                NATIVE
            )
        );
    }

    function test_deBridge_blacklistedSelector() public {
        bytes memory txDataWithNonAllowedSelector = abi.encodeWithSelector(DeBridgeMock.globalFixedNativeFee.selector);
        vm.expectRevert(Error.BLACKLISTED_ROUTE_ID.selector);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txDataWithNonAllowedSelector, ETH, BSC, BSC, true, address(0), deployer, NATIVE, NATIVE
            )
        );
    }

    function test_validateTxData_sameSrcDstChainId() public {
        vm.selectFork(ETH);
        vm.expectRevert(Error.INVALID_ACTION.selector);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        7,
                        address(0),
                        address(0),
                        deployer,
                        ETH,
                        ETH, // srcChainId is the same as dstChainId
                        uint256(100),
                        getContract(ETH, "CoreStateRegistry"),
                        false
                    )
                ),
                ETH,
                ETH, // srcChainId is the same as dstChainId
                ETH,
                true,
                address(0),
                getContract(ETH, "CoreStateRegistry"),
                NATIVE,
                NATIVE
            )
        );
    }

    function test_validateTxData_invalidDstSwapReceiver() public {
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        7,
                        address(0),
                        address(0),
                        deployer,
                        ETH,
                        BSC,
                        uint256(100),
                        address(1), // Invalid receiver address
                        false
                    )
                ),
                ETH,
                BSC,
                BSC,
                true,
                address(0),
                address(1),
                NATIVE,
                NATIVE
            )
        );
    }

    function test_validateTxData_invalidInterimToken() public {
        vm.selectFork(ETH);

        vm.expectRevert(Error.INVALID_INTERIM_TOKEN.selector);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        7,
                        address(0),
                        address(0),
                        deployer,
                        ETH,
                        AVAX,
                        uint256(100),
                        getContract(BSC, "DstSwapper"),
                        false
                    )
                ),
                ETH,
                AVAX,
                AVAX,
                true,
                address(0),
                getContract(BSC, "DstSwapper"),
                NATIVE,
                address(3201)
            )
        );
    }

    function test_validateTxData_invalidTxDataChainId() public {
        vm.selectFork(ETH);
        vm.expectRevert(Error.INVALID_TXDATA_CHAIN_ID.selector);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        7,
                        address(0),
                        address(0),
                        deployer,
                        ETH,
                        AVAX,
                        uint256(100),
                        getContract(AVAX, "CoreStateRegistry"),
                        false
                    )
                ),
                ETH,
                AVAX, // Invalid dstChainId
                ETH,
                true,
                address(0),
                getContract(AVAX, "CoreStateRegistry"),
                NATIVE,
                NATIVE
            )
        );
    }

    function test_decodeAmountIn() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                7,
                address(0),
                address(0),
                deployer,
                ETH,
                BSC,
                uint256(100),
                getContract(BSC, "CoreStateRegistry"),
                false
            )
        );

        uint256 amountIn = DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).decodeAmountIn(txData, false);
        assert(amountIn == 100);
    }

    function test_decodeDstSwap() public {
        vm.expectRevert(Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN.selector);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).decodeDstSwap(new bytes(0));
    }

    function test_decodeSwapOutputToken() public {
        vm.expectRevert(Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN.selector);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).decodeSwapOutputToken(new bytes(0));
    }

    function test_validateTxData_invalidExtraCallData() public {
        bytes memory txDataWithInvalidAuthority = abi.encodeWithSelector(
            IDlnSource.createOrder.selector,
            DlnOrderLib.OrderCreation({
                giveAmount: 100,
                giveTokenAddress: address(0),
                takeAmount: 200,
                takeTokenAddress: abi.encode(address(1)),
                receiverDst: abi.encode(address(0)),
                orderAuthorityAddressDst: abi.encode(address(1)), // Invalid authority address
                externalCall: bytes("invalid-call-data"),
                allowedCancelBeneficiarySrc: abi.encode(address(321)),
                takeChainId: 1,
                givePatchAuthoritySrc: address(0),
                allowedTakerDst: abi.encode(address(420))
            }),
            bytes(""),
            uint32(1),
            bytes("")
        );

        vm.expectRevert(DeBridgeError.INVALID_EXTRA_CALL_DATA.selector);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txDataWithInvalidAuthority,
                uint64(1),
                uint64(56),
                uint64(56),
                false,
                address(1),
                address(420),
                address(421),
                address(422)
            )
        );
    }

    function test_validateTxData_invalidDeBridgeAuthority() public {
        bytes memory txDataWithInvalidAuthority = abi.encodeWithSelector(
            IDlnSource.createOrder.selector,
            DlnOrderLib.OrderCreation({
                giveAmount: 100,
                giveTokenAddress: address(0),
                takeAmount: 200,
                takeTokenAddress: abi.encodePacked(address(1)),
                receiverDst: abi.encodePacked(address(1)),
                orderAuthorityAddressDst: abi.encodePacked(address(1)), // Invalid authority address
                externalCall: new bytes(0),
                allowedCancelBeneficiarySrc: abi.encodePacked(address(420)),
                takeChainId: 1,
                givePatchAuthoritySrc: address(420),
                allowedTakerDst: bytes("")
            }),
            bytes(""),
            uint32(1),
            bytes("")
        );

        vm.expectRevert(DeBridgeError.INVALID_DEBRIDGE_AUTHORITY.selector);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txDataWithInvalidAuthority,
                uint64(1),
                uint64(56),
                uint64(56),
                false,
                address(1),
                address(420),
                address(421),
                address(422)
            )
        );
    }

    function test_validateTxData_invalidAllowedTakerDst() public {
        bytes memory txDataWithInvalidAllowedTakerDst = abi.encodeWithSelector(
            IDlnSource.createOrder.selector,
            DlnOrderLib.OrderCreation({
                giveAmount: 100,
                giveTokenAddress: address(0),
                takeAmount: 200,
                takeTokenAddress: abi.encode(address(1)),
                receiverDst: abi.encode(address(0)),
                orderAuthorityAddressDst: abi.encode(getContract(BSC, "DeBridgeAuthority")),
                externalCall: new bytes(0),
                allowedCancelBeneficiarySrc: abi.encode(address(321)),
                takeChainId: 56,
                givePatchAuthoritySrc: address(0),
                allowedTakerDst: abi.encode(address(420)) // Invalid allowedTakerDst
             }),
            bytes(""),
            uint32(1),
            bytes("")
        );

        vm.expectRevert(DeBridgeError.INVALID_TAKER_DST.selector);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txDataWithInvalidAllowedTakerDst, ETH, BSC, BSC, true, address(0), deployer, NATIVE, NATIVE
            )
        );
    }

    function test_decodeTxData_invalidPermitEnvelope() public {
        bytes memory txDataWithInvalidPermitEnvelope = abi.encodeWithSelector(
            IDlnSource.createOrder.selector,
            DlnOrderLib.OrderCreation({
                giveAmount: 100,
                giveTokenAddress: address(0),
                takeAmount: 200,
                takeTokenAddress: abi.encode(address(1)),
                receiverDst: abi.encode(address(0)),
                orderAuthorityAddressDst: abi.encode(getContract(BSC, "DeBridgeAuthority")),
                externalCall: new bytes(0),
                allowedCancelBeneficiarySrc: abi.encode(address(321)),
                takeChainId: 56,
                givePatchAuthoritySrc: address(0),
                allowedTakerDst: bytes("")
            }),
            bytes(""),
            uint32(1),
            bytes("invalid-permit-envelope") // Invalid permit envelope
        );

        vm.expectRevert(DeBridgeError.INVALID_PERMIT_ENVELOP.selector);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateReceiver(
            txDataWithInvalidPermitEnvelope, address(0)
        );
    }

    function test_validateTxData_invalidRefundAddress() public {
        bytes memory txDataWithInvalidRefundAddress = abi.encodeWithSelector(
            IDlnSource.createOrder.selector,
            DlnOrderLib.OrderCreation({
                giveAmount: 100,
                giveTokenAddress: address(0),
                takeAmount: 200,
                takeTokenAddress: abi.encode(address(1)),
                receiverDst: abi.encode(getContract(BSC, "CoreStateRegistry")),
                orderAuthorityAddressDst: abi.encode(getContract(BSC, "DeBridgeAuthority")),
                externalCall: new bytes(0),
                allowedCancelBeneficiarySrc: abi.encode(address(321)), // Invalid refund address
                takeChainId: 56,
                givePatchAuthoritySrc: address(0),
                allowedTakerDst: bytes("")
            }),
            bytes(""),
            uint32(1),
            bytes("")
        );

        vm.expectRevert(DeBridgeError.INVALID_REFUND_ADDRESS.selector);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txDataWithInvalidRefundAddress,
                ETH,
                BSC,
                BSC,
                true,
                address(0),
                deployer, // The refund address should be the deployer
                NATIVE,
                NATIVE
            )
        );
    }

    function test_realData_validateTxData() public view {
        /// @dev is generated by using:
        /// https://api.dln.trade/v1.0/dln/order/create-tx?srcChainId=1&srcChainTokenIn=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48&srcChainTokenInAmount=100000000000000000000&dstChainId=43114&dstChainTokenOut=0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7&dstChainTokenOutAmount=auto&dstChainTokenOutRecipient=0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045&srcChainOrderAuthorityAddress=0x0000000000000000000000000000000000000000&dstChainOrderAuthorityAddress=0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045&affiliateFeePercent=0.1&affiliateFeeRecipient=0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045
        bool isValidReceiver = DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateReceiver(
            hex"b930370100000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000018f60b1fadc0000000000000000000000000000000000000000000000000000000000000340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003a000000000000000000000000000000000000000000000000000000000000003c0000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480000000000000000000000000000000000000000000000056bc75e2d631000000000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000001cfb0eb9833000000000000000000000000000000000000000000000000000000000000a86a00000000000000000000000000000000000000000000000000000000000001a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e000000000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000000000000000000000000000000000240000000000000000000000000000000000000000000000000000000000000026000000000000000000000000000000000000000000000000000000000000000149702230a8ea53601f5cd2dc00fdbc13d4df4a8c70000000000000000000000000000000000000000000000000000000000000000000000000000000000000014d8da6bf26964af9d7eed9e03e53415d37aa960450000000000000000000000000000000000000000000000000000000000000000000000000000000000000014d8da6bf26964af9d7eed9e03e53415d37aa960450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034d8da6bf26964af9d7eed9e03e53415d37aa96045000000000000000000000000000000000000000000000000016345785d8a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004101010000003e3e6300000000000000000000000000000000003398ebb0cf010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045
        );
        assertTrue(isValidReceiver);
    }

    function test_validateTxData_invalidWithdrawalReceiver() public {
        bytes memory txDataWithInvalidWithdrawalReceiver = abi.encodeWithSelector(
            IDlnSource.createOrder.selector,
            DlnOrderLib.OrderCreation({
                giveAmount: 100,
                giveTokenAddress: address(0),
                takeAmount: 200,
                takeTokenAddress: abi.encode(address(1)),
                receiverDst: abi.encode(address(1)), // Invalid receiver address for withdrawal
                orderAuthorityAddressDst: abi.encodePacked(deployer),
                externalCall: new bytes(0),
                allowedCancelBeneficiarySrc: abi.encodePacked(deployer),
                takeChainId: 56,
                givePatchAuthoritySrc: address(deployer),
                allowedTakerDst: bytes("")
            }),
            bytes(""),
            uint32(1),
            bytes("")
        );

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txDataWithInvalidWithdrawalReceiver,
                ETH,
                BSC,
                BSC,
                false, // Withdrawal
                deployer, // receiverAddress
                deployer,
                NATIVE,
                NATIVE
            )
        );
    }

    function test_validateTxData_validWithdrawalReceiver() public {
        vm.selectFork(FORKS[ETH]);
        bytes memory txDataWithValidWithdrawalReceiver = abi.encodeWithSelector(
            IDlnSource.createOrder.selector,
            DlnOrderLib.OrderCreation({
                giveAmount: 100,
                giveTokenAddress: address(0),
                takeAmount: 200,
                takeTokenAddress: abi.encode(address(1)),
                receiverDst: abi.encodePacked(deployer), // Valid receiver address for withdrawal
                orderAuthorityAddressDst: abi.encodePacked(deployer),
                externalCall: new bytes(0),
                allowedCancelBeneficiarySrc: abi.encodePacked(deployer),
                takeChainId: 56,
                givePatchAuthoritySrc: address(deployer),
                allowedTakerDst: bytes("")
            }),
            bytes(""),
            uint32(1),
            bytes("")
        );

        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txDataWithValidWithdrawalReceiver,
                ETH,
                BSC,
                BSC,
                false, // Withdrawal
                deployer, // receiverAddress
                deployer,
                NATIVE,
                NATIVE
            )
        );
    }

    function test_validateTxData_invalidSrcPatchAddress() public {
        vm.selectFork(FORKS[ETH]);
        bytes memory txDataWithValidWithdrawalReceiver = abi.encodeWithSelector(
            IDlnSource.createOrder.selector,
            DlnOrderLib.OrderCreation({
                giveAmount: 100,
                giveTokenAddress: address(0),
                takeAmount: 200,
                takeTokenAddress: abi.encode(address(1)),
                receiverDst: abi.encodePacked(deployer), // Valid receiver address for withdrawal
                orderAuthorityAddressDst: abi.encodePacked(deployer),
                externalCall: new bytes(0),
                allowedCancelBeneficiarySrc: abi.encodePacked(deployer),
                takeChainId: 56,
                givePatchAuthoritySrc: address(420),
                allowedTakerDst: bytes("")
            }),
            bytes(""),
            uint32(1),
            bytes("")
        );

        vm.expectRevert(DeBridgeError.INVALID_PATCH_ADDRESS.selector);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txDataWithValidWithdrawalReceiver,
                ETH,
                BSC,
                BSC,
                false, // Withdrawal
                deployer, // receiverAddress
                deployer,
                NATIVE,
                NATIVE
            )
        );
    }
}

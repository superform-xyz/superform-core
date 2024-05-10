// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import { DeBridgeError } from "src/crosschain-liquidity/debridge/libraries/DeBridgeError.sol";
import "test/utils/ProtocolActions.sol";
import "src/interfaces/IBridgeValidator.sol";
import { DeBridgeForwarderValidator } from "src/crosschain-liquidity/debridge/DeBridgeForwarderValidator.sol";
import { DlnOrderLib } from "src/vendor/debridge/DlnOrderLib.sol";
import { IDlnSource } from "src/vendor/debridge/IDlnSource.sol";
import { ICrossChainForwarder } from "src/vendor/debridge/ICrossChainForwarder.sol";

contract DeBridgeForwarderValidatorTest is ProtocolActions {
    address constant NATIVE = address(0); // native for de-bridge is address(0)
    address constant DE_BRIDGE_SOURCE = 0xeF4fB24aD0916217251F553c0596F8Edc630EB66;
    DeBridgeForwarderValidator validator;

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
        validator = DeBridgeForwarderValidator(getContract(ETH, "DeBridgeForwarderValidator"));
    }

    function test_validateReceiver() public {
        bytes memory txData = _buildDummyDeBridgeTxData(
            address(0), 100, getContract(BSC, "CoreStateRegistry"), address(0), ETH, BSC, bytes(""), ""
        );

        bool isValid = validator.validateReceiver(txData, getContract(BSC, "CoreStateRegistry"));
        assertTrue(isValid);
    }

    function test_validateTxData_validDeposit() public {
        bytes memory targetTxData = abi.encodeWithSelector(
            DeBridgeMock.createSaltedOrder.selector,
            DlnOrderLib.OrderCreation({
                giveAmount: 100,
                giveTokenAddress: address(0),
                takeAmount: 100,
                takeTokenAddress: abi.encodePacked(address(1)),
                receiverDst: abi.encodePacked(getContract(BSC, "DstSwapper")), // dstswapper
                orderAuthorityAddressDst: abi.encodePacked(mockDebridgeAuth),
                externalCall: new bytes(0),
                allowedCancelBeneficiarySrc: bytes(""),
                takeChainId: uint256(BSC),
                givePatchAuthoritySrc: address(0),
                allowedTakerDst: bytes("")
            }),
            uint64(block.timestamp),
            bytes(""),
            uint32(0),
            bytes(""),
            bytes("")
        );

        bytes memory txData = _buildDummyDeBridgeTxData(
            address(0), 100, getContract(BSC, "DstSwapper"), address(0), ETH, BSC, bytes(""), targetTxData
        );

        bool hasDstSwap = validator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, BSC, BSC, true, address(0), deployer, NATIVE, address(1))
        );
        assertTrue(hasDstSwap);
    }

    function test_validateTxData_sameSrcDstChainId() public {
        bytes memory targetTxData = abi.encodeWithSelector(
            DeBridgeMock.createSaltedOrder.selector,
            DlnOrderLib.OrderCreation({
                giveAmount: 100,
                giveTokenAddress: address(0),
                takeAmount: 200,
                takeTokenAddress: abi.encodePacked(address(1)),
                receiverDst: abi.encodePacked(getContract(AVAX, "CoreStateRegistry")),
                orderAuthorityAddressDst: abi.encodePacked(mockDebridgeAuth),
                externalCall: new bytes(0),
                allowedCancelBeneficiarySrc: bytes(""),
                takeChainId: uint256(AVAX),
                givePatchAuthoritySrc: address(0),
                allowedTakerDst: bytes("")
            }),
            uint64(block.timestamp),
            bytes(""),
            uint32(0),
            bytes(""),
            bytes("")
        );

        bytes memory txData = _buildDummyDeBridgeTxData(
            address(0), 100, getContract(ETH, "CoreStateRegistry"), address(0), AVAX, AVAX, bytes(""), targetTxData
        );

        vm.expectRevert(Error.INVALID_ACTION.selector);
        validator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, AVAX, AVAX, AVAX, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_validateTxData_invalidDstSwapReceiver() public {
        bytes memory targetTxData = abi.encodeWithSelector(
            DeBridgeMock.createSaltedOrder.selector,
            DlnOrderLib.OrderCreation({
                giveAmount: 100,
                giveTokenAddress: address(0),
                takeAmount: 100,
                takeTokenAddress: abi.encodePacked(address(1)),
                receiverDst: abi.encodePacked(address(1)), // Invalid receiver address
                orderAuthorityAddressDst: abi.encodePacked(mockDebridgeAuth),
                externalCall: new bytes(0),
                allowedCancelBeneficiarySrc: bytes(""),
                takeChainId: uint256(BSC),
                givePatchAuthoritySrc: address(0),
                allowedTakerDst: bytes("")
            }),
            uint64(block.timestamp),
            bytes(""),
            uint32(0),
            bytes(""),
            bytes("")
        );

        bytes memory txData = _buildDummyDeBridgeTxData(
            address(0),
            100,
            address(1), // Invalid receiver address
            address(0),
            ETH,
            BSC,
            bytes(""),
            targetTxData
        );

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        validator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, BSC, BSC, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_validateTxData_invalidInterimToken() public {
        bytes memory targetTxData = abi.encodeWithSelector(
            DeBridgeMock.createSaltedOrder.selector,
            DlnOrderLib.OrderCreation({
                giveAmount: 100,
                giveTokenAddress: address(3201),
                takeAmount: 200,
                takeTokenAddress: abi.encodePacked(address(3201)), // Invalid interim token address
                receiverDst: abi.encodePacked(getContract(BSC, "DstSwapper")),
                orderAuthorityAddressDst: abi.encodePacked(mockDebridgeAuth),
                externalCall: new bytes(0),
                allowedCancelBeneficiarySrc: bytes(""),
                takeChainId: uint256(AVAX),
                givePatchAuthoritySrc: address(0),
                allowedTakerDst: bytes("")
            }),
            uint64(block.timestamp),
            bytes(""),
            uint32(0),
            bytes(""),
            bytes("")
        );

        bytes memory txData = _buildDummyDeBridgeTxData(
            address(0),
            100,
            getContract(BSC, "DstSwapper"),
            address(3201), // Invalid interim token address
            ETH,
            AVAX,
            bytes(""),
            targetTxData
        );

        vm.expectRevert(Error.INVALID_INTERIM_TOKEN.selector);
        validator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, AVAX, AVAX, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_validateTxData_invalidTxDataChainId() public {
        bytes memory txData = _buildDummyDeBridgeTxData(
            address(0), 100, getContract(AVAX, "CoreStateRegistry"), address(0), ETH, AVAX, bytes(""), ""
        );

        vm.expectRevert(Error.INVALID_TXDATA_CHAIN_ID.selector);
        validator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, AVAX, ETH, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_validateTxData_invalidWithdrawalReceiver() public {
        bytes memory txData = _buildDummyDeBridgeTxData(
            address(0),
            100,
            address(1), // Invalid receiver address
            address(0),
            ETH,
            BSC,
            bytes(""),
            ""
        );

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        validator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, BSC, BSC, false, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_decodeAmountIn() public {
        bytes memory txData = _buildDummyDeBridgeTxData(
            address(0), 100, getContract(BSC, "CoreStateRegistry"), address(0), ETH, BSC, bytes(""), ""
        );

        uint256 amountIn = validator.decodeAmountIn(txData, false);
        assert(amountIn == 100);
    }

    function test_decodeDstSwap() public {
        vm.expectRevert(DeBridgeError.ONLY_SWAPS_DISALLOWED.selector);
        validator.decodeDstSwap(new bytes(0));
    }

    function test_decodeSwapOutputToken() public {
        vm.expectRevert(DeBridgeError.ONLY_SWAPS_DISALLOWED.selector);
        validator.decodeSwapOutputToken(new bytes(0));
    }

    function test_validateTxData_invalidExtraCallData() public {
        bytes memory invalidExtraCallData = bytes("invalid-call-data");
        bytes memory txDataWithInvalidAuthority = _buildDummyDeBridgeTxData(
            address(0),
            100,
            getContract(BSC, "CoreStateRegistry"),
            address(0),
            ETH,
            BSC,
            bytes(""),
            abi.encodeWithSelector(
                IDlnSource.createOrder.selector,
                DlnOrderLib.OrderCreation({
                    giveAmount: 100,
                    giveTokenAddress: address(0),
                    takeAmount: 200,
                    takeTokenAddress: abi.encode(address(1)),
                    receiverDst: abi.encode(address(0)),
                    orderAuthorityAddressDst: abi.encode(mockDebridgeAuth),
                    externalCall: invalidExtraCallData,
                    allowedCancelBeneficiarySrc: bytes(""),
                    takeChainId: 1,
                    givePatchAuthoritySrc: address(0),
                    allowedTakerDst: abi.encode(address(420))
                }),
                bytes(""),
                uint32(1),
                bytes("")
            )
        );

        vm.expectRevert(DeBridgeError.INVALID_EXTRA_CALL_DATA.selector);
        validator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txDataWithInvalidAuthority, ETH, BSC, BSC, false, address(0), deployer, NATIVE, NATIVE
            )
        );
    }

    function test_validateTxData_invalidDeBridgeAuthority() public {
        bytes memory txDataWithInvalidAuthority = _buildDummyDeBridgeTxData(
            address(0),
            100,
            getContract(BSC, "CoreStateRegistry"),
            address(0),
            ETH,
            BSC,
            bytes(""),
            abi.encodeWithSelector(
                IDlnSource.createOrder.selector,
                DlnOrderLib.OrderCreation({
                    giveAmount: 100,
                    giveTokenAddress: address(0),
                    takeAmount: 200,
                    takeTokenAddress: abi.encode(address(1)),
                    receiverDst: abi.encode(address(0)),
                    orderAuthorityAddressDst: abi.encode(address(1)), // Invalid authority address
                    externalCall: new bytes(0),
                    allowedCancelBeneficiarySrc: bytes(""),
                    takeChainId: 1,
                    givePatchAuthoritySrc: address(0),
                    allowedTakerDst: bytes("")
                }),
                bytes(""),
                uint32(1),
                bytes("")
            )
        );

        vm.expectRevert(DeBridgeError.INVALID_DEBRIDGE_AUTHORITY.selector);
        validator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txDataWithInvalidAuthority, ETH, BSC, BSC, false, address(0), deployer, NATIVE, NATIVE
            )
        );
    }

    function test_decodeTxData_invalidPermitEnvelope() public {
        bytes memory txDataWithInvalidPermitEnvelope = _buildDummyDeBridgeTxData(
            address(0),
            100,
            address(1),
            /// Invalid receiver address
            address(0),
            ETH,
            BSC,
            bytes("henlo"),
            ""
        );
        /// permit envelope for bridge

        vm.expectRevert(DeBridgeError.INVALID_PERMIT_ENVELOP.selector);
        validator.validateReceiver(txDataWithInvalidPermitEnvelope, address(420));
    }

    function test_decodeTxData_blacklistRoute() public {
        bytes memory txDataWithInvalidSelector =
            abi.encodeWithSelector(DeBridgeValidator.validateTxData.selector, address(420));
        /// permit envelope for bridge

        vm.expectRevert(Error.BLACKLISTED_ROUTE_ID.selector);
        validator.validateReceiver(txDataWithInvalidSelector, address(420));
    }

    function test_decodeTxData_bridgeTxData_blacklistRoute() public {
        bytes memory txDataWithInvalidSelector = _buildDummyDeBridgeTxData(
            address(0),
            100,
            getContract(BSC, "CoreStateRegistry"),
            address(0),
            ETH,
            BSC,
            bytes(""),
            abi.encodeWithSelector(
                DeBridgeForwarderMock.strictlySwapAndCall.selector,
                DlnOrderLib.OrderCreation({
                    giveAmount: 100,
                    giveTokenAddress: address(0),
                    takeAmount: 200,
                    takeTokenAddress: abi.encode(address(1)),
                    receiverDst: abi.encode(address(0)),
                    orderAuthorityAddressDst: abi.encode(address(1)), // Invalid authority address
                    externalCall: new bytes(0),
                    allowedCancelBeneficiarySrc: bytes(""),
                    takeChainId: 1,
                    givePatchAuthoritySrc: address(0),
                    allowedTakerDst: abi.encode(address(420))
                }),
                bytes(""),
                uint32(1),
                bytes("")
            )
        );

        vm.expectRevert(Error.BLACKLISTED_ROUTE_ID.selector);
        validator.validateReceiver(txDataWithInvalidSelector, address(420));
    }    

    function test_validateTxData_invalidAllowedTakerDst() public {
        bytes memory invalidTakerDst = abi.encode(address(420));
        bytes memory txDataWithInvalidTakerDst = _buildDummyDeBridgeTxData(
            address(0),
            100,
            getContract(BSC, "CoreStateRegistry"),
            address(0),
            ETH,
            BSC,
            bytes(""),
            abi.encodeWithSelector(
                IDlnSource.createOrder.selector,
                DlnOrderLib.OrderCreation({
                    giveAmount: 100,
                    giveTokenAddress: address(0),
                    takeAmount: 200,
                    takeTokenAddress: abi.encode(address(1)),
                    receiverDst: abi.encode(address(0)),
                    orderAuthorityAddressDst: abi.encode(mockDebridgeAuth),
                    externalCall: new bytes(0),
                    allowedCancelBeneficiarySrc: bytes(""),
                    takeChainId: 56,
                    givePatchAuthoritySrc: address(0),
                    allowedTakerDst: invalidTakerDst // Invalid allowedTakerDst
                }),
                bytes(""),
                uint32(1),
                bytes("")
            )
        );

        vm.expectRevert(DeBridgeError.INVALID_TAKER_DST.selector);
        validator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txDataWithInvalidTakerDst,
                ETH,
                BSC,
                BSC,
                true,
                address(0),
                deployer,
                NATIVE,
                NATIVE
            )
        );
    }

    function test_realDataForwarder_validateTxData() public {
        /// @dev is generated by using: https://api.dln.trade/v1.0/dln/order/create-tx?srcChainId=1&srcChainTokenIn=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2&srcChainTokenInAmount=100000000000000000000&dstChainId=43114&dstChainTokenOut=0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7&dstChainTokenOutAmount=auto&dstChainTokenOutRecipient=0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045&srcChainOrderAuthorityAddress=0x0000000000000000000000000000000000000000&dstChainOrderAuthorityAddress=0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045&affiliateFeePercent=0.1&affiliateFeeRecipient=0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045
        bool isValidReceiver = validator.validateReceiver(
            hex"4d8160ba000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000056bc75e2d631000000000000000000000000000000000000000000000000000000000000000000140000000000000000000000000def1c0ded9bec7f1a1670819833240f027b25eff0000000000000000000000000000000000000000000000000000000000000160000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb4800000000000000000000000000000000000000000000000000000045eac824de0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ef4fb24ad0916217251f553c0596f8edc630eb660000000000000000000000000000000000000000000000000000000000000ac000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000928415565b0000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480000000000000000000000000000000000000000000000056bc75e2d6310000000000000000000000000000000000000000000000000000000000045eac824dd00000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000005e000000000000000000000000000000000000000000000000000000000000006e000000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000052000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000004e000000000000000000000000000000000000000000000000000000000000004e000000000000000000000000000000000000000000000000000000000000004800000000000000000000000000000000000000000000000056bc75e2d63100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004e00000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000012556e697377617056330000000000000000000000000000000000000000000000000000000000000433874f632cc600000000000000000000000000000000000000000000000000000000003644c61a33000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000e592427a0aece92de3edee1f18e0157c0586156400000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002bc02aaa39b223fe8d0a0e5c4f27ead9083c756cc20001f4a0b86991c6218b36c1d19d4a2e9eb0ce3606eb4800000000000000000000000000000000000000000000000000000000000000000000000012556e697377617056330000000000000000000000000000000000000000000000000000000000000138400eca364a00000000000000000000000000000000000000000000000000000000000fc0e57fc2000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000e592427a0aece92de3edee1f18e0157c05861564000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000042c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20001f4dac17f958d2ee523a2206206994597c13d831ec7000064a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000000000000000001ae37518000000000000000000000000ad01c20d5886137e056775af56915de824c8fce5000000000000000000000000000000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000002000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000869584cd0000000000000000000000007d66f426a64faff078f1abc1d0e28b485014e23400000000000000000000000000000000b10a29be9a032a0462e57e02a7e651400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000444b930370100000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000018f60c107360000000000000000000000000000000000000000000000000000000000000340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003a000000000000000000000000000000000000000000000000000000000000003c0000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb4800000000000000000000000000000000000000000000000000000045eac824de000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000045a66423c4000000000000000000000000000000000000000000000000000000000000a86a00000000000000000000000000000000000000000000000000000000000001a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e000000000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000000000000000000000000000000000240000000000000000000000000000000000000000000000000000000000000026000000000000000000000000000000000000000000000000000000000000000149702230a8ea53601f5cd2dc00fdbc13d4df4a8c70000000000000000000000000000000000000000000000000000000000000000000000000000000000000014d8da6bf26964af9d7eed9e03e53415d37aa960450000000000000000000000000000000000000000000000000000000000000000000000000000000000000014d8da6bf26964af9d7eed9e03e53415d37aa960450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034d8da6bf26964af9d7eed9e03e53415d37aa960450000000000000000000000000000000000000000000000000000000011e61691000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000410101000000d20e61efde4c0a00000000000000000000000000c42364a64500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045
        );
        assertTrue(isValidReceiver);
    }

    function _buildDummyDeBridgeTxData(
        address _inputToken,
        uint256 _inputAmount,
        address _receiver,
        address _swapOutputToken,
        uint64 _srcChainId,
        uint64 _dstChainId,
        bytes memory _permitEnvelop,
        bytes memory _txData
    )
        internal
        returns (bytes memory)
    {
        if (_txData.length == 0) {
            _txData = abi.encodeWithSelector(
                DeBridgeMock.createSaltedOrder.selector,
                DlnOrderLib.OrderCreation(
                    _swapOutputToken,
                    _inputAmount,
                    abi.encodePacked(address(420)),
                    /// take amount
                    _inputAmount,
                    uint256(_dstChainId),
                    abi.encodePacked(getContract(_dstChainId, "CoreStateRegistry")),
                    address(0),
                    abi.encodePacked(mockDebridgeAuth),
                    bytes(""),
                    bytes(""),
                    bytes("")
                ),
                /// random salt
                uint64(block.timestamp),
                /// affliate fee
                bytes(""),
                /// referral code
                uint32(0),
                /// permit envelope
                _permitEnvelop,
                /// metadata
                bytes("")
            );
        }

        bytes memory txData = abi.encodeWithSelector(
            DeBridgeForwarderMock.strictlySwapAndCall.selector,
            _inputToken,
            _inputAmount,
            bytes(""),
            // src swap router
            address(0),
            /// src swap calldata
            bytes(""),
            /// src token expected amount
            _swapOutputToken,
            /// src token refund recipient
            _inputAmount,
            _receiver,
            /// de bridge target
            DE_BRIDGE_SOURCE,
            _txData
        );

        return txData;
    }
}

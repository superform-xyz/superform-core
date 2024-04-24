// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
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
        bytes memory txData =
            _buildDummyDeBridgeTxData(address(0), 100, getContract(BSC, "CoreStateRegistry"), address(0), ETH, BSC);

        bool isValid = validator.validateReceiver(txData, getContract(BSC, "CoreStateRegistry"));
        assertTrue(isValid);
    }

    function test_validateTxData_validDeposit() public {
        bytes memory txData =
            _buildDummyDeBridgeTxData(address(0), 100, getContract(BSC, "CoreStateRegistry"), address(0), ETH, BSC);

        bool hasDstSwap = validator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, BSC, BSC, true, address(0), deployer, NATIVE, NATIVE)
        );
        assertTrue(hasDstSwap);
    }

    function test_validateTxData_sameSrcDstChainId() public {
        bytes memory txData =
            _buildDummyDeBridgeTxData(address(0), 100, getContract(ETH, "CoreStateRegistry"), address(0), ETH, ETH);

        vm.expectRevert(Error.INVALID_ACTION.selector);
        validator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, ETH, ETH, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_validateTxData_invalidDstSwapReceiver() public {
        bytes memory txData = _buildDummyDeBridgeTxData(
            address(0),
            100,
            address(1), // Invalid receiver address
            address(0),
            ETH,
            BSC
        );

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        validator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, BSC, BSC, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_validateTxData_invalidInterimToken() public {
        bytes memory txData =
            _buildDummyDeBridgeTxData(address(0), 100, getContract(BSC, "DstSwapper"), address(3201), ETH, AVAX);

        vm.expectRevert(Error.INVALID_INTERIM_TOKEN.selector);
        validator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, AVAX, AVAX, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_validateTxData_invalidTxDataChainId() public {
        bytes memory txData =
            _buildDummyDeBridgeTxData(address(0), 100, getContract(AVAX, "CoreStateRegistry"), address(0), ETH, AVAX);

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
            BSC
        );

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        validator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, BSC, BSC, false, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_decodeAmountIn() public {
        bytes memory txData =
            _buildDummyDeBridgeTxData(address(0), 100, getContract(BSC, "CoreStateRegistry"), address(0), ETH, BSC);

        uint256 amountIn = validator.decodeAmountIn(txData, false);
        assert(amountIn == 100);
    }

    function test_decodeDstSwap() public {
        vm.expectRevert(Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN.selector);
        validator.decodeDstSwap(new bytes(0));
    }

    function test_decodeSwapOutputToken() public {
        vm.expectRevert(Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN.selector);
        validator.decodeSwapOutputToken(new bytes(0));
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

        vm.expectRevert(DeBridgeForwarderValidator.INVALID_EXTRA_CALL_DATA.selector);
        validator.validateTxData(
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
                takeTokenAddress: abi.encode(address(1)),
                receiverDst: abi.encode(address(0)),
                orderAuthorityAddressDst: abi.encode(address(1)), // Invalid authority address
                externalCall: new bytes(0),
                allowedCancelBeneficiarySrc: abi.encode(address(321)),
                takeChainId: 1,
                givePatchAuthoritySrc: address(0),
                allowedTakerDst: abi.encode(address(420))
            }),
            bytes(""),
            uint32(1),
            bytes("")
        );

        vm.expectRevert(DeBridgeForwarderValidator.INVALID_DEBRIDGE_AUTHORITY.selector);
        validator.validateTxData(
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

    function test_decodeTxData_invalidPermitEnvelope() public {
        bytes memory txDataWithInvalidPermitEnvelope = abi.encodeWithSelector(
            IDlnSource.createOrder.selector,
            DlnOrderLib.OrderCreation({
                giveAmount: 100,
                giveTokenAddress: address(0),
                takeAmount: 200,
                takeTokenAddress: abi.encode(address(1)),
                receiverDst: abi.encode(address(0)),
                orderAuthorityAddressDst: abi.encode(address(1)), // Invalid authority address
                externalCall: new bytes(0),
                allowedCancelBeneficiarySrc: abi.encode(address(321)),
                takeChainId: 1,
                givePatchAuthoritySrc: address(0),
                allowedTakerDst: abi.encode(address(420))
            }),
            bytes(""),
            uint32(1),
            bytes("hello")
        );

        vm.expectRevert(DeBridgeForwarderValidator.INVALID_PERMIT_ENVELOP.selector);
        validator.validateReceiver(txDataWithInvalidPermitEnvelope, address(420));
    }

    function _buildDummyDeBridgeTxData(
        address _inputToken,
        uint256 _inputAmount,
        address _receiver,
        address _swapOutputToken,
        uint64 _srcChainId,
        uint64 _dstChainId
    )
        internal
        returns (bytes memory)
    {
        bytes memory targetTxData = abi.encodeWithSelector(
            DeBridgeMock.createSaltedOrder.selector,
            DlnOrderLib.OrderCreation(
                _swapOutputToken,
                _inputAmount,
                abi.encode(address(420)),
                /// take amount
                _inputAmount,
                uint256(_dstChainId),
                abi.encode(getContract(_dstChainId, "CoreStateRegistry")),
                address(0),
                abi.encode(mockDebridgeAuth),
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
            bytes(""),
            /// metadata
            bytes("")
        );

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
            targetTxData
        );

        return txData;
    }
}

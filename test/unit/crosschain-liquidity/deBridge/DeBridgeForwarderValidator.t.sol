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
                takeTokenAddress: abi.encode(address(1)),
                receiverDst: abi.encode(getContract(BSC, "DstSwapper")), // dstswapper
                orderAuthorityAddressDst: abi.encode(mockDebridgeAuth),
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
                takeTokenAddress: abi.encode(address(1)),
                receiverDst: abi.encode(getContract(AVAX, "CoreStateRegistry")),
                orderAuthorityAddressDst: abi.encode(mockDebridgeAuth),
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
                takeTokenAddress: abi.encode(address(1)),
                receiverDst: abi.encode(address(1)), // Invalid receiver address
                orderAuthorityAddressDst: abi.encode(mockDebridgeAuth),
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
                takeTokenAddress: abi.encode(address(3201)), // Invalid interim token address
                receiverDst: abi.encode(getContract(BSC, "DstSwapper")),
                orderAuthorityAddressDst: abi.encode(mockDebridgeAuth),
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
        vm.expectRevert(DeBridgeForwarderValidator.ONLY_SWAPS_DISALLOWED.selector);
        validator.decodeDstSwap(new bytes(0));
    }

    function test_decodeSwapOutputToken() public {
        vm.expectRevert(DeBridgeForwarderValidator.ONLY_SWAPS_DISALLOWED.selector);
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

        vm.expectRevert(DeBridgeForwarderValidator.INVALID_EXTRA_CALL_DATA.selector);
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

        vm.expectRevert(DeBridgeForwarderValidator.INVALID_DEBRIDGE_AUTHORITY.selector);
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

        vm.expectRevert(DeBridgeForwarderValidator.INVALID_PERMIT_ENVELOP.selector);
        validator.validateReceiver(txDataWithInvalidPermitEnvelope, address(420));
    }

    function test_decodeTxData_blacklistRoute() public {
        bytes memory txDataWithInvalidSelector =
            abi.encodeWithSelector(DeBridgeForwarderValidator.validateTxData.selector, address(420));
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

        vm.expectRevert(DeBridgeForwarderValidator.INVALID_TAKER_DST.selector);
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

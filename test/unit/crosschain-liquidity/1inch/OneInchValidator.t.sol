// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import { ProtocolActions, OneInchValidator } from "test/utils/ProtocolActions.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { OneInchMock } from "test/mocks/OneInchMock.sol";

import { IAggregationRouterV6, IAggregationExecutor, IERC20 } from "src/vendor/1inch/IAggregationRouterV6.sol";

contract OneInchValidatorTest is ProtocolActions {
    OneInchValidator validator;
    bytes mockTxData =
        hex"e2c95c8200000000000000000000000095ad61b0a150d79219dcf64e1e6cc01f0b64c4ce000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec700000000000000000000000000000000000000000000000000000000000f42400000000000000000000000000000000000000000000007784fc1b16e0aea69fc08000000000000003b6d034098c2b0681d8bf07767826ea8bd3b11b0ca4216318a2be008";

    function setUp() public override {
        super.setUp();

        validator = OneInchValidator(getContract(ETH, "OneInchValidator"));
        vm.selectFork(FORKS[ETH]);
    }

    function test_validateUniswap_realData() public view {
        /// @dev generated the txData using
        /// https://api.1inch.dev/swap/v6.0/1/swap?src=0xdac17f958d2ee523a2206206994597c13d831ec7&dst=0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48&amount=10000000&from=0xa195608C2306A26f727d5199D5A382a4508308DA&slippage=10&receiver=0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92&disableEstimate=true
        bytes memory txData =
            hex"e2c95c8200000000000000000000000048ab8adf869ba9902ad483fb1ca2efdab6eabe92000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000000989680000000000000000000000000000000000000000000000000000000000088dd3308000000000000003b6d03403041cbd36888becc7bbcbc0045e3b1f144466f5f8a2be008";
        assertTrue(validator.validateReceiver(txData, 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92));

        (address token, uint256 amount) = validator.decodeDstSwap(txData);
        assertEq(token, 0xdAC17F958D2ee523a2206206994597C13D831ec7);
        assertEq(amount, 10_000_000);

        address toToken = validator.decodeSwapOutputToken(txData);
        assertEq(toToken, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    }

    function test_validateCurve_realData() public view {
        /// @dev generated the txData using
        /// https://api.1inch.dev/swap/v6.0/1/swap?src=0xdac17f958d2ee523a2206206994597c13d831ec7&dst=0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48&amount=10000000&from=0xa195608C2306A26f727d5199D5A382a4508308DA&slippage=0&protocols=CURVE&includeProtocols=true&receiver=0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92&allowPartialFill=false&disableEstimate=true&usePermit2=false
        bytes memory txData =
            hex"e2c95c8200000000000000000000000048ab8adf869ba9902ad483fb1ca2efdab6eabe92000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000000000000000000000000000000000000098968000000000000000000000000000000000000000000000000000000000009896b1480001020104020400000000a5407eae9ba41422680e2e00537571bcc53efbfd8a2be008";
        assertTrue(validator.validateReceiver(txData, 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92));

        address toToken = validator.decodeSwapOutputToken(txData);
        assertEq(toToken, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    }

    function test_validateReceiver_invalidReceiver() public view {
        assertFalse(validator.validateReceiver(mockTxData, address(0)));
    }

    function test_validateTxData_deposit_invalidChainId() public {
        IBridgeValidator.ValidateTxDataArgs memory args = IBridgeValidator.ValidateTxDataArgs({
            deposit: true,
            srcChainId: 1,
            dstChainId: 5,
            liqDstChainId: 5,
            txData: mockTxData,
            superform: address(this),
            liqDataToken: 0xdAC17F958D2ee523a2206206994597C13D831ec7,
            liqDataInterimToken: address(0),
            receiverAddress: address(0)
        });

        vm.expectRevert(Error.INVALID_TXDATA_CHAIN_ID.selector);
        validator.validateTxData(args);
    }

    function test_validateTxData_deposit_invalidReceiver() public {
        IBridgeValidator.ValidateTxDataArgs memory args = IBridgeValidator.ValidateTxDataArgs({
            deposit: true,
            srcChainId: 1,
            dstChainId: 1,
            liqDstChainId: 1,
            txData: mockTxData,
            superform: address(0),
            liqDataToken: 0xdAC17F958D2ee523a2206206994597C13D831ec7,
            liqDataInterimToken: address(0),
            receiverAddress: address(this)
        });

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        validator.validateTxData(args);
    }

    function test_validateTxData_withdraw_invalidReceiver() public {
        IBridgeValidator.ValidateTxDataArgs memory args = IBridgeValidator.ValidateTxDataArgs({
            deposit: false,
            srcChainId: 1,
            dstChainId: 1,
            liqDstChainId: 1,
            txData: mockTxData,
            superform: address(this),
            liqDataToken: 0xdAC17F958D2ee523a2206206994597C13D831ec7,
            liqDataInterimToken: address(0),
            receiverAddress: address(0)
        });

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        validator.validateTxData(args);
    }

    function test_validateTxData_invalidToken() public {
        IBridgeValidator.ValidateTxDataArgs memory args = IBridgeValidator.ValidateTxDataArgs({
            deposit: false,
            srcChainId: 1,
            dstChainId: 1,
            liqDstChainId: 1,
            txData: mockTxData,
            superform: address(this),
            liqDataToken: address(0),
            liqDataInterimToken: address(0),
            receiverAddress: 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE
        });

        vm.expectRevert(Error.INVALID_TXDATA_TOKEN.selector);
        validator.validateTxData(args);
    }

    function test_constructor_zeroAddress() public {
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new OneInchValidator(address(0));
    }

    function test_decodeTxData_swapSelector() public view {
        /// @dev txData is imported from
        /// https://etherscan.io/tx/0xe6c6ca260d59041934097c51c42733b60f8c28cc66da93b16ef97edcbdafec29
        bytes memory txData =
            hex"07ed2379000000000000000000000000e37e799d5077682fa0a244d46e5649f71457bd09000000000000000000000000d29da236dd4aac627346e1bba06a619e8c22d7c5000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000c3fdf9c70835f9be9db9585ecb6a1ee3f20a6c7000000000000000000000000f62cc7b4e8f91dbeef515ec11f477f4836c0ea1c0000000000000000000000000000000000000000000000000053442ca5785469000000000000000000000000000000000000000000000000339197b56fb2863d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000000dd0000000000000000000000000000000000000000bf0000a500008f00005300206ae4071118002dc6c00c3fdf9c70835f9be9db9585ecb6a1ee3f20a6c7000000000000000000000000000000000000000000000000334f40c1638ee4c2d29da236dd4aac627346e1bba06a619e8c22d7c54101c02aaa39b223fe8d0a0e5c4f27ead9083c756cc200042e1a7d4d0000000000000000000000000000000000000000000000000000000000000000c061111111125421ca6dc452d289314280a0f8842a6500206b4be0b9111111125421ca6dc452d289314280a0f8842a65000000e26b9977";

        assertTrue(validator.validateReceiver(txData, 0xf62Cc7b4e8f91DBEEf515Ec11f477f4836C0eA1c));

        IBridgeValidator.ValidateTxDataArgs memory args = IBridgeValidator.ValidateTxDataArgs({
            deposit: false,
            srcChainId: 1,
            dstChainId: 1,
            liqDstChainId: 1,
            txData: txData,
            superform: 0xf62Cc7b4e8f91DBEEf515Ec11f477f4836C0eA1c,
            liqDataToken: 0xD29DA236dd4AAc627346e1bBa06A619E8c22d7C5,
            liqDataInterimToken: address(0),
            receiverAddress: 0xf62Cc7b4e8f91DBEEf515Ec11f477f4836C0eA1c
        });

        assertFalse(validator.validateTxData(args));

        assertEq(validator.decodeSwapOutputToken(txData), 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        (address fromToken, uint256 fromAmount) = validator.decodeDstSwap(txData);

        assertEq(fromToken, 0xD29DA236dd4AAc627346e1bBa06A619E8c22d7C5);
        assertEq(fromAmount, 23_437_381_612_360_809);
    }

    function test_decodeTxData_unsupportedSelector() public {
        bytes memory txData = hex"11111111";
        vm.expectRevert(Error.BLACKLISTED_SELECTOR.selector);
        validator.validateReceiver(txData, address(420));
    }

    function test_validateTxData_deposit_invalidLiqDstChainId() public {
        IBridgeValidator.ValidateTxDataArgs memory args = IBridgeValidator.ValidateTxDataArgs({
            deposit: true,
            srcChainId: 1,
            dstChainId: 1,
            liqDstChainId: 5,
            txData: mockTxData,
            superform: address(this),
            liqDataToken: 0xdAC17F958D2ee523a2206206994597C13D831ec7,
            liqDataInterimToken: address(0),
            receiverAddress: address(0)
        });

        vm.expectRevert(Error.INVALID_DEPOSIT_LIQ_DST_CHAIN_ID.selector);
        validator.validateTxData(args);
    }

    function test_decodeTxData_unoswapTo_shibaswap() public view {
        ///  @dev txdata for shibaswap
        /// https://api.1inch.dev/swap/v6.0/1/swap?src=0xdac17f958d2ee523a2206206994597c13d831ec7&dst=0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE&amount=10000000&from=0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92&slippage=10&fee=0&includeProtocols=true&excludedProtocols=UNISWAP_V2%2CUNISWAP_V3&receiver=0x4A430607a16108994f878F2D8D8dd6a53Ae98288&allowPartialFill=false&disableEstimate=true
        bytes memory txData =
            hex"e2c95c820000000000000000000000004a430607a16108994f878f2d8d8dd6a53ae98288000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec700000000000000000000000000000000000000000000000000000000009896800000000000000000000000000000000000000000000048bf97c8b7cc9e294ad408000000000000003b6d034098c2b0681d8bf07767826ea8bd3b11b0ca4216318a2be008";
        assertTrue(validator.validateReceiver(txData, 0x4A430607a16108994f878F2D8D8dd6a53Ae98288));

        assertEq(validator.decodeSwapOutputToken(txData), 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE);
        (address fromToken, uint256 fromAmount) = validator.decodeDstSwap(txData);

        assertEq(fromToken, 0xdAC17F958D2ee523a2206206994597C13D831ec7);
        assertEq(fromAmount, 10_000_000);

        IBridgeValidator.ValidateTxDataArgs memory args = IBridgeValidator.ValidateTxDataArgs({
            deposit: false,
            srcChainId: 1,
            dstChainId: 1,
            liqDstChainId: 1,
            txData: txData,
            superform: address(0),
            liqDataToken: 0xdAC17F958D2ee523a2206206994597C13D831ec7,
            liqDataInterimToken: address(0),
            receiverAddress: 0x4A430607a16108994f878F2D8D8dd6a53Ae98288
        });

        assertFalse(validator.validateTxData(args));
    }

    function test_decodeTxData_unsupportedSelector_errorMessage() public {
        bytes memory txData = hex"11111111";
        vm.expectRevert(abi.encodeWithSelector(Error.BLACKLISTED_SELECTOR.selector));
        validator.validateReceiver(txData, address(420));
    }

    function test_validateTxData_deposit_invalidSrcChainId() public {
        IBridgeValidator.ValidateTxDataArgs memory args = IBridgeValidator.ValidateTxDataArgs({
            deposit: true,
            srcChainId: 1,
            dstChainId: 5,
            liqDstChainId: 5,
            txData: mockTxData,
            superform: address(this),
            liqDataToken: 0xdAC17F958D2ee523a2206206994597C13D831ec7,
            liqDataInterimToken: address(0),
            receiverAddress: address(0)
        });

        vm.expectRevert(Error.INVALID_TXDATA_CHAIN_ID.selector);
        validator.validateTxData(args);
    }

    function test_validateTxData_deposit_invalidSuperform() public {
        IBridgeValidator.ValidateTxDataArgs memory args = IBridgeValidator.ValidateTxDataArgs({
            deposit: true,
            srcChainId: 1,
            dstChainId: 1,
            liqDstChainId: 1,
            txData: mockTxData,
            superform: address(0),
            liqDataToken: 0xdAC17F958D2ee523a2206206994597C13D831ec7,
            liqDataInterimToken: address(0),
            receiverAddress: address(this)
        });

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        validator.validateTxData(args);
    }

    function test_validateTxData_withdraw_invalidReceiverAddress() public {
        IBridgeValidator.ValidateTxDataArgs memory args = IBridgeValidator.ValidateTxDataArgs({
            deposit: false,
            srcChainId: 1,
            dstChainId: 1,
            liqDstChainId: 1,
            txData: mockTxData,
            superform: address(this),
            liqDataToken: 0xdAC17F958D2ee523a2206206994597C13D831ec7,
            liqDataInterimToken: address(0),
            receiverAddress: address(0)
        });

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        validator.validateTxData(args);
    }

    function test_decodeTxData_invalidTokenPair() public {
        // Encode the txData with the mock Uniswap pair address and an invalid token
        bytes memory txData = abi.encodeWithSelector(
            OneInchMock.unoswapTo.selector,
            uint256(uint160(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)),
            uint256(uint160(address(420))),
            1e6,
            1e18,
            uint256(uint160(address(0x3041CbD36888bECc7bbCBc0045E3B1f144466f5f)))
        );

        vm.expectRevert(abi.encodeWithSelector(OneInchValidator.INVALID_TOKEN_PAIR.selector));
        validator.validateReceiver(txData, address(this));
    }

    function test_decodeTxData_nativeToken() public view {
        /// @dev generated txData from
        /// https://api.1inch.dev/swap/v6.0/1/swap?src=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48&dst=0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee&amount=1000000&from=0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92&origin=0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92&slippage=10&protocols=UNISWAP_V2&includeTokensInfo=true&includeProtocols=true&receiver=0x8f340f5B24da38216834AaFDB61ACa747D217a92&allowPartialFill=false&disableEstimate=true&usePermit2=false
        bytes memory txData =
            hex"e2c95c820000000000000000000000008f340f5b24da38216834aafdb61aca747d217a92000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb4800000000000000000000000000000000000000000000000000000000000f42400000000000000000000000000000000000000000000000000000d6453d3697bb18800000000000003b6d0340b4e16d0168e52d35cacd2c6185b44281ec28c9dc8a2be008";

        assertEq(validator.decodeSwapOutputToken(txData), 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    }

    function test_decodeTxData_invalidPermit() public {
        /// @dev generated txData from
        /// https://api.1inch.dev/swap/v6.0/1/swap?src=0xdac17f958d2ee523a2206206994597c13d831ec7&dst=0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48&amount=10000000&from=0xa195608C2306A26f727d5199D5A382a4508308DA&origin=0xa195608C2306A26f727d5199D5A382a4508308DA&slippage=10&receiver=0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92&allowPartialFill=false&disableEstimate=true&usePermit2=true
        bytes memory txData =
            hex"e2c95c8200000000000000000000000048ab8adf869ba9902ad483fb1ca2efdab6eabe92000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000000989680000000000000000000000000000000000000000000000000000000000088d1790c000000000000003b6d03403041cbd36888becc7bbcbc0045e3b1f144466f5f8a2be008";

        vm.expectRevert(OneInchValidator.INVALID_PERMIT2_DATA.selector);
        validator.decodeSwapOutputToken(txData);
    }

    function test_swap_invalidPermit() public {
        /// @dev generated txData from
        /// https://api.1inch.dev/swap/v6.0/1/swap?src=0xdac17f958d2ee523a2206206994597c13d831ec7&dst=0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48&amount=10000000&from=0xa195608C2306A26f727d5199D5A382a4508308DA&origin=0xa195608C2306A26f727d5199D5A382a4508308DA&slippage=10&includeProtocols=true&excludedProtocols=UNISWAP_V2%2CUNISWAP_V3%2CSUSHI%2CDEFISWAP&receiver=0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92&allowPartialFill=false&disableEstimate=true&usePermit2=true
        bytes memory txData =
            hex"07ed2379000000000000000000000000e37e799d5077682fa0a244d46e5649f71457bd09000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000e37e799d5077682fa0a244d46e5649f71457bd0900000000000000000000000048ab8adf869ba9902ad483fb1ca2efdab6eabe920000000000000000000000000000000000000000000000000000000000989680000000000000000000000000000000000000000000000000000000000089548100000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000013c00000000000000000000000000000000000000000000000000011e0000f051306146be494fee4c73540cb1c5f87536abf1452500dac17f958d2ee523a2206206994597c13d831ec7004475d39ecb000000000000000000000000111111125421ca6dc452d289314280a0f8842a6500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffd8963efd1fc6a506488495d951d5263988d2500000000000000000000000000000000000000000000000000000000008954810000000000000000000000000000000000000000000000000000000066680b620020d6bdbf78a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48111111125421ca6dc452d289314280a0f8842a65000000008a2be008";

        vm.expectRevert(OneInchValidator.INVALID_PERMIT2_DATA.selector);
        validator.decodeSwapOutputToken(txData);
    }

    function test_swap_invalidPartialFill() public {
        IAggregationExecutor executor = IAggregationExecutor(address(420));
        IAggregationRouterV6.SwapDescription memory swapDescription = IAggregationRouterV6.SwapDescription(
            IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7),
            IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),
            payable(address(320)),
            payable(address(321)),
            1_000_000,
            1_000_000,
            3
        );

        bytes memory txData =
            abi.encodeWithSelector(IAggregationRouterV6.swap.selector, executor, swapDescription, bytes(""));

        vm.expectRevert(OneInchValidator.PARTIAL_FILL_NOT_ALLOWED.selector);
        validator.decodeSwapOutputToken(txData);
    }
}

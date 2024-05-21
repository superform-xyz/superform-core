// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";

contract OneInchValidatorTest is ProtocolActions {
    OneInchValidator validator;

    function setUp() public override {
        super.setUp();

        validator = OneInchValidator(getContract(ETH, "OneInchValidator"));
        vm.selectFork(FORKS[ETH]);
    }

    function test_validateUniswap_realData() public {
        /// @dev generated the txData using
        /// https://api.1inch.dev/swap/v6.0/1/swap?src=0xdac17f958d2ee523a2206206994597c13d831ec7&dst=0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48&amount=10000000&from=0xa195608C2306A26f727d5199D5A382a4508308DA&slippage=10&receiver=0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92&disableEstimate=true
        bytes memory txData =
            hex"e2c95c8200000000000000000000000048ab8adf869ba9902ad483fb1ca2efdab6eabe92000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000000989680000000000000000000000000000000000000000000000000000000000088d0e808000000000000003b6d03403041cbd36888becc7bbcbc0045e3b1f144466f5f8a2be008";
        assertTrue(validator.validateReceiver(txData, 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92));

        (address token, uint256 amount) = validator.decodeDstSwap(txData);
        assertEq(token, 0xdAC17F958D2ee523a2206206994597C13D831ec7);
        assertEq(amount, 10_000_000);

        address toToken = validator.decodeSwapOutputToken(txData);
        assertEq(toToken, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    }

    function test_validateCurve_realData() public {
        /// @dev generated the txData using
        /// https://api.1inch.dev/swap/v6.0/1/swap?src=0xdac17f958d2ee523a2206206994597c13d831ec7&dst=0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48&amount=10000000&from=0xa195608C2306A26f727d5199D5A382a4508308DA&slippage=0&protocols=CURVE&includeProtocols=true&receiver=0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92&allowPartialFill=false&disableEstimate=true&usePermit2=false
        bytes memory txData =
            hex"e2c95c8200000000000000000000000048ab8adf869ba9902ad483fb1ca2efdab6eabe92000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000000000000000000000000000000000000098968000000000000000000000000000000000000000000000000000000000009896b1480001020104020400000000a5407eae9ba41422680e2e00537571bcc53efbfd8a2be008";
        assertTrue(validator.validateReceiver(txData, 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92));

        address toToken = validator.decodeSwapOutputToken(txData);
        assertEq(toToken, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    }
}

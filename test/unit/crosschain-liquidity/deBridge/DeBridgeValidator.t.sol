// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";
import "src/interfaces/IBridgeValidator.sol";
import { DeBridgeValidator } from "src/crosschain-liquidity/deBridge/DeBridgeValidator.sol";
import { DlnOrderLib } from "src/vendor/deBridge/DlnOrderLib.sol";

contract DeBridgeValidatorTest is ProtocolActions {
    address constant NATIVE = address(0); // native for de-bridge is address(0)

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
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
                deployer,
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
                deployer,
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
                deployer,
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
                deployer,
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
                deployer,
                NATIVE,
                NATIVE
            )
        );
    }

    function test_validateTxData_invalidWithdrawalReceiver() public {
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        DeBridgeValidator(getContract(ETH, "DeBridgeValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        7,
                        address(0),
                        address(0),
                        address(1), // Invalid receiver address
                        ETH,
                        BSC,
                        uint256(100),
                        address(0),
                        false
                    )
                ),
                ETH,
                BSC,
                BSC,
                false,
                address(0),
                deployer,
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
}

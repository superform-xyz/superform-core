// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;

import { Error } from "src/utils/Error.sol";
import "test/utils/ProtocolActions.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";

contract SocketOneInchValidatorTest is ProtocolActions {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[BSC]);
    }

    function test_socket_one_inch_validator() public {
        SocketOneInchValidator(getContract(BSC, "SocketOneInchValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        3, address(0), address(0), deployer, ETH, BSC, uint256(100), deployer, false
                    )
                ),
                BSC,
                BSC,
                BSC,
                true,
                deployer,
                deployer,
                address(0)
            )
        );
    }

    function test_socket_one_inch_invalid_receiver() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                3,
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

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        SocketOneInchValidator(getContract(BSC, "SocketOneInchValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, BSC, BSC, BSC, true, deployer, deployer, address(0))
        );
    }

    function test_socket_one_inch_invalid_liq_dst_chain() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(3, address(0), address(0), deployer, ETH, BSC, uint256(100), deployer, false)
        );

        vm.expectRevert(Error.INVALID_DEPOSIT_LIQ_DST_CHAIN_ID.selector);
        SocketOneInchValidator(getContract(BSC, "SocketOneInchValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, BSC, BSC, ETH, true, deployer, deployer, address(0))
        );
    }

    function test_socket_one_inch_invalid_receiver_xchain_withdraw() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                3,
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

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        SocketOneInchValidator(getContract(BSC, "SocketOneInchValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, BSC, BSC, BSC, false, deployer, deployer, address(0))
        );
    }

    function test_validate_receiver() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                3,
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

        assertTrue(
            SocketOneInchValidator(getContract(BSC, "SocketOneInchValidator")).validateReceiver(
                txData, getContract(BSC, "CoreStateRegistry")
            )
        );
    }

    function test_validate_amountIn() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                3,
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

        assertEq(
            SocketOneInchValidator(getContract(BSC, "SocketOneInchValidator")).decodeAmountIn(txData, true),
            uint256(100)
        );
    }

    function test_validateTxData_reverts() public {
        vm.expectRevert(Error.INVALID_ACTION.selector);
        SocketOneInchValidator(getContract(BSC, "SocketOneInchValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        3, address(0), address(0), deployer, ETH, BSC, uint256(100), deployer, false
                    )
                ),
                ETH,
                BSC,
                BSC,
                true,
                deployer,
                deployer,
                address(0)
            )
        );

        vm.expectRevert(Error.INVALID_TXDATA_TOKEN.selector);
        SocketOneInchValidator(getContract(BSC, "SocketOneInchValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        3, address(0), address(0), deployer, ETH, BSC, uint256(100), deployer, false
                    )
                ),
                BSC,
                BSC,
                BSC,
                true,
                deployer,
                deployer,
                address(0x777)
            )
        );
    }
}

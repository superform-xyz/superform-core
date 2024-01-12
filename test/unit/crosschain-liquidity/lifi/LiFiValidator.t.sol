// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";

contract LiFiValidatorTest is ProtocolActions {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
    }

    function test_lifi_validator() public {
        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        1,
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

    function test_lifi_validator_real_data() public {
        uint256 amount = LiFiValidator(getContract(ETH, "LiFiValidator")).decodeAmountIn(
            hex"be1eace700000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000200f81170be1714f230dbc4b9ccf7d570656fca6477da7f2352cf53c04ade23efcc000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c2132d05d31c914a87c6611c10748aeb04b58e8f000000000000000000000000552008c0f6870c2f77e5cc1d2eb9bdff03e30ea000000000000000000000000000000000000000000000000000000000000f42400000000000000000000000000000000000000000000000000000000000000038000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008737461726761746500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000086c6966692d6170690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000f2c6300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c51f9c16fa9dfc5000000000000000000000000552008c0f6870c2f77e5cc1d2eb9bdff03e30ea0000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000014552008c0f6870c2f77e5cc1d2eb9bdff03e30ea00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            false
        );
        assertEq(amount, 1_000_000);
    }

    function test_lifi_validator_invalidInterimToken() public {
        vm.expectRevert(Error.INVALID_INTERIM_TOKEN.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        1,
                        address(0),
                        address(0),
                        deployer,
                        ETH,
                        BSC,
                        uint256(100),
                        getContract(BSC, "DstSwapper"),
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
                address(0)
            )
        );
    }

    function test_lifi_invalid_receiver() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1, address(0), address(0), deployer, ETH, BSC, uint256(100), getContract(BSC, "PayMaster"), false
            )
        );
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, BSC, BSC, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_lifi_invalid_dstchain() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1,
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
        vm.expectRevert(Error.INVALID_TXDATA_CHAIN_ID.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, ARBI, ARBI, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_lifi_invalid_receiver_samechain() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1, address(0), address(0), deployer, ETH, ETH, uint256(100), getContract(ETH, "PayMaster"), true
            )
        );
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, ETH, ETH, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_lifi_invalid_receiver_xchain_withdraw() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1, address(0), address(0), deployer, ETH, OP, uint256(100), getContract(OP, "PayMaster"), false
            )
        );

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, ARBI, OP, false, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_lifi_invalid_txdata_chainid_withdraw() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1, address(0), address(0), deployer, ETH, OP, uint256(100), getContract(OP, "PayMaster"), false
            )
        );

        vm.expectRevert(Error.INVALID_TXDATA_CHAIN_ID.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, ARBI, ARBI, false, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_lifi_invalid_token() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                1,
                address(0),
                address(0),
                deployer,
                ETH,
                ARBI,
                uint256(100),
                getContract(ARBI, "CoreStateRegistry"),
                false
            )
        );

        vm.expectRevert(Error.INVALID_TXDATA_TOKEN.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txData, ETH, ARBI, ARBI, true, address(0), deployer, address(420), NATIVE
            )
        );
    }

    function test_extractGenericSwap_standardizedCallInterface() public {
        bytes memory data = abi.encodeWithSelector(
            0xd6a4bc50,
            _buildDummyTxDataUnitTests(
                BuildDummyTxDataUnitTestsVars(
                    1,
                    address(0),
                    address(0),
                    deployer,
                    ETH,
                    ETH,
                    uint256(100),
                    getContract(ETH, "CoreStateRegistry"),
                    true
                )
            )
        );

        (,, address receiver,,) = LiFiValidator(getContract(ETH, "LiFiValidator")).extractGenericSwapParameters(data);

        assertEq(receiver, getContract(ETH, "CoreStateRegistry"));
    }
}

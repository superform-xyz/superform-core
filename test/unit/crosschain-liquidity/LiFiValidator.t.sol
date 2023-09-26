// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import { Error } from "src/utils/Error.sol";
import "test/utils/ProtocolActions.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";

contract LiFiValidatorTest is ProtocolActions {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
    }

    function test_lifi_validator() public view {
        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    1, address(0), address(0), deployer, BSC, uint256(100), getContract(BSC, "CoreStateRegistry"), false
                ),
                ETH,
                BSC,
                BSC,
                true,
                address(0),
                deployer,
                NATIVE
            )
        );
    }

    function test_lifi_invalid_receiver() public {
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    1, address(0), address(0), deployer, BSC, uint256(100), getContract(BSC, "PayMaster"), false
                ),
                ETH,
                BSC,
                BSC,
                true,
                address(0),
                deployer,
                NATIVE
            )
        );
    }

    function test_lifi_invalid_dstchain() public {
        vm.expectRevert(Error.INVALID_TXDATA_CHAIN_ID.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    1, address(0), address(0), deployer, BSC, uint256(100), getContract(BSC, "CoreStateRegistry"), false
                ),
                ETH,
                ARBI,
                ARBI,
                true,
                address(0),
                deployer,
                NATIVE
            )
        );
    }

    function test_lifi_invalid_receiver_samechain() public {
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    1, address(0), address(0), deployer, ETH, uint256(100), getContract(ETH, "PayMaster"), true
                ),
                ETH,
                ETH,
                ETH,
                true,
                address(0),
                deployer,
                NATIVE
            )
        );
    }

    function test_lifi_invalid_receiver_xchain_withdraw() public {
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    1, address(0), address(0), deployer, OP, uint256(100), getContract(OP, "PayMaster"), false
                ),
                ETH,
                ARBI,
                OP,
                false,
                address(0),
                deployer,
                NATIVE
            )
        );
    }

    function test_lifi_invalid_txdata_chainid_withdraw() public {
        vm.expectRevert(Error.INVALID_TXDATA_CHAIN_ID.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    1, address(0), address(0), deployer, OP, uint256(100), getContract(OP, "PayMaster"), false
                ),
                ETH,
                ARBI,
                ARBI,
                false,
                address(0),
                deployer,
                NATIVE
            )
        );
    }

    function test_lifi_invalid_token() public {
        vm.expectRevert(Error.INVALID_TXDATA_TOKEN.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    1,
                    address(0),
                    address(0),
                    deployer,
                    ARBI,
                    uint256(100),
                    getContract(ARBI, "CoreStateRegistry"),
                    false
                ),
                ETH,
                ARBI,
                ARBI,
                true,
                address(0),
                deployer,
                address(420)
            )
        );
    }

    function test_extractGenericSwap_standardizedCallInterface() public {
        bytes memory data = abi.encodeWithSelector(
            0xd6a4bc50,
            _buildDummyTxDataUnitTests(
                1, address(0), address(0), deployer, ETH, uint256(100), getContract(ETH, "CoreStateRegistry"), true
            )
        );

        (,, address receiver,,) = LiFiValidator(getContract(ETH, "LiFiValidator")).extractGenericSwapParameters(data);

        assertEq(receiver, getContract(ETH, "CoreStateRegistry"));
    }
}

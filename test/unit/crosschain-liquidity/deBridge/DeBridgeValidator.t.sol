/// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";
import "src/interfaces/IBridgeValidator.sol";

contract DeBridgeValidatorTest is ProtocolActions {
    address constant NATIVE = address(0);
    /// native for de-bridge is address(0)

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
        vm.expectRevert(Error.INVALID_ACTION.selector);
        LiFiValidator(getContract(ETH, "DeBridgeValidator")).validateTxData(
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
}

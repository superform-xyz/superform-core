// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";

contract SocketValidatorTest is ProtocolActions {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
    }

    function test_socketEmergencyAdmin() public {
        vm.expectRevert(Error.NOT_EMERGENCY_ADMIN.selector);
        SocketValidator(getContract(ETH, "SocketValidator")).addToBlacklist(420);
    }

    function test_socket_validator() public {
        SocketValidator(getContract(ETH, "SocketValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        2,
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
                address(0),
                NATIVE
            )
        );
    }

    function test_socket_validator_blacklistedRouteId() public {
        ISocketRegistry.BridgeRequest memory bridgeRequest;
        ISocketRegistry.MiddlewareRequest memory middlewareRequest;

        bridgeRequest = ISocketRegistry.BridgeRequest(
            18,
            /// @dev request id, arbitrary number, but using 0 or 1 for mocking purposes
            0,
            /// @dev unused in tests
            address(0),
            /// @dev initial token to extract will be externalToken in args, which is the actual
            /// underlyingTokenDst for withdraws (check how the call is made in
            /// _buildSingleVaultWithdrawCallData )
            ""
        );

        bytes memory txData = abi.encodeWithSelector(
            SocketMock.outboundTransferTo.selector,
            ISocketRegistry.UserRequest(address(0), 1, 1, middlewareRequest, bridgeRequest)
        );

        vm.expectRevert(Error.BLACKLISTED_ROUTE_ID.selector);
        SocketValidator(getContract(ETH, "SocketValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, BSC, BSC, true, address(0), deployer, address(0), NATIVE)
        );
    }

    function test_socket_validator_invalidInterimToken() public {
        vm.expectRevert(Error.INVALID_INTERIM_TOKEN.selector);

        SocketValidator(getContract(ETH, "SocketValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        2,
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
                address(0),
                address(0)
            )
        );
    }

    function test_socket_validator_revert_withdraw_differentReceiver() public {
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        SocketValidator(getContract(ETH, "SocketValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        2,
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
                false,
                address(0),
                address(0x7777),
                address(0),
                NATIVE
            )
        );
    }

    function test_socket_invalid_receiver() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                2, address(0), address(0), deployer, ETH, BSC, uint256(100), getContract(BSC, "PayMaster"), false
            )
        );

        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);
        SocketValidator(getContract(ETH, "SocketValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, BSC, BSC, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_socket_invalid_dstchain() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                2,
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
        SocketValidator(getContract(ETH, "SocketValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, ARBI, ARBI, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_socket_invalid_receiver_xchain_withdraw() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                2, address(0), address(0), deployer, ETH, BSC, uint256(100), getContract(BSC, "PayMaster"), false
            )
        );

        vm.expectRevert(Error.INVALID_TXDATA_CHAIN_ID.selector);
        SocketValidator(getContract(ETH, "SocketValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(txData, ETH, ARBI, ARBI, true, address(0), deployer, NATIVE, NATIVE)
        );
    }

    function test_validate_receiver() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                2, address(0), address(0), deployer, ETH, BSC, uint256(100), getContract(BSC, "PayMaster"), false
            )
        );

        assertTrue(
            SocketValidator(getContract(ETH, "SocketValidator")).validateReceiver(txData, getContract(BSC, "PayMaster"))
        );
    }

    function test_validate_amountIn() public {
        bytes memory txData = _buildDummyTxDataUnitTests(
            BuildDummyTxDataUnitTestsVars(
                2, address(0), address(0), deployer, ETH, BSC, uint256(100), getContract(BSC, "PayMaster"), false
            )
        );

        assertEq(SocketValidator(getContract(ETH, "SocketValidator")).decodeAmountIn(txData, true), uint256(100));
    }

    function test_socket_validator_reverts() public {
        vm.expectRevert(Error.INVALID_ACTION.selector);
        SocketValidator(getContract(ETH, "SocketValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        2,
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
                ETH,
                BSC,
                true,
                address(0),
                deployer,
                address(0),
                NATIVE
            )
        );

        vm.expectRevert(Error.INVALID_TXDATA_TOKEN.selector);
        SocketValidator(getContract(ETH, "SocketValidator")).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                _buildDummyTxDataUnitTests(
                    BuildDummyTxDataUnitTestsVars(
                        2,
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
                address(0x777),
                NATIVE
            )
        );
    }

    function test_decodeDstSwap() public {
        vm.expectRevert();
        SocketValidator(getContract(ETH, "SocketValidator")).decodeDstSwap("");
    }

    function test_decodeSwapOutputToken() public {
        vm.expectRevert(Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN.selector);
        SocketValidator(getContract(ETH, "SocketValidator")).decodeSwapOutputToken("");
    }

    function test_addRemoveFromBlacklist() public {
        vm.startPrank(deployer);

        SocketValidator socketValidator = SocketValidator(getContract(ETH, "SocketValidator"));
        socketValidator.addToBlacklist(20);
        assertTrue(socketValidator.isRouteBlacklisted(20));

        vm.expectRevert(Error.BLACKLISTED_ROUTE_ID.selector);
        socketValidator.addToBlacklist(20);

        socketValidator.removeFromBlacklist(20);
        assertFalse(socketValidator.isRouteBlacklisted(20));

        vm.expectRevert(Error.NOT_BLACKLISTED_ROUTE_ID.selector);
        socketValidator.removeFromBlacklist(20);
    }
}

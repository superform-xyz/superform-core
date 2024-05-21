// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import "test/utils/ProtocolActions.sol";

contract TimelockStateRegistryTest is ProtocolActions {
    TimelockStateRegistry public timelockStateRegistry;
    address receiverAddress = address(444);

    function setUp() public override {
        super.setUp();

        timelockStateRegistry = TimelockStateRegistry(payable(getContract(ETH, "TimelockStateRegistry")));
    }

    function test_updateTxDataBranch() external {
        /// @dev mocks receive payload as a form
        vm.selectFork(FORKS[ETH]);
        (address superform, uint256 superformId) = _legacySuperformPackWithShift(ETH);

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ETH, "ERC4626TimelockForm"),
            ETH,
            ETH,
            ETH,
            false,
            deployer,
            uint256(ETH),
            420,
            //420,
            false,
            /// @dev placeholder value, not used
            0,
            1,
            1,
            1
        );

        vm.prank(getContract(AVAX, "SuperformRouter"));
        SuperPositions(getContract(AVAX, "SuperPositions")).updateTxHistory(
            1, DataLib.packTxInfo(1, 2, 0, 3, deployer, ETH), receiverAddress
        );

        vm.prank(getContract(AVAX, "SuperformRouter"));
        SuperPositions(getContract(AVAX, "SuperPositions")).updateTxHistory(
            1, DataLib.packTxInfo(1, 2, 0, 3, deployer, ETH), receiverAddress
        );

        vm.prank(superform);
        timelockStateRegistry.receivePayload(
            0,
            ETH,
            block.timestamp - 5 seconds,
            InitSingleVaultData(
                1,
                superformId,
                420,
                420,
                0,
                LiqRequest(
                    _buildLiqBridgeTxData(liqBridgeTxDataArgs, true), getContract(ETH, "DAI"), address(0), 1, ETH, 0
                ),
                false,
                false,
                receiverAddress,
                bytes("")
            )
        );

        vm.prank(deployer);
        timelockStateRegistry.finalizePayload(1, bytes(""));
    }

    function test_updateTxDataBranch_WithSlippageReverts() external {
        /// @dev mocks receive payload as a form
        vm.selectFork(FORKS[ETH]);

        address superform = getContract(
            ETH, string.concat("DAI", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[1]))
        );
        uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[1], ETH);

        vm.prank(superform);
        timelockStateRegistry.receivePayload(
            0,
            ETH,
            block.timestamp - 5 seconds,
            InitSingleVaultData(
                1,
                superformId,
                420,
                420,
                1000,
                /// @dev note txData (2nd arg) is empty and token (3rd arg) is not address(0) to
                /// indicate keeper to create and update txData using finalizePayload()
                LiqRequest(bytes(""), getContract(ETH, "DAI"), address(0), 1, ETH, 0),
                false,
                false,
                receiverAddress,
                bytes("")
            )
        );

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ETH, "DAI"),
            getContract(ETH, "ERC4626TimelockForm"),
            ETH,
            ETH,
            ETH,
            false,
            receiverAddress,
            uint256(ETH),
            /// @dev amount is 1 less than 420 * 0.9 i.e. exceeding maxSlippage of 10% by 1
            377,
            //377,
            false,
            /// @dev currently testing with 0 bridge slippage
            0,
            1,
            1,
            1
        );

        bytes memory txData = _buildLiqBridgeTxData(liqBridgeTxDataArgs, true);

        vm.prank(deployer);
        vm.expectRevert(Error.SLIPPAGE_OUT_OF_BOUNDS.selector);
        timelockStateRegistry.finalizePayload(1, txData);
    }

    function test_processPayloadMintPositionBranch() external {
        /// @dev mocks receive payload as a form
        vm.selectFork(FORKS[AVAX]);
        (, uint256 superformId) = _legacySuperformPackWithShift(AVAX);

        bytes memory _message = abi.encode(
            AMBMessage(
                DataLib.packTxInfo(1, 2, 0, 3, deployer, ETH),
                abi.encode(new uint8[](0), abi.encode(ReturnSingleData(1, superformId, 420)))
            )
        );

        vm.prank(getContract(AVAX, "SuperformRouter"));
        SuperPositions(getContract(AVAX, "SuperPositions")).updateTxHistory(
            1, DataLib.packTxInfo(1, 2, 0, 3, deployer, ETH), receiverAddress
        );

        vm.prank(getContract(AVAX, "HyperlaneImplementation"));
        timelockStateRegistry.receivePayload(ETH, _message);

        vm.prank(deployer);
        SuperRegistry(getContract(ETH, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        timelockStateRegistry.processPayload(1);
    }

    function test_dispatchPayloadRevert() external {
        /// @dev mocks dispatch payload from any caller
        vm.selectFork(FORKS[AVAX]);

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        vm.expectRevert(Error.DISABLED.selector);
        timelockStateRegistry.dispatchPayload(address(420), ambIds, uint64(1), bytes(""), bytes(""));
    }

    function test_finalizePayload_NotPrivilegedCaller() public {
        vm.selectFork(FORKS[ETH]);

        vm.prank(address(1));
        vm.expectRevert(
            abi.encodeWithSelector(
                Error.NOT_PRIVILEGED_CALLER.selector, keccak256("TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE")
            )
        );
        timelockStateRegistry.finalizePayload(1, bytes(""));
    }

    function test_processPayload_NotPrivilegedCaller() public {
        vm.selectFork(FORKS[ETH]);

        vm.prank(address(1));
        vm.expectRevert(
            abi.encodeWithSelector(
                Error.NOT_PRIVILEGED_CALLER.selector, keccak256("TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE")
            )
        );
        timelockStateRegistry.processPayload(1);
    }

    function test_receivePayload_SuperformIdNonexistent() public {
        vm.selectFork(FORKS[ETH]);

        uint256 nonexistentSuperformId = 123;
        vm.prank(address(1));
        vm.expectRevert(Error.SUPERFORM_ID_NONEXISTENT.selector);
        timelockStateRegistry.receivePayload(
            0,
            0,
            0,
            InitSingleVaultData(
                0,
                nonexistentSuperformId,
                0,
                0,
                0,
                LiqRequest(bytes(""), address(0), address(0), 0, 0, 0),
                false,
                false,
                address(0),
                bytes("")
            )
        );
    }

    function test_receivePayload_NotTimelockSuperform() public {
        vm.selectFork(FORKS[ETH]);

        address nonTimelockSuperform = getContract(
            ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
        );

        uint256 nonTimelockSuperformId = DataLib.packSuperform(nonTimelockSuperform, FORM_IMPLEMENTATION_IDS[0], ETH);

        vm.prank(nonTimelockSuperform);
        vm.expectRevert(Error.NOT_TIMELOCK_SUPERFORM.selector);
        timelockStateRegistry.receivePayload(
            0,
            0,
            0,
            InitSingleVaultData(
                0,
                nonTimelockSuperformId,
                0,
                0,
                0,
                LiqRequest(bytes(""), address(0), address(0), 0, 0, 0),
                false,
                false,
                address(0),
                bytes("")
            )
        );
    }

    function test_processPayload_InvalidPayloadId() public {
        vm.selectFork(FORKS[ETH]);

        uint256 invalidPayloadId = timelockStateRegistry.payloadsCount() + 1;
        vm.prank(deployer);
        vm.expectRevert(Error.INVALID_PAYLOAD_ID.selector);
        timelockStateRegistry.processPayload(invalidPayloadId);
    }

    function _legacySuperformPackWithShift(uint64 chainId_)
        internal
        view
        returns (address superform, uint256 superformId_)
    {
        superform = getContract(
            chainId_,
            string.concat("DAI", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[1]))
        );

        superformId_ = uint256(uint160(superform));
        superformId_ |= uint256(FORM_IMPLEMENTATION_IDS[1]) << 160;
        superformId_ |= uint256(chainId_) << 192;
    }
}

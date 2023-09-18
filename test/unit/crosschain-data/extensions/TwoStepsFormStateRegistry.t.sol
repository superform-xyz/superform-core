// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.21;

import { Error } from "src/utils/Error.sol";
import "test/utils/ProtocolActions.sol";

contract TwoStepsStateRegistryTest is ProtocolActions {
    TwoStepsFormStateRegistry public twoStepRegistry;
    address dstRefundAddress = address(444);

    function setUp() public override {
        super.setUp();

        twoStepRegistry = TwoStepsFormStateRegistry(payable(getContract(ETH, "TwoStepsFormStateRegistry")));
    }

    function test_updateTxDataBranch() external {
        /// @dev mocks receive payload as a form
        vm.selectFork(FORKS[ETH]);
        uint256 superformId = _legacySuperformPackWithShift();

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "USDT"),
            getContract(ETH, "USDT"),
            getContract(ETH, "USDT"),
            getContract(ETH, "ERC4626TimelockForm"),
            ETH,
            ETH,
            ETH,
            false,
            deployer,
            uint256(ETH),
            420,
            false,
            /// @dev placeholder value, not used
            0
        );

        vm.prank(getContract(ETH, "ERC4626TimelockForm"));
        twoStepRegistry.receivePayload(
            0,
            deployer,
            ETH,
            block.timestamp - 5 seconds,
            InitSingleVaultData(
                1,
                1,
                superformId,
                420,
                0,
                false,
                LiqRequest(1, _buildLiqBridgeTxData(liqBridgeTxDataArgs, true), getContract(ETH, "USDT"), ETH, 0),
                dstRefundAddress,
                bytes("")
            )
        );

        vm.prank(deployer);
        twoStepRegistry.finalizePayload(1, bytes(""));
    }

    function test_updateTxDataBranch_WithSlippageReverts() external {
        /// @dev mocks receive payload as a form
        vm.selectFork(FORKS[ETH]);

        address superform = getContract(
            ETH, string.concat("USDT", "ERC4626TimelockMock", "Superform", Strings.toString(FORM_BEACON_IDS[1]))
        );
        uint256 superformId = DataLib.packSuperform(superform, FORM_BEACON_IDS[1], ETH);

        vm.prank(superform);
        twoStepRegistry.receivePayload(
            0,
            deployer,
            ETH,
            block.timestamp - 5 seconds,
            InitSingleVaultData(
                1,
                1,
                superformId,
                420,
                1000,
                false,
                /// @dev note txData (2nd arg) is empty and token (3rd arg) is not address(0) to
                /// indicate keeper to create and update txData using finalizePayload()
                LiqRequest(1, bytes(""), getContract(ETH, "USDT"), ETH, 0),
                dstRefundAddress,
                bytes("")
            )
        );

        LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
            1,
            getContract(ETH, "USDT"),
            getContract(ETH, "USDT"),
            getContract(ETH, "USDT"),
            getContract(ETH, "ERC4626TimelockForm"),
            ETH,
            ETH,
            ETH,
            false,
            deployer,
            uint256(ETH),
            /// @dev amount is 1 less than 420 * 0.9 i.e. exceeding maxSlippage of 10% by 1
            377,
            false,
            /// @dev currently testing with 0 bridge slippage
            0
        );

        bytes memory txData = _buildLiqBridgeTxData(liqBridgeTxDataArgs, true);

        vm.prank(deployer);
        vm.expectRevert(Error.SLIPPAGE_OUT_OF_BOUNDS.selector);
        twoStepRegistry.finalizePayload(1, txData);
    }

    function test_processPayloadMintPositionBranch() external {
        /// @dev mocks receive payload as a form
        vm.selectFork(FORKS[AVAX]);
        uint256 superformId = _legacySuperformPackWithShift();

        bytes memory _message = abi.encode(
            AMBMessage(
                DataLib.packTxInfo(1, 2, 0, 3, deployer, ETH), abi.encode(ReturnSingleData(1, 1, superformId, 420))
            )
        );

        vm.prank(getContract(AVAX, "SuperformRouter"));
        SuperPositions(getContract(AVAX, "SuperPositions")).updateTxHistory(
            1, DataLib.packTxInfo(1, 2, 0, 3, deployer, ETH)
        );

        vm.prank(getContract(AVAX, "HyperlaneImplementation"));
        twoStepRegistry.receivePayload(ETH, _message);

        vm.prank(deployer);
        SuperRegistry(getContract(ETH, "SuperRegistry")).setRequiredMessagingQuorum(ETH, 0);

        vm.prank(deployer);
        twoStepRegistry.processPayload(1);
    }

    function _legacySuperformPackWithShift() internal view returns (uint256 superformId_) {
        address superform_ = getContract(ETH, "ERC4626TimelockForm");
        uint32 formBeaconId_ = 1;
        uint64 chainId_ = ETH;

        superformId_ = uint256(uint160(superform_));
        superformId_ |= uint256(formBeaconId_) << 160;
        superformId_ |= uint256(chainId_) << 192;
    }
}

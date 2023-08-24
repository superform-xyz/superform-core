// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { Error } from "src/utils/Error.sol";
import "test/utils/ProtocolActions.sol";

contract CoreStateRegistryTest is ProtocolActions {
    TwoStepsFormStateRegistry public twoStepRegistry;

    function setUp() public override {
        super.setUp();

        twoStepRegistry = TwoStepsFormStateRegistry(payable(getContract(ETH, "TwoStepsFormStateRegistry")));
    }

    function test_updateTxDataBranch() external {
        /// @dev mocks receive payload as a form
        vm.selectFork(FORKS[ETH]);
        uint256 superformId = _legacySuperformPackWithShift();

        vm.prank(getContract(ETH, "ERC4626TimelockForm"));
        twoStepRegistry.receivePayload(
            0,
            deployer,
            ETH,
            block.timestamp - 5 seconds,
            InitSingleVaultData(
                1,
                superformId,
                420,
                0,
                LiqRequest(
                    1,
                    _buildLiqBridgeTxData(
                        1,
                        getContract(ETH, "USDT"),
                        getContract(ETH, "USDT"),
                        getContract(ETH, "USDT"),
                        getContract(ETH, "ERC4626TimelockForm"),
                        ETH,
                        false,
                        deployer,
                        uint256(ETH),
                        420,
                        false
                    ),
                    getContract(ETH, "USDT"),
                    420,
                    0,
                    bytes("")
                ),
                bytes("")
            )
        );

        vm.prank(deployer);
        twoStepRegistry.finalizePayload(1, bytes(""), bytes(""));
    }

    function test_processPayloadMintPositionBranch() external {
        /// @dev mocks receive payload as a form
        vm.selectFork(FORKS[AVAX]);
        uint256 superformId = _legacySuperformPackWithShift();

        bytes memory _message = abi.encode(
            AMBMessage(DataLib.packTxInfo(1, 2, 0, 3, deployer, ETH), abi.encode(ReturnSingleData(1, superformId, 420)))
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

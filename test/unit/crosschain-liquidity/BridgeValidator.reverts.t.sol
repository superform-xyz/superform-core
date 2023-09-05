// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { Error } from "src/utils/Error.sol";
import "test/utils/ProtocolActions.sol";

contract BridgeValidatorInvalidReceiverTest is BaseSetup {
    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
    }

    function test_lifi_validator() public {
        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            _buildTxData(1, address(0), deployer, BSC, uint256(100), "CoreStateRegistry"),
            ETH,
            BSC,
            BSC,
            true,
            address(0),
            deployer,
            address(0)
        );
    }

    function test_lifi_invalid_receiver() public {
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            _buildTxData(1, address(0), deployer, BSC, uint256(100), "PayMaster"),
            ETH,
            BSC,
            BSC,
            true,
            address(0),
            deployer,
            address(0)
        );
    }

    function test_lifi_invalid_dstchain() public {
        vm.expectRevert(Error.INVALID_TXDATA_CHAIN_ID.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            _buildTxData(1, address(0), deployer, BSC, uint256(100), "CoreStateRegistry"),
            ETH,
            ARBI,
            ARBI,
            true,
            address(0),
            deployer,
            address(0)
        );
    }

    function test_lifi_invalid_receiver_samechain() public {
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            _buildTxData(1, address(0), deployer, ETH, uint256(100), "PayMaster"),
            ETH,
            ETH,
            ETH,
            true,
            address(0),
            deployer,
            address(0)
        );
    }

    function test_lifi_invalid_receiver_xchain_withdraw() public {
        vm.expectRevert(Error.INVALID_TXDATA_RECEIVER.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            _buildTxData(1, address(0), deployer, OP, uint256(100), "PayMaster"),
            ETH,
            ARBI,
            OP,
            false,
            address(0),
            deployer,
            address(0)
        );
    }

    function test_lifi_invalid_txdata_chainid_withdraw() public {
        vm.expectRevert(Error.INVALID_TXDATA_CHAIN_ID.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            _buildTxData(1, address(0), deployer, OP, uint256(100), "PayMaster"),
            ETH,
            ARBI,
            ARBI,
            false,
            address(0),
            deployer,
            address(0)
        );
    }

    function test_lifi_invalid_token() public {
        vm.expectRevert(Error.INVALID_TXDATA_TOKEN.selector);

        LiFiValidator(getContract(ETH, "LiFiValidator")).validateTxData(
            _buildTxData(1, address(0), deployer, ARBI, uint256(100), "CoreStateRegistry"),
            ETH,
            ARBI,
            ARBI,
            true,
            address(0),
            deployer,
            address(420)
        );
    }

    function _buildTxData(
        uint8 liqBridgeKind_,
        address underlyingToken_,
        address from_,
        uint64 toChainId_,
        uint256 amount_,
        string memory receiver_
    )
        internal
        returns (bytes memory txData)
    {
        if (liqBridgeKind_ == 1) {
            ILiFi.BridgeData memory bridgeData;
            ILiFi.SwapData[] memory swapData = new ILiFi.SwapData[](1);

            swapData[0] = ILiFi.SwapData(
                address(0),
                /// callTo (arbitrary)
                address(0),
                /// callTo (approveTo)
                underlyingToken_,
                underlyingToken_,
                amount_,
                abi.encode(from_, FORKS[toChainId_]),
                false // arbitrary
            );

            bridgeData = ILiFi.BridgeData(
                bytes32("1"),
                /// request id
                "",
                "",
                address(0),
                underlyingToken_,
                getContract(toChainId_, receiver_),
                amount_,
                uint256(toChainId_),
                true,
                true
            );

            txData = abi.encodeWithSelector(LiFiMock.swapAndStartBridgeTokensViaBridge.selector, bridgeData, swapData);
        }
    }
}

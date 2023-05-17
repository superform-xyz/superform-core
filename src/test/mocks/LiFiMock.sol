// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
/// Types Imports
import {ILiFi} from "../../vendor/lifi/ILiFi.sol";
import "./MockERC20.sol";

/// @title Socket Router Mock
/// @dev eventually replace this by using a fork of the real registry contract
contract LiFiMock is Test {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    receive() external payable {}

    /// @dev FIXME LiFi does not work like this, it is just for testing purposes
    function swapAndStartBridgeTokensViaBridge(
        ILiFi.BridgeData calldata bridgeData,
        ILiFi.SwapData[] calldata swapData
    ) external payable {
        /// @dev for the purpose of this mock, encapsulating mock data in swap data, regardless if we are doing a swap or not
        if (!bridgeData.hasSourceSwaps && !bridgeData.hasDestinationCall) {
            /// @dev just mock bridge
            _bridge(
                bridgeData.minAmount,
                bridgeData.receiver,
                bridgeData.sendingAssetId,
                swapData[0].callData,
                false
            );
        } else if (
            bridgeData.hasSourceSwaps && !bridgeData.hasDestinationCall
        ) {
            /// @dev else, assume according to socket a swap and bridge is involved
            /// @dev assume from amount = minAmount
            _swap(
                swapData[0].fromAmount,
                swapData[0].sendingAssetId,
                swapData[0].receivingAssetId,
                swapData[0].callData
            );

            _bridge(
                bridgeData.minAmount,
                bridgeData.receiver,
                bridgeData.sendingAssetId,
                swapData[0].callData,
                true
            );
        } else if (
            !bridgeData.hasSourceSwaps && bridgeData.hasDestinationCall
        ) {
            /// @dev assume, for mocking purposes that cases with just swap is for the same token
            /// @dev this is for direct actions and multiTx swap of destination
            /// @dev bridge is used here to mint tokens in a new contract, but actually it's just a swap (chain id is the same)
            _bridge(
                bridgeData.minAmount,
                bridgeData.receiver,
                bridgeData.sendingAssetId,
                swapData[0].callData,
                false
            );
        }
    }

    function _bridge(
        uint256 amount_,
        address receiver_,
        address inputToken_,
        bytes memory data_,
        bool prevSwap
    ) internal {
        /// @dev encapsulating from
        (address from, uint256 toForkId) = abi.decode(
            data_,
            (address, uint256)
        );
        if (!prevSwap)
            MockERC20(inputToken_).transferFrom(from, address(this), amount_);
        MockERC20(inputToken_).burn(address(this), amount_);

        uint256 prevForkId = vm.activeFork();
        vm.selectFork(toForkId);
        MockERC20(inputToken_).mint(receiver_, amount_);
        vm.selectFork(prevForkId);
    }

    function _swap(
        uint256 amount_,
        address inputToken_,
        address bridgeToken_,
        bytes memory data_
    ) internal {
        /// @dev encapsulating from
        address from = abi.decode(data_, (address));
        MockERC20(inputToken_).transferFrom(from, address(this), amount_);
        MockERC20(inputToken_).burn(address(this), amount_);
        /// @dev assume no swap slippage
        MockERC20(bridgeToken_).mint(address(this), amount_);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import "forge-std/Test.sol";
/// Types Imports
import {ISocketRegistry} from "../../interfaces/ISocketRegistry.sol";

import "./MockERC20.sol";

/// @title Socket Router Mock
contract SocketRegistryMock is ISocketRegistry, Test {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    receive() external payable {}

    function outboundTransferTo(
        ISocketRegistry.UserRequest calldata _userRequest
    ) external payable override {
        if (_userRequest.middlewareRequest.inputToken != NATIVE) {
            /// @dev assuming it is always a bridge request for mocking purposes
            ISocketRegistry.BridgeRequest memory bridgeRequest = _userRequest
                .bridgeRequest;

            /// @dev encapsulating from
            /// @dev TODO - do we need this?
            (address from, uint256 toForkId) = abi.decode(
                bridgeRequest.data,
                (address, uint256)
            );
            MockERC20(bridgeRequest.inputToken).transferFrom(
                from,
                address(this),
                _userRequest.amount
            );
            MockERC20(bridgeRequest.inputToken).burn(
                address(this),
                _userRequest.amount
            );

            uint256 prevForkId = vm.activeFork();
            vm.selectFork(toForkId);

            MockERC20(bridgeRequest.inputToken).mint(
                _userRequest.receiverAddress,
                _userRequest.amount
            );

            vm.selectFork(prevForkId);
        }
    }

    function routes() external view override returns (RouteData[] memory) {}
}

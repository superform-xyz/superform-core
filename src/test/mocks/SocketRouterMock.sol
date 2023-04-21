// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import "forge-std/Test.sol";
/// Types Imports
import {ISocketRegistry} from "../../interfaces/ISocketRegistry.sol";

import "./MockERC20.sol";

/// @title Socket Router Mock
contract SocketRouterMock is ISocketRegistry, Test {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    receive() external payable {}

    function outboundTransferTo(
        ISocketRegistry.UserRequest calldata _userRequest
    ) external payable override {
        ISocketRegistry.BridgeRequest memory bridgeRequest = _userRequest
            .bridgeRequest;

        ISocketRegistry.MiddlewareRequest
            memory middlewareRequest = _userRequest.middlewareRequest;
        /// @dev FIXME need to implement native case
        if (bridgeRequest.id != 0) {
            if (_userRequest.bridgeRequest.inputToken != NATIVE) {
                /// @dev encapsulating from
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
        } else {
            if (_userRequest.middlewareRequest.inputToken != NATIVE) {
                /// @dev encapsulating from
                (address from, uint256 toForkId) = abi.decode(
                    middlewareRequest.data,
                    (address, uint256)
                );
                MockERC20(middlewareRequest.inputToken).transferFrom(
                    from,
                    address(this),
                    _userRequest.amount
                );
                MockERC20(middlewareRequest.inputToken).burn(
                    address(this),
                    _userRequest.amount
                );

                uint256 prevForkId = vm.activeFork();
                vm.selectFork(toForkId);

                MockERC20(middlewareRequest.inputToken).mint(
                    _userRequest.receiverAddress,
                    _userRequest.amount
                );
                vm.selectFork(prevForkId);
            }
        }
    }

    function routes() external view override returns (RouteData[] memory) {}
}

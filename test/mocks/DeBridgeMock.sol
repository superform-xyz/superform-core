// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

/// Types Imports
import "src/vendor/deBridge/IDlnSource.sol";
import "./MockERC20.sol";

/// @title DeBridge Dln Source Mock
/// @dev eventually replace this by using a fork of the real dln source contract

contract DeBridgeMock is Test {
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    receive() external payable { }

    function globalFixedNativeFee() external returns (uint88) {
        return type(uint88).max;
    }

    function createSaltedOrder(
        DlnOrderLib.OrderCreation calldata _orderCreation,
        uint64,
        bytes calldata,
        uint32,
        bytes calldata,
        bytes calldata _metadata
    )
        external
        payable
        returns (bytes32)
    {
        (address from, uint256 fromChainId, uint256 toChainId) = abi.decode(_metadata, (address, uint256, uint256));

        // vm.selectFork(fromChainId);
        // MockERC20(_orderCreation.giveTokenAddress).transferFrom(from, address(this), _orderCreation.giveAmount);

        vm.selectFork(toChainId);
        deal(
            _castToAddress(_orderCreation.takeTokenAddress),
            _castToAddress(_orderCreation.receiverDst),
            _orderCreation.takeAmount
        );

        vm.selectFork(fromChainId);

        /// just returning a random key here
        return keccak256(abi.encode(_orderCreation));
    }

    function _castToAddress(bytes memory address_) internal pure returns (address) {
        return address(uint160(bytes20(address_)));
    }
}

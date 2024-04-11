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

    function createSaltedOrder(
        DlnOrderLib.OrderCreation calldata _orderCreation,
        uint64 _salt,
        bytes calldata _affiliateFee,
        uint32 _referralCode,
        bytes calldata _permitEnvelope,
        bytes calldata _metadata
    )
        external
        payable
        returns (bytes32)
    {
        return keccak256(abi.encode(""));
    }
}

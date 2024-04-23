// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

/// Types Imports
import "src/vendor/debridge/IDlnSource.sol";
import "./MockERC20.sol";

/// @title DeBridge Forwarder Mock
/// @dev eventually replace this by using a fork of the real crosschain forwarder contract
contract DeBridgeForwarderMock is Test {
    struct InternalVars {
        address from;
        uint256 fromChainId;
        uint256 toChainId;
        bytes metadata;
        DlnOrderLib.OrderCreation quote;
    }

    function strictlySwapAndCall(
        address _inputToken,
        uint256 _inputAmount,
        bytes memory,
        address,
        bytes memory,
        address,
        uint256,
        address,
        address,
        bytes memory _targetData
    )
        external
        payable
    {
        /// works only if _targetData is createSaltedOrder
        _strictlySwapAndCall(_inputToken, _inputAmount, _targetData);
    }

    function _strictlySwapAndCall(address _inputToken, uint256 _inputAmount, bytes memory _targetData) internal {
        InternalVars memory v;

        (v.quote,,,,, v.metadata) =
            abi.decode(_parseCallDataMem(_targetData), (DlnOrderLib.OrderCreation, uint64, bytes, uint32, bytes, bytes));
        (v.from, v.fromChainId, v.toChainId) = abi.decode(v.metadata, (address, uint256, uint256));

        _bridge(v);
    }

    function _bridge(InternalVars memory v) internal {
        vm.selectFork(v.toChainId);
        deal(
            abi.decode(v.quote.takeTokenAddress, (address)),
            abi.decode(v.quote.receiverDst, (address)),
            v.quote.takeAmount
        );
    }

    /// @dev helps parse bytes memory selector
    function _parseCallDataMem(bytes memory data) internal pure returns (bytes memory calldata_) {
        assembly {
            calldata_ := add(data, 0x04)
        }
    }
}

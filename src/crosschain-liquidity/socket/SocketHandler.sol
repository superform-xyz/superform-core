// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {BridgeHandler} from "../BridgeHandler.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";

/// @title Socket verification contract
/// @author Zeropoint Labs
///
/// @dev To assert input txData is valid
contract SocketHandler is BridgeHandler {
    constructor(ISuperRegistry superRegistry_) BridgeHandler(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    function validateTxData(
        bytes memory txData,
        bytes memory expectedData
    ) external view override returns (bool) {
        /// @dev TODO
        return true;
    }

    function performBridgeCall(
        address to,
        uint256 nativeAmount,
        bytes memory txData
    ) external override {
        /// @dev TODO
    }
}

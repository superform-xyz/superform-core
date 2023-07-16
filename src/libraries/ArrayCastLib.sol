// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "../types/LiquidityTypes.sol";

/// @dev library to cast single values into array for streamlining helper functions
/// @notice not gas optimized, suggested for usage only in view/pure functions
library ArrayCastLib {
    function castToArray(bytes memory value) internal pure returns (bytes[] memory values) {
        values = new bytes[](1);

        values[0] = value;
    }

    function castToArray(LiqRequest memory value) internal pure returns (LiqRequest[] memory values) {
        values = new LiqRequest[](1);

        values[0] = value;
    }
}
